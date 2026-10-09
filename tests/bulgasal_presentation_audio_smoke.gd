extends SceneTree
const PLAYER := preload("res://src/ui/transcendent_cutscene_player.gd")
const CINEMATIC := preload("res://src/ui/battle_summon_cinematic.gd")
const BANK := preload("res://src/audio/event_sfx_bank.gd")
const AUDIO := preload("res://src/data/bulgasal_audio_catalog.gd")
const CATALOG := preload("res://src/data/battle_summon_cinematic_catalog.gd")
func _initialize() -> void: run.call_deferred()
func run() -> void:
	if root.has_node("CloudStore"): root.get_node("CloudStore").stop()
	if root.has_node("LoginGateway"): root.get_node("LoginGateway").remember_session_enabled=false
	if AudioServer.get_bus_index(&"SFX")<0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count-1,&"SFX")
	var player := PLAYER.new()
	root.add_child(player)
	var finished := [0]
	player.finished.connect(func():finished[0]+=1)
	for mode in ["normal","skip","cancel"]:
		player.play("bulgasal")
		player.set_process(false)
		assert(player._running and player._charge_sound.stream is AudioStreamWAV and player._impact_sound.stream is AudioStreamWAV)
		player.advance(1.74)
		assert(not player._charge_played and not player._impact_played)
		player.advance(0.02)
		assert(player._charge_played and player._charge_sound.playing)
		player.advance(0.55)
		assert(player._impact_played and player._impact_sound.playing and not player._charge_sound.playing)
		player.advance(0.1)
		assert(player._charge_sound.bus==&"SFX" and player._impact_sound.volume_db==-12.0)
		match mode:
			"normal": player.advance(5.0)
			"skip": player.skip()
			"cancel": player.cancel()
		assert(not player._running and not player._charge_sound.playing and not player._impact_sound.playing)
	assert(finished[0]==2)
	var bank := BANK.new()
	root.add_child(bank)
	bank.configure(CATALOG.ENTRIES.bulgasal.audio_cues)
	assert(bank.players.size()==2 and not bank.scaled_clock)
	var controller := CINEMATIC.new()
	root.add_child(controller)
	controller.set_process(false)
	controller.sound_bank = bank
	controller.audio_timeline = CATALOG.ENTRIES.bulgasal.audio_timeline
	controller.elapsed = 0.24
	controller._advance_audio()
	assert(bank.played_count==0)
	controller.elapsed = 0.25
	controller._advance_audio()
	assert(bank.played_count==1 and bank.players.rumble.playing)
	controller.elapsed = 1.8
	controller._advance_audio()
	assert(bank.played_count==2 and bank.players.reveal.playing and not bank.players.rumble.playing)
	controller._advance_audio()
	assert(bank.played_count==2)
	assert(bank.players.reveal.pitch_scale==1.0 and bank.players.reveal.bus==&"SFX")
	controller.cancel()
	assert(not bank.players.reveal.playing and not bank.players.rumble.playing)
	# Conservative sum of clip peaks, including actual land and a pillar batch.
	var upper := 0.0
	for cue in [AUDIO.PRESENTATION_CUES.rumble,AUDIO.PRESENTATION_CUES.reveal,AUDIO.CUES.land,AUDIO.CUES.pillar]:
		upper += db_to_linear(-6.0+float(cue.db))
	assert(upper<0.5)
	controller.free()
	bank.free()
	player.free()
	print("BULGASAL_PRESENTATION_AUDIO: PASS (timelines/reuse/skip/cancel/SFX/real-time pitch/bounded peak)")
	quit()
