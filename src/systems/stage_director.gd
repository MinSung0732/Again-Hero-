extends RefCounted
class_name StageDirector

var timeline: Array = []
var fired_event_ids: Dictionary = {}

func reset(stage_data: Dictionary) -> void:
	timeline = Array(stage_data.get("event_timeline", [])).duplicate(true)
	fired_event_ids.clear()

func collect_due_events(elapsed_seconds: float) -> Array[Dictionary]:
	var due: Array[Dictionary] = []

	for raw_event in timeline:
		var event: Dictionary = raw_event
		var event_id := String(event.get("id", ""))
		if event_id.is_empty():
			continue
		if fired_event_ids.has(event_id):
			continue
		if elapsed_seconds + 0.001 < float(event.get("at_seconds", 0.0)):
			continue

		fired_event_ids[event_id] = true
		due.append(event.duplicate(true))

	return due

func get_fired_event_ids() -> Array[String]:
	var result: Array[String] = []
	for raw_id in fired_event_ids.keys():
		result.append(String(raw_id))
	return result
