extends SceneTree
const FEEDBACK := preload("res://src/online/combat_feedback.gd")
const BUFFER := preload("res://src/online/feedback_buffer.gd")
const DATA := preload("res://src/data/online_feedback_catalog.gd")
const IDENTITY := preload("res://src/hero_mode/hero_survival_identity_runtime.gd")
class Authority extends Node2D:
	signal online_cast_feedback(cue: String,point: Vector2)
	var online_match_mode := true
class TestView extends Node2D:
	var state := {}
	var map_offset := Vector2.ZERO
	var map_scale := Vector2.ONE
	func _layout_map() -> void: pass
var checks := 0
var failures := 0
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.get_node("CloudStore").stop()
	var host := TestView.new(); root.add_child(host)
	var feedback := FEEDBACK.new(); host.add_child(feedback)
	var buffer := BUFFER.new()
	feedback.reset(); feedback.suspended = false
	for archetype in DATA.CONTEXT.HITS:
		host.state.hero_archetype = archetype
		buffer.publish("hero_hit",Vector2.ZERO,1,Color.WHITE,0)
		var cue := DATA.hit_cue(archetype)
		var player: AudioStreamPlayer = feedback.bank.players[cue]
		check(String(feedback.bank.cues[cue].path) == DATA.CONTEXT.ROOT+String(DATA.CONTEXT.HITS[archetype].file),"solo hit material: "+archetype)
		check(player.stream != null and player.volume_db == DATA.CONTEXT.HIT_DB,"prepared hit player: "+archetype)
		var before: int = feedback.bank.played_count
		feedback.consume(buffer.snapshot(),buffer.sequence,0)
		check(feedback.bank.played_count == before+1 and float(feedback.bank.cooldowns[cue]) > 0.0,"correct archetype hit cue: "+archetype)
		feedback.consume(buffer.snapshot(),buffer.sequence,0)
		check(feedback.bank.played_count == before+1,"repeated packet does not replay hit")
	host.state.hero_archetype = "no_solo_hit_profile"
	buffer.publish("hero_hit",Vector2.ZERO,1,Color.WHITE,0)
	var before: int = feedback.bank.played_count
	feedback.consume(buffer.snapshot(),buffer.sequence,0)
	check(feedback.bank.played_count == before,"missing solo profile does not borrow mage hit")
	check(feedback.bank.play_cue("summon"),"summon sound starts")
	buffer.publish("ultimate",Vector2.ZERO,0,Color.WHITE,0)
	check(DATA.valid_events(buffer.snapshot(),buffer.sequence,0),"ultimate event validates")
	before = feedback.bank.played_count
	feedback.consume(buffer.snapshot(),buffer.sequence,0)
	check(feedback.bank.played_count == before+1 and not feedback.bank.players.summon.playing,"ultimate uses solo sound and stops summon")
	check(feedback.bank.cues.ultimate == DATA.GAME.BATTLE_CUES.ultimate,"ultimate profile equals solo")
	feedback.pause_feedback()
	buffer.publish("ultimate",Vector2.ZERO,0,Color.WHITE,0)
	before = feedback.bank.played_count
	feedback.consume(buffer.snapshot(),buffer.sequence,0)
	feedback.suspended = false
	feedback.consume(buffer.snapshot(),buffer.sequence,0)
	check(feedback.bank.played_count == before,"resume does not replay muted ultimate")
	# Both the server emitter and client select from the same existing audio profiles.
	var authority := Authority.new(); root.add_child(authority)
	var hero := Node2D.new(); authority.add_child(hero)
	var identity := IDENTITY.new(); identity.hero = hero; identity.starter = "fixture_starter"
	var emitted: Array = []
	authority.online_cast_feedback.connect(func(cue: String,point: Vector2): emitted.append([cue,point]))
	for archetype in DATA.CAST_PROFILES:
		identity.archetype = archetype; host.state.hero_archetype = archetype
		var emitted_before := emitted.size()
		identity.on_cast(identity.starter)
		check(emitted.size() == emitted_before+1 and emitted[-1][0] == "cast","starter emits shared cast event: "+archetype)
		var cue := DATA.cast_cue(archetype)
		var players_before: int = feedback.bank.get_child_count()
		var sounds_before: int = feedback.bank.played_count
		var stream_before = feedback.bank.players[cue].stream
		buffer.publish(emitted[-1][0],hero.global_position,0,Color.WHITE,0)
		feedback.consume(buffer.snapshot(),buffer.sequence,0)
		check(feedback.bank.played_count == sounds_before+1,"matched starter sound plays: "+archetype)
		check(feedback.bank.cues[cue] == DATA.CAST_PROFILES[archetype] and feedback.bank.players[cue].stream != null,"shared prepared profile: "+archetype)
		feedback.consume(buffer.snapshot(),buffer.sequence,0)
		check(feedback.bank.played_count == sounds_before+1,"duplicate cast snapshot stays silent")
		check(feedback.bank.get_child_count() == players_before and feedback.bank.players[cue].stream == stream_before,"cast reuses prepared player and stream")
	var emitted_before := emitted.size()
	identity.on_cast("fixture_secondary")
	identity.on_cast(identity.starter,false)
	identity.archetype = "unmapped"; identity.on_cast(identity.starter)
	check(emitted.size() == emitted_before,"secondary, suppressed and unsupported cast never borrow starter sound")
	authority.free()
	host.free()
	print("ONLINE_FEEDBACK_AUDIO checks=",checks," failures=",failures)
	quit(1 if failures else 0)
