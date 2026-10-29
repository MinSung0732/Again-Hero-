extends SceneTree
const DATA := preload("res://src/data/online_feedback_catalog.gd")
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	var audio = root.get_node("GameAudio")
	var owner := Node.new(); root.add_child(owner)
	audio.enter_frontend(owner, "lobby")
	assert(audio.music_mode == "lobby")
	audio.attach_online(owner)
	assert(audio.online_owner.get_ref() == owner)
	var bgm = load("res://src/audio/hero_bgm_manager.gd").new()
	for player_name in ["PlayerA", "PlayerB"]:
		var player := AudioStreamPlayer.new(); player.name = player_name; bgm.add_child(player)
	owner.add_child(bgm)
	bgm.start_hero_loop("ranged_rookie")
	assert(bgm.current_phase == bgm.Phase.BATTLE)
	var before: int = audio.battle_bank.played_count
	audio.play_online(DATA.STATE_AUDIO.chest, owner)
	assert(audio.battle_bank.played_count == before + 1)
	audio.battle_result(owner, true)
	assert(audio.music_mode == "result")
	assert(audio.ui_bank.players.victory.playing)
	bgm.stop_bgm()
	owner.queue_free()
	await process_frame
	assert(audio.online_owner == null and audio.music_mode == "")
	var loser := Node.new(); root.add_child(loser)
	audio.attach_online(loser)
	audio.battle_result(loser, false)
	assert(audio.music_mode == "result" and audio.ui_bank.players.defeat.playing)
	loser.queue_free()
	await process_frame
	print("online_audio_smoke: passed")
	quit()
