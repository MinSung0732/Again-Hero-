extends SceneTree
class BattleStub extends Node:
	signal summon_result(id: String, success: bool, message: String)
	signal demon_ultimate_used(id: String, name: String, message: String)
	signal demon_augment_ready(candidates: Array, rerolls: int, level: int)
	signal demon_augment_applied(name: String, summary: String)
	signal demon_progression_changed(level: int, exp: float, next_exp: float)
	signal mutation_selected(type: String, name: String)
	var battle_over := false
	var external_pause := false
	var demon_augment_selection_active := false
	var demon_level := 1
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
	var audio = root.get_node("GameAudio")
	var owner := Control.new()
	root.add_child(owner)
	check(audio.music.bus == &"BGM" and audio.music.stream.get_length() > 190 and audio.music.stream.loop, "valid looping lobby music on BGM")
	audio.enter_frontend(owner, "title")
	await create_timer(0.15).timeout
	var position: float = audio.music.get_playback_position()
	audio.enter_frontend(owner, "lobby")
	check(audio.music.get_playback_position() >= position, "title-to-lobby keeps playback position")
	for bank in [audio.ui_bank, audio.battle_bank]:
		for player in bank.players.values():
			check(player.bus == &"SFX" and player.stream is AudioStreamWAV and player.stream.get_length() >= 0.19 and player.stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "real short one-shot WAV on SFX")
	var button := Button.new()
	owner.add_child(button)
	var count: int = audio.ui_bank.played_count
	button.pressed.emit()
	check(audio.ui_bank.played_count == count+1, "newly-created button is audible")
	button.mouse_entered.emit()
	check(audio.ui_bank.played_count == count+1, "hover stays silent")
	owner.remove_child(button)
	owner.add_child(button)
	check(button.pressed.get_connections().size() == 1, "reparented UI retains one audio connection")
	audio.feedback("upgrade")
	check(not audio.ui_bank.players.click.playing, "committed success replaces generic click")
	var battle := BattleStub.new()
	root.add_child(battle)
	audio.attach_battle(battle)
	audio.attach_battle(battle)
	count = audio.battle_bank.played_count
	battle.summon_result.emit("slime", true, "")
	battle.summon_result.emit("slime", true, "")
	check(audio.battle_bank.played_count == count+1, "burst summon coalesces and attach is idempotent")
	battle.summon_result.emit("zeus", true, "")
	check(audio.battle_bank.played_count == count+1, "dedicated transcendent sound isn't doubled")
	battle.demon_ultimate_used.emit("", "", "")
	check(audio.battle_bank.players.ultimate.playing and not audio.battle_bank.players.summon.playing, "ultimate replaces summon cue")
	battle.external_pause = true
	audio.battle_bank._process(0.1)
	check(audio.battle_bank.players.ultimate.stream_paused, "battle pause holds combat sound")
	paused = true
	audio.ui_bank.stop_all()
	audio.feedback("success")
	check(audio.ui_bank.players.success.playing, "pause-menu UI remains responsive")
	paused = false
	battle.external_pause = false
	audio.battle_bank.stop_all()
	if "--mix-capture" in OS.get_cmdline_user_args():
		var bus := AudioServer.get_bus_index(&"SFX")
		var db := AudioServer.get_bus_volume_db(bus)
		var mute := AudioServer.is_bus_mute(bus)
		AudioServer.set_bus_volume_db(bus, 0.0)
		AudioServer.set_bus_mute(bus, false)
		var capture := AudioEffectCapture.new()
		AudioServer.add_bus_effect(bus, capture)
		var index := AudioServer.get_bus_effect_count(bus)-1
		audio.ui_bank.stop_all()
		audio.battle_bank.play_cue("ultimate")
		audio.battle_bank.play_cue("chest")
		audio.feedback("victory")
		var peak := 0.0
		for i in range(35):
			await create_timer(0.03).timeout
			for sample in capture.get_buffer(capture.get_frames_available()):
				peak = maxf(peak, maxf(absf(sample.x), absf(sample.y)))
		check(peak > 0.0001 and peak < 1.0, "actual simultaneous SFX mix has nonzero unclipped output")
		print("GAME_AUDIO_MIX peak=", peak)
		AudioServer.remove_bus_effect(bus, index)
		AudioServer.set_bus_volume_db(bus, db)
		AudioServer.set_bus_mute(bus, mute)
	battle.battle_over = true
	audio.battle_result(owner, true)
	check(audio.ui_bank.players.victory.playing and not audio.battle_bank.players.ultimate.playing and audio.music_mode == "result", "battle-over permits result cue and clears combat sound")
	audio._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	audio._process(0.1)
	check(audio.music.stream_paused, "background holds music")
	audio._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	audio._process(0.1)
	check(not audio.music.stream_paused, "foreground resumes music")
	battle.queue_free()
	await process_frame
	check(audio.battle_bank.authority == null and audio.battle_owner == null, "scene exit clears battle authority")
	owner.queue_free()
	audio.ui_bank.stop_all()
	audio.queue_free()
	await process_frame
	preload("res://src/audio/event_sfx_bank.gd").streams.clear()
	print("GAME_AUDIO_SMOKE ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
