extends SceneTree
const CUE := preload("res://src/ui/battle_summon_cinematic.gd")
class Hero extends Node2D:
	signal death_started
class Battle extends Node2D:
	signal transcendent_summoned(id: String,actor: Node2D)
	signal transcendent_died(id: String,actor: Node2D)
	signal battle_finished(message: String,won: bool)
	var hero: Node2D
	var hero_player_mode := false
	var practice_mode := false
	var tutorial_mode := false
	var battle_over := false
	var external_pause := false
	var demon_augment_selection_active := false
class Host extends Control:
	var hud_layer := Control.new()
	var battle := Battle.new()
	var battle_viewport := SubViewport.new()
	var battle_viewport_container := SubViewportContainer.new()
	func _end_camera_drag() -> void: pass
var checks := 0
func check(ok: bool,message: String) -> void:
	checks += 1; assert(ok,message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var host := Host.new(); root.add_child(host); host.add_child(host.hud_layer)
	host.add_child(host.battle_viewport_container); host.battle_viewport_container.size = Vector2(1080,1174)
	host.battle_viewport_container.add_child(host.battle_viewport); host.battle_viewport.size = Vector2i(1080,1174)
	host.battle_viewport.add_child(host.battle)
	host.battle.hero = Hero.new(); host.battle.add_child(host.battle.hero); host.battle.hero.position = Vector2(500,650)
	var original := Camera2D.new(); host.battle.add_child(original); original.make_current(); await process_frame
	var cue := CUE.new(); var none: Array[String] = ["fixture_skip_prewarm"]; cue.install(host,none)
	var state := {"ended":0}; cue.focus_finished.connect(func(): state.ended += 1)
	Engine.time_scale = 0.75
	host.battle.hero_player_mode = true; host.battle.hero.death_started.emit()
	check(not cue.active,"hero mode death excluded")
	host.battle.hero_player_mode = false; host.battle.practice_mode = true; cue.play_hero_defeat()
	check(not cue.active,"practice excluded")
	host.battle.practice_mode = false; host.battle.tutorial_mode = true; cue.play_hero_defeat()
	check(not cue.active,"tutorial excluded")
	host.battle.tutorial_mode = false; host.battle.hero.death_started.emit(); cue.set_process(false)
	check(cue.active and cue.hero_defeat_focus and cue.death_mode,"terminal death begins shared focus")
	check(Engine.time_scale < 0.75 and cue.view == null,"slow without summon illustration")
	cue.advance(0.6); var elapsed := cue.elapsed
	cue.play_hero_defeat(); cue.play_death("zeus",host.battle.hero); cue.play("zeus",host.battle.hero)
	check(cue.elapsed == elapsed and state.ended == 0,"duplicates and other cues cannot replace final focus")
	host.battle.battle_over = true; host.battle.battle_finished.emit("already settled",true)
	check(cue.active and state.ended == 0,"settlement signal does not cancel focus")
	host.battle.hero.queue_free(); await process_frame; cue.advance(0.3)
	check(cue.active,"actor removal retains remembered death position")
	cue.advance(3.0)
	check(not cue.active and state.ended == 1,"one completion releases result wait")
	check(is_equal_approx(Engine.time_scale,0.75) and not cue.camera.enabled,"restore previous speed and camera")
	check(host.battle_viewport.get_camera_2d() == original,"original camera current")
	cue.cancel(); check(state.ended == 1,"idle cancellation does not duplicate result")
	host.battle.battle_over = false; host.battle.hero = Hero.new(); host.battle.add_child(host.battle.hero)
	cue.play_hero_defeat(); cue.set_process(false); host.battle.external_pause = true; cue.advance(0.1)
	check(not cue.active and state.ended == 2 and is_equal_approx(Engine.time_scale,0.75),"interruption releases wait and restores")
	Engine.time_scale = 1.0; host.queue_free(); await process_frame
	print("HERO_DEFEAT_FOCUS PASS checks=",checks); quit()
