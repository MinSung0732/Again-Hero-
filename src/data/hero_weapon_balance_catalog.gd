extends RefCounted
## Survival-only role budgets; applied after milestones, before passive/research modifiers.
const IDENTITIES := {
  "ranged_rookie": [
    "비전 공명",
    "세 번째 유효 시전이 짧은 공명 파동을 남김. MAX는 대상 위치에 재공명."
  ],
  "swift_hunter": [
    "이동 암살",
    "실제 이동 180px로 기습 충전. 충전 후 근접 시전 강화, MAX는 조건부 마무리."
  ],
  "sword_shield_hero": [
    "정면 방진",
    "정면 검격·창격과 방패가 중심. MAX 방패는 흡수 피해로 반격."
  ],
  "pistol_hero": [
    "화력과 재장전",
    "단일 집중사격·근거리 산탄·도탄·고정 기관총. 넓은 폭격에는 긴 간격."
  ],
  "archmage_hero": [
    "원소 교대",
    "동일 적에게 다른 원소를 맞히면 반응. 동일 원소 틱만으로는 반응하지 않음."
  ],
  "madness_hero": [
    "혈검과 대가",
    "근접 혈검·저체력 증폭·체력 소모/회복. 자동 포대와 회전 개체 제거."
  ],
  "chemical_hero": [
    "시약과 촉매",
    "약병 지대가 시약을 남기고 다른 화학 무기가 촉매 반응. 같은 장판 틱은 중복 반응 없음."
  ],
  "summoner_hero": [
    "군단과 차원문",
    "4종 실체 소환수. 공격용 차원문은 살아있는 소환수 위치에서 발동, MAX 협공."
  ],
  "purifier_hero": [
    "성역과 구원",
    "자리에 남는 성역·정화·보호. 원거리 화력 대신 생존과 근거리 성역 유지."
  ],
  "sage_astra": [
    "천체 제어",
    "긴 예고의 운석·고정 결계·중력장과 유일한 이중 천체 궤도. 큰 범위에는 긴 간격."
  ]
}
const PROFILES := {
  "ranged_rookie_arcane_bolt": {
    "role": "duelist",
    "owner": "ranged_rookie",
    "element": ""
  },
  "ranged_rookie_star_wand": {
    "role": "cleave",
    "owner": "ranged_rookie",
    "element": ""
  },
  "ranged_rookie_magic_lance": {
    "role": "artillery",
    "owner": "ranged_rookie",
    "element": ""
  },
  "ranged_rookie_rune_ring": {
    "role": "field",
    "owner": "ranged_rookie",
    "element": ""
  },
  "ranged_rookie_pulse_staff": {
    "role": "artillery",
    "owner": "ranged_rookie",
    "element": ""
  },
  "ranged_rookie_barrier_book": {
    "role": "support",
    "owner": "ranged_rookie",
    "element": ""
  },
  "swift_hunter_dagger": {
    "role": "duelist",
    "owner": "swift_hunter",
    "element": ""
  },
  "swift_hunter_throwing_knife": {
    "role": "duelist",
    "owner": "swift_hunter",
    "element": ""
  },
  "swift_hunter_shadow_wire": {
    "role": "duelist",
    "owner": "swift_hunter",
    "element": ""
  },
  "swift_hunter_poison_needle": {
    "role": "duelist",
    "owner": "swift_hunter",
    "element": ""
  },
  "swift_hunter_moon_blade": {
    "role": "cleave",
    "owner": "swift_hunter",
    "element": ""
  },
  "swift_hunter_shadow_bomb": {
    "role": "artillery",
    "owner": "swift_hunter",
    "element": ""
  },
  "sword_shield_hero_longsword": {
    "role": "cleave",
    "owner": "sword_shield_hero",
    "element": ""
  },
  "sword_shield_hero_piercing_spear": {
    "role": "artillery",
    "owner": "sword_shield_hero",
    "element": ""
  },
  "sword_shield_hero_aegis": {
    "role": "support",
    "owner": "sword_shield_hero",
    "element": ""
  },
  "sword_shield_hero_shield_hammer": {
    "role": "cleave",
    "owner": "sword_shield_hero",
    "element": ""
  },
  "sword_shield_hero_blade_ring": {
    "role": "cleave",
    "owner": "sword_shield_hero",
    "element": ""
  },
  "sword_shield_hero_battle_banner": {
    "role": "support",
    "owner": "sword_shield_hero",
    "element": ""
  },
  "pistol_hero_revolver": {
    "role": "duelist",
    "owner": "pistol_hero",
    "element": ""
  },
  "pistol_hero_shotgun": {
    "role": "cleave",
    "owner": "pistol_hero",
    "element": ""
  },
  "pistol_hero_rifle": {
    "role": "duelist",
    "owner": "pistol_hero",
    "element": ""
  },
  "pistol_hero_ricochet": {
    "role": "cleave",
    "owner": "pistol_hero",
    "element": ""
  },
  "pistol_hero_grenade": {
    "role": "artillery",
    "owner": "pistol_hero",
    "element": ""
  },
  "pistol_hero_powder_bomb": {
    "role": "field",
    "owner": "pistol_hero",
    "element": ""
  },
  "archmage_hero_fire_staff": {
    "role": "duelist",
    "owner": "archmage_hero",
    "element": "fire"
  },
  "archmage_hero_ice_scepter": {
    "role": "control",
    "owner": "archmage_hero",
    "element": "ice"
  },
  "archmage_hero_lightning_rod": {
    "role": "cleave",
    "owner": "archmage_hero",
    "element": "lightning"
  },
  "archmage_hero_earth_staff": {
    "role": "artillery",
    "owner": "archmage_hero",
    "element": "earth"
  },
  "archmage_hero_storm_orb": {
    "role": "artillery",
    "owner": "archmage_hero",
    "element": "lightning"
  },
  "archmage_hero_prism_wand": {
    "role": "artillery",
    "owner": "archmage_hero",
    "element": "arcane"
  },
  "madness_hero_blood_sword": {
    "role": "duelist",
    "owner": "madness_hero",
    "element": ""
  },
  "madness_hero_blood_lance": {
    "role": "artillery",
    "owner": "madness_hero",
    "element": ""
  },
  "madness_hero_blood_wheel": {
    "role": "cleave",
    "owner": "madness_hero",
    "element": ""
  },
  "madness_hero_blood_burst": {
    "role": "artillery",
    "owner": "madness_hero",
    "element": ""
  },
  "madness_hero_drain_blade": {
    "role": "cleave",
    "owner": "madness_hero",
    "element": ""
  },
  "madness_hero_heart_chain": {
    "role": "cleave",
    "owner": "madness_hero",
    "element": ""
  },
  "chemical_hero_acid_vial": {
    "role": "field",
    "owner": "chemical_hero",
    "element": "reagent"
  },
  "chemical_hero_poison_flask": {
    "role": "field",
    "owner": "chemical_hero",
    "element": "reagent"
  },
  "chemical_hero_cryo_vial": {
    "role": "control",
    "owner": "chemical_hero",
    "element": "catalyst"
  },
  "chemical_hero_reaction_bomb": {
    "role": "artillery",
    "owner": "chemical_hero",
    "element": "catalyst"
  },
  "chemical_hero_acid_cannon": {
    "role": "artillery",
    "owner": "chemical_hero",
    "element": "catalyst"
  },
  "chemical_hero_life_elixir": {
    "role": "support",
    "owner": "chemical_hero",
    "element": "catalyst"
  },
  "summoner_hero_gate_hound": {
    "role": "summon",
    "owner": "summoner_hero",
    "element": ""
  },
  "summoner_hero_watcher": {
    "role": "summon",
    "owner": "summoner_hero",
    "element": ""
  },
  "summoner_hero_scout": {
    "role": "summon",
    "owner": "summoner_hero",
    "element": ""
  },
  "summoner_hero_gate_laser": {
    "role": "artillery",
    "owner": "summoner_hero",
    "element": ""
  },
  "summoner_hero_gatekeeper": {
    "role": "summon",
    "owner": "summoner_hero",
    "element": ""
  },
  "summoner_hero_rift_pulse": {
    "role": "artillery",
    "owner": "summoner_hero",
    "element": ""
  },
  "purifier_hero_holy_bolt": {
    "role": "duelist",
    "owner": "purifier_hero",
    "element": ""
  },
  "purifier_hero_holy_lance": {
    "role": "artillery",
    "owner": "purifier_hero",
    "element": ""
  },
  "purifier_hero_purification": {
    "role": "artillery",
    "owner": "purifier_hero",
    "element": ""
  },
  "purifier_hero_sacred_orb": {
    "role": "field",
    "owner": "purifier_hero",
    "element": ""
  },
  "purifier_hero_blessing": {
    "role": "support",
    "owner": "purifier_hero",
    "element": ""
  },
  "purifier_hero_prayer": {
    "role": "support",
    "owner": "purifier_hero",
    "element": ""
  },
  "sage_astra_starlight": {
    "role": "duelist",
    "owner": "sage_astra",
    "element": ""
  },
  "sage_astra_comet": {
    "role": "artillery",
    "owner": "sage_astra",
    "element": ""
  },
  "sage_astra_astral_chain": {
    "role": "cleave",
    "owner": "sage_astra",
    "element": ""
  },
  "sage_astra_absolute_zero": {
    "role": "control",
    "owner": "sage_astra",
    "element": ""
  },
  "sage_astra_singularity": {
    "role": "control",
    "owner": "sage_astra",
    "element": ""
  },
  "sage_astra_binary_stars": {
    "role": "orbit",
    "owner": "sage_astra",
    "element": ""
  },
  "ranged_rookie_sealing_bolt": {
    "role": "duelist",
    "owner": "ranged_rookie",
    "element": ""
  },
  "ranged_rookie_satellite_orbs": {
    "role": "orbit",
    "owner": "ranged_rookie",
    "element": ""
  },
  "ranged_rookie_rune_ray": {
    "role": "artillery",
    "owner": "ranged_rookie",
    "element": ""
  },
  "ranged_rookie_restoration_codex": {
    "role": "support",
    "owner": "ranged_rookie",
    "element": ""
  },
  "swift_hunter_execution_stiletto": {
    "role": "duelist",
    "owner": "swift_hunter",
    "element": ""
  },
  "swift_hunter_binding_wire": {
    "role": "cleave",
    "owner": "swift_hunter",
    "element": ""
  },
  "swift_hunter_smoke_mantle": {
    "role": "support",
    "owner": "swift_hunter",
    "element": ""
  },
  "swift_hunter_venom_steps": {
    "role": "field",
    "owner": "swift_hunter",
    "element": ""
  },
  "sword_shield_hero_oath_blade": {
    "role": "cleave",
    "owner": "sword_shield_hero",
    "element": ""
  },
  "sword_shield_hero_ward_crossbow": {
    "role": "duelist",
    "owner": "sword_shield_hero",
    "element": ""
  },
  "sword_shield_hero_sanctuary_shield": {
    "role": "support",
    "owner": "sword_shield_hero",
    "element": ""
  },
  "sword_shield_hero_rally_standard": {
    "role": "support",
    "owner": "sword_shield_hero",
    "element": ""
  },
  "pistol_hero_twin_pistols": {
    "role": "duelist",
    "owner": "pistol_hero",
    "element": ""
  },
  "pistol_hero_shrapnel_round": {
    "role": "duelist",
    "owner": "pistol_hero",
    "element": ""
  },
  "pistol_hero_suppressor": {
    "role": "duelist",
    "owner": "pistol_hero",
    "element": ""
  },
  "pistol_hero_smoke_canister": {
    "role": "field",
    "owner": "pistol_hero",
    "element": ""
  },
  "archmage_hero_lava_focus": {
    "role": "field",
    "owner": "archmage_hero",
    "element": "fire"
  },
  "archmage_hero_frost_moons": {
    "role": "control",
    "owner": "archmage_hero",
    "element": "ice"
  },
  "archmage_hero_gale_prism": {
    "role": "artillery",
    "owner": "archmage_hero",
    "element": "arcane"
  },
  "archmage_hero_sunfire_tome": {
    "role": "artillery",
    "owner": "archmage_hero",
    "element": "fire"
  },
  "madness_hero_desperate_cleaver": {
    "role": "cleave",
    "owner": "madness_hero",
    "element": ""
  },
  "madness_hero_vampire_fang": {
    "role": "duelist",
    "owner": "madness_hero",
    "element": ""
  },
  "madness_hero_blood_thorns": {
    "role": "field",
    "owner": "madness_hero",
    "element": ""
  },
  "madness_hero_blood_aegis": {
    "role": "support",
    "owner": "madness_hero",
    "element": ""
  },
  "chemical_hero_caustic_boots": {
    "role": "field",
    "owner": "chemical_hero",
    "element": "reagent"
  },
  "chemical_hero_catalyst_wire": {
    "role": "cleave",
    "owner": "chemical_hero",
    "element": "catalyst"
  },
  "chemical_hero_toxic_dart": {
    "role": "duelist",
    "owner": "chemical_hero",
    "element": "catalyst"
  },
  "chemical_hero_antidote_capsule": {
    "role": "support",
    "owner": "chemical_hero",
    "element": "catalyst"
  },
  "summoner_hero_rift_orbit": {
    "role": "cleave",
    "owner": "summoner_hero",
    "element": ""
  },
  "summoner_hero_collapse_glyph": {
    "role": "field",
    "owner": "summoner_hero",
    "element": ""
  },
  "summoner_hero_gate_shard": {
    "role": "duelist",
    "owner": "summoner_hero",
    "element": ""
  },
  "summoner_hero_binding_gate": {
    "role": "control",
    "owner": "summoner_hero",
    "element": ""
  },
  "purifier_hero_mercy_chain": {
    "role": "cleave",
    "owner": "purifier_hero",
    "element": ""
  },
  "purifier_hero_judgment_seal": {
    "role": "field",
    "owner": "purifier_hero",
    "element": ""
  },
  "purifier_hero_saint_reliquary": {
    "role": "support",
    "owner": "purifier_hero",
    "element": ""
  },
  "purifier_hero_martyr_blade": {
    "role": "cleave",
    "owner": "purifier_hero",
    "element": ""
  },
  "sage_astra_gravity_lance": {
    "role": "artillery",
    "owner": "sage_astra",
    "element": ""
  },
  "sage_astra_frozen_stars": {
    "role": "field",
    "owner": "sage_astra",
    "element": ""
  },
  "sage_astra_supernova_core": {
    "role": "artillery",
    "owner": "sage_astra",
    "element": ""
  },
  "sage_astra_collapsed_seed": {
    "role": "duelist",
    "owner": "sage_astra",
    "element": ""
  }
}
static func apply(id: String,data: Dictionary,rank: int,awakened: bool) -> void:
	var profile: Dictionary = PROFILES[id]
	data["weapon_id"] = id; data["kit_element"] = profile.element
	data["damage_scale"] = 1.0+0.16*(rank-1)
	data["reach_scale"] = 1.0+0.018*(rank-1)
	data["cooldown_scale"] = 1.0-0.022*(rank-1)
	if awakened: data.damage_scale *= 1.25; data.cooldown_scale *= 0.95
	# Prevent damage/count/tick/area stacking from multiplying every growth axis.
	data["bonus_hits"] = mini(int(data.get("bonus_hits",0)),3 if awakened else 2)
	data["chain_growth"] = minf(float(data.get("chain_growth",0.0)),0.06)
	data["pulse_count"] = mini(int(data.get("pulse_count",0)),1)
	data["pulse_ratio"] = minf(float(data.get("pulse_ratio",0.0)),0.35)
	data["pulse_radius_ratio"] = minf(float(data.get("pulse_radius_ratio",0.6)),0.65)
	data["splash_ratio"] = minf(float(data.get("splash_ratio",0.0)),0.2)
	data["splash_radius"] = minf(float(data.get("splash_radius",70.0)),90.0)
	data["fan_lines"] = mini(int(data.get("fan_lines",1)),3)
	data["lifesteal"] = minf(float(data.get("lifesteal",0.0)),0.05)
	data["execute_ratio"] = minf(float(data.get("execute_ratio",0.0)),0.10)
	data["low_hp_bonus"] = minf(float(data.get("low_hp_bonus",0.0)),0.65)
	if String(data.pattern) == "poison":
		data["field_duration"] = minf(float(data.get("field_duration",3.0)),4.5)
		data["field_interval"] = maxf(float(data.get("field_interval",0.5)),0.4)
		data["field_count"] = mini(int(data.get("field_count",1)),2)
		data["field_radius_ratio"] = minf(float(data.get("field_radius_ratio",0.42)),0.5)
	if String(data.pattern) in ["guard","heal"]:
		data["pulse_count"] = 0
		data["cast_heal"] = minf(float(data.get("cast_heal",0.0)),0.02)
		data["cast_shield"] = minf(float(data.get("cast_shield",0.0)),0.04)
	if String(data.pattern) == "orbit": data["pulse_count"] = 0
	# Budget all rounds in a cast, including combo finishers. Quantity is coverage/frequency,
	# not permission to multiply full unbounded per-shot damage at every milestone.
	if String(profile.role) == "duelist":
		var rounds := maxi(1,int(data.get("base_hits",1))+int(data.get("bonus_hits",0)))
		if String(data.pattern) in ["combo","burst"]: rounds = mini(rounds,6)
		var cadence := float(data.cooldown)*float(data.cooldown_scale)
		var budget := (2.0+rank*.25) if String(data.pattern) == "combo" else (1.5+rank*.22)
		if awakened: budget *= 1.2
		var nominal := float(data.power)*float(data.damage_scale)*(rounds+float(data.get("finish_ratio",0.0)))/cadence
		if nominal > budget: data.power *= budget/nominal
	data["kit_description"] = String(IDENTITIES[profile.owner][1])
static func description(id: String) -> String:
	return String(IDENTITIES[PROFILES[id].owner][0])+" · "+String(IDENTITIES[PROFILES[id].owner][1])
