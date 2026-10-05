extends RefCounted

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const STEPS := ["entry", "summon", "augment", "elite", "special", "camera", "shop", "draw_done", "done"]
const PATH := "user://stage_progress.cfg"

static func read() -> String:
	var config := ConfigFile.new()
	if SCOPE.load_config(config, PATH) != OK:
		return ""
	var step := String(config.get_value("tutorial_flow", "step", ""))
	return step if step in STEPS else ""

static func save(step: String) -> bool:
	if step not in STEPS:
		return false
	var config := ConfigFile.new()
	var error := SCOPE.load_config(config, PATH)
	if error not in [OK, ERR_FILE_NOT_FOUND]:
		return false
	config.set_value("tutorial_flow", "version", 2)
	config.set_value("tutorial_flow", "step", step)
	return SCOPE.save_config(config, PATH) == OK
