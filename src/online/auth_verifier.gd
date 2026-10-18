extends Node
const CONFIG := preload("res://src/network/supabase_config.gd")
func verify(token: String) -> String:
	if token.length() < 20 or token.length() > 4096 or token.count(".") != 2: return ""
	for byte in token.to_utf8_buffer():
		if not (byte >= 65 and byte <= 90 or byte >= 97 and byte <= 122 or byte >= 48 and byte <= 57 or byte in [45,46,95]): return ""
	var request := HTTPRequest.new(); request.timeout = 10; request.body_size_limit = 65536; add_child(request)
	var error := request.request(CONFIG.PROJECT_URL+"/auth/v1/user",PackedStringArray(["apikey: "+CONFIG.PUBLISHABLE_KEY,"Authorization: Bearer "+token]))
	if error != OK: request.queue_free(); return ""
	var response: Array = await request.request_completed; request.queue_free()
	if response[0] != HTTPRequest.RESULT_SUCCESS or response[1] != 200: return ""
	var user: Variant = JSON.parse_string((response[3] as PackedByteArray).get_string_from_utf8())
	if not user is Dictionary or not user.get("id",null) is String: return ""
	var uid: String = user.id
	return uid if uid.length() == 36 else ""
