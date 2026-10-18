extends SceneTree
const ENCOUNTER := preload("res://src/hero_mode/hero_encounter_runtime.gd")
const BASE := preload("res://tests/hero_encounters_smoke.gd")
var checks:=0
var failures:=0
class Arena extends BASE.Arena:
 var failures_called:=0
 var simulated_pause:=false
 var fail_spawn:=false
 func is_combat_simulation_paused() -> bool:return simulated_pause
 func finish_hero_boss_timeout() -> void:
  if battle_over:return
  failures_called+=1;battle_over=true
 func spawn_hero_encounter(id: String,point: Vector2,data: Dictionary) -> Node2D:
  if fail_spawn:return null
  return super.spawn_hero_encounter(id,point,data)
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize() -> void:run.call_deferred()
func run() -> void:
 var arena:=Arena.new();root.add_child(arena)
 arena.hero=BASE.Actor.new();arena.add_child(arena.hero);arena.hero.position=Vector2(1200,1200)
 var encounters:=ENCOUNTER.new();arena.add_child(encounters);encounters.install(arena)
 arena.run_metrics.elapsed_seconds=901
 arena.fail_spawn=true;encounters.tick(20)
 check(not encounters.boss_started and encounters.boss_remaining()==300,"failed boss spawn does not start deadline")
 arena.fail_spawn=false;encounters.tick(3.1)
 check(encounters.boss_started and encounters.boss_remaining()==300,"successful spawn starts at five minutes")
 encounters.tick(100);check(is_equal_approx(encounters.boss_remaining(),200),"active combat advances deadline")
 arena.external_pause=true;encounters.tick(1000);check(encounters.boss_remaining()==200,"external pause freezes deadline")
 arena.external_pause=false;arena.simulated_pause=true;encounters.tick(1000);check(encounters.boss_remaining()==200,"selection/simulation pause freezes deadline")
 arena.simulated_pause=false;encounters.boss.free();encounters.tick(.1)
 check(encounters.boss_started and encounters.boss_elapsed>100,"replacement does not reset deadline")
 encounters.boss_elapsed=299.9;encounters.tick(.09);check(arena.failures_called==0,"before deadline still playable")
 encounters.tick(.02);check(arena.failures_called==1 and arena.battle_over,"deadline fails once")
 encounters.tick(10);check(arena.failures_called==1,"finished run cannot fail twice")
 arena.battle_over=false;encounters.boss_elapsed=299.9;encounters.boss.current_hp=0;encounters.tick(1)
 check(arena.failures_called==1,"lethal hit takes priority over same-frame timeout")
 var harness=load("res://tests/hero_finale_harness.gd").new();root.add_child(harness)
 harness.hero=BASE.Actor.new();harness.add_child(harness.hero);harness.run_metrics.elapsed_seconds=901
 harness.hero_player_mode=false;harness.finish_hero_boss_timeout();check(harness.finish_count==0,"other modes unaffected")
 harness.hero_player_mode=true;harness.finish_hero_boss_timeout();harness.finish_hero_boss_timeout()
 check(harness.finish_count==1 and not harness.won,"production battle timeout is a single defeat")
 harness.queue_free();arena.queue_free();await process_frame
 print("HERO_BOSS_DEADLINE checks=",checks," failures=",failures);quit(1 if failures else 0)
