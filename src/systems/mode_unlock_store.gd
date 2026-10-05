extends RefCounted

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const PROGRESS := preload("res://src/systems/stage_progress.gd")
const DATA := preload("res://src/data/mode_unlock_catalog.gd")

static func is_test_override() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	return tree != null and bool(tree.root.get_node("LocalTestMode").active)

static func unlocked(mode: String, stage_id: String) -> bool:
	if not DATA.RULES.has(mode):
		return false
	if is_test_override():
		return true
	var required := String(DATA.RULES[mode].required_stage)
	# All existing cleared entries were earned on the only playable mode: easy.
	# Merely unlocking/browsing Stage 10 is not a Stage 10 clear.
	return PROGRESS.is_stage_cleared(stage_id if required.is_empty() else required)

static func announcement_seen(mode: String, stage_id: String) -> bool:
	var config := ConfigFile.new()
	SCOPE.load_config(config, PROGRESS.SAVE_PATH)
	return bool(config.get_value("mode_unlock_seen", DATA.announcement_key(mode, stage_id), false))

static func mark_announced(mode: String, stage_id: String) -> bool:
	if not unlocked(mode, stage_id):
		return false
	var config := ConfigFile.new()
	if SCOPE.load_config(config, PROGRESS.SAVE_PATH) != OK:
		return false
	config.set_value("mode_unlock_seen", DATA.announcement_key(mode, stage_id), true)
	return SCOPE.save_config(config, PROGRESS.SAVE_PATH) == OK
