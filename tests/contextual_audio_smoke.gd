extends SceneTree
const DATA := preload("res://src/data/contextual_audio_catalog.gd")
const PROFILES := preload("res://src/data/hero_profiles.gd")
const STAGES := preload("res://src/data/stage_catalog.gd")
var failed := false
var actors: Array[Node] = []
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("CONTEXT_AUDIO: "+message)
func _initialize() -> void:
	call_deferred("run")
func stop_players(actor: Node) -> void:
	for child in actor.get_children():
		if child is AudioStreamPlayer:
			child.stop()
func reset_hit(actor: Node) -> void:
	stop_players(actor)
	actor.contextual_hit_next_ms = 0
	actor.invulnerability_timer = 0
	actor.shield_hp = 0
	actor.fighter_guard_active = false
	actor.current_hp = 10000
	actor.max_hp = 10000
func player_count(actor: Node) -> int:
	var count := 0
	for child in actor.get_children():
		if child is AudioStreamPlayer:
			count += 1
	return count
func run() -> void:
	root.get_node("CloudStore").stop()
	root.get_node("LoginGateway").remember_session_enabled = false
	var audio = root.get_node("GameAudio")
	for stage in STAGES.ORDER.slice(0,6):
		var actor = load("res://src/hero/Hero.tscn").instantiate()
		actor.configure_profile(PROFILES.get_profile(STAGES.STAGES[stage].hero_id))
		root.add_child(actor)
		actor.set_physics_process(false)
		actors.append(actor)
		reset_hit(actor)
		var cue: Dictionary = DATA.HITS[actor.hero_archetype]
		var player: AudioStreamPlayer = actor.get(String(cue.player))
		check(player.stream is AudioStreamWAV and player.stream.resource_path == DATA.ROOT+String(cue.file),stage+": body hit is its own recording")
		check(player.bus == &"SFX" and player.pitch_scale == 1.0 and player.max_polyphony == 1,stage+": natural pitch, fixed voice, independent SFX")
		var children: int = player_count(actor)
		check(actor.take_damage(5) and player.playing,stage+": actual damage dispatch plays body hit")
		var deadline: int = actor.contextual_hit_next_ms
		actor.take_followup_damage(5)
		check(actor.contextual_hit_next_ms == deadline and player_count(actor) == children,stage+": rapid hits neither restart nor allocate")
		reset_hit(actor)
		actor.take_status_damage(5)
		check(not player.playing,stage+": poison/status damage has no collision sound")
		reset_hit(actor)
		actor.invulnerability_timer = 1
		check(not actor.take_damage(5) and not player.playing,stage+": rejected invulnerable hit stays silent")
		if actor.hero_archetype == "sword_shield":
			reset_hit(actor)
			actor.fighter_guard_active = true
			check(actor.take_damage(5) and actor.fighter_block_audio.playing and not player.playing,"physical guard uses shield instead of body")
		elif actor.hero_archetype in ["ranged_kiter","archmage_elementalist"]:
			reset_hit(actor)
			actor.shield_hp = 1
			check(actor.take_damage(5) and actor.magic_block_audio.playing and not player.playing,"breaking magical shield retains pre-impact material")
		if actor.hero_archetype == "pistol_gunner":
			actor._start_gunner_deadeye()
			check(actor.gunner_deadeye_start_audio.playing and actor.gunner_deadeye_start_audio.stream.resource_path == DATA.ROOT+"deadeye_cock.wav","actual Deadeye start uses mechanical cock instead of sword")
			actor._play_gunner_basic_shot_audio()
			check(actor.gunner_shot_audio_pool[0].stream.resource_path == DATA.ROOT+"gunner_shot.wav" and actor.gunner_shot_audio_pool[0].pitch_scale == 1.0,"pistol fires actual gunshot at natural pitch")
			actor._play_gunner_deadeye_shot_audio()
			check(actor.gunner_deadeye_shot_audio_pool[0].stream.get_length() <= .17 and actor.gunner_deadeye_shot_audio_pool[0].pitch_scale == 1.0,"rapid shot has independent short recording")
		if actor.hero_archetype == "berserker_madness":
			actor._start_berserker_madness()
			check(actor.berserker_madness_roar_audio.playing,"actual madness entry starts the vocal cue")
			check(actor.berserker_madness_roar_audio.stream.resource_path == DATA.ROOT+"berserker_roar.wav" and actor.berserker_madness_roar_audio.pitch_scale == 1.0,"madness has real restrained voice, not lowered portal")
		stop_players(actor)
	check(audio.ui_bank.players.upgrade.stream != audio.ui_bank.players.demon_level.stream and audio.ui_bank.players.formation.stream != audio.ui_bank.players.victory.stream,"growth, level, formation and result are different sources")
	audio.ui_bank.stop_all()
	audio.last_demon_level = 1
	var count: int = audio.ui_bank.played_count
	audio._demon_progression(2,0,100)
	check(audio.ui_bank.players.demon_level.playing and audio.ui_bank.played_count == count+1,"one actual level increase produces one level cue")
	audio._demon_progression(2,10,100)
	check(audio.ui_bank.played_count == count+1,"ordinary EXP progress doesn't play level cue")
	audio.feedback("denied")
	audio.feedback("defeat")
	check(audio.ui_bank.played_count == count+1,"out-of-theme negative jingles deliberately omitted")
	if "--mix-capture" in OS.get_cmdline_user_args():
		var bus := AudioServer.get_bus_index(&"Master")
		var saved_db := AudioServer.get_bus_volume_db(bus)
		var saved_mute := AudioServer.is_bus_mute(bus)
		AudioServer.set_bus_volume_db(bus,0)
		AudioServer.set_bus_mute(bus,false)
		var other_settings: Array = []
		for bus_name in [&"SFX", &"BGM"]:
			var other_bus := AudioServer.get_bus_index(bus_name)
			other_settings.append([other_bus,AudioServer.get_bus_volume_db(other_bus),AudioServer.is_bus_mute(other_bus)])
			AudioServer.set_bus_volume_db(other_bus,0)
			AudioServer.set_bus_mute(other_bus,false)
		var capture := AudioEffectCapture.new()
		AudioServer.add_bus_effect(bus,capture)
		var index := AudioServer.get_bus_effect_count(bus)-1
		var peak := 0.0
		# Simultaneous actual stage events plus 12.5 shots/sec stress the bounded pool.
		for actor in actors:
			reset_hit(actor)
			actor.take_damage(5)
		actors[0]._play_stage1_audio(&"basic")
		actors[2]._play_fighter_slash_audio()
		audio.enter_frontend(actors[0],"lobby")
		audio.feedback("upgrade")
		for i in range(12):
			actors[3]._play_gunner_deadeye_shot_audio()
			await create_timer(.08).timeout
			for sample in capture.get_buffer(capture.get_frames_available()):
				peak = maxf(peak,maxf(absf(sample.x),absf(sample.y)))
		check(peak>0.0001 and peak<1,"actual dense SFX output nonzero and unclipped")
		print("CONTEXT_AUDIO_MIX peak=",peak)
		AudioServer.remove_bus_effect(bus,index)
		AudioServer.set_bus_volume_db(bus,saved_db)
		AudioServer.set_bus_mute(bus,saved_mute)
		for setting in other_settings:
			AudioServer.set_bus_volume_db(setting[0],setting[1])
			AudioServer.set_bus_mute(setting[0],setting[2])
	for actor in actors:
		actor.queue_free()
	audio.ui_bank.stop_all()
	await process_frame
	print("CONTEXT_AUDIO_SMOKE ","FAIL" if failed else "PASS")
	quit(1 if failed else 0)
