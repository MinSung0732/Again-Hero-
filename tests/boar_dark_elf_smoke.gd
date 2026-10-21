extends SceneTree
## Real actors, projectile pool, Catalog and extracted Battle/elite functions; Hero receiver is an adapter.
const BOAR := preload("res://src/monsters/Boar.tscn")
const ARCHER := preload("res://src/monsters/DarkElfArcher.tscn")
const C := preload("res://src/data/monster_catalog.gd")
const A := preload("res://src/data/demon_augment_catalog.gd")
const COMMON := preload("res://src/monsters/monster_runtime_common.gd")
const HIT := preload("res://src/systems/monster_hit_context.gd")
const SHOP := preload("res://src/data/shop_catalog.gd")
const ELITE := preload("res://src/systems/elite_monster_skill_runtime.gd")
var checks := 0
var failures := 0
class Hero extends Node2D:
 var current_hp := 100000
 var immune := false
 var shield_hp := 0
 var normal_hits: Array[int] = []
 var followup_hits: Array[int] = []
 func take_damage(amount: int,_source: Node = null) -> bool:
  if immune: return false
  normal_hits.append(amount)
  _receive(amount)
  return true
 func take_followup_damage(amount: int,_source: Node = null) -> bool:
  followup_hits.append(amount)
  _receive(amount)
  return true
 func _receive(amount: int) -> void:
  var absorbed := mini(shield_hp,amount)
  shield_hp -= absorbed
  current_hp -= amount-absorbed
class Audio extends Node:
 func play_battle(_key: String,_battle: Node) -> void: pass
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
const MONSTER_CATALOG = preload("res://src/data/monster_catalog.gd")
const MONSTER_SUPPORT_COMMON = preload("res://src/monsters/monster_runtime_common.gd")
const MAX_PROJECTILE_POOL_PER_TYPE = 96
var hero: Node2D
var online_match_mode := false
var online_visual_projectiles := {}
var configs: Dictionary = {}
var summon_cost_multiplier := 1.0
var projectile_pools: Dictionary = {}
var battle_entity_registry = Registry.new()
class Registry extends RefCounted:
 func retire_instance(_id: int) -> void: pass
func _activate_battle_entity(_actor: Node) -> void: pass
func _get_special_augment_config(id: String) -> Dictionary: return configs.get(id,{})
func _get_monster_augment_multiplier(_id: String,_key: String) -> float: return 1.0
func _get_demon_level_monster_hp_multiplier(_spawn_seconds: float = -1.0) -> float: return 1.0
func _get_demon_level_monster_damage_multiplier(_spawn_seconds: float = -1.0) -> float: return 1.0
func _get_demon_level_monster_speed_multiplier(_spawn_seconds: float = -1.0) -> float: return 1.0
func _clamp_manual_spawn_position(point: Vector2) -> Vector2: return point.clamp(Vector2(-5000,-5000),Vector2(5000,5000))
func invalidate_monster_spatial_snapshot() -> void: pass
'''
 var source := FileAccess.get_file_as_string("res://src/battle/battle.gd")
 for name in ["_apply_demon_level_scaling_to_monster","_get_special_stat_multiplier","_get_applicable_special_augment_config","_apply_special_augments_to_monster","get_monster_cost","acquire_projectile","recycle_projectile"]:
  script.source_code += "\n"+function_source(source,name).replace("\t"," ")+"\n"
 check(script.reload() == OK,"real Battle stats/cost/pool functions compile")
 return script.new()
func actor(scene: PackedScene,id: String,battle):
 var unit = scene.instantiate()
 C.apply_runtime_base_stats(unit,id)
 for pair in [["max_hp","demon_level_base_max_hp"],["attack_damage","demon_level_base_attack_damage"],["move_speed","demon_level_base_move_speed"]]: unit.set_meta(pair[1],unit.get(pair[0]))
 unit.configure_combat_context(battle.hero,battle)
 battle.add_child(unit)
 unit.set_physics_process(false)
 battle._apply_special_augments_to_monster(unit,id)
 return unit
func arrows(battle) -> Array:
 var result: Array = []
 for node in battle.get_children():
  if node is Area2D and node.get("active") == true and not node.get("impacting"): result.append(node)
 return result
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var battle = make_battle()
 root.add_child(battle)
 battle.hero = Hero.new(); battle.hero.add_to_group("hero"); battle.add_child(battle.hero)
 var unit = actor(BOAR,"boar",battle)
 var archer = actor(ARCHER,"dark_elf_archer",battle)
 for id in ["boar","dark_elf_archer"]:
  var rarity := C.get_rarity(id)
  check(id in SHOP.get_monster_pool(rarity) and SHOP.get_monster_probability(id)>0.0,"gacha:"+id)
  var pool := SHOP.get_monster_pool(rarity)
  check(SHOP.roll_monster(rarity,(pool.find(id)+0.5)/pool.size()) == id,"deterministic gacha roll:"+id)
  check(C.get_role(id) == ("exploder" if id == "boar" else "ranged"),"role:"+id)
  check(C.get_species(id) == ("beast" if id == "boar" else "humanoid"),"species:"+id)
 check(C.get_base_stats("boar").max_hp == 120 and C.get_base_stats("boar").attack_damage == 74,"reviewedboar120/74")
 check(C.get_base_stats("dark_elf_archer").max_hp == 97 and C.get_base_stats("dark_elf_archer").attack_damage == 30,"reviewedarcher97/30")
 check(battle.get_monster_cost("boar") == 8 and battle.get_monster_cost("dark_elf_archer") == 12,"balanced costs")
 check(unit.attack_range == 275 and archer.attack_range == 375 and archer.projectile_speed == 280,"diameter550/750 and280 arrow speed")
 check(is_equal_approx(unit.visual.scale.x*unit.visual.sprite_frames.get_frame_texture("idle",0).get_height(),130*1.21),"boar121percent")
 check(is_equal_approx(archer.visual.scale.x*archer.visual.sprite_frames.get_frame_texture("idle",0).get_height(),140*1.18),"archer118percent")
 check(COMMON.get_yellow_ratio(unit)<0 and COMMON.get_yellow_ratio(archer)<0,"no unused yellow gauges")
 for pair in [[unit,6,4],[archer,7,5]]:
  check(pair[0].visual.sprite_frames.get_frame_count("attack") == pair[1] and pair[0].visual.sprite_frames.get_frame_count("death") == pair[2],"normal original frames")
 unit.apply_visual_profile(C.MONSTERS.boar.elite_visual); archer.apply_visual_profile(C.MONSTERS.dark_elf_archer.elite_visual)
 check(is_equal_approx(unit.visual.scale.x*unit.visual.sprite_frames.get_frame_texture("idle",0).get_height(),150*1.21),"elite boar121percent")
 check(is_equal_approx(archer.visual.scale.x*archer.visual.sprite_frames.get_frame_texture("idle",0).get_height(),160*1.18),"elite archer118percent")
 check(unit.visual.sprite_frames.get_frame_count("attack") == 6 and archer.visual.sprite_frames.get_frame_count("attack") == 6,"elite original frames")
 battle.hero.position = Vector2(140,0)
 unit._begin_dash(battle.hero)
 check(unit.phase == unit.Phase.WINDUP and is_equal_approx(unit.windup_remaining,0.3),"windup0.3")
 unit._physics_process(0.1)
 check(unit.global_position == Vector2.ZERO and battle.hero.normal_hits.is_empty(),"no hit/movement while concentrating")
 unit._physics_process(0.2)
 check(unit.phase == unit.Phase.DASH and unit.dash_speed == 50,"launch minimum50")
 unit._tick_dash(0.5)
 check(is_equal_approx(unit.dash_speed,237.5),"gradual acceleration")
 unit._tick_dash(0.5)
 check(unit.dash_speed == 425 and battle.hero.normal_hits == [74],"max425 swept melee contact")
 battle.hero.position = Vector2(140,300)
 for i in range(40):
  if unit.phase != unit.Phase.DASH: break
  unit._tick_dash(0.1)
 check(is_equal_approx(unit.dash_traveled,900) and is_zero_approx(unit.position.y),"900 straight locked direction")
 check(battle.hero.normal_hits.size() == 1 and unit.phase == unit.Phase.IDLE and unit.attack_timer == unit.attack_cooldown,"onehit per dash and postdash cooldown")
 unit.position = Vector2.ZERO; battle.hero.position = Vector2(100,0)
 unit.configure_special_augments({"boar_instant":{},"boar_third_charge":{}})
 for i in range(2,5):
  unit._begin_dash(battle.hero)
  check(unit.phase == unit.Phase.DASH and unit.dash_speed == (200 if i == 3 else 50),"third dash only:"+str(i))
  unit._finish_dash(false)
 unit.configure_special_augments({})
 unit._begin_dash(battle.hero); unit.set_meta("stun_active",true); unit._physics_process(0.05)
 check(unit.phase == unit.Phase.IDLE,"stun cancels windup")
 check(not unit.try_cast_elite_skill({}),"stunned elite blocked")
 unit.remove_meta("stun_active")
 check(unit.try_cast_elite_skill({}) and unit.frenzy_remaining == 10,"elite ten seconds")
 unit.configure_special_augments({"boar_instant":{}}); unit._begin_dash(battle.hero)
 var count: int = unit.dash_count
 unit.dash_traveled = 899.0; unit.dash_speed = 425; unit._tick_dash(0.01)
 check(unit.phase == unit.Phase.DASH and unit.dash_count == count+1,"elite chains immediately without windup/cooldown")
 unit._finish_dash()
 check(unit.phase == unit.Phase.IDLE and unit.attack_timer == unit.attack_cooldown and unit.frenzy_remaining > 0,"extra dash ends with normal cooldown while buff remains")
 unit.frenzy_remaining = 0.0; unit._finish_dash()
 check(unit.phase == unit.Phase.IDLE and unit.attack_timer == unit.attack_cooldown,"normal cooldown resumes after elite")
 battle.configs.boar = {"boar_tusk":A.get_augment("boar_tusk").effect_values}
 battle._apply_demon_level_scaling_to_monster(unit,false)
 check(unit.attack_damage == 96,"attack30percent")
 archer.attack_timer = 1000; archer.hero = null; archer._physics_process(2.9)
 check(not archer.stealth_active,"no early stealth")
 archer._physics_process(0.11)
 check(archer.stealth_active and is_equal_approx(archer.visual.self_modulate.a,0.4),"three seconds stealth visual")
 var hp: int = archer.current_hp
 HIT.hit(archer,20,"melee")
 check(archer.current_hp == hp-10 and archer.quiet_time == 0 and archer.stealth_active,"stealth50percent reduction and incominghit resets prep")
 archer.hero = battle.hero; battle.hero.position = Vector2(100,0); archer.position = Vector2.ZERO
 archer._attack_target(battle.hero)
 var active := arrows(battle)
 check(active.size() == 1 and active[0].damage == 45 and not active[0].bypass_invulnerability,"ambush150percent")
 check(not archer.stealth_active and archer.quiet_time == 0,"firing exits stealth and restarts preparation")
 var arrow = active[0]
 check(is_equal_approx(arrow.visual.scale.x*arrow.visual.sprite_frames.get_frame_texture("idle",0).get_height(),36*1.09),"projectile109percent")
 check(arrow.visual.sprite_frames.get_frame_count("idle") == 6 and arrow.visual.sprite_frames.get_frame_count("impact") == 6,"actual flight/impact effects")
 arrow._physics_process(0.1)
 check(is_equal_approx(arrow.traveled,28) and not arrow.impacting,"flight speed280")
 arrow._physics_process(0.3)
 check(arrow.impacting,"swept target contact")
 var hit_count: int = battle.hero.normal_hits.size()
 arrow._on_body_entered(battle.hero)
 check(battle.hero.normal_hits.size() == hit_count,"duplicate collision blocked")
 var revision: int = arrow.life_revision
 arrow._finish()
 var reused = battle.acquire_projectile(preload("res://src/monsters/DarkElfArrow.tscn"),"dark_elf_arrow")
 check(reused == arrow and not reused.active and not reused.bypass_invulnerability,"projectile recycled/reset")
 reused.setup(archer,Vector2.RIGHT,30,200,false)
 reused._finish(revision)
 check(reused.active,"old deferred finish cannot retire reused life")
 reused._physics_process(1.0)
 check(is_equal_approx(reused.traveled,0) and not reused.active,"range200 clamp and pool return")
 var old_position: Vector2 = archer.position
 archer._physics_process(0.1)
 check(archer.position.distance_to(old_position)>0 and archer.position.distance_to(battle.hero.position)>old_position.distance_to(battle.hero.position),"rapid safe reposition after shot")
 archer.position = Vector2(475,0); battle.hero.position = Vector2(100,0)
 archer._begin_reposition(battle.hero)
 check(archer.reposition_active and archer.reposition_goal.distance_to(battle.hero.position) >= 374.9 and archer.reposition_goal.distance_to(battle.hero.position)<=375.1,"edge of range lateral safety preserves distance")
 archer.configure_special_augments({"dark_elf_far_sight":A.get_augment("dark_elf_far_sight").effect_values,"dark_elf_shadow_shield":{}})
 archer.configure_special_augments({"dark_elf_far_sight":A.get_augment("dark_elf_far_sight").effect_values,"dark_elf_shadow_shield":{}})
 check(archer.attack_range == 562.5 and archer.projectile_range == 562.5,"range50percent no compounding")
 archer._enter_stealth()
 var shield: float = COMMON.shield_value(archer,"ranged")
 check(shield == int(round(archer.max_hp*0.1)),"stealth10percent rangedshield")
 archer._enter_stealth()
 check(COMMON.shield_value(archer,"ranged") == shield,"no repeated entry stacking")
 battle.configs.dark_elf_archer = {"dark_elf_economy":A.get_augment("dark_elf_economy").effect_values}
 check(battle.get_monster_cost("dark_elf_archer") == 9,"cost25percent")
 archer.position = Vector2.ZERO; battle.hero.position = Vector2(100,0)
 battle.hero.immune = true; battle.hero.shield_hp = 100
 check(archer.try_cast_elite_skill({}),"elite burst can start")
 for i in range(3): archer._tick_burst(0.18)
 active = arrows(battle)
 check(active.size() == 4 and archer.burst_remaining == 0,"exactly four shots")
 for shot in active:
  check(shot.damage == 38 and shot.bypass_invulnerability,"125percent bypass shot")
  shot._on_body_entered(battle.hero)
  shot._finish()
 check(battle.hero.followup_hits == [38,38,38,38] and battle.hero.shield_hp == 0,"followup route ignores immunity but still consumes shield")
 archer.try_cast_elite_skill({}); archer.set_meta("silence_active",true); archer._physics_process(0.2)
 check(archer.burst_remaining == 0,"silence cancels remaining burst")
 archer.remove_meta("silence_active")
 for id in ["boar","dark_elf_archer"]:
  var skills := C.get_elite_skills(id)
  check(skills.size() == 1 and skills[0].runtime == "monster","generic elite hook:"+id)
 check(C.get_elite_skills("boar")[0].initial_cooldown == 3 and C.get_elite_skills("boar")[0].cooldown == 20,"boar3/20")
 check(C.get_elite_skills("dark_elf_archer")[0].initial_cooldown == 2 and C.get_elite_skills("dark_elf_archer")[0].cooldown == 15,"archer2/15")
 var audio := Audio.new(); audio.name = "GameAudio"; root.add_child(audio)
 var elite = ELITE.new(); elite.setup(battle)
 unit.frenzy_remaining = 0.0
 archer.burst_remaining = 0
 elite.register_elite(unit,"boar",C.get_elite_skills("boar"))
 elite.register_elite(archer,"dark_elf_archer",C.get_elite_skills("dark_elf_archer"))
 elite.tick(1.99)
 check(unit.frenzy_remaining == 0 and archer.burst_remaining == 0,"actual elite controller opening delay")
 elite.tick(0.02)
 check(archer.burst_remaining == 3 and unit.frenzy_remaining == 0,"actual controller archer2seconds")
 elite.tick(1.0)
 check(unit.frenzy_remaining == 10,"actual controller boar3seconds")
 check(elite._skill_states[unit.get_instance_id()].skills[0]._timer == 20,"actual controller cooldown20")
 check(is_equal_approx(elite._skill_states[archer.get_instance_id()].skills[0]._timer,14.0),"actual controller cooldown15")
 elite.reset()
 check(elite._skill_states.is_empty(),"actual elite reset")
 var wall := StaticBody2D.new()
 wall.collision_layer = 1
 var collision_shape := CollisionShape2D.new()
 var shape := RectangleShape2D.new()
 shape.size = Vector2(12,200)
 collision_shape.shape = shape
 wall.add_child(collision_shape); battle.add_child(wall)
 wall.position = Vector2(60,1000)
 unit.frenzy_remaining = 0
 unit.position = Vector2(0,1000); battle.hero.position = Vector2(140,1000)
 await physics_frame
 unit.configure_special_augments({"boar_instant":{}}); unit._begin_dash(battle.hero); unit._tick_dash(0.5)
 check(unit.phase == unit.Phase.IDLE and unit.position.x < 45,"physical wall ends dash")
 battle.free()
 audio.free()
 print("BOAR_DARK_ELF_SMOKE checks=",checks," failures=",failures)
 quit(1 if failures else 0)
