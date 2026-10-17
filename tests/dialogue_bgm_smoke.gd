extends SceneTree

const DATA := preload("res://src/data/game_audio_catalog.gd")
const DIALOGUES := preload("res://src/data/stage_intro_dialogues.gd")
var checks := 0
var failed := false

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failed = true
		push_error(message)

func run() -> void:
	var audio = root.get_node("GameAudio")
	var owner := Node.new()
	root.add_child(owner)
	audio.enter_frontend(owner, "lobby")
	await create_timer(0.15).timeout
	var position: float = audio.music.get_playback_position()
	audio.enter_frontend(owner, "title")
	check(audio.music.get_playback_position() >= position, "frontend continues between contexts")
	var shared_player: AudioStreamPlayer = audio.music
	audio.play_dialogue_bgm(owner)
	check(audio.music == shared_player and audio.music.bus == &"BGM", "dialogue reuses common BGM player/bus")
	check(audio.music.stream is AudioStreamWAV and audio.music.stream.get_length() > 180.0, "real dialogue WAV loaded")
	check(audio.music.stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "one shot with looping disabled")
	check(audio.music.get_playback_position() < 0.1, "new cutscene starts at zero")
	check(is_equal_approx(audio.music.volume_db, float(DATA.DIALOGUE_BGM.db)), "catalog volume applied")
	await create_timer(0.2).timeout
	position = audio.music.get_playback_position()
	audio.play_dialogue_bgm(owner)
	check(audio.music.get_playback_position() >= position, "same owner cannot restart track")
	# Natural end is distinct from ending the cutscene; a page cannot restart it.
	audio.music.seek(audio.music.stream.get_length()-0.05)
	await create_timer(0.3).timeout
	check(not audio.music.playing and audio.music_mode == "dialogue", "natural song end leaves dialogue ownership")
	audio.play_dialogue_bgm(owner)
	check(not audio.music.playing, "finished one-shot stays silent on repeated call")
	audio.stop_dialogue_bgm(owner)
	audio.play_dialogue_bgm(owner)
	check(audio.music.playing and audio.music.get_playback_position() < 0.1, "new cutscene replays from zero")
	paused = true
	await process_frame
	await process_frame
	check(audio.music.stream_paused, "tree pause uses existing BGM policy")
	paused = false
	audio._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	await process_frame
	await process_frame
	check(audio.music.stream_paused, "background pause uses existing BGM policy")
	audio._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	await process_frame
	await process_frame
	check(not audio.music.stream_paused, "resume releases BGM pause")
	var bus := AudioServer.get_bus_index(&"BGM")
	AudioServer.set_bus_mute(bus, true)
	audio.stop_dialogue_bgm(owner)
	check(audio.music.playing, "ending cutscene does not abruptly stop music")
	await create_timer(0.45).timeout
	check(audio.music.playing and audio.music.volume_db < float(DATA.DIALOGUE_BGM.db), "fade decreases gain before stopping")
	await create_timer(0.7).timeout
	check(not audio.music.playing, "fade stops after configured one second")
	check(AudioServer.is_bus_mute(bus), "fade does not overwrite user mute")
	AudioServer.set_bus_mute(bus, false)
	audio.play_dialogue_bgm(owner)
	audio.stop_dialogue_bgm(owner)
	var next_owner := Node.new()
	root.add_child(next_owner)
	audio.enter_frontend(next_owner, "lobby")
	check(audio.music.stream == audio.frontend_stream and audio.music.stream.loop, "return restores frontend loop")
	audio.stop_dialogue_bgm(owner)
	await create_timer(1.1).timeout
	check(audio.music.playing and audio.music_mode == "lobby", "old cutscene/fade cannot stop next scene BGM")
	# Actual shared cutscene scene: every stage, pages, skip and tree removal.
	var packed := load("res://src/ui/StageIntroCutscene.tscn") as PackedScene
	var cutscene = packed.instantiate()
	root.add_child(cutscene)
	for number in range(1, 11):
		var dialogue := DIALOGUES.get_dialogue("stage_%d" % number)
		cutscene.play_dialogue(dialogue)
		await process_frame
		check(audio.music_mode == "dialogue" and audio.music.playing, "stage %d starts dialogue music" % number)
		await create_timer(0.13).timeout
		position = audio.music.get_playback_position()
		cutscene._advance()
		check(audio.music.get_playback_position() >= position, "stage %d page keeps playback" % number)
		cutscene._finish(number % 2 == 0)
		check(audio.music_mode == "" and audio.music.playing, "stage %d end/skip starts fade" % number)
	# Stale cleanup after a new owner's start must be ignored.
	cutscene.play_dialogue(DIALOGUES.get_dialogue("stage_1"))
	await process_frame
	cutscene.queue_free()
	await process_frame
	check(audio.music_mode == "" and audio.music.playing, "scene removal fades out dialogue")
	audio.play_dialogue_bgm(next_owner)
	await create_timer(1.1).timeout
	check(audio.music_mode == "dialogue" and audio.music.playing, "new dialogue cancels old stop callback")
	owner.queue_free()
	next_owner.queue_free()
	audio.music.stop()
	# Let the dummy audio driver retire playback references before teardown.
	await create_timer(0.15).timeout
	audio.music.stream = null
	audio.queue_free()
	await process_frame
	print("DIALOGUE_BGM_SMOKE checks=", checks, " ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
