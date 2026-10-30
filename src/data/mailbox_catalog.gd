extends RefCounted

const LIST_LIMIT := 200
const SEASON_PREVIEW := {"week_start":"local-preview", "demon":{"final_tier":"diamond_1", "final_mmr":2300, "server_rank":0}, "hero":{"final_tier":"hero", "final_mmr":3000, "server_rank":3}, "reward_tier":"hero", "demon_token":250, "hero_token":250}
const TITLE := "우편함"
const EMPTY := "도착한 우편이 없습니다."
const CLAIM := "받기"
const CLAIMED := "수령 완료"
const CLAIM_ALL := "모두 받기"
const ERROR := "우편을 불러오거나 저장하지 못했습니다. 다시 시도해 주세요."
const LOADING := "우편을 불러오는 중…"
const GOLD := {"name":"골드", "icon_path":"res://assets/art/UI/lobby_header/coin.svg"}
const LOCAL_MAIL := [
	{"id":"00000000-0000-4000-8000-000000000001", "kind":"test", "title":"마왕토큰 테스트", "body":"로컬 테스트 보상입니다.", "attachments":{"demon_token":10}},
	{"id":"00000000-0000-4000-8000-000000000002", "kind":"test", "title":"용사토큰 테스트", "body":"로컬 테스트 보상입니다.", "attachments":{"hero_token":10}},
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
