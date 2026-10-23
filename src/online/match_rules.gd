extends RefCounted
## Augment comparisons require matching protocol 17 peers.
const VERSION := 17
const HINT_DETAIL := "role" # "role" or "monster"
const ROLE_HINT_LABELS := {"melee":"근접"}
const TARGET_HINT_LABELS := {"demon":"마왕 운영","all_monsters":"모든 몬스터"}
const SUMMON_PLACEMENT := "manual" # 랭크전 마왕 소환은 수동 배치만, 자동 배치 금지.
const ID := "duel_smoke_v1"
const HERO := "ranged_rookie"
const ROSTER := ["slime","spider","orc","bomb_rat","skeleton_archer"]
const DURATION := 180.0
const POPULATION := 48
const OPENING_MANA := 48.0
const MANA_PER_SECOND := 12.0
const SNAPSHOT_INTERVAL := 0.1
const INPUT_TIMEOUT := 0.35
const CHOICE_TIMEOUT := 8.0 # Legacy fixture compatibility; ranked matches do not use a choice timer.
const UNAVAILABLE_AUGMENT_TEXT := "이미 최대 레벨이거나 슬롯이 가득 차 선택할 수 없습니다."
const MAX_OFFER_CANDIDATES := 4 # 증강 선택지 한 번에 보이는 최대 후보 수(와이어 검증·팝업 카드 수).
const MAX_COMPARE_ROWS := 6
const MAX_COMPARE_FIELD_LENGTH := 32
const AUGMENT_HOLD_LIMIT := 4
const CHEST_HISTORY_LIMIT := 16
const TRANSCENDENCE_SUMMON_LIMIT := 1
const MAX_CLIENTS := 24
const MAX_AUTH_REQUESTS := 8
const MAX_ROOMS := 8
const MAX_PACKET := 8192
const MAX_SNAPSHOT := 98304
const JOIN_TIMEOUT := 15.0
const READY_TIMEOUT := 20.0
const QUEUE_TIMEOUT := 180.0
const RECONNECT_GRACE := 15.0
const RECONNECT_RETRY := 1.0
const RECONNECT_WINDOW := 30.0
const HEARTBEAT_INTERVAL := 2.0
const PEER_IDLE_TIMEOUT := 8.0
const RESPONSE_TIMEOUT := 6.0
const RESULT_RETENTION := 10.0
const RESUME_TOKEN_BYTES := 24
const CLOSE_DRAIN_TIMEOUT := 2.0
const ERROR_MESSAGES := {
	"resume_unavailable":"경기 복귀 시간이 지났거나 서버가 재시작되었습니다. 로비에서 다시 입장하세요.",
	"resume_busy":"기존 연결의 종료를 확인하고 있습니다.",
	"local_test_denied":"테스트 서버 입장코드를 확인하세요. 서버를 --localtest 옵션으로 실행해야 합니다.",
	"server_busy":"인증 요청이 많습니다. 잠시 후 다시 시도해 주세요.",
	"authentication_failed":"로그인 확인에 실패했습니다. 다시 로그인한 후 시도해 주세요.",
	"duplicate_account":"같은 계정이 이미 매칭 또는 대전 중입니다.",
	"version_mismatch":"대전 버전이 다릅니다. 같은 버전으로 업데이트해 주세요.",
	"battle_load_failed":"서버가 전투를 준비하지 못했습니다.",
	"invalid_role":"대전 역할을 확인해 주세요.",
	"invalid_loadout":"대전 편성을 확인해 주세요.",
	"loadout_mismatch":"저장된 보유/편성과 다릅니다. 로비에서 저장 상태를 확인해 주세요.",
}
static func endpoint_valid(url: String) -> bool:
	return url.begins_with("wss://") or url.begins_with("ws://127.0.0.1:") or url.begins_with("ws://localhost:")
static func resume_token_valid(value: Variant) -> bool:
	return value is String and value.length() == RESUME_TOKEN_BYTES * 2 and value.is_valid_hex_number(false)
static func number(value: Variant,limit: float = 1000000.0) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and absf(float(value)) <= limit
static func point(value: Variant,limit: float = 1000000.0) -> bool:
	return value is Array and value.size() == 2 and number(value[0],limit) and number(value[1],limit)
static func decode(packet: PackedByteArray,max_bytes: int = MAX_PACKET) -> Dictionary:
	if packet.size() > max_bytes: return {}
	var parsed: Variant = JSON.parse_string(packet.get_string_from_utf8())
	return parsed if parsed is Dictionary else {}
