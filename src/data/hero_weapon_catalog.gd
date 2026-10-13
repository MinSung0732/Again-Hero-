extends RefCounted
const MAX_LEVEL := 10
const WEAPON_SLOTS := 3
const PASSIVE_SLOTS := 6
const SUMMON_LIMIT := 3
const SUMMON_DAMAGE_RATIO := 0.30
const SUMMON_HP_RATIO := 0.35
const STARTERS := {
  "ranged_rookie": "ranged_rookie_arcane_bolt",
  "swift_hunter": "swift_hunter_dagger",
  "sword_shield_hero": "sword_shield_hero_longsword",
  "pistol_hero": "pistol_hero_revolver",
  "archmage_hero": "archmage_hero_fire_staff",
  "madness_hero": "madness_hero_blood_sword",
  "chemical_hero": "chemical_hero_acid_vial",
  "summoner_hero": "summoner_hero_gate_hound",
  "purifier_hero": "purifier_hero_holy_bolt",
  "sage_astra": "sage_astra_starlight"
}
const HERO_WEAPONS := {
  "ranged_rookie": [
    "ranged_rookie_arcane_bolt",
    "ranged_rookie_star_wand",
    "ranged_rookie_magic_lance",
    "ranged_rookie_rune_ring",
    "ranged_rookie_pulse_staff",
    "ranged_rookie_barrier_book"
  ],
  "swift_hunter": [
    "swift_hunter_dagger",
    "swift_hunter_throwing_knife",
    "swift_hunter_shadow_wire",
    "swift_hunter_poison_needle",
    "swift_hunter_moon_blade",
    "swift_hunter_shadow_bomb"
  ],
  "sword_shield_hero": [
    "sword_shield_hero_longsword",
    "sword_shield_hero_piercing_spear",
    "sword_shield_hero_aegis",
    "sword_shield_hero_shield_hammer",
    "sword_shield_hero_blade_ring",
    "sword_shield_hero_battle_banner"
  ],
  "pistol_hero": [
    "pistol_hero_revolver",
    "pistol_hero_shotgun",
    "pistol_hero_rifle",
    "pistol_hero_ricochet",
    "pistol_hero_grenade",
    "pistol_hero_powder_bomb"
  ],
  "archmage_hero": [
    "archmage_hero_fire_staff",
    "archmage_hero_ice_scepter",
    "archmage_hero_lightning_rod",
    "archmage_hero_earth_staff",
    "archmage_hero_storm_orb",
    "archmage_hero_prism_wand"
  ],
  "madness_hero": [
    "madness_hero_blood_sword",
    "madness_hero_blood_lance",
    "madness_hero_blood_wheel",
    "madness_hero_blood_burst",
    "madness_hero_drain_blade",
    "madness_hero_heart_chain"
  ],
  "chemical_hero": [
    "chemical_hero_acid_vial",
    "chemical_hero_poison_flask",
    "chemical_hero_cryo_vial",
    "chemical_hero_reaction_bomb",
    "chemical_hero_acid_cannon",
    "chemical_hero_life_elixir"
  ],
  "summoner_hero": [
    "summoner_hero_gate_hound",
    "summoner_hero_watcher",
    "summoner_hero_scout",
    "summoner_hero_gate_laser",
    "summoner_hero_gatekeeper",
    "summoner_hero_rift_pulse"
  ],
  "purifier_hero": [
    "purifier_hero_holy_bolt",
    "purifier_hero_holy_lance",
    "purifier_hero_purification",
    "purifier_hero_sacred_orb",
    "purifier_hero_blessing",
    "purifier_hero_prayer"
  ],
  "sage_astra": [
    "sage_astra_starlight",
    "sage_astra_comet",
    "sage_astra_astral_chain",
    "sage_astra_absolute_zero",
    "sage_astra_singularity",
    "sage_astra_binary_stars"
  ]
}
const WEAPONS := {
  "ranged_rookie_arcane_bolt": {
    "name": "마력탄",
    "owner": "ranged_rookie",
    "pattern": "bolt",
    "color": "85dcff",
    "cooldown": 1.0,
    "range": 620,
    "power": 1.0,
    "base_hits": 1,
    "effect": "표적 마력 타격",
    "evolution": "마력탄 · 각성",
    "tags": [
      "damage"
    ],
    "effect_dir": "res://assets/art/heroes/stage1_mage/frames/effect_01",
    "source_skill": "고유 기본공격",
    "hit_cap": 16
  },
  "ranged_rookie_star_wand": {
    "name": "별빛 지팡이",
    "owner": "ranged_rookie",
    "pattern": "chain",
    "color": "85dcff",
    "cooldown": 2.27,
    "range": 575,
    "power": 0.85,
    "base_hits": 3,
    "effect": "가까운 적 사이로 최대 3회 연쇄",
    "evolution": "별빛 지팡이 · 각성",
    "tags": [
      "damage"
    ],
    "effect_dir": "res://assets/art/heroes/stage1_mage/frames/effect_01",
    "source_skill": "고유 기본공격",
    "hit_cap": 16,
    "chain_radius": 180
  },
  "ranged_rookie_magic_lance": {
    "name": "마력 관통포",
    "owner": "ranged_rookie",
    "pattern": "piercer",
    "color": "85dcff",
    "cooldown": 4.8,
    "range": 800,
    "power": 1.8,
    "base_hits": 1,
    "effect": "실제 마력 관통탄 · 직선의 적 관통",
    "evolution": "마력 관통포 · 각성",
    "tags": [
      "damage"
    ],
    "effect_dir": "res://assets/art/heroes/stage1_mage/frames/effect_01",
    "source_skill": "마력 관통포",
    "hit_cap": 8,
    "projectile_speed": 950.0
  },
  "ranged_rookie_rune_ring": {
    "name": "비전 집중",
    "owner": "ranged_rookie",
    "pattern": "poison",
    "color": "85dcff",
    "cooldown": 6.5,
    "range": 325,
    "power": 1.36,
    "base_hits": 1,
    "effect": "이동을 따라오는 비전 집중 · 2.5초간 주변 연속 타격",
    "evolution": "비전 집중 · 각성",
    "tags": [
      "area"
    ],
    "effect_dir": "res://assets/art/heroes/stage1_mage/frames/effect_03",
    "source_skill": "비전 집중",
    "hit_cap": 8,
    "field_follow": true,
    "field_duration": 2.5,
    "field_interval": 0.25,
    "field_power": 0.28
  },
  "ranged_rookie_pulse_staff": {
    "name": "파동 지팡이",
    "owner": "ranged_rookie",
    "pattern": "nova",
    "color": "85dcff",
    "cooldown": 3.46,
    "range": 240,
    "power": 1.48,
    "base_hits": 1,
    "effect": "광역 폭발",
    "evolution": "파동 지팡이 · 각성",
    "tags": [
      "area"
    ],
    "effect_dir": "res://assets/art/heroes/stage1_mage/frames/effect_01",
    "source_skill": "고유 기본공격",
    "hit_cap": 16
  },
  "ranged_rookie_barrier_book": {
    "name": "마력 장벽",
    "owner": "ranged_rookie",
    "pattern": "guard",
    "color": "85dcff",
    "cooldown": 12.0,
    "range": 275,
    "power": 1.6,
    "base_hits": 1,
    "effect": "마력 보호막 · 주변 충격파",
    "evolution": "마력 장벽 · 각성",
    "tags": [
      "durability"
    ],
    "effect_dir": "res://assets/art/heroes/stage1_mage/frames/effect_02",
    "source_skill": "마력 장벽",
    "hit_cap": 16,
    "shield_ratio": 0.07
  },
  "swift_hunter_dagger": {
    "name": "쌍단검",
    "owner": "swift_hunter",
    "pattern": "combo",
    "color": "bc9eee",
    "cooldown": 0.9,
    "range": 200,
    "power": 0.62,
    "base_hits": 2,
    "effect": "같은 표적을 짧은 간격으로 2연속 찌르기",
    "evolution": "쌍단검 · 각성",
    "tags": [
      "damage"
    ],
    "effect_dir": "res://assets/art/heroes/stage2_rogue/frames/effect_01",
    "source_skill": "고유 기본공격",
    "hit_cap": 8,
    "hit_interval": 0.14
  },
  "swift_hunter_throwing_knife": {
    "name": "투척 단검",
    "owner": "swift_hunter",
    "pattern": "bolt",
    "color": "bc9eee",
    "cooldown": 1.08,
    "range": 645,
    "power": 1.12,
    "base_hits": 1,
    "effect": "표적 마력 타격",
    "evolution": "투척 단검 · 각성",
    "tags": [
      "damage"
    ],
    "effect_dir": "res://assets/art/heroes/stage2_rogue/frames/effect_01",
    "source_skill": "고유 기본공격",
    "hit_cap": 16
  },
  "swift_hunter_shadow_wire": {
    "name": "급습-암살",
    "owner": "swift_hunter",
    "pattern": "combo",
    "color": "bc9eee",
    "cooldown": 4.2,
    "range": 270,
    "power": 0.7,
    "base_hits": 3,
    "effect": "근접 표적 3연격 · 체력 10% 이하 마무리",
    "evolution": "급습-암살 · 각성",
    "tags": [
      "damage"
    ],
    "effect_dir": "res://assets/art/heroes/stage2_rogue/frames/effect_02",
    "source_skill": "급습-암살",
    "hit_cap": 16,
    "hit_interval": 0.18,
    "execute_ratio": 0.1
  },
  "swift_hunter_poison_needle": {
    "name": "독침",
    "owner": "swift_hunter",
    "pattern": "poison",
    "color": "bc9eee",
    "cooldown": 2.2,
    "range": 375,
    "power": 1.36,
    "base_hits": 1,
    "effect": "독침이 남기는 작은 독 영역 · 2초 지속",
    "evolution": "독침 · 각성",
    "tags": [
      "area"
    ],
    "effect_dir": "res://assets/art/heroes/stage2_rogue/frames/effect_01",
    "source_skill": "고유 기본공격",
    "hit_cap": 16,
    "field_duration": 2.0,
    "field_interval": 0.4,
    "field_power": 0.28
  },
  "swift_hunter_moon_blade": {
    "name": "난도질",
    "owner": "swift_hunter",
    "pattern": "poison",
    "color": "bc9eee",
    "cooldown": 5.0,
    "range": 230,
    "power": 1.48,
    "base_hits": 1,
    "effect": "1.2초 이동형 검무 · 가까운 적 연속 타격",
    "evolution": "난도질 · 각성",
    "tags": [
      "area"
    ],
    "effect_dir": "res://assets/art/heroes/stage2_rogue/frames/effect_03",
    "source_skill": "난도질",
    "hit_cap": 8,
    "field_follow": true,
    "field_duration": 1.2,
    "field_interval": 0.24,
    "field_power": 0.45
  },
  "swift_hunter_shadow_bomb": {
    "name": "그림자 폭탄",
    "owner": "swift_hunter",
    "pattern": "nova",
    "color": "bc9eee",
    "cooldown": 3.71,
    "range": 265,
    "power": 1.6,
    "base_hits": 1,
    "effect": "광역 폭발",
    "evolution": "그림자 폭탄 · 각성",
    "tags": [
      "area"
    ],
    "effect_dir": "res://assets/art/heroes/stage2_rogue/frames/effect_01",
    "source_skill": "고유 기본공격",
    "hit_cap": 16
  },
  "sword_shield_hero_longsword": {
    "name": "수호 장검",
    "owner": "sword_shield_hero",
    "pattern": "slash",
    "color": "e6c372",
    "cooldown": 1.3,
    "range": 200,
    "power": 1.2,
    "base_hits": 1,
    "effect": "넓은 검격 · 최대 6명의 전방 적 타격",
    "evolution": "수호 장검 · 각성",
    "tags": [
      "damage"
    ],
    "effect_dir": "res://assets/art/heroes/stage3_fighter/frames/effect2",
    "source_skill": "고유 기본공격",
    "hit_cap": 6
  },
  "sword_shield_hero_piercing_spear": {
    "name": "검방 돌격 · 창격",
    "owner": "sword_shield_hero",
    "pattern": "beam",
    "color": "e6c372",
    "cooldown": 3.5,
    "range": 390,
    "power": 2.0,
    "base_hits": 1,
    "effect": "이동 방향을 유지하는 관통 창격 · 최대 8명",
    "evolution": "검방 돌격 · 창격 · 각성",
    "tags": [
      "damage"
    ],
    "effect_dir": "res://assets/art/heroes/stage3_fighter/frames/effect3",
    "source_skill": "검방 돌격 · 창격",
    "hit_cap": 8
  },
  "sword_shield_hero_aegis": {
    "name": "막기",
    "owner": "sword_shield_hero",
    "pattern": "guard",
    "color": "e6c372",
    "cooldown": 8.0,
    "range": 250,
    "power": 1.24,
    "base_hits": 1,
    "effect": "3초 수호 방패 · 근접 적을 밀어내는 둔화 충격파",
    "evolution": "막기 · 각성",
    "tags": [
      "durability"
    ],
    "effect_dir": "res://assets/art/heroes/stage3_fighter/frames/effect1",
    "source_skill": "막기",
    "hit_cap": 16,
    "shield_ratio": 0.12,
    "shield_duration": 3.0,
    "slow_multiplier": 0.65,
    "slow_duration": 1.0
  },
  "sword_shield_hero_shield_hammer": {
    "name": "방패 망치",
    "owner": "sword_shield_hero",
    "pattern": "nova",
    "color": "e6c372",
    "cooldown": 3.2,
    "range": 265,
    "power": 1.36,
    "base_hits": 1,
    "effect": "광역 폭발",
    "evolution": "방패 망치 · 각성",
    "tags": [
      "area"
    ],
    "effect_dir": "res://assets/art/heroes/stage3_fighter/frames/effect1",
    "source_skill": "고유 기본공격",
    "hit_cap": 16
  },
  "sword_shield_hero_blade_ring": {
    "name": "회전 검륜",
    "owner": "sword_shield_hero",
    "pattern": "orbit",
    "color": "e6c372",
    "cooldown": 1.62,
    "range": 300,
    "power": 1.48,
    "base_hits": 1,
    "effect": "회전 수호체 타격",
    "evolution": "회전 검륜 · 각성",
    "tags": [
      "area"
    ],
    "effect_dir": "res://assets/art/heroes/stage3_fighter/frames/effect4",
    "source_skill": "고유 기본공격",
    "hit_cap": 10
  },
  "sword_shield_hero_battle_banner": {
    "name": "전장의 깃발",
    "owner": "sword_shield_hero",
    "pattern": "heal",
    "color": "e6c372",
    "cooldown": 13.92,
    "range": 305,
    "power": 1.6,
    "base_hits": 1,
    "effect": "회복·주변 파동",
    "evolution": "전장의 깃발 · 각성",
    "tags": [
      "durability"
    ],
    "effect_dir": "res://assets/art/heroes/stage3_fighter/frames/effect1",
    "source_skill": "고유 기본공격",
    "hit_cap": 16
  },
  "pistol_hero_revolver": {
    "name": "육연발 권총",
    "owner": "pistol_hero",
    "pattern": "burst",
    "color": "ffcc72",
    "cooldown": 0.9,
    "range": 620,
    "power": 0.5,
    "base_hits": 3,
    "effect": "3발 속사 · 6발마다 1.6초 장전",
    "evolution": "육연발 권총 · 각성",
    "tags": [
      "damage"
    ],
    "effect_dir": "res://assets/art/heroes/stage4_gunner/frames/effect",
    "source_skill": "고유 기본공격",
    "hit_cap": 16,
    "hit_interval": 0.1,
    "magazine": 6,
    "reload": 1.6
  },
  "pistol_hero_shotgun": {
    "name": "실린더 스트라이크",
    "owner": "pistol_hero",
    "pattern": "nova",
    "color": "ffcc72",
    "cooldown": 5.5,
    "range": 230,
    "power": 1.4,
    "base_hits": 2,
    "effect": "근접 전방위 사격 · 2초 둔화",
    "evolution": "실린더 스트라이크 · 각성",
    "tags": [
      "damage"
    ],
    "effect_dir": "res://assets/art/heroes/stage3_fighter/frames/effect5",
    "source_skill": "실린더 스트라이크",
    "hit_cap": 8,
    "slow_multiplier": 0.5,
    "slow_duration": 2.0
  },
  "pistol_hero_rifle": {
    "name": "데드아이",
    "owner": "pistol_hero",
    "pattern": "burst",
    "color": "ffcc72",
    "cooldown": 5.5,
    "range": 800,
    "power": 0.65,
    "base_hits": 5,
    "effect": "단일 표적을 겨냥한 5발 집중 속사",
    "evolution": "데드아이 · 각성",
    "tags": [
      "damage"
    ],
    "effect_dir": "res://assets/art/heroes/stage4_gunner/frames/effect",
    "source_skill": "데드아이",
    "hit_cap": 8,
    "hit_interval": 0.08
  },
  "pistol_hero_ricochet": {
    "name": "도탄 권총",
    "owner": "pistol_hero",
    "pattern": "chain",
    "color": "ffcc72",
    "cooldown": 2.1,
    "range": 575,
    "power": 0.75,
    "base_hits": 4,
    "effect": "적 사이를 튕기는 최대 4회 도탄",
    "evolution": "도탄 권총 · 각성",
    "tags": [
      "damage"
    ],
    "effect_dir": "res://assets/art/heroes/stage4_gunner/frames/effect",
    "source_skill": "고유 기본공격",
    "hit_cap": 16,
    "chain_radius": 220
  },
  "pistol_hero_grenade": {
    "name": "충격 수류탄",
    "owner": "pistol_hero",
    "pattern": "nova",
    "color": "ffcc72",
    "cooldown": 3.46,
    "range": 240,
    "power": 1.48,
    "base_hits": 1,
    "effect": "광역 폭발",
    "evolution": "충격 수류탄 · 각성",
    "tags": [
      "area"
    ],
    "effect_dir": "res://assets/art/heroes/stage4_gunner/frames/effect",
    "source_skill": "고유 기본공격",
    "hit_cap": 16
  },
  "pistol_hero_powder_bomb": {
    "name": "화약 폭탄",
    "owner": "pistol_hero",
    "pattern": "poison",
    "color": "ffcc72",
    "cooldown": 2.55,
    "range": 375,
    "power": 1.6,
    "base_hits": 1,
    "effect": "화약 장판 · 짧은 폭발 연속 피해",
    "evolution": "화약 폭탄 · 각성",
    "tags": [
      "area"
    ],
    "field_duration": 2.0,
    "field_interval": 0.25,
    "field_radius_ratio": 0.5,
    "effect_dir": "res://assets/art/heroes/stage4_gunner/frames/effect",
    "source_skill": "고유 기본공격",
    "hit_cap": 16
  },
  "archmage_hero_fire_staff": {
    "name": "연소",
    "owner": "archmage_hero",
    "pattern": "poison",
    "color": "f9a95b",
    "cooldown": 2.2,
    "range": 350,
    "power": 1.0,
    "base_hits": 1,
    "effect": "연소 화염 · 좁은 범위에 빠른 지속 피해",
    "evolution": "연소 · 각성",
    "tags": [
      "area"
    ],
    "field_duration": 2.0,
    "field_interval": 0.35,
    "effect_dir": "res://assets/art/heroes/stage5_archmage/frames/effect2",
    "source_skill": "연소",
    "hit_cap": 16,
    "field_power": 0.35
  },
  "archmage_hero_ice_scepter": {
    "name": "아이스볼트",
    "owner": "archmage_hero",
    "pattern": "frost",
    "color": "f9a95b",
    "cooldown": 2.7,
    "range": 445,
    "power": 1.12,
    "base_hits": 1,
    "effect": "냉기 폭발 · 2초 35% 둔화",
    "evolution": "아이스볼트 · 각성",
    "tags": [
      "damage"
    ],
    "effect_dir": "res://assets/art/heroes/stage5_archmage/frames/effect3",
    "source_skill": "아이스볼트",
    "hit_cap": 16,
    "slow_multiplier": 0.65,
    "slow_duration": 2.0
  },
  "archmage_hero_lightning_rod": {
    "name": "체인대거",
    "owner": "archmage_hero",
    "pattern": "chain",
    "color": "f9a95b",
    "cooldown": 2.44,
    "range": 550,
    "power": 0.8,
    "base_hits": 4,
    "effect": "가까운 적을 순차 연결하는 4회 연쇄 단검",
    "evolution": "체인대거 · 각성",
    "tags": [
      "damage"
    ],
    "effect_dir": "res://assets/art/heroes/stage5_archmage/frames/effect6",
    "source_skill": "체인대거",
    "hit_cap": 16,
    "chain_radius": 200
  },
  "archmage_hero_earth_staff": {
    "name": "땅의 가시",
    "owner": "archmage_hero",
    "pattern": "nova",
    "color": "f9a95b",
    "cooldown": 5.0,
    "range": 265,
    "power": 2.0,
    "base_hits": 1,
    "effect": "대지 가시 · 큰 단발 광역 타격",
    "evolution": "땅의 가시 · 각성",
    "tags": [
      "area"
    ],
    "effect_dir": "res://assets/art/heroes/stage5_archmage/frames/effect4",
    "source_skill": "땅의 가시",
    "hit_cap": 16
  },
  "archmage_hero_storm_orb": {
    "name": "폭풍",
    "owner": "archmage_hero",
    "pattern": "orbit",
    "color": "f9a95b",
    "cooldown": 1.62,
    "range": 300,
    "power": 1.48,
    "base_hits": 1,
    "effect": "폭풍 수호체 · 회전 궤도의 적 타격",
    "evolution": "폭풍 · 각성",
    "tags": [
      "area"
    ],
    "effect_dir": "res://assets/art/heroes/stage5_archmage/frames/effect8",
    "source_skill": "폭풍",
    "hit_cap": 10,
    "orbit_count": 3
  },
  "archmage_hero_prism_wand": {
    "name": "신성력",
    "owner": "archmage_hero",
    "pattern": "poison",
    "color": "f9a95b",
    "cooldown": 5.5,
    "range": 825,
    "power": 1.6,
    "base_hits": 1,
    "effect": "신성력 장판 · 넓은 범위 연속 타격",
    "evolution": "신성력 · 각성",
    "tags": [
      "damage"
    ],
    "effect_dir": "res://assets/art/heroes/stage5_archmage/frames/effect5",
    "source_skill": "신성력",
    "hit_cap": 8,
    "field_duration": 3.0,
    "field_interval": 0.5,
    "field_power": 0.32
  },
  "madness_hero_blood_sword": {
    "name": "혈검술 제1식",
    "owner": "madness_hero",
    "pattern": "combo",
    "color": "e05e75",
    "cooldown": 1.5,
    "range": 200,
    "power": 0.55,
    "base_hits": 3,
    "effect": "혈검 3연격 · 체력이 낮을수록 피해 증가",
    "evolution": "혈검술 제1식 · 각성",
    "tags": [
      "damage"
    ],
    "effect_dir": "res://assets/art/heroes/stage6_berserker/frames/effect1",
    "source_skill": "혈검술 제1식",
    "hit_cap": 8,
    "hit_interval": 0.25,
    "low_hp_bonus": 0.5
  },
  "madness_hero_blood_lance": {
    "name": "혈검술 제2식",
    "owner": "madness_hero",
    "pattern": "poison",
    "color": "e05e75",
    "cooldown": 4.5,
    "range": 825,
    "power": 1.12,
    "base_hits": 1,
    "effect": "피의 흔적 · 유효 피해의 4% 흡혈",
    "evolution": "혈검술 제2식 · 각성",
    "tags": [
      "damage"
    ],
    "effect_dir": "res://assets/art/heroes/stage6_berserker/frames/effect2",
    "source_skill": "혈검술 제2식",
    "hit_cap": 8,
    "field_duration": 2.0,
    "field_interval": 0.4,
    "field_power": 0.3,
    "lifesteal": 0.04
  },
  "madness_hero_blood_wheel": {
    "name": "핏빛 검륜",
    "owner": "madness_hero",
    "pattern": "orbit",
    "color": "e05e75",
    "cooldown": 1.74,
    "range": 300,
    "power": 1.24,
    "base_hits": 1,
    "effect": "회전 수호체 타격",
    "evolution": "핏빛 검륜 · 각성",
    "tags": [
      "area"
    ],
    "effect_dir": "res://assets/art/heroes/stage6_berserker/frames/effect1",
    "source_skill": "고유 기본공격",
    "hit_cap": 8
  },
  "madness_hero_blood_burst": {
    "name": "혈검술 제4식",
    "owner": "madness_hero",
    "pattern": "nova",
    "color": "e05e75",
    "cooldown": 5.0,
    "range": 265,
    "power": 2.2,
    "base_hits": 1,
    "effect": "현재 HP 2% 소모 · 빈사일수록 강한 혈폭",
    "evolution": "혈검술 제4식 · 각성",
    "tags": [
      "area"
    ],
    "effect_dir": "res://assets/art/heroes/stage6_berserker/frames/effect3",
    "source_skill": "혈검술 제4식",
    "hit_cap": 16,
    "hp_cost": 0.02,
    "low_hp_bonus": 0.6
  },
  "madness_hero_drain_blade": {
    "name": "흡혈 검",
    "owner": "madness_hero",
    "pattern": "slash",
    "color": "e05e75",
    "cooldown": 2.6,
    "range": 280,
    "power": 0.8,
    "base_hits": 1,
    "effect": "유효 검격 피해의 8% 회복 · 허공 회복 없음",
    "evolution": "흡혈 검 · 각성",
    "tags": [
      "durability"
    ],
    "effect_dir": "res://assets/art/heroes/stage6_berserker/frames/effect1",
    "source_skill": "고유 기본공격",
    "hit_cap": 16,
    "lifesteal": 0.08
  },
  "madness_hero_heart_chain": {
    "name": "심장 사슬",
    "owner": "madness_hero",
    "pattern": "chain",
    "color": "e05e75",
    "cooldown": 2.44,
    "range": 575,
    "power": 1.6,
    "base_hits": 1,
    "effect": "다수 표적 연쇄 타격",
    "evolution": "심장 사슬 · 각성",
    "tags": [
      "damage"
    ],
    "effect_dir": "res://assets/art/heroes/stage6_berserker/frames/effect1",
    "source_skill": "고유 기본공격",
    "hit_cap": 16
  },
  "chemical_hero_acid_vial": {
    "name": "산성 약병",
    "owner": "chemical_hero",
    "pattern": "poison",
    "color": "a4dc63",
    "cooldown": 2.2,
    "range": 350,
    "power": 1.0,
    "base_hits": 1,
    "effect": "산성 장판 · 빠른 연속 피해",
    "evolution": "산성 약병 · 각성",
    "tags": [
      "area"
    ],
    "field_duration": 3.0,
    "field_interval": 0.5,
    "field_radius_ratio": 0.45,
    "effect_dir": "res://assets/art/heroes/stage7_alchemist/frames/effect1",
    "source_skill": "고유 기본공격",
    "hit_cap": 16,
    "field_power": 0.45
  },
  "chemical_hero_poison_flask": {
    "name": "촉매 혼합장",
    "owner": "chemical_hero",
    "pattern": "poison",
    "color": "a4dc63",
    "cooldown": 2.38,
    "range": 375,
    "power": 1.12,
    "base_hits": 1,
    "effect": "5초 혼합장 · 지속 피해와 둔화",
    "evolution": "촉매 혼합장 · 각성",
    "tags": [
      "area"
    ],
    "field_duration": 5.0,
    "field_interval": 1.0,
    "field_radius_ratio": 0.6,
    "effect_dir": "res://assets/art/heroes/stage7_alchemist/frames/effect3",
    "source_skill": "촉매 혼합장",
    "hit_cap": 16,
    "field_power": 0.38,
    "slow_multiplier": 0.8,
    "slow_duration": 1.1
  },
  "chemical_hero_cryo_vial": {
    "name": "냉각 약병",
    "owner": "chemical_hero",
    "pattern": "frost",
    "color": "a4dc63",
    "cooldown": 2.9,
    "range": 420,
    "power": 1.24,
    "base_hits": 1,
    "effect": "냉기 폭발·둔화",
    "evolution": "냉각 약병 · 각성",
    "tags": [
      "damage"
    ],
    "effect_dir": "res://assets/art/heroes/stage7_alchemist/frames/effect1",
    "source_skill": "고유 기본공격",
    "hit_cap": 16
  },
  "chemical_hero_reaction_bomb": {
    "name": "오늘도 실팬가!",
    "owner": "chemical_hero",
    "pattern": "poison",
    "color": "a4dc63",
    "cooldown": 5.5,
    "range": 265,
    "power": 1.36,
    "base_hits": 1,
    "effect": "이동 경로를 따라 독 가스를 남기는 2초 반응",
    "evolution": "오늘도 실팬가! · 각성",
    "tags": [
      "area"
    ],
    "effect_dir": "res://assets/art/heroes/stage7_alchemist/frames/effect4",
    "source_skill": "오늘도 실팬가!",
    "hit_cap": 16,
    "field_follow": true,
    "field_duration": 2.0,
    "field_interval": 0.5,
    "field_power": 0.5
  },
  "chemical_hero_acid_cannon": {
    "name": "압축 산성포",
    "owner": "chemical_hero",
    "pattern": "beam",
    "color": "a4dc63",
    "cooldown": 3.24,
    "range": 800,
    "power": 1.48,
    "base_hits": 1,
    "effect": "직선 관통",
    "evolution": "압축 산성포 · 각성",
    "tags": [
      "damage"
    ],
    "effect_dir": "res://assets/art/heroes/stage7_alchemist/frames/effect1",
    "source_skill": "고유 기본공격",
    "hit_cap": 8
  },
  "chemical_hero_life_elixir": {
    "name": "현자의 비약",
    "owner": "chemical_hero",
    "pattern": "heal",
    "color": "a4dc63",
    "cooldown": 14.0,
    "range": 305,
    "power": 1.6,
    "base_hits": 1,
    "effect": "최대 HP 3.5% 회복 · 주변 파동",
    "evolution": "현자의 비약 · 각성",
    "tags": [
      "durability"
    ],
    "effect_dir": "res://assets/art/heroes/stage7_alchemist/frames/effect6",
    "source_skill": "현자의 비약",
    "hit_cap": 16,
    "heal_ratio": 0.035
  },
  "summoner_hero_gate_hound": {
    "name": "이계의 문 - 투견",
    "owner": "summoner_hero",
    "pattern": "summon",
    "color": "86cbb8",
    "cooldown": 8.0,
    "range": 250,
    "power": 0.65,
    "base_hits": 1,
    "effect": "기존 이계 소환수 실제 소환 · 총 3체 제한 · 14초 유지",
    "evolution": "이계의 문 - 투견 · 각성",
    "tags": [
      "area"
    ],
    "orbit_count": 2,
    "orbit_speed": 4.5,
    "orbit_ratio": 0.5,
    "effect_dir": "res://assets/art/heroes/stage8_summoner/frames/effect1",
    "source_skill": "이계의 문 - 투견",
    "hit_cap": 8,
    "summon_kind": "hound",
    "summon_duration": 14.0
  },
  "summoner_hero_watcher": {
    "name": "이계의 문 - 감시자",
    "owner": "summoner_hero",
    "pattern": "summon",
    "color": "86cbb8",
    "cooldown": 8.0,
    "range": 350,
    "power": 0.65,
    "base_hits": 1,
    "effect": "기존 이계 소환수 실제 소환 · 총 3체 제한 · 14초 유지",
    "evolution": "이계의 문 - 감시자 · 각성",
    "tags": [
      "area"
    ],
    "orbit_count": 4,
    "orbit_speed": 2.5,
    "orbit_ratio": 0.85,
    "effect_dir": "res://assets/art/heroes/stage8_summoner/frames/effect1",
    "source_skill": "이계의 문 - 감시자",
    "hit_cap": 8,
    "summon_kind": "watcher",
    "summon_duration": 14.0
  },
  "summoner_hero_scout": {
    "name": "이계의 문 - 정찰병",
    "owner": "summoner_hero",
    "pattern": "summon",
    "color": "86cbb8",
    "cooldown": 8.0,
    "range": 620,
    "power": 0.65,
    "base_hits": 2,
    "effect": "기존 이계 소환수 실제 소환 · 총 3체 제한 · 14초 유지",
    "evolution": "이계의 문 - 정찰병 · 각성",
    "tags": [
      "damage"
    ],
    "effect_dir": "res://assets/art/heroes/stage8_summoner/frames/effect1",
    "source_skill": "이계의 문 - 정찰병",
    "hit_cap": 16,
    "summon_kind": "scout",
    "summon_duration": 14.0
  },
  "summoner_hero_gate_laser": {
    "name": "차원 관통문",
    "owner": "summoner_hero",
    "pattern": "beam",
    "color": "86cbb8",
    "cooldown": 3.0,
    "range": 825,
    "power": 1.36,
    "base_hits": 1,
    "effect": "직선 관통",
    "evolution": "차원 관통문 · 각성",
    "tags": [
      "damage"
    ],
    "effect_dir": "res://assets/art/heroes/stage8_summoner/frames/effect1",
    "source_skill": "고유 기본공격",
    "hit_cap": 8
  },
  "summoner_hero_gatekeeper": {
    "name": "이계의 문 - 문지기",
    "owner": "summoner_hero",
    "pattern": "summon",
    "color": "86cbb8",
    "cooldown": 8.0,
    "range": 250,
    "power": 0.65,
    "base_hits": 1,
    "effect": "기존 이계 소환수 실제 소환 · 총 3체 제한 · 14초 유지",
    "evolution": "이계의 문 - 문지기 · 각성",
    "tags": [
      "durability"
    ],
    "effect_dir": "res://assets/art/heroes/stage8_summoner/frames/effect1",
    "source_skill": "이계의 문 - 문지기",
    "hit_cap": 16,
    "summon_kind": "gatekeeper",
    "summon_duration": 14.0
  },
  "summoner_hero_rift_pulse": {
    "name": "균열 파동",
    "owner": "summoner_hero",
    "pattern": "nova",
    "color": "86cbb8",
    "cooldown": 3.71,
    "range": 265,
    "power": 1.6,
    "base_hits": 1,
    "effect": "광역 폭발",
    "evolution": "균열 파동 · 각성",
    "tags": [
      "area"
    ],
    "effect_dir": "res://assets/art/heroes/stage8_summoner/frames/effect1",
    "source_skill": "고유 기본공격",
    "hit_cap": 16
  },
  "purifier_hero_holy_bolt": {
    "name": "성광탄",
    "owner": "purifier_hero",
    "pattern": "bolt",
    "color": "fff0b1",
    "cooldown": 1.0,
    "range": 620,
    "power": 1.0,
    "base_hits": 1,
    "effect": "표적 마력 타격",
    "evolution": "성광탄 · 각성",
    "tags": [
      "damage"
    ],
    "effect_dir": "res://assets/art/heroes/stage9_prist/frames/effect1",
    "source_skill": "고유 기본공격",
    "hit_cap": 16
  },
  "purifier_hero_holy_lance": {
    "name": "궁그닐",
    "owner": "purifier_hero",
    "pattern": "beam",
    "color": "fff0b1",
    "cooldown": 5.5,
    "range": 825,
    "power": 2.4,
    "base_hits": 1,
    "effect": "긴 성창으로 직선 관통 · 최대 10명",
    "evolution": "궁그닐 · 각성",
    "tags": [
      "damage"
    ],
    "effect_dir": "res://assets/art/heroes/stage9_prist/frames/effect6",
    "source_skill": "궁그닐",
    "hit_cap": 10
  },
  "purifier_hero_purification": {
    "name": "정화",
    "owner": "purifier_hero",
    "pattern": "nova",
    "color": "fff0b1",
    "cooldown": 9.0,
    "range": 240,
    "power": 1.24,
    "base_hits": 1,
    "effect": "자신의 독·화상·둔화 해제 · 주변 정화 파동",
    "evolution": "정화 · 각성",
    "tags": [
      "area"
    ],
    "effect_dir": "res://assets/art/heroes/stage9_prist/frames/effect5",
    "source_skill": "정화",
    "hit_cap": 16,
    "cleanse": true
  },
  "purifier_hero_sacred_orb": {
    "name": "정화의 구체",
    "owner": "purifier_hero",
    "pattern": "orbit",
    "color": "fff0b1",
    "cooldown": 1.5,
    "range": 325,
    "power": 1.36,
    "base_hits": 4,
    "effect": "주변을 도는 정화 구체 · 최대 8명 타격",
    "evolution": "정화의 구체 · 각성",
    "tags": [
      "area"
    ],
    "effect_dir": "res://assets/art/heroes/stage9_prist/frames/effect2",
    "source_skill": "정화의 구체",
    "hit_cap": 8,
    "orbit_count": 4
  },
  "purifier_hero_blessing": {
    "name": "신성보호",
    "owner": "purifier_hero",
    "pattern": "guard",
    "color": "fff0b1",
    "cooldown": 11.0,
    "range": 250,
    "power": 1.48,
    "base_hits": 1,
    "effect": "4초 신성 보호막 · 주변 성광",
    "evolution": "신성보호 · 각성",
    "tags": [
      "durability"
    ],
    "effect_dir": "res://assets/art/heroes/stage9_prist/frames/effect4",
    "source_skill": "신성보호",
    "hit_cap": 16,
    "shield_ratio": 0.1,
    "shield_duration": 4.0
  },
  "purifier_hero_prayer": {
    "name": "회복의 성배",
    "owner": "purifier_hero",
    "pattern": "heal",
    "color": "fff0b1",
    "cooldown": 13.92,
    "range": 305,
    "power": 1.6,
    "base_hits": 1,
    "effect": "회복·주변 파동",
    "evolution": "회복의 성배 · 각성",
    "tags": [
      "durability"
    ],
    "effect_dir": "res://assets/art/heroes/stage9_prist/frames/effect1",
    "source_skill": "고유 기본공격",
    "hit_cap": 16
  },
  "sage_astra_starlight": {
    "name": "별빛 지팡이",
    "owner": "sage_astra",
    "pattern": "bolt",
    "color": "c6abff",
    "cooldown": 1.0,
    "range": 620,
    "power": 0.7,
    "base_hits": 2,
    "effect": "2개의 별빛 탄 · 집중 표적 추적",
    "evolution": "별빛 지팡이 · 각성",
    "tags": [
      "damage"
    ],
    "effect_dir": "res://assets/art/heroes/stage10_sage/frames/effect2",
    "source_skill": "고유 기본공격",
    "hit_cap": 16
  },
  "sage_astra_comet": {
    "name": "스타라이트",
    "owner": "sage_astra",
    "pattern": "meteor",
    "color": "c6abff",
    "cooldown": 4.5,
    "range": 825,
    "power": 1.2,
    "base_hits": 2,
    "effect": "기존 운석 실제 낙하 · 착탄 범위 피해",
    "evolution": "스타라이트 · 각성",
    "tags": [
      "damage"
    ],
    "effect_dir": "res://assets/art/heroes/stage10_sage/frames/effect1",
    "source_skill": "스타라이트",
    "hit_cap": 8,
    "native_radius": 95.0,
    "native_radius_per_level": 3.0,
    "fall_duration": 0.58,
    "visual_scale": 0.62,
    "fall_height": 430.0,
    "fall_side_offset": 260.0,
    "explosion_fps": 14.0
  },
  "sage_astra_astral_chain": {
    "name": "천체 사슬",
    "owner": "sage_astra",
    "pattern": "chain",
    "color": "c6abff",
    "cooldown": 2.44,
    "range": 550,
    "power": 0.8,
    "base_hits": 4,
    "effect": "가까운 적 사이 천체 연쇄 · 최대 4회",
    "evolution": "천체 사슬 · 각성",
    "tags": [
      "damage"
    ],
    "effect_dir": "res://assets/art/heroes/stage10_sage/frames/effect3",
    "source_skill": "고유 기본공격",
    "hit_cap": 16,
    "chain_radius": 240
  },
  "sage_astra_absolute_zero": {
    "name": "빙점폭발",
    "owner": "sage_astra",
    "pattern": "ice_pillar",
    "color": "c6abff",
    "cooldown": 6.0,
    "range": 445,
    "power": 1.1,
    "base_hits": 1,
    "effect": "기존 얼음 기둥 실제 생성 · 둔화·길목 차단",
    "evolution": "빙점폭발 · 각성",
    "tags": [
      "damage"
    ],
    "effect_dir": "res://assets/art/heroes/stage10_sage/frames/effect1",
    "source_skill": "빙점폭발",
    "hit_cap": 16,
    "field_duration": 3.0,
    "native_radius": 125.0,
    "native_radius_per_level": 3.0,
    "slow_multiplier": 0.75,
    "collision_radius": 34.0
  },
  "sage_astra_singularity": {
    "name": "소멸",
    "owner": "sage_astra",
    "pattern": "singularity",
    "color": "c6abff",
    "cooldown": 9.0,
    "range": 240,
    "power": 0.7,
    "base_hits": 1,
    "effect": "기존 소멸 영역 · 끌어당김·반복 피해·체력 10% 마무리",
    "evolution": "소멸 · 각성",
    "tags": [
      "area"
    ],
    "effect_dir": "res://assets/art/heroes/stage10_sage/frames/effect1",
    "source_skill": "소멸",
    "hit_cap": 16,
    "field_duration": 3.0,
    "native_radius": 150.0,
    "native_radius_per_level": 5.0,
    "field_power": 0.35,
    "pull_interval": 0.15,
    "pull_step": 8.0,
    "field_interval": 0.5,
    "execute_ratio": 0.1,
    "visual_scale": 0.75,
    "create_fps": 10.0,
    "active_fps": 5.0,
    "disappear_fps": 10.0
  },
  "sage_astra_binary_stars": {
    "name": "쌍성의 고리",
    "owner": "sage_astra",
    "pattern": "orbit",
    "color": "c6abff",
    "cooldown": 1.74,
    "range": 325,
    "power": 1.6,
    "base_hits": 1,
    "effect": "회전 수호체 타격",
    "evolution": "쌍성의 고리 · 각성",
    "tags": [
      "area"
    ],
    "effect_dir": "res://assets/art/heroes/stage10_sage/frames/effect1",
    "source_skill": "고유 기본공격",
    "hit_cap": 8
  }
}
const PASSIVES := {
  "survival_power": {
    "name": "공격력 증가",
    "description": "전체 무기 피해 +8% / 레벨",
    "stat": "power",
    "value": 0.08
  },
  "survival_mobility": {
    "name": "이동속도 증가",
    "description": "기본 이동속도 +3% / 레벨",
    "stat": "mobility",
    "value": 0.03
  },
  "survival_projectile": {
    "name": "투사체속도 증가",
    "description": "발사체 이동속도 +10% / 레벨\n즉시 타격·장판·검격에는 적용되지 않습니다.",
    "stat": "projectile",
    "value": 0.1
  },
  "survival_haste": {
    "name": "공격속도 증가",
    "description": "전체 무기 공격 빈도 +5% / 레벨",
    "stat": "haste",
    "value": 0.05
  },
  "survival_learning": {
    "name": "경험치 증가",
    "description": "획득 경험치 +3% / 레벨",
    "stat": "learning",
    "value": 0.03
  },
  "survival_magnet": {
    "name": "경험치 범위 증가",
    "description": "경험치 획득 반경 +15% / 레벨",
    "stat": "magnet",
    "value": 0.15
  },
  "survival_vitality": {
    "name": "최대체력 증가",
    "description": "시작 최대 HP +5% · 증가분 회복 / 레벨",
    "stat": "vitality",
    "value": 0.05
  },
  "survival_armor": {
    "name": "받는피해 감소",
    "description": "받는 피해 -3% / 레벨 · 최대 30%",
    "stat": "armor",
    "value": 0.03
  }
}
static func is_weapon(id: String) -> bool:
	return WEAPONS.has(id)
static func weapon_pool(hero_id: String = "") -> Array:
	return HERO_WEAPONS.get(hero_id,[]) if not hero_id.is_empty() else WEAPONS.keys()
static func description(id: String, next_level: int) -> String:
	if PASSIVES.has(id): return String(PASSIVES[id].description)
	var data: Dictionary = WEAPONS.get(id,{})
	return "%s\n피해·범위·빈도 성장 / Lv.5 타격 수 증가 / Lv.10 상자 진화\n선택 후 Lv.%d / 10" % [String(data.get("effect","무기 공격"))+"\n원형 기술: "+String(data.get("source_skill","고유 기본공격")),next_level]
static func profile_for_survival(source: Dictionary) -> Dictionary:
	var result := source.duplicate(true)
	result["max_hp"] = 1200
	result["attack_damage"] = 26
	result["move_speed"] = 270.0
	result["level_growth"] = {}
	return result
