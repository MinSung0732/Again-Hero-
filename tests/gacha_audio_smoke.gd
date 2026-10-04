extends SceneTree

var failed := false

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failed = true
		push_error("GACHA_AUDIO: " + message)

func run() -> void:
	var overlay: Control = load("res://src/ui/gacha_reveal_overlay.gd").new()
	root.add_child(overlay)
	await process_frame
	for player in [overlay._door_sound, overlay._creak_sound, overlay._reveal_sound]:
		check(player.bus == &"SFX" and player.stream != null, "cue loaded on SFX bus")
		if player.stream != null:
			check(player.stream.get_length() > 0.1 and player.stream.get_length() < 6.0, "short valid MP3")
	check(overlay._reveal_sound.volume_db == 0.0, "reveal raised 8 dB over old cue setting")
	var entries := [{"monster_id":"slime", "name":"슬라임", "rarity":"common", "shards":1}, {"monster_id":"orc", "name":"오크", "rarity":"common", "shards":2}]
	overlay.present(entries)
	check(not overlay._door_sound.playing, "anticipation is quiet")
	var deadline := Time.get_ticks_msec() + 15000
	while not overlay._door_sprite.is_playing() and Time.get_ticks_msec() < deadline:
		await process_frame
	check(overlay._door_sound.playing, "door cue starts with opening")
	check(not overlay._creak_sound.playing, "hinge is quiet during sheet preparation")
	while overlay._door_sprite.frame < overlay.DOOR_OPEN_FIRST_FRAME and Time.get_ticks_msec() < deadline:
		await process_frame
	check(overlay._creak_sound.playing, "creak starts with first moving hinge")
	var creak_position: float = overlay._creak_sound.get_playback_position()
	await create_timer(0.2).timeout
	check(overlay._creak_sound.get_playback_position() > creak_position, "creak is not restarted on each frame")
	while overlay._phase == "door" and Time.get_ticks_msec() < deadline:
		await process_frame
	check(overlay._phase == "reveal" and overlay._reveal_sound.playing, "first reveal plays cue")
	check(not overlay._door_sound.playing and not overlay._creak_sound.playing, "both door cues stop at reveal")
	overlay._advance_reveal()
	check(overlay._reveal_index == 1 and overlay._reveal_sound.playing, "next monster restarts cue")
	overlay.skip_to_results()
	check(not overlay._door_sound.playing and not overlay._creak_sound.playing and not overlay._reveal_sound.playing, "skip stops all cues")
	overlay._confirm()
	overlay.present(entries)
	overlay.skip_to_results()
	await create_timer(1.0).timeout
	check(overlay._phase == "result" and not overlay._door_sound.playing and not overlay._creak_sound.playing, "early skip blocks delayed audio")
	# A later sequence resets the one-shot hinge flag; skipping during opening cancels it.
	overlay._confirm()
	overlay.present(entries)
	deadline = Time.get_ticks_msec() + 15000
	while not overlay._creak_sound.playing and Time.get_ticks_msec() < deadline:
		await process_frame
	check(overlay._creak_sound.playing, "retry re-arms creak")
	overlay.skip_to_results()
	check(not overlay._creak_sound.playing and not overlay._door_sound.playing, "opening skip stops both door cues")
	overlay._confirm()
	overlay.present(entries)
	overlay._show_reveal(0)
	overlay.hide()
	check(not overlay._reveal_sound.playing, "hide stops sound")
	overlay.free()
	print("GACHA_AUDIO_SMOKE_FAILED" if failed else "GACHA_AUDIO_SMOKE_OK")
	quit(1 if failed else 0)
