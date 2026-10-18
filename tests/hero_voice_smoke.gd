extends Node
@onready var root = get_tree().root
const VOICE = preload("res://src/audio/hero_voice_player.gd")
const DATA = preload("res://src/data/hero_voice_catalog.gd")
const CHARACTERS = preload("res://src/data/hero_character_catalog.gd")
const BATTLE = preload("res://battle_fixture.gd")
var checks := 0
var failures := 0
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	run.call_deferred()
func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func wait_real(seconds: float):
	await get_tree().create_timer(seconds, true, false, true).timeout
func voice_for(battle):
	var node = VOICE.new(); root.add_child(node); node.install(battle); node.prepare()
	return node
func battle_for(id: String):
	var battle = BATTLE.new(); root.add_child(battle); battle.current_hero_profile.id = id
	return battle
func run():
	AudioSettings.config_path = "user://voice_fixture_settings.cfg"
	AudioSettings.set_sfx_muted(false)
	AudioSettings.set_sfx_level(5)
	var bgm := AudioServer.get_bus_index(&"BGM")
	var sfx := AudioServer.get_bus_index(&"SFX")
	var vb := AudioServer.get_bus_index(AudioSettings.VOICE_BUS)
	var bgm_effects := AudioServer.get_bus_effect_count(bgm)
	var sfx_effects := AudioServer.get_bus_effect_count(sfx)
	var paths: Dictionary = {}
	for id in CHARACTERS.ORDER:
		var battle = battle_for(id)
		var voice = voice_for(battle)
		check(voice.hero_id == id and voice.streams.size() == 4, "identity/cache")
		for event in DATA.EVENTS:
			var path := DATA.path_for(id, event)
			if path.is_empty():
				check(event == &"unlock" and voice.streams[event] == null, "optional unlock silence")
				continue
			paths[path] = true
			var stream = voice.streams[event]
			check(stream is AudioStreamWAV and stream.get_length() > 0.0, "real WAV imported " + path)
			check(stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "one-shot")
			voice._request(event, String(event))
			if event == &"defeat": await wait_real(0.12)
			check(voice.player.playing and voice.player.pitch_scale == 1.0, "actual audio player " + String(event))
			voice.stop()
		voice.free(); battle.free()
	check(paths.size() == 33, "all 33 WAVs covered")
	check(DATA.path_for("unregistered", &"entry").is_empty(), "unknown identity fails soft")
	var battle = battle_for("summoner_hero")
	var voice = voice_for(battle)
	var player_id = voice.player.get_instance_id()
	var counts := {"entry": 0, "unlock": 0, "defeat": 0, "victory": 0}
	voice.cue_started.connect(func(event): counts[String(event)] += 1)
	check(voice.play_entry() and not voice.play_entry(), "entry one receipt")
	check(voice.play_unlock("gate") and not voice.play_unlock("gate"), "unlock interrupts entry once")
	await wait_real(0.12)
	check(is_equal_approx(voice.duck_effects[&"BGM"].volume_db, float(DATA.DUCK_DB[&"BGM"])), "BGM duck effect")
	check(is_equal_approx(voice.duck_effects[&"SFX"].volume_db, float(DATA.DUCK_DB[&"SFX"])), "SFX duck effect")
	check(AudioServer.get_bus_effect_count(vb) == 0, "voice bypasses duck")
	AudioSettings.set_bgm_level(8); AudioSettings.set_sfx_level(7)
	check(is_equal_approx(AudioServer.get_bus_volume_db(sfx), AudioServer.get_bus_volume_db(vb)), "voice follows slider while ducked")
	var user_bgm := AudioServer.get_bus_volume_db(bgm)
	var user_sfx := AudioServer.get_bus_volume_db(sfx)
	Engine.time_scale = 0.05
	battle._finish_battle("fixture death", true, &"defeat")
	check(voice.terminal and voice.delay.time_left > 0.0, "confirmed result supersedes unlock")
	await wait_real(0.14)
	check(counts.defeat == 1 and voice.player.playing and voice.player.pitch_scale == 1.0, "delay ignores slow motion")
	battle._finish_battle("late timeout", false, &"victory")
	voice._on_outcome(&"victory")
	check(counts.victory == 0 and not voice.play_entry() and not voice.play_unlock("other"), "first terminal outcome only")
	check(voice.player.get_instance_id() == player_id, "one retained player")
	Engine.time_scale = 1.0
	get_tree().paused = true
	await wait_real(0.04)
	check(voice.player.stream_paused, "tree pause")
	get_tree().paused = false
	await wait_real(0.04)
	check(not voice.player.stream_paused, "tree resume")
	voice._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(voice.player.stream_paused, "background pause")
	voice._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	check(not voice.player.stream_paused, "foreground resume")
	AudioSettings.set_sfx_muted(true)
	check(not voice.player.playing and AudioServer.is_bus_mute(vb), "mute stops active voice")
	AudioSettings.set_sfx_muted(false)
	check(not voice.player.playing, "unmute never replays old cue")
	await wait_real(0.28)
	check(is_zero_approx(voice.duck_effects[&"BGM"].volume_db), "release restores neutral effect")
	check(is_equal_approx(AudioServer.get_bus_volume_db(bgm), user_bgm) and is_equal_approx(AudioServer.get_bus_volume_db(sfx), user_sfx), "settings preserved through release")
	voice.free(); battle.free()
	check(AudioServer.get_bus_effect_count(bgm) == bgm_effects and AudioServer.get_bus_effect_count(sfx) == sfx_effects, "scene exit removes only owned effects")
	# Whole result owners: both roles, protected modes, abandonment and race order.
	for mode in ["demon", "hero", "online", "practice", "tutorial"]:
		for death_first in [false, true]:
			battle = battle_for("ranged_rookie")
			battle.hero_player_mode = mode == "hero"
			battle.online_match_mode = mode == "online"
			battle.practice_mode = mode == "practice"
			battle.tutorial_mode = mode == "tutorial"
			var outcomes: Array = []; var results: Array = []
			battle.hero_outcome_confirmed.connect(func(outcome): outcomes.append(outcome))
			battle.battle_finished.connect(func(_message, won): results.append(won))
			if death_first: battle._on_hero_died(); battle._on_run_time_up()
			else: battle._on_run_time_up(); battle._on_hero_died()
			if mode in ["practice", "tutorial"]:
				check(outcomes.is_empty() and results.is_empty(), "protected mode")
			else:
				var expected: StringName = &"defeat" if death_first or mode == "hero" else &"victory"
				check(outcomes == [expected] and results.size() == 1 and battle.pause_syncs == 1, "race/mode " + mode)
			battle.free()
	for boss_won in [false, true]:
		battle = battle_for("sage_astra"); battle.hero_player_mode = true; battle.hero.current_hp = 10
		var outcomes: Array = []
		battle.hero_outcome_confirmed.connect(func(outcome): outcomes.append(outcome))
		if boss_won: battle._finish_hero_boss_victory()
		else: battle.finish_hero_boss_timeout()
		check(outcomes == ([&"victory"] if boss_won else [&"defeat"]), "hero boss outcome perspective")
		battle.free()
	for hero_mode in [false, true]:
		battle = battle_for("ranged_rookie"); battle.hero_player_mode = hero_mode
		voice = voice_for(battle); voice.play_entry()
		check(battle.finish_abandoned_run() and voice.terminal and not voice.player.playing, "abandon silent")
		voice.free(); battle.free()
	# Missing pack, disabled training and missing stream never block gameplay.
	battle = battle_for("unknown"); voice = voice_for(battle)
	check(not voice.play_entry() and not voice.play_unlock("skill"), "missing pack")
	voice.free(); battle.free()
	battle = battle_for("ranged_rookie"); battle.practice_mode = true; voice = voice_for(battle)
	check(not voice.play_entry() and voice.streams.is_empty(), "practice no loading or speech")
	voice.free(); battle.free()
	# Real UI timelines with synthetic artwork; signals come from the actual owners.
	battle = battle_for("summoner_hero"); voice = voice_for(battle)
	var hooks = load("res://main_hooks.gd").new(); root.add_child(hooks); hooks.hero_voice = voice
	var entry_cues := {"count": 0}
	voice.cue_started.connect(func(event):
		if event == &"entry": entry_cues.count += 1)
	var reveal = load("res://src/ui/HeroRevealCutscene.tscn").instantiate(); root.add_child(reveal)
	var entry_state := {"seen": false, "value": 0.0, "visible": false}
	reveal.battle_ready.connect(func():
		entry_state.seen = true; entry_state.value = reveal.loading_progress.value; entry_state.visible = reveal.visible
		voice.play_entry())
	reveal.finished.connect(hooks._on_hero_reveal_finished)
	reveal.play_reveal({"stage_id": "stage_8", "portrait_path": "res://fixture_texture.tres"})
	await reveal.finished
	check(entry_state.seen and entry_state.value == 100.0 and entry_state.visible and voice.player.playing, "entry after loading and across reveal outro")
	check(hooks.battle_started and hooks._stage_intro_stage_id.is_empty() and entry_cues.count == 1, "actual Main handoff never replays entry")
	reveal.queue_free()
	await get_tree().process_frame
	var cutscene = load("res://src/ui/SkillUnlockCutscene.tscn").instantiate(); root.add_child(cutscene)
	var cutscene_state := {"seen": false, "visible": false, "alpha": 0.0, "progress": 0.0}
	cutscene.artwork_revealed.connect(func(data):
		cutscene_state.seen = true; cutscene_state.visible = cutscene.visible
		cutscene_state.alpha = cutscene.root.modulate.a
		cutscene_state.progress = cutscene._art_material.get_shader_parameter("reveal_progress")
		check(data.skill_id == "gate", "payload identity preserved"))
	cutscene.artwork_revealed.connect(hooks._on_skill_artwork_revealed)
	cutscene.play_unlock({"skill_id": "gate", "cutscene_texture_path": "res://fixture_texture.tres", "cutscene_hold_seconds": 0.35})
	await cutscene.finished
	check(cutscene_state.seen and cutscene_state.visible and is_equal_approx(cutscene_state.alpha, 1.0) and is_equal_approx(cutscene_state.progress, 1.0), "unlock begins at filled artwork")
	check(voice.player.playing, "unlock voice survives cutscene outro")
	cutscene_state.seen = false
	cutscene.play_unlock({"cutscene_texture_path": "res://missing.tres"})
	check(not cutscene_state.seen and not cutscene._active, "missing artwork no voice signal")
	cutscene.queue_free(); hooks.free(); voice.free(); battle.free()
	await get_tree().process_frame
	# Natural completion releases ducking without a presentation wait.
	battle = battle_for("ranged_rookie"); voice = voice_for(battle)
	var short_stream := AudioStreamWAV.new(); short_stream.format = AudioStreamWAV.FORMAT_8_BITS; short_stream.mix_rate = 8000
	var samples := PackedByteArray(); samples.resize(400); short_stream.data = samples
	voice.streams[&"entry"] = short_stream
	Engine.time_scale = 0.05
	check(voice.play_entry(), "natural completion starts")
	await wait_real(0.55)
	check(voice.current_event == &"" and not voice.player.playing and is_zero_approx(voice.duck_effects[&"BGM"].volume_db), "natural finish ignores slow motion and releases duck")
	Engine.time_scale = 1.0
	voice.free(); battle.free()
	print("HERO_VOICE checks=%d failures=%d real_wavs=%d" % [checks, failures, paths.size()])
	get_tree().quit(1 if failures else 0)
