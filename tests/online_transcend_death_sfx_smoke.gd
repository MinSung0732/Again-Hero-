extends SceneTree
const ROOM = preload("res://src/online/battle_room.gd")
const VIEW = preload("res://src/online/battle_view.gd")
const BANK = preload("res://src/audio/event_sfx_bank.gd")
const DATA = preload("res://src/data/online_feedback_catalog.gd")
const ZEUS = preload("res://src/data/zeus_audio_catalog.gd")
const ARTHUR = preload("res://src/data/arthur_audio_catalog.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.get_node("CloudStore").stop()
	var room = ROOM.new(); root.add_child(room)
	room.set_loadouts({"hero_id": room.hero_id}, {"team_ids": room.roster, "skill_ids": [], "transcendence_id": "zeus"})
	room.prepare(); room.running = true; room.battle.set_external_pause(false)
	var view = VIEW.new(); root.add_child(view); view.size = Vector2(800, 1000)
	view.set_match_roster([], "zeus"); view.feedback.reset(); view.feedback.suspended = false
	var other_view = VIEW.new(); root.add_child(other_view); other_view.size = Vector2(800, 1000)
	other_view.set_match_roster([], "zeus"); other_view.feedback.reset(); other_view.feedback.suspended = false
	var actor := Node2D.new(); room.battle.add_child(actor); actor.position = Vector2(230, 300)
	var initial_scale := Engine.time_scale
	room.battle.transcendent_died.emit("zeus", actor)
	check(room.feedback.snapshot()[-1][2] == "transcend_death", "death published")
	view.feedback.consume(room.feedback.snapshot(), room.feedback.sequence, room.tick)
	check(view.cinematic.active and view.cinematic.death_mode, "death active")
	other_view.feedback.consume(room.feedback.snapshot(), room.feedback.sequence, room.tick)
	check(other_view.cinematic.active and other_view.cinematic.death_mode, "other role receives death")
	other_view.cinematic.advance(5.0)
	view.cinematic.advance(0.5)
	check(view.cinematic_blend > 0.0 and view.cinematic_zoom > 1.0, "death focuses map")
	view.cinematic.advance(5.0)
	check(not view.cinematic.active and view.cinematic_blend == 0.0 and view.cinematic_zoom == 1.0 and Engine.time_scale == initial_scale, "death restores map without time change")
	var server_bank = BANK.new(); room.battle.add_child(server_bank); server_bank.configure(ZEUS.CUES, room.battle, true, "res://src/data/zeus_audio_catalog.gd")
	var before: int = room.feedback.sequence
	check(server_bank.play_cue("judgment"), "server cue accepted")
	check(room.feedback.sequence == before + 1 and server_bank.played_count == 0, "server emits without playing")
	check(not server_bank.play_cue("judgment") and room.feedback.sequence == before + 1, "server interval enforced")
	var played: int = view.feedback.transcend_bank.played_count
	view.feedback.consume(room.feedback.snapshot(), room.feedback.sequence, room.tick)
	check(view.feedback.transcend_bank.played_count == played + 1, "client plays matching cue")
	room._transcendent_sfx("res://src/data/arthur_audio_catalog.gd", "judgment")
	check(room.feedback.sequence == before + 1, "other catalog rejected")
	room.battle.online_match_mode = false; server_bank.stop_all()
	check(server_bank.play_cue("judgment") and server_bank.played_count == 1 and room.feedback.sequence == before + 1, "solo plays locally")
	room.feedback.publish("transcend_death", Vector2.ZERO, DATA.transcend_index("zeus"), Color.WHITE, 0)
	view.feedback.consume(room.feedback.snapshot(), room.feedback.sequence, 1000)
	check(not view.cinematic.active, "stale death ignored")
	other_view.free(); view.free(); room.free()
	print("ONLINE_TRANSCEND_DEATH_SFX checks=", checks, " failures=", failures)
	quit(1 if failures else 0)
