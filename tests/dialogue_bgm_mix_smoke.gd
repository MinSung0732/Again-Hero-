extends SceneTree

const DATA := preload("res://src/data/game_audio_catalog.gd")
var checks := 0
var failed := false
func _initialize(): run.call_deferred()
func check(ok: bool, message: String):
	checks += 1
	if not ok:
		failed = true
		push_error(message)
func window(audio, owner, capture: AudioEffectCapture, gain: float) -> float:
	audio.stop_dialogue_bgm(owner)
	audio.play_dialogue_bgm(owner)
	audio.music.volume_db = gain
	# Retire old mixer frames, then capture the same early part of the real WAV.
	await create_timer(0.12).timeout
	capture.clear_buffer()
	await create_timer(0.32).timeout
	var frames := capture.get_buffer(capture.get_frames_available())
	check(not frames.is_empty(), "real mixer output frames")
	var energy := 0.0
	for frame in frames: energy += frame.length_squared()
	return sqrt(energy / maxf(float(frames.size()) * 2.0, 1.0))
func run():
	var audio = root.get_node("GameAudio")
	var settings = root.get_node("AudioSettings")
	settings.config_path = "user://dialogue_mix_fixture.cfg"
	settings.set_bgm_level(settings.DEFAULT_LEVEL)
	settings.set_bgm_muted(false)
	var bgm := AudioServer.get_bus_index(&"BGM")
	var master := AudioServer.get_bus_index(&"Master")
	var capture := AudioEffectCapture.new()
	capture.buffer_length = 1.0
	AudioServer.add_bus_effect(master, capture)
	var owner := Node.new(); root.add_child(owner)
	var user_gain := AudioServer.get_bus_volume_db(bgm)
	check(is_equal_approx(float(DATA.DIALOGUE_BGM.db) - float(DATA.FRONTEND_DB.lobby), DATA.DIALOGUE_BGM_LOBBY_OFFSET_DB), "dialogue derives its gain from lobby reference")
	# Historical faulty mix is a test baseline, never a runtime fallback.
	var before: float = await window(audio, owner, capture, -20.0)
	var after: float = await window(audio, owner, capture, float(DATA.DIALOGUE_BGM.db))
	check(before > 0.0 and after > before * 3.0, "fixed output is materially stronger than old -20dB mix")
	check(is_equal_approx(AudioServer.get_bus_volume_db(bgm), user_gain), "user BGM gain preserved")
	settings.set_bgm_muted(true)
	var muted: float = await window(audio, owner, capture, float(DATA.DIALOGUE_BGM.db))
	check(muted < after * 0.001, "user mute still silences the real output")
	settings.set_bgm_muted(false)
	audio.music.stop(); audio.music.stream = null
	AudioServer.remove_bus_effect(master, AudioServer.get_bus_effect_count(master)-1)
	owner.queue_free()
	await create_timer(0.15).timeout
	print("DIALOGUE_BGM_MIX checks=%d before_rms=%.8f after_rms=%.8f muted_rms=%.8f gain_db=%.2f %s" % [checks, before, after, muted, linear_to_db(after / maxf(before, 0.000000001)), "FAIL" if failed else "PASS"])
	quit(1 if failed else 0)
