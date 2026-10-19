extends SceneTree
const SCOPE := preload("res://src/systems/account_save_scope.gd")
var checks := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: push_error(message); quit(1); assert(ok,message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.size = Vector2i(1080,1920)
	for role in ["hero","demon"]:
		root.get_node("SceneTransition")._entry_options = {"role":role}
		var packed: PackedScene = load("res://src/online/OnlineMatch.tscn")
		check(packed != null,"scene compiles with autoloads")
		var scene = packed.instantiate(); root.add_child(scene)
		await process_frame; await process_frame
		check(scene.role == role,"requested role")
		check(scene.queue_button.custom_minimum_size.y >= 72,"mobile button size")
		check(scene.view.size.x > 500 and scene.view.size.y > 300,"battle panel expands")
		if role == "hero": check(scene.pad.mode == "free" and scene.pad.input_surface == scene.view,"touch binds battle only")
		else: check(scene.action_row.get_child_count() == 5,"five roster choices")
		scene._join()
		check(scene.client.socket == null,"guest without token never queues")
		check(scene.test_code == null,"ordinary account screen has no test invitation field")
		check(scene.disconnect_button == null and scene.reconnect_button == null,"ordinary screen has no connection test buttons")
		root.size = Vector2i(1536,1920); await process_frame; await process_frame
		check(scene.view.size.x > 1200,"tablet width expands")
		scene.client.match_id = "ui-recovery"
		scene._event({"op":"connection","match":"ui-recovery","paused":true,"remaining":15.0})
		scene._process(0.01)
		check(scene.connection_waiting and scene.status.text.contains("일시정지"),"server grace countdown displayed")
		if role == "hero": check(not scene.pad.enabled,"grace disables touch movement")
		else:
			for button in scene.action_row.get_children(): check(button.disabled,"grace disables summon buttons")
		scene._event({"op":"connection","match":"ui-recovery","paused":false,"remaining":0.0})
		check(not scene.connection_waiting,"server resume clears pause")
		scene.client.reconnecting = true; scene.client.connection_recovering.emit(true,20.0)
		check(not scene.ended and scene.status.text.contains("연결 복구"),"local transport loss keeps scene alive")
		scene.client.reconnecting = false; scene.client.connection_recovering.emit(false,0.0)
		scene.last_tick = 99; scene.revision = 7
		scene._event({"op":"matched","match":"ui-recovery","resumed":true})
		check(scene.last_tick == -1 and scene.revision == -1,"resume forces snapshot/choice refresh even at same tick")
		scene._event({"op":"result","match":"ui-recovery","winner":role})
		var result_text: String = scene.status.text
		scene._event({"op":"result","match":"ui-recovery","winner":""})
		check(scene.ended and scene.status.text == result_text,"terminal UI is idempotent")
		scene.queue_free(); await process_frame
	var local = root.get_node("LocalTestMode")
	var old_active: bool = local.active
	var old_preview: bool = local.tutorial_preview
	var old_owner: String = SCOPE.user_id
	var old_directory: String = SCOPE.guest_directory
	local.active = true; local.tutorial_preview = false; SCOPE.user_id = ""; SCOPE.guest_directory = local.test_directory
	check(local.is_online_match_allowed(),"isolated localtest has online permission")
	check(preload("res://src/systems/mode_unlock_store.gd").unlocked("rank","stage_1"),"localtest existing rank unlock reaches entry")
	local.tutorial_preview = true
	check(not local.is_online_match_allowed(),"tutorial preview has no online permission")
	local.tutorial_preview = false; SCOPE.user_id = "ordinary-account"
	check(not local.is_online_match_allowed(),"real account cannot borrow stale test flag")
	SCOPE.user_id = ""; SCOPE.guest_directory = "user://"
	check(not local.is_online_match_allowed(),"normal guest directory has no test permission")
	SCOPE.guest_directory = local.test_directory
	for role in ["hero","demon"]:
		root.get_node("SceneTransition")._entry_options = {"role":role}
		var scene = load("res://src/online/OnlineMatch.tscn").instantiate(); root.add_child(scene)
		await process_frame
		check(scene.initial_local_test and scene.test_code != null and scene.test_code.secret,"localtest invitation UI for both roles")
		check(scene.disconnect_button.disabled and scene.reconnect_button.disabled,"test buttons disabled before match")
		scene.endpoint.text = "ws://127.0.0.1:24844"
		scene._join()
		check(scene.client.socket == null and scene.status.text.contains("입장코드"),"missing code stays disconnected")
		scene.test_code.text = preload("res://src/online/local_test_access.gd").new_ticket()
		scene._join()
		check(scene.client.socket != null and scene.client.token.is_empty() and scene.test_code.text.is_empty(),"localtest queues without social token; field cleared")
		local.active = false; scene._process(0.01)
		check(scene.ended and scene.client.socket == null and scene.status.text.contains("테스트 모드"),"leaving test scope closes connection")
		scene._join()
		check(scene.client.socket == null,"stale test scene cannot rejoin after scope change")
		local.active = true
		scene.queue_free(); await process_frame
	local.active = old_active; local.tutorial_preview = old_preview; SCOPE.user_id = old_owner; SCOPE.guest_directory = old_directory
	print("ONLINE_UI_PASS checks=",checks); quit()
