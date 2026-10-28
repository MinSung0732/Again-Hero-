extends RefCounted
const SAMPLES := 96
const INPUT_SLOTS := 64
const REFRESH_US := 1000000
const PANEL_SECONDS := 1.0
const MAX_SEQUENCE := 2147483647
const SERVER_FIELDS := ["physics_ms","process_ms","snapshot_ms","encode_ms","snapshot_samples","encode_samples","rooms","peers","actors","projectiles","snapshot_bytes","tx_kib_s","rx_kib_s"]
const FRAME_STALL_MS := 50.0
const SAMPLE_KEYS := ["rtt","gap","input","snapshot","encode","frame"]
static func sequence(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value>=0 and value<=MAX_SEQUENCE and value==floorf(value)
static func server_valid(value: Variant) -> bool:
	if not value is Dictionary or value.size()!=SERVER_FIELDS.size(): return false
	for key in SERVER_FIELDS:
		var number: Variant = value.get(key,null)
		if not (number is int or number is float) or not is_finite(float(number)) or number<0 or number>1000000000: return false
	return true
