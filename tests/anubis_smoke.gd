extends SceneTree
## Runs with real Anubis actors/assets; an isolated fixture may stub unrelated scenes and floating damage text.
const S := preload("res://src/monsters/Anubis.tscn")
const C := preload("res://src/data/monster_catalog.gd")
const A := preload("res://src/data/demon_augment_catalog.gd")
const D := preload("res://src/data/anubis_behavior_catalog.gd")
const R := preload("res://src/systems/anubis_army_runtime.gd")
const COMMON := preload("res://src/monsters/monster_runtime_common.gd")
const HIT := preload("res://src/systems/monster_hit_context.gd")
const SHOP := preload("res://src/data/shop_catalog.gd")
var checks := 0
var failures := 0
class Hero extends Node2D:
 var hits: Array[int] = []
 func take_damage(amount: int,_source: Node = null) -> void: hits.append(amount)
class Mummy extends Node:
 var monster_type := "mummy"
func check(ok: bool,label: String) -> void:
 checks += 1
 if not ok: failures += 1; push_error(label)
func function_source(source: String,name: String) -> String:
 var start := source.find("func "+name+"(")
 var end := source.find("\nfunc ",start+1)
 return source.substr(start,end-start if end>=0 else source.length()-start)
func make_battle():
 var script := GDScript.new()
 script.source_code = '''extends Node2D
const MONSTER_SUPPORT_COMMON = preload("res://src/monsters/monster_runtime_common.gd")
func _get_special_stat_multiplier(_id: String,_key: String,_elite: bool = false) -> float: return 1.0
func _get_demon_level_monster_hp_multiplier() -> float: return 1.0
func _get_demon_level_monster_damage_multiplier() -> float: return 1.0
func _get_demon_level_monster_speed_multiplier() -> float: return 1.0
'''
 var source := FileAccess.get_file_as_string("res://src/battle/battle.gd")
 for name in ["_apply_demon_level_scaling_to_monster","refresh_monster_runtime_stats"]:
  script.source_code += "\n"+function_source(source,name)+"\n"
 check(script.reload() == OK,"real Battle scaling functions compile")
 return script.new()
func actor(battle):
 var unit = S.instantiate()
 C.apply_runtime_base_stats(unit,"anubis")
 for pair in [["max_hp","demon_level_base_max_hp"],["attack_damage","demon_level_base_attack_damage"],["move_speed","demon_level_base_move_speed"],["attack_cooldown","runtime_base_attack_cooldown"]]: unit.set_meta(pair[1],unit.get(pair[0]))
 unit.configure_combat_context(null,battle)
 battle.add_child(unit)
 unit.set_physics_process(false)
 return unit
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var battle = make_battle()
 root.add_child(battle)
 var unit = actor(battle)
 var hp: int = unit.max_hp
 var damage: int = unit.attack_damage
 var cooldown: float = unit.attack_cooldown
 var size: float = unit.visual.scale.x
 check(C.get_rarity("anubis") == "legendary" and C.get_role("anubis") == "exploder" and C.get_species("anubis") == "divine_humanoid","legendary divine burst")
 check(C.get_base_cost("anubis") == 12.0,"cost12")
 check("anubis" in SHOP.get_monster_pool("legendary") and SHOP.get_monster_probability("anubis") > 0,"gacha inclusion")
 check(unit.visual.sprite_frames.get_frame_count("attack") == 5,"normal real5 attackframes")
 check(COMMON.get_yellow_ratio(unit) < 0,"no unused yellow gauge")
 unit.current_hp = hp/2
 unit.update_army_counts(20,1)
 check(unit.max_hp == hp*2 and unit.attack_damage == damage*2,"20mummies double stats")
 check(absi(unit.current_hp-hp) <= 1,"preserve damaged HP ratio")
 check(is_equal_approx(unit.attack_cooldown,cooldown/2) and is_equal_approx(unit.visual.scale.x,size*1.06),"speed and slight visual growth")
 unit.update_army_counts(20,1)
 check(unit.max_hp == hp*2,"repeat tick does not compound")
 for pair in [[10,0.9],[20,0.8],[30,0.5],[9,1.0]]:
  unit.update_army_counts(0,pair[0])
  check(is_equal_approx(unit.runtime_additions.damage_multiplier,pair[1]),"crowd replacement"+str(pair[0]))
 unit.update_army_counts(0,1)
 check(is_equal_approx(unit.visual.scale.x,size),"size returns without mummies")
 unit.current_hp = unit.max_hp
 unit.on_mummy_death()
 check(COMMON.shield_value(unit,"melee") == 15 and COMMON.shield_value(unit,"ranged") == 20,"base death shields")
 for mode in D.MODES:
  var other = actor(battle)
  other.configure_special_augments({mode:{}})
  for i in range(12): other.on_mummy_death()
  var config: Dictionary = D.MODES[mode]
  check(COMMON.shield_value(other,config.kind) == int(config.production*12),"converted stack exact:"+mode)
  check(is_equal_approx(other.runtime_additions.hp_multiplier,1.25),"threshold boost:"+mode)
  check(COMMON.shield_value(other,"melee" if config.kind != "melee" else "ranged") == 0,"exclusive production:"+mode)
  other.free()
 var consumed = actor(battle)
 consumed.configure_special_augments({"anubis_melee":{}})
 for i in range(9): consumed.on_mummy_death()
 HIT.hit(consumed,30,"melee")
 check(COMMON.shield_value(consumed,"melee") == 285 and is_equal_approx(consumed.runtime_additions.hp_multiplier,1.0),"shield consumption removes threshold immediately")
 consumed.free()
 var hero := Hero.new()
 battle.add_child(hero)
 unit.configure_elite_passive({})
 unit.apply_visual_profile(D.ELITE_VISUAL)
 check(unit.visual.sprite_frames.get_frame_count("attack") == 6,"elite real6 attackframes")
 unit._attack_target(hero); unit._attack_target(hero)
 check(hero.hits == [damage+7,damage+14],"elite fixed7 accumulation in same melee packet")
 unit.update_army_counts(10,1)
 check(is_equal_approx(unit.runtime_additions.attack_speed_multiplier,1.5*1.3),"elite mummy extra speed")
 var registry = R.new()
 registry.setup(C.MONSTERS)
 registry.register(unit); registry.register(unit)
 check(registry.anubis_count == 1,"duplicate spawn protected")
 var mummy := Mummy.new()
 battle.add_child(mummy)
 registry.register(mummy); registry.tick()
 check(unit.mummy_count == 1,"name based global census")
 var before: float = COMMON.shield_value(unit,"melee")
 registry.retire(mummy.get_instance_id(),true); registry.retire(mummy.get_instance_id(),true)
 check(unit.mummy_count == 0 and COMMON.shield_value(unit,"melee") == before+15,"death exactly once and removes stats")
 registry.register(mummy); registry.retire(mummy.get_instance_id()); registry.tick()
 check(COMMON.shield_value(unit,"melee") == before+15,"silent removal no death shields")
 registry.reset()
 check(registry.mummy_count == 0 and registry.anubis_count == 0 and registry.leader_ids.is_empty(),"restart clears census")
 var leaders: Array = []
 for i in range(17):
  var leader = actor(battle)
  registry.register(leader); leaders.append(leader)
 mummy.monster_type = "powwow_mummy"
 registry.register(mummy)
 for i in range(3): registry.tick()
 for leader in leaders: check(leader.mummy_count == 1 and leader.anubis_count == 17,"budgeted refresh includes mummy shaman and all leaders")
 registry.retire(mummy.get_instance_id(),true)
 for leader in leaders:
  check(leader.mummy_count == 0 and COMMON.shield_value(leader,"ranged") == 20,"immediate death grants each living leader")
  leader.free()
 registry.reset()
 for id in D.MODES:
  check(A.can_acquire_special(id,[]),"first choice allowed:"+id)
  for selected in D.MODES: check(not A.can_acquire_special(id,[selected]),"three way exclusive:"+id+selected)
 var acquired: Array[String] = ["anubis_ranged"]
 for i in range(10): check(A.roll_special_candidates(["anubis"],acquired,[]).is_empty(),"exclusive choices absent from candidate roll")
 var source := FileAccess.get_file_as_string("res://src/battle/battle.gd")
 check("anubis_army_runtime.register(monster)" in source and "anubis_army_runtime.retire(monster.get_instance_id(),true)" in source,"Battle spawn/death wiring")
 check("can_acquire_special" in function_source(source,"_execute_choose_demon_augment"),"direct acquisition rejects stale choices")
 battle.free()
 print("ANUBIS_SMOKE checks=",checks," failures=",failures)
 quit(1 if failures else 0)
