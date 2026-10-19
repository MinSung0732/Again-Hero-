extends RefCounted
## Role presentation only; no combat IDs or timing rules duplicated here.
const THEMES := {
	"hero": {"art":"res://assets/art/UI/online_match/hero_gateway.png", "name":"용사", "tag":"성문 너머, 다음 도전", "accent":Color("87dfff"), "hint":"몬스터의 움직임을 살피고, 나만의 빌드를 완성하세요."},
	"demon": {"art":"res://assets/art/UI/online_match/demon_chamber.png", "name":"마왕", "tag":"이번 실험은 다를 것이다", "accent":Color("e8a2fa"), "hint":"용사의 빌드를 관찰하고, 카운터 군단으로 대응하세요."},
}
const PARTICLES := 20
const PARTICLE_SPEED := 0.065
const SPIN_SPEED := 0.9
const PREPARE_BUDGET_US := 4000
const CARPETS := ["rug_long", "rug_torn_1", "rug_torn_2", "rug_torn_3", "rug_torn_4"]
static func theme(role: String) -> Dictionary:
	return THEMES.get(role,THEMES.hero)
