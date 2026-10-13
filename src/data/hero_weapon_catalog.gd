extends RefCounted
const MAX_LEVEL := 10
const WEAPON_SLOTS := 3
const PASSIVE_SLOTS := 6
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
    ]
  },
  "ranged_rookie_star_wand": {
    "name": "별빛 지팡이",
    "owner": "ranged_rookie",
    "pattern": "chain",
    "color": "a9eece",
    "cooldown": 2.27,
    "range": 575,
    "power": 1.12,
    "base_hits": 1,
    "effect": "다수 표적 연쇄 타격",
    "evolution": "별빛 지팡이 · 각성",
    "tags": [
      "damage"
    ]
  },
  "ranged_rookie_magic_lance": {
    "name": "마력 창",
    "owner": "ranged_rookie",
    "pattern": "beam",
    "color": "ffe09a",
    "cooldown": 3.48,
    "range": 800,
    "power": 1.24,
    "base_hits": 1,
    "effect": "직선 관통",
    "evolution": "마력 창 · 각성",
    "tags": [
      "damage"
    ]
  },
  "ranged_rookie_rune_ring": {
    "name": "룬 고리",
    "owner": "ranged_rookie",
    "pattern": "orbit",
    "color": "8adcc5",
    "cooldown": 1.5,
    "range": 325,
    "power": 1.36,
    "base_hits": 1,
    "effect": "회전 수호체 타격",
    "evolution": "룬 고리 · 각성",
    "tags": [
      "area"
    ]
  },
  "ranged_rookie_pulse_staff": {
    "name": "파동 지팡이",
    "owner": "ranged_rookie",
    "pattern": "nova",
    "color": "bb95f1",
    "cooldown": 3.46,
    "range": 240,
    "power": 1.48,
    "base_hits": 1,
    "effect": "광역 폭발",
    "evolution": "파동 지팡이 · 각성",
    "tags": [
      "area"
    ]
  },
  "ranged_rookie_barrier_book": {
    "name": "결계의 서",
    "owner": "ranged_rookie",
    "pattern": "guard",
    "color": "cee2ff",
    "cooldown": 10.44,
    "range": 275,
    "power": 1.6,
    "base_hits": 1,
    "effect": "보호막·충격파",
    "evolution": "결계의 서 · 각성",
    "tags": [
      "durability"
    ]
  },
  "swift_hunter_dagger": {
    "name": "쌍단검",
    "owner": "swift_hunter",
    "pattern": "slash",
    "color": "f1a78e",
    "cooldown": 1.3,
    "range": 200,
    "power": 1.0,
    "base_hits": 2,
    "effect": "전방 부채꼴 공격",
    "evolution": "쌍단검 · 각성",
    "tags": [
      "damage"
    ]
  },
  "swift_hunter_throwing_knife": {
    "name": "투척 단검",
    "owner": "swift_hunter",
    "pattern": "bolt",
    "color": "bca4ed",
    "cooldown": 1.08,
    "range": 645,
    "power": 1.12,
    "base_hits": 1,
    "effect": "표적 마력 타격",
    "evolution": "투척 단검 · 각성",
    "tags": [
      "damage"
    ]
  },
  "swift_hunter_shadow_wire": {
    "name": "그림자 와이어",
    "owner": "swift_hunter",
    "pattern": "chain",
    "color": "a9eece",
    "cooldown": 2.44,
    "range": 550,
    "power": 1.24,
    "base_hits": 1,
    "effect": "다수 표적 연쇄 타격",
    "evolution": "그림자 와이어 · 각성",
    "tags": [
      "damage"
    ]
  },
  "swift_hunter_poison_needle": {
    "name": "독침",
    "owner": "swift_hunter",
    "pattern": "poison",
    "color": "a2d766",
    "cooldown": 2.2,
    "range": 375,
    "power": 1.36,
    "base_hits": 1,
    "effect": "지속 피해 장판",
    "evolution": "독침 · 각성",
    "tags": [
      "area"
    ]
  },
  "swift_hunter_moon_blade": {
    "name": "초승달 칼날",
    "owner": "swift_hunter",
    "pattern": "orbit",
    "color": "8adcc5",
    "cooldown": 1.62,
    "range": 300,
    "power": 1.48,
    "base_hits": 1,
    "effect": "회전 수호체 타격",
    "evolution": "초승달 칼날 · 각성",
    "tags": [
      "area"
    ]
  },
  "swift_hunter_shadow_bomb": {
    "name": "그림자 폭탄",
    "owner": "swift_hunter",
    "pattern": "nova",
    "color": "bb95f1",
    "cooldown": 3.71,
    "range": 265,
    "power": 1.6,
    "base_hits": 1,
    "effect": "광역 폭발",
    "evolution": "그림자 폭탄 · 각성",
    "tags": [
      "area"
    ]
  },
  "sword_shield_hero_longsword": {
    "name": "수호 장검",
    "owner": "sword_shield_hero",
    "pattern": "slash",
    "color": "f1a78e",
    "cooldown": 1.3,
    "range": 200,
    "power": 1.0,
    "base_hits": 1,
    "effect": "전방 부채꼴 공격",
    "evolution": "수호 장검 · 각성",
    "tags": [
      "damage"
    ]
  },
  "sword_shield_hero_piercing_spear": {
    "name": "돌파 창",
    "owner": "sword_shield_hero",
    "pattern": "beam",
    "color": "ffe09a",
    "cooldown": 3.24,
    "range": 825,
    "power": 1.12,
    "base_hits": 1,
    "effect": "직선 관통",
    "evolution": "돌파 창 · 각성",
    "tags": [
      "damage"
    ]
  },
  "sword_shield_hero_aegis": {
    "name": "수호 방패",
    "owner": "sword_shield_hero",
    "pattern": "guard",
    "color": "cee2ff",
    "cooldown": 10.44,
    "range": 250,
    "power": 1.24,
    "base_hits": 1,
    "effect": "보호막·충격파",
    "evolution": "수호 방패 · 각성",
    "tags": [
      "durability"
    ]
  },
  "sword_shield_hero_shield_hammer": {
    "name": "방패 망치",
    "owner": "sword_shield_hero",
    "pattern": "nova",
    "color": "bb95f1",
    "cooldown": 3.2,
    "range": 265,
    "power": 1.36,
    "base_hits": 1,
    "effect": "광역 폭발",
    "evolution": "방패 망치 · 각성",
    "tags": [
      "area"
    ]
  },
  "sword_shield_hero_blade_ring": {
    "name": "회전 검륜",
    "owner": "sword_shield_hero",
    "pattern": "orbit",
    "color": "8adcc5",
    "cooldown": 1.62,
    "range": 300,
    "power": 1.48,
    "base_hits": 1,
    "effect": "회전 수호체 타격",
    "evolution": "회전 검륜 · 각성",
    "tags": [
      "area"
    ]
  },
  "sword_shield_hero_battle_banner": {
    "name": "전장의 깃발",
    "owner": "sword_shield_hero",
    "pattern": "heal",
    "color": "efbdcf",
    "cooldown": 13.92,
    "range": 305,
    "power": 1.6,
    "base_hits": 1,
    "effect": "회복·주변 파동",
    "evolution": "전장의 깃발 · 각성",
    "tags": [
      "durability"
    ]
  },
  "pistol_hero_revolver": {
    "name": "육연발 권총",
    "owner": "pistol_hero",
    "pattern": "bolt",
    "color": "ffe09a",
    "cooldown": 1.0,
    "range": 620,
    "power": 1.0,
    "base_hits": 1,
    "effect": "표적 마력 타격",
    "evolution": "육연발 권총 · 각성",
    "tags": [
      "damage"
    ]
  },
  "pistol_hero_shotgun": {
    "name": "확산 산탄총",
    "owner": "pistol_hero",
    "pattern": "slash",
    "color": "f1a78e",
    "cooldown": 1.4,
    "range": 225,
    "power": 1.12,
    "base_hits": 2,
    "effect": "전방 부채꼴 공격",
    "evolution": "확산 산탄총 · 각성",
    "tags": [
      "damage"
    ]
  },
  "pistol_hero_rifle": {
    "name": "관통 소총",
    "owner": "pistol_hero",
    "pattern": "beam",
    "color": "ffe09a",
    "cooldown": 3.48,
    "range": 800,
    "power": 1.24,
    "base_hits": 1,
    "effect": "직선 관통",
    "evolution": "관통 소총 · 각성",
    "tags": [
      "damage"
    ]
  },
  "pistol_hero_ricochet": {
    "name": "도탄 권총",
    "owner": "pistol_hero",
    "pattern": "chain",
    "color": "a9eece",
    "cooldown": 2.1,
    "range": 575,
    "power": 1.36,
    "base_hits": 1,
    "effect": "다수 표적 연쇄 타격",
    "evolution": "도탄 권총 · 각성",
    "tags": [
      "damage"
    ]
  },
  "pistol_hero_grenade": {
    "name": "충격 수류탄",
    "owner": "pistol_hero",
    "pattern": "nova",
    "color": "bb95f1",
    "cooldown": 3.46,
    "range": 240,
    "power": 1.48,
    "base_hits": 1,
    "effect": "광역 폭발",
    "evolution": "충격 수류탄 · 각성",
    "tags": [
      "area"
    ]
  },
  "pistol_hero_powder_bomb": {
    "name": "화약 폭탄",
    "owner": "pistol_hero",
    "pattern": "poison",
    "color": "ed9b5f",
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
    "field_radius_ratio": 0.5
  },
  "archmage_hero_fire_staff": {
    "name": "화염 지팡이",
    "owner": "archmage_hero",
    "pattern": "poison",
    "color": "ed9b5f",
    "cooldown": 2.2,
    "range": 350,
    "power": 1.0,
    "base_hits": 1,
    "effect": "화염 장판 · 짧고 빠른 연소 피해",
    "evolution": "화염 지팡이 · 각성",
    "tags": [
      "area"
    ],
    "field_duration": 2.0,
    "field_interval": 0.35
  },
  "archmage_hero_ice_scepter": {
    "name": "빙결 홀",
    "owner": "archmage_hero",
    "pattern": "frost",
    "color": "9dcdf7",
    "cooldown": 2.7,
    "range": 445,
    "power": 1.12,
    "base_hits": 1,
    "effect": "냉기 폭발·둔화",
    "evolution": "빙결 홀 · 각성",
    "tags": [
      "damage"
    ]
  },
  "archmage_hero_lightning_rod": {
    "name": "뇌전 지팡이",
    "owner": "archmage_hero",
    "pattern": "chain",
    "color": "a9eece",
    "cooldown": 2.44,
    "range": 550,
    "power": 1.24,
    "base_hits": 1,
    "effect": "다수 표적 연쇄 타격",
    "evolution": "뇌전 지팡이 · 각성",
    "tags": [
      "damage"
    ]
  },
  "archmage_hero_earth_staff": {
    "name": "대지 지팡이",
    "owner": "archmage_hero",
    "pattern": "nova",
    "color": "bb95f1",
    "cooldown": 3.2,
    "range": 265,
    "power": 1.36,
    "base_hits": 1,
    "effect": "광역 폭발",
    "evolution": "대지 지팡이 · 각성",
    "tags": [
      "area"
    ]
  },
  "archmage_hero_storm_orb": {
    "name": "폭풍 구체",
    "owner": "archmage_hero",
    "pattern": "orbit",
    "color": "8adcc5",
    "cooldown": 1.62,
    "range": 300,
    "power": 1.48,
    "base_hits": 1,
    "effect": "회전 수호체 타격",
    "evolution": "폭풍 구체 · 각성",
    "tags": [
      "area"
    ]
  },
  "archmage_hero_prism_wand": {
    "name": "프리즘 완드",
    "owner": "archmage_hero",
    "pattern": "beam",
    "color": "ffe09a",
    "cooldown": 3.48,
    "range": 825,
    "power": 1.6,
    "base_hits": 1,
    "effect": "직선 관통",
    "evolution": "프리즘 완드 · 각성",
    "tags": [
      "damage"
    ]
  },
  "madness_hero_blood_sword": {
    "name": "혈검",
    "owner": "madness_hero",
    "pattern": "slash",
    "color": "db596f",
    "cooldown": 1.3,
    "range": 200,
    "power": 1.0,
    "base_hits": 1,
    "effect": "전방 부채꼴 공격",
    "evolution": "혈검 · 각성",
    "tags": [
      "damage"
    ]
  },
  "madness_hero_blood_lance": {
    "name": "혈창",
    "owner": "madness_hero",
    "pattern": "beam",
    "color": "db596f",
    "cooldown": 3.24,
    "range": 825,
    "power": 1.12,
    "base_hits": 1,
    "effect": "직선 관통",
    "evolution": "혈창 · 각성",
    "tags": [
      "damage"
    ]
  },
  "madness_hero_blood_wheel": {
    "name": "핏빛 검륜",
    "owner": "madness_hero",
    "pattern": "orbit",
    "color": "db596f",
    "cooldown": 1.74,
    "range": 300,
    "power": 1.24,
    "base_hits": 1,
    "effect": "회전 수호체 타격",
    "evolution": "핏빛 검륜 · 각성",
    "tags": [
      "area"
    ]
  },
  "madness_hero_blood_burst": {
    "name": "혈폭",
    "owner": "madness_hero",
    "pattern": "nova",
    "color": "db596f",
    "cooldown": 3.2,
    "range": 265,
    "power": 1.36,
    "base_hits": 1,
    "effect": "광역 폭발",
    "evolution": "혈폭 · 각성",
    "tags": [
      "area"
    ]
  },
  "madness_hero_drain_blade": {
    "name": "흡혈 검",
    "owner": "madness_hero",
    "pattern": "heal",
    "color": "efbdcf",
    "cooldown": 12.96,
    "range": 280,
    "power": 1.48,
    "base_hits": 1,
    "effect": "회복·주변 파동",
    "evolution": "흡혈 검 · 각성",
    "tags": [
      "durability"
    ]
  },
  "madness_hero_heart_chain": {
    "name": "심장 사슬",
    "owner": "madness_hero",
    "pattern": "chain",
    "color": "a9eece",
    "cooldown": 2.44,
    "range": 575,
    "power": 1.6,
    "base_hits": 1,
    "effect": "다수 표적 연쇄 타격",
    "evolution": "심장 사슬 · 각성",
    "tags": [
      "damage"
    ]
  },
  "chemical_hero_acid_vial": {
    "name": "산성 약병",
    "owner": "chemical_hero",
    "pattern": "poison",
    "color": "a2d766",
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
    "field_radius_ratio": 0.45
  },
  "chemical_hero_poison_flask": {
    "name": "독성 플라스크",
    "owner": "chemical_hero",
    "pattern": "poison",
    "color": "b7d94d",
    "cooldown": 2.38,
    "range": 375,
    "power": 1.12,
    "base_hits": 1,
    "effect": "큰 독성 장판 · 5초간 지속 피해",
    "evolution": "독성 플라스크 · 각성",
    "tags": [
      "area"
    ],
    "field_duration": 5.0,
    "field_interval": 1.0,
    "field_radius_ratio": 0.6
  },
  "chemical_hero_cryo_vial": {
    "name": "냉각 약병",
    "owner": "chemical_hero",
    "pattern": "frost",
    "color": "9dcdf7",
    "cooldown": 2.9,
    "range": 420,
    "power": 1.24,
    "base_hits": 1,
    "effect": "냉기 폭발·둔화",
    "evolution": "냉각 약병 · 각성",
    "tags": [
      "damage"
    ]
  },
  "chemical_hero_reaction_bomb": {
    "name": "반응 폭탄",
    "owner": "chemical_hero",
    "pattern": "nova",
    "color": "bb95f1",
    "cooldown": 3.2,
    "range": 265,
    "power": 1.36,
    "base_hits": 1,
    "effect": "광역 폭발",
    "evolution": "반응 폭탄 · 각성",
    "tags": [
      "area"
    ]
  },
  "chemical_hero_acid_cannon": {
    "name": "압축 산성포",
    "owner": "chemical_hero",
    "pattern": "beam",
    "color": "ffe09a",
    "cooldown": 3.24,
    "range": 800,
    "power": 1.48,
    "base_hits": 1,
    "effect": "직선 관통",
    "evolution": "압축 산성포 · 각성",
    "tags": [
      "damage"
    ]
  },
  "chemical_hero_life_elixir": {
    "name": "생명 비약",
    "owner": "chemical_hero",
    "pattern": "heal",
    "color": "efbdcf",
    "cooldown": 13.92,
    "range": 305,
    "power": 1.6,
    "base_hits": 1,
    "effect": "회복·주변 파동",
    "evolution": "생명 비약 · 각성",
    "tags": [
      "durability"
    ]
  },
  "summoner_hero_gate_hound": {
    "name": "이계 투견 수호체",
    "owner": "summoner_hero",
    "pattern": "orbit",
    "color": "8adcc5",
    "cooldown": 1.5,
    "range": 250,
    "power": 1.0,
    "base_hits": 1,
    "effect": "가까이 회전하는 투견 수호체 2개",
    "evolution": "이계 투견 수호체 · 각성",
    "tags": [
      "area"
    ],
    "orbit_count": 2,
    "orbit_speed": 4.5,
    "orbit_ratio": 0.5
  },
  "summoner_hero_watcher": {
    "name": "감시자 수호체",
    "owner": "summoner_hero",
    "pattern": "orbit",
    "color": "a8b4f4",
    "cooldown": 1.62,
    "range": 350,
    "power": 1.12,
    "base_hits": 1,
    "effect": "넓게 회전하는 감시자 수호체 4개",
    "evolution": "감시자 수호체 · 각성",
    "tags": [
      "area"
    ],
    "orbit_count": 4,
    "orbit_speed": 2.5,
    "orbit_ratio": 0.85
  },
  "summoner_hero_scout": {
    "name": "정찰병 발사체",
    "owner": "summoner_hero",
    "pattern": "bolt",
    "color": "88dcc1",
    "cooldown": 1.16,
    "range": 620,
    "power": 1.24,
    "base_hits": 2,
    "effect": "표적 마력 타격",
    "evolution": "정찰병 발사체 · 각성",
    "tags": [
      "damage"
    ]
  },
  "summoner_hero_gate_laser": {
    "name": "차원 관통문",
    "owner": "summoner_hero",
    "pattern": "beam",
    "color": "ffe09a",
    "cooldown": 3.0,
    "range": 825,
    "power": 1.36,
    "base_hits": 1,
    "effect": "직선 관통",
    "evolution": "차원 관통문 · 각성",
    "tags": [
      "damage"
    ]
  },
  "summoner_hero_gatekeeper": {
    "name": "문지기 방벽",
    "owner": "summoner_hero",
    "pattern": "guard",
    "color": "cee2ff",
    "cooldown": 9.72,
    "range": 250,
    "power": 1.48,
    "base_hits": 1,
    "effect": "보호막·충격파",
    "evolution": "문지기 방벽 · 각성",
    "tags": [
      "durability"
    ]
  },
  "summoner_hero_rift_pulse": {
    "name": "균열 파동",
    "owner": "summoner_hero",
    "pattern": "nova",
    "color": "bb95f1",
    "cooldown": 3.71,
    "range": 265,
    "power": 1.6,
    "base_hits": 1,
    "effect": "광역 폭발",
    "evolution": "균열 파동 · 각성",
    "tags": [
      "area"
    ]
  },
  "purifier_hero_holy_bolt": {
    "name": "성광탄",
    "owner": "purifier_hero",
    "pattern": "bolt",
    "color": "fff2b0",
    "cooldown": 1.0,
    "range": 620,
    "power": 1.0,
    "base_hits": 1,
    "effect": "표적 마력 타격",
    "evolution": "성광탄 · 각성",
    "tags": [
      "damage"
    ]
  },
  "purifier_hero_holy_lance": {
    "name": "정화의 성창",
    "owner": "purifier_hero",
    "pattern": "beam",
    "color": "ffe09a",
    "cooldown": 3.24,
    "range": 825,
    "power": 1.12,
    "base_hits": 1,
    "effect": "직선 관통",
    "evolution": "정화의 성창 · 각성",
    "tags": [
      "damage"
    ]
  },
  "purifier_hero_purification": {
    "name": "정화 향로",
    "owner": "purifier_hero",
    "pattern": "nova",
    "color": "bb95f1",
    "cooldown": 3.71,
    "range": 240,
    "power": 1.24,
    "base_hits": 1,
    "effect": "광역 폭발",
    "evolution": "정화 향로 · 각성",
    "tags": [
      "area"
    ]
  },
  "purifier_hero_sacred_orb": {
    "name": "성스러운 구체",
    "owner": "purifier_hero",
    "pattern": "orbit",
    "color": "8adcc5",
    "cooldown": 1.5,
    "range": 325,
    "power": 1.36,
    "base_hits": 1,
    "effect": "회전 수호체 타격",
    "evolution": "성스러운 구체 · 각성",
    "tags": [
      "area"
    ]
  },
  "purifier_hero_blessing": {
    "name": "축복의 성서",
    "owner": "purifier_hero",
    "pattern": "guard",
    "color": "cee2ff",
    "cooldown": 9.72,
    "range": 250,
    "power": 1.48,
    "base_hits": 1,
    "effect": "보호막·충격파",
    "evolution": "축복의 성서 · 각성",
    "tags": [
      "durability"
    ]
  },
  "purifier_hero_prayer": {
    "name": "회복의 성배",
    "owner": "purifier_hero",
    "pattern": "heal",
    "color": "efbdcf",
    "cooldown": 13.92,
    "range": 305,
    "power": 1.6,
    "base_hits": 1,
    "effect": "회복·주변 파동",
    "evolution": "회복의 성배 · 각성",
    "tags": [
      "durability"
    ]
  },
  "sage_astra_starlight": {
    "name": "별빛 지팡이",
    "owner": "sage_astra",
    "pattern": "bolt",
    "color": "c3a7ff",
    "cooldown": 1.0,
    "range": 620,
    "power": 1.0,
    "base_hits": 1,
    "effect": "표적 마력 타격",
    "evolution": "별빛 지팡이 · 각성",
    "tags": [
      "damage"
    ]
  },
  "sage_astra_comet": {
    "name": "혜성의 창",
    "owner": "sage_astra",
    "pattern": "beam",
    "color": "ffe09a",
    "cooldown": 3.24,
    "range": 825,
    "power": 1.12,
    "base_hits": 1,
    "effect": "직선 관통",
    "evolution": "혜성의 창 · 각성",
    "tags": [
      "damage"
    ]
  },
  "sage_astra_astral_chain": {
    "name": "천체 사슬",
    "owner": "sage_astra",
    "pattern": "chain",
    "color": "a9eece",
    "cooldown": 2.44,
    "range": 550,
    "power": 1.24,
    "base_hits": 1,
    "effect": "다수 표적 연쇄 타격",
    "evolution": "천체 사슬 · 각성",
    "tags": [
      "damage"
    ]
  },
  "sage_astra_absolute_zero": {
    "name": "빙점의 구체",
    "owner": "sage_astra",
    "pattern": "frost",
    "color": "9dcdf7",
    "cooldown": 2.5,
    "range": 445,
    "power": 1.36,
    "base_hits": 1,
    "effect": "냉기 폭발·둔화",
    "evolution": "빙점의 구체 · 각성",
    "tags": [
      "damage"
    ]
  },
  "sage_astra_singularity": {
    "name": "중력 특이점",
    "owner": "sage_astra",
    "pattern": "nova",
    "color": "bb95f1",
    "cooldown": 3.46,
    "range": 240,
    "power": 1.48,
    "base_hits": 1,
    "effect": "광역 폭발",
    "evolution": "중력 특이점 · 각성",
    "tags": [
      "area"
    ]
  },
  "sage_astra_binary_stars": {
    "name": "쌍성의 고리",
    "owner": "sage_astra",
    "pattern": "orbit",
    "color": "8adcc5",
    "cooldown": 1.74,
    "range": 325,
    "power": 1.6,
    "base_hits": 1,
    "effect": "회전 수호체 타격",
    "evolution": "쌍성의 고리 · 각성",
    "tags": [
      "area"
    ]
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
    "description": "획득 경험치 +8% / 레벨",
    "stat": "learning",
    "value": 0.08
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
	return "%s\n피해·범위·빈도 성장 / Lv.5 타격 수 증가 / Lv.10 상자 진화\n선택 후 Lv.%d / 10" % [String(data.get("effect","무기 공격")),next_level]
static func profile_for_survival(source: Dictionary) -> Dictionary:
	var result := source.duplicate(true)
	result["max_hp"] = 1200
	result["attack_damage"] = 26
	result["move_speed"] = 270.0
	result["level_growth"] = {}
	return result
