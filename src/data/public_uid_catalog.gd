extends RefCounted
const FORMAT := "UID %s-%s"
const GUEST := "계정 연동 시 발급"
const UNAVAILABLE := "UID 발급 준비 중"
const COPY := "복사"
const COPIED := "복사 완료"
const LOCAL_UID := "00000001"
const RANK_GUEST := "계정 연동 후 이용"
const RANK_NOTICE := "랭크 모드는 계정 연동 후 이용할 수 있습니다."
const LINK := "계정 연동"
const CLOSE := "닫기"
static func format_uid(value: String) -> String:
	if value.length() != 8 or not value.is_valid_int(): return ""
	return FORMAT % [value.substr(0, 4), value.substr(4, 4)]
