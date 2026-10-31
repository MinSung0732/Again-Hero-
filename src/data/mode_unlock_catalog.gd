extends RefCounted
const HARD := preload("res://src/data/hard_campaign_catalog.gd")
const PROGRESS := preload("res://src/systems/stage_progress.gd")

# Unlock progress is permanent; release availability is a separate product gate.
const HARD_AVAILABLE := true # At least one demon stage is live; availability is stage-specific.
const HARD_NOTICE := "어려움 난이도는 마왕 Stage 1부터 순차 개방합니다. 선택한 모드·스테이지는 준비 중입니다."

static func difficulty_available(value: String, stage_id: String = "", perspective: String = "demon") -> bool:
	return value == "easy" or (value == "hard" and perspective == "demon" and HARD.demon_stage_available(stage_id))

static func scene_entry_available(path: String, options: Dictionary) -> bool:
	if path == "res://src/main/Main.tscn":
		var difficulty := String(options.get("difficulty", "easy"))
		var stage_id := String(options.get("stage_id", ""))
		return difficulty_available(difficulty, stage_id, "demon") and (difficulty != "hard" or PROGRESS.is_stage_cleared(stage_id))
	if path == "res://src/hero_mode/HeroMode.tscn":
		return difficulty_available(String(options.get("difficulty", "easy")), String(options.get("stage_id", "")), "hero")
	return true

const ORDER := ["hard", "hero", "rank"]
const RULES := {
	"hard": {"name": "어려움 난이도", "required_stage": "", "condition": "해당 스테이지 쉬움 클리어 후 개방"},
	"hero": {"name": "용사 모드", "required_stage": "stage_3", "condition": "마왕 모드 쉬움 3스테이지 클리어 후 개방 · 용사는 해당 마왕 쉬움 스테이지 클리어"},
	"rank": {"name": "랭킹 매칭", "required_stage": "stage_4", "condition": "마왕 모드와 용사 모드 쉬움 4스테이지 모두 클리어 후 개방"},
}

static func announcement_key(mode: String, stage_id: String, perspective: String = "demon") -> String:
	if mode != "hard": return mode
	return mode+":hero:"+stage_id if perspective == "hero" else mode+":"+stage_id
