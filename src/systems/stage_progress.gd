extends RefCounted
class_name StageProgress

const SAVE_PATH := "user://stage_progress.cfg"

static func load_state() -> Dictionary:
	var config := ConfigFile.new()
	var state := {
		"current_stage_id": "stage_1",
		"highest_unlocked_stage": 1,
	}

	var error := config.load(SAVE_PATH)
	if error != OK:
		return state

	state["current_stage_id"] = String(config.get_value("progress", "current_stage_id", "stage_1"))
	state["highest_unlocked_stage"] = int(config.get_value("progress", "highest_unlocked_stage", 1))
	return state

static func set_current_stage(stage_id: String) -> void:
	var state := load_state()
	state["current_stage_id"] = stage_id
	_save_state(state)

static func complete_stage(stage_id: String, stage_number: int, next_stage_id: String, next_stage_number: int) -> void:
	var state := load_state()
	var config := ConfigFile.new()
	config.load(SAVE_PATH)

	config.set_value("cleared", stage_id, true)

	if not next_stage_id.is_empty() and next_stage_number > 0:
		state["highest_unlocked_stage"] = maxi(
			int(state.get("highest_unlocked_stage", 1)),
			next_stage_number
		)

	state["current_stage_id"] = stage_id
	config.set_value("progress", "current_stage_id", String(state["current_stage_id"]))
	config.set_value("progress", "highest_unlocked_stage", int(state["highest_unlocked_stage"]))
	config.save(SAVE_PATH)

static func is_stage_unlocked(stage_number: int) -> bool:
	var state := load_state()
	return stage_number <= int(state.get("highest_unlocked_stage", 1))

static func is_stage_cleared(stage_id: String) -> bool:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return false
	return bool(config.get_value("cleared", stage_id, false))

static func _save_state(state: Dictionary) -> void:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value("progress", "current_stage_id", String(state.get("current_stage_id", "stage_1")))
	config.set_value("progress", "highest_unlocked_stage", int(state.get("highest_unlocked_stage", 1)))
	config.save(SAVE_PATH)
