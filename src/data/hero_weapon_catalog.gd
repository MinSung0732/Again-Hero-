extends RefCounted
const CARD_TEXT := preload("res://src/data/hero_weapon_card_text.gd")
const ATTACKS := preload("res://src/data/hero_weapon_attack_catalog.gd")
const GROWTH := preload("res://src/data/hero_weapon_growth_catalog.gd")
const DELIVERY := preload("res://src/data/hero_weapon_delivery_catalog.gd")
const INVENTORY_SUMMON_TEXT := {
	"hound":"이계의 사냥개를 불러 적을 추적하고 근접 연격으로 몰아붙입니다.",
	"scout":"차원 정찰병을 불러 전선을 누비며 가까운 적을 베게 합니다.",
	"watcher":"용사를 따라다니는 차원의 감시자가 적에게 빠르게 원거리 사격을 합니다. 감시자는 피해를 받지 않고 시간이 지나면 귀환합니다.",
	"gatekeeper":"차원의 문지기가 적을 향해 무거운 투사체를 발사합니다.",
}
const MAX_LEVEL := 10
const WEAPON_SLOTS := 6
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
    "ranged_rookie_barrier_book",
    "ranged_rookie_sealing_bolt",
    "ranged_rookie_satellite_orbs",
    "ranged_rookie_rune_ray",
    "ranged_rookie_restoration_codex"
  ],
  "swift_hunter": [
    "swift_hunter_dagger",
    "swift_hunter_throwing_knife",
    "swift_hunter_shadow_wire",
    "swift_hunter_poison_needle",
    "swift_hunter_moon_blade",
    "swift_hunter_shadow_bomb",
    "swift_hunter_execution_stiletto",
    "swift_hunter_binding_wire",
    "swift_hunter_smoke_mantle",
    "swift_hunter_venom_steps"
  ],
  "sword_shield_hero": [
    "sword_shield_hero_longsword",
    "sword_shield_hero_piercing_spear",
    "sword_shield_hero_aegis",
    "sword_shield_hero_shield_hammer",
    "sword_shield_hero_blade_ring",
    "sword_shield_hero_battle_banner",
    "sword_shield_hero_oath_blade",
    "sword_shield_hero_ward_crossbow",
    "sword_shield_hero_sanctuary_shield",
    "sword_shield_hero_rally_standard"
  ],
  "pistol_hero": [
    "pistol_hero_revolver",
    "pistol_hero_shotgun",
    "pistol_hero_rifle",
    "pistol_hero_ricochet",
    "pistol_hero_grenade",
    "pistol_hero_powder_bomb",
    "pistol_hero_twin_pistols",
    "pistol_hero_shrapnel_round",
    "pistol_hero_suppressor",
    "pistol_hero_smoke_canister"
  ],
  "archmage_hero": [
    "archmage_hero_fire_staff",
    "archmage_hero_ice_scepter",
    "archmage_hero_lightning_rod",
    "archmage_hero_earth_staff",
    "archmage_hero_storm_orb",
    "archmage_hero_prism_wand",
    "archmage_hero_lava_focus",
    "archmage_hero_frost_moons",
    "archmage_hero_gale_prism",
    "archmage_hero_sunfire_tome"
  ],
  "madness_hero": [
    "madness_hero_blood_sword",
    "madness_hero_blood_lance",
    "madness_hero_blood_wheel",
    "madness_hero_blood_burst",
    "madness_hero_drain_blade",
    "madness_hero_heart_chain",
    "madness_hero_desperate_cleaver",
    "madness_hero_vampire_fang",
    "madness_hero_blood_thorns",
    "madness_hero_blood_aegis"
  ],
  "chemical_hero": [
    "chemical_hero_acid_vial",
    "chemical_hero_poison_flask",
    "chemical_hero_cryo_vial",
    "chemical_hero_reaction_bomb",
    "chemical_hero_acid_cannon",
    "chemical_hero_life_elixir",
    "chemical_hero_caustic_boots",
    "chemical_hero_catalyst_wire",
    "chemical_hero_toxic_dart",
    "chemical_hero_antidote_capsule"
  ],
  "summoner_hero": [
    "summoner_hero_gate_hound",
    "summoner_hero_watcher",
    "summoner_hero_scout",
    "summoner_hero_gate_laser",
    "summoner_hero_gatekeeper",
    "summoner_hero_rift_pulse",
    "summoner_hero_rift_orbit",
    "summoner_hero_collapse_glyph",
    "summoner_hero_gate_shard",
    "summoner_hero_binding_gate"
  ],
  "purifier_hero": [
    "purifier_hero_holy_bolt",
    "purifier_hero_holy_lance",
    "purifier_hero_purification",
    "purifier_hero_sacred_orb",
    "purifier_hero_blessing",
    "purifier_hero_prayer",
    "purifier_hero_mercy_chain",
    "purifier_hero_judgment_seal",
    "purifier_hero_saint_reliquary",
    "purifier_hero_martyr_blade"
  ],
  "sage_astra": [
    "sage_astra_starlight",
    "sage_astra_comet",
    "sage_astra_astral_chain",
    "sage_astra_absolute_zero",
    "sage_astra_singularity",
    "sage_astra_binary_stars",
    "sage_astra_gravity_lance",
    "sage_astra_frozen_stars",
    "sage_astra_supernova_core",
    "sage_astra_collapsed_seed"
  ]
}
const WEAPONS := {
  "ranged_rookie_arcane_bolt": {
    "name": "마력탄",
    "owner": "ranged_rookie",
    "pattern": "bolt",
    "color": "71ffca",
    "cooldown": 0.95,
    "range": 600,
    "power": 1.35,
    "base_hits": 1,
    "effect": "표적 마력 타격",
    "evolution": "유성우 마도포",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/ranged_rookie_arcane_bolt/frames",
    "source_skill": "고유 기본공격",
    "hit_cap": 16,
    "weapon_id": "ranged_rookie_arcane_bolt"
  },
  "ranged_rookie_star_wand": {
    "name": "별빛 지팡이",
    "owner": "ranged_rookie",
    "pattern": "chain",
    "color": "aeffed",
    "cooldown": 2.8,
    "range": 470,
    "power": 0.8,
    "base_hits": 3,
    "effect": "가까운 적 사이로 최대 3회 연쇄",
    "evolution": "은하 연결 지팡이",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/ranged_rookie_star_wand/frames",
    "source_skill": "고유 기본공격",
    "hit_cap": 16,
    "chain_radius": 180,
    "weapon_id": "ranged_rookie_star_wand"
  },
  "ranged_rookie_magic_lance": {
    "name": "마력 관통포",
    "owner": "ranged_rookie",
    "pattern": "piercer",
    "color": "71fff4",
    "cooldown": 5.5,
    "range": 760,
    "power": 2.7,
    "base_hits": 1,
    "effect": "실제 마력 관통탄 · 직선의 적 관통",
    "evolution": "삼중 비전 관통포",
    "tags": [
      "damage"
    ],
    "effect_dir": "res://assets/art/heroes/stage1_mage/frames/effect_01",
    "source_skill": "마력 관통포",
    "hit_cap": 8,
    "projectile_speed": 950.0,
    "weapon_id": "ranged_rookie_magic_lance"
  },
  "ranged_rookie_rune_ring": {
    "name": "비전 집중",
    "owner": "ranged_rookie",
    "pattern": "poison",
    "color": "aefaff",
    "cooldown": 5.8,
    "range": 300,
    "power": 0.9,
    "base_hits": 1,
    "effect": "이동을 따라오는 비전 집중 · 2.5초간 주변 연속 타격",
    "evolution": "이동 비전 성역",
    "tags": [
      "area"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/ranged_rookie_rune_ring/frames",
    "source_skill": "비전 집중",
    "hit_cap": 8,
    "field_follow": true,
    "field_duration": 3.0,
    "field_interval": 0.5,
    "field_power": 0.28,
    "field_radius_ratio": 0.42,
    "weapon_id": "ranged_rookie_rune_ring"
  },
  "ranged_rookie_pulse_staff": {
    "name": "파동 지팡이",
    "owner": "ranged_rookie",
    "pattern": "nova",
    "color": "71e1ff",
    "cooldown": 4.2,
    "range": 245,
    "power": 1.1,
    "base_hits": 1,
    "effect": "광역 폭발",
    "evolution": "삼중 공명 지팡이",
    "tags": [
      "area"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/ranged_rookie_pulse_staff/frames",
    "source_skill": "고유 기본공격",
    "hit_cap": 16,
    "weapon_id": "ranged_rookie_pulse_staff"
  },
  "ranged_rookie_barrier_book": {
    "name": "마력 장벽",
    "owner": "ranged_rookie",
    "pattern": "guard",
    "color": "aee2ff",
    "cooldown": 12,
    "range": 180,
    "power": 0.45,
    "base_hits": 1,
    "effect": "마력 보호막 · 주변 충격파",
    "evolution": "비전 반격 성전",
    "tags": [
      "durability"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/ranged_rookie_barrier_book/frames",
    "source_skill": "마력 장벽",
    "hit_cap": 16,
    "shield_ratio": 0.07,
    "weapon_id": "ranged_rookie_barrier_book"
  },
  "swift_hunter_dagger": {
    "name": "쌍단검",
    "owner": "swift_hunter",
    "pattern": "combo",
    "color": "8da8eb",
    "cooldown": 0.85,
    "range": 210,
    "power": 0.85,
    "base_hits": 2,
    "effect": "같은 표적을 짧은 간격으로 2연속 찌르기",
    "evolution": "그림자 육연검",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/swift_hunter_dagger/frames",
    "source_skill": "고유 기본공격",
    "hit_cap": 8,
    "hit_interval": 0.14,
    "weapon_id": "swift_hunter_dagger"
  },
  "swift_hunter_throwing_knife": {
    "name": "투척 단검",
    "owner": "swift_hunter",
    "pattern": "bolt",
    "color": "bec3f4",
    "cooldown": 1.35,
    "range": 520,
    "power": 1.9,
    "base_hits": 1,
    "effect": "표적 마력 타격",
    "evolution": "폭우 암살 단검",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/swift_hunter_throwing_knife/frames",
    "source_skill": "고유 기본공격",
    "hit_cap": 16,
    "weapon_id": "swift_hunter_throwing_knife"
  },
  "swift_hunter_shadow_wire": {
    "name": "급습-암살",
    "owner": "swift_hunter",
    "pattern": "combo",
    "color": "958deb",
    "cooldown": 3.8,
    "range": 240,
    "power": 1.15,
    "base_hits": 2,
    "effect": "근접 표적 3연격 · 체력 10% 이하 마무리",
    "evolution": "처형자의 그림자",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/swift_hunter_shadow_wire/frames",
    "source_skill": "급습-암살",
    "hit_cap": 16,
    "hit_interval": 0.18,
    "execute_ratio": 0.1,
    "weapon_id": "swift_hunter_shadow_wire"
  },
  "swift_hunter_poison_needle": {
    "name": "독침",
    "owner": "swift_hunter",
    "pattern": "bolt",
    "color": "d8be52",
    "cooldown": 1.1,
    "range": 430,
    "power": 0.75,
    "base_hits": 1,
    "effect": "독침이 남기는 작은 독 영역 · 2초 지속",
    "evolution": "만독 암살진",
    "tags": [
      "area"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/swift_hunter_poison_needle/frames",
    "source_skill": "고유 기본공격",
    "hit_cap": 16,
    "field_duration": 2.0,
    "field_interval": 0.4,
    "field_power": 0.28,
    "weapon_id": "swift_hunter_poison_needle",
    "splash_radius": 45,
    "splash_ratio": 0.18,
    "slow_multiplier": 0.8,
    "slow_duration": 0.6
  },
  "swift_hunter_moon_blade": {
    "name": "난도질",
    "owner": "swift_hunter",
    "pattern": "slash",
    "color": "cdbef4",
    "cooldown": 2.2,
    "range": 205,
    "power": 1.65,
    "base_hits": 1,
    "effect": "1.2초 이동형 검무 · 가까운 적 연속 타격",
    "evolution": "월식 난도질",
    "tags": [
      "area"
    ],
    "effect_dir": "res://assets/art/heroes/stage2_rogue/frames/effect_03",
    "source_skill": "난도질",
    "hit_cap": 8,
    "field_follow": true,
    "field_duration": 1.2,
    "field_interval": 0.24,
    "field_power": 0.45,
    "weapon_id": "swift_hunter_moon_blade"
  },
  "swift_hunter_shadow_bomb": {
    "name": "그림자 폭탄",
    "owner": "swift_hunter",
    "pattern": "nova",
    "color": "b98deb",
    "cooldown": 4.5,
    "range": 180,
    "power": 1.2,
    "base_hits": 1,
    "effect": "광역 폭발",
    "evolution": "삼중 그림자 붕괴",
    "tags": [
      "area"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/swift_hunter_shadow_bomb/frames",
    "source_skill": "고유 기본공격",
    "hit_cap": 16,
    "weapon_id": "swift_hunter_shadow_bomb"
  },
  "sword_shield_hero_longsword": {
    "name": "수호 장검",
    "owner": "sword_shield_hero",
    "pattern": "slash",
    "color": "e36661",
    "cooldown": 1.6,
    "range": 235,
    "power": 1.55,
    "base_hits": 1,
    "effect": "전방 검격 범위 안의 적 타격",
    "evolution": "왕국 수호검",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/sword_shield_hero_longsword/frames",
    "source_skill": "고유 기본공격",
    "hit_cap": 6,
    "weapon_id": "sword_shield_hero_longsword"
  },
  "sword_shield_hero_piercing_spear": {
    "name": "검방 돌격 · 창격",
    "owner": "sword_shield_hero",
    "pattern": "beam",
    "color": "eca595",
    "cooldown": 4.5,
    "range": 420,
    "power": 2.6,
    "base_hits": 1,
    "effect": "전방 직선의 적을 관통하는 창격",
    "evolution": "성벽 관통창",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/sword_shield_hero_piercing_spear/frames",
    "source_skill": "검방 돌격 · 창격",
    "hit_cap": 8,
    "weapon_id": "sword_shield_hero_piercing_spear"
  },
  "sword_shield_hero_aegis": {
    "name": "막기",
    "owner": "sword_shield_hero",
    "pattern": "guard",
    "color": "e38c61",
    "cooldown": 9,
    "range": 190,
    "power": 0.45,
    "base_hits": 1,
    "effect": "3초 수호 방패 · 근접 적을 밀어내는 둔화 충격파",
    "evolution": "절대 방벽 아이기스",
    "tags": [
      "durability"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/sword_shield_hero_aegis/frames",
    "source_skill": "막기",
    "hit_cap": 16,
    "shield_ratio": 0.12,
    "shield_duration": 3.0,
    "slow_multiplier": 0.65,
    "slow_duration": 1.0,
    "weapon_id": "sword_shield_hero_aegis"
  },
  "sword_shield_hero_shield_hammer": {
    "name": "방패 망치",
    "owner": "sword_shield_hero",
    "pattern": "slash",
    "color": "ecbe95",
    "cooldown": 3.5,
    "range": 235,
    "power": 1.5,
    "base_hits": 1,
    "effect": "정면 방패 강타 · 둔화로 전선 유지",
    "evolution": "대지 분쇄 방패",
    "tags": [
      "area"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/sword_shield_hero_shield_hammer/frames",
    "source_skill": "고유 기본공격",
    "hit_cap": 16,
    "weapon_id": "sword_shield_hero_shield_hammer",
    "slow_multiplier": 0.65,
    "slow_duration": 1.0
  },
  "sword_shield_hero_blade_ring": {
    "name": "검막 방진",
    "owner": "sword_shield_hero",
    "pattern": "slash",
    "color": "e3b261",
    "cooldown": 2.7,
    "range": 210,
    "power": 1.25,
    "base_hits": 1,
    "effect": "회전 개체 대신 정면 검막 · 보호막 획득",
    "evolution": "철벽 회전검진",
    "tags": [
      "area"
    ],
    "effect_dir": "res://assets/art/heroes/stage3_fighter/frames/effect4",
    "source_skill": "고유 기본공격",
    "hit_cap": 10,
    "weapon_id": "sword_shield_hero_blade_ring",
    "cast_shield": 0.015
  },
  "sword_shield_hero_battle_banner": {
    "name": "전장의 깃발",
    "owner": "sword_shield_hero",
    "pattern": "heal",
    "color": "ecd895",
    "cooldown": 15,
    "range": 185,
    "power": 0.25,
    "base_hits": 1,
    "effect": "회복·주변 파동",
    "evolution": "불굴의 승전기",
    "tags": [
      "durability"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/sword_shield_hero_battle_banner/frames",
    "source_skill": "고유 기본공격",
    "hit_cap": 16,
    "weapon_id": "sword_shield_hero_battle_banner"
  },
  "pistol_hero_revolver": {
    "name": "육연발 권총",
    "owner": "pistol_hero",
    "pattern": "burst",
    "color": "ff5e61",
    "cooldown": 1.1,
    "range": 620,
    "power": 0.65,
    "base_hits": 3,
    "effect": "3발 속사 · 6발마다 1.6초 장전",
    "evolution": "황혼의 육연발",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/pistol_hero_revolver/frames",
    "source_skill": "고유 기본공격",
    "hit_cap": 16,
    "hit_interval": 0.1,
    "magazine": 6,
    "reload": 1.6,
    "weapon_id": "pistol_hero_revolver"
  },
  "pistol_hero_shotgun": {
    "name": "실린더 스트라이크",
    "owner": "pistol_hero",
    "pattern": "slash",
    "color": "ffa79b",
    "cooldown": 4.2,
    "range": 235,
    "power": 2.7,
    "base_hits": 1,
    "effect": "근거리 부채꼴 산탄 · 짧은 사거리 대신 강한 순간 피해",
    "evolution": "심판의 실린더",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/pistol_hero_shotgun/frames",
    "source_skill": "실린더 스트라이크",
    "hit_cap": 8,
    "slow_multiplier": 0.5,
    "slow_duration": 2.0,
    "weapon_id": "pistol_hero_shotgun",
    "uses_ammo": true
  },
  "pistol_hero_rifle": {
    "name": "데드아이",
    "owner": "pistol_hero",
    "pattern": "burst",
    "color": "ff895e",
    "cooldown": 5.5,
    "range": 820,
    "power": 1.05,
    "base_hits": 5,
    "effect": "단일 표적을 겨냥한 5발 집중 속사",
    "evolution": "종결자 데드아이",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/pistol_hero_rifle/frames",
    "source_skill": "데드아이",
    "hit_cap": 8,
    "hit_interval": 0.08,
    "weapon_id": "pistol_hero_rifle"
  },
  "pistol_hero_ricochet": {
    "name": "도탄 권총",
    "owner": "pistol_hero",
    "pattern": "bolt",
    "color": "ffc59b",
    "cooldown": 2.6,
    "range": 530,
    "power": 1.8,
    "base_hits": 1,
    "effect": "실제 적중 지점에서 다음 적으로 튀는 도탄",
    "evolution": "무한 도탄 황금총",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/pistol_hero_ricochet/frames",
    "source_skill": "고유 기본공격",
    "hit_cap": 16,
    "chain_radius": 220,
    "weapon_id": "pistol_hero_ricochet"
  },
  "pistol_hero_grenade": {
    "name": "충격 수류탄",
    "owner": "pistol_hero",
    "pattern": "nova",
    "color": "ffb95e",
    "cooldown": 5.2,
    "range": 480,
    "power": 2.2,
    "base_hits": 1,
    "effect": "광역 폭발",
    "evolution": "연쇄 진동 수류탄",
    "tags": [
      "area"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/pistol_hero_grenade/frames",
    "source_skill": "고유 기본공격",
    "hit_cap": 16,
    "weapon_id": "pistol_hero_grenade"
  },
  "pistol_hero_powder_bomb": {
    "name": "화약 폭탄",
    "owner": "pistol_hero",
    "pattern": "poison",
    "color": "ffe29b",
    "cooldown": 6.5,
    "range": 310,
    "power": 1.2,
    "base_hits": 1,
    "effect": "이동 경로의 화약 함정 · 접근하면 한 번 폭발",
    "evolution": "종말의 화약지대",
    "tags": [
      "area"
    ],
    "field_duration": 3.0,
    "field_interval": 0.5,
    "field_radius_ratio": 0.42,
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/pistol_hero_powder_bomb/frames",
    "source_skill": "고유 기본공격",
    "hit_cap": 16,
    "field_power": 0.28,
    "weapon_id": "pistol_hero_powder_bomb"
  },
  "archmage_hero_fire_staff": {
    "name": "원소 지팡이",
    "owner": "archmage_hero",
    "pattern": "bolt",
    "color": "f84765",
    "cooldown": 2.2,
    "range": 480,
    "power": 1.35,
    "base_hits": 1,
    "effect": "6원소 평타 · 대지/화염/빙결/빛/바람/신성의 원래 효과",
    "evolution": "육원소 공명 지팡이",
    "tags": [
      "area"
    ],
    "field_duration": 2.0,
    "field_interval": 0.35,
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/archmage_hero_fire_staff/frames",
    "source_skill": "6원소 기본공격",
    "hit_cap": 16,
    "field_power": 0.35,
    "weapon_id": "archmage_hero_fire_staff"
  },
  "archmage_hero_ice_scepter": {
    "name": "아이스볼트",
    "owner": "archmage_hero",
    "pattern": "frost",
    "color": "6dffc7",
    "cooldown": 3.4,
    "range": 285,
    "power": 0.65,
    "base_hits": 1,
    "effect": "냉기 폭발 · 2초 35% 둔화",
    "evolution": "영구동토의 왕홀",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/archmage_hero_ice_scepter/frames",
    "source_skill": "아이스볼트",
    "hit_cap": 16,
    "slow_multiplier": 0.65,
    "slow_duration": 2.0,
    "weapon_id": "archmage_hero_ice_scepter"
  },
  "archmage_hero_lightning_rod": {
    "name": "체인대거",
    "owner": "archmage_hero",
    "pattern": "chain",
    "color": "fa8982",
    "cooldown": 3.1,
    "range": 520,
    "power": 0.85,
    "base_hits": 4,
    "effect": "가까운 적을 순차 연결하는 4회 연쇄 단검",
    "evolution": "천뢰 연쇄대거",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/archmage_hero_lightning_rod/frames",
    "source_skill": "체인대거",
    "hit_cap": 16,
    "chain_radius": 200,
    "weapon_id": "archmage_hero_lightning_rod"
  },
  "archmage_hero_earth_staff": {
    "name": "땅의 가시",
    "owner": "archmage_hero",
    "pattern": "nova",
    "color": "f87847",
    "cooldown": 6,
    "range": 490,
    "power": 1.7,
    "base_hits": 1,
    "effect": "대지 가시 · 큰 단발 광역 타격",
    "evolution": "대륙 파쇄 지팡이",
    "tags": [
      "area"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/archmage_hero_earth_staff/frames",
    "source_skill": "땅의 가시",
    "hit_cap": 16,
    "weapon_id": "archmage_hero_earth_staff"
  },
  "archmage_hero_storm_orb": {
    "name": "폭풍",
    "owner": "archmage_hero",
    "pattern": "nova",
    "color": "fabe82",
    "cooldown": 5.5,
    "range": 280,
    "power": 0.8,
    "base_hits": 1,
    "effect": "시전자 주변 번개 폭풍 · 원소 반응 유도",
    "evolution": "영겁의 폭풍핵",
    "tags": [
      "area"
    ],
    "effect_dir": "res://assets/art/heroes/stage5_archmage/frames/effect8",
    "source_skill": "폭풍",
    "hit_cap": 10,
    "orbit_count": 3,
    "weapon_id": "archmage_hero_storm_orb"
  },
  "archmage_hero_prism_wand": {
    "name": "신성력",
    "owner": "archmage_hero",
    "pattern": "beam",
    "color": "f8c647",
    "cooldown": 5.8,
    "range": 670,
    "power": 1.9,
    "base_hits": 1,
    "effect": "직선 원소 분광 · 다른 원소 적중 후 반응 보너스",
    "evolution": "천상의 신성력",
    "tags": [
      "damage"
    ],
    "effect_dir": "res://assets/art/heroes/stage5_archmage/frames/effect5",
    "source_skill": "신성력",
    "hit_cap": 8,
    "field_duration": 3.0,
    "field_interval": 0.5,
    "field_power": 0.32,
    "weapon_id": "archmage_hero_prism_wand"
  },
  "madness_hero_blood_sword": {
    "name": "혈검술 제1식",
    "owner": "madness_hero",
    "pattern": "combo",
    "color": "dd4dc5",
    "cooldown": 1.2,
    "range": 215,
    "power": 0.65,
    "base_hits": 3,
    "effect": "혈검 3연격 · 체력이 낮을수록 피해 증가",
    "evolution": "마혈 육연식",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/madness_hero_blood_sword/frames",
    "source_skill": "혈검술 제1식",
    "hit_cap": 8,
    "hit_interval": 0.25,
    "low_hp_bonus": 0.5,
    "weapon_id": "madness_hero_blood_sword"
  },
  "madness_hero_blood_lance": {
    "name": "혈검술 제2식",
    "owner": "madness_hero",
    "pattern": "beam",
    "color": "e780c7",
    "cooldown": 4.8,
    "range": 370,
    "power": 2.5,
    "base_hits": 1,
    "effect": "생명력을 대가로 정면 혈창 관통",
    "evolution": "흡혈 혈해창",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/madness_hero_blood_lance/frames",
    "source_skill": "혈검술 제2식",
    "hit_cap": 8,
    "field_duration": 2.0,
    "field_interval": 0.4,
    "field_power": 0.3,
    "lifesteal": 0.04,
    "weapon_id": "madness_hero_blood_lance",
    "hp_cost": 0.012
  },
  "madness_hero_blood_wheel": {
    "name": "핏빛 검륜",
    "owner": "madness_hero",
    "pattern": "slash",
    "color": "dd4d9b",
    "cooldown": 2.5,
    "range": 220,
    "power": 1.5,
    "base_hits": 1,
    "effect": "정면 혈월 검격 · 저체력일수록 강해짐",
    "evolution": "혈월 회전검",
    "tags": [
      "area"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/madness_hero_blood_wheel/frames",
    "source_skill": "고유 기본공격",
    "hit_cap": 8,
    "weapon_id": "madness_hero_blood_wheel",
    "low_hp_bonus": 0.45
  },
  "madness_hero_blood_burst": {
    "name": "혈검술 제4식",
    "owner": "madness_hero",
    "pattern": "nova",
    "color": "e780a9",
    "cooldown": 6,
    "range": 255,
    "power": 2.3,
    "base_hits": 1,
    "effect": "현재 HP 2% 소모 · 빈사일수록 강한 혈폭",
    "evolution": "심장 파열 혈폭",
    "tags": [
      "area"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/madness_hero_blood_burst/frames",
    "source_skill": "혈검술 제4식",
    "hit_cap": 16,
    "hp_cost": 0.02,
    "low_hp_bonus": 0.6,
    "weapon_id": "madness_hero_blood_burst"
  },
  "madness_hero_drain_blade": {
    "name": "흡혈 검",
    "owner": "madness_hero",
    "pattern": "slash",
    "color": "dd4d71",
    "cooldown": 3.5,
    "range": 205,
    "power": 1.1,
    "base_hits": 1,
    "effect": "유효 검격 피해의 8% 회복 · 허공 회복 없음",
    "evolution": "불멸의 포식검",
    "tags": [
      "durability"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/madness_hero_drain_blade/frames",
    "source_skill": "고유 기본공격",
    "hit_cap": 16,
    "lifesteal": 0.08,
    "weapon_id": "madness_hero_drain_blade"
  },
  "madness_hero_heart_chain": {
    "name": "심장 사슬",
    "owner": "madness_hero",
    "pattern": "chain",
    "color": "e7808b",
    "cooldown": 3.7,
    "range": 290,
    "power": 0.9,
    "base_hits": 1,
    "effect": "근거리 적의 피를 잇는 수확 사슬",
    "evolution": "심장 수확 사슬",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/madness_hero_heart_chain/frames",
    "source_skill": "고유 기본공격",
    "hit_cap": 16,
    "weapon_id": "madness_hero_heart_chain",
    "lifesteal": 0.025
  },
  "chemical_hero_acid_vial": {
    "name": "산성 약병",
    "owner": "chemical_hero",
    "pattern": "poison",
    "color": "d8be52",
    "cooldown": 3.2,
    "range": 360,
    "power": 1,
    "base_hits": 1,
    "effect": "산성 장판 · 빠른 연속 피해",
    "evolution": "왕수 살포기",
    "tags": [
      "area"
    ],
    "field_duration": 3.0,
    "field_interval": 0.5,
    "field_radius_ratio": 0.42,
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/chemical_hero_acid_vial/frames",
    "source_skill": "고유 기본공격",
    "hit_cap": 16,
    "field_power": 0.28,
    "weapon_id": "chemical_hero_acid_vial"
  },
  "chemical_hero_poison_flask": {
    "name": "촉매 혼합장",
    "owner": "chemical_hero",
    "pattern": "poison",
    "color": "e3e084",
    "cooldown": 5.5,
    "range": 390,
    "power": 0.65,
    "base_hits": 1,
    "effect": "5초 혼합장 · 지속 피해와 둔화",
    "evolution": "대연금 촉매로",
    "tags": [
      "area"
    ],
    "field_duration": 3.0,
    "field_interval": 0.5,
    "field_radius_ratio": 0.42,
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/chemical_hero_poison_flask/frames",
    "source_skill": "촉매 혼합장",
    "hit_cap": 16,
    "field_power": 0.28,
    "slow_multiplier": 0.8,
    "slow_duration": 1.1,
    "weapon_id": "chemical_hero_poison_flask"
  },
  "chemical_hero_cryo_vial": {
    "name": "냉각 약병",
    "owner": "chemical_hero",
    "pattern": "frost",
    "color": "81dcff",
    "cooldown": 4,
    "range": 250,
    "power": 0.45,
    "base_hits": 1,
    "effect": "냉기 폭발·둔화",
    "evolution": "절대영도 앰플",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/chemical_hero_cryo_vial/frames",
    "source_skill": "고유 기본공격",
    "hit_cap": 16,
    "weapon_id": "chemical_hero_cryo_vial"
  },
  "chemical_hero_reaction_bomb": {
    "name": "오늘도 실팬가!",
    "owner": "chemical_hero",
    "pattern": "nova",
    "color": "c6d852",
    "cooldown": 6.2,
    "range": 260,
    "power": 1.9,
    "base_hits": 1,
    "effect": "이동 경로를 따라 독 가스를 남기는 2초 반응",
    "evolution": "성공한 종말 실험",
    "tags": [
      "area"
    ],
    "effect_dir": "res://assets/art/heroes/stage7_alchemist/frames/effect4",
    "source_skill": "오늘도 실팬가!",
    "hit_cap": 16,
    "field_follow": true,
    "field_duration": 2.0,
    "field_interval": 0.5,
    "field_power": 0.5,
    "weapon_id": "chemical_hero_reaction_bomb"
  },
  "chemical_hero_acid_cannon": {
    "name": "압축 산성포",
    "owner": "chemical_hero",
    "pattern": "beam",
    "color": "c7e384",
    "cooldown": 4.4,
    "range": 600,
    "power": 1.9,
    "base_hits": 1,
    "effect": "직선 관통",
    "evolution": "삼중 왕수 분사포",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/chemical_hero_acid_cannon/frames",
    "source_skill": "고유 기본공격",
    "hit_cap": 8,
    "weapon_id": "chemical_hero_acid_cannon"
  },
  "chemical_hero_life_elixir": {
    "name": "현자의 비약",
    "owner": "chemical_hero",
    "pattern": "heal",
    "color": "9ad852",
    "cooldown": 16,
    "range": 160,
    "power": 0.2,
    "base_hits": 1,
    "effect": "최대 HP 3.5% 회복 · 주변 파동",
    "evolution": "불사의 현자 비약",
    "tags": [
      "durability"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/chemical_hero_life_elixir/frames",
    "source_skill": "현자의 비약",
    "hit_cap": 16,
    "heal_ratio": 0.035,
    "weapon_id": "chemical_hero_life_elixir"
  },
  "summoner_hero_gate_hound": {
    "name": "이계의 문 - 투견",
    "owner": "summoner_hero",
    "pattern": "summon",
    "color": "78c57d",
    "cooldown": 8,
    "range": 250,
    "power": 0.72,
    "base_hits": 1,
    "effect": "기존 이계 소환수 실제 소환 · 기본 3칸 · 4종 보유 시 기본 4칸 · 용사 5레벨마다 +1칸 · 14초 유지",
    "evolution": "지옥문 사냥개",
    "tags": [
      "area"
    ],
    "orbit_count": 2,
    "orbit_speed": 4.5,
    "orbit_ratio": 0.5,
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/summoner_hero_gate_hound/frames",
    "source_skill": "이계의 문 - 투견",
    "hit_cap": 8,
    "summon_kind": "hound",
    "summon_duration": 14.0,
    "weapon_id": "summoner_hero_gate_hound"
  },
  "summoner_hero_watcher": {
    "name": "이계의 문 - 감시자",
    "owner": "summoner_hero",
    "pattern": "summon",
    "color": "a3d7ae",
    "cooldown": 8,
    "range": 350,
    "power": 0.55,
    "base_hits": 1,
    "effect": "기존 이계 소환수 실제 소환 · 기본 3칸 · 4종 보유 시 기본 4칸 · 용사 5레벨마다 +1칸 · 14초 유지",
    "evolution": "차원 감시 군주",
    "tags": [
      "area"
    ],
    "orbit_count": 4,
    "orbit_speed": 2.5,
    "orbit_ratio": 0.85,
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/summoner_hero_watcher/frames",
    "source_skill": "이계의 문 - 감시자",
    "hit_cap": 8,
    "summon_kind": "watcher",
    "summon_duration": 14.0,
    "weapon_id": "summoner_hero_watcher"
  },
  "summoner_hero_scout": {
    "name": "이계의 문 - 정찰병",
    "owner": "summoner_hero",
    "pattern": "summon",
    "color": "78c593",
    "cooldown": 8,
    "range": 620,
    "power": 0.8,
    "base_hits": 2,
    "effect": "기존 이계 소환수 실제 소환 · 기본 3칸 · 4종 보유 시 기본 4칸 · 용사 5레벨마다 +1칸 · 14초 유지",
    "evolution": "차원 선봉대장",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/summoner_hero_scout/frames",
    "source_skill": "이계의 문 - 정찰병",
    "hit_cap": 16,
    "summon_kind": "scout",
    "summon_duration": 14.0,
    "weapon_id": "summoner_hero_scout"
  },
  "summoner_hero_gate_laser": {
    "name": "차원 관통문",
    "owner": "summoner_hero",
    "pattern": "beam",
    "color": "a3d7bd",
    "cooldown": 4.3,
    "range": 540,
    "power": 1.8,
    "base_hits": 1,
    "effect": "직선 관통",
    "evolution": "오중 차원 절단문",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/summoner_hero_gate_laser/frames",
    "source_skill": "고유 기본공격",
    "hit_cap": 8,
    "weapon_id": "summoner_hero_gate_laser"
  },
  "summoner_hero_gatekeeper": {
    "name": "이계의 문 - 문지기",
    "owner": "summoner_hero",
    "pattern": "summon",
    "color": "78c5aa",
    "cooldown": 8,
    "range": 250,
    "power": 0.7,
    "base_hits": 1,
    "effect": "기존 이계 소환수 실제 소환 · 기본 3칸 · 4종 보유 시 기본 4칸 · 용사 5레벨마다 +1칸 · 14초 유지",
    "evolution": "심연의 문지기",
    "tags": [
      "durability"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/summoner_hero_gatekeeper/frames",
    "source_skill": "이계의 문 - 문지기",
    "hit_cap": 16,
    "summon_kind": "gatekeeper",
    "summon_duration": 14.0,
    "weapon_id": "summoner_hero_gatekeeper"
  },
  "summoner_hero_rift_pulse": {
    "name": "균열 파동",
    "owner": "summoner_hero",
    "pattern": "nova",
    "color": "a3d7cd",
    "cooldown": 5.8,
    "range": 215,
    "power": 1.1,
    "base_hits": 1,
    "effect": "광역 폭발",
    "evolution": "심연 균열 연쇄",
    "tags": [
      "area"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/summoner_hero_rift_pulse/frames",
    "source_skill": "고유 기본공격",
    "hit_cap": 16,
    "weapon_id": "summoner_hero_rift_pulse"
  },
  "purifier_hero_holy_bolt": {
    "name": "성광탄",
    "owner": "purifier_hero",
    "pattern": "bolt",
    "color": "ffab9d",
    "cooldown": 1.25,
    "range": 590,
    "power": 1.4,
    "base_hits": 1,
    "effect": "표적 마력 타격",
    "evolution": "천벌의 성광포",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/purifier_hero_holy_bolt/frames",
    "source_skill": "고유 기본공격",
    "hit_cap": 16,
    "weapon_id": "purifier_hero_holy_bolt"
  },
  "purifier_hero_holy_lance": {
    "name": "궁그닐",
    "owner": "purifier_hero",
    "pattern": "beam",
    "color": "ffc9b2",
    "cooldown": 6.5,
    "range": 650,
    "power": 2.6,
    "base_hits": 1,
    "effect": "긴 성창으로 직선 범위의 적 관통",
    "evolution": "천공의 궁그닐",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/purifier_hero_holy_lance/frames",
    "source_skill": "궁그닐",
    "hit_cap": 10,
    "weapon_id": "purifier_hero_holy_lance"
  },
  "purifier_hero_purification": {
    "name": "정화",
    "owner": "purifier_hero",
    "pattern": "nova",
    "color": "ffc89d",
    "cooldown": 9,
    "range": 270,
    "power": 0.85,
    "base_hits": 1,
    "effect": "자신의 독·화상·둔화 해제 · 주변 정화 파동",
    "evolution": "대정화의 심판",
    "tags": [
      "area"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/purifier_hero_purification/frames",
    "source_skill": "정화",
    "hit_cap": 16,
    "cleanse": true,
    "weapon_id": "purifier_hero_purification"
  },
  "purifier_hero_sacred_orb": {
    "name": "순례의 성역",
    "owner": "purifier_hero",
    "pattern": "poison",
    "color": "ffdfb2",
    "cooldown": 6.5,
    "range": 290,
    "power": 0.7,
    "base_hits": 4,
    "effect": "시전 위치에 성역을 남김 · 적 피해와 소량 회복",
    "evolution": "천상의 팔광륜",
    "tags": [
      "area"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/purifier_hero_sacred_orb/frames",
    "source_skill": "정화의 구체",
    "hit_cap": 8,
    "orbit_count": 4,
    "field_duration": 3.0,
    "field_interval": 0.5,
    "field_power": 0.28,
    "field_radius_ratio": 0.42,
    "weapon_id": "purifier_hero_sacred_orb"
  },
  "purifier_hero_blessing": {
    "name": "신성보호",
    "owner": "purifier_hero",
    "pattern": "guard",
    "color": "ffe59d",
    "cooldown": 13,
    "range": 180,
    "power": 0.25,
    "base_hits": 1,
    "effect": "4초 신성 보호막 · 주변 성광",
    "evolution": "불멸의 신성보호",
    "tags": [
      "durability"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/purifier_hero_blessing/frames",
    "source_skill": "신성보호",
    "hit_cap": 16,
    "shield_ratio": 0.1,
    "shield_duration": 4.0,
    "weapon_id": "purifier_hero_blessing"
  },
  "purifier_hero_prayer": {
    "name": "회복의 성배",
    "owner": "purifier_hero",
    "pattern": "heal",
    "color": "fff6b2",
    "cooldown": 16,
    "range": 190,
    "power": 0.15,
    "base_hits": 1,
    "effect": "회복·주변 파동",
    "evolution": "성배의 대기적",
    "tags": [
      "durability"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/purifier_hero_prayer/frames",
    "source_skill": "고유 기본공격",
    "hit_cap": 16,
    "weapon_id": "purifier_hero_prayer"
  },
  "sage_astra_starlight": {
    "name": "별빛 지팡이",
    "owner": "sage_astra",
    "pattern": "bolt",
    "color": "97baff",
    "cooldown": 1.5,
    "range": 660,
    "power": 1.2,
    "base_hits": 2,
    "effect": "2개의 별빛 탄 · 집중 표적 추적",
    "evolution": "쌍성 관통 지팡이",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/sage_astra_starlight/frames",
    "source_skill": "고유 기본공격",
    "hit_cap": 16,
    "weapon_id": "sage_astra_starlight"
  },
  "sage_astra_comet": {
    "name": "스타라이트",
    "owner": "sage_astra",
    "pattern": "meteor",
    "color": "b2beff",
    "cooldown": 6.5,
    "range": 780,
    "power": 2,
    "base_hits": 2,
    "effect": "기존 운석 실제 낙하 · 착탄 범위 피해",
    "evolution": "은하 붕괴 유성우",
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
    "explosion_fps": 14.0,
    "weapon_id": "sage_astra_comet"
  },
  "sage_astra_astral_chain": {
    "name": "천체 사슬",
    "owner": "sage_astra",
    "pattern": "chain",
    "color": "9b97ff",
    "cooldown": 4.5,
    "range": 560,
    "power": 0.65,
    "base_hits": 4,
    "effect": "가까운 적 사이 천체 연쇄 · 최대 4회",
    "evolution": "은하 성좌 사슬",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/sage_astra_astral_chain/frames",
    "source_skill": "고유 기본공격",
    "hit_cap": 16,
    "chain_radius": 240,
    "weapon_id": "sage_astra_astral_chain"
  },
  "sage_astra_absolute_zero": {
    "name": "빙점폭발",
    "owner": "sage_astra",
    "pattern": "ice_pillar",
    "color": "6dffc7",
    "cooldown": 8.5,
    "range": 420,
    "power": 0.65,
    "base_hits": 1,
    "effect": "기존 얼음 기둥 실제 생성 · 둔화·길목 차단",
    "evolution": "영원의 빙점 감옥",
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
    "collision_radius": 34.0,
    "weapon_id": "sage_astra_absolute_zero"
  },
  "sage_astra_singularity": {
    "name": "소멸",
    "owner": "sage_astra",
    "pattern": "singularity",
    "color": "c4b2ff",
    "cooldown": 12,
    "range": 340,
    "power": 0.65,
    "base_hits": 1,
    "effect": "기존 소멸 영역 · 끌어당김·반복 피해·체력 10% 마무리",
    "evolution": "사건의 지평선",
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
    "disappear_fps": 10.0,
    "weapon_id": "sage_astra_singularity"
  },
  "sage_astra_binary_stars": {
    "name": "쌍성의 고리",
    "owner": "sage_astra",
    "pattern": "orbit",
    "color": "c297ff",
    "cooldown": 4,
    "range": 285,
    "power": 0.8,
    "base_hits": 1,
    "effect": "회전 수호체 타격",
    "evolution": "초신성 쌍성환",
    "tags": [
      "area"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/sage_astra_binary_stars/frames",
    "source_skill": "고유 기본공격",
    "hit_cap": 8,
    "weapon_id": "sage_astra_binary_stars"
  },
  "ranged_rookie_sealing_bolt": {
    "name": "봉인 마법구",
    "owner": "ranged_rookie",
    "pattern": "bolt",
    "color": "71b7ff",
    "cooldown": 1.8,
    "range": 540,
    "power": 0.8,
    "base_hits": 1,
    "effect": "마법구 적중 시 25% 둔화 1.2초",
    "evolution": "대봉인 마법구",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/ranged_rookie_sealing_bolt/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 0,
    "slow_multiplier": 0.75,
    "slow_duration": 1.2,
    "weapon_id": "ranged_rookie_sealing_bolt"
  },
  "ranged_rookie_satellite_orbs": {
    "name": "위성 마력구",
    "owner": "ranged_rookie",
    "pattern": "orbit",
    "color": "aecaff",
    "cooldown": 3.4,
    "range": 210,
    "power": 0.85,
    "base_hits": 1,
    "effect": "주변 마력구 궤도 안의 적 타격",
    "evolution": "비전 위성군",
    "tags": [
      "area"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/ranged_rookie_satellite_orbs/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 1,
    "orbit_count": 3,
    "orbit_ratio": 0.65,
    "weapon_id": "ranged_rookie_satellite_orbs"
  },
  "ranged_rookie_rune_ray": {
    "name": "룬 분광봉",
    "owner": "ranged_rookie",
    "pattern": "beam",
    "color": "718dff",
    "cooldown": 4.8,
    "range": 610,
    "power": 1.65,
    "base_hits": 1,
    "effect": "일직선의 적을 관통하는 룬 광선",
    "evolution": "삼색 룬 분광봉",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/ranged_rookie_rune_ray/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 2,
    "weapon_id": "ranged_rookie_rune_ray"
  },
  "ranged_rookie_restoration_codex": {
    "name": "안식의 마도서",
    "owner": "ranged_rookie",
    "pattern": "guard",
    "color": "aeb2ff",
    "cooldown": 15,
    "range": 160,
    "power": 0.3,
    "base_hits": 1,
    "effect": "3초 보호막과 주변 충격파",
    "evolution": "안식의 대마도서",
    "tags": [
      "durability"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/ranged_rookie_restoration_codex/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 3,
    "shield_ratio": 0.055,
    "shield_duration": 3,
    "cast_heal": 0.01,
    "weapon_id": "ranged_rookie_restoration_codex"
  },
  "swift_hunter_execution_stiletto": {
    "name": "처형 단도",
    "owner": "swift_hunter",
    "pattern": "combo",
    "color": "e1bef4",
    "cooldown": 3.1,
    "range": 215,
    "power": 1.4,
    "base_hits": 2,
    "effect": "근접 표적 2연격 · HP 6% 이하 마무리",
    "evolution": "그림자 처형식",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/swift_hunter_execution_stiletto/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 4,
    "hit_interval": 0.12,
    "execute_ratio": 0.08,
    "weapon_id": "swift_hunter_execution_stiletto"
  },
  "swift_hunter_binding_wire": {
    "name": "그림자 결박줄",
    "owner": "swift_hunter",
    "pattern": "chain",
    "color": "dc8deb",
    "cooldown": 4,
    "range": 330,
    "power": 0.42,
    "base_hits": 3,
    "effect": "3대상 연결 · 35% 둔화 1초",
    "evolution": "월영 결박망",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/swift_hunter_binding_wire/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 5,
    "chain_radius": 165,
    "slow_multiplier": 0.65,
    "slow_duration": 1,
    "weapon_id": "swift_hunter_binding_wire"
  },
  "swift_hunter_smoke_mantle": {
    "name": "연막 망토",
    "owner": "swift_hunter",
    "pattern": "guard",
    "color": "f4bef2",
    "cooldown": 12,
    "range": 140,
    "power": 0.25,
    "base_hits": 1,
    "effect": "2초 보호막 · 주변 30% 둔화",
    "evolution": "무영의 망토",
    "tags": [
      "durability"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/swift_hunter_smoke_mantle/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 6,
    "shield_ratio": 0.045,
    "shield_duration": 2,
    "slow_multiplier": 0.7,
    "slow_duration": 1,
    "weapon_id": "swift_hunter_smoke_mantle"
  },
  "swift_hunter_venom_steps": {
    "name": "독무 발톱",
    "owner": "swift_hunter",
    "pattern": "poison",
    "color": "84e390",
    "cooldown": 4,
    "range": 230,
    "power": 0.8,
    "base_hits": 1,
    "effect": "2초 이동형 독무 · 0.4초마다 주변 피해",
    "evolution": "만독 그림자 발톱",
    "tags": [
      "area"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/swift_hunter_venom_steps/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 7,
    "field_follow": true,
    "field_duration": 3.0,
    "field_interval": 0.5,
    "field_power": 0.28,
    "field_radius_ratio": 0.42,
    "weapon_id": "swift_hunter_venom_steps"
  },
  "sword_shield_hero_oath_blade": {
    "name": "맹세의 검",
    "owner": "sword_shield_hero",
    "pattern": "slash",
    "color": "e3d861",
    "cooldown": 3.5,
    "range": 245,
    "power": 2.1,
    "base_hits": 1,
    "effect": "전방 검격 · 시전 보호막 2%",
    "evolution": "왕가의 맹세검",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/sword_shield_hero_oath_blade/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 8,
    "cast_shield": 0.02,
    "weapon_id": "sword_shield_hero_oath_blade"
  },
  "sword_shield_hero_ward_crossbow": {
    "name": "수호 쇠뇌",
    "owner": "sword_shield_hero",
    "pattern": "bolt",
    "color": "e6ec95",
    "cooldown": 2.4,
    "range": 470,
    "power": 1.9,
    "base_hits": 1,
    "effect": "원거리 쇠뇌 사격 · 20% 둔화 1초",
    "evolution": "성벽 파수 쇠뇌",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/sword_shield_hero_ward_crossbow/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 9,
    "slow_multiplier": 0.8,
    "slow_duration": 1,
    "weapon_id": "sword_shield_hero_ward_crossbow"
  },
  "sword_shield_hero_sanctuary_shield": {
    "name": "성역 방패",
    "owner": "sword_shield_hero",
    "pattern": "guard",
    "color": "c7e361",
    "cooldown": 15,
    "range": 180,
    "power": 0.25,
    "base_hits": 1,
    "effect": "4초 보호막 · 독·화상·둔화 해제",
    "evolution": "성역의 대방패",
    "tags": [
      "durability"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/sword_shield_hero_sanctuary_shield/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 10,
    "shield_ratio": 0.06,
    "shield_duration": 4,
    "cleanse": true,
    "weapon_id": "sword_shield_hero_sanctuary_shield"
  },
  "sword_shield_hero_rally_standard": {
    "name": "결집 군기",
    "owner": "sword_shield_hero",
    "pattern": "heal",
    "color": "cdec95",
    "cooldown": 17,
    "range": 210,
    "power": 0.2,
    "base_hits": 1,
    "effect": "최대 HP 회복과 주변 둔화 파동",
    "evolution": "불굴의 결집 군기",
    "tags": [
      "durability"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/sword_shield_hero_rally_standard/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 11,
    "heal_ratio": 0.015,
    "slow_multiplier": 0.75,
    "slow_duration": 1.5,
    "weapon_id": "sword_shield_hero_rally_standard"
  },
  "pistol_hero_twin_pistols": {
    "name": "쌍열 권총",
    "owner": "pistol_hero",
    "pattern": "burst",
    "color": "ffe85e",
    "cooldown": 1.7,
    "range": 570,
    "power": 0.68,
    "base_hits": 3,
    "effect": "3발 교차 속사 · 공유 탄약 사용",
    "evolution": "황금 쌍열 권총",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/pistol_hero_twin_pistols/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 12,
    "hit_interval": 0.12,
    "uses_ammo": true,
    "weapon_id": "pistol_hero_twin_pistols"
  },
  "pistol_hero_shrapnel_round": {
    "name": "파쇄 탄환",
    "owner": "pistol_hero",
    "pattern": "bolt",
    "color": "ffff9b",
    "cooldown": 3.8,
    "range": 670,
    "power": 2.5,
    "base_hits": 1,
    "effect": "탄환 적중 시 주변에 35% 파편 피해",
    "evolution": "중량 파쇄 탄환",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/pistol_hero_shrapnel_round/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 13,
    "splash_ratio": 0.35,
    "splash_radius": 70,
    "uses_ammo": true,
    "weapon_id": "pistol_hero_shrapnel_round"
  },
  "pistol_hero_suppressor": {
    "name": "제압 기관권총",
    "owner": "pistol_hero",
    "pattern": "burst",
    "color": "e7ff5e",
    "cooldown": 4,
    "range": 650,
    "power": 0.4,
    "base_hits": 4,
    "effect": "4발 제압 사격 · 25% 둔화 1초",
    "evolution": "황혼의 제압사격",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/pistol_hero_suppressor/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 14,
    "hit_interval": 0.15,
    "slow_multiplier": 0.75,
    "slow_duration": 1,
    "uses_ammo": true,
    "weapon_id": "pistol_hero_suppressor"
  },
  "pistol_hero_smoke_canister": {
    "name": "연막 유탄",
    "owner": "pistol_hero",
    "pattern": "poison",
    "color": "e1ff9b",
    "cooldown": 7,
    "range": 360,
    "power": 0.4,
    "base_hits": 1,
    "effect": "3초 연막 지대 · 0.6초마다 피해와 30% 둔화",
    "evolution": "검은 화약 연막탄",
    "tags": [
      "area"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/pistol_hero_smoke_canister/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 15,
    "field_duration": 3.0,
    "field_interval": 0.5,
    "field_power": 0.28,
    "field_radius_ratio": 0.42,
    "slow_multiplier": 0.7,
    "slow_duration": 0.8,
    "weapon_id": "pistol_hero_smoke_canister"
  },
  "archmage_hero_lava_focus": {
    "name": "용암 촉매봉",
    "owner": "archmage_hero",
    "pattern": "poison",
    "color": "a4dc63",
    "cooldown": 7,
    "range": 420,
    "power": 1.2,
    "base_hits": 1,
    "effect": "3초 용암 지대 · 0.5초마다 피해",
    "evolution": "화산심장 촉매봉",
    "tags": [
      "area"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/archmage_hero_lava_focus/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 16,
    "field_duration": 3.0,
    "field_interval": 0.5,
    "field_power": 0.28,
    "field_radius_ratio": 0.42,
    "weapon_id": "archmage_hero_lava_focus"
  },
  "archmage_hero_frost_moons": {
    "name": "빙결 위성",
    "owner": "archmage_hero",
    "pattern": "frost",
    "color": "aaafff",
    "cooldown": 5,
    "range": 260,
    "power": 0.55,
    "base_hits": 1,
    "effect": "주변 냉기 파동 · 낮은 피해와 강한 둔화",
    "evolution": "영원의 빙결 위성",
    "tags": [
      "area"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/archmage_hero_frost_moons/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 17,
    "orbit_count": 3,
    "orbit_ratio": 0.7,
    "slow_multiplier": 0.7,
    "slow_duration": 1.2,
    "weapon_id": "archmage_hero_frost_moons"
  },
  "archmage_hero_gale_prism": {
    "name": "질풍 프리즘",
    "owner": "archmage_hero",
    "pattern": "beam",
    "color": "faf282",
    "cooldown": 4.8,
    "range": 590,
    "power": 1.2,
    "base_hits": 1,
    "effect": "2방향 관통 바람 칼날",
    "evolution": "오중 질풍 프리즘",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/archmage_hero_gale_prism/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 18,
    "fan_lines": 2,
    "weapon_id": "archmage_hero_gale_prism"
  },
  "archmage_hero_sunfire_tome": {
    "name": "태양화염서",
    "owner": "archmage_hero",
    "pattern": "nova",
    "color": "ddf847",
    "cooldown": 9,
    "range": 520,
    "power": 2.8,
    "base_hits": 1,
    "effect": "주변 화염 폭발 · 시전 HP 1% 회복",
    "evolution": "백야의 태양화염서",
    "tags": [
      "area"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/archmage_hero_sunfire_tome/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 19,
    "cast_heal": 0.01,
    "weapon_id": "archmage_hero_sunfire_tome"
  },
  "madness_hero_desperate_cleaver": {
    "name": "결사의 참수검",
    "owner": "madness_hero",
    "pattern": "slash",
    "color": "dd534d",
    "cooldown": 4.2,
    "range": 245,
    "power": 2.5,
    "base_hits": 1,
    "effect": "넓은 검격 · 체력이 낮을수록 피해 최대 +50%",
    "evolution": "결사의 혈왕검",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/madness_hero_desperate_cleaver/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 20,
    "low_hp_bonus": 0.5,
    "hp_cost": 0.005,
    "weapon_id": "madness_hero_desperate_cleaver"
  },
  "madness_hero_vampire_fang": {
    "name": "흡혈 송곳니",
    "owner": "madness_hero",
    "pattern": "combo",
    "color": "e79480",
    "cooldown": 2.4,
    "range": 215,
    "power": 0.9,
    "base_hits": 3,
    "effect": "근접 흡혈 연격",
    "evolution": "혈월의 송곳니",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/madness_hero_vampire_fang/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 21,
    "lifesteal": 0.04,
    "weapon_id": "madness_hero_vampire_fang"
  },
  "madness_hero_blood_thorns": {
    "name": "혈흔 가시",
    "owner": "madness_hero",
    "pattern": "poison",
    "color": "dd7d4d",
    "cooldown": 5.5,
    "range": 240,
    "power": 0.85,
    "base_hits": 1,
    "effect": "2.4초 혈흔 지대 · 0.4초마다 흡혈 피해",
    "evolution": "혈해 가시밭",
    "tags": [
      "area"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/madness_hero_blood_thorns/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 22,
    "field_duration": 3.0,
    "field_interval": 0.5,
    "field_power": 0.28,
    "field_radius_ratio": 0.42,
    "lifesteal": 0.02,
    "weapon_id": "madness_hero_blood_thorns"
  },
  "madness_hero_blood_aegis": {
    "name": "핏빛 수호구",
    "owner": "madness_hero",
    "pattern": "guard",
    "color": "e7b280",
    "cooldown": 13,
    "range": 170,
    "power": 0.35,
    "base_hits": 1,
    "effect": "3초 보호막 · 주변 흡혈 충격파",
    "evolution": "마혈 수호핵",
    "tags": [
      "durability"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/madness_hero_blood_aegis/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 23,
    "shield_ratio": 0.045,
    "shield_duration": 3,
    "lifesteal": 0.03,
    "hp_cost": 0.005,
    "weapon_id": "madness_hero_blood_aegis"
  },
  "chemical_hero_caustic_boots": {
    "name": "부식 분무기",
    "owner": "chemical_hero",
    "pattern": "poison",
    "color": "a8e384",
    "cooldown": 5,
    "range": 240,
    "power": 0.7,
    "base_hits": 1,
    "effect": "2.4초 이동 산성 지대 · 0.4초마다 피해",
    "evolution": "왕수 분무기",
    "tags": [
      "area"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/chemical_hero_caustic_boots/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 24,
    "field_follow": true,
    "field_duration": 3.0,
    "field_interval": 0.5,
    "field_power": 0.28,
    "field_radius_ratio": 0.42,
    "gas_cost": 6,
    "weapon_id": "chemical_hero_caustic_boots"
  },
  "chemical_hero_catalyst_wire": {
    "name": "촉매 도선",
    "owner": "chemical_hero",
    "pattern": "chain",
    "color": "6ed852",
    "cooldown": 3.8,
    "range": 430,
    "power": 0.55,
    "base_hits": 3,
    "effect": "3대상 촉매 연결 · 20% 둔화 1초",
    "evolution": "연금 촉매 회로",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/chemical_hero_catalyst_wire/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 25,
    "chain_radius": 180,
    "slow_multiplier": 0.8,
    "slow_duration": 1,
    "gas_cost": 5,
    "weapon_id": "chemical_hero_catalyst_wire"
  },
  "chemical_hero_toxic_dart": {
    "name": "독성 주사총",
    "owner": "chemical_hero",
    "pattern": "bolt",
    "color": "88e384",
    "cooldown": 1.8,
    "range": 530,
    "power": 1.3,
    "base_hits": 1,
    "effect": "독성 주사탄 · 적중 시 35% 둔화 1.5초",
    "evolution": "만독 주사총",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/chemical_hero_toxic_dart/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 26,
    "slow_multiplier": 0.65,
    "slow_duration": 1.5,
    "gas_cost": 3,
    "weapon_id": "chemical_hero_toxic_dart"
  },
  "chemical_hero_antidote_capsule": {
    "name": "해독 캡슐",
    "owner": "chemical_hero",
    "pattern": "guard",
    "color": "52d863",
    "cooldown": 16,
    "range": 140,
    "power": 0.2,
    "base_hits": 1,
    "effect": "독·화상·둔화 해제 · 3초 보호막",
    "evolution": "완전해독 캡슐",
    "tags": [
      "durability"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/chemical_hero_antidote_capsule/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 27,
    "shield_ratio": 0.055,
    "shield_duration": 3,
    "cleanse": true,
    "cast_heal": 0.01,
    "gas_cost": 10,
    "weapon_id": "chemical_hero_antidote_capsule"
  },
  "summoner_hero_rift_orbit": {
    "name": "차원 협공검",
    "owner": "summoner_hero",
    "pattern": "slash",
    "color": "78c5c1",
    "cooldown": 3.4,
    "range": 215,
    "power": 1.3,
    "base_hits": 1,
    "effect": "소환수 위치에서 정면 차원 검격",
    "evolution": "심연의 톱니환",
    "tags": [
      "area"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/summoner_hero_rift_orbit/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 28,
    "orbit_count": 3,
    "orbit_ratio": 0.7,
    "weapon_id": "summoner_hero_rift_orbit"
  },
  "summoner_hero_collapse_glyph": {
    "name": "붕괴 문양",
    "owner": "summoner_hero",
    "pattern": "poison",
    "color": "a3d2d7",
    "cooldown": 6.5,
    "range": 340,
    "power": 0.8,
    "base_hits": 1,
    "effect": "3초 차원 지대 · 0.5초마다 피해",
    "evolution": "심연 붕괴 문양",
    "tags": [
      "area"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/summoner_hero_collapse_glyph/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 29,
    "field_duration": 3.0,
    "field_interval": 0.5,
    "field_power": 0.28,
    "field_radius_ratio": 0.42,
    "weapon_id": "summoner_hero_collapse_glyph"
  },
  "summoner_hero_gate_shard": {
    "name": "차원 파편구",
    "owner": "summoner_hero",
    "pattern": "bolt",
    "color": "78b3c5",
    "cooldown": 2.5,
    "range": 540,
    "power": 1.75,
    "base_hits": 1,
    "effect": "차원 파편 적중 시 25% 주변 폭발",
    "evolution": "심연 파편핵",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/summoner_hero_gate_shard/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 30,
    "splash_radius": 65,
    "splash_ratio": 0.25,
    "weapon_id": "summoner_hero_gate_shard"
  },
  "summoner_hero_binding_gate": {
    "name": "결박의 문",
    "owner": "summoner_hero",
    "pattern": "frost",
    "color": "a3c3d7",
    "cooldown": 6,
    "range": 245,
    "power": 0.4,
    "base_hits": 1,
    "effect": "차원 충격파 · 40% 둔화 2초",
    "evolution": "심연 결박문",
    "tags": [
      "area"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/summoner_hero_binding_gate/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 31,
    "slow_multiplier": 0.6,
    "slow_duration": 2,
    "weapon_id": "summoner_hero_binding_gate"
  },
  "purifier_hero_mercy_chain": {
    "name": "자비의 사슬",
    "owner": "purifier_hero",
    "pattern": "chain",
    "color": "fcff9d",
    "cooldown": 5,
    "range": 390,
    "power": 0.55,
    "base_hits": 3,
    "effect": "3대상 성광 연결 · 시전 HP 1% 회복",
    "evolution": "대자비 성광사슬",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/purifier_hero_mercy_chain/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 32,
    "chain_radius": 180,
    "cast_heal": 0.01,
    "weapon_id": "purifier_hero_mercy_chain"
  },
  "purifier_hero_judgment_seal": {
    "name": "심판 낙인",
    "owner": "purifier_hero",
    "pattern": "poison",
    "color": "f2ffb2",
    "cooldown": 7,
    "range": 310,
    "power": 0.9,
    "base_hits": 1,
    "effect": "3초 성광 지대 · 0.5초마다 피해와 20% 둔화",
    "evolution": "대심판 성인",
    "tags": [
      "area"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/purifier_hero_judgment_seal/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 33,
    "field_duration": 3.0,
    "field_interval": 0.5,
    "field_power": 0.28,
    "field_radius_ratio": 0.42,
    "slow_multiplier": 0.8,
    "slow_duration": 0.8,
    "weapon_id": "purifier_hero_judgment_seal"
  },
  "purifier_hero_saint_reliquary": {
    "name": "성인의 유골함",
    "owner": "purifier_hero",
    "pattern": "guard",
    "color": "dfff9d",
    "cooldown": 16,
    "range": 170,
    "power": 0.2,
    "base_hits": 1,
    "effect": "4초 보호막 · 독·화상·둔화 해제",
    "evolution": "대성인의 성물함",
    "tags": [
      "durability"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/purifier_hero_saint_reliquary/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 34,
    "shield_ratio": 0.06,
    "shield_duration": 4,
    "cleanse": true,
    "weapon_id": "purifier_hero_saint_reliquary"
  },
  "purifier_hero_martyr_blade": {
    "name": "순교자의 검",
    "owner": "purifier_hero",
    "pattern": "slash",
    "color": "dbffb2",
    "cooldown": 3.8,
    "range": 230,
    "power": 1.9,
    "base_hits": 1,
    "effect": "전방 성검 타격 · 흡혈 2% · HP 5% 마무리",
    "evolution": "성혈 순교검",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/purifier_hero_martyr_blade/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 35,
    "lifesteal": 0.02,
    "execute_ratio": 0.05,
    "weapon_id": "purifier_hero_martyr_blade"
  },
  "sage_astra_gravity_lance": {
    "name": "중력 성창",
    "owner": "sage_astra",
    "pattern": "beam",
    "color": "e1b2ff",
    "cooldown": 6,
    "range": 710,
    "power": 2.2,
    "base_hits": 1,
    "effect": "2방향 천체 광선 · 20% 둔화 1.2초",
    "evolution": "중력 오중성창",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/sage_astra_gravity_lance/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 36,
    "fan_lines": 2,
    "slow_multiplier": 0.8,
    "slow_duration": 1.2,
    "weapon_id": "sage_astra_gravity_lance"
  },
  "sage_astra_frozen_stars": {
    "name": "빙성 결계",
    "owner": "sage_astra",
    "pattern": "poison",
    "color": "aaafff",
    "cooldown": 7,
    "range": 390,
    "power": 0.55,
    "base_hits": 1,
    "effect": "표적 주변에 고정 냉기 결계를 예고 후 전개",
    "evolution": "영겁의 빙성환",
    "tags": [
      "area"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/sage_astra_frozen_stars/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 37,
    "orbit_count": 3,
    "orbit_ratio": 0.7,
    "slow_multiplier": 0.65,
    "slow_duration": 1.5,
    "field_duration": 3.0,
    "field_interval": 0.6,
    "field_power": 0.2,
    "field_radius_ratio": 0.42,
    "weapon_id": "sage_astra_frozen_stars"
  },
  "sage_astra_supernova_core": {
    "name": "초신성 핵",
    "owner": "sage_astra",
    "pattern": "nova",
    "color": "e997ff",
    "cooldown": 11,
    "range": 680,
    "power": 3,
    "base_hits": 1,
    "effect": "주변 초신성 폭발 · 25% 후속 폭발 1회",
    "evolution": "은하 초신성 핵",
    "tags": [
      "area"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/sage_astra_supernova_core/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 38,
    "pulse_count": 1,
    "pulse_ratio": 0.25,
    "weapon_id": "sage_astra_supernova_core"
  },
  "sage_astra_collapsed_seed": {
    "name": "붕괴 별씨",
    "owner": "sage_astra",
    "pattern": "bolt",
    "color": "feb2ff",
    "cooldown": 4.5,
    "range": 710,
    "power": 2.4,
    "base_hits": 1,
    "effect": "별씨 적중 시 30% 주변 붕괴 피해",
    "evolution": "사건의 별씨",
    "tags": [
      "damage"
    ],
    "visual_effect_unique": true,
    "effect_dir": "res://assets/art/effects/hero_weapon_v2/sage_astra_collapsed_seed/frames",
    "source_skill": "전용 확장 무기",
    "icon_index_v2": 39,
    "splash_ratio": 0.3,
    "splash_radius": 75,
    "weapon_id": "sage_astra_collapsed_seed"
  }
}
const PASSIVES := {
  "survival_power": {
    "name": "공격력 증가",
    "description": "전체 무기 피해 +10% / 레벨",
    "stat": "power",
    "value": 0.1
  },
  "survival_mobility": {
    "name": "이동속도 증가",
    "description": "기본 이동속도 +3.5% / 레벨",
    "stat": "mobility",
    "value": 0.035
  },
  "survival_projectile": {
    "name": "투사체속도 증가",
    "description": "발사체 이동속도 +12% / 레벨\n즉시 타격·장판·검격에는 적용되지 않습니다.",
    "stat": "projectile",
    "value": 0.12,
    "restriction": "ranged"
  },
  "survival_haste": {
    "name": "공격속도 증가",
    "description": "전체 무기 공격 빈도 +6% / 레벨",
    "stat": "haste",
    "value": 0.06
  },
  "survival_learning": {
    "name": "경험치 증가",
    "description": "획득 경험치 +4% / 레벨",
    "stat": "learning",
    "value": 0.04
  },
  "survival_magnet": {
    "name": "경험치 범위 증가",
    "description": "경험치 획득 반경 +18% / 레벨",
    "stat": "magnet",
    "value": 0.18
  },
  "survival_vitality": {
    "name": "최대체력 증가",
    "description": "시작 최대 HP +6% · 증가분 회복 / 레벨",
    "stat": "vitality",
    "value": 0.06
  },
  "survival_armor": {
    "name": "받는피해 감소",
    "description": "받는 피해 -3% / 레벨 · 최대 30%",
    "stat": "armor",
    "value": 0.03
  },
  "survival_siphon": {
    "name": "피해량 흡수 (피흡)",
    "description": "피해량 흡수 (피흡)",
    "stat": "siphon",
    "value": 0.006,
    "icon_source": "survival_vitality"
  },
  "survival_slow_resist": {
    "name": "둔화 저항",
    "description": "둔화 저항",
    "stat": "slow_resist",
    "value": 0.05,
    "icon_source": "survival_armor"
  },
  "survival_reach": {
    "name": "사거리 증가",
    "description": "사거리 증가",
    "stat": "reach",
    "value": 0.05,
    "icon_source": "survival_magnet",
    "restriction": "ranged"
  },
  "survival_recovery": {
    "name": "즉시 회복",
    "description": "즉시 회복",
    "stat": "recovery",
    "value": 0.3,
    "icon_source": "survival_vitality",
    "one_shot": true
  },
  "survival_projectile_power": {
    "name": "투사체 피해량",
    "description": "투사체 피해량",
    "stat": "projectile_power",
    "value": 0.08,
    "icon_source": "survival_power",
    "restriction": "ranged"
  },
  "survival_area": {
    "name": "공격 범위",
    "description": "공격 범위",
    "stat": "area",
    "value": 0.06,
    "icon_source": "survival_magnet"
  },
  "survival_multishot": {
    "name": "투사체 개수",
    "description": "투사체 개수",
    "stat": "multishot",
    "value": 1.0,
    "icon_source": "survival_projectile",
    "restriction": "projectile_weapon",
    "max_level": 2
  },
  "survival_duration": {
    "name": "무기 지속시간",
    "description": "무기 지속시간",
    "stat": "duration",
    "value": 0.06,
    "icon_source": "survival_learning"
  }
}
const MELEE_HEROES := ["swift_hunter","sword_shield_hero","madness_hero"]
const RANGED_RESEARCH_PATTERNS := ["bolt","burst","piercer","beam","chain","meteor","poison","ice_pillar","singularity"]
const PROJECTILE_PATTERNS := ["bolt","burst","piercer","meteor"]
const AREA_PATTERNS := ["combo","slash","beam","capsule","orbit","nova","frost","poison","guard","heal","ice_pillar","meteor","singularity"]
# Counts apply to actual delivery, including non-starter emitters and summons.
# Ground fields, beams, healing, shields and melee swings are not projectiles.
static func projectile_quantity_kind(id: String) -> String:
	var data: Dictionary = WEAPONS.get(id,{})
	if data.is_empty(): return ""
	var rule := DELIVERY.spec(id,data)
	if String(rule.get("mode","")) == "sentry": return "sentry"
	if String(data.get("pattern","")) == "orbit": return "orbit"
	if not rule.is_empty(): return ""
	if String(data.get("pattern","")) in PROJECTILE_PATTERNS: return "shots"
	if String(data.get("summon_kind","")) in ["watcher","gatekeeper"]: return "summon"
	return ""

static func projectile_visual_radius(data: Dictionary) -> float:
	return 22.0 if String(data.get("pattern","")) == "burst" else 28.0

static func passive_limit(id: String) -> int:
	return int(PASSIVES.get(id,{}).get("max_level",MAX_LEVEL))
static func passive_allowed(id: String, owner: String, owned: Array) -> bool:
	var restriction := String(PASSIVES[id].get("restriction",""))
	if restriction == "ranged": return owner not in MELEE_HEROES
	if restriction == "projectile_weapon":
		for weapon in owned:
			if String(PASSIVES[id].stat) == "multishot":
				if projectile_quantity_kind(String(weapon)) != "": return true
			elif String(WEAPONS[weapon].pattern) in PROJECTILE_PATTERNS: return true
		return false
	return true
static func is_weapon(id: String) -> bool:
	return WEAPONS.has(id)
static func weapon_pool(hero_id: String = "") -> Array:
	return HERO_WEAPONS.get(hero_id,[]) if not hero_id.is_empty() else WEAPONS.keys()
static func card_tags(id: String, data: Dictionary = {}) -> String:
	if not WEAPONS.has(id): return "#보조"
	var stats: Dictionary = WEAPONS[id] if data.is_empty() else data
	return CARD_TEXT.tags(stats,DELIVERY.spec(id,stats),ATTACKS.spec(id))

## Owned inventory copy, independent of offered-rank upgrade deltas.
static func inventory_description(id: String, stats: Dictionary) -> String:
	if not WEAPONS.has(id): return String(PASSIVES.get(id,{}).get("description",""))
	var delivery := DELIVERY.spec(id,stats)
	var flight := ATTACKS.description(id)
	var text := String(delivery.label) if not delivery.is_empty() else flight if not flight.is_empty() else String(WEAPONS[id].get("effect",""))
	if String(stats.get("pattern","")) == "summon":
		text = String(INVENTORY_SUMMON_TEXT.get(String(stats.get("summon_kind","")),text))
		if float(stats.get("summon_area_radius",0.0)) > 0.0:
			text += "\n현재 소환수의 공격에 "+String(stats.summon_area_label)+" 광역 타격이 적용됩니다."
	if stats.has("max_mechanic"):
		text += "\n"+String(stats.max_mechanic.description)
	return text

static func description(id: String, next_level: int, with_tags: bool = true) -> String:
	if PASSIVES.has(id):
		var passive: Dictionary = PASSIVES[id]
		var rank := clampi(next_level,1,passive_limit(id))
		var gain := float(passive.value)*100.0
		var total := gain*rank
		var text := ""
		match String(passive.stat):
			"recovery": text = "최대 HP 30% 즉시 회복"
			"multishot": text = "발사체 +1개 · 누적 +%d개" % rank
			"siphon": text = "피흡 +0.6%% · 누적 %.1f%%" % total
			"slow_resist": text = "둔화 저항 +5%% · 누적 %.0f%%" % total
			"projectile_power": text = "투사체 피해 +%.0f%% · 누적 %.0f%%" % [gain,total]
			"reach": text = "사거리 +%.0f%% · 누적 %.0f%%" % [gain,total]
			"area": text = "공격 반경·폭 +%.0f%% · 누적 %.0f%%" % [gain,total]
			"duration": text = "무기 지속 +%.0f%% · 누적 %.0f%%" % [gain,total]
			"vitality": text = "최대 HP +%.0f%% · 증가분 회복" % gain
			"armor": text = "피해 감소 +%.0f%%p · 누적 %.0f%%" % [gain,minf(total,30.0)]
			"projectile": text = "탄속 +%.0f%% · 누적 %.0f%%" % [gain,total]
			_: text = "%s +%s%% · 누적 %s%%" % [String(passive.name).trim_suffix(" 증가"),CARD_TEXT.number(gain),CARD_TEXT.number(total)]
		return text+("\n#보조" if with_tags else "")
	if not WEAPONS.has(id): return ""
	var awakened := next_level > MAX_LEVEL
	var rank := clampi(next_level,1,MAX_LEVEL)
	var after := GROWTH.resolve(id,WEAPONS[id],rank,awakened)
	var text := "신규 무기 획득"
	if rank == 1:
		if String(after.pattern) == "summon": text += " · 소환 유지 %s초" % CARD_TEXT.number(after.summon_duration)
	else:
		var before := GROWTH.resolve(id,WEAPONS[id],rank if awakened else rank-1,false)
		text = CARD_TEXT.changes(before,after,rank)
	return text+("\n"+card_tags(id,after) if with_tags else "")

static func compare(id: String, next_level: int, current_stats: Dictionary = {}, next_stats: Dictionary = {}, base_damage: float = 1.0) -> Array:
	if PASSIVES.has(id):
		var passive: Dictionary = PASSIVES[id]
		if bool(passive.get("one_shot",false)): return []
		var rank := clampi(next_level,1,passive_limit(id))
		var unit := float(passive.value)
		var stat := String(passive.stat)
		var old := unit*float(rank-1)
		var new := unit*float(rank)
		if stat == "armor":
			old = minf(old,0.30); new = minf(new,0.30)
		if stat == "multishot": return [{"label":String(passive.name),"current":"+%d개" % mini(2,rank-1),"next":"+%d개" % mini(2,rank)}]
		return [{"label":String(passive.name),"current":"+%s%%" % CARD_TEXT.number(old*100.0),"next":"+%s%%" % CARD_TEXT.number(new*100.0)}]
	if not WEAPONS.has(id): return []
	var rank := clampi(next_level,1,MAX_LEVEL)
	var after: Dictionary = next_stats if not next_stats.is_empty() else GROWTH.resolve(id,WEAPONS[id],rank,next_level > MAX_LEVEL)
	var before: Dictionary = current_stats if not current_stats.is_empty() else GROWTH.resolve(id,WEAPONS[id],maxi(1,rank-1),false)
	var first := next_level == 1
	var result: Array = []
	if String(after.get("pattern","")) not in ["guard","heal"]:
		var old_damage := int(before.get("display_damage",maxi(1,roundi(base_damage*float(before.power)*float(before.damage_scale)))))
		var new_damage := int(after.get("display_damage",maxi(1,roundi(base_damage*float(after.power)*float(after.damage_scale)))))
		result.append({"label":"피해","current":"없음" if first else str(old_damage),"next":str(new_damage)})
	result.append({"label":"공격 간격","current":"없음" if first else "%s초" % CARD_TEXT.number(float(before.get("display_cooldown",float(before.cooldown)*float(before.cooldown_scale)))),"next":"%s초" % CARD_TEXT.number(float(after.get("display_cooldown",float(after.cooldown)*float(after.cooldown_scale))))})
	if String(after.get("pattern","")) != "summon":
		result.append({"label":"사거리","current":"없음" if first else CARD_TEXT.number(float(before.get("range",0.0))*float(before.reach_scale)),"next":CARD_TEXT.number(float(after.get("range",0.0))*float(after.reach_scale))})
	else:
		result.append({"label":"소환 유지","current":"없음" if first else "%s초" % CARD_TEXT.number(float(before.summon_duration)),"next":"%s초" % CARD_TEXT.number(float(after.summon_duration))})
	var fields: Dictionary = CARD_TEXT.SUMMON_FIELDS if String(after.get("pattern","")) == "summon" else CARD_TEXT.EXTRA_FIELDS
	var old_fields: Dictionary = before
	var new_fields: Dictionary = after
	if fields == CARD_TEXT.SUMMON_FIELDS:
		old_fields = before.get("summon_config",before.get("summon_patch",{}))
		new_fields = after.get("summon_config",after.get("summon_patch",{}))
	for key in fields:
		if not new_fields.has(key): continue
		var old_value := float(old_fields.get(key,0.0))
		var new_value := float(new_fields[key])
		if not first and is_equal_approx(old_value,new_value): continue
		var field: Array = fields[key]
		result.append({"label":String(field[0]),"current":"없음" if first else CARD_TEXT.number(old_value*float(field[1]))+String(field[2]),"next":CARD_TEXT.number(new_value*float(field[1]))+String(field[2])})
	return result
static func profile_for_survival(source: Dictionary) -> Dictionary:
	var result := source.duplicate(true)
	var stats := preload("res://src/data/hero_mode_catalog.gd").starting_stats(String(source.get("id","ranged_rookie")))
	for key in stats: result[key] = stats[key]
	result["level_growth"] = {}
	return result
