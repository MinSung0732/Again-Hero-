extends SceneTree

const SPOTLIGHT := preload("res://src/ui/tutorial_spotlight.gd")
const CHECKPOINT := preload("res://src/systems/tutorial_checkpoint.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const COLLECTION := preload("res://src/systems/monster_collection_store.gd")
var failed := false

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	if not value:
		failed = true
		push_error("TUTORIAL_FOCUS: " + label)

func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	root.get_node("CloudStore").stop()
	root.get_node("LocalTestMode").active = false
	root.get_node("LocalTestMode").tutorial_preview = false
	var folder := "user://tutorial_focus_" + Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(folder)
	SCOPE.guest_directory = folder
	SCOPE.select_guest()
	var target := Button.new()
	target.position = Vector2(100, 100)
	target.size = Vector2(80, 60)
	root.add_child(target)
	var mask := SPOTLIGHT.new()
	root.add_child(mask)
	await process_frame
	mask.configure([target])
	check(mask.allows(Vector2(120, 120)) and not mask.allows(Vector2(10, 10)), "hole allows only target")
	check(mask._has_point(Vector2(10, 10)) and not mask._has_point(Vector2(120, 120)), "GUI hit testing blocks dim area")
	mask.guard_until = 0
	var event := InputEventScreenTouch.new()
	event.index = 2
	event.pressed = true
	event.position = Vector2(10, 10)
	check(mask.blocks(event), "outside finger blocked")
	event.pressed = false
	event.position = Vector2(120, 120)
	check(mask.blocks(event), "outside press cannot release into allowed target")
	event.pressed = true
	check(not mask.blocks(event), "fresh inside finger allowed")
	event.pressed = false
	check(not mask.blocks(event), "inside release allowed")
	check(mask.blocks(InputEventKey.new()), "keyboard cannot escape tutorial")
	mask.input_locked = true
	check(mask.allows(Vector2(120, 120)) and mask._has_point(Vector2(120, 120)) and mask.blocks(event), "result stays bright but consumes GUI and touch input")
	check(mask.blocks(InputEventJoypadMotion.new()), "result observation blocks gamepad")
	mask.configure([target])
	mask.guard_until = 0
	check(not mask.input_locked and not mask.blocks(event), "next target guide restores allowed input")
	target.hide()
	await process_frame
	check(mask.holes.is_empty(), "hidden target fails closed without stale outline")
	target.show()
	target.position = Vector2(200, 200)
	await process_frame
	check(mask.allows(Vector2(220, 220)) and not mask.allows(Vector2(120, 120)), "layout changes update hole")
	check(CHECKPOINT.save("elite") and CHECKPOINT.read() == "elite", "checkpoint survives reload")
	check(not CHECKPOINT.save("invalid") and CHECKPOINT.read() == "elite", "invalid checkpoint rejected")
	var progress := ConfigFile.new()
	SCOPE.load_config(progress, CHECKPOINT.PATH)
	progress.set_value("meta", "gold", 1000)
	SCOPE.save_config(progress, CHECKPOINT.PATH)
	check(CHECKPOINT.save("shop"), "shop checkpoint")
	var result := COLLECTION.award_shard_batch([{"monster_id": "slime", "shards": 2}], 1000, true)
	check(result.success and CHECKPOINT.read() == "draw_done", "purchase saves completion with shards")
	SCOPE.load_config(progress, CHECKPOINT.PATH)
	check(progress.get_value("meta", "gold") == 0, "same transaction charges once")
	result = COLLECTION.award_shard_batch([{"monster_id": "slime", "shards": 2}], 1000, true)
	check(not result.success and CHECKPOINT.read() == "draw_done", "insufficient retry cannot award or erase completion")
	check(CHECKPOINT.save("done") and CHECKPOINT.read() == "done", "final completion persisted")
	# Delayed callbacks must not open a stale result on a replacement host.
	var hex := Crypto.new().generate_random_bytes(16).hex_encode()
	var owner := "%s-%s-%s-%s-%s" % [hex.substr(0,8),hex.substr(8,4),hex.substr(12,4),hex.substr(16,4),hex.substr(20,12)]
	check(SCOPE.select_account(owner), "isolated active account for cancellation")
	var flow := root.get_node("TutorialFlow")
	flow.account_owner = owner
	flow.status = "active"
	check(flow.active(), "cancellation fixture is active")
	var old_host := Control.new()
	root.add_child(old_host)
	var result_target := Control.new()
	old_host.add_child(result_target)
	flow.bind_host(old_host)
	flow.advance("augment", "old result", Callable(), result_target)
	check(CHECKPOINT.read() == "augment", "checkpoint precedes observation timer")
	var replacement := Control.new()
	root.add_child(replacement)
	flow.bind_host(replacement)
	flow.show_modal("replacement", "new scene", "OK", Callable())
	old_host.queue_free()
	await create_timer(2.1).timeout
	check(flow.title.text == "replacement", "old result timer cannot replace new scene guide")
	SCOPE.select_guest()
	print("TUTORIAL_FOCUS: " + ("FAILED" if failed else "OK"))
	quit(1 if failed else 0)
