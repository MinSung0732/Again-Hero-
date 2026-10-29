extends RefCounted
## Ranked entry and waiting screens share these player-facing rules.
const MATCH := preload("res://src/online/match_rules.gd")
const RANKED := preload("res://src/data/ranked_rules.gd")
const HERO_MODE := preload("res://src/data/hero_mode_catalog.gd")
const DEMON_AUGMENTS := preload("res://src/data/demon_augment_catalog.gd")
const PICKUPS := preload("res://src/data/ranked_pickup_catalog.gd")
const MAPS := preload("res://src/data/ranked_map_catalog.gd")
const THEMES := preload("res://src/data/battlefield_theme_catalog.gd")

static func sections() -> Array:
	var win_low := RANKED.delta(true,0.0)
	var win_high := RANKED.delta(true,1.0)
	var loss_low := absi(RANKED.delta(false,0.0))
	var loss_high := absi(RANKED.delta(false,1.0))
	var map_items: Array[String] = []
	for entry in MAPS.all():
		map_items.append("%s · %s · %d분" % [entry.name,MAPS.favor_label(String(entry.favor)),int(entry.duration_seconds)/60])
		var shown: Array = []
		for item in THEMES.get_theme(entry.theme).layout:
			var id: String = item.get("effect", "")
			if id.is_empty() or shown.has(id): continue
			shown.append(id)
			var effect: Dictionary = THEMES.EFFECTS[id]
			map_items.append("%s %+.0f%%" % [effect.label, float(effect.value) * 100.0])
		map_items.append("용사 처치 %d마리째부터 %d마리마다 엘리트 1장, 최대 %d장 보관" % [entry.elite.first_kills,entry.elite.every_kills,MATCH.ELITE_CARD_LIMIT])
	return [
		{"title":"출전 편성","items":["용사: 해금한 용사 중 선택", "마왕: 로비 편성 팀·스킬·초월 반입", "로비 연구 효과 미적용"]},
		{"title":"전투","items":["마왕 소환은 수동 배치만 가능", "초월 소환은 경기당 %d회" % MATCH.TRANSCENDENCE_SUMMON_LIMIT, "마왕은 용사의 무기·패시브·레벨·선택한 증강을 볼 수 있음(보관 중인 선택지는 비공개)", "용사는 마왕 편성·스킬·초월을 볼 수 없고, 마왕이 고른 증강의 역할 방향만 볼 수 있음"]},
		{"title":"증강 보관","items":["선택지는 받을 때 고정되며, 받아 두고 원할 때 선택", "최대 %d개 보관, 초과 시 가장 오래된 선택지 자동 선택" % MATCH.AUGMENT_HOLD_LIMIT, "용사 증강 새로고침 %d회(보관 항목에 사용)" % HERO_MODE.AUGMENT_REROLLS, "마왕 증강 새로고침 %d회(보관 항목에 사용)" % DEMON_AUGMENTS.BASE_REROLLS, "경기 종료 시 남은 증강 소멸", "증강을 고르는 동안에도 전투 진행"]},
		{"title":"상자","items":["일반 %d처치마다 상자(첫 상자도 가능)" % PICKUPS.CHEST_KILLS, "첫 정예 처치 시 첫 상자, 이후 정예 %d처치마다" % PICKUPS.CHEST_ELITE_KILLS, "상자 결과는 서버가 결정하고 즉시 적용", "랭크전 상자 골드 없음", "상자 연출 중에도 전투 진행"]},
		{"title":"랭크 전용 맵","items":map_items},
		{"title":"MMR","items":["승리 +%d~%d, 패배 -%d~%d" % [win_low,win_high,loss_low,loss_high], "경기 내용 반영: 마왕 승리는 처치 속도, 용사 승리는 남은 HP", "중도 이탈 %d" % RANKED.delta(false,1.0)]},
		{"title":"추후 추가","items":["주간 보상 준비 중"]},
	]
