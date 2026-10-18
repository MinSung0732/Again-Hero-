extends RefCounted

# Unlock progress is permanent; release availability is a separate product gate.
const HARD_AVAILABLE := false
const HARD_NOTICE := "어려움 난이도는 전용 패턴 준비 중입니다. 쉬움 난이도를 이용해 주세요."

static func difficulty_available(value: String) -> bool:
	return value == "easy" or (value == "hard" and HARD_AVAILABLE)

static func scene_entry_available(path: String, options: Dictionary) -> bool:
	if path not in ["res://src/main/Main.tscn","res://src/hero_mode/HeroMode.tscn"]: return true
	return difficulty_available(String(options.get("difficulty","easy")))

const ORDER := ["hard", "hero", "rank"]
const RULES := {
	"hard": {"name": "어려움 난이도", "required_stage": "", "condition": "해당 스테이지 쉬움 클리어 후 개방"},
	"hero": {"name": "용사 모드", "required_stage": "stage_3", "condition": "마왕 모드 쉬움 3스테이지 클리어 후 개방 · 용사는 해당 마왕 쉬움 스테이지 클리어"},
	"rank": {"name": "랭킹 매칭", "required_stage": "stage_10", "condition": "마왕 모드와 용사 모드 쉬움 10스테이지 모두 클리어 후 개방"},
}

static func announcement_key(mode: String, stage_id: String, perspective: String = "demon") -> String:
	if mode != "hard": return mode
	return mode+":hero:"+stage_id if perspective == "hero" else mode+":"+stage_id
