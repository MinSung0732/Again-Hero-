extends SceneTree
const L := preload("res://src/monsters/LizardmanFighter.tscn")
const D := preload("res://src/data/lizardman_fighter_behavior_catalog.gd")
const C := preload("res://src/data/monster_catalog.gd")
const A := preload("res://src/data/demon_augment_catalog.gd")
const COMMON := preload("res://src/monsters/monster_runtime_common.gd")
const HIT := preload("res://src/systems/monster_hit_context.gd")
const RECEIPT := preload("res://src/systems/battle_damage_receipt.gd")
const RUNTIME := preload("res://src/systems/lizard_tail_runtime.gd")
const GRID := preload("res://src/systems/monster_local_grid.gd")
var checks := 0
var failures := 0
class Hero extends Node2D:
 var current_hp := 100000
 func take_damage(amount: int, _source: Node = null) -> bool:
  current_hp -= amount
  return true
class Fallback extends Node2D:
 var actors: Array = []
 func fill_monsters_near(_point: Vector2,_radius: float,out: Array) -> void: out.assign(actors)
func check(ok: bool,label: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(label)
func function_source(source: String,name: String) -> String:
 var start := source.find("func "+name+"(")
 var end := source.find("\nfunc ",start+1)
 return source.substr(start,end-start if end>=0 else source.length()-start)
func make_battle():
 var script := GDScript.new()
 script.source_code = '''extends Node2D
const MONSTER_CATALOG = preload("res://src/data/monster_catalog.gd")
const MONSTER_SUPPORT_COMMON = preload("res://src/monsters/monster_runtime_common.gd")
var hero: Node2D
var lizard_tail_runtime
var configs: Dictionary = {}
var summon_cost_multiplier := 1.0
var bounded := false
func _get_special_augment_config(id: String) -> Dictionary: return configs.get(id,{})
func _get_monster_augment_multiplier(_id: String,_key: String) -> float: return 1.0
func _get_demon_level_monster_hp_multiplier(_spawn_seconds: float = -1.0) -> float: return 1.0
func _get_demon_level_monster_damage_multiplier(_spawn_seconds: float = -1.0) -> float: return 1.0
func _get_demon_level_monster_speed_multiplier(_spawn_seconds: float = -1.0) -> float: return 1.0
func _clamp_manual_spawn_position(point: Vector2) -> Vector2:
 return Vector2(clampf(point.x,-1000,200),clampf(point.y,-1000,100)) if bounded else point
func invalidate_monster_spatial_snapshot() -> void: pass
'''
 var source := FileAccess.get_file_as_string("res://src/battle/battle.gd")
 for name in ["_apply_demon_level_scaling_to_monster","refresh_monster_runtime_stats","_get_special_stat_multiplier","_get_applicable_special_augment_config","_apply_special_augments_to_monster","get_monster_cost"]:
  script.source_code += "\n"+function_source(source,name).replace("\t"," ")+"\n"
 check(script.reload() == OK,"actualBattle helpers compile")
 return script.new()
func actor(battle,point: Vector2 = Vector2.ZERO):
 var unit = L.instantiate()
 C.apply_runtime_base_stats(unit,"lizardman_fighter")
 unit.position = point
 for pair in [["max_hp","demon_level_base_max_hp"],["attack_damage","demon_level_base_attack_damage"],["move_speed","demon_level_base_move_speed"],["attack_cooldown","runtime_base_attack_cooldown"]]: unit.set_meta(pair[1],unit.get(pair[0]))
 unit.configure_combat_context(battle.hero,battle)
 battle.add_child(unit)
 unit.set_physics_process(false)
 battle._apply_special_augments_to_monster(unit,"lizardman_fighter")
 return unit
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var battle = make_battle()
 root.add_child(battle)
 battle.hero = Hero.new()
 battle.hero.position = Vector2(-100,0)
 battle.add_child(battle.hero)
 battle.lizard_tail_runtime = RUNTIME.new()
 var runtime = battle.lizard_tail_runtime
 runtime.setup(battle)
 var stats: Dictionary = C.get_base_stats("lizardman_fighter")
 check(stats.max_hp == 150 and stats.attack_damage == 22,"normalized baseline")
 check(C.get_rarity("lizardman_fighter") == "uncommon" and C.get_role("lizardman_fighter") == "exploder" and C.get_species("lizardman_fighter") == "beast","advanced beastburst")
 check(battle.get_monster_cost("lizardman_fighter") == 12.0,"basecost12")
 var unit = actor(battle)
 var receipt = RECEIPT.new()
 HIT.hit(unit,104,"melee",battle.hero,receipt)
 check(unit.current_hp == 46 and not unit.tail_used,"above30percent no tail")
 HIT.hit(unit,1,"ranged",battle.hero,receipt)
 check(unit.current_hp == 45 and unit.tail_used and receipt.hp_damage == 1,"30percent threshold damage receipt")
 check(runtime.active.size() == 1,"tail spawned once")
 var tail_id: int = runtime.active.keys()[0]
 var tail = runtime.active[tail_id].visual
 check(tail.global_position.is_equal_approx(Vector2.ZERO),"tail stays at originalworld position")
 check(tail.sprite_frames.get_frame_count("idle") == 8 and tail.is_visual_ready(),"actualeffect1 8PNG connected")
 await physics_frame
 unit._physics_process(D.ESCAPE_SECONDS)
 check(unit.global_position.distance_to(Vector2(400,0)) < 0.01,"straight400 escape from attacksource")
 check(unit.escape_remaining == 0.0,"escape ends")
 HIT.hit(unit,1,"melee",battle.hero,receipt)
 check(runtime.active.size() == 1,"secondlowHPhit cannot spawn another tail")
 runtime.tick(2.0)
 check(tail.visible,"tail begins blink visible")
 runtime.tick(0.13)
 check(not tail.visible,"tail blinks off")
 runtime.tick(0.12)
 check(tail.visible,"tail blinks on")
 runtime.tick(1.0)
 check(runtime.active.is_empty() and not tail.visible,"tail expires3sec")
 var reused: int = runtime.spawn_tail(Vector2(2000,0))
 check(reused == tail_id,"tailpool reuses node")
 runtime.tick(3.0)
 battle.configs.lizardman_fighter = {"lizard_tail_regrowth":{}}
 var healed = actor(battle,Vector2(0,200))
 HIT.hit(healed,120,"melee",battle.hero,receipt)
 check(healed.current_hp == 30,"heal waits for escape completion")
 await physics_frame
 healed._physics_process(0.35)
 check(healed.current_hp == 72,"missingHP35 percent recovery")
 healed._finish_tail_escape()
 check(healed.current_hp == 72,"recovery cannot repeat")
 var lethal = actor(battle,Vector2(0,400))
 var tail_count: int = runtime.active.size()
 HIT.hit(lethal,151,"melee",battle.hero,receipt)
 check(lethal.current_hp == 0 and not lethal.tail_used and receipt.death_started and runtime.active.size() == tail_count,"lethalhit no escape revive")
 var pair = actor(battle,Vector2(405,0))
 check(COMMON.ignores_separation_pair(unit,pair),"samefamily ignores pair")
 var foreign = actor(battle,Vector2(405,0))
 foreign.set_meta("noncollision_family","")
 check(not COMMON.ignores_separation_pair(unit,foreign),"otherfamily still separates")
 var grid = GRID.new()
 grid.ensure({unit.get_instance_id():unit,pair.get_instance_id():pair},1)
 check(grid.separation_bias(unit,30.0).is_zero_approx(),"optimizedgrid ignores lizard peer")
 grid.ensure({unit.get_instance_id():unit,foreign.get_instance_id():foreign},2)
 check(not grid.separation_bias(unit,30.0).is_zero_approx(),"optimizedgrid retains otherpeer pressure")
 var fallback := Fallback.new()
 battle.add_child(fallback)
 fallback.actors = [unit,pair]
 check(COMMON.compute_soft_separation_bias(unit,fallback).is_zero_approx(),"fallback ignoreslizard pair")
 fallback.actors = [unit,foreign]
 check(not COMMON.compute_soft_separation_bias(unit,fallback).is_zero_approx(),"fallback retainsother pressure")
 check((unit.collision_mask & 2) == 0,"physicalmask excludesmonster bodies")
 battle.bounded = true
 battle.hero.position = Vector2(-50,-50)
 var boundary = actor(battle)
 HIT.hit(boundary,120,"melee",battle.hero)
 await physics_frame
 boundary._physics_process(0.35)
 check(boundary.position.y <= 100.01 and absf(boundary.position.x-boundary.position.y) < 0.01,"mapboundary escape staysstraight")
 battle.bounded = false
 var wall := StaticBody2D.new()
 wall.collision_layer = 1
 wall.position = Vector2(200,600)
 var wall_shape := CollisionShape2D.new()
 var rect := RectangleShape2D.new()
 rect.size = Vector2(20,100)
 wall_shape.shape = rect
 wall.add_child(wall_shape)
 battle.add_child(wall)
 battle.hero.position = Vector2(-100,600)
 var blocked = actor(battle,Vector2(0,600))
 HIT.hit(blocked,120,"melee",battle.hero)
 await physics_frame
 blocked._physics_process(0.35)
 check(blocked.position.x < 190 and blocked.position.x > 150 and blocked.escape_remaining == 0.0,"wall blocks escape without tunneling")
 var stunned = actor(battle,Vector2(0,800))
 HIT.hit(stunned,120,"melee",battle.hero)
 stunned.set_meta("stun_active",true)
 stunned._physics_process(0.1)
 check(stunned.position.is_equal_approx(Vector2(0,800)) and is_equal_approx(stunned.escape_remaining,0.35),"stun pauses escape")
 stunned.set_meta("stun_active",false)
 await physics_frame
 stunned._physics_process(0.35)
 check(stunned.escape_remaining == 0.0,"escape resumes after stun")
 runtime.reset()
 var first = actor(battle,Vector2(100,0))
 var second = actor(battle,Vector2(1000,0))
 first.configure_elite_passive({})
 second.configure_elite_passive({})
 runtime.spawn_tail(Vector2(105,0))
 check(first.tails_eaten == 1 and second.tails_eaten == 0 and runtime.active.is_empty(),"nearestelite consumes once immediately")
 check(first.max_hp == 153 and is_equal_approx(first.move_speed,183.6) and is_equal_approx(first.attack_cooldown,0.8/1.02),"permanentstatgrowth2percent")
 runtime.spawn_tail(Vector2(990,0))
 check(second.tails_eaten == 1,"allmap tail ingestion")
 var hp_ratio: float = float(first.current_hp)/first.max_hp
 first.current_hp = 76
 hp_ratio = float(first.current_hp)/first.max_hp
 runtime.spawn_tail(Vector2(100,0))
 check(first.max_hp == 156 and first.attack_damage == 23,"two tails add4percent not repeatedexponential")
 check(absf(float(first.current_hp)/first.max_hp-hp_ratio) < 0.005,"maxHPgrowth preserves ratio")
 battle.refresh_monster_runtime_stats(first)
 check(first.max_hp == 156 and first.attack_damage == 23,"growthrefresh not doubleapply")
 first.current_hp = 0
 runtime.spawn_tail(Vector2(100,0))
 check(first.tails_eaten == 2 and second.tails_eaten == 2,"deadclosest cannot consume")
 second.current_hp = 0
 runtime.spawn_tail(Vector2(100,0))
 check(runtime.active.size() == 1,"tail remains when no liveelite")
 var late = actor(battle)
 late.configure_elite_passive({})
 check(late.tails_eaten == 1 and runtime.active.is_empty(),"newelite consumesexistingtail immediately")
 late.configure_elite_passive({})
 check(late.tails_eaten == 1,"repeatedpassive registration safe")
 var own = actor(battle,Vector2(3000,0))
 own.configure_elite_passive({})
 HIT.hit(own,120,"melee",battle.hero)
 check(own.tail_used and own.tails_eaten == 1 and runtime.active.is_empty(),"elite can consume its own tail exactlyonce")
 own.current_hp = 0
 battle.configs.lizardman_fighter.lizard_sharp_blade = A.get_augment("lizard_sharp_blade").effect_values
 battle.configs.lizardman_fighter.lizard_clutch_mobilization = A.get_augment("lizard_clutch_mobilization").effect_values
 battle.refresh_monster_runtime_stats(late)
 check(late.attack_damage == 30,"attackaugment35percent composes withfood")
 check(is_equal_approx(battle.get_monster_cost("lizardman_fighter"),9.6),"production20percent reduction")
 var elite: Dictionary = C.get_elite_skills("lizardman_fighter")[0]
 check(elite.passive and elite.cooldown == 0.0 and elite.initial_cooldown == 0.0,"elite0/0passive")
 for profile in [D.NORMAL_VISUAL,D.ELITE_VISUAL]:
  late.apply_visual_profile(profile)
  for name in profile.animations:
   check(late.visual.sprite_frames.get_frame_count(name) == profile.animations[name].count,"framecounts:"+name)
   for i in profile.animations[name].count:
    check(late.visual.sprite_frames.get_frame_texture(name,i) != null,"realPNGloaded")
 check(COMMON.get_yellow_ratio(late) < 0.0,"no unusedyellowgauge")
 for id in C.MONSTERS.lizardman_fighter.special_augment_ids: check(not A.get_augment(id).is_empty(),"augmentregistered:"+id)
 runtime.reset()
 check(runtime.eaters.is_empty() and runtime.active.is_empty() and runtime.spare.is_empty(),"runtime reset cleanup")
 battle.queue_free()
 await process_frame
 print("Lizardman: %s checks, %s failures" % [checks,failures])
 quit(0 if failures == 0 else 1)
