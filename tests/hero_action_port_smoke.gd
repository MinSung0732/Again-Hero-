extends SceneTree

const PORT := preload("res://src/hero/hero_action_port.gd")
const INTENT := preload("res://src/hero/hero_action_intent.gd")
var checks := 0
var failures := 0
var state_fields := ["current_hp", "is_dying", "target", "fighter_charge_active",
	"channeling", "attack_timer", "retarget_timer", "wander_timer",
	"attack_pose_timer", "hit_pose_timer", "ultimate_flash_timer", "level_flash_timer",
	"slow_timer", "move_multiplier", "possession_immunity_timer", "ai_memory_clock",
	"ai_observation_timer", "silence_timer", "imposed_skill_cooldown",
	"paralysis_timer", "paralysis_ratio", "petrify_timer", "attack_range"]

func _init() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func configure(actor, archetype: String, candidate: Node2D) -> void:
	actor.global_position = Vector2(400, 500)
	actor.velocity = Vector2(3, -7)
	actor.hero_archetype = archetype
	actor.target = candidate
	actor.candidate = candidate
	actor.current_hp = 100
	actor.is_dying = false
	actor.fighter_charge_active = false
	actor.fighter_charge_target = null
	actor.channeling = false
	actor.purifier_gungnir_casting = false
	actor.stunned = false
	actor.feared = false
	actor.charmed = false
	actor.poison_kills = false
	actor.channel_starts = false
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
	actor.silence_timer = 0.2
	actor.imposed_skill_cooldown = 1.2
	actor.paralysis_timer = 0.2
	actor.paralysis_ratio = 0.5
	actor.petrify_timer = 0.0
	actor.attack_range = 650.0
	actor.purifier_speed = 0.8
	actor.range_after_move = -1.0
	actor.timer_after_move = -1.0
	actor.replace_target_after_move = false
	actor.replacement_target = null
	actor.events.clear()

func compare_frame(before, after, delta: float, label: String) -> void:
	before.events.clear()
	after.events.clear()
	# Simulate a leftover producer value before a gated/normal frame. The actual
	# entry gate must discard it even when no action is prepared this frame.
	after.action_intent.prepare_ranged(Vector2(999, 999), 0.0)
	var buffer_id: int = after.action_intent.get_instance_id()
	before._physics_process(delta)
	after._physics_process(delta)
	check(before.events == after.events, label + " event order / targets")
	check(before.velocity == after.velocity and before.global_position == after.global_position, label + " movement")
	var same := true
	for field in state_fields:
		if before.get(field) != after.get(field):
			same = false
			push_error(label + " field " + field)
	check(same, label + " gameplay state / timers")
	check(before.get_meta("silence_active") == after.get_meta("silence_active") and before.get_meta("burn_active", false) == after.get_meta("burn_active", false), label + " status metadata")
	check(after.action_intent.get_instance_id() == buffer_id and not after.action_intent.pending and after.action_intent.movement_velocity == Vector2.ZERO, label + " reused / consumed buffer")
	var event_count: int = after.events.size()
	check(not PORT.execute_ranged(after, after.action_intent) and after.events.size() == event_count, label + " no replay")

func run() -> void:
	# Generated fixture dependencies are loaded only on explicit test execution.
	var old_script := load("res://tests/hero_action_before_fixture.gd") as Script
	var new_script := load("res://tests/hero_action_after_fixture.gd") as Script
	if old_script == null or new_script == null or not old_script.can_instantiate() or not new_script.can_instantiate():
		push_error("Build isolated Hero action fixture first")
		quit(1)
		return
	var before = old_script.new()
	var after = new_script.new()
	root.add_child(before)
	root.add_child(after)
	before.set_physics_process(false)
	after.set_physics_process(false)
	var near := Node2D.new()
	var far := Node2D.new()
	var hidden := Node2D.new()
	var queued := Node2D.new()
	for node in [near, far, hidden, queued]:
		root.add_child(node)
	near.position = Vector2(600, 500)
	far.position = Vector2(1300, 500)
	hidden.position = Vector2(500, 500)
	hidden.set_meta("detectable", false)
	queued.queue_free()
	var common := ["ranged_kiter", "archmage_elementalist", "cleric_purifier", "grand_sage_astra"]
	for archetype in common:
		for scenario in range(18):
			for actor in [before, after]:
				configure(actor, archetype, near)
				match scenario:
					1: actor.attack_timer = 1.0
					2: actor.target = far
					3:
						actor.target = null
						actor.candidate = null
					4: actor.retarget_timer = 0.0
					5:
						actor.target = hidden
						actor.fighter_charge_active = true
						actor.fighter_charge_target = hidden
					6: actor.channeling = true
					7: actor.purifier_gungnir_casting = true
					8: actor.current_hp = 0
					9: actor.poison_kills = true
					10: actor.stunned = true
					11: actor.feared = true
					12: actor.charmed = true
					13: actor.petrify_timer = 0.1
					14: actor.target = queued
					15: actor.range_after_move = 100.0
					16: actor.timer_after_move = 2.0
					17:
						actor.replace_target_after_move = true
						actor.replacement_target = far
			compare_frame(before, after, 0.016, "%s scenario%d" % [archetype, scenario])
		for actor in [before, after]:
			configure(actor, archetype, near)
			actor.channel_starts = true
		compare_frame(before, after, 0.35, archetype + " skill starts channel before movement")
		for actor in [before, after]:
			configure(actor, archetype, near)
		for frame in range(240):
			var delta: float = [0.0, 0.016, 0.033, 0.1][frame % 4]
			compare_frame(before, after, delta, "%s sequence%d" % [archetype, frame])
	for archetype in ["rogue_combo", "sword_shield", "pistol_gunner", "berserker_madness", "alchemist_chemical", "summoner_gatekeeper"]:
		for actor in [before, after]:
			configure(actor, archetype, near)
		compare_frame(before, after, 0.016, archetype + " dispatch preserved")
	var intent := INTENT.new()
	check(not intent.pending and not intent.basic_attack_requested, "intent initially inactive")
	intent.prepare_ranged(Vector2.ONE, 123.0)
	check(intent.pending and intent.observed_attack_distance == 123.0 and intent.basic_attack_requested, "local producer buffer")
	intent.clear()
	check(not intent.pending and not intent.basic_attack_requested and intent.observed_attack_distance == 0.0, "intent release")
	before.queue_free()
	after.queue_free()
	near.queue_free()
	far.queue_free()
	hidden.queue_free()
	await process_frame
	print("hero_action_port_smoke: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
