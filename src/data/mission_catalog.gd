extends RefCounted

# Add a tab here and a period rule in MissionLedger; the view builds from data.
const TABS := [
	{"id": "daily", "title": "일일미션", "reset": "매일 00:00 초기화 · 한국시간", "targets": [100, 1, 100, 15, 50], "gold": [150, 100, 150, 150, 100], "research": [10, 10, 10, 20, 10]},
	{"id": "weekly", "title": "주간미션", "reset": "목요일 00:00 초기화 · 한국시간", "targets": [500, 10, 1000, 100, 1000], "gold": [500, 600, 500, 700, 700], "research": [50, 60, 50, 70, 70]},
]
const EVENTS := ["summon", "gacha", "mana", "stamina", "research"]
const TITLES := ["몬스터 %d마리 소환하기", "몬스터 뽑기 %d회", "마력 %d 사용하기", "스테미너 %d 소모하기", "연구포인트 %d 획득하기"]
const ICON_DIR := "res://assets/art/UI/missions/"
const SAVE_PATH := "user://stage_progress.cfg"

static func tab(id: String) -> Dictionary:
	for entry in TABS:
		if entry.id == id:
			return entry
	return {}
