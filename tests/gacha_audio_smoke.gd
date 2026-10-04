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
	for player in [overlay._door_sound, overlay._reveal_sound]:
		check(player.bus == &"SFX" and player.stream != null, "cue loaded on SFX bus")
		check(player.stream.get_length() > 0.1 and player.stream.get_length() < 6.0, "short valid MP3")
	var entries := [{"monster_id":"slime", "name":"슬라임", "rarity":"common", "shards":1}, {"monster_id":"orc", "name":"오크", "rarity":"common", "shards":2}]
	overlay.present(entries)
	check(not overlay._door_sound.playing, "anticipation is quiet")
	var deadline := Time.get_ticks_msec() + 15000
	while not overlay._door_sprite.is_playing() and Time.get_ticks_msec() < deadline:
		await process_frame
	check(overlay._door_sound.playing, "door cue starts with opening")
	while overlay._phase == "door" and Time.get_ticks_msec() < deadline:
		await process_frame
	check(overlay._phase == "reveal" and overlay._reveal_sound.playing, "first reveal plays cue")
	check(not overlay._door_sound.playing, "door stops at reveal")
	overlay._advance_reveal()
	check(overlay._reveal_index == 1 and overlay._reveal_sound.playing, "next monster restarts cue")
	overlay.skip_to_results()
	check(not overlay._door_sound.playing and not overlay._reveal_sound.playing, "skip stops both")
	overlay._confirm()
	overlay.present(entries)
	overlay.skip_to_results()
	await create_timer(1.0).timeout
	check(overlay._phase == "result" and not overlay._door_sound.playing, "early skip blocks delayed audio")
	overlay._confirm()
	overlay.present(entries)
	overlay._show_reveal(0)
	overlay.hide()
	check(not overlay._reveal_sound.playing, "hide stops sound")
	overlay.free()
	print("GACHA_AUDIO_SMOKE_FAILED" if failed else "GACHA_AUDIO_SMOKE_OK")
	quit(1 if failed else 0)
