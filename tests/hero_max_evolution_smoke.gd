extends SceneTree
const DATA := preload("res://src/data/hero_weapon_catalog.gd")
const DESIGNS := preload("res://src/data/hero_weapon_evolution_catalog.gd")
const BASE := preload("res://tests/hero_weapon_extension_smoke.gd")
const RUNTIME := preload("res://src/hero_mode/hero_weapon_runtime.gd")
class Runtime extends RUNTIME:
 var extra_hits := 0
 func _hit(actor: Node2D,damage: int,pattern: String,rank: int,data: Dictionary = {}) -> void:
  if bool(data.get("evolution_secondary",false)) and damage > 0: extra_hits += 1
  super._hit(actor,damage,pattern,rank,data)
class Ally extends Node2D:
 var owner_hero: Node2D
class Arena extends BASE.Arena:
 var active_hero_summons := {}
 var generation := 1
 func get_battle_entity_handle(actor: Node) -> Vector3i: return Vector3i(targets.find(actor)+1,generation,1)
 func resolve_battle_entity(handle: Vector3i) -> Node:
  return super.resolve_battle_entity(handle) if handle.y == generation else null
var checks := 0
var failures := 0
func _initialize(): call_deferred("run")
func check(ok: bool,message: String):
 checks += 1
 if not ok: failures += 1; push_error(message)
func run():
 var empty: Array[Texture2D] = []
 for row in DATA.WEAPONS.values(): RUNTIME.ART.cache[String(row.effect_dir)] = empty
 check(DESIGNS.DESIGNS.size() == 100,"100 explicit MAX designs")
 var names := {}
 var modes := {}
 for owner in DATA.HERO_WEAPONS:
  var owner_modes := {}
  for id in DATA.weapon_pool(owner):
   var arena := Arena.new(); root.add_child(arena)
   var hero := BASE.Hero.new(); hero.hero_id = owner; hero.damage_poison_tracker = BASE.Clearable.new(); hero.burn_runtime = BASE.Clearable.new(); arena.add_child(hero)
   for index in 8:
    var target := BASE.Target.new(); arena.add_child(target); target.position = Vector2(120+index*10,index*2); arena.targets.append(target)
   for index in 3:
    var ally := Ally.new(); ally.owner_hero = hero; ally.position = Vector2(90,index*20); arena.add_child(ally); arena.active_hero_summons[ally.get_instance_id()] = ally
   var runtime := Runtime.new(); runtime.install(hero)
   runtime.weapon_ids.clear(); runtime.levels.clear(); runtime.cooldowns.clear(); runtime.resolved.clear()
   runtime.weapon_ids.append(id); runtime.levels[id] = 10; runtime.cooldowns[id] = 999
   check(not runtime.stats_for(id).has("max_mechanic"),id+" Lv10 has no MAX behavior")
   var receipt := runtime.roll_chest()
   check(receipt.id == id and receipt.evolution,id+" real Lv10 chest evolution")
   check(runtime.apply_chest(receipt) and not runtime.apply_chest(receipt),id+" evolution applies once")
   check(runtime.cooldowns[id] == 0,id+" MAX ready immediately")
   var data := runtime.stats_for(id)
   var mode: String = data.max_mechanic.mechanic
   owner_modes[mode] = true; modes[mode] = true
   check(data.growth_evolved and data.evolution_secondary_data.evolution_secondary,id+" nonrecursive secondary snapshot")
   var name := DATA.GROWTH.evolution_name(id)
   check(not names.has(name) and not name.is_empty(),id+" unique MAX identity"); names[name] = true
   check(receipt.description.contains("Lv.11 MAX") and receipt.description.contains(String(DESIGNS.DESIGNS[id].description).replace("3회 적중","2회 적중") if int(data.get("awakening_mark_hits",3))==2 else DESIGNS.DESIGNS[id].description),id+" receipt explains actual mechanic")
   runtime.cooldowns[id] = 999
   runtime._cast(id)
   var original_orbit := Vector2.ZERO
   var first_slot: Dictionary = {}
   for slot in runtime.delivery.slots:
    if float(slot.left) > 0:
     first_slot = slot
     if mode in ["reactive_zone","detonating_trail"]:
      for actor in arena.targets: actor.position = slot.get("landing",slot.origin) if slot.mode in ["lob","lob_burst"] else slot.origin
     if mode == "orbit":
      runtime.delivery.clock = .35
      original_orbit = runtime.delivery.orbit_point(slot,0)
     break
   if mode == "relay_turret":
    check(not first_slot.is_empty(),id+" actual turret created")
    hero.position = Vector2(260,260)
   if mode == "counter": runtime.evolution.on_shield_absorbed(100000)
   if mode in ["mark","fork"]:
    # Native starters also emit a visible MAX carrier through this exact hook.
    runtime.evolution.on_native_basic(data,hero.global_position,arena.targets[0],100,600)
    for index in 3: runtime._hit(arena.targets[0],100,"bolt",10,data)
   if mode == "reap":
    arena.targets[0].current_hp = 1
    runtime._hit(arena.targets[0],100,"slash",10,data)
   for step in 52:
    runtime.tick(.05,false)
    if step == 17 and mode == "detonating_trail": runtime._cast(id)
   if mode == "orbit":
    check(not first_slot.is_empty() and first_slot.left > 0,id+" orbit remains active")
    # The new path differs from a constant-radius clockwise circle.
    runtime.delivery.clock = .35
    var legacy: Vector2 = Vector2(first_slot.origin)+Vector2.from_angle(.35*float(data.get("orbit_speed",2.4)))*float(first_slot.orbit_radius)
    check(original_orbit.distance_to(legacy) > 5,id+" actual orbit topology changes")
   elif mode == "relay_turret": check(Vector2(first_slot.origin).distance_to(hero.global_position) < 140,id+" actual turret follows the new frontline")
   else: check(runtime.extra_hits > 0,id+" MAX mechanic actually hits, beyond base stat patch")
   check(runtime.evolution.slots.size() == 24 and runtime.evolution.marks.size() == 64 and runtime.projectiles.size() == 64,id+" bounded shared pools")
   arena.queue_free(); await process_frame
  check(owner_modes.size() >= 2,owner+" themed MAX kit has multiple actual actions")
 check(modes.has("front_echo") and modes.has("orbit") and modes.has("command"),"themed melee/orbit/command mechanics exercised")
 await edge_cases()
 print("HERO_MAX_EVOLUTION checks=",checks," failures=",failures)
 quit(1 if failures else 0)
func edge_cases():
 var arena := Arena.new(); root.add_child(arena)
 var hero := BASE.Hero.new(); hero.damage_poison_tracker = BASE.Clearable.new(); hero.burn_runtime = BASE.Clearable.new(); arena.add_child(hero)
 for index in 2:
  var actor := BASE.Target.new(); actor.position = Vector2(130+index*30,0); arena.add_child(actor); arena.targets.append(actor)
 var runtime := Runtime.new(); runtime.install(hero)
 var id := "ranged_rookie_sealing_bolt"
 runtime.levels[id] = 10; runtime.evolved[id] = true
 var data := runtime.stats_for(id).duplicate()
 data.splash_ratio = 0.0
 data.evolution_secondary_data = data.evolution_secondary_data.duplicate()
 data.evolution_secondary_data.splash_ratio = 0.0
 for index in 1: runtime._hit(arena.targets[0],10,"bolt",10,data)
 check(runtime.evolution.mark_lookup.size() == 1 and runtime.extra_hits == 0,"one mark waits for the second hit")
 arena.generation += 1
 runtime._hit(arena.targets[0],10,"bolt",10,data)
 check(runtime.extra_hits == 0,"new monster generation cannot inherit old marks")
 var before: int = runtime.extra_hits
 for index in 10: runtime._hit(arena.targets[0],10,"bolt",10,data.evolution_secondary_data)
 check(runtime.extra_hits == before+10 and runtime.evolution.mark_lookup.size() == 2,"secondary damage never recursively marks")
 runtime.evolution.tick(3.1)
 check(runtime.evolution.mark_lookup.is_empty(),"marks expire without actor retention")
 for index in 200:
  arena.generation += 1
  runtime._hit(arena.targets[0],1,"nova",10,data)
 check(runtime.evolution.mark_lookup.size() == 64,"mark saturation retains existing stacks in constant space")
 runtime.evolution.tick(3.1)
 var cross_id := "ranged_rookie_magic_lance"
 runtime.levels[cross_id] = 10; runtime.evolved[cross_id] = true
 var cross_data := runtime.stats_for(cross_id)
 var center: Vector2 = arena.targets[0].position
 var axis := Vector2.RIGHT.rotated(float(cross_data.max_mechanic.angle))
 arena.targets[1].position = center+axis.rotated(PI/4)*130
 var first_hp: int = arena.targets[0].current_hp
 var second_hp: int = arena.targets[1].current_hp
 runtime.evolution.on_cast(cross_data,Vector2.ZERO,Vector2.RIGHT,arena.targets[0],100,600)
 runtime.evolution.tick(.8)
 check(arena.targets[0].current_hp == first_hp-65,"cross intersection receives exactly one secondary hit")
 check(arena.targets[1].current_hp == second_hp,"cross visuals do not imply damage in empty diagonal space")
 runtime.levels.ranged_rookie_arcane_bolt = 10; runtime.evolved.ranged_rookie_arcane_bolt = true; runtime.resolved.erase("ranged_rookie_arcane_bolt")
 var return_data := runtime.stats_for("ranged_rookie_arcane_bolt")
 first_hp = arena.targets[0].current_hp
 runtime.evolution.on_cast(return_data,Vector2.ZERO,Vector2.RIGHT,arena.targets[0],100,600)
 for index in 20: runtime.evolution.tick(.05)
 check(arena.targets[0].current_hp == first_hp-110,"boomerang hits once outbound and once returning")
 for index in 200: runtime.evolution.on_cast(runtime.stats_for("ranged_rookie_arcane_bolt"),Vector2.ZERO,Vector2.RIGHT,arena.targets[0],100,600)
 # Explicitly awaken a moving weapon before saturation.
 runtime.levels.ranged_rookie_arcane_bolt = 10; runtime.evolved.ranged_rookie_arcane_bolt = true; runtime.resolved.erase("ranged_rookie_arcane_bolt")
 for index in 200: runtime.evolution.on_cast(runtime.stats_for("ranged_rookie_arcane_bolt"),Vector2.ZERO,Vector2.RIGHT,arena.targets[0],100,600)
 var count := 0
 for slot in runtime.evolution.slots:
  if slot.left > 0: count += 1
 check(count == 24 and runtime.evolution.slots.size() == 24,"saturation skips extra actions without allocating")
 var hp_before: int = arena.targets[0].current_hp
 hero.current_hp = 0; runtime.evolution.tick(.2)
 check(arena.targets[0].current_hp == hp_before,"dead hero cannot deal deferred MAX damage")
 arena.queue_free(); await process_frame
