extends SceneTree
const BASE:=preload("res://tests/hero_encounters_smoke.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:run.call_deferred()
func run()->void:
 for stage in [1,10]:
  var arena=load("res://tests/hero_finale_harness.gd").new();root.add_child(arena)
  arena.hero=BASE.Actor.new();arena.add_child(arena.hero);arena.hero.position=Vector2(1200,1200)
  arena.current_stage_data.number=stage
  var limit:int=arena.HERO_SURVIVAL.monster_limit(stage)
  for index in limit:arena.active_monsters[index]=true
  arena.run_metrics.elapsed_seconds=899
  check(arena.spawn_hero_encounter("orc",Vector2(600,600),{"type":"boss"})==null,"premature boss rejected")
  arena.run_metrics.elapsed_seconds=900
  arena.block_species=true;arena.block_population=true
  check(arena._spawn_monster("orc",Vector2(600,600),0.0,false,{"hero_final_boss_spawn":true})==null,"raw flag cannot bypass reservation")
  check(arena.spawn_hero_encounter("orc",arena.hero.position,{"type":"boss"})==null and not arena._hero_boss_spawn_pending,"bad position does not consume boss")
  var boss=arena.spawn_hero_encounter("orc",Vector2(600,600),{"type":"boss","target_hp":15400})
  check(is_instance_valid(boss) and boss.max_hp==15400,"boss spawns at full cap "+str(limit))
  check(arena.active_monsters.size()==limit,"reservation does not delete existing enemies")
  check(arena.hero_final_boss_spawned and not arena._hero_boss_spawn_pending,"successful spawn commits once")
  check(arena.spawn_hero_encounter("orc",Vector2(600,600),{"type":"boss"})==null,"duplicate boss rejected")
  check(arena.spawn_hero_encounter("orc",Vector2(600,600),{})==null,"ordinary spawn remains blocked")
  arena.queue_free();await process_frame
 print("HERO_BOSS_RESERVATION checks=",checks," failures=",failures);quit(1 if failures else 0)
