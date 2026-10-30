extends SceneTree

class Arena extends Node2D:
 var victim: Node2D
 func get_nearest_monster_target(_point: Vector2, _radius: float) -> Node2D:
  return victim if is_instance_valid(victim) and not victim.is_queued_for_deletion() and not victim.get_meta("hero_detection_hidden", false) else null
class Owner extends Node2D:
 var target: Node2D
class Victim extends Node2D:
 var current_hp := 100000
 func take_damage(amount: int, _source = null) -> bool:
  current_hp -= amount
  return true
var failures := 0
func check(value: bool, label: String) -> void:
 if not value:
  failures += 1
  push_error(label)
func _initialize() -> void:
 run.call_deferred()
func run() -> void:
 var arena := Arena.new()
 root.add_child(arena)
 var victim := Victim.new()
 arena.add_child(victim)
 arena.victim = victim
 victim.position = Vector2(400, 0)
 var wall := StaticBody2D.new()
 wall.collision_layer = 4
 wall.collision_mask = 0
 var shape := CollisionShape2D.new()
 var rect := RectangleShape2D.new()
 rect.size = Vector2(40, 200)
 shape.shape = rect
 wall.add_child(shape)
 arena.add_child(wall)
 wall.position = Vector2(140, 0)
 for kind in ["Scout", "Hound"]:
  var actor = load("res://src/hero/Summoner%s.tscn" % kind).instantiate()
  arena.add_child(actor)
  actor.activate(Vector2.ZERO, null, {"attack_range": 40.0, "sense_range": 1000.0, "move_speed": 220.0, "duration": 30.0})
  actor.visual.stop()
  actor.visual.play("idle")
  var before := victim.current_hp
  await create_timer(6.5).timeout
  print(kind, " position=", actor.position, " hp_delta=", before-victim.current_hp)
  check(victim.current_hp < before, kind + " cannot reach enemy behind obstacle")
  actor.deactivate()
  actor.activate(Vector2(360, 0), null, {"attack_range": 40.0, "sense_range": 1000.0, "duration": 30.0})
  actor.visual.stop()
  actor.visual.play("idle")
  victim.set_meta("hero_detection_hidden", true)
  await create_timer(0.25).timeout
  check(actor.target == null, kind + " drops hidden target after pool reuse")
  victim.set_meta("hero_detection_hidden", false)
  await create_timer(0.25).timeout
  check(actor.target == victim, kind + " reacquires revealed target")
  actor.process_mode = Node.PROCESS_MODE_DISABLED
  var paused_duration: float = actor.duration_remaining
  await create_timer(0.2).timeout
  check(actor.duration_remaining == paused_duration, kind + " freezes while paused")
  actor.process_mode = Node.PROCESS_MODE_INHERIT
  await create_timer(0.2).timeout
  check(actor.duration_remaining < paused_duration, kind + " resumes after pause")
  if kind == "Hound":
   actor._start_attack(victim)
  victim.queue_free()
  var replacement := Victim.new()
  arena.add_child(replacement)
  replacement.position = Vector2(400, 0)
  arena.victim = replacement
  victim = replacement
  await create_timer(0.7).timeout
  check(actor.target == victim, kind + " reacquires after target is freed during attack")
  if kind == "Hound":
   check(actor.pending_hits == 0, "hound clears pending hits after target is freed")
  actor.queue_free()
  await process_frame
 var gate = load("res://src/hero/SummonerOpenGate.tscn").instantiate()
 arena.add_child(gate)
 gate.activate(Vector2.ZERO, null, {"drone_pool_size": 1, "open_duration": 3.0, "drone_spawn_interval": 0.05})
 gate.visual.pause()
 gate.opening_watchdog_remaining = 0.1
 await create_timer(0.35).timeout
 check(gate.phase == &"open" and gate.drone_spawn_index > 0, "gate recovers a lost opening animation callback")
 gate.deactivate()
 var owner := Owner.new()
 arena.add_child(owner)
 owner.target = victim
 var watcher = load("res://src/hero/SummonerWatcher.tscn").instantiate()
 arena.add_child(watcher)
 watcher.activate(Vector2.ZERO, owner, {"attack_range": 1000.0})
 check(watcher._get_owner_priority_target() == victim, "watcher accepts live priority target")
 victim.set_meta("hero_detection_hidden", true)
 check(watcher._get_owner_priority_target() == null, "watcher rejects hidden priority target")
 victim.set_meta("hero_detection_hidden", false)
 victim.current_hp = 0
 check(watcher._get_owner_priority_target() == null, "watcher rejects dying priority target")
 victim.queue_free()
 check(watcher._get_owner_priority_target() == null, "watcher rejects queued priority target")
 await process_frame
 check(watcher._get_owner_priority_target() == null, "watcher rejects freed priority target")
 watcher.deactivate()
 var first := Victim.new()
 arena.add_child(first)
 first.position = Vector2(400, 0)
 arena.victim = first
 var drone = load("res://src/hero/SummonerSuicideDrone.tscn").instantiate()
 arena.add_child(drone)
 drone.activate(Vector2.ZERO, null, {"sense_range": 1000.0})
 drone.target = first
 first.queue_free()
 var second := Victim.new()
 arena.add_child(second)
 second.position = Vector2(400, 0)
 arena.victim = second
 await create_timer(0.3).timeout
 check(drone.target == second, "drone reacquires a freed target")
 drone.deactivate()
 arena.queue_free()
 print("summoner stall watchdog ", "PASS" if failures == 0 else "FAIL", " failures=", failures)
 quit(0 if failures == 0 else 1)
