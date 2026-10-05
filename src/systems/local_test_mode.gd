extends Node

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const STAGES := preload("res://src/data/stage_catalog.gd")
const TEST_FUNDS := 99999
var active := false
var pending_reset_id := ""
var original_user_id := ""
var normal_guest_directory := "user://"
var marker_path := "user://local_test_mode.cfg"
var test_directory := "user://local_test"

func _ready() -> void:
	var config := ConfigFile.new()
	if config.load(marker_path) == OK:
		active = bool(config.get_value("mode", "active", false))
		original_user_id = String(config.get_value("mode", "original_user_id", ""))
		pending_reset_id = String(config.get_value("mode", "pending_reset_id", ""))
	if active:
		SCOPE.guest_directory = test_directory
		SCOPE.select_guest()

func persist() -> bool:
	var config := ConfigFile.new()
	config.set_value("mode", "active", active)
	config.set_value("mode", "original_user_id", original_user_id)
	config.set_value("mode", "pending_reset_id", pending_reset_id)
	return config.save(marker_path) == OK

func reset_progress(test: bool = false) -> bool:
	# One account bundle/guest journal commit, never a partial collection reset.
	var configs := {}
	for name in SCOPE.FILES:
		configs[name] = ConfigFile.new()
	var progress: ConfigFile = configs["stage_progress.cfg"]
	progress.set_value("progress", "current_stage_id", "stage_1")
	progress.set_value("progress", "highest_unlocked_stage", STAGES.get_ordered_stage_ids().size() if test else 1)
	progress.set_value("meta", "research_points", TEST_FUNDS if test else 0)
	progress.set_value("meta", "gold", TEST_FUNDS if test else 0)
	return SCOPE.save_configs(configs) == OK

func apply_coupon(code: String) -> bool:
	if code not in ["localtest", "normaltest"]:
		return false
	var cloud := get_node("/root/CloudStore")
	var gateway := get_node("/root/LoginGateway")
	if cloud.busy or cloud.conflict:
		return false
	if code == "localtest":
		if active:
			return true
		if not SCOPE.user_id.is_empty() and not await cloud.flush():
			return false
		original_user_id = SCOPE.user_id
		normal_guest_directory = SCOPE.guest_directory
		if DirAccess.make_dir_recursive_absolute(test_directory) != OK:
			return false
		cloud.stop()
		SCOPE.guest_directory = test_directory
		SCOPE.select_guest()
		if not reset_progress(true):
			SCOPE.guest_directory = normal_guest_directory
			if original_user_id.is_empty():
				SCOPE.select_guest()
			else:
				SCOPE.select_account(original_user_id)
			return false
		active = true
		if not persist():
			active = false
			SCOPE.guest_directory = normal_guest_directory
			if not original_user_id.is_empty():
				SCOPE.select_account(original_user_id)
			else:
				SCOPE.select_guest()
			return false
		gateway.suspend_for_local_test()
		return true
	if not active:
		if not reset_progress():
			return false
		return SCOPE.user_id.is_empty() or await cloud.flush()
	# Discard test progress, then reset the authenticated normal account only
	# after its saved identity is validated again; never upload test files.
	if not reset_progress():
		return false
	active = false
	pending_reset_id = original_user_id
	if not persist():
		active = true
		return false
	SCOPE.guest_directory = normal_guest_directory
	SCOPE.select_guest()
	if pending_reset_id.is_empty() and not reset_progress():
		return false
	gateway.local_guest_active = false
	return true
