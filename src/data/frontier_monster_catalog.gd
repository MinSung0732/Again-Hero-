extends RefCounted
## Eight cost-budgeted monsters. No actor/catalog dependency.
const DEFINITIONS := {
  "harpy": {
    "id": "harpy",
    "name": "하피",
    "grade": "common",
    "rarity": "common",
    "role": "swarm",
    "family": "harpy",
    "species": "beast",
    "base_cost": 5.0,
    "summon_exp": 5.0,
    "attack_type": "melee",
    "base_stats": {
      "max_hp": 1,
      "attack_damage": 1,
      "move_speed": 138.0,
      "attack_range": 78.0,
      "attack_cooldown": 1.05,
      "exp_reward": 5,
      "projectile_speed": 0.0
    },
    "balance": {
      "health_share": 0.82,
      "damage_share": 0.82,
      "cycle_damage_multiplier": 1.1666666666666667,
      "note": "3회 주기 100%+100%+150% 합계350%를 평균7/6으로 계산. 고속 접근/3타 후 가속에 HP·DPS 예산18% 할인. 실전 승률 미검증."
    },
    "description": "가벼운 비행 물량. 매 3번째 공격은 150% 피해와 1.5초 이속20% 증가.",
    "special_augment_ids": [
      "harpy_special_1",
      "harpy_special_2",
      "harpy_special_3"
    ],
    "elite_skills": [
      {
        "id": "elite_harpy_gale",
        "name": "날갯바람",
        "description": "지정 대상 위치를0.4초 예고 후 대상1명에 공격력150% 피해, 1초 25% 둔화. 대상이 반경105 예고 원 밖으로 이동하면 불발.",
        "runtime": "monster",
        "kind": "strike",
        "initial_cooldown": 3.0,
        "cooldown": 12.0,
        "retry_interval": 0.35,
        "windup": 0.4,
        "cast_range": 230.0,
        "radius": 105.0,
        "damage_multiplier": 1.5,
        "slow_multiplier": 0.75,
        "slow_duration": 1.0,
        "color": "dbecab"
      }
    ],
    "card_icon_path": "res://assets/art/monsters/harpy/frames/idle_01.png",
    "behavior": {
      "third_bonus": 0.5,
      "third_speed": 1.2,
      "speed_duration": 1.5
    },
    "normal_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/monsters/harpy/frames",
      "target_height": 169.76842,
      "animations": {
        "idle": {
          "prefix": "idle",
          "count": 4,
          "fps": 6.0,
          "loop": true
        },
        "move": {
          "prefix": "move",
          "count": 6,
          "fps": 10.0,
          "loop": true
        },
        "attack": {
          "prefix": "attack",
          "count": 6,
          "fps": 14.0,
          "loop": false
        },
        "hit": {
          "prefix": "hit",
          "count": 3,
          "fps": 12.0,
          "loop": false
        },
        "death": {
          "prefix": "death",
          "count": 4,
          "fps": 10.0,
          "loop": false
        }
      },
      "offset": [
        13.0,
        -111.0
      ],
      "source_idle_bounds": [
        146,
        113,
        340,
        303
      ],
      "body_height": 84
    },
    "elite_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/elitemonster/harpy/frames",
      "target_height": 166.58028,
      "animations": {
        "idle": {
          "prefix": "idle",
          "count": 4,
          "fps": 6.0,
          "loop": true
        },
        "move": {
          "prefix": "move",
          "count": 6,
          "fps": 10.0,
          "loop": true
        },
        "attack": {
          "prefix": "attack",
          "count": 6,
          "fps": 14.0,
          "loop": false
        },
        "hit": {
          "prefix": "hit",
          "count": 3,
          "fps": 12.0,
          "loop": false
        },
        "death": {
          "prefix": "death",
          "count": 4,
          "fps": 10.0,
          "loop": false
        }
      },
      "offset": [
        19.0,
        -128.0
      ],
      "source_idle_bounds": [
        115,
        107,
        359,
        320
      ],
      "body_height": 92.4
    },
    "hero_survival_after": 300.0
  },
  "imp": {
    "id": "imp",
    "name": "임프",
    "grade": "common",
    "rarity": "common",
    "role": "ranged",
    "family": "imp",
    "species": "demon",
    "base_cost": 6.0,
    "summon_exp": 6.0,
    "attack_type": "ranged",
    "base_stats": {
      "max_hp": 1,
      "attack_damage": 1,
      "move_speed": 100.0,
      "attack_range": 350.0,
      "attack_cooldown": 1.5,
      "exp_reward": 6,
      "projectile_speed": 310.0
    },
    "balance": {
      "health_share": 0.85,
      "damage_share": 0.9,
      "cycle_damage_multiplier": 1.0,
      "note": "단일 화염탄을 발사하는 저비용 중거리 딜러. 투사체는 회피 가능. 고유 능력·엘리트는 별도 기여로 HP/기본DPS 할인. 실전 승률 미검증."
    },
    "description": "단일 화염탄을 발사하는 저비용 중거리 딜러. 투사체는 회피 가능.",
    "special_augment_ids": [
      "imp_special_1",
      "imp_special_2",
      "imp_special_3"
    ],
    "elite_skills": [
      {
        "id": "elite_imp_fan",
        "name": "갈라지는 화염",
        "description": "전방 3방향에 각 공격력60% 화염탄. 탄마다 회피 가능.",
        "runtime": "monster",
        "kind": "fan",
        "initial_cooldown": 3.0,
        "cooldown": 14.0,
        "retry_interval": 0.35,
        "cast_range": 460.0,
        "damage_multiplier": 0.6,
        "spread": 0.18,
        "color": "ff8844"
      }
    ],
    "card_icon_path": "res://assets/art/monsters/imp/frames/idle_01.png",
    "behavior": {
      "projectile": true,
      "projectile_speed": 310.0,
      "color": "ff8844"
    },
    "normal_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/monsters/imp/frames",
      "target_height": 126.33766,
      "animations": {
        "idle": {
          "prefix": "idle",
          "count": 4,
          "fps": 6.0,
          "loop": true
        },
        "move": {
          "prefix": "move",
          "count": 6,
          "fps": 10.0,
          "loop": true
        },
        "attack": {
          "prefix": "attack",
          "count": 6,
          "fps": 14.0,
          "loop": false
        },
        "hit": {
          "prefix": "hit",
          "count": 3,
          "fps": 12.0,
          "loop": false
        },
        "death": {
          "prefix": "death",
          "count": 4,
          "fps": 10.0,
          "loop": false
        }
      },
      "offset": [
        2.0,
        -72.0
      ],
      "source_idle_bounds": [
        136,
        46,
        308,
        200
      ],
      "body_height": 76
    },
    "elite_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/elitemonster/imp/frames",
      "target_height": 159.71343,
      "animations": {
        "idle": {
          "prefix": "idle",
          "count": 4,
          "fps": 6.0,
          "loop": true
        },
        "move": {
          "prefix": "move",
          "count": 6,
          "fps": 10.0,
          "loop": true
        },
        "attack": {
          "prefix": "attack",
          "count": 6,
          "fps": 14.0,
          "loop": false
        },
        "hit": {
          "prefix": "hit",
          "count": 3,
          "fps": 12.0,
          "loop": false
        },
        "death": {
          "prefix": "death",
          "count": 4,
          "fps": 10.0,
          "loop": false
        }
      },
      "offset": [
        -1.5,
        -93.0
      ],
      "source_idle_bounds": [
        107,
        87,
        248,
        221
      ],
      "body_height": 83.60000000000001
    },
    "hero_survival_after": 300.0
  },
  "mimic": {
    "id": "mimic",
    "name": "미믹",
    "grade": "uncommon",
    "rarity": "uncommon",
    "role": "exploder",
    "family": "mimic",
    "species": "construct",
    "base_cost": 10.0,
    "summon_exp": 10.0,
    "attack_type": "melee",
    "base_stats": {
      "max_hp": 1,
      "attack_damage": 1,
      "move_speed": 88.0,
      "attack_range": 86.0,
      "attack_cooldown": 2.0,
      "exp_reward": 10,
      "projectile_speed": 0.0
    },
    "balance": {
      "health_share": 1.35,
      "damage_share": 0.78,
      "cycle_damage_multiplier": 1.0,
      "note": "소환 후 첫 근접 공격180%. 첫 일격은 개체당 한 번이며 전투 재설정으로 복구되지 않음. 고유 능력·엘리트는 별도 기여로 HP/기본DPS 할인. 실전 승률 미검증."
    },
    "description": "소환 후 첫 근접 공격180%. 첫 일격은 개체당 한 번이며 전투 재설정으로 복구되지 않음.",
    "special_augment_ids": [
      "mimic_special_1",
      "mimic_special_2",
      "mimic_special_3"
    ],
    "elite_skills": [
      {
        "id": "elite_mimic_feast",
        "name": "탐욕의 아가리",
        "description": "지정 대상 위치를0.6초 예고 후 대상1명에 공격력220% 피해, 실제 체력 피해30% 회복. 대상이 반경95 예고 원 밖으로 이동하면 불발.",
        "runtime": "monster",
        "kind": "strike",
        "initial_cooldown": 3.0,
        "cooldown": 16.0,
        "retry_interval": 0.35,
        "windup": 0.6,
        "cast_range": 180.0,
        "radius": 95.0,
        "damage_multiplier": 2.2,
        "lifesteal": 0.3,
        "color": "df9c52"
      }
    ],
    "card_icon_path": "res://assets/art/monsters/mimic/frames/idle_01.png",
    "behavior": {
      "first_multiplier": 1.8
    },
    "normal_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/monsters/mimic/frames",
      "target_height": 191.56463,
      "animations": {
        "idle": {
          "prefix": "idle",
          "count": 4,
          "fps": 6.0,
          "loop": true
        },
        "move": {
          "prefix": "move",
          "count": 6,
          "fps": 10.0,
          "loop": true
        },
        "attack": {
          "prefix": "attack",
          "count": 6,
          "fps": 14.0,
          "loop": false
        },
        "hit": {
          "prefix": "hit",
          "count": 3,
          "fps": 12.0,
          "loop": false
        },
        "death": {
          "prefix": "death",
          "count": 5,
          "fps": 10.0,
          "loop": false
        }
      },
      "offset": [
        2.5,
        -62.0
      ],
      "source_idle_bounds": [
        107,
        75,
        272,
        222
      ],
      "body_height": 88
    },
    "elite_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/elitemonster/mimic/frames",
      "target_height": 224.82581,
      "animations": {
        "idle": {
          "prefix": "idle",
          "count": 4,
          "fps": 6.0,
          "loop": true
        },
        "move": {
          "prefix": "move",
          "count": 6,
          "fps": 10.0,
          "loop": true
        },
        "attack": {
          "prefix": "attack",
          "count": 6,
          "fps": 14.0,
          "loop": false
        },
        "hit": {
          "prefix": "hit",
          "count": 3,
          "fps": 12.0,
          "loop": false
        },
        "death": {
          "prefix": "death",
          "count": 4,
          "fps": 10.0,
          "loop": false
        }
      },
      "offset": [
        0.0,
        -24.0
      ],
      "source_idle_bounds": [
        32,
        29,
        64,
        60
      ],
      "body_height": 96.80000000000001
    },
    "hero_survival_after": 300.0
  },
  "mud_golem": {
    "id": "mud_golem",
    "name": "머드골렘",
    "grade": "rare",
    "rarity": "rare",
    "role": "tank",
    "family": "mud_golem",
    "species": "rock",
    "base_cost": 16.0,
    "summon_exp": 16.0,
    "attack_type": "melee",
    "base_stats": {
      "max_hp": 1,
      "attack_damage": 1,
      "move_speed": 62.0,
      "attack_range": 94.0,
      "attack_cooldown": 2.4,
      "exp_reward": 16,
      "projectile_speed": 0.0
    },
    "balance": {
      "health_share": 0.83,
      "damage_share": 0.75,
      "cycle_damage_multiplier": 1.0,
      "note": "최대체력20% 보호막으로 전선 유지. 진흙 주먹은 0.8초20% 둔화. 고유 능력·엘리트는 별도 기여로 HP/기본DPS 할인. 실전 승률 미검증."
    },
    "description": "최대체력20% 보호막으로 전선 유지. 진흙 주먹은 0.8초20% 둔화.",
    "special_augment_ids": [
      "mud_golem_special_1",
      "mud_golem_special_2",
      "mud_golem_special_3"
    ],
    "elite_skills": [
      {
        "id": "elite_mud_golem_slam",
        "name": "수렁 내려찍기",
        "description": "지정 대상 위치를0.7초 예고 후 대상1명에 공격력150% 피해, 1.2초 45% 둔화. 대상이 반경140 예고 원 밖으로 이동하면 불발.",
        "runtime": "monster",
        "kind": "strike",
        "initial_cooldown": 3.0,
        "cooldown": 18.0,
        "retry_interval": 0.35,
        "windup": 0.7,
        "cast_range": 210.0,
        "radius": 140.0,
        "damage_multiplier": 1.5,
        "slow_multiplier": 0.55,
        "slow_duration": 1.2,
        "color": "a7a56a"
      },
      {
        "id": "elite_mud_golem_ward",
        "name": "진흙 재성형",
        "description": "자신의 보호막을 최대체력25%까지 보충. 기존 잔량과 중첩하지 않음.",
        "runtime": "monster",
        "kind": "self_ward",
        "initial_cooldown": 3.0,
        "cooldown": 22.0,
        "retry_interval": 0.35,
        "shield_ratio": 0.25
      }
    ],
    "card_icon_path": "res://assets/art/monsters/mud_golem/frames/idle_01.png",
    "behavior": {
      "shield_ratio": 0.2,
      "slow_multiplier": 0.8,
      "slow_duration": 0.8
    },
    "normal_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/monsters/mud_golem/frames",
      "target_height": 271.05882,
      "animations": {
        "idle": {
          "prefix": "idle",
          "count": 4,
          "fps": 6.0,
          "loop": true
        },
        "move": {
          "prefix": "move",
          "count": 6,
          "fps": 10.0,
          "loop": true
        },
        "attack": {
          "prefix": "attack",
          "count": 5,
          "fps": 14.0,
          "loop": false,
          "files": [
            "attack_01.png",
            "attack_02.png",
            "attack_03.png",
            "attack_04.png",
            "attack_06.png"
          ]
        },
        "hit": {
          "prefix": "hit",
          "count": 3,
          "fps": 12.0,
          "loop": false
        },
        "death": {
          "prefix": "death",
          "count": 4,
          "fps": 10.0,
          "loop": false
        }
      },
      "offset": [
        -0.5,
        -158.0
      ],
      "source_idle_bounds": [
        151,
        180,
        362,
        350
      ],
      "body_height": 120
    },
    "elite_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/elitemonster/mud-golem/frames",
      "target_height": 278.50549,
      "animations": {
        "idle": {
          "prefix": "idle",
          "count": 4,
          "fps": 6.0,
          "loop": true
        },
        "move": {
          "prefix": "move",
          "count": 6,
          "fps": 10.0,
          "loop": true
        },
        "attack": {
          "prefix": "attack",
          "count": 6,
          "fps": 14.0,
          "loop": false
        },
        "hit": {
          "prefix": "hit",
          "count": 3,
          "fps": 12.0,
          "loop": false
        },
        "death": {
          "prefix": "death",
          "count": 4,
          "fps": 10.0,
          "loop": false
        }
      },
      "offset": [
        -1.0,
        -159.0
      ],
      "source_idle_bounds": [
        148,
        169,
        366,
        351
      ],
      "body_height": 132.0
    },
    "hero_survival_after": 300.0
  },
  "satyr_rogue": {
    "id": "satyr_rogue",
    "name": "사티로스 도적",
    "grade": "uncommon",
    "rarity": "uncommon",
    "role": "exploder",
    "family": "satyr_rogue",
    "species": "humanoid",
    "base_cost": 9.0,
    "summon_exp": 9.0,
    "attack_type": "melee",
    "base_stats": {
      "max_hp": 1,
      "attack_damage": 1,
      "move_speed": 151.0,
      "attack_range": 78.0,
      "attack_cooldown": 1.2,
      "exp_reward": 9,
      "projectile_speed": 0.0
    },
    "balance": {
      "health_share": 1.05,
      "damage_share": 0.85,
      "cycle_damage_multiplier": 1.0,
      "note": "은신 대신 추격·마무리에 특화. 대상 체력40% 이하에 기본공격135%. 고유 능력·엘리트는 별도 기여로 HP/기본DPS 할인. 실전 승률 미검증."
    },
    "description": "은신 대신 추격·마무리에 특화. 대상 체력40% 이하에 기본공격135%.",
    "special_augment_ids": [
      "satyr_rogue_special_1",
      "satyr_rogue_special_2",
      "satyr_rogue_special_3"
    ],
    "elite_skills": [
      {
        "id": "elite_satyr_rogue_hunt",
        "name": "사냥꾼의 낙인",
        "description": "지정 대상 위치를0.45초 예고 후 대상1명에 공격력190% 피해, 시전 후3초 이속40% 증가. 대상이 반경90 예고 원 밖으로 이동하면 불발.",
        "runtime": "monster",
        "kind": "strike",
        "initial_cooldown": 3.0,
        "cooldown": 14.0,
        "retry_interval": 0.35,
        "windup": 0.45,
        "cast_range": 180.0,
        "radius": 90.0,
        "damage_multiplier": 1.9,
        "speed_multiplier": 1.4,
        "speed_duration": 3.0,
        "color": "df6666"
      }
    ],
    "card_icon_path": "res://assets/art/monsters/satyr_rogue/frames/idle_01.png",
    "behavior": {
      "execute_threshold": 0.4,
      "execute_multiplier": 1.35
    },
    "normal_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/monsters/satyr_rogue/frames",
      "target_height": 143.28358,
      "animations": {
        "idle": {
          "prefix": "idle",
          "count": 4,
          "fps": 6.0,
          "loop": true
        },
        "move": {
          "prefix": "move",
          "count": 6,
          "fps": 10.0,
          "loop": true
        },
        "attack": {
          "prefix": "attack",
          "count": 6,
          "fps": 14.0,
          "loop": false
        },
        "hit": {
          "prefix": "hit",
          "count": 3,
          "fps": 12.0,
          "loop": false
        },
        "death": {
          "prefix": "death",
          "count": 4,
          "fps": 10.0,
          "loop": false
        }
      },
      "offset": [
        23.0,
        -73.0
      ],
      "source_idle_bounds": [
        144,
        32,
        322,
        233
      ],
      "body_height": 90
    },
    "elite_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/elitemonster/satyr_rouge/frames",
      "target_height": 189.13433,
      "animations": {
        "idle": {
          "prefix": "idle",
          "count": 4,
          "fps": 6.0,
          "loop": true
        },
        "move": {
          "prefix": "move",
          "count": 6,
          "fps": 10.0,
          "loop": true
        },
        "attack": {
          "prefix": "attack",
          "count": 6,
          "fps": 14.0,
          "loop": false
        },
        "hit": {
          "prefix": "hit",
          "count": 3,
          "fps": 12.0,
          "loop": false
        },
        "death": {
          "prefix": "death",
          "count": 4,
          "fps": 10.0,
          "loop": false
        }
      },
      "offset": [
        15.5,
        -92.0
      ],
      "source_idle_bounds": [
        102,
        86,
        219,
        220
      ],
      "body_height": 99.00000000000001
    },
    "hero_survival_after": 300.0
  },
  "satyr_shaman": {
    "id": "satyr_shaman",
    "name": "사티로스 주술사",
    "grade": "rare",
    "rarity": "rare",
    "role": "controller",
    "family": "satyr_shaman",
    "species": "humanoid",
    "base_cost": 14.0,
    "summon_exp": 14.0,
    "attack_type": "ranged",
    "base_stats": {
      "max_hp": 1,
      "attack_damage": 1,
      "move_speed": 82.0,
      "attack_range": 330.0,
      "attack_cooldown": 1.8,
      "exp_reward": 14,
      "projectile_speed": 245.0
    },
    "balance": {
      "health_share": 0.9,
      "damage_share": 0.72,
      "cycle_damage_multiplier": 1.0,
      "note": "주술탄 적중 시 1초15% 둔화. 희귀 엘리트의 둔화 표식·군단 보호막으로 전선 지원. 고유 능력·엘리트는 별도 기여로 HP/기본DPS 할인. 실전 승률 미검증."
    },
    "description": "주술탄 적중 시 1초15% 둔화. 희귀 엘리트의 둔화 표식·군단 보호막으로 전선 지원.",
    "special_augment_ids": [
      "satyr_shaman_special_1",
      "satyr_shaman_special_2",
      "satyr_shaman_special_3"
    ],
    "elite_skills": [
      {
        "id": "elite_satyr_shaman_hex",
        "name": "가시덩굴 표식",
        "description": "지정 대상 위치를0.65초 예고 후 대상1명에 공격력80% 피해, 1.4초 45% 둔화. 대상이 반경135 예고 원 밖으로 이동하면 불발.",
        "runtime": "monster",
        "kind": "strike",
        "initial_cooldown": 3.0,
        "cooldown": 17.0,
        "retry_interval": 0.35,
        "windup": 0.65,
        "cast_range": 400.0,
        "radius": 135.0,
        "damage_multiplier": 0.8,
        "slow_multiplier": 0.55,
        "slow_duration": 1.4,
        "color": "bc87e8"
      },
      {
        "id": "elite_satyr_shaman_ward",
        "name": "숲의 결계",
        "description": "주변250 내 자신을 제외한 아군 최대3명에 각 최대체력12% 보호막. 중첩 대신 높은 잔량으로 갱신.",
        "runtime": "monster",
        "kind": "ally_ward",
        "initial_cooldown": 3.0,
        "cooldown": 20.0,
        "retry_interval": 0.35,
        "ward_radius": 250.0,
        "ward_count": 3,
        "ward_ratio": 0.12
      }
    ],
    "card_icon_path": "res://assets/art/monsters/satyr_shaman/frames/idle_01.png",
    "behavior": {
      "projectile": true,
      "projectile_speed": 245.0,
      "color": "b875ef",
      "slow_multiplier": 0.85,
      "slow_duration": 1.0
    },
    "normal_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/monsters/satyr_shaman/frames",
      "target_height": 147.2,
      "animations": {
        "idle": {
          "prefix": "idle",
          "count": 4,
          "fps": 6.0,
          "loop": true
        },
        "move": {
          "prefix": "move",
          "count": 6,
          "fps": 10.0,
          "loop": true
        },
        "attack": {
          "prefix": "attack",
          "count": 6,
          "fps": 14.0,
          "loop": false
        },
        "hit": {
          "prefix": "hit",
          "count": 2,
          "fps": 12.0,
          "loop": false
        },
        "death": {
          "prefix": "death",
          "count": 4,
          "fps": 10.0,
          "loop": false
        }
      },
      "offset": [
        2.5,
        -94.0
      ],
      "source_idle_bounds": [
        96,
        62,
        251,
        222
      ],
      "body_height": 92
    },
    "elite_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/elitemonster/satyr_shaman/frames",
      "target_height": 147.87215,
      "animations": {
        "idle": {
          "prefix": "idle",
          "count": 4,
          "fps": 6.0,
          "loop": true
        },
        "move": {
          "prefix": "move",
          "count": 6,
          "fps": 10.0,
          "loop": true
        },
        "attack": {
          "prefix": "attack",
          "count": 6,
          "fps": 14.0,
          "loop": false
        },
        "hit": {
          "prefix": "hit",
          "count": 2,
          "fps": 12.0,
          "loop": false
        },
        "death": {
          "prefix": "death",
          "count": 4,
          "fps": 10.0,
          "loop": false
        }
      },
      "offset": [
        -3.0,
        -112.0
      ],
      "source_idle_bounds": [
        142,
        53,
        376,
        272
      ],
      "body_height": 101.2
    },
    "hero_survival_after": 300.0
  },
  "skeleton_shield": {
    "id": "skeleton_shield",
    "name": "해골방패병",
    "grade": "common",
    "rarity": "common",
    "role": "tank",
    "family": "skeleton_shield",
    "species": "undead",
    "base_cost": 7.0,
    "summon_exp": 7.0,
    "attack_type": "melee",
    "base_stats": {
      "max_hp": 1,
      "attack_damage": 1,
      "move_speed": 73.0,
      "attack_range": 76.0,
      "attack_cooldown": 1.8,
      "exp_reward": 7,
      "projectile_speed": 0.0
    },
    "balance": {
      "health_share": 0.78,
      "damage_share": 0.9,
      "cycle_damage_multiplier": 1.0,
      "note": "소환 시 최대체력30% 보호막. 낮은 비용으로 원거리 몬스터 앞을 지키는 방패 전선. 고유 능력·엘리트는 별도 기여로 HP/기본DPS 할인. 실전 승률 미검증."
    },
    "description": "소환 시 최대체력30% 보호막. 낮은 비용으로 원거리 몬스터 앞을 지키는 방패 전선.",
    "special_augment_ids": [
      "skeleton_shield_special_1",
      "skeleton_shield_special_2",
      "skeleton_shield_special_3"
    ],
    "elite_skills": [
      {
        "id": "elite_skeleton_shield_reform",
        "name": "방패 재정비",
        "description": "자신의 보호막을 최대체력30%까지 보충. 기존 잔량과 중첩하지 않음.",
        "runtime": "monster",
        "kind": "self_ward",
        "initial_cooldown": 3.0,
        "cooldown": 16.0,
        "retry_interval": 0.35,
        "shield_ratio": 0.3
      }
    ],
    "card_icon_path": "res://assets/art/monsters/skeleton_shield/frames/idle_01.png",
    "behavior": {
      "shield_ratio": 0.3
    },
    "normal_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/monsters/skeleton_shield/frames",
      "target_height": 173.91304,
      "animations": {
        "idle": {
          "prefix": "idle",
          "count": 4,
          "fps": 6.0,
          "loop": true
        },
        "move": {
          "prefix": "move",
          "count": 6,
          "fps": 10.0,
          "loop": true
        },
        "attack": {
          "prefix": "attack",
          "count": 6,
          "fps": 14.0,
          "loop": false
        },
        "hit": {
          "prefix": "hit",
          "count": 3,
          "fps": 12.0,
          "loop": false
        },
        "death": {
          "prefix": "death",
          "count": 4,
          "fps": 10.0,
          "loop": false
        }
      },
      "offset": [
        7.0,
        -107.0
      ],
      "source_idle_bounds": [
        88,
        83,
        282,
        267
      ],
      "body_height": 100
    },
    "elite_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/elitemonster/skeleton_shield/frames",
      "target_height": 176.0,
      "animations": {
        "idle": {
          "prefix": "idle",
          "count": 4,
          "fps": 6.0,
          "loop": true
        },
        "move": {
          "prefix": "move",
          "count": 6,
          "fps": 10.0,
          "loop": true
        },
        "attack": {
          "prefix": "attack",
          "count": 6,
          "fps": 14.0,
          "loop": false
        },
        "hit": {
          "prefix": "hit",
          "count": 3,
          "fps": 12.0,
          "loop": false
        },
        "death": {
          "prefix": "death",
          "count": 4,
          "fps": 10.0,
          "loop": false
        }
      },
      "offset": [
        1.0,
        -106.0
      ],
      "source_idle_bounds": [
        116,
        66,
        330,
        266
      ],
      "body_height": 110.00000000000001
    },
    "hero_survival_after": 300.0
  },
  "toxic_slime": {
    "id": "toxic_slime",
    "name": "맹독슬라임",
    "grade": "uncommon",
    "rarity": "uncommon",
    "role": "controller",
    "family": "toxic_slime",
    "species": "liquid",
    "base_cost": 8.0,
    "summon_exp": 8.0,
    "attack_type": "melee",
    "base_stats": {
      "max_hp": 1,
      "attack_damage": 1,
      "move_speed": 85.0,
      "attack_range": 82.0,
      "attack_cooldown": 1.6,
      "exp_reward": 8,
      "projectile_speed": 0.0
    },
    "balance": {
      "health_share": 0.95,
      "damage_share": 0.68,
      "cycle_damage_multiplier": 1.0,
      "note": "접촉 시 현재체력1.2%를 3초간 나눠 독 피해, 0.9초15% 둔화. 독은 기존 상태를 갱신하며 개체별 중첩하지 않음. 고유 능력·엘리트는 별도 기여로 HP/기본DPS 할인. 실전 승률 미검증."
    },
    "description": "접촉 시 현재체력1.2%를 3초간 나눠 독 피해, 0.9초15% 둔화. 독은 기존 상태를 갱신하며 개체별 중첩하지 않음.",
    "special_augment_ids": [
      "toxic_slime_special_1",
      "toxic_slime_special_2",
      "toxic_slime_special_3"
    ],
    "elite_skills": [
      {
        "id": "elite_toxic_slime_burst",
        "name": "맹독 분출",
        "description": "지정 대상 위치를0.6초 예고 후 대상1명에 공격력80% 피해, 1.2초 35% 둔화, 현재체력2% 독(3초 총합). 대상이 반경130 예고 원 밖으로 이동하면 불발.",
        "runtime": "monster",
        "kind": "strike",
        "initial_cooldown": 3.0,
        "cooldown": 16.0,
        "retry_interval": 0.35,
        "windup": 0.6,
        "cast_range": 190.0,
        "radius": 130.0,
        "damage_multiplier": 0.8,
        "poison_ratio": 0.02,
        "poison_duration": 3.0,
        "slow_multiplier": 0.65,
        "slow_duration": 1.2,
        "color": "90d94b"
      }
    ],
    "card_icon_path": "res://assets/art/monsters/toxic_slime/frames/idle_01.png",
    "behavior": {
      "poison_ratio": 0.012,
      "poison_duration": 3.0,
      "slow_multiplier": 0.85,
      "slow_duration": 0.9
    },
    "normal_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/monsters/toxic_slime/frames",
      "target_height": 157.53846,
      "animations": {
        "idle": {
          "prefix": "idle",
          "count": 4,
          "fps": 6.0,
          "loop": true
        },
        "move": {
          "prefix": "move",
          "count": 6,
          "fps": 10.0,
          "loop": true
        },
        "attack": {
          "prefix": "attack",
          "count": 5,
          "fps": 14.0,
          "loop": false
        },
        "hit": {
          "prefix": "hit",
          "count": 3,
          "fps": 12.0,
          "loop": false
        },
        "death": {
          "prefix": "death",
          "count": 4,
          "fps": 10.0,
          "loop": false
        }
      },
      "offset": [
        -3.0,
        -50.0
      ],
      "source_idle_bounds": [
        307,
        61,
        467,
        178
      ],
      "body_height": 72
    },
    "elite_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/elitemonster/toxic_slime/frames",
      "target_height": 137.92653,
      "animations": {
        "idle": {
          "prefix": "idle",
          "count": 4,
          "fps": 6.0,
          "loop": true
        },
        "move": {
          "prefix": "move",
          "count": 6,
          "fps": 10.0,
          "loop": true
        },
        "attack": {
          "prefix": "attack",
          "count": 5,
          "fps": 14.0,
          "loop": false
        },
        "hit": {
          "prefix": "hit",
          "count": 3,
          "fps": 12.0,
          "loop": false
        },
        "death": {
          "prefix": "death",
          "count": 4,
          "fps": 10.0,
          "loop": false
        }
      },
      "offset": [
        -4.5,
        -53.0
      ],
      "source_idle_bounds": [
        357,
        34,
        548,
        181
      ],
      "body_height": 79.2
    },
    "hero_survival_after": 300.0
  }
}
const AUGMENTS := [
  {
    "id": "harpy_special_1",
    "monster_id": "harpy",
    "name": "바람깃",
    "description": "이동속도15% 증가.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "harpy_special_1",
    "effect_values": {
      "runtime_stat_multipliers": {
        "speed_multiplier": 1.15
      }
    }
  },
  {
    "id": "harpy_special_2",
    "monster_id": "harpy",
    "name": "갈고리 발톱",
    "description": "매 3번째 기본공격 피해150%→200%.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "harpy_special_2",
    "effect_values": {
      "behavior": {
        "third_bonus": 1.0
      }
    }
  },
  {
    "id": "harpy_special_3",
    "monster_id": "harpy",
    "name": "포식자의 깃",
    "description": "근접 공격으로 실제 감소시킨 체력의15% 회복.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "harpy_special_3",
    "effect_values": {
      "behavior": {
        "lifesteal": 0.15
      }
    }
  },
  {
    "id": "imp_special_1",
    "monster_id": "imp",
    "name": "꺼지지 않는 불씨",
    "description": "화염탄 적중 시 공격력25%를 2초간 화상 피해.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "imp_special_1",
    "effect_values": {
      "behavior": {
        "burn_ratio": 0.25,
        "burn_duration": 2.0
      }
    }
  },
  {
    "id": "imp_special_2",
    "monster_id": "imp",
    "name": "불꽃 도약",
    "description": "사거리350→460, 투사체속도310→435.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "imp_special_2",
    "effect_values": {
      "stat_overrides": {
        "attack_range": 460.0,
        "projectile_speed": 435.0
      }
    }
  },
  {
    "id": "imp_special_3",
    "monster_id": "imp",
    "name": "지옥불 심장",
    "description": "공격력25% 증가.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "imp_special_3",
    "effect_values": {
      "stat_multipliers": {
        "damage": 1.25
      }
    }
  },
  {
    "id": "mimic_special_1",
    "monster_id": "mimic",
    "name": "욕심 많은 송곳니",
    "description": "개체당 첫 근접공격180%→280%.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "mimic_special_1",
    "effect_values": {
      "behavior": {
        "first_multiplier": 2.8
      }
    }
  },
  {
    "id": "mimic_special_2",
    "monster_id": "mimic",
    "name": "삼켜 버린 보물",
    "description": "근접 공격으로 실제 감소시킨 체력의20% 회복.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "mimic_special_2",
    "effect_values": {
      "behavior": {
        "lifesteal": 0.2
      }
    }
  },
  {
    "id": "mimic_special_3",
    "monster_id": "mimic",
    "name": "철갑 금고",
    "description": "최대체력35% 증가, 이동속도10% 감소.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "mimic_special_3",
    "effect_values": {
      "stat_multipliers": {
        "hp": 1.35
      },
      "runtime_stat_multipliers": {
        "speed_multiplier": 0.9
      }
    }
  },
  {
    "id": "mud_golem_special_1",
    "monster_id": "mud_golem",
    "name": "두꺼운 진흙갑옷",
    "description": "최초 보호막 최대체력20%→35%. 기존 개체에는 증가분만1회 지급.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "mud_golem_special_1",
    "effect_values": {
      "behavior": {
        "shield_ratio": 0.35
      }
    }
  },
  {
    "id": "mud_golem_special_2",
    "monster_id": "mud_golem",
    "name": "발목 잡는 수렁",
    "description": "기본공격 둔화20%→35%, 지속0.8초→1.2초.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "mud_golem_special_2",
    "effect_values": {
      "behavior": {
        "slow_multiplier": 0.65,
        "slow_duration": 1.2
      }
    }
  },
  {
    "id": "mud_golem_special_3",
    "monster_id": "mud_golem",
    "name": "굳어 버린 점토",
    "description": "최대체력25% 증가.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "mud_golem_special_3",
    "effect_values": {
      "stat_multipliers": {
        "hp": 1.25
      }
    }
  },
  {
    "id": "satyr_rogue_special_1",
    "monster_id": "satyr_rogue",
    "name": "사냥감의 빈틈",
    "description": "대상 체력40% 이하 기본공격135%→165%.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "satyr_rogue_special_1",
    "effect_values": {
      "behavior": {
        "execute_multiplier": 1.65
      }
    }
  },
  {
    "id": "satyr_rogue_special_2",
    "monster_id": "satyr_rogue",
    "name": "피를 쫓는 칼날",
    "description": "근접 공격으로 실제 감소시킨 체력의15% 회복.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "satyr_rogue_special_2",
    "effect_values": {
      "behavior": {
        "lifesteal": 0.15
      }
    }
  },
  {
    "id": "satyr_rogue_special_3",
    "monster_id": "satyr_rogue",
    "name": "숲길 추격자",
    "description": "이동속도20% 증가.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "satyr_rogue_special_3",
    "effect_values": {
      "runtime_stat_multipliers": {
        "speed_multiplier": 1.2
      }
    }
  },
  {
    "id": "satyr_shaman_special_1",
    "monster_id": "satyr_shaman",
    "name": "엉킨 가지의 저주",
    "description": "주술탄 둔화15%→30%, 지속1초→1.5초.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "satyr_shaman_special_1",
    "effect_values": {
      "behavior": {
        "slow_multiplier": 0.7,
        "slow_duration": 1.5
      }
    }
  },
  {
    "id": "satyr_shaman_special_2",
    "monster_id": "satyr_shaman",
    "name": "숲의 수호 부적",
    "description": "매 4번째 기본공격 시 주변220 내 아군 최대3명에 각 최대체력8% 보호막. 중첩 대신 높은 값으로 갱신.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "satyr_shaman_special_2",
    "effect_values": {
      "behavior": {
        "ward_every": 4,
        "ward_ratio": 0.08,
        "ward_radius": 220.0,
        "ward_count": 3
      }
    }
  },
  {
    "id": "satyr_shaman_special_3",
    "monster_id": "satyr_shaman",
    "name": "재촉하는 주문",
    "description": "공격 간격20% 감소.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "satyr_shaman_special_3",
    "effect_values": {
      "stat_multipliers": {
        "attack_cooldown": 0.8
      }
    }
  },
  {
    "id": "skeleton_shield_special_1",
    "monster_id": "skeleton_shield",
    "name": "겹겹의 방패",
    "description": "최초 보호막 최대체력30%→50%. 기존 개체에는 증가분만1회 지급.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "skeleton_shield_special_1",
    "effect_values": {
      "behavior": {
        "shield_ratio": 0.5
      }
    }
  },
  {
    "id": "skeleton_shield_special_2",
    "monster_id": "skeleton_shield",
    "name": "질긴 뼈대",
    "description": "최대체력25% 증가.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "skeleton_shield_special_2",
    "effect_values": {
      "stat_multipliers": {
        "hp": 1.25
      }
    }
  },
  {
    "id": "skeleton_shield_special_3",
    "monster_id": "skeleton_shield",
    "name": "방패 밀어치기",
    "description": "공격력30% 증가, 공격 간격10% 감소.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "skeleton_shield_special_3",
    "effect_values": {
      "stat_multipliers": {
        "damage": 1.3,
        "attack_cooldown": 0.9
      }
    }
  },
  {
    "id": "toxic_slime_special_1",
    "monster_id": "toxic_slime",
    "name": "농축된 맹독",
    "description": "기본 독 피해 현재체력1.2%→2%(3초 총합).",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "toxic_slime_special_1",
    "effect_values": {
      "behavior": {
        "poison_ratio": 0.02
      }
    }
  },
  {
    "id": "toxic_slime_special_2",
    "monster_id": "toxic_slime",
    "name": "끈적한 독점액",
    "description": "기본공격 둔화15%→30%.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "toxic_slime_special_2",
    "effect_values": {
      "behavior": {
        "slow_multiplier": 0.7
      }
    }
  },
  {
    "id": "toxic_slime_special_3",
    "monster_id": "toxic_slime",
    "name": "부푼 독낭",
    "description": "최대체력35% 증가.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "toxic_slime_special_3",
    "effect_values": {
      "stat_multipliers": {
        "hp": 1.35
      }
    }
  }
]
