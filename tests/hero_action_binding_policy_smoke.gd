extends SceneTree
const BEFORE = preload("res://before.gd")
const AFTER = preload("res://after.gd")
const BINDINGS = preload("res://src/data/hero_runtime_binding_catalog.gd")
const ARCHETYPES = ["ranged_kiter", "rogue_combo", "sword_shield", "pistol_gunner", "archmage_elementalist", "berserker_madness", "alchemist_chemical", "summoner_gatekeeper", "cleric_purifier", "grand_sage_astra", "unknown", ""]
var checks := 0
var failures := 0
var near: Node2D
var far: Node2D
var hidden: Node2D

func _initialize(): call_deferred("run")
func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func make(script, archetype: String, mode: int):
	var actor = script.new()
	root.add_child(actor)
	actor.hero_archetype = archetype
	actor.global_position = Vector2(400, 500)
	actor.velocity = Vector2(3, -7)
	actor.target = near
	actor.candidate = near
	actor.attack_timer = 0.0
	actor.retarget_timer = 0.5
	actor.wander_timer = 0.4
	actor.attack_pose_timer = 0.34
	actor.hit_pose_timer = 0.2
	actor.ultimate_flash_timer = 0.1
	actor.level_flash_timer = 0.1
	actor.slow_timer = 0.2
	actor.move_multiplier = 0.5
	actor.possession_immunity_timer = 2.0
	actor.ai_memory_clock = 15.0
	actor.ai_observation_timer = 0.25
	actor.paralysis_ratio = 0.5
	if mode == 1 or mode == 3: actor.enable_player(mode == 1)
	if mode == 2: actor.player_controlled = true
	return actor

func compare_frames(a, b, delta: float, label: String):
	var before_buffer = a.action_intent.get_instance_id()
	var after_buffer = b.action_intent.get_instance_id()
	for frame in range(3):
		for node in [a, b]:
			node.events.clear()
			node.action_intent.prepare_ranged(Vector2(999, 999), 0.0)
		a._physics_process_actions(delta)
		b._physics_process_actions(delta)
		check(a.snapshot() == b.snapshot(), "action owner mismatch: " + label + "/" + str(frame))
		check(a.action_intent.get_instance_id() == before_buffer and b.action_intent.get_instance_id() == after_buffer, "retained intent buffer")
		if b._hero_action_binding_valid:
			check(b._hero_pose_tick.is_valid(), "cached player pose is always valid")

func scenario_case(archetype: String, mode: int, delta: float, scenario: int):
	var a = make(BEFORE, archetype, mode)
	var b = make(AFTER, archetype, mode)
	for node in [a, b]:
		match scenario:
			1: node.current_hp = 0
			2: node.is_dying = true
			3: node.poison_kills = true
			4: node.stunned = true
			5: node.feared = true
			6: node.charmed = true
			7: node.channeling = true
			8: node.purifier_gungnir_casting = true
			9: node.target = null; node.candidate = null
			10: node.target = hidden
			11: node.target = far
			12: node.fighter_charge_active = true; node.fighter_charge_target = hidden
			13: node.retarget_timer = 0.0; node.channel_starts = true
			14: node.berserker_reviving = true
			15: node.berserker_reviving = true; node.revive_finishes = true
			16: node.alchemist_philosopher_channeling = true
			17: node.alchemist_philosopher_unlock_pending = true
			18: node.weapon_starts_channel = true
			19: node.range_after_move = 1.0
	compare_frames(a, b, delta, "%s/%d/%s/%d" % [archetype, mode, delta, scenario])
	a.free()
	b.free()

func run():
	var saved = BINDINGS.ACTION_BINDINGS.duplicate(true)
	near = Node2D.new(); root.add_child(near); near.position = Vector2(600, 500)
	far = Node2D.new(); root.add_child(far); far.position = Vector2(1300, 500)
	hidden = Node2D.new(); root.add_child(hidden); hidden.position = Vector2(500, 500); hidden.set_meta("detectable", false)
	for archetype in ARCHETYPES:
		for mode in range(4):
			for delta in [0.0, 0.016, 0.2]:
				for scenario in range(20):
					scenario_case(archetype, mode, delta, scenario)
	# Change identities inside preceding callbacks, at the original selection
	# boundaries, and inside a selected specialization/pose callback itself.
	for from_archetype in ARCHETYPES:
		for to_archetype in ARCHETYPES:
			for mode in [0, 1]:
				for point in ["weapon_tick", "move", "_update_combat_reposition", "channel", "_update_ultimate", "_update_archmage_skill_runtime", "rogue", "rogue_pose"]:
					var a = make(BEFORE, from_archetype, mode)
					var b = make(AFTER, from_archetype, mode)
					for node in [a, b]: node.mutations = {point: to_archetype}
					compare_frames(a, b, 0.016, "mutation %s/%s/%d/%s" % [from_archetype, to_archetype, mode, point])
					a.free(); b.free()
	# The same cached identity also works when only player mode changes.
	for archetype in ARCHETYPES:
		var a = make(BEFORE, archetype, 0)
		var b = make(AFTER, archetype, 0)
		for mode in [0, 1, 0, 3, 2]:
			for node in [a, b]:
				node.player_controlled = mode > 0
				node.player_weapons = null
				if mode == 1 or mode == 3: node.enable_player(mode == 1)
			compare_frames(a, b, 0.016, "mode change")
		a.free(); b.free()
	# Independent routing expectations, without consulting the new metadata.
	var node = make(AFTER, "rogue_combo", 0)
	node._physics_process_actions(0.016)
	check("rogue" in node.events and not "observe" in node.events, "specialized AI returns before common AI")
	node.enable_player(true); node.events.clear()
	node._physics_process_actions(0.016)
	check("rogue_pose" in node.events and not "rogue" in node.events, "player uses pose only")
	node.hero_archetype = "unknown"; node.events.clear()
	node._physics_process_actions(0.016)
	check("_update_stage1_pose_visual" in node.events, "unknown player pose fallback")
	node.player_controlled = false; node.player_weapons = null
	node.hero_archetype = "archmage_elementalist"; node.events.clear()
	node._physics_process_actions(0.016)
	check("_update_archmage_skill_runtime" in node.events, "common runtime hook")
	node.free()
	check(BINDINGS.ACTION_BINDINGS == saved, "shared bindings unchanged")
	near.free(); far.free(); hidden.free()
	print("HERO_ACTION_BINDING_POLICY checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
