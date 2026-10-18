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
var coincident: Node2D
func _initialize(): call_deferred("run")
func check(ok: bool, label: String):
	checks += 1
	if not ok: failures += 1; push_error(label)
func make(script, archetype: String):
	var node = script.new(); root.add_child(node)
	node.hero_archetype = archetype; node.global_position = Vector2(400, 500)
	return node
func compare(a, b, label: String):
	check(a.binding_state() == b.binding_state(), label)
	a.free(); b.free()
func fire_case(archetype, bonus, guard, fail, mutation = {}):
	var a = make(BEFORE, archetype); var b = make(AFTER, archetype)
	for node in [a, b]:
		node.projectile_count_bonus = bonus
		node.channeling = guard == 1
		node.fail_acquires = [1] if fail == 1 else ([1, 2, 3, 4, 5] if fail == 2 else [])
		node.mutations = mutation
		node._fire_projectile(null if guard == 2 else (coincident if guard == 3 else near))
	compare(a, b, "fire %s/%s/%s/%s/%s" % [archetype, bonus, guard, fail, mutation])
func skill_case(archetype, method, config, silent, frames, flipped):
	var a = make(BEFORE, archetype); var b = make(AFTER, archetype)
	for node in [a, b]:
		node.channel_skill_config = config
		node.shield_skill_config = config
		node.ultimate_config = config
		node.silence_timer = 1.0 if silent else 0.0
		node.hero_sprite.flip_h = flipped
		if not frames:
			node.channel_effect.sprite_frames = null
			node.shield_effect.sprite_frames = null
		node.call(method)
	compare(a, b, "skill %s/%s/%s/%s/%s/%s" % [archetype, method, config, silent, frames, flipped])
func context_case(archetype, fighter, magic, mutation):
	var a = make(BEFORE, archetype); var b = make(AFTER, archetype)
	for node in [a, b]:
		if fighter > 0:
			node.fighter_block_audio = AudioStreamPlayer.new(); node.add_child(node.fighter_block_audio)
			if fighter == 2: node.fighter_block_audio.free()
		if magic > 0:
			node.magic_block_audio = AudioStreamPlayer.new(); node.add_child(node.magic_block_audio)
			if magic == 2: node.magic_block_audio.free()
		node.mutations = mutation
		node._prepare_contextual_damage_audio()
		node._prepare_contextual_damage_audio()
	compare(a, b, "context audio")
func augment_case(archetype, id, stack, maximum, mutation):
	var a = make(BEFORE, archetype); var b = make(AFTER, archetype)
	for node in [a, b]:
		node.build_counts = {id: stack}
		node.mutations = mutation
		node._apply_augment({"id": id, "max_stack": maximum, "effects": [{"fixture": 1}]})
	compare(a, b, "augment %s/%s/%s/%s/%s" % [archetype, id, stack, maximum, mutation])
func level_case(archetype, start, mode, empty, mutation):
	var a = make(BEFORE, archetype); var b = make(AFTER, archetype)
	var rng_after: Array = []
	for node in [a, b]:
		node.level = start
		node.fixture_candidates = [] if empty else [{"id": "summoner_watcher_network", "name": "fixture", "max_stack": 3, "effects": [{"fixture": 1}]}]
		if mode == 1: node.enable_player(true)
		if mode == 2: node.player_controlled = true
		node.mutations = mutation
		node.activate_fixture()
		seed(1931)
		node._level_up()
		rng_after.append(randi())
	check(rng_after[0] == rng_after[1], "level RNG order")
	compare(a, b, "level %s/%s/%s/%s/%s" % [archetype, start, mode, empty, mutation])
func charm_case(archetype, delta, snapshot_mode, source, phase):
	var a = make(BEFORE, archetype); var b = make(AFTER, archetype)
	for node in [a, b]:
		node.archmage_skill_cooldowns = {"combustion": -1.0, "ice_bolt": 3.0, "extra": 4.0}
		node.charm_cooldown_properties = [] if snapshot_mode == 0 else ([&"frozen_timer"] if snapshot_mode == 1 else [&"frozen_timer", &"unused_timer"])
		node.charm_source = weakref(source) if source != null else null
		node.charm_timer = 0.0 if phase == 2 else 2.0
		node.sage_phase_active = phase > 0
		node.sage_phase_remaining = 0.005 if phase == 1 else 5.0
		node.slow_timer = 0.01
		node._tick_charm_state(delta)
	compare(a, b, "charm")
func run():
	near = Node2D.new(); root.add_child(near); near.position = Vector2(600, 500)
	far = Node2D.new(); root.add_child(far); far.position = Vector2(1300, 500)
	hidden = Node2D.new(); root.add_child(hidden); hidden.position = near.position; hidden.set_meta("detectable", false)
	coincident = Node2D.new(); root.add_child(coincident); coincident.position = Vector2(400, 500)
	for archetype in ARCHETYPES:
		for bonus in [-2, 0, 1, 4, 10]:
			for guard in range(4):
				for fail in range(3): fire_case(archetype, bonus, guard, fail)
		for method in ["_activate_channel_skill", "_activate_shield", "_use_piercing_projectile_ultimate"]:
			for config in [{}, {"duration": -1.0, "cooldown": -1.0, "tick_interval": -1.0, "shield_hp": 0.0, "shield_hp_ratio": 0.0, "damage": 0, "projectile_speed": 0.0, "projectile_range": 0.0}, {"duration": 1.2, "cooldown": 3.0, "tick_interval": 0.5, "shield_hp": 25.0, "damage": 99, "projectile_speed": 777.0, "projectile_range": 888.0}]:
				for silent in [false, true]:
					for frames in [false, true]:
						for flipped in [false, true]: skill_case(archetype, method, config, silent, frames, flipped)
		for fighter in range(3):
			for magic in range(3): context_case(archetype, fighter, magic, {})
		for id in ["", "summoner_watcher_network", "purifier_", "purifier_book_of_purification", "purifier_other", "unrelated"]:
			for stack in [0, 1, 3]:
				for maximum in [0, 1, 3]: augment_case(archetype, id, stack, maximum, {})
		for start in [1, 4, 5, 9, 10]:
			for mode in range(3):
				for empty in [false, true]: level_case(archetype, start, mode, empty, {})
		for delta in [0.0, 0.016, 2.0]:
			for snapshot_mode in range(3):
				for source in [null, near, far, hidden]:
					for phase in range(3): charm_case(archetype, delta, snapshot_mode, source, phase)
	for from_archetype in ARCHETYPES:
		for to_archetype in ARCHETYPES:
			for point in ["face", "animation", "audio_basic", "projectile_setup"]:
				fire_case(from_archetype, 1, 0, 0, {point: to_archetype})
			context_case(from_archetype, 0, 0, {"ensure_hit": to_archetype})
			augment_case(from_archetype, "purifier_other", 0, 3, {"augment_effect": to_archetype})
			for point in ["feedback", "growth", "ai_context"]:
				level_case(from_archetype, 4, 0, false, {point: to_archetype})
			for point in ["heal_steer", "chest_steer", "magnet_steer"]:
				var a = make(BEFORE, from_archetype); var b = make(AFTER, from_archetype)
				for node in [a, b]:
					node.target = near
					node.mutations = {point: to_archetype}
					node._prepare_ranged_ai_intent(0.016, 200.0)
				compare(a, b, "boundary live mutation")
	# Independent example: do not collapse two sequential basic-audio checks.
	var node = make(AFTER, "ranged_kiter")
	node.mutations = {"audio_basic": "cleric_purifier"}
	node._fire_projectile(near)
	check(["audio", &"basic"] in node.events and "purifier_basic" in node.events, "sequential basic cues")
	node.free()
	for target in [near, far, hidden, coincident]: target.free()
	print("HERO_REMAINING_BINDING_POLICY checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
