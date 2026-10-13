extends SceneTree
# Actual catalogs/RunMetrics plus extracted production functions. No full actor/scene gameplay.
const P=preload("res://src/data/hero_profiles.gd")
const S=preload("res://src/data/stage_catalog.gd")
const A=preload("res://src/data/hero_augment_catalog.gd")
const C=preload("res://src/data/hero_codex_catalog.gd")
const M=preload("res://src/systems/run_metrics.gd")
const EXPECTED={1:[360,32,220.0,0.70],2:[600,42,255.0,1.20],3:[1100,50,205.0,1.0],4:[2400,94,285.0,0.38],5:[3000,144,245.0,1.05],6:[3875,173,230.0,1.20],7:[4750,173,270.0,2.50],8:[4250,126,255.0,1.10],9:[4500,144,245.0,1.40],10:[6250,195,225.0,1.25]}
var checks:=0
var failures:=0
func check(ok: bool,message: String)->void:
 checks+=1
 if not ok:
  failures+=1
  push_error(message)
func function_source(source: String,name: String)->String:
 var start:=source.find("func "+name+"(")
 if start<0:return ""
 var end:=source.find("\nfunc ",start+1)
 return source.substr(start,end-start if end>=0 else -1)+"\n"
func shell(code: String)->GDScript:
 var script:=GDScript.new()
 script.source_code=code
 check(script.reload()==OK,"production function shell compiles")
 return script
func _init()->void:
 var battle:=FileAccess.get_file_as_string("res://src/battle/battle.gd")
 var hero:=FileAccess.get_file_as_string("res://src/hero/hero.gd")
 var scaler=shell("extends RefCounted\n"+function_source(battle,"_apply_stage_hero_balance")).new()
 for n in EXPECTED:
  var stage:=S.get_stage("stage_"+str(n))
  var raw:=P.get_profile(stage.hero_id)
  var actual:Dictionary=scaler._apply_stage_hero_balance(raw,stage)
  var expected:Array=EXPECTED[n]
  check(actual.max_hp==expected[0],"stage%d HP"%n)
  check(actual.attack_damage==expected[1],"stage%d damage"%n)
  check(is_equal_approx(actual.move_speed,expected[2]),"stage%d speed"%n)
  check(is_equal_approx(actual.attack_cooldown,expected[3]),"stage%d interval"%n)
  check(raw==P.PROFILES[stage.hero_id],"stage%d source not mutated"%n)
  var overview:=C.overview(stage,raw)
  check(overview.contains("체력  %d"%actual.max_hp) and overview.contains("공격력  %d"%actual.attack_damage),"stage%d Codex/spawn parity"%n)
  check(not C.skill_text(raw).is_empty(),"stage%d skills projection"%n)
  var grow=shell("extends RefCounted\nconst HERO_BASE_ATTACK_GROWTH_PER_LEVEL=0.02\nconst HERO_ATTACK_MILESTONE_INTERVAL=10\nconst HERO_ATTACK_MILESTONE_BONUS=0.05\nvar level=1\nvar level_growth_config={}\nvar base_attack_damage_for_level_growth:=0.0\nvar passive_attack_growth_accumulator=0.0\nvar attack_damage=0\nvar current_hp=1\nvar max_hp=1\nfunc heal_direct(_n):pass\n"+function_source(hero,"_apply_level_growth")).new()
  grow.level_growth_config=raw.level_growth.duplicate(true)
  grow.base_attack_damage_for_level_growth=actual.attack_damage
  grow.attack_damage=actual.attack_damage
  for level in range(2,31):
   grow.level=level
   grow._apply_level_growth()
  var expected_growth:=floori(actual.attack_damage*(29*float(raw.level_growth.base_attack_growth_ratio)+3*float(raw.level_growth.attack_milestone_bonus))+0.0001)
  check(grow.attack_damage==actual.attack_damage+expected_growth,"stage%d Lv30 additive growth"%n)
 check(EXPECTED[4][0]>EXPECTED[3][0]*1.7,"stage4 health difficulty step")
 check(float(EXPECTED[4][1])/EXPECTED[4][3]>float(EXPECTED[3][1])/EXPECTED[3][3]*3.0,"stage4 burst firepower step; excludes reload")
 _test_swarm_response(hero)
 _test_augments(hero)
 _test_rewards()
 _test_settlement(battle)
 var main:=FileAccess.get_file_as_string("res://src/main/main.gd")
 var exit:=function_source(main,"_on_lobby_pressed")
 check(exit.contains("finish_abandoned_run()") and exit.contains("not battle.battle_over"),"active exit settles once before navigation")
 check(exit.contains("not battle.practice_mode and not battle.tutorial_mode"),"practice/tutorial exit preserved")
 print("hero_balance_smoke: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
func _test_augments(hero:String)->void:
 # Compile just the selected match arms, with their production statements untouched.
 var source:=function_source(hero,"_apply_augment_effect")
 var ops=["add_stat","grow_max_hp_ratio","advance_common_attack_speed","gunner_low_hp_backstep","archmage_fast_cast","archmage_multicast"]
 var code="extends Node\nvar attack_damage=50\nvar max_hp=1000\nvar current_hp=500\nvar move_speed=200.0\nvar heal_item_multiplier=1.0\nvar projectile_splash_damage_ratio=0.0\nvar projectile_splash_radius=0.0\nvar common_attack_speed_bonus=0.0\nvar common_attack_speed_augment_bonus=0.0\nvar gunner_low_hp_backstep_bonus=0.0\nvar archmage_cooldown_reduction=0.0\nvar archmage_multicast_stacks=0\nfunc _apply_augment_effect(effect:Dictionary):\n\tvar target:=String(effect.get('target',''))\n\tmatch String(effect.get('op','')):\n"
 for op in ops:
  var start:=source.find('\t\t"'+op+'":')
  var end:=source.find('\n\t\t"',start+1)
  check(start>=0,"augment arm exists "+op)
  code+=source.substr(start,end-start if end>=0 else -1)+"\n"
 var actor=shell(code).new()
 var cases={"rapid_strikes":["common_attack_speed_bonus",0.30],"pursuit":["move_speed",260.0],"healing_efficiency":["heal_item_multiplier",1.40],"gunner_fugitive_instinct":["gunner_low_hp_backstep_bonus",0.30],"archmage_fast_cast":["archmage_cooldown_reduction",0.20],"archmage_multicast":["archmage_multicast_stacks",2]}
 for id in cases:
  var augment:=A.get_augment(id)
  for i in range(augment.max_stack):
   for effect in augment.effects:actor._apply_augment_effect(effect)
  check(is_equal_approx(float(actor.get(cases[id][0])),cases[id][1]),id+" max-stack actual effect")
 var iron:=A.get_augment("iron_body")
 for i in range(iron.max_stack):actor._apply_augment_effect(iron.effects[0])
 check(actor.max_hp==1345 and actor.current_hp==845,"iron growth rounds per acquisition and heals gained HP")
 var resistance:=A.get_augment("slow_resistance")
 check(resistance.effects[0].value==0.05 and resistance.effects[0].max==0.40 and resistance.max_stack==8,"control counterplay resistance cap")
 actor.common_attack_speed_bonus+=0.50
 actor._apply_augment_effect(A.get_augment("rapid_strikes").effects[0])
 check(is_equal_approx(actor.common_attack_speed_bonus,0.80),"augment cap never discards permanent attack speed")
 actor.free()
 var describe=load("res://src/data/hero_skill_descriptions.gd")
 var sage:Dictionary=P.PROFILES.sage_astra.sage
 check(describe.describe(sage.skill_3).contains("1.5%") and describe.describe(sage.skill_3).contains("25%"),"condensation description reads new config")
 check(describe.describe(sage.skill_4).contains("95%"),"starlight description reads config")
 check(describe.describe(sage.skill_5).contains("12초") and describe.describe(sage.skill_5).contains("55%"),"annihilation description reads config")
func _test_rewards()->void:
 var rules:=S.RUN_REWARD_RULES
 var m=M.new()
 for duration in [300.0,420.0,600.0]:
  m.reset(duration,100,100)
  m.total_damage_dealt=100
  m.summon_spend={"slime":60.0}
  var previous:=100000
  for percent in [0.0,0.2,0.5,0.8,1.0,1.2]:
   m.elapsed_seconds=duration*percent
   var b:=m.get_research_reward_breakdown(true,1,1,rules)
   check(b.remaining_time==int(floor(maxf(1.0-percent,0.0)*100+0.0001)),"normalized clear speed bonus")
   check(b.total<=previous,"slower clear never increases equivalent rewards")
   previous=b.total
   var lose:=m.get_partial_reward_breakdown(1,1,rules)
   check(lose.remaining_time==0 and lose.victory==0,"no speed/victory bonus for failed/abandoned run")
 # Performance cap must not swallow the speed bonus.
 m.reset(300,100,100)
 m.total_damage_dealt=100000
 m.summon_spend={"slime":99999.0}
 m.hero_augment_events.resize(10)
 m.strategy_switches.resize(10)
 m.elapsed_seconds=60
 var fast:=m.get_research_reward_breakdown(true,100,100,rules)
 m.elapsed_seconds=240
 var slow:=m.get_research_reward_breakdown(true,100,100,rules)
 check(fast.total==280 and slow.total==220,"speed remains on top of capped performance")
 check(floori(fast.total*.6)>floori(slow.total*.6),"faster clear increases gold too")
 var partial:=m.get_partial_reward_breakdown(100,100,rules)
 check(partial.total==60 and partial.partial,"partial cap60")
 m.reset(300,100,100)
 m.elapsed_seconds=30
 m.summon_spend={"slime":3.0}
 check(m.get_partial_reward_breakdown(1,1,rules).total==0,"AFK no damage gets zero")
 m.total_damage_dealt=1
 m.elapsed_seconds=29.999
 check(m.get_partial_reward_breakdown(1,1,rules).total==0,"early refund window no reward")
 m.elapsed_seconds=30
 check(m.get_partial_reward_breakdown(1,1,rules).total==10,"participating run30s gets small reward")
 m.summon_spend={"slime":2.99}
 check(m.get_partial_reward_breakdown(1,1,rules).total==0,"minimum summon spend required")
 m.reset(0,100,100)
 check(m.get_research_reward_breakdown(true,1,1,rules).remaining_time==0,"zero duration guarded")
func _test_settlement(battle:String)->void:
 var code="""extends Node
const STAGE_CATALOG=preload("res://src/data/stage_catalog.gd")
var run_metrics=preload("res://src/systems/run_metrics.gd").new()
var _run_reward_granted=false
var _run_reward_save_failed=false
var practice_mode=false
var hero_player_mode=false
var tutorial_mode=false
var battle_over=false
var demon_level=1
var hero=null
var current_stage_data={"run_reward_multiplier":1.6}
var finish_count=0
var result_text=""
class Progress:
 var calls=0
 var fail=false
 var points=0
 var gold=0
 func add_research_points(p,g):
  calls+=1
  if fail:return {"granted":0,"gold_granted":0}
  points+=p
  gold+=g
  return {"granted":p,"gold_granted":g}
var STAGE_PROGRESS=Progress.new()
func _finish_battle(message,won):
 finish_count+=1
 battle_over=true
 result_text=message
"""
 code=code.replace("\n ","\n\t").replace("\n\t ","\n\t\t")
 for name in ["finish_abandoned_run","_grant_run_research_reward","_format_run_reward_detail"]:code+=function_source(battle,name)
 var actor=shell(code).new()
 actor.run_metrics.reset(300,100,100)
 actor.run_metrics.elapsed_seconds=60
 actor.run_metrics.total_damage_dealt=100
 actor.run_metrics.summon_spend={"slime":60.0}
 actor.STAGE_PROGRESS.fail=true
 check(not actor.finish_abandoned_run() and not actor.battle_over and not actor._run_reward_granted,"failed partial save keeps run retryable")
 actor.STAGE_PROGRESS.fail=false
 check(actor.finish_abandoned_run() and actor.battle_over,"successful partial save finishes")
 check(actor.STAGE_PROGRESS.points>0 and actor.STAGE_PROGRESS.gold==floori(actor.STAGE_PROGRESS.points*.6),"partial actual points/gold grant")
 check(actor.result_text.contains("35%") and actor.result_text.contains("Run 골드"),"partial result feedback")
 var calls:int=actor.STAGE_PROGRESS.calls
 check(actor.finish_abandoned_run() and actor.STAGE_PROGRESS.calls==calls and actor.finish_count==1,"repeat exit never duplicates reward")
 check(actor._grant_run_research_reward(true).is_empty() and actor.STAGE_PROGRESS.calls==calls,"finish callback cannot grant twice")
 actor.free()
 for elapsed in [60.0,240.0]:
  var win=shell(code).new()
  win.run_metrics.reset(300,100,100)
  win.run_metrics.elapsed_seconds=elapsed
  win.run_metrics.total_damage_dealt=100
  win.run_metrics.summon_spend={"slime":60.0}
  var message:String=win._grant_run_research_reward(true)
  check(win.STAGE_PROGRESS.points==(266 if elapsed==60 else 170),"clear actual stage-scaled research grant")
  check(win.STAGE_PROGRESS.gold==(159 if elapsed==60 else 102),"clear actual gold grant")
  check(message.contains("Run 연구") and message.contains("신속"),"speed reward result feedback")
  win._grant_run_research_reward(true)
  check(win.STAGE_PROGRESS.calls==1,"duplicate victory callback no duplicate grant")
  win.free()
 for exemption in ["practice_mode","tutorial_mode"]:
  var exempt=shell(code).new()
  exempt.set(exemption,true)
  exempt.run_metrics.reset(300,100,100)
  exempt.run_metrics.elapsed_seconds=60
  exempt.run_metrics.total_damage_dealt=100
  exempt.run_metrics.summon_spend={"slime":60.0}
  check(exempt._grant_run_research_reward(true).is_empty() and exempt.STAGE_PROGRESS.calls==0,exemption+" no rewards")
  exempt.free()

func _test_swarm_response(hero:String)->void:
 # Production decision gates: density changes eligibility, not guaranteed accuracy.
 var g:Dictionary=P.get_profile("pistol_hero").gunner
 var gunner=shell("extends RefCounted\nvar silence_timer=0.0\nvar gunner_reloading=false\nvar gunner_deadeye_cooldown=0.0\nvar gunner_ammo=12\nvar gunner_config={}\nvar gunner_deadeye_analysis_score:=0.0\nfunc _update_gunner_deadeye_aim_analysis():pass\n"+function_source(hero,"_gunner_should_start_deadeye")).new()
 gunner.gunner_config=g
 gunner.gunner_deadeye_analysis_score=4.6
 check(gunner._gunner_should_start_deadeye(),"dense corridor reaches decisive fire threshold")
 gunner.gunner_deadeye_analysis_score=2.3
 check(not gunner._gunner_should_start_deadeye(),"scattered targets remain below density threshold")
 gunner.gunner_deadeye_analysis_score=4.6
 gunner.gunner_ammo=2
 check(not gunner._gunner_should_start_deadeye(),"too little ammunition cannot trigger deadeye")
 gunner.gunner_ammo=12
 gunner.gunner_reloading=true
 check(not gunner._gunner_should_start_deadeye(),"reload remains punishable")
 gunner.gunner_reloading=false
 gunner.silence_timer=1.0
 check(not gunner._gunner_should_start_deadeye(),"silence still counters deadeye")
 check(g.reload_seconds==2.0 and g.backstep_invulnerability==0.6 and g.backstep_cooldown==5.5,"no defensive invulnerability rollback")
 var p:Dictionary=P.get_profile("archmage_hero")
 var a:Dictionary=p.archmage_skills
 # Gauge estimate excludes casting/movement/misses/refunds; not measured combat frequency.
 var generation:=float(a.gauge_per_second)+float(a.gauge_per_basic_attack)/float(p.attack_cooldown)
 check(100.0/generation<14.0 and 100.0/generation>13.0,"sustained basic casts generate one gauge in about13.7s")
 var gauge=shell("extends Node\nvar hero_archetype='archmage_elementalist'\nvar archmage_skill_config={}\nvar ultimate_charge=0.0\nfunc queue_redraw():pass\n"+function_source(hero,"_add_archmage_gauge")).new()
 gauge.archmage_skill_config=a
 gauge._add_archmage_gauge(3.5)
 check(is_equal_approx(gauge.ultimate_charge,3.5),"actual gauge function accepts restored regeneration")
 gauge._add_archmage_gauge(200.0)
 check(gauge.ultimate_charge==100.0,"gauge still caps at100")
 gauge._add_archmage_gauge(-5.0)
 check(gauge.ultimate_charge==100.0,"negative restoration cannot reduce gauge")
 gauge.free()
 check(a.ice_bolt.pillar_count==10 and a.holy_power.burst_count==12 and a.earth_spikes.spike_count==7,"area effect object counts unchanged")
 check(a.harmony.cooldown==110.0 and A.get_augment("archmage_multicast").max_stack==2,"reset and multicast limits preserved")
