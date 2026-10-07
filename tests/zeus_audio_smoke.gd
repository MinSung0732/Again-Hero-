extends SceneTree
const AUDIO := preload("res://src/data/zeus_audio_catalog.gd")
const BANK := preload("res://src/audio/event_sfx_bank.gd")
class BattleStub extends Node:
	var battle_over := false
	var external_pause := false
	var demon_augment_selection_active := false
var failed := false
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.get_node("CloudStore").stop()
	root.get_node("LoginGateway").remember_session_enabled = false
	var battle := BattleStub.new()
	root.add_child(battle)
	var bank := BANK.new()
	battle.add_child(bank)
	bank.configure(AUDIO.CUES, battle, true)
	var count := bank.get_child_count()
	for id in bank.players:
		var player: AudioStreamPlayer = bank.players[id]
		check(player.bus == &"SFX" and player.stream is AudioStreamWAV, id+": real WAV on SFX bus")
		check(player.stream.get_length() > 0.2 and player.volume_db <= -7, id+": duration and safe gain")
		check(player.stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, id+": no unintended looping")
	check(is_equal_approx(bank.players.charge.stream.get_length(), 2.0), "charge matches two-second skill")
	check(bank.play_cue("orb") and not bank.play_cue("orb"), "dense absorptions coalesce")
	bank.stop_all()
	Engine.time_scale = 0.25
	check(bank.play_cue("charge") and bank.players.charge.pitch_scale == 0.25, "combat charge follows slowed game clock")
	Engine.time_scale = 1.0
	battle.external_pause = true
	bank._process(0.1)
	check(bank.players.charge.stream_paused and not bank.play_cue("thunder"), "battle menu pauses audio and blocks new cues")
	battle.external_pause = false
	bank._process(0.1)
	check(not bank.players.charge.stream_paused, "audio resumes")
	bank.stop_all()
	for i in range(100):
		bank.play_cue("judgment")
	check(bank.get_child_count() == count and bank.players.judgment.max_polyphony == 1, "fixed bounded players under burst load")
	bank.stop_all()
	for player in bank.players.values():
		check(not player.playing, "cancel/death stops all actor cues")
	# Actual mixer capture; dummy headless audio is unsuitable for waveform assertions.
	if "--mix-capture" in OS.get_cmdline_user_args():
		var bus := AudioServer.get_bus_index(&"SFX")
		var saved_db := AudioServer.get_bus_volume_db(bus)
		var saved_mute := AudioServer.is_bus_mute(bus)
		AudioServer.set_bus_volume_db(bus, 0.0)
		AudioServer.set_bus_mute(bus, false)
		var capture := AudioEffectCapture.new()
		AudioServer.add_bus_effect(bus, capture)
		var effect_index := AudioServer.get_bus_effect_count(bus)-1
		var peak := 0.0
		bank.play_cue("charge")
		bank.play_cue("thunder")
		bank.play_cue("crown")
		bank.play_cue("slash")
		for i in range(30):
			await create_timer(0.03).timeout
			var samples := capture.get_buffer(capture.get_frames_available())
			for sample in samples:
				peak = maxf(peak, maxf(absf(sample.x), absf(sample.y)))
		check(peak > 0.0001 and peak < 1.0, "actual SFX mix emits non-clipping samples")
		print("ZEUS_AUDIO_MIX peak=", peak)
		bank.stop_all()
		AudioServer.remove_bus_effect(bus, effect_index)
		AudioServer.set_bus_volume_db(bus, saved_db)
		AudioServer.set_bus_mute(bus, saved_mute)
	bank.queue_free()
	battle.queue_free()
	await process_frame
	BANK.streams.clear()
	print("ZEUS_AUDIO_SMOKE ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
