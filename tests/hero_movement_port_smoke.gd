extends SceneTree

const INTENT := preload("res://src/hero/hero_action_intent.gd")
const PORT := preload("res://src/hero/hero_action_port.gd")
class Chest:
	extends Node2D
	var hits: Array = []
	func take_damage(amount: float) -> void:
		hits.append(amount)

var checks := 0
var failures := 0
var fields := ["target", "attack_timer", "retarget_timer", "wander_timer",
	"wander_target", "rogue_combo_index", "rogue_combo_direction"]

func _init() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func reset_actor(actor, archetype: String, near: Node2D) -> void:
	actor.hero_archetype = archetype
	actor.position = Vector2(400, 500)
	actor.velocity = Vector2(3, -7)
	actor.target = near
	actor.candidate = near
	actor.attack_range = 650.0
	actor.attack_timer = 0.0
	actor.retarget_timer = 0.5
	actor.move_multiplier = 0.5
	actor.purifier_speed = 0.8
	actor.heal_item_target = null
	actor.magnet_item_target = null
	actor.chest_target = null
	actor.exp_target = null
	actor.material_target_spy = null
	actor.wander_target = Vector2(1400, 1500)
	actor.wander_timer = 3.0
	actor.steer_enabled = true
	actor.gunner_reloading = false
	actor.deadeye_ready = false
	actor.rogue_slash_active = false
	actor.rogue_combo_index = 2
	actor.rogue_combo_direction = Vector2.RIGHT
	actor.fighter_guard_active = false
	actor.fighter_charge_cooldown_timer = 1.0
	actor.charge_ready = false
	actor.berserker_madness_active = false
	actor.contextual_skill = false
	actor.alchemist_gas = 100.0
	actor.alchemist_throw_index = 0
	actor.alchemist_throw_positions.clear()
	actor.chest_attack_target = null
	actor.range_after_move = -1.0
	actor.timer_after_move = -1.0
	actor.replace_target_after_move = false
	actor.replacement_target = null
	actor.reenter_port = true
	actor.replay_rejected = false
	actor.action_intent.clear()

func compare_call(before, after, method: String, arguments: Array, chest: Chest, label: String) -> void:
	before.events.clear()
	after.events.clear()
	chest.hits.clear()
	before.callv(method, arguments)
	var old_hits := chest.hits.duplicate()
	chest.hits.clear()
	var id: int = after.action_intent.get_instance_id()
	after.callv(method, arguments)
	check(before.events == after.events, label + " event order / target")
	check(before.velocity == after.velocity and before.position == after.position, label + " movement")
	var same := true
	for field in fields:
		if before.get(field) != after.get(field):
			same = false
			push_error(label + " field " + field)
	check(same, label + " state / cooldown")
	check(old_hits == chest.hits, label + " chest damage")
	check(after.action_intent.get_instance_id() == id and not after.action_intent.pending and after.action_intent.kind == INTENT.Kind.NONE, label + " same buffer consumed")
	var count: int = after.events.size()
	check(not PORT.execute_movement(after, after.action_intent) and not PORT.execute_basic_attack(after, after.action_intent, after.target) and count == after.events.size(), label + " no replay")
	if "move" in after.events:
		check(after.replay_rejected, label + " consumed before movement callback")

func run() -> void:
	var old_script := load("res://tests/hero_movement_before_fixture.gd") as Script
	var new_script := load("res://tests/hero_movement_after_fixture.gd") as Script
	if old_script == null or new_script == null or not old_script.can_instantiate() or not new_script.can_instantiate():
		push_error("Build isolated movement fixture first")
		quit(1)
		return
	var before = old_script.new()
	var after = new_script.new()
	root.add_child(before)
	root.add_child(after)
	var near := Node2D.new()
	var far := Node2D.new()
	var item := Node2D.new()
	var material := Node2D.new()
	var chest := Chest.new()
	for node in [near, far, item, material, chest]:
		root.add_child(node)
	near.position = Vector2(600, 500)
	far.position = Vector2(1300, 500)
	item.position = Vector2(800, 900)
	material.position = Vector2(650, 800)
	chest.position = Vector2(450, 500)
	var archetypes := {"rogue": "rogue_combo", "fighter": "sword_shield",
		"gunner": "pistol_gunner", "berserker": "berserker_madness",
		"alchemist": "alchemist_chemical", "summoner": "summoner_gatekeeper"}
	for archetype in archetypes:
		for scenario in range(19):
			for actor in [before, after]:
				reset_actor(actor, archetypes[archetype], near)
				match scenario:
					1: actor.attack_timer = 1.0
					2: actor.target = far
					3:
						actor.target = null
						actor.candidate = null
					4: actor.retarget_timer = 0.0
					5: actor.gunner_reloading = true
					6: actor.deadeye_ready = true
					7: actor.rogue_slash_active = true
					8: actor.fighter_guard_active = true
					9:
						actor.fighter_charge_cooldown_timer = 0.0
						actor.charge_ready = true
					10: actor.contextual_skill = true
					11:
						actor.berserker_madness_active = true
						actor.attack_range = 80.0
					12: actor.alchemist_throw_positions.append(Vector2.ONE)
					13:
						actor.alchemist_gas = 0.0
						actor.material_target_spy = material
					14: actor.steer_enabled = false
					15: actor.range_after_move = 100.0
					16: actor.timer_after_move = 2.0
					17:
						actor.replace_target_after_move = true
						actor.replacement_target = far
					18: actor.chest_attack_target = chest
			compare_call(before, after, "_physics_process_" + archetype, [0.016], chest, "%s scenario%d" % [archetype, scenario])
		for actor in [before, after]:
			reset_actor(actor, archetypes[archetype], near)
		for frame in range(120):
			compare_call(before, after, "_physics_process_" + archetype, [0.016], chest, "%s repeat%d" % [archetype, frame])
	for family in ["ranged_kiter", "sword_shield", "alchemist_chemical", "summoner_gatekeeper"]:
		for scenario in range(11):
			for actor in [before, after]:
				reset_actor(actor, family, near)
				actor.target = null
				actor.candidate = null
				match scenario:
					0:
						actor.heal_item_target = item
						actor.magnet_item_target = item
						actor.chest_target = chest
						actor.exp_target = item
					1:
						actor.magnet_item_target = item
						actor.chest_target = chest
						actor.exp_target = item
					2:
						actor.chest_target = chest
						actor.exp_target = item
					3: actor.exp_target = item
					4: actor.wander_timer = 0.0
					5: actor.wander_target = actor.position
					6:
						actor.chest_target = chest
						actor.attack_timer = 1.0
					7:
						actor.heal_item_target = item
						actor.exp_target = item
						actor.steer_enabled = false
					8:
						actor.chest_target = chest
						actor.attack_range = 20.0
					9:
						actor.chest_target = chest
						actor.attack_range = 20.0
						actor.steer_enabled = false
					10:
						actor.chest_target = chest
						actor.alchemist_throw_positions.append(Vector2.ONE)
			var method := "_move_without_monsters"
			var arguments: Array = []
			if family == "sword_shield":
				method = "_fighter_move_without_monsters"
				arguments = [0.62]
			elif family == "summoner_gatekeeper":
				method = "_move_summoner_without_monsters_near_open_gate"
			compare_call(before, after, method, arguments, chest, "%s no-target%d" % [family, scenario])
	var intent := INTENT.new()
	intent.prepare_movement(Vector2.ONE)
	check(not PORT.execute_ranged(after, intent) and intent.pending, "wrong executor cannot consume movement")
	check(PORT.execute_movement(after, intent) and not intent.pending, "movement consumed")
	intent.prepare_basic_attack(INTENT.AttackKind.ALCHEMIST)
	check(not PORT.execute_movement(after, intent) and intent.pending, "wrong executor cannot consume attack")
	after.events.clear()
	check(PORT.execute_basic_attack(after, intent, null), "alchemist null target preserved")
	check(after.events == [["_start_alchemist_basic_attack", 0]], "correct original attack called")
	intent.prepare_basic_attack(999)
	after.events.clear()
	check(not PORT.execute_basic_attack(after, intent, near) and not intent.pending and after.events.is_empty(), "unknown operation consumed without dispatch")
	for node in [before, after, near, far, item, material, chest]:
		node.queue_free()
	await process_frame
	print("hero_movement_port_smoke: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
