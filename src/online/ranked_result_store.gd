extends Node
## Server process only. The secret is read from its environment, never sent to peers.
const RULES := preload("res://src/data/ranked_rules.gd")
var endpoint := ""
var service_key := ""

func _ready() -> void:
	endpoint = OS.get_environment("AGAIN_HERO_SUPABASE_URL").strip_edges().trim_suffix("/")
	service_key = OS.get_environment("AGAIN_HERO_SUPABASE_SERVICE_KEY").strip_edges()
	if not endpoint.begins_with("https://") or service_key.is_empty():
		endpoint = ""; service_key = ""

func configured() -> bool:
	return not endpoint.is_empty() and not service_key.is_empty()

func record(match_id: String, demon_uid: String, hero_uid: String, winner: String, reason: String, margins: Dictionary) -> Dictionary:
	if not configured(): return {}
	var body := JSON.stringify({"p_match_id":match_id,"p_demon_user":demon_uid,"p_hero_user":hero_uid,
		"p_winner":winner,"p_reason":reason,"p_margin_demon":margins.demon,"p_margin_hero":margins.hero})
	for attempt in 3:
		var request := HTTPRequest.new()
		request.timeout = 3.0; request.body_size_limit = 16384
		add_child(request)
		var error := request.request(endpoint + "/rest/v1/rpc/record_ranked_result", PackedStringArray([
			"apikey: " + service_key,"Authorization: Bearer " + service_key,
			"Content-Type: application/json","Accept: application/json"]), HTTPClient.METHOD_POST, body)
		if error == OK:
			var response: Array = await request.request_completed
			request.queue_free()
			if response[0] == HTTPRequest.RESULT_SUCCESS and response[1] == 200:
				var parsed: Variant = JSON.parse_string((response[3] as PackedByteArray).get_string_from_utf8())
				if _valid_result(parsed): return parsed
		else:
			request.queue_free()
		if attempt < 2: await get_tree().create_timer(0.3).timeout
	return {}

static func _valid_result(value: Variant) -> bool:
	if not value is Dictionary: return false
	for role in ["demon", "hero"]:
		var entry: Variant = value.get(role, null)
		if not entry is Dictionary: return false
		for field in ["previous_mmr", "mmr", "delta", "server_rank"]:
			var number: Variant = entry.get(field, null)
			if not (number is int or number is float) or not is_finite(float(number)) or float(number) != floorf(float(number)): return false
		if RULES.icon_path(String(entry.get("tier", ""))).is_empty(): return false
	return true
