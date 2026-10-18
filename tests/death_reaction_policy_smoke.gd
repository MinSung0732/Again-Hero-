extends SceneTree
const BEFORE=preload("res://before.gd")
const AFTER=preload("res://after.gd")
const CATALOG=preload("res://src/data/monster_catalog.gd")
const OLD_CATALOG=preload("res://catalog_before.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String):
 checks+=1
 if not ok:
  failures+=1
  push_error(label)
func cleanup(battle):
 var source=battle.get_meta("fixture_source",null) if battle.has_meta("fixture_source") else null
 if is_instance_valid(source):source.free()
 if battle.has_meta("fixture_source"):battle.remove_meta("fixture_source")
 for actor in battle.children:
  if is_instance_valid(actor):actor.free()
 battle.children.clear();battle.events.clear()
 battle.monster_summon_costs.clear();battle.active_monsters.clear();battle.active_elite_skeletons.clear()
func setup(battle,id,opts):
 cleanup(battle)
 battle.raw_allied_deaths=0;battle.raw_tank_deaths=0
 battle.hero_elite_kills_toward_chest=0
 battle.hero_kills_toward_heal_item=int(opts.get("near_cap",false)) * (battle.HEAL_ITEM_KILLS_REQUIRED-1)
 battle.hero_kills_toward_chest=0;battle.hero_kills_toward_magnet=0
 battle.monster_spatial_grid_physics_frame=27
 battle.monsters_alive=1
 battle.command_power=opts.get("power",20.0)
 battle.max_command=30.0
 battle.death_refund_ratio=opts.get("refund",0.25)
 battle.banshee_deaths_toward_elite=opts.get("counter",0)
 battle.slime_split_chance=opts.get("chance",0.0)
 battle.hero_changes_chance=opts.get("hero_changes_chance",false)
 battle.refund_changes_chance=opts.get("refund_changes_chance",false)
 battle.changed_chance=opts.get("changed_chance",1.0)
 battle.spawn_failure=opts.get("failure",false)
 battle.mutate_modifiers=opts.get("mutate_modifiers",false)
 battle.spawn_rng=opts.get("spawn_rng",false)
 battle.hero_player_mode=opts.get("hero_mode",false)
 battle.battle_over=opts.get("battle_over",false)
 battle.current_stage_id=opts.get("stage","normal")
 battle.configs={"banshee":{"banshee_death_possession":opts.get("config",{"deaths_required":30}).duplicate(true)},"slime":{"slime_residual_mucus":{"count":opts.get("special_count",0)}}}
 if opts.get("invalid",false):return null
 var actor=battle.Actor.new()
 actor.monster_type=id;actor.exp_reward=opts.get("exp",7)
 actor.position=Vector2(10,1900)
 actor.set_meta("split_child",opts.get("split",false))
 actor.set_meta("allow_special_death_split",opts.get("allow",false))
 actor.set_meta("death_type",opts.get("death","normal"))
 actor.set_meta("exclude_all_augments",opts.get("exclude",false))
 actor.set_meta("allied_death_recorded",opts.get("recorded",false))
 actor.set_meta("transcendent_death_handled",opts.get("handled",false))
 actor.set_meta("stage_event_type",opts.get("event",""))
 battle.add_child(actor)
 battle.set_meta("fixture_source",actor)
 battle.monster_summon_costs[actor.get_instance_id()]=opts.get("cost",8.0)
 battle.active_monsters[actor.get_instance_id()]=actor
 battle.active_elite_skeletons[actor.get_instance_id()]=actor
 return actor
func snapshot(battle,actor):
 var state=[]
 if is_instance_valid(actor):state=actor.get_meta_list().map(func(key):return [key,actor.get_meta(key)])
 var spawned=[]
 for child in battle.children:spawned.append([child.monster_type,child.position,child.get_meta_list().map(func(key):return [key,child.get_meta(key)])])
 return [battle.events.duplicate(true),state,spawned,battle.raw_allied_deaths,battle.raw_tank_deaths,battle.hero_elite_kills_toward_chest,battle.hero_kills_toward_heal_item,battle.hero_kills_toward_chest,battle.hero_kills_toward_magnet,battle.banshee_deaths_toward_elite,battle.slime_split_chance,battle.monsters_alive,battle.command_power,battle.monster_summon_costs.values(),battle.active_monsters.size(),battle.active_elite_skeletons.size(),battle.monster_spatial_grid_physics_frame]
func compare(before,after,id,opts,random_seed=51):
 var a=setup(before,id,opts);var b=setup(after,id,opts)
 seed(random_seed);before._on_monster_died(a);var old_rng=[randi(),randi(),randi()]
 seed(random_seed);after._on_monster_died(b);var new_rng=[randi(),randi(),randi()]
 check(snapshot(before,a)==snapshot(after,b) and old_rng==new_rng,"death equivalence "+str([id,opts,random_seed]))
func _initialize():call_deferred("run")
func run():
 var before=BEFORE.new();var after=AFTER.new()
 root.add_child(before);root.add_child(after)
 for id in CATALOG.MONSTERS:
  var data:Dictionary=CATALOG.MONSTERS[id].duplicate(true)
  data.erase("death_reactions")
  check(data==OLD_CATALOG.MONSTERS[id],"unchanged authoring "+id)
  check(is_same(CATALOG.get_death_reaction_profile(id),CATALOG.get_death_reaction_profile(id)),"shared profile "+id)
 check(CATALOG.DEFAULT_DEATH_MONSTER_ID=="slime" and CATALOG.get_death_reaction_profile("unknown").is_empty(),"legacy default and unknown neutral")
 check(after.has_method(CATALOG.get_death_reaction_profile("ghost").pre_reward_method),"registered ghost callback")
 var ids:Array=CATALOG.MONSTERS.keys();ids.append("unknown")
 for id in ids:
  for death in ["normal","self_destruct","consumed"]:
   compare(before,after,id,{"death":death,"counter":29,"chance":1.0,"special_count":2})
 for id in ["slime","banshee","ghost","unknown"]:
  for death in ["normal","self_destruct","consumed"]:
   for split in [false,true]:
    for allow in [false,true]:
     for exclude in [false,true]:
      for chance in [-1.0,0.0,0.15,1.0,2.0]:
       compare(before,after,id,{"death":death,"split":split,"allow":allow,"exclude":exclude,"chance":chance,"counter":29,"special_count":2},97)
 for config in [{},{"junk":true},{"deaths_required":0},{"deaths_required":1},{"deaths_required":2},{"deaths_required":30},{"deaths_required":2.9},{"deaths_required":-3}]:
  for counter in [0,1,28,29,30]:
   for failure in [false,true]:
    compare(before,after,"banshee",{"config":config,"counter":counter,"failure":failure,"mutate_modifiers":true})
 for id in ["slime","banshee","ghost"]:
  for option in ["hero_changes_chance","refund_changes_chance","spawn_rng"]:
   for chance in [0.0,1.0]:
    for changed_chance in [0.0,1.0]:
     var opts={option:true,"chance":chance,"changed_chance":changed_chance,"counter":29,"special_count":2,"power":29.0,"cost":100.0,"stage":"castle"}
     compare(before,after,id,opts,713)
 for id in ["slime","banshee","ghost","zeus"]:
  for opts in [{"battle_over":true},{"hero_mode":true,"event":"elite"},{"recorded":true},{"handled":true},{"refund":0.0,"exp":0},{"refund":-1.0},{"invalid":true,"chance":1.0},{"chance":1.0,"failure":true,"special_count":2}]:
   compare(before,after,id,opts)
 # Sanity-check important owner contracts independently of the before/after oracle.
 var actor=setup(after,"banshee",{"counter":29,"failure":true})
 after._on_monster_died(actor)
 check(after.banshee_deaths_toward_elite==0 and after.children.is_empty(),"counter resets even when elite spawn fails")
 actor=setup(after,"banshee",{"counter":29})
 after._on_monster_died(actor)
 check(after.children.size()==1 and after.children[0].get_meta("exclude_all_augments",false),"replacement banshee excludes augments")
 actor=setup(after,"slime",{"refund_changes_chance":true,"chance":0.0,"changed_chance":1.0})
 after._on_monster_died(actor)
 check(after.children.size()==1 and after.children[0].get_meta("split_child",false),"legacy chance read after refund callback")
 actor=setup(after,"slime",{"death":"consumed","chance":0.0})
 after._on_monster_died(actor)
 check(not after.events.any(func(e):return e is Array and e[0] in ["exp","trans_exp","hero_kill","metric"]),"consumed keeps no reward/hero kill/metric")
 var rule:Dictionary=CATALOG.get_death_reaction_profile("banshee").counter_elite
 check(not rule.spawn_modifiers.has("fixture_mutation") and not rule.elite_modifiers.has("fixture_mutation"),"shared policy dictionaries not mutated")
 cleanup(before);cleanup(after);before.free();after.free()
 print("DEATH_REACTION_POLICY checks=%d failures=%d"%[checks,failures])
 quit(1 if failures else 0)
