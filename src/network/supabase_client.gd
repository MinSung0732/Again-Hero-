extends Node
class_name SupabaseClient

const CONFIG := preload("res://src/network/supabase_config.gd")
const REQUEST_TIMEOUT_SECONDS := 20.0
const MAX_RESPONSE_BYTES := 2000000

signal request_completed(tag: String, status_code: int, payload: Variant)

var access_token: String = ""
var _session_generation := 0

func set_access_token(token: String) -> void:
	if token != access_token:
		_session_generation += 1
	access_token = token

func clear_session() -> void:
	_session_generation += 1
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
	# A stalled/oversized response must not retain a request indefinitely.
	request.timeout = REQUEST_TIMEOUT_SECONDS
	request.body_size_limit = MAX_RESPONSE_BYTES
	add_child(request)
	request.request_completed.connect(
		_on_http_request_completed.bind(request, tag, _session_generation),
		CONNECT_ONE_SHOT
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
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	request: HTTPRequest,
	tag: String,
	generation: int
) -> void:
	request.queue_free()
	# A response started under another session cannot enter the current UI.
	if generation != _session_generation:
		return
	if result != HTTPRequest.RESULT_SUCCESS:
		request_completed.emit(tag, 0, null)
		return
	var body_text := body.get_string_from_utf8()
	var payload: Variant = body_text

	if not body_text.is_empty():
		var parser := JSON.new()
		if parser.parse(body_text) == OK and parser.data != null:
			payload = parser.data

	request_completed.emit(tag, response_code, payload)
