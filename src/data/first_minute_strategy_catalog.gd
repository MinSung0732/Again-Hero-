extends RefCounted
## Presentation suggestions, never forced AI choices or combat bonuses.
const ROLE_TIPS := {
	"swarm":"물량은 용사를 성장시킵니다. 선택을 본 뒤 공세를 바꿔 보세요.",
	"controller":"둔화로 접근 시간을 만듭니다. 탱커나 화력을 이어 보내세요.",
	"control":"둔화로 접근 시간을 만듭니다. 탱커나 화력을 이어 보내세요.",
	"tank":"공격을 받아 줄 전선입니다. 다른 몬스터의 화력을 붙이세요.",
	"ranged":"탱커가 앞서 접근하면 뒤에서 지속 화력을 보내세요.",
	"exploder":"용사가 가까이 왔을 때 폭발을 맞힐 기회를 만드세요.",
	"burst":"짧은 공격 기회를 노리세요. 제어 몬스터와 함께 시험하세요.",
}
const RESPONSE_ROLES := {
	"area":["tank","ranged"],
	"reload":["exploder","burst","swarm"],
	"recovery":["ranged","exploder","burst"],
	"mobility":["controller","control"],
	"evasion":["controller","control","ranged"],
	"durability":["ranged","exploder","burst"],
	"projectile":["tank","controller","control"],
	"attack_speed":["tank","ranged"],
	"damage":["tank","controller","control"],
}
const GOAL := "목표 · 몬스터를 소환해 용사 HP를 0으로"
const LOOP := "내 공세 → 용사 성장·선택 → 다른 조합 시험"
static func role_tip(role: String) -> String:
	return String(ROLE_TIPS.get(role,"역할이 다른 몬스터를 함께 보내 조합을 시험하세요."))
