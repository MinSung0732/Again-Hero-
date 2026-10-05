extends RefCounted
class_name ShopCatalog

const TEST_GOLD := 99999
const SINGLE_DRAW_COST := 100
const MULTI_DRAW_COST := 1000
const MULTI_DRAW_COUNT := 11

const GACHA_SOUNDS := {
	"door": {"path": "res://assets/audio/sfx/gacha/door_open.mp3", "volume_db": -5.0},
	"creak": {"path": "res://assets/audio/sfx/gacha/door_creak.mp3", "volume_db": -2.0},
	"reveal": {"path": "res://assets/audio/sfx/gacha/monster_reveal.mp3", "volume_db": 0.0},
}

const BANNERS := [
	{
		"id": "monster_reinforcement",
		"badge": "EVENT",
		"title": "어둠의 군단 소환",
		"description": "몬스터 조각을 모아\n새로운 전력을 편성하세요.",
		"art_path": "res://assets/art/UI/shop/monster_banner.png",
		"footer": "마왕군 확장 이벤트",
	},
	{
		"id": "relic_preview",
		"badge": "COMING SOON",
		"title": "유물 소환 준비 중",
		"description": "마왕군을 강화할 유물,\n곧 찾아옵니다.",
		"art_path": "res://assets/art/UI/shop/relic_banner.png",
		"footer": "유물 데이터 · 확률 · 재화 설계 중",
	},
	{
		"id": "growth_packages",
		"badge": "PACKAGE",
		"title": "성장 재화 패키지",
		"description": "골드 · 연구 포인트 보급\n상품을 준비하고 있습니다.",
		"art_path": "res://assets/art/UI/shop/monster_banner.png",
		"footer": "결제/상품 정책 확정 후 활성화",
	},
]

const PACKAGES := [
	{
		"id": "gold_supply_small",
		"art_path": "res://assets/art/UI/shop/gold_supply.png",
		"badge": "GOLD",
		"title": "골드 보급 I",
		"reward_text": "골드 5,000",
		"price_text": "가격 준비 중",
		"featured": false,
		"enabled": false,
	},
	{
		"id": "gold_supply_large",
		"art_path": "res://assets/art/UI/shop/gold_supply.png",
		"badge": "GOLD",
		"title": "골드 보급 II",
		"reward_text": "골드 25,000",
		"price_text": "가격 준비 중",
		"featured": true,
		"enabled": false,
	},
	{
		"id": "research_supply_small",
		"art_path": "res://assets/art/UI/shop/research_supply.png",
		"badge": "RESEARCH",
		"title": "연구 지원팩",
		"reward_text": "연구 포인트 100",
		"price_text": "가격 준비 중",
		"featured": false,
		"enabled": false,
	},
	{
		"id": "research_supply_large",
		"art_path": "res://assets/art/UI/shop/research_supply.png",
		"badge": "RESEARCH",
		"title": "심화 연구팩",
		"reward_text": "연구 포인트 500",
		"price_text": "가격 준비 중",
		"featured": true,
		"enabled": false,
	},
]

const RARITY_ORDER := [
	"common",
	"uncommon",
	"rare",
	"legendary",
	"transcendent",
]

const RARITIES := {
	"common": {
		"label": "일반",
		"rank": 0,
		"weight": 100.0,
		"shard_min": 2,
		"shard_max": 5,
		"color": Color("f4f4f4"),
		"door_sheet_path": "res://assets/art/effects/gatcha/gacha_gold_light/monster_common/monster_common_sheet.png",
	},
	"uncommon": {
		"label": "고급",
		"rank": 1,
		"weight": 0.0,
		"shard_min": 6,
		"shard_max": 15,
		"color": Color("ffd84f"),
		"door_sheet_path": "res://assets/art/effects/gatcha/gacha_gold_light/monster_uncommon/monster_uncommon_sheet.png",
	},
	"rare": {
		"label": "희귀",
		"rank": 2,
		"weight": 0.0,
		"shard_min": 3,
		"shard_max": 8,
		"color": Color("54a8ff"),
		"door_sheet_path": "res://assets/art/effects/gatcha/gacha_gold_light/monster_rare/monster_rare_sheet.png",
	},
	"legendary": {
		"label": "전설",
		"rank": 3,
		"weight": 0.0,
		"shard_min": 1,
		"shard_max": 3,
		"color": Color("bc70ff"),
		"door_sheet_path": "res://assets/art/effects/gatcha/gacha_gold_light/monster_legendary/monster_legendary_sheet.png",
	},
	"transcendent": {
		"label": "초월",
		"rank": 4,
		"weight": 0.0,
		"shard_min": 1,
		"shard_max": 1,
		"color": Color("61e887"),
		"door_sheet_path": "res://assets/art/effects/gatcha/gacha_gold_light/monster_transcendent/monster_transcendent_sheet.png",
	},
}

static func get_rarity(rarity_id: String) -> Dictionary:
	var data = RARITIES.get(rarity_id, {})
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	return data

static func get_rarity_label(rarity_id: String) -> String:
	var data := get_rarity(rarity_id)
	return String(data.get("label", rarity_id))


static func get_rarity_rank(rarity_id: String) -> int:
	var data := get_rarity(rarity_id)
	return maxi(int(data.get("rank", 0)), 0)


static func get_banner_count() -> int:
	return BANNERS.size()


static func get_banner(index: int) -> Dictionary:
	if BANNERS.is_empty():
		return {}
	var count := BANNERS.size()
	var safe_index := ((index % count) + count) % count
	var data = BANNERS[safe_index]
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	return Dictionary(data).duplicate(true)


static func get_packages() -> Array:
	return PACKAGES.duplicate(true)


static func get_package(package_id: String) -> Dictionary:
	for raw_data in PACKAGES:
		if typeof(raw_data) != TYPE_DICTIONARY:
			continue
		var data: Dictionary = raw_data
		if String(data.get("id", "")) == package_id:
			return data.duplicate(true)
	return {}
