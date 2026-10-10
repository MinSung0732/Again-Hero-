extends SceneTree

const STORE := preload("res://src/systems/exploration_reward_store.gd")
const RULES := preload("res://src/data/exploration_reward_catalog.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const SERVICE := preload("res://src/systems/exploration_rewards.gd")
const TRAYS := preload("res://src/ui/lobby_tool_trays.gd")
const VIEW := preload("res://src/ui/lobby_exploration_rewards_view.gd")
var failures := 0
var folder := ""
var account_folder := ""

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("EXPLORATION_TEST: " + message)

func write_state(seconds: int, anchor: int, gold: int = 10, research: int = 20) -> void:
	var config := ConfigFile.new()
	config.set_value(STORE.SECTION, "seconds", seconds)
	config.set_value(STORE.SECTION, "anchor", anchor)
	config.set_value("meta", "gold", gold)
	config.set_value("meta", "research_points", research)
	config.set_value("stamina", "amount", 17)
	config.set_value("cleared", "stage_1", true)
	check(SCOPE.save_config(config, STORE.SAVE_PATH) == OK, "seed persisted")

func config() -> ConfigFile:
	var result := ConfigFile.new()
	check(SCOPE.load_config(result, STORE.SAVE_PATH) == OK, "read config")
	return result

func run() -> void:
	root.size = Vector2i(1080, 1920)
	folder = "user://exploration_test_" + Crypto.new().generate_random_bytes(8).hex_encode()
	DirAccess.make_dir_recursive_absolute(folder)
	SCOPE.select_guest()
	SCOPE.guest_directory = folder
	check(STORE.checkpoint(true, 1000) == OK, "first launch initializes")
	check(STORE.snapshot().seconds == 0, "new install gets no retroactive reward")
	check(STORE.checkpoint(false, 2000) == OK, "foreground checkpoint")
	check(STORE.snapshot().seconds == 0, "foreground never earns")
	check(STORE.checkpoint(true, 3800) == OK, "offline interval")
	check(STORE.snapshot().percent == 10, "180 seconds per percent")
	check(STORE.checkpoint(true, 3800) == OK and STORE.snapshot().percent == 10, "same resume cannot double count")
	write_state(9000, 1000)
	check(not STORE.snapshot().can_claim, "exact 50 percent disabled")
	check(not STORE.claim(1000).success, "threshold cannot be bypassed")
	write_state(9179, 1000)
	check(not STORE.snapshot().can_claim, "partial 51 percent still disabled")
	write_state(9180, 1000)
	var result := STORE.claim(1000)
	check(result.success and result.gold == 102 and result.research == 51, "51 percent payout")
	var saved := config()
	check(saved.get_value("meta", "gold") == 112 and saved.get_value("meta", "research_points") == 71, "wallet awarded together")
	check(saved.get_value("stamina", "amount") == 17 and saved.get_value("cleared", "stage_1"), "unrelated progress retained")
	check(STORE.snapshot().seconds == 0 and not STORE.claim(1000).success, "claimed time consumed, repeat blocked")
	write_state(0, 1000)
	STORE.checkpoint(true, 999999999)
	check(STORE.snapshot().percent == 300 and STORE.snapshot().gold == 600 and STORE.snapshot().research == 300, "long absence capped in O(1)")
	STORE.checkpoint(true, 1100)
	check(config().get_value(STORE.SECTION, "anchor") == 999999999, "backward clock cannot reopen interval")
	# Account bundle rollback: a directory blocks only the temporary save path.
	var raw := Crypto.new().generate_random_bytes(16).hex_encode()
	var id := "%s-%s-%s-%s-%s" % [raw.substr(0, 8), raw.substr(8, 4), raw.substr(12, 4), raw.substr(16, 4), raw.substr(20, 12)]
	check(SCOPE.select_account(id), "isolated account selected")
	account_folder = "user://accounts/" + id
	write_state(54000, 1000)
	DirAccess.make_dir_absolute(account_folder.path_join("save_bundle.json.tmp"))
	check(not STORE.claim(1000).success, "save failure refuses payout")
	check(STORE.snapshot().full and config().get_value("meta", "gold") == 10, "save failure keeps bank and currency")
	DirAccess.remove_absolute(account_folder.path_join("save_bundle.json.tmp"))
	check(STORE.claim(1000).success, "retry succeeds once storage recovers")
	SCOPE.select_guest()
	check(STORE.snapshot().full, "guest accumulation isolated from account claim")
	write_state(0, int(Time.get_unix_time_from_system()))
	var service := SERVICE.new()
	root.add_child(service)
	await process_frame
	service._sync_session()
	var now := int(Time.get_unix_time_from_system())
	write_state(0, now - 1800)
	service._heartbeat()
	check(STORE.snapshot().seconds == 0, "heartbeat excludes online time")
	service._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	write_state(0, now - 1800)
	service._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(config().get_value(STORE.SECTION, "anchor") == now - 1800, "duplicate pause keeps original anchor")
	service._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	check(STORE.snapshot().seconds == 0, "focus in while paused does not resume")
	service._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	check(STORE.snapshot().percent == 10, "resume credits absence once")
	service._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	check(STORE.snapshot().percent == 10, "duplicate resume ignored")
	write_state(1800, now - 8000)
	var before := SCOPE.serial
	SCOPE.revision += 1
	service._sync_session()
	check(SCOPE.serial == before, "revision acknowledgement causes no cloud save loop")
	check(config().get_value(STORE.SECTION, "anchor") == now - 8000, "revision acknowledgement is read-only")
	STORE.checkpoint(false)
	var host := Control.new()
	host.size = Vector2(1080, 1400)
	root.add_child(host)
	var trays := TRAYS.new()
	trays.install(host, func(): return true)
	var view := VIEW.new()
	view.install(host, trays, service, Callable())
	await process_frame
	check(trays._rails[&"left"].get_child_count() == 3, "chest visible below two tools")
	trays.set_notification(&"daily", true)
	check(trays._badges[&"daily"][0].get_ref().visible, "mission notification on")
	trays.set_notification(&"daily", false)
	check(not trays._badges[&"daily"][0].get_ref().visible, "mission notification clears")
	write_state(53820, now)
	view.refresh()
	check(not trays._badges[&"exploration"][0].get_ref().visible, "chest 299 percent has no notification")
	write_state(54000, now)
	view.open()
	await process_frame
	check(trays._badges[&"exploration"][0].get_ref().visible, "chest 300 percent notification on")
	var font_manager := root.get_node_or_null("GameFontManager")
	check(font_manager != null and view._percent.get_theme_font("font").resource_path == "res://assets/fonts/Galmuri11.ttf", "regression uses actual game font")
	# Container minimum sizes settle after deferred sorting/font assignment.
	# Containment alone misses a panel that grew taller than the whole screen.
	for i in range(20):
		await process_frame
	check(view._panel.size.is_equal_approx(VIEW.DESIGN_SIZE), "panel retains design size after deferred font/container layout")
	check(Rect2(Vector2.ZERO, view._overlay.size).encloses(view._panel.get_global_rect()), "whole panel fits viewport after settling")
	check(view._panel.get_global_rect().get_center().distance_to(view._overlay.size * 0.5) < 1.0, "settled panel centered")
	check(view._panel.get_global_rect().encloses(view._claim.get_global_rect()), "claim button remains inside popup")
	check(view._percent.text == "300% / 300%" and view._elapsed.text.contains("15:00:00"), "popup gauge and HH:MM:SS")
	check(view._gold.text == "+600" and view._research.text == "+300", "reward amounts under icons")
	check(not view._claim.disabled and view.blocks_stage_input(), "claim enabled and stage swipe blocked")
	view._claim_reward()
	check(not trays._badges[&"exploration"][0].get_ref().visible, "claim clears full notification immediately")
	check(view._claim.disabled and view._gauge.value == 0, "popup resets after claim")
	for i in range(20):
		await process_frame
	check(view._panel.size.is_equal_approx(VIEW.DESIGN_SIZE), "claim status does not inflate panel")
	root.size = Vector2i(540, 960)
	view.open()
	await process_frame
	for i in range(20):
		await process_frame
	check(view._panel.size.is_equal_approx(VIEW.DESIGN_SIZE), "small-window layout does not grow panel")
	check(view._panel.get_global_rect().size.x <= 477 and view._panel.get_global_rect().size.y <= 897, "popup fits smaller PC window")
	check(view._panel.get_global_rect().encloses(view._claim.get_global_rect()), "scaled popup retains claim button")
	var rect: Rect2 = view._panel.get_global_rect()
	check(rect.size.x > rect.size.y, "popup is landscape")
	check(rect.get_center().distance_to(view._overlay.size * 0.5) < 1.0, "popup fixed at viewport center")
	check(view._panel.get_global_rect().encloses(view._research.get_global_rect()), "research amount stays inside popup")
	for control in [view._gauge, view._percent, view._elapsed, view._gold, view._research, view._status, view._claim]:
		check(view._panel.get_global_rect().encloses(control.get_global_rect()), "all reward fields fit inside panel")
	var position: Vector2 = view._panel.position
	var drag := InputEventMouseMotion.new()
	drag.relative = Vector2(100, 100)
	view._input(drag)
	check(view._panel.position == position, "mouse motion cannot drag popup")
	var cancel := InputEventAction.new()
	cancel.action = &"ui_cancel"
	cancel.pressed = true
	view._input(cancel)
	check(not view._overlay.visible, "escape closes canvas modal")
	view.open()
	host.hide()
	check(not view._overlay.visible, "tab change closes popup")
	# Hidden tools still forward completion notifications to the More button.
	var extra: Array = []
	for i in range(20):
		extra.append({"id": StringName("extra%d" % i), "title": "도구", "side": &"left"})
	var large := TRAYS.new()
	large.install(host, func(): return true, extra)
	large.set_notification(&"extra19", true)
	check(large._rails[&"left"].get_node("MoreTools/NotificationDot").visible, "hidden tool notification reaches more")
	large.set_notification(&"extra19", false)
	check(not large._rails[&"left"].get_node("MoreTools/NotificationDot").visible, "more notification clears")
	host.free()
	service.free()
	SCOPE.select_guest()
	for file in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(file))
	DirAccess.remove_absolute(folder)
	for file in DirAccess.get_files_at(account_folder):
		DirAccess.remove_absolute(account_folder.path_join(file))
	DirAccess.remove_absolute(account_folder)
	SCOPE.guest_directory = "user://"
	print("EXPLORATION_REWARDS_OK" if failures == 0 else "EXPLORATION_REWARDS_FAILED: %d" % failures)
	quit(0 if failures == 0 else 1)
