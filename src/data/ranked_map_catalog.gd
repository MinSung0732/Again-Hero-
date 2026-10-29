extends RefCounted
## Initial playtest values. Longer rounds give the hero more room; shorter rounds
## give the demon a tighter arena, so time and arena size offset each other.
# 맵별 엘리트 처치 조건을 조절할 수 있다.
const MAPS := [
	{"id":"plaza","name":"성문 광장","theme":"castle","description":"기본 전장에서 균형 있게 겨룹니다.","elite":{"first_kills":100,"every_kills":150},"favor":"neutral","duration_seconds":600,"stage_visual":"stage_1","map_size":Vector2(3200,3200),"modifiers":{}},
	{"id":"plains","name":"햇살 숲 평원","theme":"sunlit_meadow","description":"넓은 전장과 긴 시간으로 용사가 성장하기 좋습니다.","elite":{"first_kills":100,"every_kills":150},"favor":"hero","duration_seconds":900,"stage_visual":"stage_1","map_size":Vector2(4000,4000),"modifiers":{"hero_exp_multiplier":1.1}},
	{"id":"corridor","name":"저주받은 늪지","theme":"cursed_swamp","description":"좁은 전장에서 마왕의 공세가 거세집니다.","elite":{"first_kills":100,"every_kills":150},"favor":"demon","duration_seconds":480,"stage_visual":"stage_1","map_size":Vector2(2560,2560),"modifiers":{"command_regen_multiplier":1.1}},
]

static func all() -> Array:
	return MAPS.duplicate(true)

static func get_map(id: String) -> Dictionary:
	for entry in MAPS:
		if entry.id == id: return entry.duplicate(true)
	return {}

static func pick(rng: RandomNumberGenerator) -> Dictionary:
	return MAPS[rng.randi_range(0,MAPS.size()-1)].duplicate(true)

static func ids() -> Array[String]:
	var result: Array[String] = []
	for entry in MAPS: result.append(entry.id)
	return result

static func favor_label(_favor: String) -> String:
	return "랭킹 매칭"
