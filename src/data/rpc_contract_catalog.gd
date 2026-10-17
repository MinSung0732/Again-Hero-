extends RefCounted

# Transport argument types, separate from snapshot/gameplay values.
const INTEGER_ARGUMENTS := {
	"cloud_sync": ["expected_revision"],
	"account_tutorial": ["expected_revision"],
	"save_game_snapshot": ["expected_revision"],
}
const RETRYABLE_CLIENT_STATUSES := [401, 408, 429]
const CLIENT_ERROR_MIN := 400
const CLIENT_ERROR_MAX := 499
const REJECTED_MESSAGE := "서버 요청을 처리하지 못했습니다. 로그인 화면으로 돌아가 다시 시도해 주세요."
const MAX_EXACT_JSON_INTEGER := 9007199254740991.0
