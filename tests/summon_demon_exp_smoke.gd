extends SceneTree
## Executes actual Battle summon/EXP functions with isolated spawn, metrics and UI adapters.
const C := preload("res://src/data/monster_catalog.gd")
var checks := 0
var failures := 0
func check(ok: bool,label: String) -> void:
 checks += 1
 if not ok: failures += 1; push_error(label)
func function_source(source: String,name: String) -> String:
 var static_method := source.find("static func "+name+"(") >= 0
 var start := source.find(("static func " if static_method else "func ")+name+"(")
 var end := source.find("\nstatic func " if static_method else "\nfunc ",start+1)
 return source.substr(start,end-start if end>=0 else source.length()-start)
func make_battle():
 var script := GDScript.new()
 script.source_code = '''extends Node2D
signal command_changed(current,maximum)
signal summon_result(id,success,message)
signal transcendence_changed(id,ready,used)
signal transcendent_summoned(id,actor)
signal demon_progression_changed(level,exp,needed)
const MONSTER_CATALOG = preload("res://src/data/monster_catalog.gd")
const TRANSCENDENCE_DATA = preload("res://src/data/transcendence_catalog.gd")
const DEMON_ULTIMATES = preload("res://src/data/demon_ultimate_catalog.gd")
const DEMON_BASE_EXP_TO_NEXT = 15.0
const DEMON_EXP_GROWTH_PER_LEVEL = 4.0
var command_power := 1000.0
var max_command := 1000.0
var hero: Node2D
var tutorial_mode := false
var battle_over := false
var fail_spawn := false
var extras := 0
var demon_exp_gain_multiplier := 1.0
var demon_level := 1
var demon_exp := 0.0
var demon_exp_to_next_level := 15.0
var demon_pending_augments := 0
var demon_pending_augment_levels: Array[int] = []
var refreshes := 0
var notifications := 0
var transcendence = Trans.new()
var run_metrics = Metrics.new()
class Trans extends RefCounted:
 var monster_id := "zeus"
 func record_command(_cost: float) -> bool: return false
 func consume() -> void: pass
class Metrics extends RefCounted:
 var exp_log: Array = []
 func record_summon(_id: String,_cost: float) -> void: pass
 func record_summon_demon_exp(id: String,exp: float) -> void: exp_log.append([id,exp])
func _roll_giant_monster_for_normal_summon() -> bool: return false
func _spawn_monster(_id: String,_point: Vector2,_cost: float,_split: bool,_modifiers: Dictionary):
 if fail_spawn: return null
 var unit := Node2D.new()
 add_child(unit)
 return unit
func _spawn_extra_normal_summon_monsters(_id: String,_point: Vector2) -> void: extras += 1
func _try_fuse_nearby_kobolts(unit: Node2D) -> Node2D: return unit
func _emit_stats() -> void: pass
func _get_monster_name(id: String) -> String: return id
func _add_demon_ultimate_charge(_amount: float) -> void: pass
func _refresh_alive_monsters_for_demon_level() -> void: refreshes += 1
func _open_next_demon_augment_if_needed() -> void: notifications += 1
'''
 var source := FileAccess.get_file_as_string("res://src/battle/battle.gd")
 for name in ["_perform_summon","_gain_demon_exp","_required_demon_exp_for_level"]:
  script.source_code += "\n"+function_source(source,name).replace("\t"," ")+"\n"
 check(script.reload() == OK,"actual summon/EXP functions compile")
 return script.new()
func _initialize() -> void: call_deferred("run")
func run() -> void:
 for id in C.ORDER:
  check(C.get_summon_exp(id) == (0.0 if C.get_rarity(id) == "transcendent" else C.get_base_cost(id)),"all35 summonEXP:"+id)
 var catalog_shell := GDScript.new()
 catalog_shell.source_code = 'extends RefCounted\nconst MONSTERS={"future":{"base_cost":6.5},"zero":{"base_cost":6.0,"summon_exp":0.0},"custom":{"base_cost":6.0,"summon_exp":3.0},"negative":{"summon_exp":-1.0}}\n'+function_source(FileAccess.get_file_as_string("res://src/data/monster_catalog.gd"),"get_summon_exp")
 check(catalog_shell.reload() == OK,"actual Catalog fallback compiles")
 check(catalog_shell.get_summon_exp("future") == 6.5,"future missing field defaults to cost")
 check(catalog_shell.get_summon_exp("zero") == 0 and catalog_shell.get_summon_exp("custom") == 3,"explicit zero/custom rewards preserved")
 check(catalog_shell.get_summon_exp("unknown") == 0 and catalog_shell.get_summon_exp("negative") == 0,"unknown/negative rewards safe")
 var battle = make_battle()
 root.add_child(battle)
 var emitted := [0]
 battle.demon_progression_changed.connect(func(_level,_exp,_needed): emitted[0] += 1)
 check(battle._perform_summon("boar",Vector2.ZERO,8,false),"auto summon succeeds")
 check(battle.demon_exp == 8 and battle.demon_level == 1 and emitted[0] == 1,"boar actualEXP8 and HUD signal")
 check(battle._perform_summon("dark_elf_archer",Vector2.ZERO,9,true),"discounted manual summon succeeds")
 check(battle.demon_level == 2 and battle.demon_exp == 5 and battle.demon_pending_augments == 1,"archer baseEXP12 crosses level and grants augment")
 check(battle.run_metrics.exp_log == [["boar",8.0],["dark_elf_archer",12.0]],"metrics record actualEXP once, discounts do not reduce base reward")
 battle._perform_summon("anubis",Vector2.ZERO,24,false)
 check(battle.demon_level == 3 and battle.demon_exp == 10 and battle.demon_pending_augment_levels == [2,3],"anubisEXP24 and multiple level progression")
 check(battle.extras == 3 and battle.run_metrics.exp_log.size() == 3,"extra summon helper does not double EXP")
 var before: float = battle.demon_exp
 var power: float = battle.command_power
 var count: int = battle.run_metrics.exp_log.size()
 battle.fail_spawn = true
 check(not battle._perform_summon("boar",Vector2.ZERO,8,false),"failed spawn rejected")
 check(battle.demon_exp == before and battle.command_power == power and battle.run_metrics.exp_log.size() == count,"failed spawn refunds cost/noEXP")
 battle.fail_spawn = false
 battle._perform_summon("zeus",Vector2.ZERO,0,false)
 check(battle.demon_exp == before,"transcendent remains zeroEXP")
 battle.tutorial_mode = true
 battle._perform_summon("boar",Vector2.ZERO,8,false)
 check(battle.demon_exp == before,"tutorial progression intentionally suppressed")
 battle.tutorial_mode = false; battle.battle_over = true
 battle._gain_demon_exp(100)
 check(battle.demon_exp == before,"battle over noEXP")
 battle.battle_over = false; battle.demon_exp_gain_multiplier = 1.5
 battle._perform_summon("boar",Vector2.ZERO,8,false)
 check(battle.demon_exp == before+12,"research EXP multiplier retained")
 battle.free()
 print("SUMMON_DEMON_EXP_SMOKE checks=",checks," failures=",failures)
 quit(1 if failures else 0)
