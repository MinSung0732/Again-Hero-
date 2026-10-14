extends RefCounted

const ORDER := ["hard", "hero", "rank"]
const RULES := {
	"hard": {"name": "어려움 난이도", "required_stage": "", "condition": "해당 스테이지 쉬움 클리어 후 개방"},
	"hero": {"name": "용사 모드", "required_stage": "stage_3", "condition": "마왕 모드 쉬움 3스테이지 클리어 후 개방 · 용사는 해당 마왕 쉬움 스테이지 클리어"},
	"rank": {"name": "랭킹 매칭", "required_stage": "stage_10", "condition": "마왕 모드와 용사 모드 쉬움 10스테이지 모두 클리어 후 개방"},
}

static func announcement_key(mode: String, stage_id: String, perspective: String = "demon") -> String:
	if mode != "hard": return mode
	return mode+":hero:"+stage_id if perspective == "hero" else mode+":"+stage_id
