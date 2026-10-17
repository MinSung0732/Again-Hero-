extends RefCounted

# Cloud snapshot/profile transport and reconnect presentation policy.
# Keep OAuth provider/session-refresh policy separate; this is not an auth setting.
const RETRY_INITIAL_SECONDS := 1.0
const RETRY_MULTIPLIER := 2.0
const RETRY_MAX_SECONDS := 15.0
const HEARTBEAT_SECONDS := 15.0
const SAVE_COALESCE_SECONDS := 0.15
const REQUEST_TIMEOUT_SECONDS := 20.0
const RESPONSE_BODY_LIMIT_BYTES := 2000000
const WAIT_SCREEN_DELAY_SECONDS := 0.8

const CONNECTING := "서버에 연결 중입니다"
const CONNECTION_CHECK_TITLE := "연결을 확인해 주세요"
const CONNECTION_WAIT_DETAIL := "잠시만 기다려 주세요. 연결되면 자동으로 계속됩니다."
const RETURN_TO_LOGIN := "로그인 화면으로"
const REQUEST_REJECTED := "서버 요청을 처리하지 못했습니다. 로그인 화면으로 돌아가 다시 시도해 주세요."
const SESSION_REPLACED := "다른 기기에서 로그인했습니다. 다시 로그인해 주세요."
const SESSION_EXPIRED := "로그인이 만료되었습니다. 다시 로그인해 주세요."
const SAVING := "클라우드에 저장 중…"
const LOADED := "클라우드 저장 불러오기 완료"
const SAVED := "클라우드 저장 완료"
const REMOTE_SAVE_INVALID := "서버 저장을 읽지 못했습니다. 게임을 다시 실행해 주세요."
const LOCAL_INSTALL_FAILED := "기기에 저장할 공간을 확보한 후 다시 시도해 주세요."
const LOCAL_SAVE_FAILED := "저장 공간을 확인하고 게임을 다시 실행해 주세요."
const REWARD_RESPONSE_INVALID := "보상 저장 응답을 확인하지 못했습니다. 다시 로그인해 주세요."
const REWARD_INSTALL_FAILED := "기기에 저장할 공간을 확보한 뒤 다시 로그인해 주세요."
const WITHDRAWING := "계정 탈퇴 처리 중…"
const RELOADING_LOBBY := "서버의 기록을 불러오는 중"
const LOBBY_RELOAD_FAILED := "화면을 다시 준비하지 못했습니다. 다시 로그인해 주세요."

static func next_retry_delay(current: float) -> float:
	return minf(current * RETRY_MULTIPLIER, RETRY_MAX_SECONDS)
