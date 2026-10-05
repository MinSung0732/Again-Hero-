extends RefCounted

const ORDER := ["hard", "hero", "rank"]
const RULES := {
	"hard": {"name": "어려움 난이도", "required_stage": "", "condition": "해당 스테이지 쉬움 클리어 후 개방"},
	"hero": {"name": "용사 모드", "required_stage": "stage_10", "condition": "쉬움 Stage 10 클리어 후 개방"},
	"rank": {"name": "랭킹 매칭", "required_stage": "stage_10", "condition": "쉬움 Stage 10 클리어 후 개방"},
}

static func announcement_key(mode: String, stage_id: String) -> String:
	return mode + ":" + stage_id if mode == "hard" else mode
