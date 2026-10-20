extends RefCounted
## Packet-local path interning. No connection dictionary or mutable input state.
const ART := preload("res://src/data/online_presentation_catalog.gd")
const RULES := preload("res://src/online/match_rules.gd")
var path_ids := {}
var paths: Array = []
var path_costs := PackedInt32Array()
var row_cache: Array = []
var rows: Array = []
var envelope := {}
var used_table := false
var saved_bytes := 0
func _init() -> void:
	path_costs.resize(ART.MAX_COMMANDS)
	for index in ART.MAX_COMMANDS:
		var row: Array = []; row.resize(ART.COMMAND_SIZE); row_cache.append(row)
func encode(message: Dictionary) -> String:
	used_table = false; saved_bytes = 0
	path_ids.clear(); paths.clear(); rows.clear(); envelope.clear()
	if message.get("op","") != "state" or not message.has("visuals"): return _finish(message)
	var commands: Variant = message.visuals
	if not commands is Array or commands.size() > ART.MAX_COMMANDS or message.has(ART.PATH_TABLE_FIELD): return ""
	var replaced_bytes := 0
	var table_bytes := 0
	for command in commands:
		# Authoritative sampler output: check shape/path here. Incoming clients
		# perform full numeric/geometry validation before expansion and rendering.
		if not command is Array or command.size()!=ART.COMMAND_SIZE or not ART.path_allowed(command[ART.PATH_INDEX]): return ""
		var path: String = command[ART.PATH_INDEX]
		var id: int = path_ids.get(path,-1)
		if id < 0:
			id = paths.size(); path_ids[path] = id; paths.append(path)
			path_costs[id] = JSON.stringify(path).to_utf8_buffer().size()
			table_bytes += path_costs[id]
		replaced_bytes += path_costs[id]-str(id).length()
	# Added comma, quoted field name, colon, brackets and table-item commas.
	table_bytes += JSON.stringify(ART.PATH_TABLE_FIELD).length()+4+maxi(0,paths.size()-1)
	saved_bytes = replaced_bytes-table_bytes
	if saved_bytes <= 0: saved_bytes = 0; return _finish(message)
	for index in commands.size():
		var source: Array = commands[index]; var row: Array = row_cache[index]
		for field in ART.COMMAND_SIZE: row[field] = source[field]
		row[ART.PATH_INDEX] = path_ids[source[ART.PATH_INDEX]]; rows.append(row)
	envelope.merge(message); envelope["visuals"] = rows; envelope[ART.PATH_TABLE_FIELD] = paths
	var encoded := _finish(envelope)
	envelope.clear()
	used_table = not encoded.is_empty()
	return encoded
static func _finish(message: Dictionary) -> String:
	var encoded := JSON.stringify(message)
	return encoded if encoded.to_utf8_buffer().size() <= RULES.MAX_SNAPSHOT else ""
static func expand(message: Dictionary) -> bool:
	# Validate the entire packet before replacing any path index.
	var commands: Variant = message.get("visuals",ART.EMPTY)
	if not commands is Array or commands.size() > ART.MAX_COMMANDS: return false
	if not message.has(ART.PATH_TABLE_FIELD):
		for command in commands:
			if not ART.valid(command): return false
		return true
	var table: Variant = message[ART.PATH_TABLE_FIELD]
	if not table is Array or table.size() > ART.MAX_COMMANDS: return false
	for path in table:
		if not ART.path_allowed(path): return false
	for command in commands:
		if not ART.indexed_valid(command,table.size()): return false
	for command in commands: command[ART.PATH_INDEX] = table[int(command[ART.PATH_INDEX])]
	message.erase(ART.PATH_TABLE_FIELD)
	return true
