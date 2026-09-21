extends Node
class_name SupabaseClient

const CONFIG := preload("res://src/network/supabase_config.gd")

signal request_completed(tag: String, status_code: int, payload: Variant)

var access_token: String = ""

func set_access_token(token: String) -> void:
	access_token = token

func clear_session() -> void:
	access_token = ""

func get_rows(table_name: String, query: String = "", tag: String = "") -> Error:
	var path := "/rest/v1/%s%s" % [table_name, query]
	return request_json(path, HTTPClient.METHOD_GET, null, tag)

func upsert_rows(table_name: String, rows: Variant, tag: String = "") -> Error:
	return request_json(
		"/rest/v1/%s" % table_name,
		HTTPClient.METHOD_POST,
		rows,
		tag,
		PackedStringArray(["Prefer: resolution=merge-duplicates,return=representation"])
	)

func delete_rows(table_name: String, query: String, tag: String = "") -> Error:
	return request_json(
		"/rest/v1/%s%s" % [table_name, query],
		HTTPClient.METHOD_DELETE,
		null,
		tag
	)

func request_json(
	path: String,
	method: int,
	body: Variant = null,
	tag: String = "",
	extra_headers: PackedStringArray = PackedStringArray()
) -> Error:
	if not CONFIG.is_configured():
		return ERR_UNCONFIGURED

	var request := HTTPRequest.new()
	add_child(request)
	request.request_completed.connect(
		_on_http_request_completed.bind(request, tag)
	)

	var headers := PackedStringArray([
		"apikey: %s" % CONFIG.PUBLISHABLE_KEY,
		"Accept: application/json",
		"Content-Type: application/json",
	])

	if not access_token.is_empty():
		headers.append("Authorization: Bearer %s" % access_token)

	for header in extra_headers:
		headers.append(header)

	var request_body := ""
	if body != null:
		request_body = JSON.stringify(body)

	var error := request.request(
		CONFIG.PROJECT_URL + path,
		headers,
		method,
		request_body
	)

	if error != OK:
		request.queue_free()

	return error

func _on_http_request_completed(
	_result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	request: HTTPRequest,
	tag: String
) -> void:
	var body_text := body.get_string_from_utf8()
	var payload: Variant = body_text

	if not body_text.is_empty():
		var parsed: Variant = JSON.parse_string(body_text)
		if parsed != null:
			payload = parsed

	request_completed.emit(tag, response_code, payload)
	request.queue_free()
