extends SceneTree
const ROOM := preload("res://src/online/battle_room.gd")
const WIRE := preload("res://src/online/hero_cooldown_wire.gd")
const RULES := preload("res://src/online/match_rules.gd")
const FEEDBACK := preload("res://src/data/online_feedback_catalog.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.get_node("CloudStore").stop()
	check(RULES.VERSION==27, "protocol 25")
	for path in ["res://src/ui/hero_skill_cooldown_bar.gd", "res://src/ui/hero_level_up_effect.gd", "res://src/online/hero_cooldown_wire.gd", "res://src/online/match_scene.gd", "res://src/online/battle_room.gd", "res://src/online/combat_feedback.gd", "res://src/online/battle_view.gd", "res://src/online/match_server.gd", "res://src/online/match_rules.gd", "res://src/data/online_feedback_catalog.gd", "res://src/main/main.gd", "res://src/hero/hero.gd"]:
		check(load(path) != null, "load " + path)
	for path in ["res://src/main/Main.tscn", "res://src/hero_mode/HeroMode.tscn", "res://src/online/OnlineMatch.tscn"]:
		var packed := load(path) as PackedScene
		check(packed != null and packed.can_instantiate(), "can instantiate " + path)
		if packed != null and packed.can_instantiate():
			var instance := packed.instantiate(); check(instance != null, "instantiate " + path); instance.free()
	var room := ROOM.new(); root.add_child(room); room.prepare(); room.start()
	var state: Dictionary = room.snapshot()
	check(not state.has("hero_skill_cooldowns"), "match snapshot omits AI cooldowns")
	check(JSON.stringify(state).to_utf8_buffer().size() <= RULES.MAX_SNAPSHOT, "snapshot fits MAX_SNAPSHOT")
	for role in ["demon", "hero"]:
		root.get_node("SceneTransition")._entry_options = {"role":role}
		var online = load("res://src/online/OnlineMatch.tscn").instantiate(); root.add_child(online)
		check(online.find_child("HeroSkillCooldownBar",true,false) == null, role + " has no AI cooldown bar")
		online.free()
	var solo = load("res://src/main/Main.tscn").instantiate()
	check(solo.get_node_or_null("HUD/HeroSkillCooldownBar") != null, "solo demon keeps cooldown bar")
	solo.free()
	var before: int = room.feedback.sequence
	room.battle.hero.gain_exp(400)
	var events: Array = room.feedback.snapshot(before)
	var levels := 0
	for row in events:
		if row[2] == "level_up": levels += 1
	check(levels > 0 and FEEDBACK.valid_events(events, room.feedback.sequence, room.tick), "level-up event round trip")
	var view = preload("res://src/online/battle_view.gd").new(); root.add_child(view)
	view.feedback.reset(before); view.feedback.suspended = false
	check(view.feedback.consume(events, room.feedback.sequence, room.tick), "client accepts level-up event")
	var accepted: int = view.feedback.accepted
	view.feedback.consume(events, room.feedback.sequence, room.tick)
	check(view.feedback.accepted == accepted, "replayed level-up is ignored")
	view.free()
	var match_scene = load("res://src/online/OnlineMatch.tscn").instantiate(); root.add_child(match_scene)
	match_scene.client.match_id = "stage3-test"
	match_scene.matched_hero_id = room.hero_id
	match_scene._event({"op":"result", "match":"stage3-test", "winner":"demon", "reason":"hero_died"})
	check(match_scene.ended and match_scene.result_pending and match_scene.result_wait_seconds >= 2.8, "result waits for presentation")
	check(match_scene.movement == Vector2.ZERO and (match_scene.pad == null or not match_scene.pad.enabled), "input blocked during result wait")
	match_scene._event({"op":"result", "match":"stage3-test", "winner":"hero", "reason":"duplicate"})
	check(match_scene.result_pending and match_scene.status.text.find("대전 종료") < 0, "duplicate result ignored and screen delayed")
	await create_timer(match_scene.result_wait_seconds + 0.15, true, false, true).timeout
	check(not match_scene.result_pending and match_scene.status.text.find("대전 종료") >= 0, "result visible after voice and focus")
	match_scene.free()
	for player in room.find_children("*", "AudioStreamPlayer", true, false): player.stop(); player.stream = null
	room.free()
	print("ONLINE_STAGE3_PRESENTATION checks=", checks, " failures=", failures, " snapshot_bytes=", JSON.stringify(state).to_utf8_buffer().size())
	quit(1 if failures else 0)
