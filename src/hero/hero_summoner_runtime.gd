extends RefCounted
class_name HeroSummonerRuntime


static func get_level_slot_bonus(level: int) -> int:
	return maxi(int(floor(float(level) / 5.0)), 0)


static func get_slot_capacity(
	slot_base: int,
	slot_bonus: int,
	level: int
) -> int:
	return maxi(
		slot_base
		+ slot_bonus
		+ get_level_slot_bonus(level),
		1
	)


static func count_active_summons(pool: Array) -> int:
	var count := 0
	for summon in pool:
		if is_instance_valid(summon) and bool(summon.get("active")):
			count += 1
	return count


static func count_active_regular_summons(
	gatekeeper_pool: Array,
	scout_pool: Array,
	hound_pool: Array,
	watcher_pool: Array
) -> int:
	return (
		count_active_summons(gatekeeper_pool)
		+ count_active_summons(scout_pool)
		+ count_active_summons(hound_pool)
		+ count_active_summons(watcher_pool)
	)


static func get_watcher_max_active(
	watcher_config: Dictionary,
	network_augment_stacks: int
) -> int:
	return maxi(
		int(watcher_config.get("max_active", 2))
		+ network_augment_stacks,
		0
	)


static func get_next_watcher_follow_slot(
	watcher_pool: Array,
	max_active: int
) -> int:
	for slot_index in range(max_active):
		var occupied := false
		for summon in watcher_pool:
			if (
				is_instance_valid(summon)
				and bool(summon.get("active"))
				and int(summon.get("follow_slot")) == slot_index
			):
				occupied = true
				break
		if not occupied:
			return slot_index
	return -1


static func roll_ai_personality(ai_config: Dictionary) -> String:
	var personalities = ai_config.get(
		"personalities",
		["balanced", "aggressive", "defensive", "swarm", "focus"]
	)
	if not personalities is Array or personalities.is_empty():
		return "balanced"
	return String(personalities[randi() % personalities.size()])


static func get_target_hp_ratio(target: Node) -> float:
	if not is_instance_valid(target):
		return 0.0
	var raw_current = target.get("current_hp")
	var raw_max = target.get("max_hp")
	if raw_current == null or raw_max == null:
		return 0.0
	var target_max := maxf(float(raw_max), 1.0)
	return clampf(float(raw_current) / target_max, 0.0, 1.0)


static func score_ai_candidate(
	skill_id: String,
	nearby_count: int,
	hero_hp_ratio: float,
	target_valid: bool,
	target_hp_ratio: float,
	gatekeepers: int,
	scouts: int,
	hounds: int,
	watchers: int,
	total_active: int,
	past_picks: int,
	last_choice: String,
	personality: String,
	random_span: float
) -> float:
	var score := 50.0
	var same_active := 0

	match skill_id:
		"gatekeeper":
			same_active = gatekeepers
			score += (1.0 - hero_hp_ratio) * 32.0
			score += minf(float(nearby_count), 10.0) * 1.8
			score += float(hounds + scouts) * 2.5
		"scout":
			same_active = scouts
			score += minf(float(nearby_count), 12.0) * 2.3
			score += 8.0 if nearby_count >= 5 else 0.0
		"hound":
			same_active = hounds
			score += 20.0 if target_valid and nearby_count <= 4 else 0.0
			score += target_hp_ratio * 18.0
			score -= maxf(float(nearby_count - 6), 0.0) * 2.0
		"watcher":
			same_active = watchers
			score += 22.0 if target_valid else -12.0
			score += target_hp_ratio * 12.0
			score += float(hounds + scouts) * 2.0
		"open_gate":
			score += minf(float(nearby_count), 14.0) * 3.0
			score += (1.0 - hero_hp_ratio) * 12.0
			score += 16.0 if nearby_count >= 8 else 0.0
			score += 10.0 if total_active <= 2 else 0.0

	if skill_id != "open_gate":
		score -= float(same_active) * 11.0

	score += minf(float(past_picks), 6.0) * 1.8
	if last_choice == skill_id:
		score -= 5.0

	match personality:
		"aggressive":
			if skill_id in ["hound", "scout"]:
				score += 10.0
		"defensive":
			if skill_id == "gatekeeper":
				score += 14.0
			elif skill_id == "watcher":
				score += 5.0
		"swarm":
			if skill_id in ["scout", "open_gate"]:
				score += 12.0
		"focus":
			if skill_id in ["watcher", "hound"]:
				score += 12.0
		_:
			pass

	score += randf_range(-maxf(random_span, 0.0), maxf(random_span, 0.0))
	return maxf(score, 1.0)


static func build_augment_ai_settings(
	base_settings: Dictionary,
	choice_counts: Dictionary,
	active_summons: int,
	slot_capacity: int
) -> Dictionary:
	var settings := base_settings.duplicate(true)
	var biases: Dictionary = Dictionary(
		settings.get("augment_biases", {})
	).duplicate(true)
	var families := {
		"gatekeeper": [
			"summoner_gatekeeper_fortress",
			"summoner_gatekeeper_barrage",
		],
		"scout": [
			"summoner_scout_reinforcement",
			"summoner_scout_swarm_tactics",
		],
		"hound": [
			"summoner_hound_frenzy",
			"summoner_hound_blood_track",
		],
		"watcher": [
			"summoner_watcher_focus",
			"summoner_watcher_network",
		],
	}
	var total := 0
	for family_id in families:
		total += int(choice_counts.get(family_id, 0))
	if total > 0:
		for family_id in families:
			var ratio := (
				float(choice_counts.get(family_id, 0))
				/ float(total)
			)
			for augment_id in families[family_id]:
				biases[augment_id] = (
					float(biases.get(augment_id, 0.0))
					+ ratio * 4.0
				)

	var filled_ratio := (
		float(active_summons)
		/ float(maxi(slot_capacity, 1))
	)
	biases["summoner_shield_fortify"] = (
		float(biases.get("summoner_shield_fortify", 0.0))
		+ filled_ratio * 1.4
	)
	biases["summoner_shield_resonance"] = (
		float(biases.get("summoner_shield_resonance", 0.0))
		+ filled_ratio * 1.2
	)
	settings["augment_biases"] = biases
	return settings



static func ensure_pool_capacity(
	world_parent: Node,
	pool: Array,
	scene: PackedScene,
	target_size: int,
	released_callable: Callable,
	prepare_method: StringName = &"",
	prepare_config: Dictionary = {}
) -> void:
	if (
		not is_instance_valid(world_parent)
		or scene == null
		or target_size <= 0
	):
		return

	while pool.size() < target_size:
		var summon := scene.instantiate() as Node2D
		if summon == null:
			break

		world_parent.add_child(summon)
		if (
			summon.has_signal("released")
			and released_callable.is_valid()
			and not summon.is_connected(
				"released",
				released_callable
			)
		):
			summon.connect(
				"released",
				released_callable
			)

		if (
			prepare_method != &""
			and summon.has_method(prepare_method)
		):
			summon.call(
				prepare_method,
				prepare_config
			)

		pool.append(summon)


static func acquire_inactive_summon(pool: Array) -> Node2D:
	for summon in pool:
		if (
			is_instance_valid(summon)
			and not bool(summon.get("active"))
		):
			return summon as Node2D
	return null


static func are_runtime_pools_ready(
	gatekeeper_pool: Array,
	scout_config: Dictionary,
	scout_pool: Array,
	hound_config: Dictionary,
	hound_pool: Array,
	watcher_config: Dictionary,
	watcher_pool: Array,
	open_gate_config: Dictionary,
	open_gate_pool: Array
) -> bool:
	return (
		not gatekeeper_pool.is_empty()
		and (
			scout_config.is_empty()
			or not scout_pool.is_empty()
		)
		and (
			hound_config.is_empty()
			or not hound_pool.is_empty()
		)
		and (
			watcher_config.is_empty()
			or not watcher_pool.is_empty()
		)
		and (
			open_gate_config.is_empty()
			or not open_gate_pool.is_empty()
		)
	)



const PENDING_GATEKEEPER := 1
const PENDING_SCOUT := 2
const PENDING_HOUND := 4
const PENDING_WATCHER := 8


static func activate_summon(
	summon: Node2D,
	spawn_position: Vector2,
	owner_hero: Node,
	runtime_config: Dictionary
) -> bool:
	if (
		not is_instance_valid(summon)
		or summon.is_queued_for_deletion()
		or not summon.has_method("activate")
	):
		return false
	summon.call(
		"activate",
		spawn_position,
		owner_hero,
		runtime_config
	)
	return true


static func get_release_pending_mask(
	gatekeeper_cooldown: float,
	scout_cooldown: float,
	hound_cooldown: float,
	watcher_cooldown: float,
	active_watchers: int,
	max_watchers: int
) -> int:
	var mask := 0
	if gatekeeper_cooldown <= 0.0:
		mask |= PENDING_GATEKEEPER
	if scout_cooldown <= 0.0:
		mask |= PENDING_SCOUT
	if hound_cooldown <= 0.0:
		mask |= PENDING_HOUND
	if (
		watcher_cooldown <= 0.0
		and active_watchers < max_watchers
	):
		mask |= PENDING_WATCHER
	return mask
