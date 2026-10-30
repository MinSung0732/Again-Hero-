extends RefCounted

const LIST_LIMIT := 200
const FRAME_SIZE := Vector2(840, 1100)
const FRAME_MARGIN := 36
const GAP := 16
const DATE_FONT_SIZE := 24
const ROW_PADDING := 12
const ROW_GAP := 12
const ACTION_SIZE := Vector2(100, 64)
const ATTACHMENT_WIDTH := 110
const EMPTY_SIZE := Vector2(180, 180)
const ICON_DIR := "res://assets/art/UI/mailbox/"
const TRASH_ICON := ICON_DIR + "trash.png"
const CLOSE_ICON := ICON_DIR + "close.png"
const CLAIMED_ICON := ICON_DIR + "claimed.png"
const EMPTY_ICON := ICON_DIR + "empty.png"
const SENDER_COLOR := Color("eac14d")
const HEADER_FORMAT := "%s · %s"
const TITLE_FORMAT := "%s · %d"
const SEASON_BUTTON_SIZE := Vector2(220, 120)
const BUTTON_SIZE := Vector2(120, 120)
const CLOSE_SIZE := Vector2(112, 64)
const SEASON_PORTRAIT_SIZE := 128
const SEASON_TIER_SIZE := 48
const SEASON_ROW_FILL := "32233e"
const SEASON_ROW_EDGE := "776184"
const SEASON_REWARD_FORMAT := "보상 기준: %s 모드 · %s"
const SEASON_ROLE_FORMAT := "%s 모드"
const ICON_SIZE := Vector2(88, 88)
const ROW_HEIGHT := 120.0
const ROW_COLOR := Color("21192f")
const ROW_BORDER := Color("8f6c3e")
const SEASON_PREVIEW := {"week_start":"local-preview", "demon":{"final_tier":"diamond_1", "final_mmr":2300, "server_rank":0, "wins":1}, "hero":{"final_tier":"hero", "final_mmr":3000, "server_rank":3, "wins":1}, "hero_top_hero_id":"ranged_rookie", "demon_top_transcendence_id":"zeus", "demon_top_role":"tank", "reward_tier":"hero", "demon_token":250, "hero_token":250}
const TITLE := "우편함"
const EMPTY := "도착한 우편이 없습니다."
const CLAIM := "받기"
const CLAIMED := "수령 완료"
const CLAIM_ALL := "모두 받기"
const ERROR := "우편을 불러오거나 저장하지 못했습니다. 다시 시도해 주세요."
const UNAVAILABLE := "우편함 서비스를 준비 중입니다."
const DELETE_ALL := "일괄 삭제"
const DELETE := "삭제"
const DELETE_CONFIRM := "우편 %d개를 삭제하시겠습니까?"
const CLOSE_SYMBOL := "X"
const DELETE_SYMBOL := "🗑"
const CLOSE := "닫기"
const MESSAGE_ICON := "res://assets/art/UI/lobby_tools/mailbox.png"
const DEFAULT_SENDER := "운영팀"
const SENDERS := {"ranked_weekly": "랭킹 정산"}
const LOADING := "우편을 불러오는 중…"
const GOLD := {"name":"골드", "icon_path":"res://assets/art/UI/lobby_header/coin.svg"}
const LOCAL_MAIL := [
	{"id":"00000000-0000-4000-8000-000000000001", "kind":"test", "title":"마왕토큰 테스트", "body":"로컬 테스트 보상입니다.", "created_at":"2026-10-30", "attachments":{"demon_token":10}},
	{"id":"00000000-0000-4000-8000-000000000002", "kind":"test", "title":"용사토큰 테스트", "body":"로컬 테스트 보상입니다.", "created_at":"2026-10-30", "attachments":{"hero_token":10}},
	{"id":"00000000-0000-4000-8000-000000000003", "kind":"test", "title":"안내 우편", "body":"로컬 테스트 메시지입니다.", "created_at":"2026-10-30", "attachments":{}},
]

static func currencies() -> Dictionary:
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://src/data/token_currencies.json"))
	if not value is Dictionary: return {}
	value["gold"] = GOLD
	return value

static func texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path): return load(path) as Texture2D
	if path.ends_with(".png"):
		var image := Image.new()
		if image.load(path) == OK: return ImageTexture.create_from_image(image)
	return null
