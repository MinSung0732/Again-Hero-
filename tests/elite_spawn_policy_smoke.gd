extends SceneTree
const BEFORE = preload("res://before.gd")
const AFTER = preload("res://after.gd")
const OLD_CATALOG = preload("res://catalog_before.gd")
const CATALOG = preload("res://src/data/monster_catalog.gd")
var checks := 0
var failures := 0
func check(ok: bool,label: String):
 checks+=1
 if not ok:
  failures+=1
  push_error(label)
func snapshot(battle):
 var states=[]
 for actor in battle.actors:
  states.append([actor.position,actor.scale,actor.attack_cooldown,actor.self_destruct_fuse,actor.explosion_damage,actor.current_hp,actor.exp_reward,actor.get_meta_list().map(func(key):return [key,actor.get_meta(key)])])
 return [battle.trace,states,battle.active_elite_skeletons.size(),battle.has_living_elite_skeleton()]
func cleanup(battle):
 for actor in battle.actors:
  if is_instance_valid(actor):actor.free()
 battle.actors.clear()
 battle.trace.clear()
func compare_spawn(before,after,id,event,label):
 seed(98147)
 var was:bool=before.spawn_special_monster(id,event)
 var old_rng=randi()
 seed(98147)
 var now:bool=after.spawn_special_monster(id,event)
 var new_rng=randi()
 check(was==now and snapshot(before)==snapshot(after) and old_rng==new_rng,label)
 cleanup(before);cleanup(after)
 check(before.active_elite_skeletons.is_empty() and after.active_elite_skeletons.is_empty(),"tree exit cleanup "+label)
func _initialize():call_deferred("run")
func run():
 var before=BEFORE.new();var after=AFTER.new()
 root.add_child(before);root.add_child(after)
 for battle in [before,after]:
  battle.hero=Node2D.new()
  battle.add_child(battle.hero)
 # Only two opt-in policy entries change. All combat/stat content stays equal.
 for id in CATALOG.MONSTERS:
  var data:Dictionary=CATALOG.MONSTERS[id].duplicate(true)
  data.erase("elite_spawn")
  check(data==OLD_CATALOG.MONSTERS[id],"catalog unchanged "+id)
  var profile:Dictionary=CATALOG.get_elite_spawn_profile(id)
  if id=="kobolt":
   check(profile.position_policy==CATALOG.EliteSpawnPosition.FARTHEST_ATTACK_RANGE,"range opt in")
  elif id=="skeleton":
   check(profile.alive_registration_method==&"set_elite_skeleton_alive" and after.has_method(profile.alive_registration_method),"liveness binding exists")
  else:check(profile==CATALOG.DEFAULT_ELITE_SPAWN and is_same(profile,CATALOG.get_elite_spawn_profile(id)),"shared default "+id)
 check(CATALOG.get_elite_spawn_profile("missing")==CATALOG.DEFAULT_ELITE_SPAWN and is_same(CATALOG.get_elite_spawn_profile("missing"),CATALOG.get_elite_spawn_profile("missing")),"unknown shared default")
 # Same global RNG seed verifies both position and random consumption.
 for map_size in [Vector2(1080,1920),Vector2(400,500)]:
  for stage in ["normal","castle"]:
   for hero_point in [Vector2.ZERO,map_size*0.5,map_size,Vector2(70,70),Vector2(-50,250)]:
    for distance in [-10.0,0.0,720.0,5000.0]:
     for battle in [before,after]:
      battle.current_map_size=map_size
      battle.current_stage_id=stage
      battle.hero.position=hero_point
     for id in CATALOG.MONSTERS:
      compare_spawn(before,after,id,{"spawn_distance":distance},"geometry "+id+str([map_size,stage,hero_point,distance]))
 # Coincident farthest corner and hero position, plus default event data.
 for battle in [before,after]:
  battle.current_stage_id="normal"
  battle.current_map_size=Vector2(140,140)
  battle.hero.position=Vector2(70,70)
 for id in ["kobolt","skeleton","slime","unknown"]:
  compare_spawn(before,after,id,{},"default/zero offset "+id)
 # Original early-return gates and hero-mode replacement must precede policy lookup.
 for battle in [before,after]:
  battle.hero_player_mode=true
 for remap in ["kobolt","skeleton","deny"]:
  for battle in [before,after]:battle.remapped_id=remap
  compare_spawn(before,after,"slime",{},"hero remap "+remap)
 for battle in [before,after]:
  battle.remapped_id=""
  battle.HERO_SURVIVAL.allowed=false
 compare_spawn(before,after,"kobolt",{},"survival gate")
 for battle in [before,after]:
  battle.HERO_SURVIVAL.allowed=true
  battle.hero_player_mode=false
  battle.spawn_failure=true
 compare_spawn(before,after,"kobolt",{},"spawn pool failure")
 for battle in [before,after]:
  battle.spawn_failure=false
  battle.hero.free()
 compare_spawn(before,after,"skeleton",{},"invalid hero")
 for battle in [before,after]:
  battle.hero=null
 check(before._get_farthest_kobolt_attack_spawn_position("kobolt")==after._get_farthest_attack_range_spawn_position("kobolt"),"missing hero range fallback")
 check(after._get_special_monster_spawn_position("slime",{})==after.current_map_size*0.5,"missing hero ring fallback")
 # Actual registry + actual tree_exited signals, including re-entry of a reused actor.
 for battle in [before,after]:
  battle.hero=Node2D.new();battle.add_child(battle.hero)
  battle.hero.position=Vector2(300,300)
  battle.current_map_size=Vector2(1080,1920)
  check(battle.spawn_special_monster("skeleton",{}),"first liveness spawn")
  check(battle.spawn_special_monster("skeleton",{}),"second liveness spawn")
  var a=battle.actors[0];var b=battle.actors[1]
  check(battle.active_elite_skeletons.size()==2,"two living")
  battle.set_elite_skeleton_alive(a,true)
  check(battle.active_elite_skeletons.size()==2 and a.tree_exited.get_connections().size()==1,"duplicate registration idempotent")
  battle.set_elite_skeleton_alive(a,false)
  battle.set_elite_skeleton_alive(a,false)
  check(battle.active_elite_skeletons.size()==1 and battle.has_living_elite_skeleton(),"explicit unregister keeps other actor")
  battle.set_elite_skeleton_alive(a,true)
  battle.remove_child(a)
  check(battle.active_elite_skeletons.size()==1 and a.tree_exited.get_connections().is_empty(),"exit removes registration/one-shot connection")
  battle.add_child(a)
  battle.set_elite_skeleton_alive(a,true)
  check(battle.active_elite_skeletons.size()==2 and a.tree_exited.get_connections().size()==1,"re-enter and register once")
  a.free()
  check(battle.active_elite_skeletons.size()==1,"free removes first only")
  b.free()
  battle.actors.clear()
  check(not battle.has_living_elite_skeleton(),"last free clears liveness")
 before.free();after.free()
 print("ELITE_SPAWN_POLICY checks=%d failures=%d"%[checks,failures])
 quit(1 if failures else 0)
