extends Node

# Presentation boundary only. No fake OAuth token/account is ever produced.
# Replace begin_login with the real provider adapter after server restoration;
# emit authenticated only after validated session + account save selection.
signal login_requested(provider: String)
signal login_unavailable(message: String)
signal local_guest_started
signal authenticated

var local_guest_active := false


func begin_login(provider: String) -> void:
	if provider not in ["google", "kakao"]:
		login_unavailable.emit("지원하지 않는 로그인 방식입니다.")
		return
	login_requested.emit(provider)
	login_unavailable.emit("계정 로그인은 서버 복구 후 연결됩니다.\n지금은 게스트로 기존 로컬 데이터를 이어서 플레이할 수 있어요.")


func begin_local_guest() -> void:
	if local_guest_active:
		return
	local_guest_active = true
	local_guest_started.emit()


func reset_local_guest() -> void:
	local_guest_active = false
