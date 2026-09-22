extends RefCounted
class_name FlowPauseManager

const DOMAIN_COMBAT := "combat"
const DOMAIN_RUN_TIMER := "run_timer"
const DOMAIN_COMMAND_REGEN := "command_regen"
const DOMAIN_STAGE_EVENTS := "stage_events"
const DOMAIN_DEMON_RUNTIME := "demon_runtime"

var _requests: Dictionary = {}

func reset() -> void:
	_requests.clear()

func request_pause(reason: String, domains: Array) -> void:
	if reason.is_empty():
		return

	var normalized: Array[String] = []
	for raw_domain in domains:
		var domain := String(raw_domain)
		if domain.is_empty() or domain in normalized:
			continue
		normalized.append(domain)

	if normalized.is_empty():
		_requests.erase(reason)
		return

	_requests[reason] = normalized

func release_pause(reason: String) -> void:
	_requests.erase(reason)

func is_paused(domain: String) -> bool:
	for raw_domains in _requests.values():
		for raw_domain in raw_domains:
			if String(raw_domain) == domain:
				return true
	return false

func get_reasons_for(domain: String) -> Array[String]:
	var reasons: Array[String] = []
	for raw_reason in _requests.keys():
		var reason := String(raw_reason)
		var domains: Array = _requests.get(raw_reason, [])
		if domain in domains:
			reasons.append(reason)
	return reasons

func get_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	for raw_reason in _requests.keys():
		var reason := String(raw_reason)
		var domains: Array = _requests.get(raw_reason, [])
		snapshot[reason] = domains.duplicate()
	return snapshot
