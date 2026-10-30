extends SceneTree
const CLOCK := preload("res://src/systems/server_clock.gd")
const LEDGER := preload("res://src/systems/mission_ledger.gd")
const MISSIONS := preload("res://src/systems/mission_store.gd")
const STAMINA := preload("res://src/systems/stamina_store.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const EXPLORE := preload("res://src/systems/exploration_reward_store.gd")
var failed := false
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("SERVER_CLOCK_TEST: " + message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.get_node("CloudStore").stop()
	root.get_node("LocalTestMode").active = false
	SCOPE.guest_directory = "user://clock_test"
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	SCOPE.select_guest()
	CLOCK._synced = false
	CLOCK.test_system = 1800000000
	CLOCK.test_ticks = 1000
	var boundary := CLOCK.parse_date("Wed, 07 Oct 2026 15:00:00 GMT")
	check(boundary > 0 and CLOCK.parse_date("bad") == -1, "RFC1123 parse")
	var old := LEDGER.period("weekly", boundary - 1)
	var state := {"weekly": {"period": old, "counts": {}, "claimed": {}}}
	LEDGER.normalize(state, boundary, false)
	check(state.weekly.period == old, "unsynced period held")
	check(MISSIONS.claim("daily").get("reason") == "clock_pending", "claim held")
	check(EXPLORE.checkpoint(true) == ERR_BUSY and EXPLORE.claim().get("reason") == "clock_pending", "exploration held")
	var cfg := ConfigFile.new()
	cfg.set_value("stamina", "amount", 5)
	cfg.set_value("stamina", "recovery_at", boundary - 720)
	SCOPE.save_configs({"stage_progress.cfg": cfg})
	STAMINA.invalidate()
	check(STAMINA.read_state().amount == 5, "stamina held")
	root.get_node("ServerClock").observe(PackedStringArray(["Date: Wed, 07 Oct 2026 15:00:00 GMT"]))
	CLOCK.test_system = 100
	CLOCK.test_ticks = 3000
	check(CLOCK.now() == boundary + 2, "monotonic clock")
	LEDGER.normalize(state, CLOCK.now())
	check(state.weekly.period == old + 1, "KST weekly boundary")
	state.weekly.period += 9
	state.weekly.claimed["summon"] = true
	LEDGER.normalize(state, CLOCK.now())
	check(state.weekly.period == old + 1 and state.weekly.claimed.summon, "future mission period clamped without regrant")
	check(STAMINA.read_state().amount == 7, "stamina settled")
	cfg.set_value("stamina", "recovery_at", boundary + 10000)
	SCOPE.save_configs({"stage_progress.cfg": cfg})
	STAMINA.invalidate()
	check(STAMINA.read_state().recovery_at == CLOCK.now(), "future stamina clamped")
	cfg.set_value("exploration_rewards", "anchor", CLOCK.now() + 10000)
	SCOPE.save_configs({"stage_progress.cfg": cfg})
	check(EXPLORE.checkpoint(true) == OK, "exploration checkpoint")
	var loaded := ConfigFile.new()
	SCOPE.load_config(loaded, "user://stage_progress.cfg")
	check(int(loaded.get_value("exploration_rewards", "anchor", 0)) == CLOCK.now(), "future exploration anchor clamped")
	print("SERVER_CLOCK_TEST: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
