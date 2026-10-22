extends Node
const LOADOUT := preload("res://src/online/online_loadout.gd")
const HEROES := preload("res://src/data/hero_character_catalog.gd")
var endpoint := ""
var service_key := ""

func _ready() -> void:
	endpoint = OS.get_environment("AGAIN_HERO_SUPABASE_URL").strip_edges().trim_suffix("/")
	service_key = OS.get_environment("AGAIN_HERO_SUPABASE_SERVICE_KEY").strip_edges()
	if not endpoint.begins_with("https://") or service_key.is_empty(): endpoint = ""; service_key = ""

func configured() -> bool:
	return not endpoint.is_empty() and not service_key.is_empty()

func verify(uid: String,role: String,loadout: Dictionary) -> bool:
	if not configured() or not LOADOUT.valid(role,loadout): return false
	var hero_stage := String(HEROES.get_character(String(loadout.get("hero_id",""))).get("stage","")) if role == "hero" else ""
	var monster_ids: Array = []
	if role == "demon":
		monster_ids = loadout.team_ids.duplicate()
		if not loadout.transcendence_id.is_empty(): monster_ids.append(loadout.transcendence_id)
	var request := HTTPRequest.new()
	request.timeout = 5.0; request.body_size_limit = 8192; add_child(request)
	var error := request.request(endpoint+"/rest/v1/rpc/read_ranked_loadout",PackedStringArray([
		"apikey: "+service_key,"Authorization: Bearer "+service_key,
		"Content-Type: application/json","Accept: application/json"]),HTTPClient.METHOD_POST,
		JSON.stringify({"p_user":uid,"p_hero_stage":hero_stage,"p_monster_ids":monster_ids}))
	if error != OK: request.queue_free(); return false
	var response: Array = await request.request_completed
	request.queue_free()
	if response[0] != HTTPRequest.RESULT_SUCCESS or response[1] != 200: return false
	var saved: Variant = JSON.parse_string((response[3] as PackedByteArray).get_string_from_utf8())
	return saved is Dictionary and LOADOUT.owned(role,loadout,saved)
