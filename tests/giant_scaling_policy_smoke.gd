extends SceneTree
const BEFORE=preload("res://before.gd")
const AFTER=preload("res://after.gd")
const OLD_CATALOG=preload("res://catalog_before.gd")
const CATALOG=preload("res://src/data/monster_catalog.gd")
const LEGACY=preload("res://legacy.gd")
const FIELDS=["max_hp","current_hp","move_speed","exp_reward","attack_damage","attack_range","attack_cooldown","projectile_speed","projectile_range","projectile_size_multiplier","slow_duration","self_destruct_range","self_destruct_fuse","hero_kill_exp_reward","self_destruct_exp_reward","explosion_radius","explosion_damage"]
var checks:=0
var failures:=0
class Actor extends Node2D:
 var monster_type=""
 var max_hp=100
 var current_hp=40
 var move_speed=78.0
 var exp_reward=7
 var attack_damage=18
 var attack_range=82.0
 var attack_cooldown=0.8
 var projectile_speed=450.0
 var projectile_range=750.0
 var projectile_size_multiplier=1.0
 var slow_duration=1.5
 var self_destruct_range=78.0
 var self_destruct_fuse=0.3
 var hero_kill_exp_reward=7
 var self_destruct_exp_reward=2
 var explosion_radius=150.0
 var explosion_damage=28
func check(ok: bool,label: String):
 checks+=1
 if not ok:
  failures+=1
  push_error(label)
func snapshot(actor,battle):
 var values=[]
 for field in FIELDS:values.append(actor.get(field))
 return [values,actor.scale,actor.get_meta_list().map(func(key):return [key,actor.get_meta(key)]),battle.trace,battle.monster_spatial_grid_physics_frame]
func setup(actor,id,value):
 actor.monster_type=id
 for key in actor.get_meta_list():actor.remove_meta(key)
 for field in FIELDS:actor.set(field,value)
 actor.scale=Vector2(0.7,1.2)
func reset_trace(before,after):
 before.trace=[];after.trace=[]
 before.monster_spatial_grid_physics_frame=27
 after.monster_spatial_grid_physics_frame=27
func _initialize():
 var before=BEFORE.new();var after=AFTER.new()
 for id in CATALOG.MONSTERS:
  var data:Dictionary=CATALOG.MONSTERS[id].duplicate(true)
  data.erase("giant_scaling")
  if id=="spider":data.erase("runtime_scaling")
  check(data==OLD_CATALOG.MONSTERS[id],"unchanged authoring "+id)
  var profile:Dictionary=CATALOG.get_giant_scaling_profile(id)
  check(bool(profile.get("basic_attack",false))==(id in LEGACY.BASIC_IDS),"legacy basic coverage "+id)
  check(bool(profile.get("ranged_attack",false))==(id in BEFORE.GIANT_RANGED_MONSTER_IDS),"legacy ranged coverage "+id)
  check(is_same(profile,CATALOG.get_giant_scaling_profile(id)),"stable shared profile "+id)
 check(CATALOG.get_giant_scaling_profile("unknown").is_empty(),"unknown neutral")
 # Reuse the same objects across IDs/values to catch stale cached policy/results.
 var a=Actor.new();var b=Actor.new()
 var ids:Array=CATALOG.MONSTERS.keys();ids.append("unknown")
 for id in ids:
  for value in [-2.0,0.0,0.003,0.1,0.5,1.0,2.5,19.5]:
   for multiplier in [-1.0,0.0,1.0,1.75]:
    setup(a,id,value);setup(b,id,value);reset_trace(before,after)
    before.spider_slow_duration_multiplier=multiplier
    after.spider_slow_duration_multiplier=multiplier
    before._apply_giant_monster_base_stats(a,id)
    after._apply_giant_monster_base_stats(b,id)
    check(snapshot(a,before)==snapshot(b,after),"giant base "+id+str([value,multiplier]))
    before.capture_spawn_raw(a);after.capture_spawn_raw(b)
    before._apply_monster_spawn_property_multipliers(a,id)
    after._apply_monster_spawn_property_multipliers(b,id)
    check(snapshot(a,before)==snapshot(b,after),"giant raw + spawn properties "+id)
    # Already giant must not be promoted or refreshed a second time.
    var old_result=before.promote_monster_to_giant(a,id)
    var new_result=after.promote_monster_to_giant(b,id)
    check(not old_result and not new_result and snapshot(a,before)==snapshot(b,after),"giant promotion gate "+id)
    # Existing normal actors take the distinct promotion path, preserving raw baselines.
    setup(a,id,value);setup(b,id,value);reset_trace(before,after)
    before.capture_spawn_raw(a);after.capture_spawn_raw(b)
    before._apply_monster_spawn_property_multipliers(a,id)
    after._apply_monster_spawn_property_multipliers(b,id)
    check(snapshot(a,before)==snapshot(b,after),"normal spawn properties "+id)
    old_result=before.promote_monster_to_giant(a,id)
    new_result=after.promote_monster_to_giant(b,id)
    check(old_result and new_result and snapshot(a,before)==snapshot(b,after),"promote normal "+id)
 # Optional properties preserve original null guards.
 for id in ["spider","orc","ghost","unknown"]:
  setup(a,id,1.0);setup(b,id,1.0);reset_trace(before,after)
  for actor in [a,b]:
   actor.max_hp=null;actor.move_speed=null;actor.exp_reward=null
   actor.attack_damage=null;actor.attack_range=null;actor.attack_cooldown=null
   actor.projectile_size_multiplier=null
  before._apply_giant_monster_base_stats(a,id)
  after._apply_giant_monster_base_stats(b,id)
  check(snapshot(a,before)==snapshot(b,after),"null guards "+id)
 setup(a,"spider",1.0);setup(b,"spider",1.0);reset_trace(before,after)
 a.slow_duration=null;b.slow_duration=null
 before._apply_monster_spawn_property_multipliers(a,"spider")
 after._apply_monster_spawn_property_multipliers(b,"spider")
 check(snapshot(a,before)==snapshot(b,after),"null spawn slow skips")
 for state in ["elite","wrong_id"]:
  setup(a,"spider",1.0);setup(b,"spider",1.0);reset_trace(before,after)
  if state=="elite":
   a.set_meta("visual_variant","elite");b.set_meta("visual_variant","elite")
  var id="orc" if state=="wrong_id" else "spider"
  check(not before.promote_monster_to_giant(a,id) and not after.promote_monster_to_giant(b,id) and snapshot(a,before)==snapshot(b,after),"promotion refusal "+state)
 check(not before.promote_monster_to_giant(null,"spider") and not after.promote_monster_to_giant(null,"spider"),"invalid actor gate")
 a.free();b.free();before.free();after.free()
 print("GIANT_SCALING_POLICY checks=%d failures=%d"%[checks,failures])
 quit(1 if failures else 0)
