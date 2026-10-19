extends SceneTree

const BEFORE = preload("res://before.gd")
const AFTER = preload("res://after.gd")
const OLD = preload("res://before_catalog.gd")
const NEW = preload("res://after_catalog.gd")
const EXTENDED = preload("res://extended.gd")
const EXTENDED_DATA = preload("res://extended_catalog.gd")
const ARCHETYPES = ["ranged_kiter", "rogue_combo", "sword_shield", "pistol_gunner", "archmage_elementalist", "berserker_madness", "alchemist_chemical", "summoner_gatekeeper", "cleric_purifier", "grand_sage_astra", "unknown", ""]
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var before = BEFORE.new()
	var after = AFTER.new()
	for archetype in ARCHETYPES:
		before.hero_archetype = archetype
		after.hero_archetype = archetype
		for raw_augment in OLD.AUGMENTS + [{"id": "missing"}, {"id": ""}]:
			var augment: Dictionary = raw_augment
			var id := String(augment.get("id", ""))
			for supplied in [-5, -1, 0, 1, 3, 10, 100]:
				check(OLD.get_effective_max_stack(id, archetype, supplied) == NEW.get_effective_max_stack(id, archetype, supplied), "effective limit %s/%s/%s" % [archetype, id, supplied])
			for stack in [-1, 0, 1, 2, 3, 4, 9, 10, 11, 100]:
				var source := {id: stack, "unrelated": 17, "nested": {"value": 3}}
				before.build_counts = source.duplicate(true)
				after.build_counts = source.duplicate(true)
				var old_counts: Dictionary = before._get_augment_roll_build_counts()
				var new_counts: Dictionary = after._get_augment_roll_build_counts()
				check(old_counts == new_counts, "roll snapshot %s/%s/%s" % [archetype, id, stack])
				check(is_same(old_counts, before.build_counts) == is_same(new_counts, after.build_counts), "snapshot identity")
				check(before.build_counts == source and after.build_counts == source, "source counts preserved")
				check(is_same(new_counts["nested"], after.build_counts["nested"]), "shallow snapshot retained")
				before.effects.clear()
				after.effects.clear()
				before.hooks.clear()
				after.hooks.clear()
				before._apply_augment(augment)
				after._apply_augment(augment)
				check(before.build_counts == after.build_counts and before.effects == after.effects and before.hooks == after.hooks, "application/effect/hook parity")
		# Use real weighted roll code, identical seed, order and next RNG value.
		for stack in [0, 2, 3, 4, 10, 99]:
			before.build_counts = {"pursuit": stack, "projectile_power": 2}
			after.build_counts = before.build_counts.duplicate()
			for allowed in [[], ["pursuit"], ["pursuit", "projectile_power", "missing"], ["missing"]]:
				for count in [0, 1, 3, 500]:
					seed(20261020 + stack)
					var old_candidates: Array = OLD.roll_candidates(count, before._get_augment_roll_build_counts(), allowed)
					var old_next := randf()
					seed(20261020 + stack)
					var new_candidates: Array = NEW.roll_candidates(count, after._get_augment_roll_build_counts(), allowed)
					check(old_candidates == new_candidates and old_next == randf(), "seeded candidates/order/next RNG")
	# Per-selection snapshots must reflect hero switches and current counts.
	after.build_counts = {"pursuit": 3}
	after.hero_archetype = "alchemist_chemical"
	check(after._get_augment_roll_build_counts()["pursuit"] == 10, "alchemist cap masks roll")
	after.hero_archetype = "rogue_combo"
	check(is_same(after._get_augment_roll_build_counts(), after.build_counts), "hero switch restores shared limit")
	after.hero_archetype = "alchemist_chemical"
	after.build_counts["pursuit"] = 2
	check(is_same(after._get_augment_roll_build_counts(), after.build_counts), "live count below cap")
	var extended = EXTENDED.new()
	extended.hero_archetype = "fixture_new_hero"
	extended.build_counts = {"pursuit": 1, "projectile_power": 2, "unrelated": 99}
	var snapshot: Dictionary = extended._get_augment_roll_build_counts()
	check(snapshot == {"pursuit": 10, "projectile_power": 4, "unrelated": 99}, "two content-only limits masked")
	check(not is_same(snapshot, extended.build_counts) and extended.build_counts.pursuit == 1, "one separate snapshot/source preserved")
	check(EXTENDED_DATA.roll_candidates(3, snapshot, ["pursuit", "projectile_power"]).is_empty(), "new hero caps filter both candidates")
	for id in ["pursuit", "projectile_power"]:
		var original: Dictionary = extended.build_counts.duplicate()
		extended._apply_augment(EXTENDED_DATA.get_augment(id))
		check(extended.build_counts == original and extended.effects.is_empty() and extended.hooks.is_empty(), "new policy also gates application")
		extended.build_counts[id] -= 1
		extended._apply_augment(EXTENDED_DATA.get_augment(id))
		check(extended.build_counts == original, "new policy permits below cap")
		extended.effects.clear()
		extended.hooks.clear()
	print("HERO_STACK_POLICY checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
