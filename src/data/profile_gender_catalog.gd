extends RefCounted

const DEFAULT_ID := "male"
const LINKED_CHANGES := 1
const OPTIONS := {"male": "남성", "female": "여성"}
const PROLOGUE_CHOICE_RECTS := {
 "male": Rect2(0.08, 0.40, 0.40, 0.28),
 "female": Rect2(0.52, 0.40, 0.40, 0.28),
}
const TITLE := "마왕 성별 변경"
const ACTION := "마왕 성별 변경 (계정 연동 %d회)"
const GUIDE := "계정 연동 후 성별을 %d회 변경할 수 있습니다.\n이름 변경 기회와 별개이며, 확정하면 되돌릴 수 없습니다."
const CONFIRM := "%s 마왕으로 변경 확정"
const SAVING := "변경 사항을 저장하고 있습니다…"
const ERRORS := {
 "unchanged": "현재 성별과 다른 성별을 선택해 주세요.",
 "locked": "성별 변경 기회를 이미 사용했습니다.",
 "account_changed": "계정이 변경되었습니다. 닫고 다시 확인해 주세요.",
 "local_save": "서버 반영은 완료됐지만 기기 저장에 실패했습니다. 다시 로그인해 주세요.",
 "default": "변경을 완료하지 못했습니다. 다시 시도해 주세요.",
}

static func valid(id: String) -> bool:
	return OPTIONS.has(id)

static func label(id: String) -> String:
	return OPTIONS.get(id, OPTIONS[DEFAULT_ID])
