extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func function_source(source: String,name: String) -> String:
	var start := source.find("func "+name+"(")
	var end := source.find("\nfunc ",start+1)
	return source.substr(start,end-start if end>=0 else source.length()-start)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var script := GDScript.new()
	script.source_code = '''extends Node2D
const SUCCUBUS_BEHAVIOR = preload("res://src/data/succubus_behavior_catalog.gd")
class FX:
	static func show_on(_node,_kind): pass
const COMBAT_STATUS_EFFECT_VISUAL = preload("res://src/ui/combat_status_effect_visual.gd")
var current_hp := 100
var is_dying := false
var dying := false
var charm_timer := 0.0
var charm_immunity_timer := 0.0
var charm_recovery_immunity := 7.0
var charm_stacks := 0
var charm_source: WeakRef
var charm_cooldown_properties: Array = []
var channeling := false
var velocity := Vector2.ZERO
var fear_timer := 0.0
var fear_immunity_timer := 0.0
var fear_recovery_immunity := 0.0
var possession_immunity_timer := 0.0
var fear_speed_multiplier := 1.0
var fear_source: Node2D
var fear_origin := Vector2.ZERO
var ai_memory_clock := 0.0
var attack_timer := 0.0
var retarget_timer := 0.0
var wander_timer := 0.0
var slow_timer := 0.0
var move_multiplier := 1.0
var move_speed := 100.0
# Mirrors hero.gd since the player-controlled hero mode: AI heroes skip the policy.
const PLAYER_CONTROL_POLICY = preload("res://src/hero_mode/hero_control_policy.gd")
var player_control_policy := PLAYER_CONTROL_POLICY.new()
var player_controlled := false
func get_status_resistance(_kind) -> float: return 0.0
func _get_external_skill_cooldown_properties(): return []
func record_status_effect_event(_kind): pass
func _end_channel_skill(): pass
func _prune_offensive_memory(): pass
func _prune_status_memory(): pass
func get_paralysis_attack_multiplier() -> float: return 1.0
func _tick_fear_skill_cooldowns(_delta): pass
func _update_invulnerability(_delta): pass
func _get_effective_move_multiplier() -> float: return 1.0
func _get_purifier_move_speed_multiplier() -> float: return 1.0
func _move_and_slide_with_obstacle_escape(): pass
func _clamp_to_battlefield(): pass
'''
	var source := FileAccess.get_file_as_string("res://src/hero/hero.gd")
	for name in ["_apply_charm_status","_tick_charm_timers","_apply_fear_status","_tick_fear_state"]: script.source_code += "\n"+function_source(source,name)+"\n"
	check(script.reload() == OK,"actual Hero status functions compile")
	var hero = script.new(); root.add_child(hero)
	var caster = script.new(); root.add_child(caster); caster.position = Vector2(-30,0)
	check(hero._apply_charm_status(caster,1.5),"normal charm accepted")
	hero._tick_charm_timers(1.5); check(hero.charm_immunity_timer == 7,"existing succubus immunity7 retained")
	hero._tick_charm_timers(7); hero.set_meta("incoming_charm_immunity",5.0)
	hero._apply_charm_status(caster,1.5); hero.remove_meta("incoming_charm_immunity")
	hero._tick_charm_timers(1.6); check(is_equal_approx(hero.charm_immunity_timer,4.9),"scoped5 snapshot and timer overshoot")
	check(not hero._apply_charm_status(caster,1.5),"charm immunity rejects")
	hero._tick_charm_timers(4.9); check(hero._apply_charm_status(caster,1.5),"charm immunity expires")
	check(hero.charm_recovery_immunity == 7,"next regular charm default restored")
	hero._apply_fear_status(caster,2,1.7); hero._tick_fear_state(2)
	check(hero.fear_immunity_timer == 0,"other fear retains no immunity")
	hero.set_meta("incoming_fear_immunity",5.0); hero._apply_fear_status(caster,2,1.7); hero.remove_meta("incoming_fear_immunity")
	hero._tick_fear_state(1); check(hero.velocity.length() == 170,"actual flee speed170percent")
	hero._tick_fear_state(1.1); check(is_equal_approx(hero.fear_immunity_timer,4.9) and not hero.get_meta("fear_active"),"fear end scoped5 with overshoot")
	hero._apply_fear_status(caster,2,1.7); check(hero.fear_timer == 0,"fear immunity rejects")
	hero._tick_fear_state(4.9); hero._apply_fear_status(caster,2,1.7); check(hero.fear_timer == 2,"fear immunity expires")
	hero.free(); caster.free()
	print("GUMIHO_HERO_STATUS_SMOKE checks=",checks," failures=",failures)
	quit(1 if failures else 0)
