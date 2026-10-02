extends RefCounted
class_name ShopCatalog

const TEST_GOLD := 99999
const SINGLE_DRAW_COST := 100
const MULTI_DRAW_COST := 1000
const MULTI_DRAW_COUNT := 11

const BANNERS := [
	{
		"id": "monster_reinforcement",
		"badge": "EVENT",
		"title": "신규 몬스터 전력 보급",
		"description": "몬스터 소환에서 조각을 모아 새로운 전투 편성을 준비하세요.",
		"footer": "마왕군 확장 이벤트",
	},
	{
		"id": "relic_preview",
		"badge": "COMING SOON",
		"title": "유물 소환 준비 중",
		"description": "마왕군 전체 빌드를 보조하는 유물 시스템이 이 상점에 합류합니다.",
		"footer": "유물 데이터 · 확률 · 재화 설계 중",
	},
	{
		"id": "growth_packages",
		"badge": "PACKAGE",
		"title": "성장 재화 패키지",
		"description": "골드와 연구 포인트 상품을 한 화면에서 확인하도록 패키지 영역을 확장했습니다.",
		"footer": "결제/상품 정책 확정 후 활성화",
	},
]

const PACKAGES := [
	{
		"id": "gold_supply_small",
		"badge": "GOLD",
		"title": "골드 보급 I",
		"reward_text": "골드 5,000",
		"price_text": "가격 준비 중",
		"featured": false,
		"enabled": false,
	},
	{
		"id": "gold_supply_large",
		"badge": "GOLD",
		"title": "골드 보급 II",
		"reward_text": "골드 25,000",
		"price_text": "가격 준비 중",
		"featured": true,
		"enabled": false,
	},
	{
		"id": "research_supply_small",
		"badge": "RESEARCH",
		"title": "연구 지원팩",
		"reward_text": "연구 포인트 100",
		"price_text": "가격 준비 중",
		"featured": false,
		"enabled": false,
	},
	{
		"id": "research_supply_large",
		"badge": "RESEARCH",
		"title": "심화 연구팩",
		"reward_text": "연구 포인트 500",
		"price_text": "가격 준비 중",
		"featured": true,
		"enabled": false,
	},
]

const RARITY_ORDER := ["common", "rare", "legendary"]

const RARITIES := {
	"common": {
		"label": "일반",
		"weight": 70.0,
		"shard_min": 10,
		"shard_max": 30,
	},
	"rare": {
		"label": "희귀",
		"weight": 25.0,
		"shard_min": 3,
		"shard_max": 8,
	},
	"legendary": {
		"label": "최고등급",
		"weight": 5.0,
		"shard_min": 1,
		"shard_max": 1,
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
