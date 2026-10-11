extends SceneTree
## Isolated data/logic regression. Does not simulate a full match or rendering.
const C := preload("res://src/data/monster_catalog.gd")
const B := preload("res://src/data/monster_balance_catalog.gd")
const EXPECTED := {
 "slime":[72,9],"bat":[60,5],"goblin":[96,9],"scorpion":[54,4],"wolf":[105,10],
 "orc":[260,18],"skeleton":[180,10],"mummy":[140,13],"dullahan":[350,28],
 "spider":[80,6],"ghost":[100,5],"banshee":[110,5],"medusa":[120,6],"yuki_onna":[100,9],"succubus":[220,18],
 "goblin_thrower":[72,11],"skeleton_archer":[72,14],"kobolt":[110,32],"kraken":[180,90],"powwow_mummy":[72,7],"bomb_rat":[48,96]
}
const TRANSC := {"zeus":[1450,150,30.0],"bulgasal":[2100,130,20.0],"izanami":[1400,55,20.0],"manticore":[1700,42,35.0],"shuten_doji":[2500,220,30.0],"arthur":[2000,170,50.0]}
var checks := 0
var failures := 0

class Actor:
 extends Node
 var max_hp := 1
 var attack_damage := 1
 var attack_cooldown := 1.0
 var move_speed := 1.0
 var explosion_damage := 1
 var exp_reward := 777

func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(message)

func function_source(text: String, name: String) -> String:
 var start := text.find("func "+name+"(")
 if start < 0: return ""
 var end := text.find("\nfunc ",start+1)
 return text.substr(start,end-start if end >= 0 else -1)+"\n"

func _init() -> void:
 for id in EXPECTED:
  var data: Dictionary = C.MONSTERS[id]
  var stats := C.get_base_stats(id)
  check(B.audit(data).is_empty(),id+" reviewed profile")
  check(stats.max_hp == EXPECTED[id][0],id+" HP")
  check(stats.get("explosion_damage",stats.get("attack_damage",0)) == EXPECTED[id][1],id+" damage")
  var raw_damage: int = stats.get("attack_damage",0)
  stats["attack_damage"] = 999999
  check(C.get_base_stats(id).get("attack_damage",0) == raw_damage,id+" isolated cache")
  var exported := C.get_monster(id)
  check(exported.base_stats.max_hp == EXPECTED[id][0],id+" public projection")
  var actor := Actor.new()
  C.apply_runtime_base_stats(actor,id)
  check(actor.max_hp == EXPECTED[id][0],id+" spawn HP")
  check(actor.exp_reward == 777,id+" spawn EXP independent")
  actor.free()
 for id in ["orc","spider","bomb_rat"]:
  check(C.get_base_cost(id) == {"orc":10.0,"spider":5.0,"bomb_rat":6.0}[id],id+" cost")
  check(C.get_summon_exp(id) == C.get_base_cost(id),id+" summon exp")
 for role in B.ROLE_BUDGETS:
  for rarity in B.GRADE_EFFICIENCY:
   var input := {"id":"future","role":role,"rarity":rarity,"base_cost":6.0,"attack_type":"self_destruct" if role=="burst" else "melee","base_stats":{"max_hp":999999,"attack_damage":999999,"explosion_damage":999999,"attack_cooldown":1.0}}
   var result := B.resolve_base_stats(input)
   var hp: float = result.max_hp*B.RARITY_COMBAT_PROFILES[rarity].hp_multiplier
   var expected_hp: float = 6.0*B.GRADE_EFFICIENCY[rarity]*B.ROLE_BUDGETS[role].hp_per_cost
   check(absf(hp-expected_hp) <= B.RARITY_COMBAT_PROFILES[rarity].hp_multiplier,role+" "+rarity+" future HP budget")
   check(result.attack_damage < 999999 if role != "burst" else result.explosion_damage < 999999,role+" rough authoring normalized")
   var combat: Dictionary = B.RARITY_COMBAT_PROFILES[rarity]
   var output := float(result.explosion_damage)*float(combat.damage_multiplier) if role=="burst" else float(result.attack_damage)*float(combat.damage_multiplier)/float(combat.attack_cooldown_multiplier)
   var target := 6.0*float(B.GRADE_EFFICIENCY[rarity])*float(B.ROLE_BUDGETS[role].get("burst_per_cost",B.ROLE_BUDGETS[role].damage_per_cost))
   check(absf(output-target) <= float(combat.damage_multiplier)/float(combat.attack_cooldown_multiplier),role+" "+rarity+" damage budget")
   check(input.base_stats.max_hp == 999999,role+" original data untouched")
   check(not B.audit(input).is_empty(),role+" unreviewed mechanics reported")
 var malformed := {"id":"future","role":"controller","rarity":"advanced","base_cost":5.0,"base_stats":{"max_hp":9999,"attack_damage":9999,"attack_cooldown":NAN},"balance":{"health_share":INF,"damage_share":-999.0}}
 var safe := B.resolve_base_stats(malformed)
 check(safe.max_hp > 0 and safe.attack_damage > 0 and is_finite(safe.attack_cooldown),"invalid tuning fail soft")
 check(not B.audit(malformed).is_empty(),"invalid tuning reported")
 check(B.resolve_base_stats({"base_stats":null}).is_empty(),"null stats")
 check(C.get_base_stats("unknown").is_empty(),"unknown monster")
 var composite := {"id":"future","role":"tank","rarity":"common","base_cost":5.0,"base_stats":{"max_hp":1,"attack_damage":999,"attack_cooldown":1.0,"hits_per_attack":2,"hit_damage_multiplier":1.0,"attack_range":333.0}}
 var double := B.resolve_base_stats(composite)
 check(double.attack_damage == 3,"future double attack budget divides damage")
 check(double.attack_range == 333.0,"authored range preserved")
 composite["role"]="exploder"
 composite.base_stats["explosion_damage"]=999999
 var hybrid := B.resolve_base_stats(composite)
 check(hybrid.attack_damage==6 and hybrid.explosion_damage==80,"future hybrid burst uses separate recurring/one-shot units")
 _test_transcendents()
 _test_gunner_damage()
 var battle := FileAccess.get_file_as_string("res://src/battle/battle.gd")
 var apply_at := battle.find("MONSTER_CATALOG.apply_runtime_base_stats(monster, monster_type)")
 check(apply_at > 0 and apply_at < battle.find("_apply_giant_monster_base_stats(monster, monster_type)",apply_at),"canonical stats before giant scaling")
 check(apply_at < battle.find('monster.set_meta("augment_raw_attack_damage"',apply_at),"canonical stats before augment snapshots")
 print("monster_balance_smoke: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)

func _test_transcendents() -> void:
 for id in TRANSC:
  var data = load("res://src/data/"+id+"_behavior_catalog.gd")
  check(data.BASE.max_hp == TRANSC[id][0] and data.BASE.attack_damage == TRANSC[id][1],id+" canonical base")
  check(data.INITIAL_GAUGE == TRANSC[id][2],id+" opening gauge")
  var text := FileAccess.get_file_as_string("res://src/monsters/"+id+".gd")
  check(text.contains("var gauge := DATA.INITIAL_GAUGE"),id+" live gauge wiring")
  # Execute the actual snapshot function in a minimal shell; no visuals/physics involved.
  var shell := GDScript.new()
  shell.source_code = 'extends RefCounted\nconst DATA=preload("res://src/data/'+id+'_behavior_catalog.gd")\nvar max_hp=0\nvar current_hp=0\nvar attack_damage=0\nvar move_speed=0.0\nvar attack_range=0.0\nvar attack_cooldown=0.0\nvar exp_reward=0\nvar summon_snapshot=0\nvar attack_snapshot=0\nvar transcend_level=0\n'+function_source(text,"configure_transcendence")
  if id=="bulgasal": shell.source_code += function_source(text,"configure_attack_snapshot")
  var error := shell.reload()
  check(error == OK,id+" snapshot compiles")
  if error != OK: continue
  var actor = shell.new()
  actor.configure_transcendence(-5,9)
  check(actor.max_hp == data.BASE.max_hp and actor.transcend_level==5,id+" negative count/level guard")
  actor.configure_transcendence(40,0)
  var expected_hp: int = {"zeus":1550,"bulgasal":2140,"izanami":1460,"manticore":1720,"shuten_doji":2540,"arthur":2600}[id]
  check(actor.max_hp == expected_hp and actor.current_hp==expected_hp,id+" snapshot growth preserved")
  if id=="manticore":
   actor.configure_transcendence(400,0)
   check(actor.attack_damage==72 and actor.max_hp==1900,"manticore unlock snapshot")
  if id=="bulgasal":
   actor.configure_attack_snapshot(50)
   check(actor.attack_damage==160,"bulgasal separate attack metric")

func _test_gunner_damage() -> void:
 var source := FileAccess.get_file_as_string("res://src/hero/hero.gd")
 var shell := GDScript.new()
 shell.source_code = """extends Node2D
signal accepted_damage_hit(source)
signal health_changed(current, maximum)
signal combat_damage_received(amount)
const DAMAGE_NUMBERS=preload("res://tests/fixtures/balance_damage_numbers.gd")
var current_hp:=100
var max_hp:=100
var is_dying:=false
var invulnerability_timer:=0.0
var invulnerability_duration:=0.22
var hero_archetype:="pistol_gunner"
var fighter_guard_active:=false
var shield_hp:=0.0
var damage_taken_increase_ratio:=0.0
var alchemist_equivalent_exchange_damage_reduction_timer:=0.0
var fighter_guard_stored_damage:=0.0
var ultimate_config:={}
var fighter_guard_damage_reduction_bonus:=0.0
var fighter_reflect_ratio:=0.0
var purifier_protection_active:=false
var hit_flash_timer:=0.0
var hit_pose_timer:=0.0
var berserker_revive_used:=false
var berserker_reviving:=false
var evade_rolls:=0
var backsteps:=0
func _get_alchemist_augment_stacks(_x) -> int: return 0
func _get_alchemist_equivalent_exchange_data(_x) -> Dictionary: return {}
func _apply_sage_mana_conversion(x: float) -> float: return x
func _fighter_reflect_damage(_x,_y): pass
func _end_purifier_protection(_x): pass
func _get_summoner_augment_stacks(_x) -> int: return 0
func _extend_regular_summon_durations(_x): pass
func _end_shield(): pass
func _restart_stage1_animation(_x): pass
func _play_contextual_damage_audio(_x,_y): pass
func _add_ultimate_charge(_x): pass
func _begin_berserker_revive(): pass
func _begin_death_sequence(): is_dying=true
func _gunner_should_backstep_on_hit():
 evade_rolls+=1
 return true
func _start_gunner_backstep(): backsteps+=1
func _refresh_invulnerability_visual(): pass
"""
 shell.source_code = shell.source_code.replace("\n ","\n\t")
 for method in ["take_damage","take_followup_damage","take_status_damage","_take_damage_internal"]:
  shell.source_code += function_source(source,method)
 var error := shell.reload()
 check(error==OK,"actual Hero damage boundary compiles in shell")
 if error != OK: return
 var actor = shell.new()
 for _tick in range(5):
  check(actor.take_status_damage(2),"DOT accepted")
 check(actor.current_hp==90 and actor.evade_rolls==0 and actor.backsteps==0,"DOT deals damage without evade rolls")
 check(actor.invulnerability_timer==0.0,"DOT grants no immunity")
 actor.shield_hp=10.0
 check(actor.take_status_damage(3) and actor.shield_hp==7.0 and actor.current_hp==90,"DOT shield consumption retained")
 check(actor.evade_rolls==0,"shielded DOT still no evade roll")
 check(actor.take_damage(4) and actor.backsteps==1 and actor.invulnerability_timer>0.0,"direct hit retains backstep/immunity")
 check(not actor.take_damage(2),"ordinary immunity retained")
 check(actor.take_followup_damage(2) and actor.backsteps==2,"followup bypass/evade retained")
 actor.free()
