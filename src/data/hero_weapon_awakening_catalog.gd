extends RefCounted
## Applies AFTER normal growth ceilings. MAX gets a deliberate structural leap.
const PROFILES := {
  "ranged_rookie_arcane_bolt": {
    "name": "천공을 가르는 비전포",
    "description": "다중 관통·두 겹 비전 각인 · 양옆45% 추가탄",
    "patch": {
      "awakening_wings": 2,
      "awakening_wing_ratio": 0.45,
      "awakening_mark_hits": 2,
      "awakening_pierces": 6
    },
    "role": "assault"
  },
  "ranged_rookie_star_wand": {
    "name": "비전 종극 · 별빛 지팡이",
    "description": "다중 관통·두 겹 비전 각인 · 양옆45% 추가탄",
    "patch": {
      "awakening_wings": 2,
      "awakening_wing_ratio": 0.45,
      "awakening_mark_hits": 2,
      "awakening_pierces": 6
    },
    "role": "assault"
  },
  "ranged_rookie_magic_lance": {
    "name": "비전 종극 · 마력 관통포",
    "description": "전용 기술의 대형화·폭 넓은 다중 전개 · 시전 후 확대되는 천체 충격파",
    "patch": {
      "native_radius_scale": 1.65,
      "bonus_hits": 4,
      "awakening_wings": 2,
      "awakening_wing_ratio": 0.45,
      "awakening_wave": true,
      "awakening_wave_ratio": 0.35
    },
    "role": "assault"
  },
  "ranged_rookie_rune_ring": {
    "name": "비전 종극 · 비전 집중",
    "description": "3곳으로 분산되는 대형 지대 · 착지·소멸 반응 폭발과 긴 지속시간",
    "patch": {
      "field_count": 3,
      "field_duration": 6.0,
      "field_radius_ratio": 0.65,
      "awakening_lob_spread": 145.0,
      "awakening_budget": 2.5
    },
    "role": "assault"
  },
  "ranged_rookie_pulse_staff": {
    "name": "비전 종극 · 파동 지팡이",
    "description": "기본 파동 뒤 이중 확장 충격파 · 더 넓은 범위로 시간차 연속 타격",
    "patch": {
      "awakening_wave": true,
      "awakening_wave_ratio": 0.45
    },
    "role": "assault"
  },
  "ranged_rookie_barrier_book": {
    "name": "비전 종극 · 마력 장벽",
    "description": "보호·회복 시 큰 수호 광륜이 주기적으로 맥동 · 실제 보호막 흡수25%에 반격",
    "patch": {
      "awakening_halo": true,
      "awakening_halo_ratio": 0.22,
      "awakening_counter_threshold": 0.25,
      "shield_duration": 6.0
    },
    "role": "support"
  },
  "swift_hunter_dagger": {
    "name": "월영의 끝없는 칼춤",
    "description": "근접 연격과 다방향 잔영 칼날 동시 전개",
    "patch": {
      "awakening_wave": true,
      "awakening_wave_ratio": 0.4,
      "awakening_wings": 2,
      "awakening_wing_ratio": 0.45
    },
    "role": "assault"
  },
  "swift_hunter_throwing_knife": {
    "name": "월영 해방 · 투척 단검",
    "description": "5적을 가르는 왕복 칼날 · 양옆45% 추가탄",
    "patch": {
      "awakening_wings": 2,
      "awakening_wing_ratio": 0.45,
      "awakening_mark_hits": 2,
      "awakening_flight": "return",
      "awakening_pierces": 5
    },
    "role": "assault"
  },
  "swift_hunter_shadow_wire": {
    "name": "월영 해방 · 급습-암살",
    "description": "근접 연격과 다방향 잔영 칼날 동시 전개",
    "patch": {
      "awakening_wave": true,
      "awakening_wave_ratio": 0.4,
      "awakening_wings": 2,
      "awakening_wing_ratio": 0.45
    },
    "role": "assault"
  },
  "swift_hunter_poison_needle": {
    "name": "월영 해방 · 독침",
    "description": "5적을 가르는 왕복 칼날 · 양옆45% 추가탄",
    "patch": {
      "awakening_wings": 2,
      "awakening_wing_ratio": 0.45,
      "awakening_mark_hits": 2,
      "awakening_flight": "return",
      "awakening_pierces": 5
    },
    "role": "assault"
  },
  "swift_hunter_moon_blade": {
    "name": "월영 해방 · 난도질",
    "description": "근접 연격과 다방향 잔영 칼날 동시 전개",
    "patch": {
      "awakening_wave": true,
      "awakening_wave_ratio": 0.4,
      "awakening_wings": 2,
      "awakening_wing_ratio": 0.45
    },
    "role": "assault"
  },
  "swift_hunter_shadow_bomb": {
    "name": "월영 해방 · 그림자 폭탄",
    "description": "기본 파동 뒤 이중 확장 충격파 · 더 넓은 범위로 시간차 연속 타격",
    "patch": {
      "awakening_wave": true,
      "awakening_wave_ratio": 0.45
    },
    "role": "assault"
  },
  "sword_shield_hero_longsword": {
    "name": "불멸의 성왕검",
    "description": "정면 검격이 전방위 성검 파동으로 전환",
    "patch": {
      "awakening_wave": true,
      "awakening_wave_ratio": 0.4,
      "pattern": "nova",
      "attack_kind": "melee"
    },
    "role": "assault"
  },
  "sword_shield_hero_piercing_spear": {
    "name": "성왕의 서약 · 검방 돌격 · 창격",
    "description": "직선 공격이 5방향 광선망으로 확장 · 후속 확대 충격파 전개",
    "patch": {
      "fan_lines": 5,
      "awakening_wave": true,
      "awakening_wave_ratio": 0.3
    },
    "role": "assault"
  },
  "sword_shield_hero_aegis": {
    "name": "성왕의 서약 · 막기",
    "description": "보호·회복 시 큰 수호 광륜이 주기적으로 맥동 · 실제 보호막 흡수25%에 반격",
    "patch": {
      "awakening_halo": true,
      "awakening_halo_ratio": 0.22,
      "awakening_counter_threshold": 0.25,
      "shield_duration": 6.0
    },
    "role": "support"
  },
  "sword_shield_hero_shield_hammer": {
    "name": "성왕의 서약 · 방패 망치",
    "description": "정면 검격이 전방위 성검 파동으로 전환",
    "patch": {
      "awakening_wave": true,
      "awakening_wave_ratio": 0.4,
      "pattern": "nova",
      "attack_kind": "melee"
    },
    "role": "assault"
  },
  "sword_shield_hero_blade_ring": {
    "name": "성왕의 서약 · 검막 방진",
    "description": "정면 검격이 전방위 성검 파동으로 전환",
    "patch": {
      "awakening_wave": true,
      "awakening_wave_ratio": 0.4,
      "pattern": "nova",
      "attack_kind": "melee"
    },
    "role": "assault"
  },
  "sword_shield_hero_battle_banner": {
    "name": "성왕의 서약 · 전장의 깃발",
    "description": "회복과 함께 대형 성역이 맥동",
    "patch": {
      "awakening_halo": true,
      "awakening_halo_ratio": 0.22,
      "awakening_counter_threshold": 0.25,
      "shield_duration": 6.0
    },
    "role": "support"
  },
  "pistol_hero_revolver": {
    "name": "최후통첩 · 도탄폭풍",
    "description": "실탄이 최대7적을 잇는 도탄으로 진화 · 양옆45% 추가탄",
    "patch": {
      "awakening_wings": 2,
      "awakening_wing_ratio": 0.45,
      "awakening_mark_hits": 2,
      "awakening_flight": "bounce",
      "awakening_bounces": 6
    },
    "role": "assault"
  },
  "pistol_hero_shotgun": {
    "name": "결전 병기 · 실린더 스트라이크",
    "description": "근접 연격과 다방향 잔영 칼날 동시 전개",
    "patch": {
      "awakening_wave": true,
      "awakening_wave_ratio": 0.4,
      "awakening_wings": 2,
      "awakening_wing_ratio": 0.45
    },
    "role": "assault"
  },
  "pistol_hero_rifle": {
    "name": "결전 병기 · 데드아이",
    "description": "실탄이 최대7적을 잇는 도탄으로 진화 · 양옆45% 추가탄",
    "patch": {
      "awakening_wings": 2,
      "awakening_wing_ratio": 0.45,
      "awakening_mark_hits": 2,
      "awakening_flight": "bounce",
      "awakening_bounces": 6
    },
    "role": "assault"
  },
  "pistol_hero_ricochet": {
    "name": "결전 병기 · 도탄 권총",
    "description": "실탄이 최대7적을 잇는 도탄으로 진화 · 양옆45% 추가탄",
    "patch": {
      "awakening_wings": 2,
      "awakening_wing_ratio": 0.45,
      "awakening_mark_hits": 2,
      "awakening_flight": "bounce",
      "awakening_bounces": 6
    },
    "role": "assault"
  },
  "pistol_hero_grenade": {
    "name": "결전 병기 · 충격 수류탄",
    "description": "기본 파동 뒤 이중 확장 충격파 · 더 넓은 범위로 시간차 연속 타격",
    "patch": {
      "awakening_wave": true,
      "awakening_wave_ratio": 0.45
    },
    "role": "assault"
  },
  "pistol_hero_powder_bomb": {
    "name": "결전 병기 · 화약 폭탄",
    "description": "3곳으로 분산되는 대형 지대 · 착지·소멸 반응 폭발과 긴 지속시간",
    "patch": {
      "field_count": 3,
      "field_duration": 6.0,
      "field_radius_ratio": 0.65,
      "awakening_lob_spread": 145.0,
      "awakening_budget": 2.5
    },
    "role": "assault"
  },
  "archmage_hero_fire_staff": {
    "name": "삼원소 대재앙",
    "description": "주력 공격과 양옆 추가탄 동시 전개 · 양옆45% 추가탄",
    "patch": {
      "awakening_wings": 2,
      "awakening_wing_ratio": 0.45,
      "awakening_mark_hits": 2
    },
    "role": "assault"
  },
  "archmage_hero_ice_scepter": {
    "name": "원소 재앙 · 아이스볼트",
    "description": "기본 파동 뒤 이중 확장 충격파 · 더 넓은 범위로 시간차 연속 타격",
    "patch": {
      "awakening_wave": true,
      "awakening_wave_ratio": 0.45
    },
    "role": "assault"
  },
  "archmage_hero_lightning_rod": {
    "name": "원소 재앙 · 체인대거",
    "description": "주력 공격과 양옆 추가탄 동시 전개 · 양옆45% 추가탄",
    "patch": {
      "awakening_wings": 2,
      "awakening_wing_ratio": 0.45,
      "awakening_mark_hits": 2
    },
    "role": "assault"
  },
  "archmage_hero_earth_staff": {
    "name": "원소 재앙 · 땅의 가시",
    "description": "기본 파동 뒤 이중 확장 충격파 · 더 넓은 범위로 시간차 연속 타격",
    "patch": {
      "awakening_wave": true,
      "awakening_wave_ratio": 0.45
    },
    "role": "assault"
  },
  "archmage_hero_storm_orb": {
    "name": "원소 재앙 · 폭풍",
    "description": "기본 파동 뒤 이중 확장 충격파 · 더 넓은 범위로 시간차 연속 타격",
    "patch": {
      "awakening_wave": true,
      "awakening_wave_ratio": 0.45
    },
    "role": "assault"
  },
  "archmage_hero_prism_wand": {
    "name": "원소 재앙 · 신성력",
    "description": "직선 공격이 5방향 광선망으로 확장 · 후속 확대 충격파 전개",
    "patch": {
      "fan_lines": 5,
      "awakening_wave": true,
      "awakening_wave_ratio": 0.3
    },
    "role": "assault"
  },
  "madness_hero_blood_sword": {
    "name": "혈왕의 육연참",
    "description": "연격 뒤 이중 혈월 충격파가 연속 확장",
    "patch": {
      "awakening_wave": true,
      "awakening_wave_ratio": 0.4,
      "finish_radius": 230.0,
      "finish_ratio": 1.2
    },
    "role": "assault"
  },
  "madness_hero_blood_lance": {
    "name": "혈왕 강림 · 혈검술 제2식",
    "description": "직선 공격이 5방향 광선망으로 확장 · 후속 확대 충격파 전개",
    "patch": {
      "fan_lines": 5,
      "awakening_wave": true,
      "awakening_wave_ratio": 0.3
    },
    "role": "assault"
  },
  "madness_hero_blood_wheel": {
    "name": "혈왕 강림 · 핏빛 검륜",
    "description": "연격 뒤 이중 혈월 충격파가 연속 확장",
    "patch": {
      "awakening_wave": true,
      "awakening_wave_ratio": 0.4,
      "finish_radius": 230.0,
      "finish_ratio": 1.2
    },
    "role": "assault"
  },
  "madness_hero_blood_burst": {
    "name": "혈왕 강림 · 혈검술 제4식",
    "description": "기본 파동 뒤 이중 확장 충격파 · 더 넓은 범위로 시간차 연속 타격",
    "patch": {
      "awakening_wave": true,
      "awakening_wave_ratio": 0.45
    },
    "role": "assault"
  },
  "madness_hero_drain_blade": {
    "name": "혈왕 강림 · 흡혈 검",
    "description": "연격 뒤 이중 혈월 충격파가 연속 확장",
    "patch": {
      "awakening_wave": true,
      "awakening_wave_ratio": 0.4,
      "finish_radius": 230.0,
      "finish_ratio": 1.2
    },
    "role": "assault"
  },
  "madness_hero_heart_chain": {
    "name": "혈왕 강림 · 심장 사슬",
    "description": "주력 공격과 양옆 추가탄 동시 전개 · 양옆45% 추가탄",
    "patch": {
      "awakening_wings": 2,
      "awakening_wing_ratio": 0.45,
      "awakening_mark_hits": 2
    },
    "role": "assault"
  },
  "chemical_hero_acid_vial": {
    "name": "금단연성 · 왕수폭우",
    "description": "3곳으로 분산되는 대형 지대 · 착지·소멸 반응 폭발과 긴 지속시간",
    "patch": {
      "field_count": 3,
      "field_duration": 6.0,
      "field_radius_ratio": 0.65,
      "awakening_lob_spread": 145.0,
      "awakening_budget": 2.5
    },
    "role": "assault"
  },
  "chemical_hero_poison_flask": {
    "name": "금단 연성 · 촉매 혼합장",
    "description": "3곳으로 분산되는 대형 지대 · 착지·소멸 반응 폭발과 긴 지속시간",
    "patch": {
      "field_count": 3,
      "field_duration": 6.0,
      "field_radius_ratio": 0.65,
      "awakening_lob_spread": 145.0,
      "awakening_budget": 2.5
    },
    "role": "assault"
  },
  "chemical_hero_cryo_vial": {
    "name": "금단 연성 · 냉각 약병",
    "description": "기본 파동 뒤 이중 확장 충격파 · 더 넓은 범위로 시간차 연속 타격",
    "patch": {
      "awakening_wave": true,
      "awakening_wave_ratio": 0.45
    },
    "role": "assault"
  },
  "chemical_hero_reaction_bomb": {
    "name": "금단 연성 · 오늘도 실팬가!",
    "description": "기본 파동 뒤 이중 확장 충격파 · 더 넓은 범위로 시간차 연속 타격",
    "patch": {
      "awakening_wave": true,
      "awakening_wave_ratio": 0.45
    },
    "role": "assault"
  },
  "chemical_hero_acid_cannon": {
    "name": "금단 연성 · 압축 산성포",
    "description": "직선 공격이 5방향 광선망으로 확장 · 후속 확대 충격파 전개",
    "patch": {
      "fan_lines": 5,
      "awakening_wave": true,
      "awakening_wave_ratio": 0.3
    },
    "role": "assault"
  },
  "chemical_hero_life_elixir": {
    "name": "금단 연성 · 현자의 비약",
    "description": "회복과 함께 대형 성역이 맥동",
    "patch": {
      "awakening_halo": true,
      "awakening_halo_ratio": 0.22,
      "awakening_counter_threshold": 0.25,
      "shield_duration": 6.0
    },
    "role": "support"
  },
  "summoner_hero_gate_hound": {
    "name": "심연개방 · 군단강습",
    "description": "활성 소환수 전원이 3연속 차원 협공 · 소환 유지40초·용사HP170%의 내구",
    "patch": {
      "awakening_command_rounds": 3,
      "summon_duration": 40.0,
      "summon_hp_ratio": 1.7
    },
    "role": "assault"
  },
  "summoner_hero_watcher": {
    "name": "심연 개방 · 이계의 문 - 감시자",
    "description": "활성 소환수 전원이 3연속 차원 협공 · 소환 유지40초·감시자는 무적",
    "patch": {
      "awakening_command_rounds": 3,
      "summon_duration": 40.0,
      "summon_hp_ratio": 0.0
    },
    "role": "assault"
  },
  "summoner_hero_scout": {
    "name": "심연 개방 · 이계의 문 - 정찰병",
    "description": "활성 소환수 전원이 3연속 차원 협공 · 소환 유지40초·용사HP200%의 내구",
    "patch": {
      "awakening_command_rounds": 3,
      "summon_duration": 40.0,
      "summon_hp_ratio": 2.0
    },
    "role": "assault"
  },
  "summoner_hero_gate_laser": {
    "name": "심연 개방 · 차원 관통문",
    "description": "직선 공격이 5방향 광선망으로 확장 · 후속 확대 충격파 전개",
    "patch": {
      "fan_lines": 5,
      "awakening_wave": true,
      "awakening_wave_ratio": 0.3
    },
    "role": "assault"
  },
  "summoner_hero_gatekeeper": {
    "name": "심연 개방 · 이계의 문 - 문지기",
    "description": "활성 소환수 전원이 3연속 차원 협공 · 소환 유지40초·용사HP150%의 내구",
    "patch": {
      "awakening_command_rounds": 3,
      "summon_duration": 40.0,
      "summon_hp_ratio": 1.5
    },
    "role": "assault"
  },
  "summoner_hero_rift_pulse": {
    "name": "심연 개방 · 균열 파동",
    "description": "기본 파동 뒤 이중 확장 충격파 · 더 넓은 범위로 시간차 연속 타격",
    "patch": {
      "awakening_wave": true,
      "awakening_wave_ratio": 0.45
    },
    "role": "assault"
  },
  "purifier_hero_holy_bolt": {
    "name": "대성인의 천벌",
    "description": "주력 공격과 양옆 추가탄 동시 전개 · 양옆45% 추가탄",
    "patch": {
      "awakening_wings": 2,
      "awakening_wing_ratio": 0.45,
      "awakening_mark_hits": 2
    },
    "role": "assault"
  },
  "purifier_hero_holy_lance": {
    "name": "대성인의 기적 · 궁그닐",
    "description": "직선 공격이 5방향 광선망으로 확장 · 후속 확대 충격파 전개",
    "patch": {
      "fan_lines": 5,
      "awakening_wave": true,
      "awakening_wave_ratio": 0.3
    },
    "role": "assault"
  },
  "purifier_hero_purification": {
    "name": "대성인의 기적 · 정화",
    "description": "기본 파동 뒤 이중 확장 충격파 · 더 넓은 범위로 시간차 연속 타격",
    "patch": {
      "awakening_wave": true,
      "awakening_wave_ratio": 0.45
    },
    "role": "assault"
  },
  "purifier_hero_sacred_orb": {
    "name": "대성인의 기적 · 순례의 성역",
    "description": "3곳으로 분산되는 대형 지대 · 착지·소멸 반응 폭발과 긴 지속시간",
    "patch": {
      "field_count": 3,
      "field_duration": 6.0,
      "field_radius_ratio": 0.65,
      "awakening_lob_spread": 145.0,
      "awakening_budget": 2.5
    },
    "role": "assault"
  },
  "purifier_hero_blessing": {
    "name": "대성인의 기적 · 신성보호",
    "description": "보호·회복 시 큰 수호 광륜이 주기적으로 맥동 · 실제 보호막 흡수25%에 반격",
    "patch": {
      "awakening_halo": true,
      "awakening_halo_ratio": 0.22,
      "awakening_counter_threshold": 0.25,
      "shield_duration": 6.0
    },
    "role": "support"
  },
  "purifier_hero_prayer": {
    "name": "대성인의 기적 · 회복의 성배",
    "description": "회복과 함께 대형 성역이 맥동",
    "patch": {
      "awakening_halo": true,
      "awakening_halo_ratio": 0.22,
      "awakening_counter_threshold": 0.25,
      "shield_duration": 6.0
    },
    "role": "support"
  },
  "sage_astra_starlight": {
    "name": "은하종말 · 성좌붕괴",
    "description": "주력 공격과 양옆 추가탄 동시 전개 · 양옆45% 추가탄",
    "patch": {
      "awakening_wings": 2,
      "awakening_wing_ratio": 0.45,
      "awakening_mark_hits": 2
    },
    "role": "assault"
  },
  "sage_astra_comet": {
    "name": "은하 붕괴 · 스타라이트",
    "description": "전용 기술의 대형화·폭 넓은 다중 전개 · 시전 후 확대되는 천체 충격파",
    "patch": {
      "native_radius_scale": 1.65,
      "bonus_hits": 4,
      "awakening_wave": true,
      "awakening_wave_ratio": 0.35
    },
    "role": "assault"
  },
  "sage_astra_astral_chain": {
    "name": "은하 붕괴 · 천체 사슬",
    "description": "주력 공격과 양옆 추가탄 동시 전개 · 양옆45% 추가탄",
    "patch": {
      "awakening_wings": 2,
      "awakening_wing_ratio": 0.45,
      "awakening_mark_hits": 2
    },
    "role": "assault"
  },
  "sage_astra_absolute_zero": {
    "name": "은하 붕괴 · 빙점폭발",
    "description": "전용 기술의 대형화·폭 넓은 다중 전개 · 시전 후 확대되는 천체 충격파",
    "patch": {
      "native_radius_scale": 1.65,
      "field_duration": 6.5,
      "awakening_wave": true,
      "awakening_wave_ratio": 0.35
    },
    "role": "assault"
  },
  "sage_astra_singularity": {
    "name": "은하 붕괴 · 소멸",
    "description": "전용 기술의 대형화·폭 넓은 다중 전개 · 시전 후 확대되는 천체 충격파",
    "patch": {
      "native_radius_scale": 1.65,
      "field_duration": 6.5,
      "awakening_wave": true,
      "awakening_wave_ratio": 0.35
    },
    "role": "assault"
  },
  "sage_astra_binary_stars": {
    "name": "은하 붕괴 · 쌍성의 고리",
    "description": "10개의 대형 위성이 안팎 궤도를 교차 · 공전 반경과 접촉 범위 확대",
    "patch": {
      "orbit_count": 10,
      "orbit_ratio": 0.9,
      "orbit_speed": 3.4,
      "awakening_budget": 1.65
    },
    "role": "assault"
  },
  "ranged_rookie_sealing_bolt": {
    "name": "비전 종극 · 봉인 마법구",
    "description": "다중 관통·두 겹 비전 각인 · 양옆45% 추가탄 · 각인2회 적중으로 폭발",
    "patch": {
      "awakening_wings": 2,
      "awakening_wing_ratio": 0.45,
      "awakening_mark_hits": 2,
      "awakening_pierces": 6
    },
    "role": "assault"
  },
  "ranged_rookie_satellite_orbs": {
    "name": "비전 종극 · 위성 마력구",
    "description": "10개의 대형 위성이 안팎 궤도를 교차 · 공전 반경과 접촉 범위 확대",
    "patch": {
      "orbit_count": 10,
      "orbit_ratio": 0.9,
      "orbit_speed": 3.4,
      "awakening_budget": 1.65
    },
    "role": "assault"
  },
  "ranged_rookie_rune_ray": {
    "name": "비전 종극 · 룬 분광봉",
    "description": "직선 공격이 5방향 광선망으로 확장 · 후속 확대 충격파 전개",
    "patch": {
      "fan_lines": 5,
      "awakening_wave": true,
      "awakening_wave_ratio": 0.3
    },
    "role": "assault"
  },
  "ranged_rookie_restoration_codex": {
    "name": "비전 종극 · 안식의 마도서",
    "description": "보호·회복 시 큰 수호 광륜이 주기적으로 맥동 · 실제 보호막 흡수25%에 반격",
    "patch": {
      "awakening_halo": true,
      "awakening_halo_ratio": 0.22,
      "awakening_counter_threshold": 0.25,
      "shield_duration": 6.0
    },
    "role": "support"
  },
  "swift_hunter_execution_stiletto": {
    "name": "월영 해방 · 처형 단도",
    "description": "근접 연격과 다방향 잔영 칼날 동시 전개",
    "patch": {
      "awakening_wave": true,
      "awakening_wave_ratio": 0.4,
      "awakening_wings": 2,
      "awakening_wing_ratio": 0.45
    },
    "role": "assault"
  },
  "swift_hunter_binding_wire": {
    "name": "월영 해방 · 그림자 결박줄",
    "description": "5적을 가르는 왕복 칼날 · 양옆45% 추가탄",
    "patch": {
      "awakening_wings": 2,
      "awakening_wing_ratio": 0.45,
      "awakening_mark_hits": 2,
      "awakening_flight": "return",
      "awakening_pierces": 5
    },
    "role": "assault"
  },
  "swift_hunter_smoke_mantle": {
    "name": "월영 해방 · 연막 망토",
    "description": "보호·회복 시 큰 수호 광륜이 주기적으로 맥동 · 실제 보호막 흡수25%에 반격",
    "patch": {
      "awakening_halo": true,
      "awakening_halo_ratio": 0.22,
      "awakening_counter_threshold": 0.25,
      "shield_duration": 6.0
    },
    "role": "support"
  },
  "swift_hunter_venom_steps": {
    "name": "월영 해방 · 독무 발톱",
    "description": "이동 경로에 남기는 3중 독성 지대 · 지속6초·지대 피해 예산2.5배",
    "patch": {
      "field_count": 3,
      "field_duration": 6.0,
      "field_radius_ratio": 0.65,
      "awakening_lob_spread": 145.0,
      "awakening_budget": 2.5
    },
    "role": "assault"
  },
  "sword_shield_hero_oath_blade": {
    "name": "성왕의 서약 · 맹세의 검",
    "description": "정면 검격이 전방위 성검 파동으로 전환",
    "patch": {
      "awakening_wave": true,
      "awakening_wave_ratio": 0.4,
      "pattern": "nova",
      "attack_kind": "melee"
    },
    "role": "assault"
  },
  "sword_shield_hero_ward_crossbow": {
    "name": "성왕의 서약 · 수호 쇠뇌",
    "description": "주력 공격과 양옆 추가탄 동시 전개 · 양옆45% 추가탄",
    "patch": {
      "awakening_wings": 2,
      "awakening_wing_ratio": 0.45,
      "awakening_mark_hits": 2
    },
    "role": "assault"
  },
  "sword_shield_hero_sanctuary_shield": {
    "name": "성왕의 서약 · 성역 방패",
    "description": "보호·회복 시 큰 수호 광륜이 주기적으로 맥동 · 실제 보호막 흡수25%에 반격",
    "patch": {
      "awakening_halo": true,
      "awakening_halo_ratio": 0.22,
      "awakening_counter_threshold": 0.25,
      "shield_duration": 6.0
    },
    "role": "support"
  },
  "sword_shield_hero_rally_standard": {
    "name": "성왕의 서약 · 결집 군기",
    "description": "회복과 함께 대형 성역이 맥동",
    "patch": {
      "awakening_halo": true,
      "awakening_halo_ratio": 0.22,
      "awakening_counter_threshold": 0.25,
      "shield_duration": 6.0
    },
    "role": "support"
  },
  "pistol_hero_twin_pistols": {
    "name": "결전 병기 · 쌍열 권총",
    "description": "실탄이 최대7적을 잇는 도탄으로 진화 · 양옆45% 추가탄",
    "patch": {
      "awakening_wings": 2,
      "awakening_wing_ratio": 0.45,
      "awakening_mark_hits": 2,
      "awakening_flight": "bounce",
      "awakening_bounces": 6
    },
    "role": "assault"
  },
  "pistol_hero_shrapnel_round": {
    "name": "결전 병기 · 파쇄 탄환",
    "description": "실탄이 최대7적을 잇는 도탄으로 진화 · 양옆45% 추가탄",
    "patch": {
      "awakening_wings": 2,
      "awakening_wing_ratio": 0.45,
      "awakening_mark_hits": 2,
      "awakening_flight": "bounce",
      "awakening_bounces": 6
    },
    "role": "assault"
  },
  "pistol_hero_suppressor": {
    "name": "결전 병기 · 제압 기관권총",
    "description": "실탄이 최대7적을 잇는 도탄으로 진화 · 양옆45% 추가탄",
    "patch": {
      "awakening_wings": 2,
      "awakening_wing_ratio": 0.45,
      "awakening_mark_hits": 2,
      "awakening_flight": "bounce",
      "awakening_bounces": 6
    },
    "role": "assault"
  },
  "pistol_hero_smoke_canister": {
    "name": "결전 병기 · 연막 유탄",
    "description": "3곳으로 분산되는 대형 지대 · 착지·소멸 반응 폭발과 긴 지속시간",
    "patch": {
      "field_count": 3,
      "field_duration": 6.0,
      "field_radius_ratio": 0.65,
      "awakening_lob_spread": 145.0,
      "awakening_budget": 2.5
    },
    "role": "assault"
  },
  "archmage_hero_lava_focus": {
    "name": "원소 재앙 · 용암 촉매봉",
    "description": "3곳으로 분산되는 대형 지대 · 착지·소멸 반응 폭발과 긴 지속시간",
    "patch": {
      "field_count": 3,
      "field_duration": 6.0,
      "field_radius_ratio": 0.65,
      "awakening_lob_spread": 145.0,
      "awakening_budget": 2.5
    },
    "role": "assault"
  },
  "archmage_hero_frost_moons": {
    "name": "원소 재앙 · 빙결 위성",
    "description": "기본 파동 뒤 이중 확장 충격파 · 더 넓은 범위로 시간차 연속 타격",
    "patch": {
      "awakening_wave": true,
      "awakening_wave_ratio": 0.45
    },
    "role": "assault"
  },
  "archmage_hero_gale_prism": {
    "name": "원소 재앙 · 질풍 프리즘",
    "description": "직선 공격이 5방향 광선망으로 확장 · 후속 확대 충격파 전개",
    "patch": {
      "fan_lines": 5,
      "awakening_wave": true,
      "awakening_wave_ratio": 0.3
    },
    "role": "assault"
  },
  "archmage_hero_sunfire_tome": {
    "name": "원소 재앙 · 태양화염서",
    "description": "기본 파동 뒤 이중 확장 충격파 · 더 넓은 범위로 시간차 연속 타격",
    "patch": {
      "awakening_wave": true,
      "awakening_wave_ratio": 0.45
    },
    "role": "assault"
  },
  "madness_hero_desperate_cleaver": {
    "name": "혈왕 강림 · 결사의 참수검",
    "description": "연격 뒤 이중 혈월 충격파가 연속 확장",
    "patch": {
      "awakening_wave": true,
      "awakening_wave_ratio": 0.4,
      "finish_radius": 230.0,
      "finish_ratio": 1.2
    },
    "role": "assault"
  },
  "madness_hero_vampire_fang": {
    "name": "혈왕 강림 · 흡혈 송곳니",
    "description": "연격 뒤 이중 혈월 충격파가 연속 확장",
    "patch": {
      "awakening_wave": true,
      "awakening_wave_ratio": 0.4,
      "finish_radius": 230.0,
      "finish_ratio": 1.2
    },
    "role": "assault"
  },
  "madness_hero_blood_thorns": {
    "name": "혈왕 강림 · 혈흔 가시",
    "description": "대형 혈독 오라와 이중 혈월 충격파 · 지속 피해 강화",
    "patch": {
      "field_count": 1,
      "field_duration": 6.0,
      "field_radius_ratio": 0.65,
      "awakening_lob_spread": 145.0,
      "awakening_budget": 2.5,
      "awakening_wave": true,
      "awakening_wave_ratio": 0.4
    },
    "role": "assault"
  },
  "madness_hero_blood_aegis": {
    "name": "혈왕 강림 · 핏빛 수호구",
    "description": "보호·회복 시 큰 수호 광륜이 주기적으로 맥동 · 실제 보호막 흡수25%에 반격",
    "patch": {
      "awakening_halo": true,
      "awakening_halo_ratio": 0.22,
      "awakening_counter_threshold": 0.25,
      "shield_duration": 6.0
    },
    "role": "support"
  },
  "chemical_hero_caustic_boots": {
    "name": "금단 연성 · 부식 분무기",
    "description": "이동 경로에 남기는 3중 독성 지대 · 지속6초·지대 피해 예산2.5배",
    "patch": {
      "field_count": 3,
      "field_duration": 6.0,
      "field_radius_ratio": 0.65,
      "awakening_lob_spread": 145.0,
      "awakening_budget": 2.5
    },
    "role": "assault"
  },
  "chemical_hero_catalyst_wire": {
    "name": "금단 연성 · 촉매 도선",
    "description": "주력 공격과 양옆 추가탄 동시 전개 · 양옆45% 추가탄",
    "patch": {
      "awakening_wings": 2,
      "awakening_wing_ratio": 0.45,
      "awakening_mark_hits": 2
    },
    "role": "assault"
  },
  "chemical_hero_toxic_dart": {
    "name": "금단 연성 · 독성 주사총",
    "description": "주력 공격과 양옆 추가탄 동시 전개 · 양옆45% 추가탄",
    "patch": {
      "awakening_wings": 2,
      "awakening_wing_ratio": 0.45,
      "awakening_mark_hits": 2
    },
    "role": "assault"
  },
  "chemical_hero_antidote_capsule": {
    "name": "금단 연성 · 해독 캡슐",
    "description": "보호·회복 시 큰 수호 광륜이 주기적으로 맥동 · 실제 보호막 흡수25%에 반격",
    "patch": {
      "awakening_halo": true,
      "awakening_halo_ratio": 0.22,
      "awakening_counter_threshold": 0.25,
      "shield_duration": 6.0
    },
    "role": "support"
  },
  "summoner_hero_rift_orbit": {
    "name": "심연 개방 · 차원 협공검",
    "description": "근접 연격과 다방향 잔영 칼날 동시 전개",
    "patch": {
      "awakening_wave": true,
      "awakening_wave_ratio": 0.4,
      "awakening_wings": 2,
      "awakening_wing_ratio": 0.45
    },
    "role": "assault"
  },
  "summoner_hero_collapse_glyph": {
    "name": "심연 개방 · 붕괴 문양",
    "description": "3곳으로 분산되는 대형 지대 · 착지·소멸 반응 폭발과 긴 지속시간",
    "patch": {
      "field_count": 3,
      "field_duration": 6.0,
      "field_radius_ratio": 0.65,
      "awakening_lob_spread": 145.0,
      "awakening_budget": 2.5
    },
    "role": "assault"
  },
  "summoner_hero_gate_shard": {
    "name": "심연 개방 · 차원 파편구",
    "description": "주력 공격과 양옆 추가탄 동시 전개 · 양옆45% 추가탄",
    "patch": {
      "awakening_wings": 2,
      "awakening_wing_ratio": 0.45,
      "awakening_mark_hits": 2
    },
    "role": "assault"
  },
  "summoner_hero_binding_gate": {
    "name": "심연 개방 · 결박의 문",
    "description": "기본 파동 뒤 이중 확장 충격파 · 더 넓은 범위로 시간차 연속 타격",
    "patch": {
      "awakening_wave": true,
      "awakening_wave_ratio": 0.45
    },
    "role": "assault"
  },
  "purifier_hero_mercy_chain": {
    "name": "대성인의 기적 · 자비의 사슬",
    "description": "주력 공격과 양옆 추가탄 동시 전개 · 양옆45% 추가탄",
    "patch": {
      "awakening_wings": 2,
      "awakening_wing_ratio": 0.45,
      "awakening_mark_hits": 2
    },
    "role": "assault"
  },
  "purifier_hero_judgment_seal": {
    "name": "대성인의 기적 · 심판 낙인",
    "description": "3곳으로 분산되는 대형 지대 · 착지·소멸 반응 폭발과 긴 지속시간",
    "patch": {
      "field_count": 3,
      "field_duration": 6.0,
      "field_radius_ratio": 0.65,
      "awakening_lob_spread": 145.0,
      "awakening_budget": 2.5
    },
    "role": "assault"
  },
  "purifier_hero_saint_reliquary": {
    "name": "대성인의 기적 · 성인의 유골함",
    "description": "보호·회복 시 큰 수호 광륜이 주기적으로 맥동 · 실제 보호막 흡수25%에 반격",
    "patch": {
      "awakening_halo": true,
      "awakening_halo_ratio": 0.22,
      "awakening_counter_threshold": 0.25,
      "shield_duration": 6.0
    },
    "role": "support"
  },
  "purifier_hero_martyr_blade": {
    "name": "대성인의 기적 · 순교자의 검",
    "description": "근접 연격과 다방향 잔영 칼날 동시 전개",
    "patch": {
      "awakening_wave": true,
      "awakening_wave_ratio": 0.4,
      "awakening_wings": 2,
      "awakening_wing_ratio": 0.45
    },
    "role": "assault"
  },
  "sage_astra_gravity_lance": {
    "name": "은하 붕괴 · 중력 성창",
    "description": "직선 공격이 5방향 광선망으로 확장 · 후속 확대 충격파 전개",
    "patch": {
      "fan_lines": 5,
      "awakening_wave": true,
      "awakening_wave_ratio": 0.3
    },
    "role": "assault"
  },
  "sage_astra_frozen_stars": {
    "name": "은하 붕괴 · 빙성 결계",
    "description": "3곳으로 분산되는 대형 지대 · 착지·소멸 반응 폭발과 긴 지속시간",
    "patch": {
      "field_count": 3,
      "field_duration": 6.0,
      "field_radius_ratio": 0.65,
      "awakening_lob_spread": 145.0,
      "awakening_budget": 2.5
    },
    "role": "assault"
  },
  "sage_astra_supernova_core": {
    "name": "은하 붕괴 · 초신성 핵",
    "description": "기본 파동 뒤 이중 확장 충격파 · 더 넓은 범위로 시간차 연속 타격",
    "patch": {
      "awakening_wave": true,
      "awakening_wave_ratio": 0.45
    },
    "role": "assault"
  },
  "sage_astra_collapsed_seed": {
    "name": "은하 붕괴 · 붕괴 별씨",
    "description": "주력 공격과 양옆 추가탄 동시 전개 · 양옆45% 추가탄",
    "patch": {
      "awakening_wings": 2,
      "awakening_wing_ratio": 0.45,
      "awakening_mark_hits": 2
    },
    "role": "assault"
  }
}
static func apply(id: String,data: Dictionary) -> void:
 var rule: Dictionary = PROFILES[id]
 for key in rule.patch: data[key]=rule.patch[key]
 data["awakening"] = true
 data["reach_scale"] = float(data.reach_scale)*1.3
 data["awakening_visual_scale"] = 1.55
static func description(id: String) -> String:
 return String(PROFILES[id].description)
