extends Node

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const STAGES := preload("res://src/data/stage_catalog.gd")
const TEST_FUNDS := 99999
var active := false
var tutorial_preview := false
var preview_directory := ""
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
		tutorial_preview = bool(config.get_value("mode", "tutorial_preview", false))
		preview_directory = String(config.get_value("mode", "preview_directory", ""))
		normal_guest_directory = String(config.get_value("mode", "normal_guest_directory", "user://"))
		if tutorial_preview and (not preview_directory.begins_with(test_directory + "_tutorial_") or not DirAccess.dir_exists_absolute(preview_directory)):
			tutorial_preview = false # Never recover an invalid marker into the normal save directory.
	if tutorial_preview:
		SCOPE.guest_directory = preview_directory
		SCOPE.select_guest()
	elif active:
		SCOPE.guest_directory = test_directory
		SCOPE.select_guest()

func persist() -> bool:
	var config := ConfigFile.new()
	config.set_value("mode", "active", active)
	config.set_value("mode", "original_user_id", original_user_id)
	config.set_value("mode", "pending_reset_id", pending_reset_id)
	config.set_value("mode", "tutorial_preview", tutorial_preview)
	config.set_value("mode", "preview_directory", preview_directory)
	config.set_value("mode", "normal_guest_directory", normal_guest_directory)
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
	if code not in ["localtest", "normaltest", "tutorialtest"]:
		return false
	var cloud := get_node("/root/CloudStore")
	var gateway := get_node("/root/LoginGateway")
	if cloud.busy or cloud.conflict:
		return false
	if code == "tutorialtest":
		return await _start_tutorial_preview()
	if tutorial_preview:
		if code != "normaltest":
			return false
		tutorial_preview = false
		if not persist():
			tutorial_preview = true
			return false
		# Exit preview without resetting the original guest or social account.
		get_node("/root/TutorialFlow").clear_guide()
		SCOPE.guest_directory = normal_guest_directory
		SCOPE.select_guest()
		gateway.local_guest_active = false
		return true
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

func is_tutorial_preview() -> bool:
	return tutorial_preview and SCOPE.user_id.is_empty() and SCOPE.guest_directory == preview_directory

func _start_tutorial_preview() -> bool:
	if active or not pending_reset_id.is_empty():
		return false # Finish the existing reset workflow first.
	var cloud := get_node("/root/CloudStore")
	var entering_owner := SCOPE.user_id
	var entering_directory := SCOPE.guest_directory
	if not SCOPE.user_id.is_empty() and not await cloud.flush():
		return false
	if entering_owner != SCOPE.user_id or entering_directory != SCOPE.guest_directory:
		return false
	var old_owner := SCOPE.user_id
	var old_directory := SCOPE.guest_directory
	var old_preview := preview_directory
	var was_preview := tutorial_preview
	if not was_preview:
		normal_guest_directory = old_directory
	preview_directory = test_directory + "_tutorial_" + Crypto.new().generate_random_bytes(16).hex_encode()
	if DirAccess.make_dir_recursive_absolute(preview_directory) != OK:
		preview_directory = old_preview
		return false
	SCOPE.guest_directory = preview_directory
	SCOPE.select_guest()
	tutorial_preview = true
	var initialized := reset_progress()
	if initialized:
		initialized = persist()
	if not initialized:
		tutorial_preview = was_preview
		preview_directory = old_preview
		SCOPE.guest_directory = old_directory
		if old_owner.is_empty():
			SCOPE.select_guest()
		else:
			SCOPE.select_account(old_owner)
		return false
	get_node("/root/TutorialFlow").clear_guide()
	get_node("/root/LoginGateway").suspend_for_local_test()
	return true

func tutorial_operation(action: String) -> Dictionary:
	if not is_tutorial_preview() or action not in ["read", "start", "skip", "complete"]:
		return {}
	var progress := ConfigFile.new()
	if SCOPE.load_config(progress, "user://stage_progress.cfg") != OK:
		return {}
	var status := String(progress.get_value("tutorial_preview", "status", "pending"))
	var claimed := bool(progress.get_value("tutorial_preview", "claimed", false))
	if action == "start" and status == "pending":
		status = "active"
	if action in ["skip", "complete"] and not claimed:
		if action == "complete" and status != "active":
			return {}
		status = "completed" if action == "complete" else "skipped"
		claimed = true
		progress.set_value("meta", "gold", int(progress.get_value("meta", "gold", 0)) + preload("res://src/data/tutorial_catalog.gd").REWARD)
	progress.set_value("tutorial_preview", "status", status)
	progress.set_value("tutorial_preview", "claimed", claimed)
	if SCOPE.save_config(progress, "user://stage_progress.cfg") != OK:
		return {}
	return {"ok": true, "status": status, "reward_claimed": claimed}


func has_all_monsters_unlocked() -> bool:
	return (
		active and not tutorial_preview
		and SCOPE.user_id.is_empty()
		and SCOPE.guest_directory == test_directory
	)
