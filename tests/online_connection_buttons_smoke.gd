extends SceneTree
const SERVER := preload("res://src/online/match_server.gd")
const ACCESS := preload("res://src/online/local_test_access.gd")
const RULES := preload("res://src/online/match_rules.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
var checks := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: push_error(message); quit(1); assert(ok,message)
func _initialize() -> void: run.call_deferred()
func pump(seconds: float) -> void:
	var deadline := Time.get_ticks_msec()+int(seconds*1000)
	while Time.get_ticks_msec()<deadline: await process_frame
func until(condition: Callable) -> bool:
	var deadline := Time.get_ticks_msec()+6000
	while not condition.call() and Time.get_ticks_msec()<deadline: await process_frame
	return condition.call()
func run() -> void:
	root.size = Vector2i(1080,1920)
	var local = root.get_node("LocalTestMode")
	var saved := [local.active,local.tutorial_preview,SCOPE.user_id,SCOPE.guest_directory]
	local.active = true; local.tutorial_preview = false; SCOPE.user_id = ""; SCOPE.guest_directory = local.test_directory
	var server = SERVER.new(); root.add_child(server)
	var ticket := ACCESS.new_ticket()
	check(server.start(24847,"127.0.0.1",false,ticket) == OK,"real invitation server")
	var screens: Array = []
	for role in ["hero","demon"]:
		root.get_node("SceneTransition")._entry_options = {"role":role}
		var scene = load("res://src/online/OnlineMatch.tscn").instantiate(); root.add_child(scene); screens.append(scene)
		check(scene.disconnect_button.disabled and scene.reconnect_button.disabled,"no socket test before match")
		check(not scene.client.set_local_test_disconnected(true),"unmatched API rejected")
		scene.endpoint.text = "ws://127.0.0.1:24847"; scene.test_code.text = ticket
		scene.queue_button.pressed.emit()
	var hero = screens[0]; var demon = screens[1]
	check(await until(func(): return not hero.client.match_id.is_empty() and server.rooms.has(hero.client.match_id) and server.rooms[hero.client.match_id].node.running and not hero.waiting_for_start and not demon.waiting_for_start),"both UI ready on real room")
	var key: String = hero.client.match_id
	var room = server.rooms[key].node
	var instance: int = room.get_instance_id()
	# Exercise the reported spider selection/placement through the real UI/socket.
	demon.action_row.get_child(RULES.ROSTER.find("spider")).pressed.emit()
	check(demon.selected_monster == "spider","spider card selects network subject")
	var spawn: Vector2 = room.battle.hero.position + Vector2(300,0)
	demon.view.placement.emit(spawn)
	check(await until(func(): return not room.battle.active_monsters.is_empty()),"opening spider placement reaches actual server factory")
	check(await until(func(): return demon.action_notice.text.contains("수동 배치")),"accepted summon feedback reaches demon UI")
	for scene in screens:
		check(not scene.disconnect_button.disabled and scene.reconnect_button.disabled,"only disconnect available while connected")
		local.active = false
		check(not scene.client.set_local_test_disconnected(true),"stale scope cannot use test API")
		local.active = true
		scene.client.local_test_connection = false
		check(not scene.client.set_local_test_disconnected(true),"normal authenticated transport cannot use test API")
		scene.client.local_test_connection = true
		room.battle.hero._level_up()
		await pump(0.15)
		var token: String = scene.client.resume_token
		scene.disconnect_button.pressed.emit()
		var deadline: int = scene.client.reconnect_deadline
		check(scene.client.socket == null and scene.client.test_transport_paused and scene.client.reconnecting,"button really releases socket and holds retries")
		check(scene.disconnect_button.disabled and not scene.reconnect_button.disabled and scene.status.text.contains("재접속 버튼"),"held connection UI")
		check(await until(func(): return room.connection_paused),"server pauses instead of immediate forfeit")
		var frozen := [room.tick,room.battle.hero.current_hp,room.battle.hero.level,room.choice_revision,room.hero_holds.size()]
		await pump(RULES.RECONNECT_RETRY+0.2)
		check(scene.client.socket == null and scene.client.reconnect_deadline == deadline,"manual hold suppresses automatic retries without extending deadline")
		check(frozen == [room.tick,room.battle.hero.current_hp,room.battle.hero.level,room.choice_revision,room.hero_holds.size()],"real battle state stays frozen")
		check(not scene.client.set_local_test_disconnected(true),"repeated disconnect rejected")
		scene.reconnect_button.pressed.emit()
		check(not scene.client.test_transport_paused and scene.reconnect_button.disabled,"resume button releases hold once")
		check(await until(func(): return not scene.client.reconnecting and not room.connection_paused and not scene.waiting_for_start),"same seat ready resumes actual battle")
		check(scene.client.match_id == key and room.get_instance_id() == instance and scene.client.resume_token == token,"same match instance and capability")
		check(not scene.disconnect_button.disabled and scene.reconnect_button.disabled,"buttons reset after resume")
		check(not room.hero_holds.is_empty(),"held augment survives reconnect")
		if scene.role == "hero":
			check(await until(func(): return scene.hold_toggle.text.contains("%d개" % room.hero_holds.size())),"own held augment badge restored")
		else:
			check(scene.hold_toggle.text.contains("0개"),"opponent held count remains hidden")
	# Leaving the button held never extends the authoritative grace.
	hero.disconnect_button.pressed.emit()
	check(await until(func(): return room.connection_paused),"timeout scenario paused")
	server.rooms[key].seats.hero.deadline = Time.get_ticks_msec()-1
	server._expire_disconnections(key,Time.get_ticks_msec())
	check(await until(func(): return demon.ended),"survivor sees result while other UI remains offline")
	check(room.winner == "demon" and room.reason == "reconnect_timeout","server deadline still wins")
	hero.reconnect_button.pressed.emit()
	check(await until(func(): return hero.ended),"late button recovers terminal result")
	check(hero.client.result_received and hero.status.text.contains("패배") and demon.status.text.contains("승리"),"same authoritative result on both UIs")
	for scene in screens:
		check(scene.disconnect_button.disabled and scene.reconnect_button.disabled,"no test buttons after result")
		check(not scene.client.set_local_test_disconnected(true),"terminal API denied")
		scene.client.close()
		check(not scene.client.test_transport_paused and not scene.client.local_test_connection,"close clears test flags")
		scene.queue_free()
	server.queue_free(); await pump(0.2)
	local.active = saved[0]; local.tutorial_preview = saved[1]; SCOPE.user_id = saved[2]; SCOPE.guest_directory = saved[3]
	print("ONLINE_CONNECTION_BUTTONS_PASS checks=",checks); quit()
