extends Node
## Server process only. The secret is read from its environment, never sent to peers.
const RULES := preload("res://src/data/ranked_rules.gd")
var endpoint := ""
var service_key := ""
var mmr_cache := {}
const CACHE_SECONDS := 30.0

func _ready() -> void:
	endpoint = OS.get_environment("AGAIN_HERO_SUPABASE_URL").strip_edges().trim_suffix("/")
	service_key = OS.get_environment("AGAIN_HERO_SUPABASE_SERVICE_KEY").strip_edges()
	if not endpoint.begins_with("https://") or service_key.is_empty():
		endpoint = ""; service_key = ""

func configured() -> bool:
	return not endpoint.is_empty() and not service_key.is_empty()

func fetch_mmr(uid: String, role: String) -> int:
	var initial := int(RULES.data().get("initial_mmr", 1000))
	if not configured() or not RULES._uid_valid(uid) or role not in ["demon", "hero"]: return initial
	var cache_key := uid + ":" + role
	var now := Time.get_ticks_msec() / 1000.0
	if mmr_cache.has(cache_key) and now < float(mmr_cache[cache_key].expires): return int(mmr_cache[cache_key].mmr)
	for attempt in 2:
		var request := HTTPRequest.new()
		request.timeout = 3.0; request.body_size_limit = 16384
		add_child(request)
		var error := request.request(endpoint + "/rest/v1/ranked_profiles?user_id=eq." + uid.uri_encode() + "&role=eq." + role + "&select=mmr", PackedStringArray([
			"apikey: " + service_key,"Authorization: Bearer " + service_key,
			"Content-Type: application/json","Accept: application/json"]), HTTPClient.METHOD_GET)
		if error == OK:
			var response: Array = await request.request_completed
			request.queue_free()
			if response[0] == HTTPRequest.RESULT_SUCCESS and response[1] == 200:
				var parsed: Variant = JSON.parse_string((response[3] as PackedByteArray).get_string_from_utf8())
				if parsed is Array:
					var mmr := initial
					if not parsed.is_empty() and parsed[0] is Dictionary:
						var value: Variant = parsed[0].get("mmr", null)
						if (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value)): mmr = int(value)
					mmr_cache[cache_key] = {"mmr":mmr,"expires":Time.get_ticks_msec() / 1000.0 + CACHE_SECONDS}
					return mmr
		else: request.queue_free()
		if attempt == 0: await get_tree().create_timer(0.3).timeout
	return initial

func record(match_id: String, demon_uid: String, hero_uid: String, winner: String, reason: String, margins: Dictionary, usage: Dictionary = {}) -> Dictionary:
	mmr_cache.erase(demon_uid + ":demon"); mmr_cache.erase(hero_uid + ":hero")
	if not configured(): return {}
	var body := JSON.stringify({"p_match_id":match_id,"p_demon_user":demon_uid,"p_hero_user":hero_uid,
		"p_winner":winner,"p_reason":reason,"p_margin_demon":margins.demon,"p_margin_hero":margins.hero, "p_hero_id":usage.get("hero_id", ""), "p_transcendence_id":usage.get("transcendence_id", ""), "p_role_counts":usage.get("role_counts", {})})
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
				if _valid_result(parsed):
					mmr_cache.erase(demon_uid + ":demon"); mmr_cache.erase(hero_uid + ":hero")
					return parsed
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
