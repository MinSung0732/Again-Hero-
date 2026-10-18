extends RefCounted
## Separate versioned experiment; no rating or account-reward writer.
const VERSION := 1
const ID := "duel_smoke_v1"
const HERO := "ranged_rookie"
const ROSTER := ["slime","spider","orc","bomb_rat","skeleton_archer"]
const DURATION := 180.0
const POPULATION := 48
const OPENING_MANA := 48.0
const MANA_PER_SECOND := 12.0
const SNAPSHOT_INTERVAL := 0.1
const INPUT_TIMEOUT := 0.35
const CHOICE_TIMEOUT := 8.0
const MAX_CLIENTS := 24
const MAX_AUTH_REQUESTS := 8
const MAX_ROOMS := 8
const MAX_PACKET := 8192
const MAX_SNAPSHOT := 98304
const JOIN_TIMEOUT := 15.0
const READY_TIMEOUT := 20.0
const QUEUE_TIMEOUT := 180.0
const ERROR_MESSAGES := {
	"server_busy":"인증 요청이 많습니다. 잠시 후 다시 시도해 주세요.",
	"authentication_failed":"로그인 확인에 실패했습니다. 다시 로그인한 후 시도해 주세요.",
	"duplicate_account":"같은 계정이 이미 매칭 또는 대전 중입니다.",
	"version_mismatch":"대전 버전이 다릅니다. 같은 버전으로 업데이트해 주세요.",
	"battle_load_failed":"서버가 전투를 준비하지 못했습니다.",
	"invalid_role":"대전 역할을 확인해 주세요.",
}
static func endpoint_valid(url: String) -> bool:
	return url.begins_with("wss://") or url.begins_with("ws://127.0.0.1:") or url.begins_with("ws://localhost:")
static func number(value: Variant,limit: float = 1000000.0) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and absf(float(value)) <= limit
static func point(value: Variant,limit: float = 1000000.0) -> bool:
	return value is Array and value.size() == 2 and number(value[0],limit) and number(value[1],limit)
static func decode(packet: PackedByteArray,max_bytes: int = MAX_PACKET) -> Dictionary:
	if packet.size() > max_bytes: return {}
	var parsed: Variant = JSON.parse_string(packet.get_string_from_utf8())
	return parsed if parsed is Dictionary else {}
