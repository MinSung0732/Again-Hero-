extends SceneTree
const BEFORE=preload("res://before.gd")
const AFTER=preload("res://after.gd")
const OLD_CATALOG=preload("res://catalog_before.gd")
const CATALOG=preload("res://src/data/monster_catalog.gd")
const AUGMENTS=preload("res://src/data/demon_augment_catalog.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String):
 checks+=1
 if not ok:
  failures+=1
  push_error(label)
func actual_configs() -> Dictionary:
 var result={}
 for id in CATALOG.MONSTERS:
  for event in [&"on_death",&"on_normal_summon"]:
   var rule:Dictionary=CATALOG.get_secondary_spawn_rule(id,event)
   if rule.is_empty():continue
   var augment:Dictionary=AUGMENTS.get_augment(rule.augment_id)
   check(not augment.is_empty() and augment.monster_id==id and augment.effect_type==String(rule.augment_id),"live augment binding "+id+str(event))
   if not result.has(id):result[id]={}
   result[id][String(rule.augment_id)]=augment.effect_values.duplicate(true)
 return result
func configured(params) -> Dictionary:
 return {"slime":{"slime_cell_division":params.duplicate(true),"slime_residual_mucus":params.duplicate(true)},"bomb_rat":{"bomb_rat_litter":params.duplicate(true)},"bat":{"bat_echo_summon":params.duplicate(true)}}
func cleanup(battle):
 for actor in battle.children:actor.free()
 battle.children.clear();battle.events.clear();battle.modifier_refs.clear()
 battle.attempts=0
func setup(battle,configs,options):
 cleanup(battle)
 battle.configs=configs.duplicate(true)
 battle.success_limit=options.get("limit",-1)
 battle.mutate_modifiers=options.get("mutate_modifiers",false)
 battle.mutate_config=options.get("mutate_config",false)
 battle.clamp_mutates_config=options.get("clamp_mutates_config",false)
 battle.spawn_rng=options.get("spawn_rng",false)
 battle.current_stage_id=options.get("stage","normal")
func snapshot(battle):
 var actors=[]
 for actor in battle.children:
  actors.append([actor.position,actor.get_meta_list().map(func(key):return [key,actor.get_meta(key)])])
 return [battle.events.duplicate(true),actors,battle.configs.duplicate(true),battle.attempts]
func invoke(battle,id,event,point,split,allow,death):
 if event=="normal":battle._spawn_extra_normal_summon_monsters(id,point)
 else:battle._process_special_death_spawn(id,point,split,allow,death)
func compare(before,after,id,event,configs,random_seed,split=false,allow=false,death="normal",options={}):
 setup(before,configs,options);setup(after,configs,options)
 var point:Vector2=options.get("point",Vector2(5,1910))
 seed(random_seed)
 invoke(before,id,event,point,split,allow,death)
 var old_rng=[randi(),randi(),randi()]
 seed(random_seed)
 invoke(after,id,event,point,split,allow,death)
 var new_rng=[randi(),randi(),randi()]
 check(snapshot(before)==snapshot(after) and old_rng==new_rng,"equivalence "+str([id,event,random_seed,split,allow,death,configs,options]))
 var isolated=true
 for i in range(1,after.modifier_refs.size()):
  if is_same(after.modifier_refs[i-1],after.modifier_refs[i]):isolated=false
 check(isolated,"separate child modifier dictionaries")
func chain(battle,id):
 if id=="bomb_rat":battle._process_special_death_spawn(id,Vector2(500,500),false,false,"normal")
 else:battle._spawn_extra_normal_summon_monsters(id,Vector2(500,500))
 var first=battle.children.duplicate()
 for child in first:
  battle._process_special_death_spawn(id,child.position,bool(child.get_meta("split_child",false)),bool(child.get_meta("allow_special_death_split",false)),"normal")
 var after_first=battle.children.size()
 var descendants=battle.children.slice(first.size())
 for child in descendants:
  battle._process_special_death_spawn(id,child.position,bool(child.get_meta("split_child",false)),bool(child.get_meta("allow_special_death_split",false)),"normal")
 check(battle.children.size()==after_first,"no unbounded death recursion "+id)
func _initialize():
 var before=BEFORE.new();var after=AFTER.new()
 for id in CATALOG.MONSTERS:
  var data:Dictionary=CATALOG.MONSTERS[id].duplicate(true)
  data.erase("secondary_spawns")
  if not OLD_CATALOG.MONSTERS[id].has("death_reactions"):data.erase("death_reactions")
  check(data==OLD_CATALOG.MONSTERS[id],"unchanged authoring "+id)
  for event in [&"on_death",&"on_normal_summon"]:
   check(is_same(CATALOG.get_secondary_spawn_rule(id,event),CATALOG.get_secondary_spawn_rule(id,event)),"shared immutable rule")
 check(CATALOG.get_secondary_spawn_rule("unknown",&"on_death").is_empty(),"unknown neutral")
 var live=actual_configs()
 var ids:Array=CATALOG.MONSTERS.keys();ids.append("unknown")
 for id in ids:
  compare(before,after,id,"normal",live,71)
  compare(before,after,id,"death",live,71)
 var cases=[{}, {"junk":true}, {"count":-2,"extra_count":-1,"chance":-1.0,"min_extra_count":-3,"max_extra_count":-5}, {"count":1,"extra_count":1,"chance":1.0,"min_extra_count":1,"max_extra_count":1}, {"count":3,"extra_count":2,"chance":0.15,"min_extra_count":1,"max_extra_count":3,"hp_multiplier":0.37,"damage_multiplier":2.0}, {"count":2.9,"extra_count":3.9,"chance":5.0,"min_extra_count":3.9,"max_extra_count":1.5,"hp_multiplier":-1.0,"damage_multiplier":0.0}, {"count":0,"extra_count":0,"chance":0.0,"min_extra_count":1,"max_extra_count":1}, {"count":1,"extra_count":1,"chance":0.5,"min_extra_count":2,"max_extra_count":4}]
 for id in ["slime","bomb_rat","bat","unknown"]:
  for params in cases:
   for random_seed in [3,7,31,901]:
    compare(before,after,id,"normal",configured(params),random_seed)
    for split in [false,true]:
     for allow in [false,true]:
      for death in ["normal","self_destruct","consumed"]:
       compare(before,after,id,"death",configured(params),random_seed,split,allow,death)
 var full=configured({"count":3,"extra_count":3,"chance":1.0,"min_extra_count":3,"max_extra_count":3,"hp_multiplier":0.5,"damage_multiplier":0.5})
 for id in ["slime","bomb_rat","bat"]:
  for mode in ["mutate_modifiers","mutate_config","clamp_mutates_config","spawn_rng"]:
   for limit in [-1,0,1]:
    for event in ["normal","death"]:
     var options={mode:true,"limit":limit,"point":Vector2(-100,10),"stage":"castle"}
     compare(before,after,id,event,full,811,false,false,"normal",options)
 for id in ["slime","bomb_rat","bat"]:
  var configs=configured({"count":2,"extra_count":2,"chance":1.0,"min_extra_count":3,"max_extra_count":3})
  setup(before,configs,{});setup(after,configs,{})
  seed(73);chain(before,id);var old_rng=randi()
  seed(73);chain(after,id);var new_rng=randi()
  check(snapshot(before)==snapshot(after) and old_rng==new_rng,"child/death chain "+id)
  check(after.children.size()==({"slime":6,"bomb_rat":2,"bat":3}[id]),"expected bounded descendants "+id)
 cleanup(before);cleanup(after);before.free();after.free()
 print("SECONDARY_SPAWN_POLICY checks=%d failures=%d"%[checks,failures])
 quit(1 if failures else 0)
