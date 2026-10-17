extends RefCounted

# Shared by every name entry/view; the SQL policy is checked against these values.
const MIN_LENGTH := 2
const LEGACY_MIN_LENGTH := 1
const MAX_LENGTH := 6
const ALLOWED_CHARACTERS := "가-힣A-Za-z0-9"
const LINKED_RENAMES := 1
const RANDOM_PREFIXES := ["새벽", "붉은", "검은", "달빛", "별빛", "고요", "은빛", "심연", "황혼", "푸른"]
const RANDOM_SUFFIXES := ["군주", "마왕", "왕관", "그림자", "불꽃", "루나", "아르", "카인", "밤", "별"]

static func valid(value: String, minimum: int = MIN_LENGTH) -> bool:
	var pattern := RegEx.new()
	pattern.compile("\\A[%s]{%d,%d}\\z" % [ALLOWED_CHARACTERS, minimum, MAX_LENGTH])
	return pattern.search(value) != null

static func guide() -> String:
	return "한글·영문·숫자 %d~%d글자 · 중복 불가" % [MIN_LENGTH, MAX_LENGTH]

static func random_name(previous: String = "") -> String:
	var candidate := previous
	while candidate == previous or not valid(candidate):
		candidate = String(RANDOM_PREFIXES.pick_random()) + String(RANDOM_SUFFIXES.pick_random()) + str(randi_range(0, 9))
	return candidate
