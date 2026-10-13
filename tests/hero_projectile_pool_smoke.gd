extends SceneTree
const RUNTIME := preload("res://src/hero_mode/hero_weapon_runtime.gd")
var checks := 0
var failures := 0
class Actor extends Node2D:
	var hp := 100
	func take_damage(amount: int) -> bool:
		hp -= amount
		return true
class Authority extends Node2D:
	var actor: Actor
	var generation := 1
	func get_battle_entity_handle(target: Node) -> Vector3i:
		return Vector3i(1,generation,1) if target == actor else Vector3i.ZERO
	func resolve_battle_entity(handle: Vector3i) -> Node:
		return actor if handle == Vector3i(1,generation,1) else null
class Hero extends Node2D:
	var hero_id := "ranged_rookie"
	var max_hp := 1200
	var move_speed := 270.0
	var exp_pickup_radius := 150.0
	var exp_gain_multiplier := 1.0
	var build_counts: Dictionary = {}
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func run() -> void:
	var authority := Authority.new(); root.add_child(authority)
	authority.actor = Actor.new(); authority.add_child(authority.actor)
	authority.actor.position = Vector2(144,0)
	var hero := Hero.new(); authority.add_child(hero)
	var runtime := RUNTIME.new(); runtime.install(hero)
	runtime._launch_projectile(authority.actor,Vector2.ZERO,10,1,Color.WHITE)
	check(authority.actor.hp == 100,"launch does not deal instant damage")
	runtime._tick_projectiles(0.1)
	check(authority.actor.hp == 100,"base-speed shot still in flight")
	authority.generation += 1
	runtime._tick_projectiles(0.1)
	check(authority.actor.hp == 100,"retired generation cannot receive pending hit")
	for rank in range(10): runtime.add("survival_projectile")
	runtime._launch_projectile(authority.actor,Vector2.ZERO,10,1,Color.WHITE)
	runtime._tick_projectiles(0.1)
	check(authority.actor.hp == 90,"double-speed shot arrives in half the time")
	for shot in range(100): runtime._launch_projectile(authority.actor,Vector2.ZERO,1,1,Color.WHITE)
	var active := 0
	for shot in runtime.projectiles:
		if bool(shot.active): active += 1
	check(active == 64 and runtime.projectiles.size() == 64,"saturated pool stays bounded")
	authority.queue_free()
	print("HERO_PROJECTILE_POOL_SMOKE checks=",checks," failures=",failures)
	quit(1 if failures else 0)
