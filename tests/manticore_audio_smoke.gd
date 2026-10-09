extends SceneTree
const COMBAT := preload("res://tests/manticore_combat_smoke.gd")
const SCENE := preload("res://src/monsters/Manticore.tscn")
const AUDIO := preload("res://src/data/manticore_audio_catalog.gd")
const CINEMATIC := preload("res://src/data/battle_summon_cinematic_catalog.gd")
const GACHA := preload("res://src/data/transcendent_cutscene_catalog.gd")
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("MANTICORE_AUDIO: "+message)
func run() -> void:
	root.get_node("CloudStore").stop()
	root.get_node("LoginGateway").remember_session_enabled = false
	var authority := COMBAT.Authority.new()
	root.add_child(authority)
	var target := COMBAT.Target.new()
	authority.add_child(target)
	authority.hero = target
	var actor = SCENE.instantiate()
	actor.configure_combat_context(target,authority)
	actor.configure_transcendence(400,1)
	authority.add_child(actor)
	actor.set_physics_process(false)
	var bank = actor.audio_bank
	for cue in AUDIO.CUES:
		var player: AudioStreamPlayer = bank.players[cue]
		check(player.stream is AudioStreamWAV and player.stream.get_length()>0.1,"imported PCM "+cue)
		check(player.bus==&"SFX" and player.max_polyphony==1,"bounded SFX "+cue)
	check(bank.players.size()==12,"fixed voices")
	actor._arrival_explosion()
	check(bank.cooldowns.summon>0,"actual arrival dispatch")
	actor.arrival = 0.0
	target.position = Vector2(100,0)
	actor._tick_motion(0.01)
	check(bank.cooldowns.focus>0,"concentration dispatch")
	actor._tick_motion(1.0)
	check(bank.cooldowns.hunt>0,"guided hunt dispatch")
	actor._tick_motion(1.0)
	var before: int = bank.played_count
	actor._tick_motion(0.01)
	actor._tick_motion(0.12)
	check(bank.played_count==before+3 and bank.cooldowns.retreat>0,"two hit cues then retreat")
	actor.motion = actor.Motion.COMBO
	actor.combo_hits = 0
	actor.combo_timer = 0
	target.reject = true
	before = bank.played_count
	actor._tick_motion(0.01)
	check(bank.played_count==before,"rejected damage produces no hit")
	target.reject = false
	actor.gauge = 100
	actor.cooldowns.fill(0)
	actor._try_cast()
	check(bank.cooldowns.flame_cast>0,"flame creation dispatch")
	target.position = actor._flame_point(0)+Vector2(60,0)
	before = bank.played_count
	actor._tick_flames(0.05)
	actor._tick_flames(0.05)
	check(bank.played_count==before+1,"contact breath shared across damage ticks")
	actor.flame_audio_timer = 0
	target.position = Vector2(3000,0)
	before = bank.played_count
	actor._tick_flames(0.05)
	check(bank.played_count==before,"out of flame range silent")
	target.position = Vector2(100,0)
	actor.gauge = 100
	actor.cooldowns[0] = 60
	actor._try_cast()
	actor._tick_meteors(0.2)
	check(bank.cooldowns.venom_launch>0,"actual meteor spawn dispatch")
	for i in range(10):
		if actor.meteor_state[i]==1: actor.meteor_points[i]=actor.meteor_dest[i]
	actor._tick_meteors(0.01)
	check(bank.cooldowns.venom_impact>0,"actual arrival at destination dispatch")
	before = bank.played_count
	for i in range(10): bank.play_cue("venom_impact")
	check(bank.played_count==before,"cluster impact bounded")
	actor._shoot_wave(Vector2.RIGHT)
	check(bank.cooldowns.wave>0,"one wave launch cue")
	actor.take_damage(actor.current_hp+100)
	check(bank.cooldowns.escape>0,"once lethal escape dispatch")
	bank.stop_all()
	authority.external_pause = true
	check(not bank.play_cue("hunt"),"battle pause blocks cue")
	authority.external_pause = false
	var scale_before := Engine.time_scale
	Engine.time_scale = 0.25
	check(bank.play_cue("hunt") and is_equal_approx(bank.players.hunt.pitch_scale,0.25),"combat slow motion clock")
	Engine.time_scale = scale_before
	bank.stop_all()
	check(CINEMATIC.ENTRIES.manticore.audio_cues==AUDIO.PRESENTATION_CUES,"dedicated cinematic bank")
	check(GACHA.ENTRIES.manticore.impact_sound_path==AUDIO.PRESENTATION_CUES.reveal.path,"dedicated gacha reveal")
	if "--mix-capture" in OS.get_cmdline_user_args():
		var master := AudioServer.get_bus_index(&"Master")
		var sfx := AudioServer.get_bus_index(&"SFX")
		AudioServer.set_bus_volume_db(master,0)
		AudioServer.set_bus_mute(master,false)
		AudioServer.set_bus_volume_db(sfx,0)
		AudioServer.set_bus_mute(sfx,false)
		root.get_node("GameAudio").ui_bank.stop_all()
		var capture := AudioEffectCapture.new()
		capture.buffer_length = 2
		AudioServer.add_bus_effect(master,capture)
		var effect_index := AudioServer.get_bus_effect_count(master)-1
		var peak := 0.0
		var samples := 0
		for iteration in range(5):
			for cue in AUDIO.CUES: bank.play_cue(cue)
			await create_timer(0.2).timeout
			for sample in capture.get_buffer(capture.get_frames_available()):
				peak=maxf(peak,maxf(absf(sample.x),absf(sample.y)))
				samples+=1
		check(peak>0.0001 and peak<0.85,"dense output has headroom")
		print("MANTICORE_AUDIO_MIX peak=",peak," samples=",samples)
		AudioServer.remove_bus_effect(master,effect_index)
	bank.stop_all()
	authority.queue_free()
	await process_frame
	print("MANTICORE_AUDIO: ","PASS" if failures==0 else "FAIL")
	quit(0 if failures==0 else 1)
