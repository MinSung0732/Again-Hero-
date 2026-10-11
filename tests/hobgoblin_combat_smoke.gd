extends SceneTree
## Actual actors/runtime and Battle function source. Fixture adapters supply the
## spatial index, growth inputs, and registry; this is not a complete game match.
const H = preload("res://src/monsters/Hobgoblin.tscn")
const O = preload("res://src/monsters/orc.gd")
const G = preload("res://src/monsters/goblin.gd")
const T = preload("res://src/monsters/goblin_thrower.gd")
const D = preload("res://src/data/hobgoblin_behavior_catalog.gd")
const C = preload("res://src/data/monster_catalog.gd")
const A = preload("res://src/data/demon_augment_catalog.gd")
const R = preload("res://src/systems/goblin_formation_runtime.gd")
const COMMON = preload("res://src/monsters/monster_runtime_common.gd")
const HIT = preload("res://src/systems/monster_hit_context.gd")
var checks := 0
var failures := 0
class Hero extends Node2D:
 var current_hp := 1000000
 var shield_hp := 0
 var immune := false
 var stuns := 0
 var last_stun := 0.0
 func take_damage(amount: int, _source: Node = null) -> bool:
  if immune: return false
  current_hp -= amount
  return true
 func apply_stun(seconds: float) -> bool:
  stuns += 1
  last_stun = seconds
  return true
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(message)
func function_source(source: String, name: String) -> String:
 var start := source.find("func "+name+"(")
 if start < 0: return ""
 var finish := source.find("\nfunc ",start+1)
 return source.substr(start,finish-start if finish >= 0 else source.length()-start)
func make_battle():
 var source := FileAccess.get_file_as_string("res://src/battle/battle.gd")
 var script := GDScript.new()
 script.source_code = '''extends Node2D
const MONSTER_SUPPORT_COMMON = preload("res://src/monsters/monster_runtime_common.gd")
const MONSTER_CATALOG = preload("res://src/data/monster_catalog.gd")
const DEMON_AUGMENTS = preload("res://src/data/demon_augment_catalog.gd")
var hero: Node2D
var goblin_formation_runtime
var active_monsters: Dictionary = {}
var monster_summon_costs: Dictionary = {}
var monster_population_counts: Dictionary = {}
var monster_population_ids: Dictionary = {}
var direct_population_ids: Dictionary = {}
var active_elite_skeletons: Dictionary = {}
var monster_spatial_grid: Dictionary = {}
var monster_spatial_grid_physics_frame := -1
var monsters_alive := 0
var monster_hp_multiplier := 1.0
var monster_damage_multiplier := 1.0
var monster_speed_multiplier := 1.0
var monster_attack_speed_multiplier := 1.0
var captured_spawn: Dictionary = {}
var refreshed_ids: Array = []
var configs: Dictionary = {}
var spatial_queries := 0
var battle_entity_registry = Registry.new()
class Registry extends RefCounted:
 func retire_instance(_id: int) -> void: pass
func _get_farthest_kobolt_attack_spawn_position(_id: String) -> Vector2: return Vector2.ZERO
func _get_stage_event_spawn_position(_distance: float) -> Vector2: return Vector2.ZERO
func _spawn_monster(id: String, _point: Vector2, _cost: float, _split: bool, modifiers: Dictionary = {}):
 captured_spawn = modifiers
 if _monster_population_limit_reached(id,bool(modifiers.get("elite_variant",false))): return null
 var actor := Node2D.new()
 add_child(actor)
 return actor
func _apply_special_monster_modifiers(actor: Node, _id: String, _data: Dictionary) -> void: actor.queue_free()
func _emit_stats() -> void: pass
func _queue_population_update() -> void: pass
func _get_special_augment_config(id: String) -> Dictionary: return configs.get(id,{})
func _get_demon_level_monster_hp_multiplier() -> float: return 1.0
func _get_demon_level_monster_damage_multiplier() -> float: return 1.0
func _get_demon_level_monster_speed_multiplier() -> float: return 1.0
func _refresh_alive_monsters_for_augments(ids: Array[String] = []) -> void: refreshed_ids = ids
func _ensure_monster_spatial_grid() -> void:
 spatial_queries += 1
 monster_spatial_grid.clear()
 for id in active_monsters:
  var actor = active_monsters[id]
  if not is_instance_valid(actor) or actor.is_queued_for_deletion(): continue
  var cell = _spatial_cell_for_position(actor.global_position)
  if not monster_spatial_grid.has(cell): monster_spatial_grid[cell] = []
  monster_spatial_grid[cell].append(actor)
func _spatial_cell_for_position(point: Vector2) -> Vector2i:
 return Vector2i(floori(point.x/256.0),floori(point.y/256.0))
'''
 for name in ["spawn_special_monster","_apply_demon_level_scaling_to_monster","refresh_monster_runtime_stats","get_goblin_formation_damage_multiplier","fill_monsters_near","_get_applicable_special_augment_config","_apply_special_augments_to_monster","_get_special_stat_multiplier","_monster_population_limit_reached","_get_active_monsters_snapshot","_unregister_monster","_consume_monster_for_fusion","_refresh_monsters_for_selected_augment"]:
  var body := function_source(source,name)
  check(not body.is_empty(),"Battle function present: "+name)
  script.source_code += "\n"+body.replace("\t"," ")+"\n"
 check(script.reload() == OK,"actual Battle functions compile")
 return script.new()
func _initialize() -> void: call_deferred("run")
func add_actor(battle, id: String, point: Vector2 = Vector2.ZERO):
 var actor = H.instantiate() if id == "hobgoblin" else O.new()
 if id != "hobgoblin":
  var collider := CollisionShape2D.new()
  collider.name = "CollisionShape2D"
  actor.add_child(collider)
 actor.monster_type = id
 actor.configure_combat_context(battle.hero,battle)
 actor.position = point
 actor.set_meta("demon_level_base_max_hp",300.0)
 actor.set_meta("demon_level_base_attack_damage",24.0)
 actor.set_meta("demon_level_base_move_speed",75.0)
 actor.attack_cooldown = 2.0
 battle.add_child(actor)
 actor.set_physics_process(false)
 var key: int = actor.get_instance_id()
 battle.active_monsters[key] = actor
 battle.monster_population_ids[key] = id
 battle.monster_population_counts[id] = int(battle.monster_population_counts.get(id,0))+1
 battle.monsters_alive += 1
 return actor
func verify_frames(actor, profile: Dictionary) -> void:
 check(actor.visual.is_visual_ready(),"original sprite profile ready")
 for name in D.ANIMATIONS:
  check(actor.visual.sprite_frames.get_frame_count(name) == int(D.ANIMATIONS[name].count),"original frames: "+name)
  check(actor.visual.sprite_frames.get_animation_loop(name) == bool(D.ANIMATIONS[name].loop),"loop: "+name)
 check(is_equal_approx(actor.visual.scale.y*actor.visual.sprite_frames.get_frame_texture("idle",0).get_height(),float(profile.target_height)),"sprite height")
func run() -> void:
 var battle = make_battle()
 root.add_child(battle)
 battle.hero = Hero.new()
 battle.add_child(battle.hero)
 battle.hero.position = Vector2(500,0)
 var runtime = R.new()
 runtime.setup(battle,C.MONSTERS)
 battle.goblin_formation_runtime = runtime
 var leader = add_actor(battle,"hobgoblin")
 verify_frames(leader,D.NORMAL_VISUAL)
 leader.apply_visual_profile(D.ELITE_VISUAL)
 verify_frames(leader,D.ELITE_VISUAL)
 runtime.tick(0.0)
 check(leader.nearby_goblins == 1,"self is counted by goblin name")
 check(leader.max_hp == 302 and leader.attack_damage == 26 and leader.move_speed == 77,"flat two point growth")
 check(is_equal_approx(leader.attack_cooldown,2.0/1.02),"attack speed two percent per ally")
 check(COMMON.get_yellow_ratio(leader) < 0,"no invented yellow gauge")
 var edge = add_actor(battle,"goblin",Vector2(175,0))
 var outside = add_actor(battle,"goblin_thrower",Vector2(175.01,0))
 var non_goblin = add_actor(battle,"orc",Vector2(20,0))
 runtime.tick(0.25)
 check(leader.nearby_goblins == 2,"diameter350 exact boundary and name filter")
 edge.current_hp = 0
 runtime.tick(0.25)
 check(leader.nearby_goblins == 1 and leader.max_hp == 302,"death removes only its two points")
 outside.position = Vector2(10,0)
 runtime.tick(0.25)
 check(leader.nearby_goblins == 2,"goblin thrower included on entry")
 outside.position = Vector2(200,0)
 runtime.tick(0.25)
 check(leader.nearby_goblins == 1,"leaving removes same bonus without permanent penalty")
 var army: Array = []
 for i in range(99): army.append(add_actor(battle,"goblin",Vector2(30,0)))
 runtime.tick(0.25)
 check(leader.nearby_goblins == 100 and leader.max_hp == 2000,"100 goblins trigger 300 percent extra maximum HP")
 check(leader.attack_damage == 224 and is_equal_approx(leader.attack_cooldown,2.0/3.0),"100 units flat ATK and attack speed")
 leader.current_hp = 1000
 army[0].current_hp = 0
 runtime.tick(0.25)
 check(leader.nearby_goblins == 99 and leader.max_hp == 498 and leader.current_hp == 249,"99 removes fortress and preserves health ratio")
 var augment_configs := {"hobgoblin_iron_bond":{},"hobgoblin_shield_march":{}}
 leader.configure_special_augments(augment_configs)
 var ally = army[1]
 ally.current_hp = 1000
 HIT.hit(ally,100,"melee",battle.hero)
 check(ally.current_hp == 920,"iron bond reduces incoming damage by20 percent")
 var hp: int = non_goblin.current_hp
 HIT.hit(non_goblin,100,"melee",battle.hero)
 check(non_goblin.current_hp == hp-100,"non goblin is not protected")
 runtime.tick(2.0)
 check(int(ally.get_meta("melee_shield_hp",0)) == 30,"first shield pulse30")
 runtime.tick(2.0)
 check(int(ally.get_meta("melee_shield_hp",0)) == 60,"second pulse stacks to60")
 hp = ally.current_hp
 HIT.hit(ally,100,"ranged",battle.hero)
 check(ally.current_hp == hp-80 and int(ally.get_meta("melee_shield_hp",0)) == 60,"ranged bypasses melee shield")
 hp = ally.current_hp
 HIT.hit(ally,100,"melee",battle.hero)
 check(ally.current_hp == hp-20 and int(ally.get_meta("melee_shield_hp",0)) == 0,"melee shield absorbs after aura")
 leader.configure_special_augments({"hobgoblin_lord":{},"hobgoblin_iron_bond":{}})
 check(leader.formation_radius() == 375.0,"lord diameter750")
 outside.position = Vector2(374,0)
 runtime.tick(0.25)
 check(leader.nearby_goblins == 100,"lord radius includes distant goblin")
 leader.configure_elite_passive({})
 runtime.tick(0.0)
 check(ally.has_meta("goblin_command_leader"),"elite command issues without initial cooldown")
 var first_expiry: float = ally.get_meta("goblin_command_until",0.0)
 var second = add_actor(battle,"hobgoblin",Vector2(300,0))
 second.configure_elite_passive({})
 runtime.tick(0.25)
 check(ally.get_meta("goblin_command_leader").get_ref() == leader,"nearest leader wins")
 check(not second.has_meta("goblin_command_leader"),"elite leaders cannot order each other")
 runtime.tick(4.75)
 check(float(ally.get_meta("goblin_command_until",0.0)) > first_expiry,"command refreshes every5 seconds")
 ally.position = Vector2(150,0)
 var before: Vector2 = ally.position
 check(COMMON.follow_goblin_command(ally,0.1),"goblin uses formation movement objective")
 check(ally.position.distance_to(before) <= ally.move_speed*0.1+1,"command does not teleport")
 ally.set_meta("forced_movement_lock_until",Time.get_ticks_msec()+1000)
 check(not COMMON.follow_goblin_command(ally,0.1),"command respects forced movement locks")
 ally.remove_meta("forced_movement_lock_until")
 seed(191)
 leader.nearby_goblins = 9
 for i in range(100): leader._attack_target(battle.hero)
 check(battle.hero.stuns == 0,"9 goblins cannot stun")
 leader.nearby_goblins = 10
 for i in range(1000): leader._attack_target(battle.hero)
 check(battle.hero.stuns >= 10 and battle.hero.stuns <= 60 and battle.hero.last_stun == 1.0,"10 goblins proc seeded3 percent one second stun")
 # Check each real movement script routes the command before chasing the hero.
 for actor_script in [G,T]:
  var follower = actor_script.new()
  var collider := CollisionShape2D.new()
  collider.name = "CollisionShape2D"
  follower.add_child(collider)
  follower.configure_combat_context(battle.hero,battle)
  battle.add_child(follower)
  follower.set_physics_process(false)
  follower.position = Vector2(150,0)
  follower.set_meta("goblin_command_leader",weakref(leader))
  follower.set_meta("goblin_command_until",runtime.clock+5.0)
  follower.set_meta("goblin_command_offset",Vector2.ZERO)
  follower._physics_process(0.1)
  check(follower.velocity.x < 0,"real goblin movement follows leader rather than distant hero")
  follower.free()
 var previous_stuns: int = battle.hero.stuns
 battle.hero.immune = true
 for i in range(100): leader._attack_target(battle.hero)
 check(battle.hero.stuns == previous_stuns,"blocked hits never stun")
 battle.hero.immune = false
 second.configure_special_augments({"hobgoblin_iron_bond":{}})
 check(is_equal_approx(runtime.incoming_multiplier(ally),0.80),"multiple iron bond providers do not stack")
 second.configure_special_augments({})
 leader.current_hp = 0
 check(is_equal_approx(runtime.incoming_multiplier(ally),1.0),"dead provider removes aura immediately")
 check(not COMMON.follow_goblin_command(ally,0.1),"dead provider releases formation order")
 # Actual selection/limit functions remove existing commanders without deaths/EXP.
 var lord: Dictionary = A.get_augment("hobgoblin_lord")
 battle.configs.hobgoblin = {"hobgoblin_lord":lord.effect_values}
 var exempt = add_actor(battle,"hobgoblin",Vector2(2000,0))
 exempt.set_meta("visual_variant","elite")
 battle._refresh_monsters_for_selected_augment(lord)
 check(leader.is_queued_for_deletion() and second.is_queued_for_deletion(),"lord selection removes all existing hobgoblins")
 check(not ally.is_queued_for_deletion() and not non_goblin.is_queued_for_deletion(),"lord cleanup preserves other monsters")
 check(int(battle.monster_population_counts.get("hobgoblin",0)) == 1,"cleanup retains elite population count")
 check(not exempt.is_queued_for_deletion(),"lord selection preserves existing elite")
 check(not battle._monster_population_limit_reached("hobgoblin"),"elite alone does not consume normal lord slot")
 check(not battle._monster_population_limit_reached("hobgoblin",true),"elite spawn ignores lord cap")
 var lord_actor = add_actor(battle,"hobgoblin")
 lord_actor.configure_special_augments({"hobgoblin_lord":lord.effect_values})
 battle.refresh_monster_runtime_stats(lord_actor)
 check(lord_actor.max_hp == 6000 and lord_actor.attack_damage == 480,"lord20 bodies applies once to baseHP andATK")
 battle.refresh_monster_runtime_stats(lord_actor)
 check(lord_actor.max_hp == 6000 and lord_actor.attack_damage == 480,"refresh cannot multiply lord again")
 check(battle._monster_population_limit_reached("hobgoblin"),"lord max population one")
 check(not battle._monster_population_limit_reached("hobgoblin",true),"elite still spawns with normal lord present")
 check(battle.spawn_special_monster("hobgoblin",{"type":"elite"}),"actual elite event spawn succeeds while lord cap is full")
 check(bool(battle.captured_spawn.get("elite_variant",false)),"actual elite spawn passes exemption to spawn gate")
 battle.configs.hobgoblin.hobgoblin_iron_bond = {}
 battle.configs.hobgoblin.hobgoblin_shield_march = {}
 battle._apply_special_augments_to_monster(exempt,"hobgoblin")
 var elite_configs: Dictionary = exempt.get_meta("special_augment_configs")
 check(not elite_configs.has("hobgoblin_lord"),"elite excludes lord config")
 check(elite_configs.has("hobgoblin_iron_bond") and elite_configs.has("hobgoblin_shield_march"),"elite retains other augments")
 check(exempt.formation_radius() == 175.0,"elite keeps diameter350 without lord circle")
 exempt.set_meta("demon_level_base_max_hp",900.0)
 exempt.set_meta("demon_level_base_attack_damage",72.0)
 battle.refresh_monster_runtime_stats(exempt)
 check(exempt.max_hp == 900 and exempt.attack_damage == 72,"elite variant stats retained without20x")
 battle._apply_special_augments_to_monster(exempt,"hobgoblin")
 battle.refresh_monster_runtime_stats(exempt)
 check(exempt.max_hp == 900 and exempt.attack_damage == 72,"later refresh cannot reapply lord to elite")
 var battle_source := FileAccess.get_file_as_string("res://src/battle/battle.gd")
 var special_spawn := function_source(battle_source,"spawn_special_monster")
 check(special_spawn.contains('{"elite_variant": true}'),"event spawn carries elite flag before population gate")
 var spawn_source := function_source(battle_source,"_spawn_monster")
 check(spawn_source.find('monster.set_meta("visual_variant", "elite")') < spawn_source.find('MONSTER_CATALOG.apply_runtime_base_stats'),"elite identity precedes initial stats and ready")
 var modifier_source := function_source(battle_source,"_apply_special_monster_modifiers")
 check(modifier_source.find('monster.set_meta("visual_variant", "elite")') < modifier_source.find('_apply_demon_level_scaling_to_monster'),"direct elite conversion excludes lord before scaling")
 check(not battle._monster_population_limit_reached("goblin"),"other goblin population unrestricted")
 runtime.tick(0.25)
 check(not runtime.states.has(leader.get_instance_id()),"removed leader state cleaned")
 var actual: Dictionary = C.get_base_stats("hobgoblin")
 check(int(actual.max_hp) == 300 and int(actual.attack_damage) == 24 and C.get_base_cost("hobgoblin") == 18.0,"reviewed cost and base stats")
 check(C.get_species("hobgoblin") == "beast" and C.get_grade("hobgoblin") == "rare","catalog beast rare")
 check(C.get_elite_visual_profile("hobgoblin").asset_dir == D.ELITE_VISUAL.asset_dir,"elite profile route")
 runtime.reset()
 check(runtime.leaders.is_empty() and runtime.states.is_empty(),"battle reset releases all registrations")
 var pending: Array = []
 for i in range(6): pending.append(add_actor(battle,"hobgoblin",Vector2(1000,0)))
 var queries_before: int = battle.spatial_queries
 runtime.tick(0.0)
 check(battle.spatial_queries-queries_before <= D.REFRESH_BUDGET,"spatial refresh work bounded per frame")
 check(pending[4].nearby_goblins == 0 and pending[5].nearby_goblins == 0,"remaining leaders deferred instead of scanning army together")
 runtime.tick(0.01)
 check(pending[4].nearby_goblins == 6 and pending[5].nearby_goblins == 6,"round robin refreshes deferred leaders")
 print("Hobgoblin: ",checks," checks, ",failures," failures")
 battle.free()
 quit(1 if failures else 0)
