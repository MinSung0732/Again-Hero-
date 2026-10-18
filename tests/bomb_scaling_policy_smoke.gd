extends SceneTree
const BEFORE=preload("res://before.gd")
const AFTER=preload("res://after.gd")
const OLD_CATALOG=preload("res://catalog_before.gd")
const CATALOG=preload("res://src/data/monster_catalog.gd")
const DEFAULTS={"max_hp":149.3,"move_speed":77.8,"exp_reward":17.5,"attack_damage":18.5,"attack_range":90.25,"attack_cooldown":0.31,"projectile_speed":450.0,"projectile_range":750.0,"projectile_size_multiplier":1.17,"slow_duration":2.3,"self_destruct_range":78.5,"self_destruct_fuse":0.17,"hero_kill_exp_reward":19.5,"self_destruct_exp_reward":2.5,"explosion_radius":150.9,"explosion_damage":28.5}
var checks:=0
var failures:=0
class Actor extends Node2D:
 var values:Dictionary={}
 var events:Array=[]
 func _get(property: StringName):
  if values.has(property):
   events.append(["get",property,values[property]])
   return values[property]
  return null
 func _set(property: StringName,value) -> bool:
  if values.has(property):
   values[property]=value
   events.append(["set",property,value])
   return true
  return false
func check(ok:bool,label:String):
 checks+=1
 if not ok:
  failures+=1
  push_error(label)
func setup(actor,factor,overrides={}):
 actor.values=DEFAULTS.duplicate()
 for key in actor.values:actor.values[key]*=factor
 actor.values.merge(overrides,true)
 actor.events=[]
 for key in actor.get_meta_list():actor.remove_meta(key)
 actor.scale=Vector2(0.7,1.2)
func snapshot(actor,battle):
 return [actor.values.duplicate(true),actor.events.duplicate(true),actor.scale,actor.get_meta_list().map(func(key):return [key,actor.get_meta(key)]),battle.trace.duplicate(true)]
func compare(before,after,a,b,id,factor,giant,split,modifiers,overrides={}):
 setup(a,factor,overrides);setup(b,factor,overrides)
 before.trace=[];after.trace=[]
 seed(7541)
 if giant and not split:before._apply_giant_monster_base_stats(a,id)
 var old_state=snapshot(a,before)
 var old_rng=randi()
 seed(7541)
 if giant and not split:after._apply_giant_monster_base_stats(b,id)
 var new_state=snapshot(b,after)
 var new_rng=randi()
 check(old_state==new_state and old_rng==new_rng,"giant/order "+id+str([factor,giant,split,overrides]))
 before.apply_spawn_stats(a,id,modifiers,split)
 after.apply_spawn_stats(b,id,modifiers,split)
 check(snapshot(a,before)==snapshot(b,after),"spawn/raw/order "+id+str([factor,giant,split,overrides]))
func _initialize():
 var before=BEFORE.new();var after=AFTER.new();var a=Actor.new();var b=Actor.new()
 for id in CATALOG.MONSTERS:
  var data:Dictionary=CATALOG.MONSTERS[id].duplicate(true)
  if id=="bomb_rat":data.erase("giant_scaling")
  check(data==OLD_CATALOG.MONSTERS[id],"unchanged authoring "+id)
 var ids:Array=CATALOG.MONSTERS.keys();ids.append("unknown")
 for id in ids:
  for factor in [-1.0,0.0,0.003,1.0,1.75]:
   for giant in [false,true]:
    for split in [false,true]:
     compare(before,after,a,b,id,factor,giant,split,{"hp_multiplier":1.3,"damage_multiplier":1.4,"speed_multiplier":1.2,"exp_multiplier":1.5,"visual_scale":1.7,"stage_event_type":"fixture"})
 # Independently vary each property: XP fields must never be swapped or conflated.
 for field in ["self_destruct_range","self_destruct_fuse","hero_kill_exp_reward","self_destruct_exp_reward","explosion_radius","explosion_damage"]:
  for value in [-1.0,0.0,0.099,0.1279,0.128,0.1281,0.5,1.171875,1.5,19.5]:
   for giant in [false,true]:
    compare(before,after,a,b,"bomb_rat",1.0,giant,false,{}, {field:value})
 # Current multiplier changes are read at use time; repeat using the same actors.
 for factor in [0.0,0.25,1.0,1.79]:
  for battle in [before,after]:
   battle.monster_damage_multiplier=factor
   battle.monster_attack_speed_multiplier=factor
   battle.demon_damage_factor=factor
  compare(before,after,a,b,"bomb_rat",1.0,true,false,{})
 # Nullable spawn properties are still skipped after raw capture.
 for overrides in [{"self_destruct_fuse":null},{"explosion_damage":null},{"self_destruct_fuse":null,"explosion_damage":null}]:
  compare(before,after,a,b,"bomb_rat",1.0,false,false,{},overrides)
 setup(a,1.0)
 after._apply_giant_monster_base_stats(a,"bomb_rat")
 check(a.values.hero_kill_exp_reward==25 and a.values.self_destruct_exp_reward==3,"distinct XP fields independently scaled")
 check(a.values.explosion_damage==36 and a.values.self_destruct_fuse==0.1328125,"fixture executes real mapped properties")
 a.free();b.free();before.free();after.free()
 print("BOMB_SCALING_POLICY checks=%d failures=%d"%[checks,failures])
 quit(1 if failures else 0)
