extends RefCounted
class_name StageProgress
const ACCOUNT_SCOPE := preload("res://src/systems/account_save_scope.gd")

const STAGE_CATALOG := preload("res://src/data/stage_catalog.gd")
const TESTER_UNLOCK_ALL_STAGES := false

const SAVE_PATH := "user://stage_progress.cfg"

static func load_state() -> Dictionary:
	var config := ConfigFile.new()
	var state := {
		"current_stage_id": "stage_1",
		"highest_unlocked_stage": 1,
		"research_points": 0,
	}

	var error := ACCOUNT_SCOPE.load_config(config, SAVE_PATH)
	if error != OK:
		if TESTER_UNLOCK_ALL_STAGES:
			state["highest_unlocked_stage"] = STAGE_CATALOG.get_ordered_stage_ids().size()
		return state

	state["current_stage_id"] = String(
		config.get_value("progress", "current_stage_id", "stage_1")
	)
	state["highest_unlocked_stage"] = int(
		config.get_value("progress", "highest_unlocked_stage", 1)
	)
	state["research_points"] = int(
		config.get_value("meta", "research_points", 0)
	)
	if TESTER_UNLOCK_ALL_STAGES:
		state["highest_unlocked_stage"] = STAGE_CATALOG.get_ordered_stage_ids().size()
	return state

static func set_current_stage(stage_id: String) -> void:
	var state := load_state()
	state["current_stage_id"] = stage_id
	_save_state(state)

static func complete_stage(
	stage_id: String,
	stage_number: int,
	next_stage_id: String,
	next_stage_number: int,
	first_clear_reward: int
) -> Dictionary:
	var state := load_state()
	var config := ConfigFile.new()
	ACCOUNT_SCOPE.load_config(config, SAVE_PATH)

	var was_cleared := bool(config.get_value("cleared", stage_id, false))
	var reward_claimed := bool(config.get_value("reward_claimed", stage_id, false))
	var granted_reward := 0

	config.set_value("cleared", stage_id, true)

	if not reward_claimed and first_clear_reward > 0:
		granted_reward = first_clear_reward
		state["research_points"] = int(state.get("research_points", 0)) + granted_reward
		config.set_value("reward_claimed", stage_id, true)

	if not next_stage_id.is_empty() and next_stage_number > 0:
		state["highest_unlocked_stage"] = maxi(
			int(state.get("highest_unlocked_stage", 1)),
			next_stage_number
		)

	state["current_stage_id"] = stage_id
	config.set_value(
		"progress",
		"current_stage_id",
		String(state["current_stage_id"])
	)
	config.set_value(
		"progress",
		"highest_unlocked_stage",
		int(state["highest_unlocked_stage"])
	)
	config.set_value(
		"meta",
		"research_points",
		int(state.get("research_points", 0))
	)
	ACCOUNT_SCOPE.save_config(config, SAVE_PATH)

	return {
		"was_cleared": was_cleared,
		"first_clear": not was_cleared,
		"reward": granted_reward,
		"research_points": int(state.get("research_points", 0)),
		"highest_unlocked_stage": int(state.get("highest_unlocked_stage", 1)),
	}

static func is_stage_unlocked(stage_number: int) -> bool:
	if TESTER_UNLOCK_ALL_STAGES:
		return true
	var state := load_state()
	return stage_number <= int(state.get("highest_unlocked_stage", 1))

static func get_gold() -> int:
	var config := ConfigFile.new()
	ACCOUNT_SCOPE.load_config(config, SAVE_PATH)
	return maxi(int(config.get_value("meta", "gold", 0)), 0)

static func is_stage_cleared(stage_id: String) -> bool:
	var config := ConfigFile.new()
	if ACCOUNT_SCOPE.load_config(config, SAVE_PATH) != OK:
		return false
	return bool(config.get_value("cleared", stage_id, false))

static func is_reward_claimed(stage_id: String) -> bool:
	var config := ConfigFile.new()
	if ACCOUNT_SCOPE.load_config(config, SAVE_PATH) != OK:
		return false
	return bool(config.get_value("reward_claimed", stage_id, false))


static func has_seen_stage_intro(stage_id: String) -> bool:
	if stage_id.is_empty():
		return false
	var config := ConfigFile.new()
	if ACCOUNT_SCOPE.load_config(config, SAVE_PATH) != OK:
		return false
	return bool(config.get_value("intro_seen", stage_id, false))


static func mark_stage_intro_seen(stage_id: String) -> bool:
	if stage_id.is_empty():
		return false
	var config := ConfigFile.new()
	ACCOUNT_SCOPE.load_config(config, SAVE_PATH)
	config.set_value("intro_seen", stage_id, true)
	return ACCOUNT_SCOPE.save_config(config, SAVE_PATH) == OK


static func record_hero_encounter(
	stage_id: String,
	identity_id: String
) -> Dictionary:
	if stage_id.is_empty() or identity_id.is_empty():
		return {
			"stage_encounters": 0,
			"unique_stage_encounters": 0,
			"true_name_unlocked": false,
		}

	var config := ConfigFile.new()
	ACCOUNT_SCOPE.load_config(config, SAVE_PATH)

	var stage_count := int(
		config.get_value("hero_stage_encounters", stage_id, 0)
	) + 1
	config.set_value("hero_stage_encounters", stage_id, stage_count)

	var raw_stages = config.get_value(
		"hero_identity_stages",
		identity_id,
		PackedStringArray()
	)
	var stages := PackedStringArray()
	if raw_stages is PackedStringArray:
		stages = raw_stages
	elif raw_stages is Array:
		for raw_stage in raw_stages:
			stages.append(String(raw_stage))

	if stage_id not in stages:
		stages.append(stage_id)
	config.set_value("hero_identity_stages", identity_id, Array(stages))
	ACCOUNT_SCOPE.save_config(config, SAVE_PATH)

	return {
		"stage_encounters": stage_count,
		"unique_stage_encounters": stages.size(),
		"true_name_unlocked": stage_count >= 100 or stages.size() >= 3,
	}


static func reveal_hero_true_name(identity_id: String) -> bool:
	if identity_id.is_empty():
		return false
	var config := ConfigFile.new()
	ACCOUNT_SCOPE.load_config(config, SAVE_PATH)
	config.set_value("hero_true_names", identity_id, true)
	return ACCOUNT_SCOPE.save_config(config, SAVE_PATH) == OK


static func is_hero_true_name_unlocked(
	stage_id: String,
	identity_id: String
) -> bool:
	if identity_id.is_empty():
		return false
	var config := ConfigFile.new()
	if ACCOUNT_SCOPE.load_config(config, SAVE_PATH) != OK:
		return false

	if bool(config.get_value("hero_true_names", identity_id, false)):
		return true
	if identity_id == "returning_magic_hero":
		return false
	if stage_id.is_empty():
		return false

	var stage_count := int(
		config.get_value("hero_stage_encounters", stage_id, 0)
	)
	var raw_stages = config.get_value(
		"hero_identity_stages",
		identity_id,
		PackedStringArray()
	)
	var unique_count := 0
	if raw_stages is PackedStringArray or raw_stages is Array:
		unique_count = raw_stages.size()

	return stage_count >= 100 or unique_count >= 3


static func get_research_points() -> int:
	var state := load_state()
	return int(state.get("research_points", 0))

static func add_research_points(amount: int, gold_amount: int = 0) -> Dictionary:
	if amount <= 0 or gold_amount < 0:
		return {
			"success": false,
			"granted": 0,
			"research_points": get_research_points(),
		}

	var config := ConfigFile.new()
	ACCOUNT_SCOPE.load_config(config, SAVE_PATH)

	var state := load_state()
	var research_points := int(state.get("research_points", 0)) + amount
	config.set_value(
		"progress",
		"current_stage_id",
		String(state.get("current_stage_id", "stage_1"))
	)
	config.set_value(
		"progress",
		"highest_unlocked_stage",
		int(state.get("highest_unlocked_stage", 1))
	)
	config.set_value("meta", "research_points", research_points)
	if gold_amount > 0:
		config.set_value("meta", "gold", maxi(int(config.get_value("meta", "gold", 0)), 0) + gold_amount)
	var save_error := ACCOUNT_SCOPE.save_config(config, SAVE_PATH)

	return {
		"success": save_error == OK,
		"granted": amount if save_error == OK else 0,
		"gold_granted": gold_amount if save_error == OK else 0,
		"research_points": (
			research_points
			if save_error == OK
			else int(state.get("research_points", 0))
		),
	}

static func try_spend_research_points(cost: int) -> Dictionary:
	if cost < 0:
		return {
			"success": false,
			"reason": "invalid",
			"research_points": get_research_points(),
		}

	var config := ConfigFile.new()
	ACCOUNT_SCOPE.load_config(config, SAVE_PATH)

	var state := load_state()
	var research_points := int(state.get("research_points", 0))
	if research_points < cost:
		return {
			"success": false,
			"reason": "not_enough_points",
			"research_points": research_points,
		}

	research_points -= cost
	config.set_value(
		"progress",
		"current_stage_id",
		String(state.get("current_stage_id", "stage_1"))
	)
	config.set_value(
		"progress",
		"highest_unlocked_stage",
		int(state.get("highest_unlocked_stage", 1))
	)
	config.set_value("meta", "research_points", research_points)
	var save_error := ACCOUNT_SCOPE.save_config(config, SAVE_PATH)

	return {
		"success": save_error == OK,
		"reason": "spent" if save_error == OK else "save_failed",
		"research_points": (
			research_points
			if save_error == OK
			else int(state.get("research_points", 0))
		),
	}


static func get_research_level(research_id: String) -> int:
	var config := ConfigFile.new()
	if ACCOUNT_SCOPE.load_config(config, SAVE_PATH) != OK:
		return 0
	return int(config.get_value("research", research_id, 0))

static func get_research_levels(research_ids: Array[String]) -> Dictionary:
	var levels := {}
	for research_id in research_ids:
		levels[research_id] = get_research_level(research_id)
	return levels

static func try_purchase_research(
	research_id: String,
	cost: int,
	max_level: int
) -> Dictionary:
	if research_id.is_empty() or cost < 0 or max_level <= 0:
		return {
			"success": false,
			"reason": "invalid",
			"level": 0,
			"research_points": get_research_points(),
		}

	var config := ConfigFile.new()
	ACCOUNT_SCOPE.load_config(config, SAVE_PATH)

	var current_level := int(config.get_value("research", research_id, 0))
	var research_points := int(config.get_value("meta", "research_points", 0))

	if current_level >= max_level:
		return {
			"success": false,
			"reason": "max_level",
			"level": current_level,
			"research_points": research_points,
		}

	if research_points < cost:
		return {
			"success": false,
			"reason": "not_enough_points",
			"level": current_level,
			"research_points": research_points,
		}

	current_level += 1
	research_points -= cost

	config.set_value("research", research_id, current_level)
	config.set_value("meta", "research_points", research_points)
	ACCOUNT_SCOPE.save_config(config, SAVE_PATH)

	return {
		"success": true,
		"reason": "purchased",
		"level": current_level,
		"research_points": research_points,
	}

static func _save_state(state: Dictionary) -> void:
	var config := ConfigFile.new()
	ACCOUNT_SCOPE.load_config(config, SAVE_PATH)
	config.set_value(
		"progress",
		"current_stage_id",
		String(state.get("current_stage_id", "stage_1"))
	)
	config.set_value(
		"progress",
		"highest_unlocked_stage",
		int(state.get("highest_unlocked_stage", 1))
	)
	config.set_value(
		"meta",
		"research_points",
		int(state.get("research_points", 0))
	)
	ACCOUNT_SCOPE.save_config(config, SAVE_PATH)
