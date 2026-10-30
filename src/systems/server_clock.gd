extends Node

signal synchronized
const RULES := preload("res://src/data/server_clock_catalog.gd")
const CLIENT := preload("res://src/network/supabase_client.gd")
static var synced_unix := 0
static var synced_ticks := 0
static var _synced := false
static var test_ticks := -1
static var test_system := -1
var _client: Node
var _requesting := false

static func ticks() -> int:
	return test_ticks if test_ticks >= 0 else Time.get_ticks_msec()

static func now() -> int:
	if _synced:
		return synced_unix + maxi(ticks() - synced_ticks, 0) / 1000
	return test_system if test_system >= 0 else int(Time.get_unix_time_from_system())

static func is_synced() -> bool:
	return _synced

static func allowed() -> bool:
	if _synced: return true
	var loop := Engine.get_main_loop() as SceneTree
	if loop == null: return false
	var mode := loop.root.get_node_or_null("LocalTestMode")
	return mode != null and mode.active

static func parse_date(value: String) -> int:
	var parts := value.strip_edges().split(" ", false)
	if parts.size() != 6 or not parts[0].ends_with(",") or parts[5] != "GMT": return -1
	var month := RULES.MONTHS.find(parts[2]) + 1
	var clock := parts[4].split(":")
	if month == 0 or clock.size() != 3 or not parts[1].is_valid_int() or not parts[3].is_valid_int(): return -1
	for part in clock:
		if not part.is_valid_int(): return -1
	var date := {"year": int(parts[3]), "month": month, "day": int(parts[1]), "hour": int(clock[0]), "minute": int(clock[1]), "second": int(clock[2])}
	if date.year < 1970 or date.day < 1 or date.day > 31 or date.hour > 23 or date.minute > 59 or date.second > 59 or date.hour < 0 or date.minute < 0 or date.second < 0: return -1
	var unix := int(Time.get_unix_time_from_datetime_dict(date))
	var check := Time.get_datetime_dict_from_unix_time(unix)
	return unix if check.year == date.year and check.month == date.month and check.day == date.day else -1

func observe(headers: PackedStringArray) -> void:
	for header in headers:
		if header.to_lower().begins_with("date:"):
			var timestamp := parse_date(header.substr(5))
			if timestamp >= 0:
				synced_unix = timestamp
				synced_ticks = ticks()
				_synced = true
				synchronized.emit()
			return

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_client = CLIENT.new()
	add_child(_client)
	_client.request_completed.connect(_on_probe_completed)
	_resync.call_deferred()
	var timer := Timer.new()
	timer.wait_time = RULES.RESYNC_SECONDS
	timer.timeout.connect(_resync)
	add_child(timer)
	timer.start()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED: _resync.call_deferred()

func _resync() -> void:
	if _requesting: return
	var mode := get_node_or_null("/root/LocalTestMode")
	if mode != null and mode.active: return
	_requesting = true
	if _client.request_json(RULES.RESYNC_PATH, HTTPClient.METHOD_GET, null, "server_clock") != OK:
		_requesting = false

func _on_probe_completed(_tag: String, _status: int, _payload: Variant) -> void:
	_requesting = false
