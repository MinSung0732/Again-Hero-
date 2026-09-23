extends RefCounted
class_name StageProgress

const STAGE_CATALOG := preload("res://src/data/stage_catalog.gd")
const TESTER_UNLOCK_ALL_STAGES := true

const SAVE_PATH := "user://stage_progress.cfg"

static func load_state() -> Dictionary:
	var config := ConfigFile.new()
	var state := {
		"current_stage_id": "stage_1",
		"highest_unlocked_stage": 1,
		"research_points": 0,
	}

	var error := config.load(SAVE_PATH)
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
	config.load(SAVE_PATH)

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
	config.save(SAVE_PATH)

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

static func is_stage_cleared(stage_id: String) -> bool:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return false
	return bool(config.get_value("cleared", stage_id, false))

static func is_reward_claimed(stage_id: String) -> bool:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return false
	return bool(config.get_value("reward_claimed", stage_id, false))

static func get_research_points() -> int:
	var state := load_state()
	return int(state.get("research_points", 0))

static func add_research_points(amount: int) -> Dictionary:
	if amount <= 0:
		return {
			"success": false,
			"granted": 0,
			"research_points": get_research_points(),
		}

	var config := ConfigFile.new()
	config.load(SAVE_PATH)

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
	var save_error := config.save(SAVE_PATH)

	return {
		"success": save_error == OK,
		"granted": amount if save_error == OK else 0,
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
	config.load(SAVE_PATH)

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
	var save_error := config.save(SAVE_PATH)

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
	if config.load(SAVE_PATH) != OK:
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
	config.load(SAVE_PATH)

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
	config.save(SAVE_PATH)

	return {
		"success": true,
		"reason": "purchased",
		"level": current_level,
		"research_points": research_points,
	}

static func _save_state(state: Dictionary) -> void:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
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
	config.save(SAVE_PATH)
