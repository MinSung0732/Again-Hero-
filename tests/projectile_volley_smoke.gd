extends SceneTree

const VOLLEY := preload("res://src/hero/projectile_volley.gd")
const BASIC := preload("res://src/hero/HeroProjectile.tscn")
const SAGE := preload("res://src/hero/SageProjectile.tscn")
var failed := false
var arena: Node2D

class Target extends Node2D:
	var total := 0
	var hits := 0
	func take_damage(amount: int) -> void:
		total += amount
		hits += 1

class Arena extends Node2D:
	func recycle_projectile(projectile: Node, _key: String) -> void:
		projectile.deactivate_for_pool()

class HolyCaster extends Node2D:
	func get_purifier_holy_damage_multiplier(_target: Node) -> float:
		return 1.5

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("VOLLEY_TEST: " + message)

func target(group: String = "monsters") -> Target:
	var result := Target.new()
	arena.add_child(result)
	result.add_to_group(group)
	return result

func basic(record = null, splash: float = 0.0):
	var result = BASIC.instantiate()
	arena.add_child(result)
	result.setup(Vector2.RIGHT, 100, 680, 420, "", splash, 0.5, record)
	result.set_physics_process(false)
	return result

func sage(record = null, mode: int = 0):
	var result = SAGE.instantiate()
	arena.add_child(result)
	result.setup(Vector2.RIGHT, 100, 800, 650, mode, 26.4, null, record)
	result.set_physics_process(false)
	return result

func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	arena = Arena.new()
	root.add_child(arena)
	var first := target()
	var second := target()
	var record := VOLLEY.new()
	var bullets: Array = []
	for index in range(5):
		bullets.append(basic(record))
	for bullet in bullets:
		bullet._on_body_entered(first)
	check(first.total == 100 and first.hits == 1, "five fan bullets damage one monster once")
	check(bullets[0].volley == null and bullets[1].volley == record, "pool release preserves sibling record")
	check(bullets[1].active and not bullets[1].has_impacted, "duplicate bullet keeps flying")
	bullets[1]._on_body_entered(second)
	check(second.total == 100, "extra bullet can damage another monster")
	var next = basic(VOLLEY.new())
	next._on_body_entered(first)
	check(first.total == 200, "next attack can damage same monster again")
	for index in range(2):
		basic()._on_body_entered(first)
	check(first.total == 400, "independent projectiles remain independent")
	bullets[0].setup(Vector2.RIGHT, 100, 680, 420)
	bullets[0]._on_body_entered(first)
	check(first.total == 500, "pool reuse drops old volley")
	var chest := target("treasure_chests")
	var chest_record := VOLLEY.new()
	for index in range(2):
		basic(chest_record)._on_body_entered(chest)
	check(chest.total == 200, "chest interaction unchanged")
	var holy_caster := HolyCaster.new()
	arena.add_child(holy_caster)
	var holy_record := VOLLEY.new()
	var holy_target := target()
	for index in range(2):
		var holy = basic(holy_record)
		holy.source_hero_id = "purifier_hero"
		holy.source_hero = holy_caster
		holy._on_body_entered(holy_target)
	check(holy_target.total == 150 and holy_target.hits == 1, "purifier holy multiplier remains applied once")
	holy_target.position = Vector2(5000, 0)
	# First damage wins, including a splash hit before another sibling's direct hit.
	first.position = Vector2(1000, 0)
	second.position = Vector2(1000, 0)
	first.total = 0
	second.total = 0
	var splash_record := VOLLEY.new()
	var splash = basic(splash_record, 100.0)
	splash.position = first.position
	splash._on_body_entered(first)
	var overlap = basic(splash_record, 100.0)
	overlap.position = first.position
	overlap._on_body_entered(second)
	check(first.total == 100 and second.total == 50, "overlapping splash/direct damage does not multiply")
	first.total = 0
	second.total = 0
	var sage_record := VOLLEY.new()
	var sage_a = sage(sage_record)
	var sage_b = sage(sage_record)
	check(sage_a._try_hit_target(first), "sage first hit accepted")
	sage_a.deactivate_for_pool()
	check(not sage_b._try_hit_target(first), "sage sibling still remembers pooled hit")
	check(sage_b._try_hit_target(second), "sage fan damages different target")
	check(first.total == 100 and second.total == 100, "sage fan damage totals")
	var pierce = sage(null, 1)
	check(pierce._try_hit_target(first) and pierce._try_hit_target(second), "single piercing projectile still hits multiple monsters")
	check(not pierce._try_hit_target(first), "piercing retains per-projectile hit limit")
	sage_a.setup(Vector2.RIGHT, 100, 800, 650, 0, 26.4, null)
	check(sage_a._try_hit_target(first), "sage pooled reuse clears previous hits")
	# Exercise the actual hero firing methods, not only the shared record fixture.
	var hero = load("res://src/hero/Hero.tscn").instantiate()
	arena.add_child(hero)
	hero.set_physics_process(false)
	hero.projectile_count_bonus = 4
	for archetype in ["ranged_kiter", "cleric_purifier", "grand_sage_astra"]:
		hero.hero_archetype = archetype
		hero.hero_id = "purifier_hero" if archetype == "cleric_purifier" else "ranged_rookie"
		hero.sage_attack_serial = 0
		var before := arena.get_child_count()
		hero._fire_projectile(first)
		check(arena.get_child_count() - before == 5, archetype + " produces five fan bullets")
		var shared = arena.get_child(before).volley
		check(shared != null, archetype + " owns shared volley")
		for index in range(before, arena.get_child_count()):
			var projectile = arena.get_child(index)
			check(projectile.volley == shared, archetype + " siblings share record")
			projectile.set_physics_process(false)
		before = arena.get_child_count()
		hero._fire_projectile(first)
		check(arena.get_child(before).volley != shared, archetype + " next attack owns new record")
		if archetype == "grand_sage_astra":
			before = arena.get_child_count()
			hero._fire_projectile(first)
			check(arena.get_child_count() - before == 1 and arena.get_child(before).volley == null, "sage third piercing attack remains single and independent")
	arena.free()
	print("PROJECTILE_VOLLEY_FAILED" if failed else "PROJECTILE_VOLLEY_OK")
	quit(1 if failed else 0)
