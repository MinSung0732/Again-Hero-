extends SceneTree

const STORE := preload("res://src/systems/stamina_store.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const PROGRESS := preload("res://src/systems/stage_progress.gd")
var failed := false
const T := 1000000
var folder := ""

class DeferredTransition extends Node:
	var requests := 0
	func is_transitioning() -> bool:
		return false
	func change_scene(_path: String, _message: String) -> bool:
		requests += 1
		return true

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failed = true
		push_error("STAMINA_TEST: " + message)

func seed_wallet(amount: int, anchor: int) -> void:
	var config := ConfigFile.new()
	SCOPE.load_config(config, "user://stage_progress.cfg")
	config.set_value("progress", "current_stage_id", "stage_1")
	config.set_value("stamina", "amount", amount)
	config.set_value("stamina", "recovery_at", anchor)
	config.set_value("meta", "gold", 1000)
	config.set_value("meta", "research_points", 73)
	config.set_value("cleared", "stage_1", true)
	check(SCOPE.save_configs({"stage_progress.cfg": config}) == OK, "seed saved")
	STORE.invalidate()

func settle() -> void:
	await process_frame
	await process_frame
	await process_frame

func capture(name: String) -> void:
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/commerce-" + name + ".png")

func run() -> void:
	root.get_node("CloudStore").stop()
	root.get_node("LoginGateway").remember_session_enabled = false
	var mode := root.get_node("LocalTestMode")
	mode.active = false
	mode.tutorial_preview = false
	mode.pending_reset_id = ""
	folder = "user://stamina_test_" + Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(folder)
	SCOPE.guest_directory = folder
	SCOPE.select_guest()
	check(STORE.read_state(T).amount == 30, "new and legacy saves start full")
	check(STORE.resolve(23, T, T+3599).amount == 23 and STORE.resolve(23,T,T+3599).next_seconds == 1, "one hour boundary")
	check(STORE.resolve(23,T,T+3600).amount == 24, "one hourly recovery")
	check(STORE.resolve(23,T,T+7201).amount == 25 and STORE.resolve(23,T,T+7201).next_seconds == 3599, "offline ticks retain remainder")
	check(STORE.resolve(23,T,T+10000000).amount == 30, "natural cap offline")
	check(STORE.resolve(60,T,T+10000000).amount == 60, "overflow neither clipped nor regenerated")
	check(STORE.resolve(23,T,T-3600).amount == 23 and STORE.resolve(23,T,T-3600).next_seconds == 7200, "clock rollback gives no extra recharge")
	seed_wallet(30,T)
	var entry := STORE.try_enter("stage_2", false, T+40000)
	check(entry.success and STORE.read_state(T+40000).amount == 25, "one full entry costs five")
	check(STORE.read_state(T+40001).next_seconds == 3599, "full time never banked")
	check(PROGRESS.load_state().current_stage_id == "stage_2", "stage and debit committed together")
	check(PROGRESS.get_gold() == 1000 and PROGRESS.get_research_points() == 73 and PROGRESS.is_stage_cleared("stage_1"), "other progression preserved")
	check(STORE.refund_failed_entry(entry,T+40001) and STORE.read_state(T+40001).amount == 30, "failed scene refunds once")
	check(STORE.refund_failed_entry(entry,T+40001) and STORE.read_state(T+40001).amount == 30, "refund retry idempotent")
	seed_wallet(10,T)
	check(STORE.try_enter("stage_1",false,T+1200).success and STORE.read_state(T+1200).next_seconds == 2400, "partial timer survives spending")
	seed_wallet(4,T)
	check(not STORE.try_enter("stage_2",false,T+1).success and STORE.read_state(T+1).amount == 4, "insufficient blocks charge and entry")
	check(STORE.try_enter("stage_1",true,T+1).success and STORE.read_state(T+1).amount == 4, "practice exemption")
	seed_wallet(5,T)
	check(STORE.try_enter("stage_1",false,T+1).success and STORE.read_state(T+1).amount == 0, "exact cost allowed")
	seed_wallet(29,T)
	check(STORE.grant(20,"gift:test",T+60).success and STORE.read_state(T+60).amount == 49, "gift exceeds natural cap")
	check(STORE.grant(20,"gift:test",T+60).granted == 0 and STORE.read_state(T+60).amount == 49, "reward receipt dedupe")
	check(STORE.grant(5,"purchase:test",T+60).success and STORE.read_state(T+60).amount == 54, "purchase hook exceeds cap")
	for i in 4:
		check(STORE.try_enter("stage_1",false,T+40000+i).success, "overflow spend")
	check(STORE.read_state(T+40004).amount == 34, "overflow is spendable without regen")
	check(STORE.try_enter("stage_1",false,T+40004).success and STORE.read_state(T+40004).amount == 29, "cross below cap")
	check(STORE.read_state(T+40004).next_seconds == 3600, "cross below cap starts fresh timer")
	STORE.invalidate()
	check(STORE.read_state(T+43604).amount == 30, "reload recovers from persisted anchor")
	# A paid ticket is bound to exactly one destination battle. Real elapsed time
	# includes pauses; full-load refunds and partial exits share one receipt.
	for elapsed in [29999, 30000, 30001]:
		seed_wallet(30,T)
		STORE.try_enter("stage_1",false,T)
		var ticket := STORE.claim_battle_entry("stage_1")
		check(not ticket.is_empty() and STORE.claim_battle_entry("stage_1").is_empty(), "battle claims ticket once")
		var result := STORE.refund_early_exit(ticket,elapsed,T+31)
		var expected := 4 if elapsed <= 30000 else 0
		check(result.success and result.refunded == expected and STORE.read_state(T+31).amount == 25+expected, "30 second refund boundary")
		check(STORE.refund_early_exit(ticket,elapsed,T+31).refunded == 0, "exit refund retry deduped")
	seed_wallet(30,T)
	STORE.try_enter("stage_1",true,T)
	check(STORE.refund_early_exit(STORE.claim_battle_entry("stage_1"),1000,T).refunded == 0, "free practice cannot claim refund")
	seed_wallet(30,T)
	STORE.try_enter("stage_1",false,T)
	var old_ticket := STORE.claim_battle_entry("stage_1")
	STORE.try_enter("stage_2",false,T)
	check(STORE.refund_early_exit(old_ticket,1000,T).refunded == 0, "stale battle cannot refund new run")
	var original := SCOPE.guest_directory
	SCOPE.guest_directory = folder.path_join("missing")
	check(not STORE.try_enter("stage_2",false,T).success, "disk error denies battle")
	SCOPE.guest_directory = original
	STORE.invalidate()
	var hex := Crypto.new().generate_random_bytes(16).hex_encode()
	var id := "%s-%s-%s-%s-%s" % [hex.substr(0,8),hex.substr(8,4),hex.substr(12,4),hex.substr(16,4),hex.substr(20,12)]
	check(SCOPE.select_account(id), "isolated account")
	check(STORE.read_state(T).amount == 30, "account cannot inherit guest wallet")
	check(STORE.try_enter("stage_1",false,T).success, "account debit")
	var snapshot := SCOPE.files.duplicate(true)
	check(SCOPE.valid_payload(snapshot) and snapshot["stage_progress.cfg"]["stamina"]["amount"] == 25, "existing cloud snapshot includes stamina")
	check(STORE.grant(20,"cloud:gift",T).success, "account credit")
	check(SCOPE.install(snapshot, 9) and STORE.read_state(T).amount == 25, "remote replacement invalidates wallet cache")
	SCOPE.select_guest()
	seed_wallet(4,int(Time.get_unix_time_from_system()))
	root.size = Vector2i(540,960)
	root.content_scale_size = Vector2i(1080,1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	await root.get_node("PresentationWarmup").prepare_scene("res://src/lobby/Lobby.tscn")
	var lobby = load("res://src/lobby/Lobby.tscn").instantiate()
	lobby.gameplay_settings_path = folder.path_join("gameplay.cfg")
	root.add_child(lobby)
	current_scene = lobby
	await settle()
	await capture("main")
	var slots: Control = lobby.get_node("SafeArea/Layout/Header/HeaderSlots")
	var previous_end := 0.0
	for name in ["HeaderGoldPlate","HeaderStaminaPlate","HeaderProgressPlate"]:
		var rect := (slots.get_node(name) as Control).get_global_rect()
		check(rect.position.x >= previous_end and rect.end.x <= slots.get_global_rect().end.x+1, "header slots do not overlap")
		previous_end = rect.end.x
	check(lobby.get_node("SafeArea/Layout/Header").custom_minimum_size.y == 244, "header uses readable second row")
	check(lobby.shop_package_grid.columns == 2, "packages use readable two columns")
	check((slots.get_node("HeaderStaminaPlate") as Panel).get_theme_stylebox("panel").texture != null, "new header frame loads")
	check(lobby.enter_stage_button.text.is_empty() and lobby.stamina_view._entry_title.text == "던전 입장" and lobby.stamina_view._entry_amount.text == "-5", "entry shows one combined label without duplicate button text")
	var entry_rect: Rect2 = lobby.enter_stage_button.get_global_rect()
	var content_rect: Rect2 = lobby.stamina_view._entry_cost.get_global_rect()
	check(content_rect.get_center().distance_to(entry_rect.get_center()) < 2.0 and entry_rect.encloses(content_rect), "entire entry label is centered and fits inside button")
	for child in lobby.stamina_view._entry_cost.get_children():
		check(child.mouse_filter == Control.MOUSE_FILTER_IGNORE, "entry label and cost share original button hit area")
	check(lobby.stamina_view._entry_center.mouse_filter == Control.MOUSE_FILTER_IGNORE, "centering container passes touches to entry button")
	await lobby.stamina_view.play_entry_cost(0)
	check(not lobby.stamina_view._entry_center.visible and not lobby.stamina_view._spend_label.visible, "free entry clears combined row for native loading status")
	lobby.enter_stage_button.text = "스테이지 잠김"
	lobby.stamina_view.configure_entry(false, 5)
	check(not lobby.stamina_view._entry_center.visible and lobby.enter_stage_button.text == "스테이지 잠김", "locked status remains native and unobscured")
	lobby._refresh_stage_card()
	await settle()
	lobby.stamina_view._info_button.mouse_entered.emit()
	await settle()
	check(lobby.stamina_view.overlay.visible and not lobby.stamina_view._info_pinned, "desktop hover shows unpinned information")
	var info_rect: Rect2 = lobby.stamina_view.overlay.get_global_rect()
	check(info_rect.position.y >= lobby.stamina_view._info_button.get_global_rect().end.y and root.get_visible_rect().encloses(info_rect), "information sits below header within viewport")
	lobby.stamina_view._info_button.mouse_exited.emit()
	check(not lobby.stamina_view.overlay.visible, "desktop mouse leave hides information")
	lobby.stamina_view._info_button.pressed.emit()
	lobby.stamina_view._info_button.mouse_exited.emit()
	check(lobby.stamina_view.overlay.visible and lobby.stamina_view._info_pinned, "single tap pins information without hover dependency")
	lobby.stamina_view._info_button.pressed.emit()
	check(not lobby.stamina_view.overlay.visible, "second tap closes information")
	lobby.stamina_view.show_info()
	var outside := InputEventScreenTouch.new()
	outside.pressed = true
	outside.position = Vector2(5, 1200)
	check(not lobby.stamina_view.handle_info_input(outside) and not lobby.stamina_view.overlay.visible, "outside touch dismisses card without blocking lobby input")
	lobby._enter_selected_stage()
	check(lobby.stamina_view.overlay.visible and not lobby._battle_entry_pending and STORE.read_state().amount == 4, "actual insufficient lobby request stays put")
	await capture("recovery")
	check(lobby.stamina_view.details.text.contains("다음 +1까지") and lobby.stamina_view.details.text.contains("최대 충전까지"), "overlay shows both recovery times")
	lobby.stamina_view.open_shop()
	await settle()
	check(lobby.current_tab == "shop" and not lobby.stamina_view.overlay.visible, "+ targets shop")
	var scroll := lobby.get_node("SafeArea/Layout/Content/ShopTab/ShopMargin/ShopLayout/ShopScroll") as ScrollContainer
	check(scroll.get_global_rect().intersects(lobby.stamina_view.product.get_global_rect()), "stamina product scrolls into view")
	check(lobby.stamina_view.product.get_node("VBoxContainer/StaminaPurchase").disabled, "unconfigured payment never charges")
	if "--capture" in OS.get_cmdline_user_args():
		scroll.scroll_vertical = 0
		await settle()
		await capture("shop")
	lobby._switch_tab("main")
	seed_wallet(5, int(Time.get_unix_time_from_system()))
	var transition := root.get_node("SceneTransition")
	root.remove_child(transition)
	var deferred := DeferredTransition.new()
	deferred.name = "SceneTransition"
	root.add_child(deferred)
	lobby._enter_selected_stage()
	lobby._enter_selected_stage()
	check(lobby.stamina_view._spend_label.visible and lobby.stamina_view._spend_label.text == "-5" and lobby.stamina_view._entry_blocker.visible, "deduction feedback appears before loading")
	await create_timer(0.55).timeout
	check(not lobby.stamina_view._spend_label.visible and not lobby.stamina_view._entry_blocker.visible, "deduction feedback recycles controls")
	check(deferred.requests == 1 and STORE.read_state().amount == 0, "actual double-tap entry charges once")
	lobby._refund_failed_stamina_entry()
	check(STORE.read_state().amount == 5, "actual lobby load failure refunds")
	root.remove_child(deferred)
	deferred.free()
	root.add_child(transition)
	lobby.queue_free()
	await settle()
	seed_wallet(4, int(Time.get_unix_time_from_system()))
	var config := ConfigFile.new()
	SCOPE.load_config(config, "user://stage_progress.cfg")
	config.set_value("progress", "highest_unlocked_stage", 2)
	SCOPE.save_configs({"stage_progress.cfg": config})
	var main = load("res://src/main/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await settle()
	main._on_restart_pressed()
	check(STORE.read_state().amount == 4 and not main._stamina_entry_pending, "battle retry insufficient does not reload")
	check(main.get_node("StaminaNotice").visible, "battle insufficient notice visible")
	main.get_node("StaminaNotice").hide()
	main._on_next_stage_pressed()
	check(STORE.read_state().amount == 4 and PROGRESS.load_state().current_stage_id == "stage_1", "next stage gate cannot bypass debit")
	seed_wallet(30,int(Time.get_unix_time_from_system()))
	STORE.try_enter("stage_1")
	main._battle_stamina_entry = STORE.claim_battle_entry("stage_1")
	main._start_battle_after_intro("stage_1")
	main._battle_started_ms = maxi(Time.get_ticks_msec() - 1000, 0)
	main.battle.set_external_pause(true) # Menu time is included in the real-time window.
	root.remove_child(transition)
	var exit_transition := DeferredTransition.new()
	exit_transition.name = "SceneTransition"
	root.add_child(exit_transition)
	main._on_lobby_pressed()
	main._on_lobby_pressed()
	check(STORE.read_state().amount == 29 and exit_transition.requests == 1, "actual early lobby exit returns four once")
	root.remove_child(exit_transition)
	exit_transition.free()
	root.add_child(transition)
	main.queue_free()
	await settle()
	print("STAMINA_SMOKE_" + ("FAILED" if failed else "OK"))
	quit(1 if failed else 0)
