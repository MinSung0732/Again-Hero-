extends RefCounted
## Survival delivery only: IDs, cooldowns, milestones, art and native actors stay canonical.
const ORBIT := {"mode":"orbit","label":"지속 회전형 · 회전 개체 접촉 피해","interval":0.18,"budget":1.6}
const MODES := {
	"ranged_rookie_star_wand":{"mode":"sentry","label":"별빛 정령 설치 · 자동 사격","duration":5.5,"count":1},
	"ranged_rookie_pulse_staff":{"mode":"random","label":"맵 무작위 마력 파동 · 고정 지대","duration":3.4,"count":2},
	"ranged_rookie_rune_ring":{"mode":"aura","label":"이동 유지형 · 근거리 마력 성역","duration":4.5,"count":1},
	"swift_hunter_poison_needle":{"mode":"random","label":"맵 무작위 독침 지대","duration":3.0,"count":2},
	"swift_hunter_venom_steps":{"mode":"trail","label":"이동 경로에 남기는 독무","duration":4.6,"count":3},
	"swift_hunter_moon_blade":{"mode":"orbit","label":"지속 회전형 · 주변 검무 접촉 피해","interval":0.18,"budget":1.6},
	"sword_shield_hero_ward_crossbow":{"mode":"sentry","label":"수호 쇠뇌 설치 · 자동 사격","duration":6.0,"count":1},
	"sword_shield_hero_shield_hammer":{"mode":"random","label":"맵 무작위 대지 충격 지대","duration":3.4,"count":2},
	"pistol_hero_grenade":{"mode":"random","label":"맵 무작위 수류탄 폭격 지대","duration":3.0,"count":2},
	"pistol_hero_powder_bomb":{"mode":"trail","label":"발밑에 남기는 지속 화약 지대","duration":4.0,"count":2},
	"pistol_hero_suppressor":{"mode":"sentry","label":"기관권총 거치 · 자동 사격","duration":6.0,"count":1},
	"archmage_hero_earth_staff":{"mode":"random","label":"맵 무작위 대지 가시 지대","duration":4.0,"count":3},
	"archmage_hero_lava_focus":{"mode":"trail","label":"이동 경로에 남기는 용암 지대","duration":5.0,"count":3},
	"archmage_hero_sunfire_tome":{"mode":"sentry","label":"태양 마력체 설치 · 자동 사격","duration":7.0,"count":2},
	"madness_hero_blood_thorns":{"mode":"trail","label":"이동 경로에 남기는 혈흔 가시","duration":5.0,"count":3},
	"madness_hero_heart_chain":{"mode":"sentry","label":"심장 마력체 설치 · 자동 사격","duration":5.0,"count":1},
	"chemical_hero_poison_flask":{"mode":"random","label":"맵 무작위 촉매 반응 지대","duration":4.2,"count":3},
	"chemical_hero_caustic_boots":{"mode":"trail","label":"이동 경로에 남기는 부식 분무","duration":5.0,"count":3},
	"summoner_hero_collapse_glyph":{"mode":"random","label":"맵 무작위 붕괴 문양","duration":4.5,"count":3},
	"purifier_hero_judgment_seal":{"mode":"random","label":"맵 무작위 심판 성역","duration":4.0,"count":3},
	"sage_astra_supernova_core":{"mode":"random","label":"맵 무작위 초신성 지대","duration":4.0,"count":3},
	"sage_astra_collapsed_seed":{"mode":"sentry","label":"붕괴 별씨 설치 · 자동 사격","duration":6.0,"count":2},
}
static func spec(id: String, data: Dictionary) -> Dictionary:
	return MODES.get(id,ORBIT if String(data.get("pattern","")) == "orbit" else {})
static func description(id: String,data: Dictionary) -> String:
	var rule := spec(id,data)
	if rule.is_empty(): return ""
	var text := String(rule.label)
	if String(rule.mode) == "sentry": text += "\n고정 마력 설치체 · 피격 없음 · 무기별 최대 2기"
	if String(rule.mode) == "random": text += "\n0.6초 예고 후 발동 · 생성 지점에 유지"
	return text
