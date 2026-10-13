extends RefCounted
const MAX_LEVEL := 10
const WEAPON_SLOTS := 3
const PASSIVE_SLOTS := 3
const STARTERS := {
  "ranged_rookie": "weapon_basic_ranged_rookie",
  "archmage_hero": "weapon_basic_archmage_hero",
  "swift_hunter": "weapon_basic_swift_hunter",
  "pistol_hero": "weapon_basic_pistol_hero",
  "sword_shield_hero": "weapon_basic_sword_shield_hero",
  "madness_hero": "weapon_basic_madness_hero",
  "chemical_hero": "weapon_basic_chemical_hero",
  "purifier_hero": "weapon_basic_purifier_hero",
  "summoner_hero": "weapon_basic_summoner_hero",
  "sage_astra": "weapon_basic_sage_astra"
}
const WEAPONS := {
  "weapon_basic_ranged_rookie": {
    "name": "마력탄",
    "owner": "ranged_rookie",
    "pattern": "bolt",
    "color": "85dcff",
    "cooldown": 1.0,
    "range": 620,
    "power": 1.0,
    "evolution": "마력탄 · 각성",
    "tags": [
      "damage"
    ]
  },
  "arcane_piercer": {
    "name": "마력 관통포",
    "owner": "ranged_rookie",
    "pattern": "beam",
    "color": "ffe09a",
    "cooldown": 3.0,
    "range": 800,
    "power": 1.22,
    "evolution": "마력 관통포 · 각성",
    "tags": [
      "damage"
    ]
  },
  "arcane_barrier": {
    "name": "마력 장벽",
    "owner": "ranged_rookie",
    "pattern": "guard",
    "color": "cee2ff",
    "cooldown": 9.0,
    "range": 250,
    "power": 1.44,
    "evolution": "마력 장벽 · 각성",
    "tags": [
      "durability"
    ]
  },
  "arcane_field": {
    "name": "비전 집중",
    "owner": "ranged_rookie",
    "pattern": "poison",
    "color": "a2d766",
    "cooldown": 2.2,
    "range": 350,
    "power": 1.0,
    "evolution": "비전 집중 · 각성",
    "tags": [
      "area"
    ]
  },
  "weapon_basic_archmage_hero": {
    "name": "원소탄",
    "owner": "archmage_hero",
    "pattern": "bolt",
    "color": "85dcff",
    "cooldown": 1.0,
    "range": 620,
    "power": 1.0,
    "evolution": "원소탄 · 각성",
    "tags": [
      "damage"
    ]
  },
  "archmage_combustion": {
    "name": "연소",
    "owner": "archmage_hero",
    "pattern": "nova",
    "color": "bb95f1",
    "cooldown": 3.2,
    "range": 240,
    "power": 1.22,
    "evolution": "연소 · 각성",
    "tags": [
      "area"
    ]
  },
  "archmage_ice_bolt": {
    "name": "아이스볼트",
    "owner": "archmage_hero",
    "pattern": "frost",
    "color": "9dcdf7",
    "cooldown": 2.5,
    "range": 420,
    "power": 1.44,
    "evolution": "아이스볼트 · 각성",
    "tags": [
      "damage"
    ]
  },
  "archmage_earth_spikes": {
    "name": "땅의 가시",
    "owner": "archmage_hero",
    "pattern": "beam",
    "color": "ffe09a",
    "cooldown": 3.0,
    "range": 800,
    "power": 1.0,
    "evolution": "땅의 가시 · 각성",
    "tags": [
      "damage"
    ]
  },
  "archmage_holy_power": {
    "name": "신성력",
    "owner": "archmage_hero",
    "pattern": "heal",
    "color": "efbdcf",
    "cooldown": 12.0,
    "range": 280,
    "power": 1.22,
    "evolution": "신성력 · 각성",
    "tags": [
      "durability"
    ]
  },
  "archmage_chain_dagger": {
    "name": "체인대거",
    "owner": "archmage_hero",
    "pattern": "chain",
    "color": "a9eece",
    "cooldown": 2.1,
    "range": 550,
    "power": 1.44,
    "evolution": "체인대거 · 각성",
    "tags": [
      "damage"
    ]
  },
  "archmage_harmony": {
    "name": "조화",
    "owner": "archmage_hero",
    "pattern": "orbit",
    "color": "8adcc5",
    "cooldown": 1.5,
    "range": 300,
    "power": 1.0,
    "evolution": "조화 · 각성",
    "tags": [
      "area"
    ]
  },
  "archmage_storm": {
    "name": "폭풍",
    "owner": "archmage_hero",
    "pattern": "nova",
    "color": "bb95f1",
    "cooldown": 3.2,
    "range": 240,
    "power": 1.22,
    "evolution": "폭풍 · 각성",
    "tags": [
      "area"
    ]
  },
  "weapon_basic_swift_hunter": {
    "name": "단검",
    "owner": "swift_hunter",
    "pattern": "slash",
    "color": "f1a78e",
    "cooldown": 1.3,
    "range": 200,
    "power": 1.0,
    "evolution": "단검 · 각성",
    "tags": [
      "damage"
    ]
  },
  "blade_storm": {
    "name": "난도질",
    "owner": "swift_hunter",
    "pattern": "nova",
    "color": "bb95f1",
    "cooldown": 3.2,
    "range": 240,
    "power": 1.22,
    "evolution": "난도질 · 각성",
    "tags": [
      "area"
    ]
  },
  "shadow_assassination": {
    "name": "급습-암살",
    "owner": "swift_hunter",
    "pattern": "slash",
    "color": "f1a78e",
    "cooldown": 1.3,
    "range": 200,
    "power": 1.44,
    "evolution": "급습-암살 · 각성",
    "tags": [
      "damage"
    ]
  },
  "weapon_basic_pistol_hero": {
    "name": "권총탄",
    "owner": "pistol_hero",
    "pattern": "bolt",
    "color": "ffe09a",
    "cooldown": 1.0,
    "range": 620,
    "power": 1.0,
    "evolution": "권총탄 · 각성",
    "tags": [
      "damage"
    ]
  },
  "gunner_cylinder": {
    "name": "실린더 충격",
    "owner": "pistol_hero",
    "pattern": "bolt",
    "color": "85dcff",
    "cooldown": 1.0,
    "range": 620,
    "power": 1.22,
    "evolution": "실린더 충격 · 각성",
    "tags": [
      "damage"
    ]
  },
  "gunner_deadeye": {
    "name": "데드아이",
    "owner": "pistol_hero",
    "pattern": "beam",
    "color": "ffe09a",
    "cooldown": 3.0,
    "range": 800,
    "power": 1.44,
    "evolution": "데드아이 · 각성",
    "tags": [
      "damage"
    ]
  },
  "gunner_fanning_weapon": {
    "name": "패닝 연사",
    "owner": "pistol_hero",
    "pattern": "beam",
    "color": "ffe09a",
    "cooldown": 3.0,
    "range": 800,
    "power": 1.0,
    "evolution": "패닝 연사 · 각성",
    "tags": [
      "damage"
    ]
  },
  "weapon_basic_sword_shield_hero": {
    "name": "검격",
    "owner": "sword_shield_hero",
    "pattern": "guard",
    "color": "cee2ff",
    "cooldown": 9.0,
    "range": 250,
    "power": 1.0,
    "evolution": "검격 · 각성",
    "tags": [
      "durability"
    ]
  },
  "shield_charge": {
    "name": "검방 돌격",
    "owner": "sword_shield_hero",
    "pattern": "guard",
    "color": "cee2ff",
    "cooldown": 9.0,
    "range": 250,
    "power": 1.22,
    "evolution": "검방 돌격 · 각성",
    "tags": [
      "durability"
    ]
  },
  "shield_guard": {
    "name": "막기",
    "owner": "sword_shield_hero",
    "pattern": "guard",
    "color": "cee2ff",
    "cooldown": 9.0,
    "range": 250,
    "power": 1.44,
    "evolution": "막기 · 각성",
    "tags": [
      "durability"
    ]
  },
  "weapon_basic_madness_hero": {
    "name": "혈검",
    "owner": "madness_hero",
    "pattern": "slash",
    "color": "f1a78e",
    "cooldown": 1.3,
    "range": 200,
    "power": 1.0,
    "evolution": "혈검 · 각성",
    "tags": [
      "damage"
    ]
  },
  "blood_sword_first": {
    "name": "혈검술 제1식",
    "owner": "madness_hero",
    "pattern": "bolt",
    "color": "85dcff",
    "cooldown": 1.0,
    "range": 620,
    "power": 1.22,
    "evolution": "혈검술 제1식 · 각성",
    "tags": [
      "damage"
    ]
  },
  "blood_sword_second": {
    "name": "혈검술 제2식",
    "owner": "madness_hero",
    "pattern": "slash",
    "color": "f1a78e",
    "cooldown": 1.3,
    "range": 200,
    "power": 1.44,
    "evolution": "혈검술 제2식 · 각성",
    "tags": [
      "damage"
    ]
  },
  "blood_sword_third": {
    "name": "혈검술 제3식",
    "owner": "madness_hero",
    "pattern": "beam",
    "color": "ffe09a",
    "cooldown": 3.0,
    "range": 800,
    "power": 1.0,
    "evolution": "혈검술 제3식 · 각성",
    "tags": [
      "damage"
    ]
  },
  "blood_sword_fourth": {
    "name": "혈검술 제4식",
    "owner": "madness_hero",
    "pattern": "nova",
    "color": "bb95f1",
    "cooldown": 3.2,
    "range": 240,
    "power": 1.22,
    "evolution": "혈검술 제4식 · 각성",
    "tags": [
      "area"
    ]
  },
  "weapon_basic_chemical_hero": {
    "name": "연금술 약병",
    "owner": "chemical_hero",
    "pattern": "poison",
    "color": "a2d766",
    "cooldown": 2.2,
    "range": 350,
    "power": 1.0,
    "evolution": "연금술 약병 · 각성",
    "tags": [
      "damage"
    ]
  },
  "alchemist_catalyst_field": {
    "name": "촉매 혼합장",
    "owner": "chemical_hero",
    "pattern": "poison",
    "color": "a2d766",
    "cooldown": 2.2,
    "range": 350,
    "power": 1.22,
    "evolution": "촉매 혼합장 · 각성",
    "tags": [
      "area"
    ]
  },
  "alchemist_mystery_cauldron": {
    "name": "무엇이 나올까요?",
    "owner": "chemical_hero",
    "pattern": "poison",
    "color": "a2d766",
    "cooldown": 2.2,
    "range": 350,
    "power": 1.44,
    "evolution": "무엇이 나올까요? · 각성",
    "tags": [
      "area"
    ]
  },
  "alchemist_today_failed_again": {
    "name": "오늘도 실팬가!",
    "owner": "chemical_hero",
    "pattern": "beam",
    "color": "ffe09a",
    "cooldown": 3.0,
    "range": 800,
    "power": 1.0,
    "evolution": "오늘도 실팬가! · 각성",
    "tags": [
      "damage"
    ]
  },
  "alchemist_philosopher_stone": {
    "name": "현자의 돌",
    "owner": "chemical_hero",
    "pattern": "heal",
    "color": "efbdcf",
    "cooldown": 12.0,
    "range": 280,
    "power": 1.22,
    "evolution": "현자의 돌 · 각성",
    "tags": [
      "durability"
    ]
  },
  "weapon_basic_purifier_hero": {
    "name": "성광탄",
    "owner": "purifier_hero",
    "pattern": "bolt",
    "color": "85dcff",
    "cooldown": 1.0,
    "range": 620,
    "power": 1.0,
    "evolution": "성광탄 · 각성",
    "tags": [
      "damage"
    ]
  },
  "purifier_divine_protection": {
    "name": "신성보호",
    "owner": "purifier_hero",
    "pattern": "guard",
    "color": "cee2ff",
    "cooldown": 9.0,
    "range": 250,
    "power": 1.22,
    "evolution": "신성보호 · 각성",
    "tags": [
      "durability"
    ]
  },
  "purifier_crown_of_courage": {
    "name": "용기의 왕관",
    "owner": "purifier_hero",
    "pattern": "guard",
    "color": "cee2ff",
    "cooldown": 9.0,
    "range": 250,
    "power": 1.44,
    "evolution": "용기의 왕관 · 각성",
    "tags": [
      "durability"
    ]
  },
  "purifier_purification_orb": {
    "name": "정화의 구체",
    "owner": "purifier_hero",
    "pattern": "orbit",
    "color": "8adcc5",
    "cooldown": 1.5,
    "range": 300,
    "power": 1.0,
    "evolution": "정화의 구체 · 각성",
    "tags": [
      "area"
    ]
  },
  "purifier_cleansing": {
    "name": "정화",
    "owner": "purifier_hero",
    "pattern": "nova",
    "color": "bb95f1",
    "cooldown": 3.2,
    "range": 240,
    "power": 1.22,
    "evolution": "정화 · 각성",
    "tags": [
      "area"
    ]
  },
  "purifier_gungnir": {
    "name": "궁그닐",
    "owner": "purifier_hero",
    "pattern": "beam",
    "color": "ffe09a",
    "cooldown": 3.0,
    "range": 800,
    "power": 1.44,
    "evolution": "궁그닐 · 각성",
    "tags": [
      "damage"
    ]
  },
  "weapon_basic_summoner_hero": {
    "name": "이계 수호체",
    "owner": "summoner_hero",
    "pattern": "orbit",
    "color": "8adcc5",
    "cooldown": 1.5,
    "range": 300,
    "power": 1.0,
    "evolution": "이계 수호체 · 각성",
    "tags": [
      "area"
    ]
  },
  "summoner_full_slot_shield": {
    "name": "포화 방벽",
    "owner": "summoner_hero",
    "pattern": "guard",
    "color": "cee2ff",
    "cooldown": 9.0,
    "range": 250,
    "power": 1.22,
    "evolution": "포화 방벽 · 각성",
    "tags": [
      "durability"
    ]
  },
  "summoner_gatekeeper": {
    "name": "이계의 문 - 문지기",
    "owner": "summoner_hero",
    "pattern": "orbit",
    "color": "8adcc5",
    "cooldown": 1.5,
    "range": 300,
    "power": 1.44,
    "evolution": "이계의 문 - 문지기 · 각성",
    "tags": [
      "area"
    ]
  },
  "summoner_scout": {
    "name": "이계의 문 - 정찰병",
    "owner": "summoner_hero",
    "pattern": "orbit",
    "color": "8adcc5",
    "cooldown": 1.5,
    "range": 300,
    "power": 1.0,
    "evolution": "이계의 문 - 정찰병 · 각성",
    "tags": [
      "area"
    ]
  },
  "summoner_hound": {
    "name": "이계의 문 - 투견",
    "owner": "summoner_hero",
    "pattern": "orbit",
    "color": "8adcc5",
    "cooldown": 1.5,
    "range": 300,
    "power": 1.22,
    "evolution": "이계의 문 - 투견 · 각성",
    "tags": [
      "area"
    ]
  },
  "summoner_watcher": {
    "name": "이계의 문 - 감시자",
    "owner": "summoner_hero",
    "pattern": "orbit",
    "color": "8adcc5",
    "cooldown": 1.5,
    "range": 300,
    "power": 1.44,
    "evolution": "이계의 문 - 감시자 · 각성",
    "tags": [
      "area"
    ]
  },
  "summoner_open_gate": {
    "name": "이계의 문 - 개방",
    "owner": "summoner_hero",
    "pattern": "orbit",
    "color": "8adcc5",
    "cooldown": 1.5,
    "range": 300,
    "power": 1.0,
    "evolution": "이계의 문 - 개방 · 각성",
    "tags": [
      "area"
    ]
  },
  "weapon_basic_sage_astra": {
    "name": "별빛탄",
    "owner": "sage_astra",
    "pattern": "bolt",
    "color": "85dcff",
    "cooldown": 1.0,
    "range": 620,
    "power": 1.0,
    "evolution": "별빛탄 · 각성",
    "tags": [
      "damage"
    ]
  },
  "freezing_point_explosion": {
    "name": "빙점폭발",
    "owner": "sage_astra",
    "pattern": "frost",
    "color": "9dcdf7",
    "cooldown": 2.5,
    "range": 420,
    "power": 1.22,
    "evolution": "빙점폭발 · 각성",
    "tags": [
      "damage"
    ]
  },
  "radiance_singularity": {
    "name": "광휘의 특이점",
    "owner": "sage_astra",
    "pattern": "slash",
    "color": "f1a78e",
    "cooldown": 1.3,
    "range": 200,
    "power": 1.44,
    "evolution": "광휘의 특이점 · 각성",
    "tags": [
      "damage"
    ]
  },
  "mana_condensation": {
    "name": "마력응축",
    "owner": "sage_astra",
    "pattern": "heal",
    "color": "efbdcf",
    "cooldown": 12.0,
    "range": 280,
    "power": 1.0,
    "evolution": "마력응축 · 각성",
    "tags": [
      "durability"
    ]
  },
  "starlight": {
    "name": "스타라이트",
    "owner": "sage_astra",
    "pattern": "nova",
    "color": "bb95f1",
    "cooldown": 3.2,
    "range": 240,
    "power": 1.22,
    "evolution": "스타라이트 · 각성",
    "tags": [
      "area"
    ]
  },
  "annihilation": {
    "name": "소멸",
    "owner": "sage_astra",
    "pattern": "beam",
    "color": "ffe09a",
    "cooldown": 3.0,
    "range": 800,
    "power": 1.44,
    "evolution": "소멸 · 각성",
    "tags": [
      "damage"
    ]
  },
  "black_spot_explosion": {
    "name": "흑점폭발",
    "owner": "sage_astra",
    "pattern": "nova",
    "color": "bb95f1",
    "cooldown": 3.2,
    "range": 240,
    "power": 1.0,
    "evolution": "흑점폭발 · 각성",
    "tags": [
      "area"
    ]
  }
}
const PASSIVES := {
  "survival_power": {
    "name": "전투 숙련",
    "description": "전체 무기 피해 +8% / 레벨"
  },
  "survival_haste": {
    "name": "속사 훈련",
    "description": "전체 무기 재사용 대기시간 -4% / 레벨"
  },
  "survival_vitality": {
    "name": "생명력",
    "description": "최대 HP +5% · 증가분 회복 / 레벨"
  },
  "survival_mobility": {
    "name": "기동력",
    "description": "이동속도 +3% / 레벨"
  },
  "survival_learning": {
    "name": "경험치 수련",
    "description": "획득 경험치 +8% / 레벨"
  }
}
static func is_weapon(id: String) -> bool:
	return WEAPONS.has(id)
static func weapon_pool() -> Array:
	return WEAPONS.keys()
static func description(id: String, next_level: int) -> String:
	if PASSIVES.has(id): return String(PASSIVES[id].description)
	var data: Dictionary = WEAPONS.get(id,{})
	var modes := {"bolt":"표적 투사 공격", "slash":"전방 부채꼴 검격", "beam":"관통 직선 공격", "nova":"주변 광역 폭발", "chain":"다수 표적 연쇄 공격", "orbit":"회전 수호체 공격", "guard":"보호막과 충격파", "poison":"독성 장판 연속 피해", "frost":"냉기 폭발과 둔화", "heal":"회복과 신성 파동"}
	return "%s\n피해·범위·빈도 성장 / Lv.5 타격 수 증가 / Lv.10 상자 진화 가능\n선택 후 Lv.%d / 10" % [modes.get(data.get("pattern","bolt"),"무기 공격"),next_level]
static func profile_for_survival(source: Dictionary) -> Dictionary:
	var result := source.duplicate(true)
	result["max_hp"] = 1200
	result["attack_damage"] = 26
	result["move_speed"] = 270.0
	result["level_growth"] = {}
	return result
