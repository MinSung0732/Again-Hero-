extends RefCounted
## Only thematic persistent weapons use emitters. No all-hero distribution quota.
const MODES := {
  "ranged_rookie_rune_ring": {
    "mode": "sigil",
    "label": "정면 비전진 · 위치 고정",
    "duration": 3.2,
    "count": 1,
    "budget": 1.4
  },
  "ranged_rookie_pulse_staff": {
    "mode": "sigil",
    "label": "표적 비전 파동 · 고정 공명진",
    "duration": 1.8,
    "count": 1,
    "budget": 1.8
  },
  "ranged_rookie_satellite_orbs": {
    "mode": "orbit",
    "label": "근거리 비전 위성 · 접촉 피해",
    "interval": 0.24,
    "budget": 1.15
  },
  "swift_hunter_venom_steps": {
    "mode": "trail",
    "label": "이동 경로 독무",
    "duration": 3.2,
    "count": 2,
    "budget": 1.8
  },
  "pistol_hero_grenade": {
    "mode": "bombard",
    "label": "표적 수류탄 · 예고 후 단발 폭발",
    "duration": 1.1,
    "count": 1,
    "budget": 1.0
  },
  "pistol_hero_powder_bomb": {
    "mode": "trap",
    "label": "화약 함정 · 적 접근 후 단발 폭발",
    "duration": 4,
    "count": 2,
    "budget": 1.5
  },
  "pistol_hero_suppressor": {
    "mode": "sentry",
    "label": "고정 기관총 · 자동 사격",
    "duration": 5,
    "count": 1,
    "budget": 5.0
  },
  "archmage_hero_earth_staff": {
    "mode": "fault",
    "label": "정면에 순서대로 솟는 대지 가시",
    "duration": 1.4,
    "count": 3,
    "budget": 1.8
  },
  "archmage_hero_lava_focus": {
    "mode": "sigil",
    "label": "표적 용암 분출 · 위치 고정",
    "duration": 4,
    "count": 1,
    "budget": 1.6
  },
  "archmage_hero_sunfire_tome": {
    "mode": "bombard",
    "label": "태양 충전 · 긴 예고 후 폭발",
    "duration": 1.5,
    "count": 1,
    "budget": 1.8
  },
  "madness_hero_blood_thorns": {
    "mode": "aura",
    "label": "용사 근거리 혈흔 가시",
    "duration": 3,
    "count": 1,
    "budget": 1.4
  },
  "chemical_hero_poison_flask": {
    "mode": "sigil",
    "label": "표적 시약 혼합장",
    "duration": 4,
    "count": 1,
    "budget": 1.8
  },
  "chemical_hero_caustic_boots": {
    "mode": "trail",
    "label": "이동 경로 부식 시약",
    "duration": 3,
    "count": 2,
    "budget": 1.8
  },
  "summoner_hero_collapse_glyph": {
    "mode": "sigil",
    "label": "소환수 전선의 붕괴 문양",
    "duration": 3,
    "count": 1,
    "budget": 1.5
  },
  "purifier_hero_sacred_orb": {
    "mode": "consecrate",
    "label": "시전 위치에 남는 순례 성역",
    "duration": 4,
    "count": 1,
    "budget": 1.4
  },
  "purifier_hero_judgment_seal": {
    "mode": "consecrate",
    "label": "시전 위치의 심판 성역",
    "duration": 4,
    "count": 1,
    "budget": 1.5
  },
  "sage_astra_binary_stars": {
    "mode": "orbit",
    "label": "이중 천체 공전 · 접촉 피해",
    "interval": 0.25,
    "budget": 1.4
  },
  "sage_astra_frozen_stars": {
    "mode": "sigil",
    "label": "표적 냉기 결계",
    "duration": 3.5,
    "count": 1,
    "budget": 0.9
  },
  "sage_astra_supernova_core": {
    "mode": "bombard",
    "label": "초신성 붕괴 · 긴 예고 후 단발 폭발",
    "duration": 1.8,
    "count": 1,
    "budget": 1.8
  },
  "sage_astra_collapsed_seed": {
    "mode": "sigil",
    "label": "표적 중력 별씨",
    "duration": 2.8,
    "count": 1,
    "budget": 1.8
  }
}
static func spec(id: String, _data: Dictionary) -> Dictionary:
	return MODES.get(id,{})
static func description(id: String,data: Dictionary) -> String:
	return String(spec(id,data).get("label",""))
