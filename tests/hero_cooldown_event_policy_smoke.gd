extends SceneTree
const BEFORE = preload("res://before.gd")
const AFTER = preload("res://after.gd")
const BINDINGS = preload("res://src/data/hero_runtime_binding_catalog.gd")
const PRESENTATION = preload("res://src/data/hero_presentation_catalog.gd")
var checks := 0
var failures := 0

func _initialize(): call_deferred("run")
func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func make(script, archetype: String, gate: int, values: int = 0):
	var node = script.new()
	root.add_child(node)
	node.hero_archetype = archetype
	node.unlocked = {"sage_skill_5": bool(gate & 1), "purifier_fourth_skill": bool(gate & 2)}
	node.summoner_open_gate_unlocked = bool(gate & 1)
	for profile in BINDINGS.PROPERTY_COOLDOWNS.values():
		for property in profile.properties:
			node.timers[property] = -2.0 if values == 1 else (null if values == 2 else 3.0)
		for property in profile.get("expanded_properties", []):
			node.timers[property] = -2.0 if values == 1 else (null if values == 2 else 3.0)
	node.archmage_skill_config = {"combustion": {"enabled": false}, "ice_bolt": {}, "earth_spikes": null, "holy_power": [], "chain_dagger": {"x": 1}}
	node.archmage_skill_cooldowns = {"combustion": -1.0, "ice_bolt": 2.0, "extra": 9.0}
	return node

func list_case(archetype: String, gate: int):
	var a = make(BEFORE, archetype, gate)
	var b = make(AFTER, archetype, gate)
	var old_list = a._get_external_skill_cooldown_properties()
	var new_list = b._get_external_skill_cooldown_properties()
	check(old_list == new_list and a.trace == b.trace, "property list/gate mismatch")
	old_list.clear()
	new_list.clear()
	check(a._get_external_skill_cooldown_properties() == b._get_external_skill_cooldown_properties(), "legacy lists own their storage")
	# The charm owner really clears its snapshot. Shared metadata must survive it.
	a.charm_cooldown_properties = a._get_external_skill_cooldown_properties()
	b.charm_cooldown_properties = b._get_external_skill_cooldown_properties()
	a._clear_charm()
	b._clear_charm()
	check(a._get_external_skill_cooldown_properties() == b._get_external_skill_cooldown_properties(), "charm clear must not clear shared lists")
	for node in [a, b]:
		node.unlocked = {"sage_skill_5": not bool(gate & 1), "purifier_fourth_skill": not bool(gate & 2)}
		node.summoner_open_gate_unlocked = not bool(gate & 1)
	check(a._get_external_skill_cooldown_properties() == b._get_external_skill_cooldown_properties(), "live unlock refresh")
	a.free()
	b.free()

func owner_case(archetype: String, gate: int, seconds: float, values: int, guard: int):
	for method in ["add_random_skill_cooldown_delay", "_tick_fear_skill_cooldowns", "impose_all_skill_cooldowns"]:
		# The existing full-impose API requires numeric properties. Its legacy
		# float(null) error is outside this refactor; random/fear support null.
		if values == 2 and guard == 0 and method == "impose_all_skill_cooldowns":
			continue
		var a = make(BEFORE, archetype, gate, values)
		var b = make(AFTER, archetype, gate, values)
		for node in [a, b]:
			node.current_hp = 0 if guard == 1 else 50
			node.is_dying = guard == 2
		seed(1793)
		var result_a = a.call(method, seconds)
		var next_a = randi()
		seed(1793)
		var result_b = b.call(method, seconds)
		var next_b = randi()
		check(result_a == result_b and next_a == next_b and a.cooldown_state() == b.cooldown_state(), "cooldown owner mismatch: %s/%s/%s/%s/%s/%s" % [archetype, gate, method, seconds, values, guard])
		a.free()
		b.free()

func run():
	check(BEFORE.ARCHMAGE_SKILL_KEYS == AFTER.ARCHMAGE_SKILL_KEYS, "shared dictionary key order")
	var saved = BINDINGS.PROPERTY_COOLDOWNS.duplicate(true)
	var saved_dictionary = BINDINGS.DICTIONARY_COOLDOWNS.duplicate(true)
	var saved_events = PRESENTATION.EVENT_AUDIO.duplicate(true)
	var archetypes = PRESENTATION.VISUAL_PROFILES.keys()
	archetypes.append("unknown")
	archetypes.append("")
	for archetype in archetypes:
		for gate in range(4):
			list_case(archetype, gate)
			for seconds in [-1.0, 0.0, 0.1, 1.5, 5.0]:
				for values in range(3):
					for guard in range(3):
						owner_case(archetype, gate, seconds, values, guard)
	# Empty, all-configured and malformed dictionary configurations affect RNG only
	# when a valid candidate exists; verify the global generator's next result too.
	for config in [{}, {"combustion": null}, {"combustion": {}, "ice_bolt": []}, {"combustion": {"x": 1}}, {"combustion": {"x": 1}, "ice_bolt": {"x": 2}, "harmony": {"x": 0}}]:
		for random_seed in [1, 2, 17, 999, 12345]:
			var a = make(BEFORE, "archmage_elementalist", 0)
			var b = make(AFTER, "archmage_elementalist", 0)
			a.archmage_skill_config = config.duplicate(true)
			b.archmage_skill_config = config.duplicate(true)
			seed(random_seed)
			var first = a.add_random_skill_cooldown_delay(2.0)
			var next = randi()
			seed(random_seed)
			var second = b.add_random_skill_cooldown_delay(2.0)
			check(first == second and next == randi() and a.cooldown_state() == b.cooldown_state(), "dictionary config/RNG mismatch")
			a.free()
			b.free()
	# Full level-up owner with absent/empty/valid effects and valid/null/freed audio.
	for archetype in archetypes:
		for effect_mode in range(4):
			for audio_mode in range(3):
				var a = make(BEFORE, archetype, 0)
				var b = make(AFTER, archetype, 0)
				for node in [a, b]:
					if effect_mode > 0:
						var frames = SpriteFrames.new()
						if effect_mode > 1: frames.add_animation(&"level_up")
						if effect_mode > 2: frames.add_frame(&"level_up", ImageTexture.create_from_image(Image.create(4, 4, false, Image.FORMAT_RGBA8)))
						node.level_up_effect.sprite_frames = frames
					else:
						node.level_up_effect.sprite_frames = null
					if audio_mode == 1: node.level_up_audio = null
					if audio_mode == 2: node.level_up_audio.free()
					node._play_level_up_feedback()
					node._play_level_up_feedback()
				check(a.level_up_state() == b.level_up_state(), "level-up event/fallback mismatch")
				a.free()
				b.free()
	# Execute the actual asynchronous death owner, including real Tween, timer,
	# death_started/died signals, repeated request and queue_free/tree exit.
	var death_pairs: Array = []
	for archetype in archetypes:
		for mode in range(5):
			var a = make(BEFORE, archetype, 1)
			var b = make(AFTER, archetype, 1)
			for node in [a, b]:
				node.velocity = Vector2(11, 17)
				node.modulate.a = 0.4
				node.set_meta("dullahan_soul_stacks", 4)
				node.set_meta("fear_active", true)
				node.set_meta("poison_active", true)
				node.charm_cooldown_properties = node._get_external_skill_cooldown_properties()
				if mode == 0: node.hero_sprite.visible = false
				if mode == 1: node.hero_sprite.sprite_frames.remove_animation(&"death")
				if mode == 2: node.hero_sprite.sprite_frames = null
				if mode == 3: node.is_dying = true
				node._begin_death_sequence()
				node._begin_death_sequence()
				if mode == 4: root.remove_child(node)
			check(a.trace == b.trace and a.death_state() == b.death_state(), "death immediate order/state mismatch")
			death_pairs.append([a, b, a.trace, b.trace])
	await create_timer(0.65).timeout
	for pair in death_pairs:
		check(pair[2] == pair[3] and is_instance_valid(pair[0]) == is_instance_valid(pair[1]), "death completion signal/tween/exit mismatch")
		for index in range(2):
			if is_instance_valid(pair[index]): pair[index].free()
	# Independent scalar outcome and the unknown-event no-op.
	var custom = make(AFTER, "ranged_kiter", 0)
	custom._tick_fear_skill_cooldowns(0.5)
	check(custom.timers[&"ultimate_cooldown_timer"] == 2.5 and custom.timers[&"shield_cooldown_timer"] == 2.5 and custom.timers[&"channel_cooldown_timer"] == 2.5, "independent cooldown result")
	custom.hero_archetype = "ranged_kiter"
	custom.trace.clear()
	check(custom._play_bound_hero_audio(&"missing") == false and custom.trace.is_empty(), "unknown event is no-op")
	custom.free()
	check(BINDINGS.PROPERTY_COOLDOWNS == saved and BINDINGS.DICTIONARY_COOLDOWNS == saved_dictionary and PRESENTATION.EVENT_AUDIO == saved_events, "shared rules unchanged")
	print("HERO_COOLDOWN_EVENT_POLICY checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
