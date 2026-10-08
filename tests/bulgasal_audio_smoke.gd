extends SceneTree
const PROFILES := preload("res://src/data/hero_profiles.gd")
const AUDIO := preload("res://src/data/bulgasal_audio_catalog.gd")
const BANK := preload("res://src/audio/event_sfx_bank.gd")
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures+=1
		push_error("BULGASAL_AUDIO: "+message)
func run() -> void:
	root.get_node("CloudStore").stop()
	root.get_node("LoginGateway").remember_session_enabled=false
	var hero = load("res://src/hero/Hero.tscn").instantiate()
	hero.configure_profile(PROFILES.get_profile("archmage_hero"))
	root.add_child(hero)
	hero.set_physics_process(false)
	var player: AudioStreamPlayer=hero.archmage_combustion_release_audio
	check(player.stream is AudioStreamWAV and player.stream.resource_path=="res://assets/audio/sfx/bulgasal/archmage_fire_burst.wav","actual archmage release uses replacement recording")
	check(player.bus==&"SFX" and player.pitch_scale==1.0 and player.volume_db==-12.0,"natural pitch and SFX gain")
	await hero._cast_archmage_combustion({"charge_duration":0.1,"charge_tick_interval":0.05},false)
	check(player.playing and not hero.archmage_casting_sequence,"actual charge-to-burst dispatch starts replacement")
	player.stop()
	var bank = BANK.new()
	root.add_child(bank)
	bank.configure(AUDIO.CUES)
	for cue in AUDIO.CUES:
		check(bank.players[cue].stream is AudioStreamWAV,"imported clip "+cue)
		check(bank.players[cue].bus==&"SFX" and bank.players[cue].max_polyphony==1,"bounded SFX voice "+cue)
	check(bank.play_cue("pillar") and not bank.play_cue("pillar"),"stone batch cooldown")
	bank.stop_all()
	paused=true
	check(not bank.play_cue("land"),"pause blocks new events")
	paused=false
	if "--mix-capture" in OS.get_cmdline_user_args():
		var master := AudioServer.get_bus_index(&"Master")
		var sfx := AudioServer.get_bus_index(&"SFX")
		var settings := [AudioServer.get_bus_volume_db(master),AudioServer.is_bus_mute(master),AudioServer.get_bus_volume_db(sfx),AudioServer.is_bus_mute(sfx)]
		AudioServer.set_bus_volume_db(master,0)
		AudioServer.set_bus_mute(master,false)
		AudioServer.set_bus_volume_db(sfx,0)
		AudioServer.set_bus_mute(sfx,false)
		var capture := AudioEffectCapture.new()
		capture.buffer_length=2
		AudioServer.add_bus_effect(master,capture)
		var effect_index := AudioServer.get_bus_effect_count(master)-1
		var peak := 0.0
		var samples := 0
		for iteration in range(4):
			bank.play_cue("rock")
			bank.play_cue("land")
			bank.play_cue("burrow")
			for index in range(13): bank.play_cue("pillar")
			hero._play_archmage_player(player)
			await create_timer(0.3).timeout
			for sample in capture.get_buffer(capture.get_frames_available()):
				peak=maxf(peak,maxf(absf(sample.x),absf(sample.y)))
				samples+=1
		check(peak>0.0001 and peak<0.85,"dense actual output audible and below clipping")
		print("BULGASAL_AUDIO_MIX peak=",peak," samples=",samples)
		AudioServer.remove_bus_effect(master,effect_index)
		AudioServer.set_bus_volume_db(master,settings[0])
		AudioServer.set_bus_mute(master,settings[1])
		AudioServer.set_bus_volume_db(sfx,settings[2])
		AudioServer.set_bus_mute(sfx,settings[3])
	bank.stop_all()
	for child in hero.get_children():
		if child is AudioStreamPlayer: child.stop()
	hero.queue_free()
	bank.queue_free()
	await process_frame
	print("BULGASAL_AUDIO: ","PASS" if failures==0 else "FAIL"," failures=",failures)
	quit(0 if failures==0 else 1)
