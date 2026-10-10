extends Node

signal changed

const STORE := preload("res://src/systems/exploration_reward_store.gd")
const RULES := preload("res://src/data/exploration_reward_catalog.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
var _owner := ""
var _revision := -1
var _focused := true
var _paused := false
var _idle := false
var _booted := false
var _timer: Timer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_timer = Timer.new()
	_timer.wait_time = RULES.CHECKPOINT_SECONDS
	_timer.timeout.connect(_heartbeat)
	add_child(_timer)
	_timer.start()
	_booted = true
	_sync_session.call_deferred()
	var cloud := get_node_or_null("/root/CloudStore")
	if cloud != null:
		cloud.status_changed.connect(_on_account_status)

func _on_account_status(_message: String) -> void:
	# Cloud saves also emit status; only changed account/revision needs a read.
	var key := _account_key()
	if key != _owner or SCOPE.revision != _revision:
		_sync_session.call_deferred()

func _account_key() -> String:
	return SCOPE.user_id if not SCOPE.user_id.is_empty() else "guest:" + SCOPE.guest_directory

func _available() -> bool:
	if SCOPE.user_id.is_empty():
		return true
	var cloud := get_node_or_null("/root/CloudStore")
	return cloud != null and cloud.ready_for_play and not cloud.conflict

func _sync_session() -> bool:
	if not _available():
		return false
	var key := _account_key()
	if key == _owner and SCOPE.revision == _revision:
		return true
	# Account switch credits only that account's offline anchor. A same-account
	# cloud refresh must not re-credit the ongoing foreground interval.
	var new_owner := key != _owner
	if new_owner:
		var error := STORE.checkpoint(true)
		if error != OK:
			return false
	# A revision acknowledgement is read-only. Writing here would trigger a
	# new cloud save after every acknowledgement and create a sync loop.
	_owner = key
	_revision = SCOPE.revision
	changed.emit()
	return true

func _heartbeat() -> void:
	if not _sync_session():
		return
	_set_idle(not _focused or _paused)
	if _idle or not _focused or _paused:
		return
	STORE.checkpoint(false)

func _notification(what: int) -> void:
	if not _booted:
		return
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			_focused = false
		NOTIFICATION_APPLICATION_FOCUS_IN:
			_focused = true
		NOTIFICATION_APPLICATION_PAUSED:
			_paused = true
		NOTIFICATION_APPLICATION_RESUMED:
			_paused = false
		_:
			return
	_set_idle(not _focused or _paused)

func _set_idle(value: bool) -> void:
	if value == _idle or not _sync_session():
		return
	var error := STORE.checkpoint(not value)
	if error == OK:
		_idle = value
		changed.emit()

func snapshot() -> Dictionary:
	if not _sync_session():
		return {"success": false}
	return STORE.snapshot()

func claim() -> Dictionary:
	if _idle or not _sync_session():
		return {"success": false, "reason": "unavailable"}
	var result := STORE.claim()
	if bool(result.get("success", false)):
		changed.emit()
	return result

func _exit_tree() -> void:
	# Normal quit records the exact anchor. Unexpected process termination uses
	# the last 60-second foreground checkpoint (documented recovery tolerance).
	if _booted and not _idle and _account_key() == _owner and _available():
		STORE.checkpoint(false)
