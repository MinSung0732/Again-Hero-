extends SceneTree
const S := preload("res://src/monsters/LizardmanSpearman.tscn")
const F := preload("res://src/monsters/LizardmanFighter.tscn")
const D := preload("res://src/data/lizardman_spearman_behavior_catalog.gd")
const C := preload("res://src/data/monster_catalog.gd")
const A := preload("res://src/data/demon_augment_catalog.gd")
const COMMON := preload("res://src/monsters/monster_runtime_common.gd")
const HIT := preload("res://src/systems/monster_hit_context.gd")
const TAILS := preload("res://src/systems/lizard_tail_runtime.gd")
const SHOP := preload("res://src/data/shop_catalog.gd")
var checks := 0
var failures := 0
class Hero extends Node2D:
 var current_hp := 100000
 var damage_log: Array = []
 var immune := false
 func take_damage(amount: int,_source: Node = null) -> bool:
  if immune: return false
  current_hp -= amount
  damage_log.append(amount)
  return true
func check(ok: bool,label: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(label)
func function_source(s: String,name: String) -> String:
 var start := s.find("func "+name+"(")
 var end := s.find("\nfunc ",start+1)
 return s.substr(start,end-start if end>=0 else s.length()-start)
func make_battle():
 var script := GDScript.new()
 script.source_code = '''extends Node2D
const MONSTER_CATALOG = preload("res://src/data/monster_catalog.gd")
const MONSTER_SUPPORT_COMMON = preload("res://src/monsters/monster_runtime_common.gd")
const MAX_PROJECTILE_POOL_PER_TYPE = 96
var hero: Node2D
var online_match_mode := false
var online_visual_projectiles := {}
var lizard_tail_runtime
var configs: Dictionary = {}
var summon_cost_multiplier := 1.0
var projectile_pools: Dictionary = {}
var battle_entity_registry = Registry.new()
class Registry extends RefCounted:
 var retire_count := 0
 func retire_instance(_id: int) -> void: retire_count += 1
func _activate_battle_entity(_actor: Node) -> void: pass
func _get_special_augment_config(id: String) -> Dictionary: return configs.get(id,{})
func _get_monster_augment_multiplier(_id: String,_key: String) -> float: return 1.0
func _get_demon_level_monster_hp_multiplier(_spawn_seconds: float = -1.0) -> float: return 1.0
func _get_demon_level_monster_damage_multiplier(_spawn_seconds: float = -1.0) -> float: return 1.0
func _get_demon_level_monster_speed_multiplier(_spawn_seconds: float = -1.0) -> float: return 1.0
func _clamp_manual_spawn_position(point: Vector2) -> Vector2: return point
func invalidate_monster_spatial_snapshot() -> void: pass
'''
 var source := FileAccess.get_file_as_string("res://src/battle/battle.gd")
 for name in ["_apply_demon_level_scaling_to_monster","refresh_monster_runtime_stats","_get_special_stat_multiplier","_get_applicable_special_augment_config","_apply_special_augments_to_monster","_apply_special_runtime_preview","get_monster_cost","acquire_projectile","recycle_projectile"]:
  script.source_code += "\n"+function_source(source,name).replace("\t"," ")+"\n"
 check(script.reload() == OK,"actualBattle functions compile")
 return script.new()
func actor(battle,point: Vector2 = Vector2.ZERO):
 var unit = S.instantiate()
 C.apply_runtime_base_stats(unit,"lizardman_spearman")
 unit.position = point
 for pair in [["max_hp","demon_level_base_max_hp"],["attack_damage","demon_level_base_attack_damage"],["move_speed","demon_level_base_move_speed"],["attack_cooldown","runtime_base_attack_cooldown"]]: unit.set_meta(pair[1],unit.get(pair[0]))
 unit.configure_combat_context(battle.hero,battle)
 battle.add_child(unit)
 unit.set_physics_process(false)
 battle._apply_special_augments_to_monster(unit,"lizardman_spearman")
 return unit
func active_projectile(battle):
 for node in battle.get_children():
  if node is Area2D and node.get("active") == true: return node
 return null
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var battle = make_battle()
 root.add_child(battle)
 battle.hero = Hero.new()
 battle.hero.add_to_group("hero")
 battle.hero.position = Vector2(100,0)
 battle.add_child(battle.hero)
 battle.lizard_tail_runtime = TAILS.new()
 battle.lizard_tail_runtime.setup(battle)
 var unit = actor(battle)
 var base := C.get_base_stats("lizardman_spearman")
 check(base.max_hp == 150 and base.attack_damage == 28 and base.attack_range == 130.0 and is_equal_approx(base.attack_cooldown,1.2),"reviewed mediumHP damage cooldown")
 check(base.attack_range-C.get_base_stats("lizardman_fighter").attack_range == 50.0,"melee range50 longer")
 check(C.get_rarity("lizardman_spearman") == "uncommon" and C.get_species("lizardman_spearman") == "beast" and C.get_role("lizardman_spearman") == "exploder","advancedbeastburst")
 check(battle.get_monster_cost("lizardman_spearman") == 12.0,"cost12")
 for id in C.ORDER:
  if C.get_rarity(id) == "uncommon": check(C.get_grade_label(C.get_grade(id)) == "고급","advancedKoreanlabel:"+id)
 check(C.get_grade_label("advanced") == "고급" and C.get_grade_label("common") == "일반","gradealias compatibility")
 check("lizardman_spearman" in SHOP.get_monster_pool("uncommon") and SHOP.get_monster_probability("lizardman_spearman") > 0.0,"gacha registered")
 var companion = F.instantiate()
 battle.add_child(companion)
 companion.set_physics_process(false)
 check(COMMON.ignores_separation_pair(unit,companion),"fighter/spearman share collision exclusion")
 unit._attack_target(battle.hero)
 check(battle.hero.damage_log[-1] == 28,"basic melee attack")
 var charge: Dictionary = C.get_elite_skills("lizardman_spearman")[0]
 var ready: Dictionary = C.get_elite_skills("lizardman_spearman")[1]
 unit.configure_elite_passive(charge)
 unit.configure_elite_passive(ready)
 battle.hero.position = Vector2(500,0)
 await physics_frame
 unit._physics_process(0.5)
 check(not unit.charging,"charge initialcooldown not elapsed")
 unit._physics_process(0.5)
 check(unit.charging and is_equal_approx(unit.charge_timer,15.0),"charge beginsafter1sec")
 unit._physics_process(0.01)
 check(not unit.charging and battle.hero.damage_log[-1] == 70,"chargeapproach attacks250percent")
 unit._attack_target(battle.hero)
 check(battle.hero.damage_log[-1] == 28,"nextattack normal no persistent250percent")
 unit.charge_timer = 0.0
 unit.set_meta("silence_active",true)
 unit._physics_process(0.01)
 check(not unit.charging,"silence blocksnewcharge")
 unit.set_meta("silence_active",false)
 battle.configs.lizardman_spearman = {"lizard_spear_repulse":{},"lizard_spear_footwork":{}}
 battle._apply_special_augments_to_monster(unit,"lizardman_spearman")
 unit.position = Vector2(0,300)
 battle.hero.position = Vector2(100,300)
 unit._attack_target(battle.hero)
 check(battle.hero.position.is_equal_approx(Vector2(135,300)),"closehit knocks back35")
 check(unit.reposition_remaining > 0 and unit.reposition_goal.distance_to(battle.hero.position) <= unit.attack_range,"afterattack goal within own attackrange")
 var start: Vector2 = unit.position
 await physics_frame
 unit.charge_timer = 10.0
 unit.attack_timer = 1.2
 unit._physics_process(0.1)
 check(is_equal_approx(unit.attack_timer,1.1),"footwork does not freeze attackcooldown")
 check(unit.position.distance_to(start)>1.0,"footwork moves physically ratherthan teleport")
 battle.hero.position = unit.global_position+Vector2(170,0)
 var far_pos: Vector2 = battle.hero.position
 unit.on_spear_contact(battle.hero)
 check(battle.hero.position.is_equal_approx(far_pos),"farhit no weakknockback")
 battle.hero.position = unit.global_position+Vector2(100,0)
 battle.hero.set_meta("movement_effect_immune",true)
 far_pos = battle.hero.position
 unit.on_spear_contact(battle.hero)
 check(battle.hero.position.is_equal_approx(far_pos),"knockback respectsmovement immunity")
 battle.hero.remove_meta("movement_effect_immune")
 var before_ratio: float = float(unit.current_hp)/unit.max_hp
 battle.configs.lizardman_spearman.lizard_spear_throw = A.get_augment("lizard_spear_throw").effect_values
 unit.charging = true
 unit.charge_bonus_pending = true
 battle._apply_special_augments_to_monster(unit,"lizardman_spearman")
 check(unit.monster_role == "ranged" and unit.max_hp == 90 and unit.attack_damage == 38,"ranged conversion lowHP highdamage")
 check(is_equal_approx(unit.attack_range,185.0) and is_equal_approx(unit.projectile_speed,280.0) and is_equal_approx(unit.attack_cooldown,0.75),"diameter370 speed280 fastcooldown")
 check(not unit.charging and not unit.charge_bonus_pending,"conversion cancelschargebonus")
 check(absf(float(unit.current_hp)/unit.max_hp-before_ratio)<0.01,"conversion preservesHPratio")
 var detail := {"max_hp":150,"attack_damage":28,"move_speed":180.0,"attack_cooldown":1.2,"attack_type":"melee"}
 battle._apply_special_runtime_preview(detail,"lizardman_spearman")
 check(detail.role == "ranged" and detail.attack_type == "ranged" and detail.attack_type_label == "원거리" and detail.max_hp == 90 and detail.attack_range == 185.0,"run detailmode stats/type/range")
 unit.position = Vector2(0,1000)
 battle.hero.position = Vector2(100,1000)
 unit.reposition_remaining = 0.0
 var count_before: int = battle.hero.damage_log.size()
 unit._attack_target(battle.hero)
 var p = active_projectile(battle)
 check(p != null and battle.hero.damage_log.size() == count_before,"rangedfires without instantdamage")
 check(p.speed == 280.0 and p.max_range == 185.0 and p.damage == 38,"projectile snapshot speed/range/damage")
 check(unit.ready_stacks == 1 and is_equal_approx(unit.attack_cooldown,0.75/1.02),"first rangedattack2percentready")
 p._on_body_entered(battle.hero)
 check(battle.hero.damage_log[-1] == 38,"projectile actualimpactdamage")
 p._on_body_entered(battle.hero)
 check(battle.hero.damage_log.size() == count_before+1,"projectile cannot doublehit")
 await process_frame
 check(battle.projectile_pools.lizard_spear_projectile.size() == 1,"actualBattlepool recycled projectile")
 var reused_id: int = p.get_instance_id()
 unit._attack_target(battle.hero)
 p = active_projectile(battle)
 check(p.get_instance_id() == reused_id,"projectile reuses poolednode")
 battle.hero.immune = true
 count_before = battle.hero.damage_log.size()
 far_pos = battle.hero.position
 p._on_body_entered(battle.hero)
 check(battle.hero.damage_log.size() == count_before and battle.hero.position.is_equal_approx(far_pos),"immunehit no damageor knockback")
 await process_frame
 battle.hero.immune = false
 for i in range(25):
  unit._attack_target(battle.hero)
  p = active_projectile(battle)
  p._finish()
 check(unit.ready_stacks == 20 and is_equal_approx(unit.attack_cooldown,0.75/1.40),"ready caps20stacks40percent")
 battle.refresh_monster_runtime_stats(unit)
 check(is_equal_approx(unit.attack_cooldown,0.75/1.40) and unit.max_hp == 90,"refreshpreserves stacks no repeatedgrowth")
 unit.charge_timer = 0.0
 unit.reposition_remaining = 0.0
 unit.attack_timer = 10.0
 unit._physics_process(0.01)
 check(not unit.charging,"ranged never startscharge")
 unit._attack_target(battle.hero)
 p = active_projectile(battle)
 var p_start: Vector2 = p.position
 p._physics_process(0.5)
 check(is_equal_approx(p.position.distance_to(p_start),140.0),"projectilemoves280 persecond")
 p._physics_process(1.0)
 check(not p.active and is_equal_approx(p.position.distance_to(p_start),185.0),"projectile range capped185")
 var tail_count: int = battle.lizard_tail_runtime.active.size()
 HIT.hit(unit,64,"melee",battle.hero)
 check(unit.tail_used and unit.escape_remaining>0 and battle.lizard_tail_runtime.active.size() == tail_count+1,"rangedmode sharedtailescape threshold")
 check(not unit.eater_active,"spearelite has no warriornutrition")
 unit._physics_process(0.35)
 check(unit.escape_remaining == 0.0,"sharedtailescape completes")
 for profile in [D.NORMAL_VISUAL,D.ELITE_VISUAL]:
  unit.apply_visual_profile(profile)
  for key in D.ANIMATIONS:
   check(unit.visual.sprite_frames.get_frame_count(key) == D.ANIMATIONS[key].count,"actualframes:"+key)
   for i in D.ANIMATIONS[key].count: check(unit.visual.sprite_frames.get_frame_texture(key,i) != null,"realPNGframe")
 for elite in [false,true]:
  unit.set_meta("visual_variant","elite" if elite else "normal")
  unit._attack_target(battle.hero)
  p = active_projectile(battle)
  check(p.visual.is_visual_ready() and p.visual.sprite_frames.get_frame_texture("idle",0) != null,"normal/elite existingprojectitlePNG")
  p._finish()
 unit._attack_target(battle.hero)
 p = active_projectile(battle)
 var old_life: int = p.life_revision
 p._on_body_entered(battle.hero)
 p._finish()
 unit._attack_target(battle.hero)
 p = active_projectile(battle)
 p._finish(old_life)
 check(p.active,"stale deferredfinish cannot recycle new projectilelife")
 p._finish()
 var giant = actor(battle,Vector2(5000,0))
 giant.melee_range_snapshot = -1.0
 giant.attack_range = 195.0
 giant.configure_special_augments({})
 check(is_equal_approx(giant.attack_range,195.0),"modeconfig preserves preapplied giantmeleerange")
 giant.configure_special_augments({"lizard_spear_throw":A.get_augment("lizard_spear_throw").effect_values})
 check(is_equal_approx(giant.attack_range,277.5),"rangedconversion preserves giant rangefactor")
 check(COMMON.get_yellow_ratio(unit) < 0.0,"no unusedyellowgauge")
 for id in C.MONSTERS.lizardman_spearman.special_augment_ids: check(not A.get_augment(id).is_empty(),"namedaugment registered:"+id)
 battle.lizard_tail_runtime.reset()
 battle.queue_free()
 await process_frame
 print("Spearman: %s checks, %s failures" % [checks,failures])
 quit(0 if failures == 0 else 1)
