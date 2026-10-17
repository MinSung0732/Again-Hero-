extends RefCounted
const CONTRACT := preload("res://src/data/rpc_contract_catalog.gd")

static func encode(method: String, parameters: Dictionary) -> Dictionary:
	var wire := parameters.duplicate()
	for field in CONTRACT.INTEGER_ARGUMENTS.get(method, []):
		if not wire.has(field): continue # Omitted optional arguments use server defaults.
		var value: Variant = wire[field]
		if value is int:
			if value < 0: return {"ok": false}
		elif value is float:
			if not is_finite(value) or value < 0.0 or value > CONTRACT.MAX_EXACT_JSON_INTEGER or value != floor(value):
				return {"ok": false}
		else:
			return {"ok": false}
		# JSON.parse_string restores integers as floats. PostgreSQL bigint input
		# rejects the resulting JSON decimal 1.0; preserve an integer wire token.
		wire[field] = int(value)
	return {"ok": true, "body": JSON.stringify(wire)}

static func is_permanent_http_error(status: int) -> bool:
	return status >= CONTRACT.CLIENT_ERROR_MIN and status <= CONTRACT.CLIENT_ERROR_MAX and status not in CONTRACT.RETRYABLE_CLIENT_STATUSES
