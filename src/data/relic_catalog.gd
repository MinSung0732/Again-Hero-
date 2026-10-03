extends RefCounted
class_name RelicCatalog

# 유물 콘텐츠가 확정되면 이 Catalog에만 항목을 추가한다.
# 항목 필드: id, name, category, icon_path, effect_text,
# required_fragments(기본 30). Lobby는 이를 읽어 4열 카드와 상세 패널을
# 자동 구성하고, 실제 level/fragments는 별도 진행 저장 상태에서 받는다.
const RELICS := {}
const ORDER: Array[String] = []

const CATEGORY_ORDER: Array[String] = [
	"all",
	"attack",
	"defense",
	"utility",
]

const CATEGORY_LABELS := {
	"all": "전체",
	"attack": "공격",
	"defense": "방어",
	"utility": "보조",
}


static func get_relic(relic_id: String) -> Dictionary:
	var data = RELICS.get(relic_id, {})
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	return Dictionary(data).duplicate(true)


static func get_ordered_ids(category_id: String = "all") -> Array[String]:
	var result: Array[String] = []
	for raw_id in ORDER:
		var relic_id := String(raw_id)
		var data := get_relic(relic_id)
		if data.is_empty():
			continue
		if (
			category_id != "all"
			and String(data.get("category", "utility")) != category_id
		):
			continue
		result.append(relic_id)
	return result
