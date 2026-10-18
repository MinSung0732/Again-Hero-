extends RefCounted
## Real flight/impact rules, not a color variant of a universal homing round.
const SHOTS := {
 "ranged_rookie_arcane_bolt":{"kind":"lance","pierce":2,"label":"직진 관통 마력탄"},
 "ranged_rookie_sealing_bolt":{"kind":"curve","label":"휘어 들어가는 봉인구"},
 "swift_hunter_throwing_knife":{"kind":"return","pierce":3,"label":"전진 후 돌아오는 왕복 단검"},
 "swift_hunter_poison_needle":{"kind":"straight","label":"목표 방향으로 직진하는 독침"},
 "sword_shield_hero_ward_crossbow":{"kind":"lance","pierce":2,"label":"적 전열을 관통하는 중량 쇠뇌"},
 "pistol_hero_revolver":{"kind":"straight","label":"발사 순간 조준 방향을 유지하는 실탄"},
 "pistol_hero_twin_pistols":{"kind":"fan","label":"좌우로 벌어지는 쌍열 사격"},
 "pistol_hero_shrapnel_round":{"kind":"straight","label":"직진 파쇄탄 · 적중 지점 파편"},
 "pistol_hero_ricochet":{"kind":"bounce","bounces":3,"label":"실제 적중 위치에서 인접 적에게 튀는 도탄"},
 "chemical_hero_toxic_dart":{"kind":"straight","label":"직진 촉매 주사탄"},
 "summoner_hero_gate_shard":{"kind":"curve","label":"소환수 전선에서 곡선으로 날아가는 차원 파편"},
 "purifier_hero_holy_bolt":{"kind":"curve","label":"완만한 곡선으로 추적하는 성광탄"}
}
static func spec(id: String) -> Dictionary: return SHOTS.get(id,{})
static func description(id: String) -> String: return String(spec(id).get("label",""))
