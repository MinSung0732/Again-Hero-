extends SceneTree
const BEFORE = preload("res://before.gd")
const AFTER = preload("res://after.gd")
const OLD_CATALOG = preload("res://catalog_before.gd")
const CATALOG = preload("res://src/data/monster_catalog.gd")
var checks := 0
var failures := 0
class Actor extends Node2D:
 var attack_cooldown = 0.8
 var self_destruct_fuse = 0.3
 var explosion_damage = 28
 var current_hp = 16
 var max_hp = 140
 var exp_reward = 7
class RuntimeActor extends Actor:
 func get_runtime_stat_additions():return {}
func check(ok: bool,label: String):
 checks += 1
 if not ok:
  failures += 1
  push_error(label)
func snapshot(actor,battle):
 return [actor.attack_cooldown,actor.self_destruct_fuse,actor.explosion_damage,actor.current_hp,actor.max_hp,actor.exp_reward,actor.scale,actor.get_meta_list().map(func(key):return [key,actor.get_meta(key)]),battle.trace]
func setup(actor,value,raw,variant):
 actor.attack_cooldown=value
 actor.self_destruct_fuse=value
 actor.explosion_damage=int(round(value*28.0))
 actor.set_meta("hero_survival_spawn_seconds",27.0)
 actor.set_meta("runtime_variant_stats",variant)
 actor.set_meta("special_augment_configs",{"test":{"exclude_elite":true}})
 for property in ["move_speed","attack_damage","max_hp","attack_cooldown","self_destruct_fuse","explosion_damage"]:
  if raw:actor.set_meta("augment_raw_"+property,value*13.0)
 actor.set_meta("demon_level_base_max_hp",value*140.0)
 actor.set_meta("demon_level_base_attack_damage",value*18.0)
 actor.set_meta("demon_level_base_move_speed",value*78.0)
func _initialize():
 var before=BEFORE.new()
 var after=AFTER.new()
 # Verify that authoring data other than the new bindings is identical.
 for id in CATALOG.MONSTERS:
  var data:Dictionary=CATALOG.MONSTERS[id].duplicate(true)
  data.erase("runtime_scaling")
  if not OLD_CATALOG.MONSTERS[id].has("elite_spawn"):data.erase("elite_spawn")
  check(data==OLD_CATALOG.MONSTERS[id],"unchanged catalog "+id)
  var profile:Dictionary=CATALOG.get_runtime_scaling_profile(id)
  check(profile.is_empty() if id not in ["orc","bomb_rat"] else not profile.is_empty(),"opt in "+id)
 check(CATALOG.get_runtime_scaling_profile("unknown").is_empty(),"unknown neutral")
 for id in ["orc","bomb_rat","skeleton","slime","unknown"]:
  for value in [-1.0,0.0,0.003,0.3,1.0,2.5]:
   for hero_mode in [false,true]:
    for runtime in [false,true]:
     for raw in ([false] if "--missing-meta" in OS.get_cmdline_user_args() else [true]):
      before.hero_player_mode=hero_mode
      after.hero_player_mode=hero_mode
      before.orc_hp_multiplier=value
      after.orc_hp_multiplier=value
      var pair=[RuntimeActor.new() if runtime else Actor.new(),RuntimeActor.new() if runtime else Actor.new()]
      for actor in pair:setup(actor,value,raw,{"hp":1.7,"damage":1.6,"speed":1.4,"attack_speed":1.3})
      var event={"hp_multiplier":value,"damage_multiplier":value,"speed_multiplier":value,"attack_speed_multiplier":value,"exp_multiplier":value,"visual_scale":value}
      before.trace=[];after.trace=[]
      before._apply_special_monster_modifiers(pair[0],id,event)
      after._apply_special_monster_modifiers(pair[1],id,event)
      check(snapshot(pair[0],before)==snapshot(pair[1],after),"elite "+id+str([value,hero_mode,runtime,raw]))
      before.trace=[];after.trace=[]
      before._apply_normal_augments_to_existing_monster(pair[0],id)
      after._apply_normal_augments_to_existing_monster(pair[1],id)
      check(snapshot(pair[0],before)==snapshot(pair[1],after),"refresh "+id+str([value,hero_mode,runtime,raw]))
      # Repeat refresh: pooled/raw bases must not accumulate extra multipliers.
      before._apply_normal_augments_to_existing_monster(pair[0],id)
      after._apply_normal_augments_to_existing_monster(pair[1],id)
      check(snapshot(pair[0],before)==snapshot(pair[1],after),"repeat "+id)
      check(before.detail_hp(id,pair[0])==after.detail_hp(id,pair[1]),"detail HP "+id)
      for actor in pair:actor.set_meta("spawn_modifiers",{"hp_multiplier":value})
      check(before.spawn_hp(id,pair[0])==after.spawn_hp(id,pair[1]),"spawn HP "+id)
      for actor in pair:actor.free()
 # Null properties continue to be skipped, not converted into numeric zero.
 var a=Actor.new();var b=Actor.new()
 for actor in [a,b]:
  setup(actor,1.0,true,{})
  actor.self_destruct_fuse=null
  actor.explosion_damage=null
 before.trace=[];after.trace=[]
 before._apply_special_monster_modifiers(a,"bomb_rat",{})
 after._apply_special_monster_modifiers(b,"bomb_rat",{})
 check(snapshot(a,before)==snapshot(b,after),"null optional properties")
 a.free();b.free();before.free();after.free()
 print("MONSTER_SCALING_POLICY checks=%d failures=%d"%[checks,failures])
 quit(1 if failures else 0)
