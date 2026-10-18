extends RefCounted

const CONNECTION := preload("res://src/data/cloud_connection_catalog.gd")

# Transport argument types, separate from snapshot/gameplay values.
const INTEGER_ARGUMENTS := {
	"cloud_sync": ["expected_revision"],
	"account_tutorial": ["expected_revision"],
	"save_game_snapshot": ["expected_revision"],
}
# Only these commands own CloudStore's serial profile-RPC retry loop.
# Register/complete are idempotent; rename/gender reuse the caller's operation UUID.
# cloud_sync owns its lock/recovery externally. Unknown mutations must not retry.
const SERIAL_RETRY_METHODS := {
	"read_player_profile": true,
	"register_player_profile": true,
	"complete_player_prologue": true,
	"check_player_nickname": true,
	"rename_player_nickname": true,
	"change_player_gender": true,
}
const AUTH_REFRESH_STATUS := HTTPClient.RESPONSE_UNAUTHORIZED
const DELAY_RETRY_CLIENT_STATUSES := [HTTPClient.RESPONSE_REQUEST_TIMEOUT, HTTPClient.RESPONSE_TOO_MANY_REQUESTS]
const SERVER_ERROR_MIN := HTTPClient.RESPONSE_INTERNAL_SERVER_ERROR
const CLIENT_ERROR_MIN := HTTPClient.RESPONSE_BAD_REQUEST
const CLIENT_ERROR_MAX := SERVER_ERROR_MIN - 1
const REJECTED_MESSAGE := CONNECTION.REQUEST_REJECTED # Compatibility for existing codec callers.
const MAX_EXACT_JSON_INTEGER := 9007199254740991.0

static func is_retryable_client_status(status: int) -> bool:
	return status == AUTH_REFRESH_STATUS or status in DELAY_RETRY_CLIENT_STATUSES

static func retry_empty_response(status: int) -> bool:
	# 401 gets one credential refresh in the caller, never the delay retry loop.
	return status <= 0 or status >= SERVER_ERROR_MIN or status in DELAY_RETRY_CLIENT_STATUSES
