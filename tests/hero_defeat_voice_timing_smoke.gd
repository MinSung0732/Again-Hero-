extends SceneTree
## Real Battle + hero voice player: the defeat line must start at the fatal
## hit (death_started, with the death focus/slow), not after the death
## animation when the battle finishes, and must play exactly once.
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const PROGRESS := preload("res://src/systems/stage_progress.gd")
const VOICE_PATH := "res://src/audio/hero_voice_player.gd"
var checks := 0
var failures := 0


func _initialize() -> void: run.call_deferred()


func expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("DEFEAT_VOICE_FAIL " + label)


func run() -> void:
	root.get_node("CloudStore").stop()
	root.get_node("LoginGateway").remember_session_enabled = false
	SCOPE.guest_directory = "user://defeat_voice_test_" + Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	SCOPE.select_guest()
	root.get_node("AudioSettings").set_sfx_muted(false)
	PROGRESS.set_current_stage("stage_4")
	var battle = load("res://src/battle/Battle.tscn").instantiate()
	root.add_child(battle)
	await battle.prepare_spawn_resources()
	var hero = battle.hero
	var voice = load(VOICE_PATH).new()
	root.add_child(voice)
	voice.install(battle)
	voice.prepare()
	expect(voice.enabled and voice.streams.get(&"defeat") != null, "stage hero has a defeat line")
	var started: Array = []
	voice.cue_started.connect(func(event): started.append([event, battle.battle_over]))
	var finished_at := []
	battle.battle_finished.connect(func(_m, _w): finished_at.append(Time.get_ticks_msec()))

	hero.invulnerability_timer = 0.0
	hero.shield_hp = 0
	hero.take_damage(hero.current_hp + 100000)
	expect(hero.is_dying, "fatal hit starts the death sequence")
	expect(voice.terminal and voice.current_event == &"defeat", "defeat cue requested at death_started")
	expect(not battle.battle_over, "request happens before the battle finishes")
	for frame in 30:
		await process_frame
		if not started.is_empty(): break
	expect(started.size() == 1 and started[0][0] == &"defeat", "defeat line actually starts")
	expect(not started.is_empty() and started[0][1] == false, "line starts while the death focus runs, before the result")

	# The later confirmed outcome must not restart or duplicate the line.
	var position_before: float = voice.player.get_playback_position()
	for frame in 600:
		await process_frame
		if battle.battle_over: break
	expect(battle.battle_over and not finished_at.is_empty(), "battle finishes after the death animation")
	expect(started.size() == 1, "defeat line plays exactly once")
	expect(voice.player.playing and voice.player.get_playback_position() >= position_before, "line keeps playing through the finish")

	voice.queue_free()
	battle.queue_free()
	await process_frame
	if failures == 0:
		print("DEFEAT_VOICE_TIMING_PASS checks=", checks)
		quit(0)
	else:
		print("DEFEAT_VOICE_TIMING_FAIL failures=", failures, " checks=", checks)
		quit(1)
