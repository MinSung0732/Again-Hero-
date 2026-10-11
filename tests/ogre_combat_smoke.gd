extends SceneTree
const OGRE := preload("res://src/monsters/Ogre.tscn")
const DATA := preload("res://src/data/ogre_behavior_catalog.gd")
const CATALOG := preload("res://src/data/monster_catalog.gd")
const AUGMENTS := preload("res://src/data/demon_augment_catalog.gd")
const COMMON := preload("res://src/monsters/monster_runtime_common.gd")
const HIT := preload("res://src/systems/monster_hit_context.gd")
const RECEIPT := preload("res://src/systems/battle_damage_receipt.gd")
var checks := 0
var failures := 0
class FixedOgre extends "res://src/monsters/ogre.gd":
 var roll := 1.0
 func _roll_fat() -> float: return roll
class Hero extends Node2D:
 var current_hp := 100000
 var reflected_hits := 0
 var bounce := false
 func take_damage(amount: int, source: Node = null) -> bool:
  current_hp -= amount
  reflected_hits += 1
  if bounce: preload("res://src/systems/monster_hit_context.gd").hit(source,10,"melee",self)
  return true
func check(ok: bool, label: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(label)
func function_source(source: String, name: String) -> String:
 var start := source.find("func "+name+"(")
 var finish := source.find("\nfunc ",start+1)
 return source.substr(start,finish-start if finish >= 0 else source.length()-start)
func make_battle():
 var script := GDScript.new()
 script.source_code = '''extends Node2D
const MONSTER_CATALOG = preload("res://src/data/monster_catalog.gd")
const MONSTER_SUPPORT_COMMON = preload("res://src/monsters/monster_runtime_common.gd")
var hero: Node2D
var configs: Dictionary = {}
var special_summon_counts: Dictionary = {}
var summon_cost_multiplier := 1.0
var cost_normal_multiplier := 1.0
func _get_special_augment_config(id: String) -> Dictionary: return configs.get(id,{})
func _get_monster_augment_multiplier(_id: String,_stat: String) -> float: return cost_normal_multiplier
func _get_demon_level_monster_hp_multiplier() -> float: return 1.0
func _get_demon_level_monster_damage_multiplier() -> float: return 1.0
func _get_demon_level_monster_speed_multiplier() -> float: return 1.0
'''
 var source := FileAccess.get_file_as_string("res://src/battle/battle.gd")
 for name in ["_apply_demon_level_scaling_to_monster","refresh_monster_runtime_stats","_get_special_stat_multiplier","_get_applicable_special_augment_config","_apply_special_augments_to_monster","_configure_summon_cadence","get_monster_cost","_apply_special_runtime_preview"]:
  script.source_code += "\n"+function_source(source,name).replace("\t"," ")+"\n"
 check(script.reload() == OK,"actual Battle functions compile")
 return script.new()
func actor(battle, fixed: bool = false):
 var a = FixedOgre.new() if fixed else OGRE.instantiate()
 if fixed:
  var visual = preload("res://src/monsters/monster_visual.gd").new()
  visual.name = "Visual"
  a.add_child(visual)
  var collider := CollisionShape2D.new()
  collider.name = "CollisionShape2D"
  collider.shape = CircleShape2D.new()
  a.add_child(collider)
 CATALOG.apply_runtime_base_stats(a,"ogre")
 for pair in [["max_hp","demon_level_base_max_hp"],["attack_damage","demon_level_base_attack_damage"],["move_speed","demon_level_base_move_speed"],["attack_cooldown","runtime_base_attack_cooldown"]]:
  a.set_meta(pair[1],a.get(pair[0]))
 a.configure_combat_context(battle.hero,battle)
 battle.add_child(a)
 a.set_physics_process(false)
 return a
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var battle = make_battle()
 root.add_child(battle)
 battle.hero = Hero.new()
 battle.add_child(battle.hero)
 var stats: Dictionary = CATALOG.get_base_stats("ogre")
 check(stats.max_hp == 420 and stats.attack_damage == 18,"normalized tank baseline")
 check(CATALOG.get_base_cost("ogre") == 20.0,"cost20")
 check(CATALOG.get_rarity("ogre") == "uncommon" and CATALOG.get_species("ogre") == "beast","advanced beast")
 var a = actor(battle)
 a.on_spawn_stats_finalized()
 check(a.get_meta("melee_shield_hp") == 420,"spawn shield equals maxHP")
 a.on_spawn_stats_finalized()
 check(a.get_meta("melee_shield_hp") == 420,"finalize idempotent")
 battle._configure_summon_cadence(a,"ogre")
 check(battle.special_summon_counts.is_empty(),"pre-augment summons not counted")
 var receipt = RECEIPT.new()
 HIT.hit(a,100,"melee",battle.hero,receipt)
 check(a.current_hp == 420 and receipt.shield_absorbed == 100,"first melee shield receipt")
 HIT.hit(a,100,"melee",battle.hero,receipt)
 HIT.hit(a,100,"melee",battle.hero,receipt)
 check(a.get_meta("melee_shield_hp") == 150 and receipt.shield_absorbed == 70,"third melee reduces30 percent before shield")
 HIT.hit(a,100,"ranged",battle.hero,receipt)
 check(a.current_hp == 320 and a.get_meta("melee_shield_hp") == 150,"ranged bypasses melee shield")
 HIT.hit(a,100,"ranged",battle.hero,receipt)
 HIT.hit(a,100,"ranged",battle.hero,receipt)
 check(receipt.hp_damage == 100,"third ranged not reduced")
 var before: int = a.hit_count
 HIT.hit(a,0,"melee",battle.hero)
 check(a.hit_count == before,"zero damage not counted")
 var medium: Dictionary = AUGMENTS.get_augment("ogre_great_blood").effect_values
 battle.configs.ogre = {"ogre_great_blood":medium}
 var army: Array = []
 for index in range(20):
  var unit = actor(battle)
  battle._apply_special_augments_to_monster(unit,"ogre")
  battle._configure_summon_cadence(unit,"ogre")
  unit.on_spawn_stats_finalized()
  army.append(unit)
  check(unit.medium_variant == ((index+1)%10 == 0),"only10th/20th replaced: "+str(index+1))
 var m = army[9]
 check(m.max_hp == 630 and m.attack_damage == 27,"mediumHP/ATK1.5")
 check(is_equal_approx(m.scale.x,1.15) and is_equal_approx(m.move_speed,71.5),"mediumsize15 percent/speed10percent")
 check(m.get_meta("melee_shield_hp") == 630,"mediumshield uses finalHP")
 HIT.hit(m,100,"melee",battle.hero,receipt)
 check(receipt.shield_absorbed == 80,"mediummelee20 percent reduction")
 HIT.hit(m,100,"ranged",battle.hero,receipt)
 check(receipt.hp_damage == 100,"mediumranged no reduction")
 HIT.hit(m,100,"melee",battle.hero,receipt)
 check(receipt.shield_absorbed == 56,"medium and thirdhit multiplicative")
 m.configure_summon_variant("ogre_great_blood",true)
 battle.refresh_monster_runtime_stats(m)
 check(m.max_hp == 630 and is_equal_approx(m.scale.x,1.15),"medium refresh never double scales")
 var fury: Dictionary = AUGMENTS.get_augment("ogre_war_fury").effect_values
 battle.configs.ogre.ogre_war_fury = fury
 var old_shield: int = m.get_meta("melee_shield_hp")
 var old_ratio: float = float(m.current_hp)/m.max_hp
 battle._apply_special_augments_to_monster(m,"ogre")
 check(m.max_hp == 315 and m.attack_damage == 95,"medium/fury compose")
 check(absf(float(m.current_hp)/m.max_hp-old_ratio) < 0.005,"transform preservesHP ratio")
 check(m.get_meta("melee_shield_hp") == old_shield,"augment refresh does not refill shield")
 var furious = actor(battle)
 battle._apply_special_augments_to_monster(furious,"ogre")
 furious.on_spawn_stats_finalized()
 check(furious.max_hp == 210 and furious.attack_damage == 63,"furyHPmedium ATKhigh")
 check(furious.monster_role == "exploder" and is_equal_approx(furious.move_speed,130.0) and is_equal_approx(furious.attack_cooldown,1.04),"fury actual role speed cooldown")
 check(furious.get_meta("melee_shield_hp") == 210,"new fury shield based on finalHP")
 battle.refresh_monster_runtime_stats(furious)
 check(furious.max_hp == 210 and furious.attack_damage == 63,"fury stable across growthrefresh")
 var detail := {"max_hp":420,"attack_damage":18,"move_speed":65.0,"attack_cooldown":2.6}
 battle._apply_special_runtime_preview(detail,"ogre")
 check(detail.max_hp == 210 and detail.attack_damage == 63 and detail.role == "exploder" and is_equal_approx(detail.attack_cooldown,1.04),"run UI matches transformed stats")
 battle.configs.ogre.ogre_mass_production = AUGMENTS.get_augment("ogre_mass_production").effect_values
 check(battle.get_monster_cost("ogre") == 15.0,"productioncost25 percent lower")
 battle.cost_normal_multiplier = 0.96
 check(battle.get_monster_cost("ogre") == 14.4,"discount composes with normalcost")
 var elite = actor(battle,true)
 elite.set_meta("visual_variant","elite")
 battle._apply_special_augments_to_monster(elite,"ogre")
 check(not elite.special_augment_configs.has("ogre_great_blood"),"elite excludes medium augment")
 var cadence_before: int = battle.special_summon_counts["ogre:ogre_great_blood"]
 battle._configure_summon_cadence(elite,"ogre")
 check(battle.special_summon_counts["ogre:ogre_great_blood"] == cadence_before,"elite never advances normal cadence")
 var split = actor(battle)
 split.set_meta("split_child",true)
 battle._configure_summon_cadence(split,"ogre")
 check(battle.special_summon_counts["ogre:ogre_great_blood"] == cadence_before,"split never advances cadence")
 battle.configs.ogre.erase("ogre_war_fury")
 battle._apply_special_augments_to_monster(elite,"ogre")
 elite.configure_elite_passive({})
 elite.set_meta("demon_level_base_max_hp",1260.0)
 battle.refresh_monster_runtime_stats(elite)
 elite.on_spawn_stats_finalized()
 check(elite.get_meta("melee_shield_hp") == 1260,"elite shield follows eliteHP")
 elite.roll = 0.049
 HIT.hit(elite,100,"melee",battle.hero,receipt)
 check(receipt.hp_damage == 0 and receipt.shield_absorbed == 0 and not receipt.accepted,"nullify includes shields and accurate receipt")
 var hero_hp: int = battle.hero.current_hp
 elite.roll = 0.05
 HIT.hit(elite,100,"melee",battle.hero,receipt)
 check(battle.hero.current_hp == hero_hp-80 and receipt.shield_absorbed == 100,"reflection80 percent still takes hit")
 elite.roll = 0.099
 hero_hp = battle.hero.current_hp
 HIT.hit(elite,100,"melee",battle.hero,receipt)
 check(receipt.shield_absorbed == 70 and battle.hero.current_hp == hero_hp-56,"reflect uses thirdhit mitigated damage")
 elite.roll = 0.10
 hero_hp = battle.hero.current_hp
 HIT.hit(elite,100,"melee",battle.hero,receipt)
 check(battle.hero.current_hp == hero_hp and receipt.shield_absorbed == 100,"10percent upper boundary excludeseliteproc")
 elite.roll = 0.0
 HIT.hit(elite,100,"ranged",battle.hero,receipt)
 check(receipt.hp_damage == 100,"elite never nullifies ranged")
 elite.roll = 0.06
 battle.hero.bounce = true
 var hero_hits: int = battle.hero.reflected_hits
 HIT.hit(elite,100,"melee",battle.hero,receipt)
 check(battle.hero.reflected_hits == hero_hits+1,"reflection cannot recurse through counterhit")
 for profile in [DATA.NORMAL_VISUAL,DATA.ELITE_VISUAL]:
  a.apply_visual_profile(profile)
  for key in DATA.ANIMATIONS:
   check(a.visual.sprite_frames.get_frame_count(key) == DATA.ANIMATIONS[key].count,"existingPNG frames: "+key)
  check(a.visual.sprite_frames.get_frame_count("attack") == 4,"actual attack files4 override stale manifest6")
 check(COMMON.get_yellow_ratio(a) < 0.0,"no unused yellowgauge")
 var dead = actor(battle)
 dead.current_hp = 10
 HIT.hit(dead,100,"ranged",battle.hero,receipt)
 check(dead.current_hp == 0 and receipt.hp_damage == 10 and receipt.death_started,"lethal receipt caps damage and reportsdeath")
 var dead_hits: int = dead.hit_count
 HIT.hit(dead,100,"melee",battle.hero,receipt)
 check(dead.hit_count == dead_hits and not receipt.accepted,"dead actor ignores hit and eliteproc")
 var selected := CATALOG.get_elite_skills("ogre")
 check(selected[0].passive and selected[0].cooldown == 0.0 and selected[0].initial_cooldown == 0.0,"elitepassive0/0")
 for id in CATALOG.MONSTERS.ogre.special_augment_ids:
  check(not AUGMENTS.get_augment(id).is_empty(),"namedaugment registered: "+id)
 battle.queue_free()
 await process_frame
 print("Ogre: %s checks, %s failures" % [checks,failures])
 quit(0 if failures == 0 else 1)
