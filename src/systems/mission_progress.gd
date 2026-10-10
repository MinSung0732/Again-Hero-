extends Node

signal changed
const STORE := preload("res://src/systems/mission_store.gd")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var timer := Timer.new()
	timer.wait_time = 5.0
	timer.timeout.connect(_checkpoint)
	add_child(timer)
	timer.start()

func record(event: String, amount: float) -> void:
	STORE.record(event, amount)

func _checkpoint() -> void:
	STORE.flush()
	changed.emit()

func flush() -> void:
	_checkpoint()

func snapshot() -> Dictionary:
	return STORE.snapshot()

func claim(tab: String, id: String = "") -> Dictionary:
	var result := STORE.claim(tab, id)
	changed.emit()
	return result

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST]:
		STORE.flush()
