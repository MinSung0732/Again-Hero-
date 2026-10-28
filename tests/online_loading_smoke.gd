extends SceneTree
const SERVER := preload("res://src/online/match_server.gd")
const ACCESS := preload("res://src/online/local_test_access.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
var checks := 0
var server
var scenes: Array = []
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: push_error(message); quit(1); assert(ok,message)
func _initialize() -> void: run.call_deferred()
func until(condition: Callable) -> bool:
	var deadline := Time.get_ticks_msec()+15000
	while not condition.call() and Time.get_ticks_msec()<deadline: await process_frame
	return condition.call()
func run() -> void:
	root.size = Vector2i(1080,1920)
	var local = root.get_node("LocalTestMode")
	local.active = true; local.tutorial_preview = false; SCOPE.user_id = ""; SCOPE.guest_directory = local.test_directory
	server = SERVER.new(); root.add_child(server)
	var ticket := ACCESS.new_ticket()
	check(server.start(24851,"127.0.0.1",false,ticket)==OK,"real localtest server")
	for role in ["hero","demon"]:
		root.get_node("SceneTransition")._entry_options = {"role":role}
		var scene = load("res://src/online/OnlineMatch.tscn").instantiate(); root.add_child(scene); scenes.append(scene)
		await process_frame
		scene.endpoint.text = "ws://127.0.0.1:24851"; scene.test_code.text = ticket; scene._join()
		check(scene.loading.visible and scene.loading.phase=="queue","role matching animation visible")
		check(scene.loading.backdrop.texture!=null and scene.loading.role_theme.name==("용사" if role=="hero" else "마왕"),"generated role PNG connected")
	check(scenes[0].loading.backdrop.texture.resource_path != scenes[1].loading.backdrop.texture.resource_path,"separate role art")
	check(await until(func(): return scenes[0].local_preparing and scenes[1].local_preparing),"both prepare asynchronously")
	var key: String = scenes[0].client.match_id
	var room = server.rooms[key].node
	check(not room.running and room.tick==0,"server does not simulate before both ready")
	for scene in scenes:
		check(scene.entry_voice_pending and not scene.hero_voice.consumed.has("entry"),"entry voice waits for authoritative start")
	var progress_frames := 0
	var network_kept := true
	var first_clock: float = scenes[0].loading.clock
	while scenes[0].local_preparing or scenes[1].local_preparing:
		progress_frames += 1
		network_kept = network_kept and not scenes[0].client.reconnecting and not scenes[1].client.reconnecting
		if progress_frames>500: check(false,"bounded async preparation"); return
		for value in scenes: value.view._layout_map()
		await process_frame
	check(network_kept,"socket polls throughout loading")
	check(progress_frames>1 and scenes[0].loading.clock>first_clock,"animation advances while loading")
	check(await until(func(): return not scenes[0].waiting_for_start and not scenes[1].waiting_for_start),"both ready and authoritative tick reveal battle")
	for scene in scenes:
		check(not scene.loading.visible and not scene.local_preparing,"loading dismissed after start")
		check(not scene.entry_voice_pending and scene.hero_voice.consumed.has("entry"),"entry voice requested once after actual battle start")
		var consumed_before: int = scene.hero_voice.consumed.size()
		await process_frame; await process_frame
		check(scene.hero_voice.consumed.size() == consumed_before,"successive states do not repeat entry voice")
		check(scene.view.battlefield.field.render_only and scene.view.battlefield.field.collision_layer_root.get_child_count()==0,"no client physics")
		for index in scene.view.battlefield.field.depth_prop_roots.size():
			check(is_equal_approx(float(scene.view.battlefield.prop_commands[index][21]),scene.view.battlefield.field.depth_prop_roots[index].position.y),"async resize does not change world ground anchor")
		var rebuilds: int = scene.view.battlefield.rebuilds
		check(await scene.view.prepare_battlefield_async(room.battlefield_info,func(): return true,func(_progress): pass),"repeat map prepare")
		check(scene.view.battlefield.rebuilds==rebuilds,"reuses prepared map")
	# A cancelled partial texture cache must not be mistaken for a complete map.
	var fresh = preload("res://src/online/battle_view.gd").new(); root.add_child(fresh)
	var alive := [true]
	fresh.prepare_battlefield_async(room.battlefield_info,func(): return alive[0],func(_value): pass)
	alive[0] = false
	await process_frame; await process_frame
	check(fresh.battlefield.descriptor.is_empty(),"cancelled partial map never commits descriptor")
	alive[0] = true
	check(await fresh.prepare_battlefield_async(room.battlefield_info,func(): return alive[0],func(_value): pass),"retry after cancelled partial cache completes")
	check(fresh.battlefield.field.async_textures_complete,"retry marks fully prepared cache")
	fresh.queue_free(); await process_frame
	# Cancellation mid-load must never send a stale ready or leave an overlay.
	var scene = scenes[0]
	scene._event({"op":"matched","match":key,"resumed":true,"map":"plaza","duration":600,"battlefield":{"stage":"stage_2","bounds":[3600,3600],"map":"plaza"}})
	check(scene.local_preparing and scene.loading.visible,"new prepare in progress")
	check(not scene.entry_voice_pending,"rejoin does not queue entry voice")
	scene._event({"op":"result","match":key,"winner":""})
	await process_frame; await process_frame
	check(scene.ended and not scene.loading.visible and not scene.local_preparing,"terminal event cancels old loader")
	# Cancellation before start is void, not a free opponent victory.
	room.running = false
	server._receive(server.rooms[key].seats.demon.peer,{"op":"leave","match":key})
	check(room.finished and room.winner.is_empty() and room.reason=="preparation_cancelled","preparation cancellation is void")
	for value in scenes: value.queue_free()
	server.queue_free(); await process_frame; await create_timer(0.2).timeout
	print("ONLINE_LOADING_PASS checks=",checks); quit()
