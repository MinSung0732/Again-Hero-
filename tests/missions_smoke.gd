extends SceneTree

const RULES := preload("res://src/data/mission_catalog.gd")
const LEDGER := preload("res://src/systems/mission_ledger.gd")
const STORE := preload("res://src/systems/mission_store.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const SERVICE := preload("res://src/systems/mission_progress.gd")
const VIEW := preload("res://src/ui/lobby_missions_view.gd")
const TRAYS := preload("res://src/ui/lobby_tool_trays.gd")
var failures := 0
var checks := 0

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(label)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var thursday := int(Time.get_unix_time_from_datetime_string("2026-10-07T15:00:00"))
	check(LEDGER.period("daily", thursday - 1) + 1 == LEDGER.period("daily", thursday), "KST daily midnight")
	check(LEDGER.period("weekly", thursday - 1) + 1 == LEDGER.period("weekly", thursday), "KST Thursday midnight")
	check(LEDGER.period("weekly", thursday) == LEDGER.period("weekly", thursday + 6 * 86400), "weekly stays through Wednesday")
	var state := {}
	LEDGER.record(state, "summon", 99, thursday - 1)
	LEDGER.record(state, "summon", 1, thursday)
	check(state.daily.counts.summon == 1 and state.weekly.counts.summon == 1, "expired events do not carry over")
	LEDGER.record(state, "mana", 37.5, thursday)
	LEDGER.record(state, "mana", 62.5, thursday)
	check(state.daily.counts.mana == 100, "fractional mana retained")
	LEDGER.record(state, "summon", 1000000, thursday)
	check(state.daily.counts.summon == 100 and state.weekly.counts.summon == 500, "bounded counters")
	LEDGER.record(state, "unknown", 100, thursday)
	check(not state.daily.counts.has("unknown"), "unknown event ignored")
	var friday := thursday + 86400
	var across_days := {}
	LEDGER.record(across_days, "summon", 99, friday - 1)
	LEDGER.record(across_days, "summon", 1, friday)
	check(across_days.daily.counts.summon == 1 and across_days.weekly.counts.summon == 100, "daily reset preserves week")
	var malformed := {"daily": {"period": LEDGER.period("daily", thursday), "counts": {"summon": "invalid"}, "claimed": []}}
	LEDGER.normalize(malformed, thursday)
	check(malformed.daily.counts.summon == 0 and malformed.daily.claimed is Dictionary, "malformed ledger normalized")
	var capture := {"meta": {"research_points": 70}, "monster_gacha": {"total_draws": 11}, "stamina": {"active_entry": 1, "active_charged": 5, "active_claimed": false}}
	var previous := {"meta": {"research_points": 20}, "monster_gacha": {"total_draws": 1}}
	LEDGER.capture(capture, previous, thursday)
	check(capture.missions.state.daily.counts.research == 50 and capture.missions.state.weekly.counts.gacha == 10, "actual acquisition/draw deltas")
	check(float(capture.missions.state.daily.counts.get("stamina", 0)) == 0, "unclaimed/failed battle entry excluded")
	var committed := capture.duplicate(true)
	capture.stamina.active_claimed = true
	LEDGER.capture(capture, committed, thursday)
	check(capture.missions.state.daily.counts.stamina == 5, "claimed entry counts once")
	committed = capture.duplicate(true)
	LEDGER.capture(capture, committed, thursday)
	check(capture.missions.state.daily.counts.stamina == 5, "repeat entry save is idempotent")

	var original_guest := SCOPE.guest_directory
	SCOPE.select_guest()
	SCOPE.guest_directory = "user://mission_smoke_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	STORE.pending.clear()
	var config := ConfigFile.new()
	check(SCOPE.save_config(config, RULES.SAVE_PATH) == OK, "isolated guest initial save")
	STORE.record("summon", 100)
	STORE.record("mana", 100)
	check(STORE.flush(), "buffered combat flush")
	var snapshot := STORE.snapshot()
	check(snapshot.tabs.daily[0].id == "summon" and snapshot.claimable == 2, "completed first, stable ordering")
	var result := STORE.claim("daily", "summon")
	check(result.get("success", false) and result.gold == 150 and result.research == 10, "individual claim")
	check(not STORE.claim("daily", "summon").success, "double claim denied")
	check(STORE.snapshot().tabs.daily[-1].id == "summon", "claimed goes to bottom")
	check(not STORE.claim("weekly", "gacha").success, "incomplete denied")
	check(STORE.claim("daily").get("count", 0) == 1, "claim-all eligible snapshot")
	var wallet := ConfigFile.new()
	check(SCOPE.load_config(wallet, RULES.SAVE_PATH) == OK, "wallet load")
	check(wallet.get_value("meta", "gold", 0) == 300 and wallet.get_value("meta", "research_points", 0) == 20, "markers and exact currencies")
	check(STORE.snapshot().tabs.daily[-1].claimed, "claimed status survives disk reload")
	# Source wallet delta and mission progress save atomically; caller is unchanged.
	wallet.set_value("meta", "research_points", 70)
	check(SCOPE.save_config(wallet, RULES.SAVE_PATH) == OK, "currency transaction")
	check(STORE.snapshot().claimable == 1, "acquisition completes research mission")
	var retry := ConfigFile.new()
	SCOPE.load_config(retry, RULES.SAVE_PATH)
	check(SCOPE.save_config(retry, RULES.SAVE_PATH) == OK and STORE.snapshot().claimable == 1, "same wallet write does not double count")
	var stale := ConfigFile.new()
	stale.set_value("meta", "gold", 300)
	stale.set_value("meta", "research_points", 70)
	check(SCOPE.save_config(stale, RULES.SAVE_PATH) == OK and STORE.snapshot().tabs.daily[-1].claimed, "unrelated writes preserve ledger")
	check(not stale.has_section("missions"), "capture never mutates caller config")
	# Broken journal must retain pending actions and prevent all rewards.
	var journal := SCOPE.guest_directory.path_join("gameplay_transaction.json")
	var file := FileAccess.open(journal, FileAccess.WRITE)
	file.store_string("[]") # Valid JSON but invalid transaction: no expected parser noise.
	file.close()
	STORE.record("summon", 5)
	check(not STORE.flush() and not STORE.pending.is_empty(), "failed flush retains events")
	check(not STORE.claim("daily", "research").success, "failed save gives no rewards")
	DirAccess.remove_absolute(journal)
	check(STORE.flush(), "retry saves once")
	var other_guest := SCOPE.guest_directory + "_other"
	DirAccess.make_dir_recursive_absolute(other_guest)
	SCOPE.guest_directory = other_guest
	check(STORE.snapshot().claimable == 0, "guest namespace isolation")
	var raw_id := Crypto.new().generate_random_bytes(16).hex_encode()
	var account_id := "%s-%s-%s-%s-%s" % [raw_id.substr(0, 8), raw_id.substr(8, 4), raw_id.substr(12, 4), raw_id.substr(16, 4), raw_id.substr(20, 12)]
	check(SCOPE.select_account(account_id), "isolated account selected")
	STORE.record("mana", 100)
	check(STORE.flush(), "account buffered flush")
	var saved_serial := SCOPE.serial
	var blocked_path := SCOPE.resolve("user://save_bundle.json") + ".tmp"
	DirAccess.make_dir_recursive_absolute(blocked_path)
	check(not STORE.claim("daily", "mana").success and SCOPE.serial == saved_serial, "failed account claim rolls back serial")
	check(STORE.snapshot().claimable == 1 and int(SCOPE.files["stage_progress.cfg"].get("meta", {}).get("gold", 0)) == 0, "failed account claim preserves markers and wallet")
	DirAccess.remove_absolute(blocked_path)
	check(STORE.claim("daily", "mana").get("success", false), "account retry awards once")
	check(not STORE.claim("daily", "mana").success, "account duplicate denied")
	DirAccess.remove_absolute(SCOPE.resolve("user://save_bundle.json"))
	DirAccess.remove_absolute("user://accounts/" + account_id)
	SCOPE.select_guest()
	SCOPE.guest_directory = original_guest
	STORE.pending.clear()
	STORE.pending_owner = STORE.owner()

	# Use a separate temporary guest wallet for live view checks.
	SCOPE.guest_directory = other_guest
	STORE.record("summon", 100)
	STORE.flush()
	var parent := Control.new()
	root.add_child(parent)
	parent.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tray := TRAYS.new()
	tray.install(parent, func() -> bool: return true)
	var service := SERVICE.new()
	root.add_child(service)
	var view := VIEW.new()
	view.install(parent, tray, service, Callable())
	view.open()
	check(bool(tray.get("_notifications").get(&"daily", false)), "claimable mission turns on badge")
	for size_px in [Vector2i(1080, 1920), Vector2i(540, 960), Vector2i(1280, 720), Vector2i(390, 844)]:
		root.size = size_px
		for frame in 20:
			await process_frame
		var panel: PanelContainer = view.get("_panel")
		var overlay: Control = view.get("_overlay")
		check(panel.size.is_equal_approx(VIEW.DESIGN_SIZE), "bounded design dimensions %s actual %s" % [size_px, panel.size])
		var rect := Rect2(panel.position, panel.size * panel.scale)
		check(Rect2(Vector2.ZERO, overlay.size).encloses(rect), "whole popup fits %s" % size_px)
		check(view.blocks_stage_input(), "visible modal blocks stage swipe")
		var cache: Dictionary = view.get("_row_cache")
		for id in RULES.EVENTS:
			check(cache[id].button.get_child(0).get_rect().size.x >= 500, "row content width %s" % id)
	view.call("_claim", "summon")
	var row: Dictionary = view.get("_row_cache").summon
	check(row.button.disabled and row.button.modulate.r < 0.5, "claimed card gray and disabled")
	check(not bool(tray.get("_notifications").get(&"daily", false)), "badge clears after final available claim")
	view.call("_select_tab", "weekly")
	check(view.get("_reset").text.contains("목요일"), "weekly tab reset label")
	view.close()
	check(not view.blocks_stage_input(), "closed modal releases input")
	parent.hide()
	parent.queue_free()
	service.queue_free()
	SCOPE.guest_directory = original_guest
	STORE.pending.clear()
	print("missions_smoke: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
