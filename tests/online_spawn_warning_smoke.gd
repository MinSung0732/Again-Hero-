extends SceneTree
class FakeClient extends RefCounted:
	var reconnecting := false
	var match_id := "test"
	var commands: Array = []
	func command(kind: String,argument: Dictionary) -> bool:
		commands.append([kind,argument]); return true
var checks := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: push_error(message); quit(1); assert(ok,message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.get_node("SceneTransition")._entry_options = {"role":"demon"}
	var scene = load("res://src/online/OnlineMatch.tscn").instantiate(); root.add_child(scene)
	var original = scene.client
	var fake := FakeClient.new(); scene.client = fake
	scene.ended = false; scene.local_preparing = false; scene.waiting_for_start = false; scene.connection_waiting = false
	scene.view.state = {"hero":[1000,1000],"actors":[]}
	for mode in ["summon","elite_summon","transcend"]:
		scene.selected_elite = 1 if mode == "elite_summon" else -1
		scene.transcend_placement = mode == "transcend"
		scene.view.placement.emit(Vector2(1000,1000))
		check(fake.commands.is_empty() and scene.action_notice.text == "용사와 너무 가까움" and scene.view.manual_spawn_warning_timer > 0.0,mode+" close rejected")
		scene.view.placement.emit(Vector2(1300,1000))
		check(fake.commands.size() == 1 and fake.commands[0][0] == mode,mode+" distant sent")
		fake.commands.clear()
	scene.view.pending_textures.clear(); scene.view.motion_paused = true
	scene.view._process(scene.view.battle_constants.MANUAL_SPAWN_WARNING_DURATION)
	check(scene.view.manual_spawn_warning_timer == 0.0 and not scene.view.is_processing(),"warning expires and processing stops")
	scene._event({"op":"action","match":"test","message":"용사와 너무 가까움"})
	check(scene.view.manual_spawn_warning_timer > 0.0,"server rejection shows warning")
	scene.client = original; scene.queue_free()
	print("ONLINE_SPAWN_WARNING_PASS checks=",checks); quit()
