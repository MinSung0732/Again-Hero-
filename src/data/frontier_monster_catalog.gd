extends RefCounted
## Declarative species, visuals, named augments and generic elite payloads.
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
      "target_height": 192.080842,
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
      "body_height": 95.04,
      "hero_height_ratio": 0.88,
      "ground_y": 30.0,
      "source_animation_top": 113
    },
    "elite_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/elitemonster/harpy/frames",
      "target_height": 191.900485,
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
      "body_height": 106.4448,
      "hero_height_ratio": 0.88,
      "ground_y": 30.0,
      "source_animation_top": 99
    },
    "hero_survival_after": 300.0,
    "ground_shadow": {
      "offset_y": 30.0,
      "opacity": 0.42
    }
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
      "color": "ff8844",
      "projectile_art": "imp"
    },
    "normal_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/monsters/imp/frames",
      "target_height": 143.625974,
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
      "body_height": 86.4,
      "hero_height_ratio": 0.8,
      "ground_y": 30.0,
      "source_animation_top": 36
    },
    "elite_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/elitemonster/imp/frames",
      "target_height": 184.870209,
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
      "body_height": 96.768,
      "hero_height_ratio": 0.8,
      "ground_y": 30.0,
      "source_animation_top": 82
    },
    "hero_survival_after": 300.0,
    "ground_shadow": {
      "offset_y": 30.0,
      "opacity": 0.42
    }
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
      "target_height": 211.591837,
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
      "body_height": 97.2,
      "hero_height_ratio": 0.9,
      "ground_y": 30.0,
      "source_animation_top": 36
    },
    "elite_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/elitemonster/mimic/frames",
      "target_height": 252.845419,
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
      "body_height": 108.864,
      "hero_height_ratio": 0.9,
      "ground_y": 30.0,
      "source_animation_top": 25
    },
    "hero_survival_after": 300.0,
    "ground_shadow": {
      "offset_y": 30.0,
      "opacity": 0.42
    }
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
      "target_height": 292.743529,
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
      "body_height": 129.6,
      "hero_height_ratio": 1.2,
      "ground_y": 30.0,
      "source_animation_top": 122
    },
    "elite_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/elitemonster/mud-golem/frames",
      "target_height": 306.254769,
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
      "body_height": 145.152,
      "hero_height_ratio": 1.2,
      "ground_y": 30.0,
      "source_animation_top": 110
    },
    "hero_survival_after": 300.0,
    "ground_shadow": {
      "offset_y": 30.0,
      "opacity": 0.42
    }
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
      "target_height": 163.343284,
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
      "body_height": 102.6,
      "hero_height_ratio": 0.95,
      "ground_y": 30.0,
      "source_animation_top": 32
    },
    "elite_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/elitemonster/satyr_rouge/frames",
      "target_height": 219.533373,
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
      "body_height": 114.912,
      "hero_height_ratio": 0.95,
      "ground_y": 30.0,
      "source_animation_top": 86
    },
    "hero_survival_after": 300.0,
    "ground_shadow": {
      "offset_y": 30.0,
      "opacity": 0.42
    }
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
      "slow_duration": 1.0,
      "projectile_art": "satyr_shaman"
    },
    "normal_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/monsters/satyr_shaman/frames",
      "target_height": 172.8,
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
      "body_height": 108.0,
      "hero_height_ratio": 1.0,
      "ground_y": 30.0,
      "source_animation_top": 42
    },
    "elite_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/elitemonster/satyr_shaman/frames",
      "target_height": 176.745205,
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
      "body_height": 120.96,
      "hero_height_ratio": 1.0,
      "ground_y": 30.0,
      "source_animation_top": 38
    },
    "hero_survival_after": 300.0,
    "ground_shadow": {
      "offset_y": 30.0,
      "opacity": 0.42
    }
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
      "target_height": 197.217391,
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
      "body_height": 113.4,
      "hero_height_ratio": 1.05,
      "ground_y": 30.0,
      "source_animation_top": 36
    },
    "elite_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/elitemonster/skeleton_shield/frames",
      "target_height": 203.2128,
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
      "body_height": 127.008,
      "hero_height_ratio": 1.05,
      "ground_y": 30.0,
      "source_animation_top": 32
    },
    "hero_survival_after": 300.0,
    "ground_shadow": {
      "offset_y": 30.0,
      "opacity": 0.42
    }
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
      "art_faces_left": true,
      "asset_dir": "res://assets/art/monsters/toxic_slime/frames",
      "target_height": 170.141538,
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
      "body_height": 77.76,
      "hero_height_ratio": 0.72,
      "ground_y": 30.0,
      "source_animation_top": 32
    },
    "elite_visual": {
      "mode": "frames",
      "art_faces_left": true,
      "asset_dir": "res://assets/art/elitemonster/toxic_slime/frames",
      "target_height": 151.669029,
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
      "body_height": 87.0912,
      "hero_height_ratio": 0.72,
      "ground_y": 30.0,
      "source_animation_top": 32
    },
    "hero_survival_after": 300.0,
    "ground_shadow": {
      "offset_y": 30.0,
      "opacity": 0.42
    }
  },
  "cave_ant": {
    "id": "cave_ant",
    "name": "동굴개미",
    "grade": "common",
    "rarity": "common",
    "role": "swarm",
    "family": "cave_ant",
    "species": "beast",
    "base_cost": 3.0,
    "summon_exp": 3.0,
    "attack_type": "melee",
    "base_stats": {
      "max_hp": 1,
      "attack_damage": 1,
      "move_speed": 124.0,
      "attack_range": 65.0,
      "attack_cooldown": 0.85,
      "exp_reward": 3,
      "projectile_speed": 0.0
    },
    "balance": {
      "health_share": 0.9,
      "damage_share": 0.9,
      "cycle_damage_multiplier": 1.0833333333333333,
      "note": "빠르게 접근하는 저비용 물량. 매3번째 공격은125% 피해와1.2초 이속20% 증가. 고유능력 기여를 HP/직접DPS 할인에 반영. 엘리트·증강은 별도 기여, 실전 승률 미검증."
    },
    "description": "빠르게 접근하는 저비용 물량. 매3번째 공격은125% 피해와1.2초 이속20% 증가.",
    "special_augment_ids": [
      "cave_ant_special_1",
      "cave_ant_special_2",
      "cave_ant_special_3"
    ],
    "elite_skills": [
      {
        "id": "elite_cave_ant",
        "name": "큰턱 급습",
        "description": "0.4초간 대상 위치를 예고한 뒤 대상1명에 공격력160% 피해. 반경85.0px 밖으로 피하면 불발. 시전 종료 후1.5초간 이속30% 증가.",
        "runtime": "monster",
        "kind": "strike",
        "initial_cooldown": 3.0,
        "cooldown": 13.0,
        "retry_interval": 0.35,
        "windup": 0.4,
        "cast_range": 200.0,
        "radius": 85.0,
        "damage_multiplier": 1.6,
        "color": "d6ad72",
        "speed_multiplier": 1.3,
        "speed_duration": 1.5
      }
    ],
    "card_icon_path": "res://assets/art/monsters/cave_ant/frames/idle_01.png",
    "behavior": {
      "third_bonus": 0.25,
      "third_speed": 1.2,
      "speed_duration": 1.2
    },
    "hero_survival_after": 300.0,
    "ground_shadow": {
      "offset_y": 30.0,
      "opacity": 0.42
    },
    "normal_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/monsters/cave_ant/frames",
      "target_height": 100.0,
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
        -18.0,
        -78.0
      ],
      "source_idle_bounds": [
        67,
        42,
        259,
        168
      ],
      "body_height": 70,
      "hero_height_ratio": 0.6481481481481481,
      "ground_y": 30.0,
      "source_animation_top": 12
    },
    "elite_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/elitemonster/cave_ant/frames",
      "target_height": 109.60384615384615,
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
        -17.0,
        -76.5
      ],
      "source_idle_bounds": [
        65,
        35,
        267,
        165
      ],
      "body_height": 80.5,
      "hero_height_ratio": 0.7453703703703703,
      "ground_y": 30.0,
      "source_animation_top": 12
    }
  },
  "thorn_hedgehog": {
    "id": "thorn_hedgehog",
    "name": "밤가시고슴도치",
    "grade": "common",
    "rarity": "common",
    "role": "ranged",
    "family": "thorn_hedgehog",
    "species": "beast",
    "base_cost": 5.0,
    "summon_exp": 5.0,
    "attack_type": "ranged",
    "base_stats": {
      "max_hp": 1,
      "attack_damage": 1,
      "move_speed": 90.0,
      "attack_range": 260.0,
      "attack_cooldown": 1.4,
      "exp_reward": 5,
      "projectile_speed": 350.0
    },
    "balance": {
      "health_share": 0.95,
      "damage_share": 0.9,
      "cycle_damage_multiplier": 1.1666666666666667,
      "note": "회피 가능한 가시를 발사. 매3번째 가시는150% 피해. 짧은 사거리가 약점. 고유능력 기여를 HP/직접DPS 할인에 반영. 엘리트·증강은 별도 기여, 실전 승률 미검증."
    },
    "description": "회피 가능한 가시를 발사. 매3번째 가시는150% 피해. 짧은 사거리가 약점.",
    "special_augment_ids": [
      "thorn_hedgehog_special_1",
      "thorn_hedgehog_special_2",
      "thorn_hedgehog_special_3"
    ],
    "elite_skills": [
      {
        "id": "elite_thorn_hedgehog",
        "name": "밤가시 부채",
        "description": "전방3방향으로 각 공격력65% 가시탄. 탄마다 회피 가능.",
        "runtime": "monster",
        "kind": "fan",
        "initial_cooldown": 3.0,
        "cooldown": 14.0,
        "retry_interval": 0.35,
        "cast_range": 340.0,
        "damage_multiplier": 0.65,
        "spread": 0.2,
        "color": "b89b47"
      }
    ],
    "card_icon_path": "res://assets/art/monsters/thorn_hedgehog/frames/idle_01.png",
    "behavior": {
      "projectile": true,
      "third_bonus": 0.5,
      "color": "a4be57",
      "projectile_art": "thorn_hedgehog"
    },
    "hero_survival_after": 300.0,
    "ground_shadow": {
      "offset_y": 30.0,
      "opacity": 0.42
    },
    "normal_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/monsters/thorn_hedgehog/frames",
      "target_height": 104.0,
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
        -88.0
      ],
      "source_idle_bounds": [
        50,
        38,
        216,
        188
      ],
      "body_height": 78,
      "hero_height_ratio": 0.7222222222222222,
      "ground_y": 30.0,
      "source_animation_top": 12
    },
    "elite_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/elitemonster/thorn_hedgehog/frames",
      "target_height": 124.15430463576159,
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
        -92.5
      ],
      "source_idle_bounds": [
        45,
        46,
        215,
        197
      ],
      "body_height": 89.69999999999999,
      "hero_height_ratio": 0.8305555555555555,
      "ground_y": 30.0,
      "source_animation_top": 12
    }
  },
  "spore_mushroom": {
    "id": "spore_mushroom",
    "name": "포자버섯",
    "grade": "common",
    "rarity": "common",
    "role": "controller",
    "family": "spore_mushroom",
    "species": "plant",
    "base_cost": 5.0,
    "summon_exp": 5.0,
    "attack_type": "ranged",
    "base_stats": {
      "max_hp": 1,
      "attack_damage": 1,
      "move_speed": 68.0,
      "attack_range": 275.0,
      "attack_cooldown": 1.8,
      "exp_reward": 5,
      "projectile_speed": 250.0
    },
    "balance": {
      "health_share": 0.9,
      "damage_share": 0.65,
      "cycle_damage_multiplier": 1.0,
      "note": "느린 포자탄 적중 시1초간20% 둔화. 낮은 직접 화력으로 아군의 공격 기회를 만든다. 고유능력 기여를 HP/직접DPS 할인에 반영. 엘리트·증강은 별도 기여, 실전 승률 미검증."
    },
    "description": "느린 포자탄 적중 시1초간20% 둔화. 낮은 직접 화력으로 아군의 공격 기회를 만든다.",
    "special_augment_ids": [
      "spore_mushroom_special_1",
      "spore_mushroom_special_2",
      "spore_mushroom_special_3"
    ],
    "elite_skills": [
      {
        "id": "elite_spore_mushroom",
        "name": "만개한 포자",
        "description": "전방3방향으로 각 공격력55% 포자탄. 적중 시1.5초간30% 둔화. 탄마다 회피 가능.",
        "runtime": "monster",
        "kind": "fan",
        "initial_cooldown": 3.0,
        "cooldown": 16.0,
        "retry_interval": 0.35,
        "cast_range": 320.0,
        "damage_multiplier": 0.55,
        "spread": 0.22,
        "slow_multiplier": 0.7,
        "slow_duration": 1.5,
        "color": "bc7cda"
      }
    ],
    "card_icon_path": "res://assets/art/monsters/spore_mushroom/frames/idle_01.png",
    "behavior": {
      "projectile": true,
      "slow_multiplier": 0.8,
      "slow_duration": 1.0,
      "color": "dba598",
      "projectile_art": "spore_mushroom"
    },
    "hero_survival_after": 300.0,
    "ground_shadow": {
      "offset_y": 30.0,
      "opacity": 0.42
    },
    "normal_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/monsters/spore_mushroom/frames",
      "target_height": 107.42857142857143,
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
        -3.5,
        -82.0
      ],
      "source_idle_bounds": [
        72,
        22,
        239,
        176
      ],
      "body_height": 88,
      "hero_height_ratio": 0.8148148148148148,
      "ground_y": 30.0,
      "source_animation_top": 12
    },
    "elite_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/elitemonster/spore_mushroom/frames",
      "target_height": 113.40502512562813,
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
        -3.5,
        -99.5
      ],
      "source_idle_bounds": [
        63,
        12,
        250,
        211
      ],
      "body_height": 101.19999999999999,
      "hero_height_ratio": 0.9370370370370369,
      "ground_y": 30.0,
      "source_animation_top": 12
    }
  },
  "shell_crab": {
    "id": "shell_crab",
    "name": "돌껍질소라게",
    "grade": "common",
    "rarity": "common",
    "role": "tank",
    "family": "shell_crab",
    "species": "beast",
    "base_cost": 6.0,
    "summon_exp": 6.0,
    "attack_type": "melee",
    "base_stats": {
      "max_hp": 1,
      "attack_damage": 1,
      "move_speed": 65.0,
      "attack_range": 72.0,
      "attack_cooldown": 2.0,
      "exp_reward": 6,
      "projectile_speed": 0.0
    },
    "balance": {
      "health_share": 0.74,
      "damage_share": 0.85,
      "cycle_damage_multiplier": 1.0,
      "note": "등장 시 최대체력35% 보호막. 느리지만 전선을 유지하는 저비용 탱커. 보호막은 자동 재생하지 않는다. 고유능력 기여를 HP/직접DPS 할인에 반영. 엘리트·증강은 별도 기여, 실전 승률 미검증."
    },
    "description": "등장 시 최대체력35% 보호막. 느리지만 전선을 유지하는 저비용 탱커. 보호막은 자동 재생하지 않는다.",
    "special_augment_ids": [
      "shell_crab_special_1",
      "shell_crab_special_2",
      "shell_crab_special_3"
    ],
    "elite_skills": [
      {
        "id": "elite_shell_crab",
        "name": "바위집 틀어막기",
        "description": "최대체력55% 보호막을 생성. 남은 보호막과 합산하지 않고 더 큰 값으로 갱신.",
        "runtime": "monster",
        "kind": "self_ward",
        "initial_cooldown": 4.0,
        "cooldown": 18.0,
        "retry_interval": 0.35,
        "shield_ratio": 0.55
      }
    ],
    "card_icon_path": "res://assets/art/monsters/shell_crab/frames/idle_01.png",
    "behavior": {
      "shield_ratio": 0.35
    },
    "hero_survival_after": 300.0,
    "ground_shadow": {
      "offset_y": 30.0,
      "opacity": 0.42
    },
    "normal_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/monsters/shell_crab/frames",
      "target_height": 122.62295081967213,
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
        -4.0,
        -73.0
      ],
      "source_idle_bounds": [
        56,
        36,
        248,
        158
      ],
      "body_height": 88,
      "hero_height_ratio": 0.8148148148148148,
      "ground_y": 30.0,
      "source_animation_top": 12
    },
    "elite_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/elitemonster/shell_crab/frames",
      "target_height": 134.66771653543307,
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
        -4.0,
        -72.5
      ],
      "source_idle_bounds": [
        58,
        30,
        258,
        157
      ],
      "body_height": 101.19999999999999,
      "hero_height_ratio": 0.9370370370370369,
      "ground_y": 30.0,
      "source_animation_top": 12
    }
  },
  "swamp_toad": {
    "id": "swamp_toad",
    "name": "늪지두꺼비",
    "grade": "common",
    "rarity": "common",
    "role": "controller",
    "family": "swamp_toad",
    "species": "beast",
    "base_cost": 4.0,
    "summon_exp": 4.0,
    "attack_type": "melee",
    "base_stats": {
      "max_hp": 1,
      "attack_damage": 1,
      "move_speed": 82.0,
      "attack_range": 155.0,
      "attack_cooldown": 1.6,
      "exp_reward": 4,
      "projectile_speed": 0.0
    },
    "balance": {
      "health_share": 0.85,
      "damage_share": 0.7,
      "cycle_damage_multiplier": 1.0,
      "note": "155px 거리의 단일 혀 공격. 적중 시0.8초간20% 둔화. 혀 공격은 즉시 판정이며 원거리 투사체가 아니다. 고유능력 기여를 HP/직접DPS 할인에 반영. 엘리트·증강은 별도 기여, 실전 승률 미검증."
    },
    "description": "155px 거리의 단일 혀 공격. 적중 시0.8초간20% 둔화. 혀 공격은 즉시 판정이며 원거리 투사체가 아니다.",
    "special_augment_ids": [
      "swamp_toad_special_1",
      "swamp_toad_special_2",
      "swamp_toad_special_3"
    ],
    "elite_skills": [
      {
        "id": "elite_swamp_toad",
        "name": "늪왕의 끈끈혀",
        "description": "0.55초간 대상 위치를 예고한 뒤 대상1명에 공격력140% 피해. 반경95.0px 밖으로 피하면 불발. 적중 시1.3초간50% 둔화.",
        "runtime": "monster",
        "kind": "strike",
        "initial_cooldown": 3.0,
        "cooldown": 14.0,
        "retry_interval": 0.35,
        "windup": 0.55,
        "cast_range": 260.0,
        "radius": 95.0,
        "damage_multiplier": 1.4,
        "color": "d6ad72",
        "slow_multiplier": 0.5,
        "slow_duration": 1.3
      }
    ],
    "card_icon_path": "res://assets/art/monsters/swamp_toad/frames/idle_01.png",
    "behavior": {
      "slow_multiplier": 0.8,
      "slow_duration": 0.8
    },
    "hero_survival_after": 300.0,
    "ground_shadow": {
      "offset_y": 30.0,
      "opacity": 0.42
    },
    "normal_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/monsters/swamp_toad/frames",
      "target_height": 108.77862595419847,
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
        -83.0
      ],
      "source_idle_bounds": [
        99,
        47,
        266,
        178
      ],
      "body_height": 75,
      "hero_height_ratio": 0.6944444444444444,
      "ground_y": 30.0,
      "source_animation_top": 12
    },
    "elite_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/elitemonster/swamp_toad/frames",
      "target_height": 125.15977443609023,
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
        1.5,
        -84.5
      ],
      "source_idle_bounds": [
        82,
        48,
        257,
        181
      ],
      "body_height": 86.25,
      "hero_height_ratio": 0.7986111111111112,
      "ground_y": 30.0,
      "source_animation_top": 12
    }
  },
  "rag_scarecrow": {
    "id": "rag_scarecrow",
    "name": "누더기허수아비",
    "grade": "common",
    "rarity": "common",
    "role": "burst",
    "family": "rag_scarecrow",
    "species": "construct",
    "base_cost": 5.0,
    "summon_exp": 5.0,
    "attack_type": "melee",
    "base_stats": {
      "max_hp": 1,
      "attack_damage": 1,
      "move_speed": 102.0,
      "attack_range": 88.0,
      "attack_cooldown": 1.5,
      "exp_reward": 5,
      "projectile_speed": 0.0
    },
    "balance": {
      "health_share": 1.05,
      "damage_share": 0.82,
      "cycle_damage_multiplier": 1.0,
      "note": "체력이35% 이하인 대상에게 기본공격 피해135%. 처형 즉사 판정 없이 잔여 체력을 마무리한다. 고유능력 기여를 HP/직접DPS 할인에 반영. 엘리트·증강은 별도 기여, 실전 승률 미검증."
    },
    "description": "체력이35% 이하인 대상에게 기본공격 피해135%. 처형 즉사 판정 없이 잔여 체력을 마무리한다.",
    "special_augment_ids": [
      "rag_scarecrow_special_1",
      "rag_scarecrow_special_2",
      "rag_scarecrow_special_3"
    ],
    "elite_skills": [
      {
        "id": "elite_rag_scarecrow",
        "name": "황혼의 추수",
        "description": "0.65초간 대상 위치를 예고한 뒤 대상1명에 공격력200% 피해. 반경110.0px 밖으로 피하면 불발. 실제 체력 피해의15% 회복.",
        "runtime": "monster",
        "kind": "strike",
        "initial_cooldown": 3.0,
        "cooldown": 15.0,
        "retry_interval": 0.35,
        "windup": 0.65,
        "cast_range": 190.0,
        "radius": 110.0,
        "damage_multiplier": 2.0,
        "color": "d6ad72",
        "lifesteal": 0.15
      }
    ],
    "card_icon_path": "res://assets/art/monsters/rag_scarecrow/frames/idle_01.png",
    "behavior": {
      "execute_threshold": 0.35,
      "execute_multiplier": 1.35
    },
    "hero_survival_after": 300.0,
    "ground_shadow": {
      "offset_y": 30.0,
      "opacity": 0.42
    },
    "normal_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/monsters/rag_scarecrow/frames",
      "target_height": 119.2663043478261,
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
        -3.5,
        -92.5
      ],
      "source_idle_bounds": [
        75,
        13,
        252,
        197
      ],
      "body_height": 105,
      "hero_height_ratio": 0.9722222222222222,
      "ground_y": 30.0,
      "source_animation_top": 12
    },
    "elite_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/elitemonster/rag_scarecrow/frames",
      "target_height": 135.38636363636363,
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
        -7.0,
        -99.0
      ],
      "source_idle_bounds": [
        85,
        12,
        273,
        210
      ],
      "body_height": 120.74999999999999,
      "hero_height_ratio": 1.1180555555555554,
      "ground_y": 30.0,
      "source_animation_top": 12
    }
  },
  "rust_automaton": {
    "id": "rust_automaton",
    "name": "녹슨태엽병",
    "grade": "common",
    "rarity": "common",
    "role": "tank",
    "family": "rust_automaton",
    "species": "construct",
    "base_cost": 6.0,
    "summon_exp": 6.0,
    "attack_type": "melee",
    "base_stats": {
      "max_hp": 1,
      "attack_damage": 1,
      "move_speed": 72.0,
      "attack_range": 82.0,
      "attack_cooldown": 1.7,
      "exp_reward": 6,
      "projectile_speed": 0.0
    },
    "balance": {
      "health_share": 0.85,
      "damage_share": 0.65,
      "cycle_damage_multiplier": 1.0,
      "note": "매3회 공격마다170px 내 아군 최대2명에게 각 최대체력4% 보호막. 같은 계열 보호막은 합산하지 않고 큰 잔량으로 갱신. 고유능력 기여를 HP/직접DPS 할인에 반영. 엘리트·증강은 별도 기여, 실전 승률 미검증.",
      "role": "buffer"
    },
    "description": "매3회 공격마다170px 내 아군 최대2명에게 각 최대체력4% 보호막. 같은 계열 보호막은 합산하지 않고 큰 잔량으로 갱신.",
    "special_augment_ids": [
      "rust_automaton_special_1",
      "rust_automaton_special_2",
      "rust_automaton_special_3"
    ],
    "elite_skills": [
      {
        "id": "elite_rust_automaton",
        "name": "비상 방호 태엽",
        "description": "220px 내 아군 최대3명에게 각 최대체력12% 보호막. 같은 보호막은 합산하지 않고 더 큰 잔량으로 갱신. 자신은 제외.",
        "runtime": "monster",
        "kind": "ally_ward",
        "initial_cooldown": 4.0,
        "cooldown": 16.0,
        "retry_interval": 0.5,
        "ward_radius": 220.0,
        "ward_ratio": 0.12,
        "ward_count": 3
      }
    ],
    "card_icon_path": "res://assets/art/monsters/rust_automaton/frames/idle_01.png",
    "behavior": {
      "ward_every": 3,
      "ward_radius": 170.0,
      "ward_ratio": 0.04,
      "ward_count": 2
    },
    "hero_survival_after": 300.0,
    "ground_shadow": {
      "offset_y": 30.0,
      "opacity": 0.42
    },
    "normal_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/monsters/rust_automaton/frames",
      "target_height": 134.93150684931507,
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
        2.5,
        -86.5
      ],
      "source_idle_bounds": [
        53,
        39,
        224,
        185
      ],
      "body_height": 100,
      "hero_height_ratio": 0.9259259259259259,
      "ground_y": 30.0,
      "source_animation_top": 12
    },
    "elite_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/elitemonster/rust_automaton/frames",
      "target_height": 155.13422818791943,
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
        4.0,
        -88.5
      ],
      "source_idle_bounds": [
        39,
        40,
        239,
        189
      ],
      "body_height": 114.99999999999999,
      "hero_height_ratio": 1.0648148148148147,
      "ground_y": 30.0,
      "source_animation_top": 12
    }
  },
  "iron_beetle": {
    "id": "iron_beetle",
    "name": "철갑장수풍뎅이",
    "grade": "uncommon",
    "rarity": "uncommon",
    "role": "tank",
    "family": "iron_beetle",
    "species": "beast",
    "base_cost": 11.0,
    "summon_exp": 11.0,
    "attack_type": "melee",
    "base_stats": {
      "max_hp": 1,
      "attack_damage": 1,
      "move_speed": 72.0,
      "attack_range": 90.0,
      "attack_cooldown": 2.2,
      "exp_reward": 11,
      "projectile_speed": 0.0
    },
    "balance": {
      "health_share": 0.7,
      "damage_share": 0.85,
      "cycle_damage_multiplier": 1.0,
      "note": "첫 기본공격140% 피해. 등장 시 최대체력40% 보호막을 얻는 전선 탱커. 느린 접근과 긴 공격 간격이 약점. 고유 생존/화상/연격/지원 기여를 HP·직접DPS 예산에 반영. 실전 승률 미검증."
    },
    "description": "첫 기본공격140% 피해. 등장 시 최대체력40% 보호막을 얻는 전선 탱커. 느린 접근과 긴 공격 간격이 약점.",
    "special_augment_ids": [
      "iron_beetle_special_1",
      "iron_beetle_special_2",
      "iron_beetle_special_3"
    ],
    "elite_skills": [
      {
        "id": "elite_iron_beetle",
        "name": "철옹의 등딱지",
        "description": "최대체력65% 보호막을 생성. 남은 보호막과 합산하지 않고 큰 값으로 갱신.",
        "runtime": "monster",
        "kind": "self_ward",
        "initial_cooldown": 4.0,
        "cooldown": 18.0,
        "retry_interval": 0.35,
        "shield_ratio": 0.65
      }
    ],
    "card_icon_path": "res://assets/art/monsters/iron_beetle/frames/idle_01.png",
    "behavior": {
      "shield_ratio": 0.4,
      "first_multiplier": 1.4
    },
    "hero_survival_after": 420.0,
    "ground_shadow": {
      "offset_y": 30.0,
      "opacity": 0.42
    },
    "normal_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/monsters/iron_beetle/frames",
      "target_height": 149.625,
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
        -4.0,
        -73.5
      ],
      "source_idle_bounds": [
        45,
        39,
        241,
        159
      ],
      "body_height": 105,
      "hero_height_ratio": 0.9722222222222222,
      "ground_y": 30.0,
      "source_animation_top": 12
    },
    "elite_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/elitemonster/iron_beetle/frames",
      "target_height": 156.00547445255472,
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
        -6.5,
        -76.5
      ],
      "source_idle_bounds": [
        46,
        28,
        261,
        165
      ],
      "body_height": 120.74999999999999,
      "hero_height_ratio": 1.1180555555555554,
      "ground_y": 30.0,
      "source_animation_top": 12
    }
  },
  "lantern_wisp": {
    "id": "lantern_wisp",
    "name": "등불도깨비",
    "grade": "uncommon",
    "rarity": "uncommon",
    "role": "ranged",
    "family": "lantern_wisp",
    "species": "gas",
    "base_cost": 9.0,
    "summon_exp": 9.0,
    "attack_type": "ranged",
    "base_stats": {
      "max_hp": 1,
      "attack_damage": 1,
      "move_speed": 94.0,
      "attack_range": 360.0,
      "attack_cooldown": 1.7,
      "exp_reward": 9,
      "projectile_speed": 315.0
    },
    "balance": {
      "health_share": 0.8,
      "damage_share": 0.9,
      "cycle_damage_multiplier": 1.3,
      "note": "회피 가능한 불씨탄 적중 시 해당 공격력30%를2초간 추가 화상 피해. 낮은 몸체 체력으로 중거리 화력을 지원. 고유 생존/화상/연격/지원 기여를 HP·직접DPS 예산에 반영. 실전 승률 미검증."
    },
    "description": "회피 가능한 불씨탄 적중 시 해당 공격력30%를2초간 추가 화상 피해. 낮은 몸체 체력으로 중거리 화력을 지원.",
    "special_augment_ids": [
      "lantern_wisp_special_1",
      "lantern_wisp_special_2",
      "lantern_wisp_special_3"
    ],
    "elite_skills": [
      {
        "id": "elite_lantern_wisp",
        "name": "삼도천 길잡이",
        "description": "전방3방향으로 각 공격력65% 불씨탄을 발사. 탄마다 회피 가능하며 현재 불씨 화상 증강을 적용.",
        "runtime": "monster",
        "kind": "fan",
        "initial_cooldown": 3.0,
        "cooldown": 15.0,
        "retry_interval": 0.35,
        "cast_range": 430.0,
        "damage_multiplier": 0.65,
        "spread": 0.2,
        "color": "80decf"
      }
    ],
    "card_icon_path": "res://assets/art/monsters/lantern_wisp/frames/idle_01.png",
    "behavior": {
      "projectile": true,
      "burn_ratio": 0.3,
      "burn_duration": 2.0,
      "color": "f6ae45",
      "projectile_art": "lantern_wisp"
    },
    "hero_survival_after": 420.0,
    "ground_shadow": {
      "offset_y": 30.0,
      "opacity": 0.42
    },
    "normal_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/monsters/lantern_wisp/frames",
      "target_height": 107.13924050632912,
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
        3.0,
        -80.0
      ],
      "source_idle_bounds": [
        82,
        14,
        210,
        172
      ],
      "body_height": 92,
      "hero_height_ratio": 0.8518518518518519,
      "ground_y": 30.0,
      "source_animation_top": 12
    },
    "elite_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/elitemonster/lantern_wisp/frames",
      "target_height": 121.92804878048781,
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
        4.0,
        -82.5
      ],
      "source_idle_bounds": [
        80,
        13,
        214,
        177
      ],
      "body_height": 105.8,
      "hero_height_ratio": 0.9796296296296296,
      "ground_y": 30.0,
      "source_animation_top": 12
    }
  },
  "blade_mantis": {
    "id": "blade_mantis",
    "name": "쌍낫사마귀",
    "grade": "uncommon",
    "rarity": "uncommon",
    "role": "burst",
    "family": "blade_mantis",
    "species": "beast",
    "base_cost": 10.0,
    "summon_exp": 10.0,
    "attack_type": "melee",
    "base_stats": {
      "max_hp": 1,
      "attack_damage": 1,
      "move_speed": 133.0,
      "attack_range": 96.0,
      "attack_cooldown": 1.15,
      "exp_reward": 10,
      "projectile_speed": 0.0
    },
    "balance": {
      "health_share": 0.9,
      "damage_share": 0.88,
      "cycle_damage_multiplier": 1.2666666666666666,
      "note": "빠른 근접 낫 공격. 매3번째 공격180% 피해와1.2초 이속15% 증가. 광역 공격에 취약한 돌파 딜러. 고유 생존/화상/연격/지원 기여를 HP·직접DPS 예산에 반영. 실전 승률 미검증."
    },
    "description": "빠른 근접 낫 공격. 매3번째 공격180% 피해와1.2초 이속15% 증가. 광역 공격에 취약한 돌파 딜러.",
    "special_augment_ids": [
      "blade_mantis_special_1",
      "blade_mantis_special_2",
      "blade_mantis_special_3"
    ],
    "elite_skills": [
      {
        "id": "elite_blade_mantis",
        "name": "초승달 가르기",
        "description": "대상 위치를0.5초 예고 후 반경110px 안 대상1명에 공격력210% 피해. 원 밖으로 피하면 불발. 시전 종료 후1.5초 이속20% 증가.",
        "runtime": "monster",
        "kind": "strike",
        "initial_cooldown": 3.0,
        "cooldown": 15.0,
        "retry_interval": 0.35,
        "windup": 0.5,
        "cast_range": 240.0,
        "radius": 110.0,
        "damage_multiplier": 2.1,
        "speed_multiplier": 1.2,
        "speed_duration": 1.5,
        "color": "c9df82"
      }
    ],
    "card_icon_path": "res://assets/art/monsters/blade_mantis/frames/idle_01.png",
    "behavior": {
      "third_bonus": 0.8,
      "third_speed": 1.15,
      "speed_duration": 1.2
    },
    "hero_survival_after": 420.0,
    "ground_shadow": {
      "offset_y": 30.0,
      "opacity": 0.42
    },
    "normal_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/monsters/blade_mantis/frames",
      "target_height": 131.625,
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
        4.5,
        -85.5
      ],
      "source_idle_bounds": [
        75,
        23,
        240,
        183
      ],
      "body_height": 108,
      "hero_height_ratio": 1.0,
      "ground_y": 30.0,
      "source_animation_top": 12
    },
    "elite_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/elitemonster/blade_mantis/frames",
      "target_height": 152.14499999999998,
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
        2.5,
        -86.0
      ],
      "source_idle_bounds": [
        76,
        24,
        243,
        184
      ],
      "body_height": 124.19999999999999,
      "hero_height_ratio": 1.15,
      "ground_y": 30.0,
      "source_animation_top": 12
    }
  },
  "moss_deer": {
    "id": "moss_deer",
    "name": "이끼뿔사슴",
    "grade": "uncommon",
    "rarity": "uncommon",
    "role": "ranged",
    "family": "moss_deer",
    "species": "beast",
    "base_cost": 10.0,
    "summon_exp": 10.0,
    "attack_type": "ranged",
    "base_stats": {
      "max_hp": 1,
      "attack_damage": 1,
      "move_speed": 100.0,
      "attack_range": 300.0,
      "attack_cooldown": 1.9,
      "exp_reward": 10,
      "projectile_speed": 310.0
    },
    "balance": {
      "health_share": 0.9,
      "damage_share": 0.7,
      "cycle_damage_multiplier": 1.0,
      "note": "씨앗탄을 발사하며 매3회 공격마다200px 내 아군 최대3명에게 각 최대체력6% 보호막. 자신은 제외, 같은 계열 보호막은 합산 없이 큰 잔량으로 갱신. 고유 생존/화상/연격/지원 기여를 HP·직접DPS 예산에 반영. 실전 승률 미검증.",
      "role": "buffer"
    },
    "description": "씨앗탄을 발사하며 매3회 공격마다200px 내 아군 최대3명에게 각 최대체력6% 보호막. 자신은 제외, 같은 계열 보호막은 합산 없이 큰 잔량으로 갱신.",
    "special_augment_ids": [
      "moss_deer_special_1",
      "moss_deer_special_2",
      "moss_deer_special_3"
    ],
    "elite_skills": [
      {
        "id": "elite_moss_deer",
        "name": "고목의 축복",
        "description": "260px 내 아군 최대4명에게 각 최대체력16% 보호막. 자신은 제외, 같은 계열 보호막은 합산 없이 큰 잔량으로 갱신.",
        "runtime": "monster",
        "kind": "ally_ward",
        "initial_cooldown": 4.0,
        "cooldown": 18.0,
        "retry_interval": 0.5,
        "ward_radius": 260.0,
        "ward_ratio": 0.16,
        "ward_count": 4
      }
    ],
    "card_icon_path": "res://assets/art/monsters/moss_deer/frames/idle_01.png",
    "behavior": {
      "projectile": true,
      "ward_every": 3,
      "ward_radius": 200.0,
      "ward_ratio": 0.06,
      "ward_count": 3,
      "color": "9acb7b",
      "projectile_art": "moss_deer"
    },
    "hero_survival_after": 420.0,
    "ground_shadow": {
      "offset_y": 30.0,
      "opacity": 0.42
    },
    "normal_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/monsters/moss_deer/frames",
      "target_height": 126.7843137254902,
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
        -79.5
      ],
      "source_idle_bounds": [
        91,
        18,
        235,
        171
      ],
      "body_height": 106,
      "hero_height_ratio": 0.9814814814814815,
      "ground_y": 30.0,
      "source_animation_top": 12
    },
    "elite_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/elitemonster/moss_deer/frames",
      "target_height": 137.71405405405406,
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
        -92.5
      ],
      "source_idle_bounds": [
        85,
        12,
        239,
        197
      ],
      "body_height": 121.89999999999999,
      "hero_height_ratio": 1.1287037037037035,
      "ground_y": 30.0,
      "source_animation_top": 12
    }
  },
  "crystal_tortoise": {
    "id": "crystal_tortoise",
    "name": "수정등거북",
    "grade": "rare",
    "rarity": "rare",
    "role": "tank",
    "family": "crystal_tortoise",
    "species": "beast",
    "base_cost": 17.0,
    "summon_exp": 17.0,
    "attack_type": "melee",
    "base_stats": {
      "max_hp": 1,
      "attack_damage": 1,
      "move_speed": 58.0,
      "attack_range": 92.0,
      "attack_cooldown": 2.5,
      "exp_reward": 17,
      "projectile_speed": 0.0
    },
    "balance": {
      "health_share": 0.76,
      "damage_share": 0.87,
      "cycle_damage_multiplier": 1.0,
      "note": "등장 시 최대체력30% 보호막. 느린 근접 탱커로 원거리 추격이 약하다. 고유 능력·엘리트 기여를 몸체/직접DPS 예산에서 할인. 실전 승률 미검증."
    },
    "description": "등장 시 최대체력30% 보호막. 느린 근접 탱커로 원거리 추격이 약하다.",
    "special_augment_ids": [
      "crystal_tortoise_special_1",
      "crystal_tortoise_special_2",
      "crystal_tortoise_special_3"
    ],
    "elite_skills": [
      {
        "name": "수정 재결정",
        "description": "자신의 보호막을 최대체력40%까지 보충. 남은 잔량과 합산하지 않고 큰 값으로 갱신.",
        "runtime": "monster",
        "kind": "self_ward",
        "initial_cooldown": 4.0,
        "cooldown": 20.0,
        "retry_interval": 0.35,
        "shield_ratio": 0.4,
        "id": "elite_crystal_tortoise_1"
      },
      {
        "name": "등갑 내려찍기",
        "description": "대상 위치를0.65초 예고 후 반경115px 안 대상1명에 공격력150% 피해·1초25% 둔화. 원 밖으로 피하면 불발.",
        "runtime": "monster",
        "kind": "strike",
        "initial_cooldown": 4.0,
        "cooldown": 18.0,
        "retry_interval": 0.35,
        "windup": 0.65,
        "cast_range": 240.0,
        "radius": 115.0,
        "damage_multiplier": 1.5,
        "color": "94dbea",
        "slow_multiplier": 0.75,
        "slow_duration": 1.0,
        "id": "elite_crystal_tortoise_2"
      }
    ],
    "card_icon_path": "res://assets/art/monsters/crystal_tortoise/frames/idle_01.png",
    "behavior": {
      "shield_ratio": 0.3
    },
    "normal_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/monsters/crystal_tortoise/frames",
      "target_height": 140.43076923076924,
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
        -69.5
      ],
      "source_idle_bounds": [
        53,
        21,
        244,
        151
      ],
      "body_height": 112.0,
      "hero_height_ratio": 1.037037037037037,
      "ground_y": 30.0,
      "source_animation_top": 12
    },
    "elite_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/elitemonster/crystal_tortoise/frames",
      "target_height": 159.98144927536234,
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
        -2.5,
        -76.0
      ],
      "source_idle_bounds": [
        50,
        26,
        247,
        164
      ],
      "body_height": 125.44000000000001,
      "hero_height_ratio": 1.1614814814814816,
      "ground_y": 30.0,
      "source_animation_top": 12
    },
    "hero_survival_after": 540.0,
    "ground_shadow": {
      "offset_y": 30.0,
      "opacity": 0.42
    }
  },
  "ember_salamander": {
    "id": "ember_salamander",
    "name": "잿불도롱뇽",
    "grade": "rare",
    "rarity": "rare",
    "role": "ranged",
    "family": "ember_salamander",
    "species": "beast",
    "base_cost": 15.0,
    "summon_exp": 15.0,
    "attack_type": "ranged",
    "base_stats": {
      "max_hp": 1,
      "attack_damage": 1,
      "move_speed": 90.0,
      "attack_range": 355.0,
      "attack_cooldown": 1.65,
      "exp_reward": 15,
      "projectile_speed": 340.0
    },
    "balance": {
      "health_share": 0.88,
      "damage_share": 0.76,
      "cycle_damage_multiplier": 1.0,
      "note": "직선 불씨탄에 공격력25%의2초 화상. 접근당하면 취약하다. 고유 능력·엘리트 기여를 몸체/직접DPS 예산에서 할인. 실전 승률 미검증."
    },
    "description": "직선 불씨탄에 공격력25%의2초 화상. 접근당하면 취약하다.",
    "special_augment_ids": [
      "ember_salamander_special_1",
      "ember_salamander_special_2",
      "ember_salamander_special_3"
    ],
    "elite_skills": [
      {
        "name": "세갈래 잿불",
        "description": "지정 방향으로 3갈래 직선탄. 각 공격력65% 피해, 회피 가능. 기본 공격의 상태효과를 계승.",
        "runtime": "monster",
        "kind": "fan",
        "initial_cooldown": 4.0,
        "cooldown": 18.0,
        "retry_interval": 0.35,
        "cast_range": 415.0,
        "spread": 0.22,
        "damage_multiplier": 0.65,
        "color": "f58d51",
        "id": "elite_ember_salamander_1"
      },
      {
        "name": "화염 낙인",
        "description": "대상 위치를0.65초 예고 후 반경115px 안 대상1명에 공격력140% 피해와 해당 피해40%의2초 화상. 피하면 불발.",
        "runtime": "monster",
        "kind": "strike",
        "initial_cooldown": 4.0,
        "cooldown": 20.0,
        "retry_interval": 0.35,
        "windup": 0.65,
        "cast_range": 240.0,
        "radius": 115.0,
        "damage_multiplier": 1.4,
        "color": "f58d51",
        "burn_ratio": 0.4,
        "burn_duration": 2.0,
        "id": "elite_ember_salamander_2"
      }
    ],
    "card_icon_path": "res://assets/art/monsters/ember_salamander/frames/idle_01.png",
    "behavior": {
      "projectile": true,
      "color": "f58d51",
      "burn_ratio": 0.25,
      "burn_duration": 2.0,
      "projectile_art": "ember_salamander"
    },
    "normal_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/monsters/ember_salamander/frames",
      "target_height": 135.7941176470588,
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
        -3.0,
        -73.5
      ],
      "source_idle_bounds": [
        76,
        23,
        258,
        159
      ],
      "body_height": 108.0,
      "hero_height_ratio": 1.0,
      "ground_y": 30.0,
      "source_animation_top": 12
    },
    "elite_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/elitemonster/ember_salamander/frames",
      "target_height": 147.744,
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
        -2.0,
        -73.5
      ],
      "source_idle_bounds": [
        77,
        19,
        267,
        159
      ],
      "body_height": 120.96000000000001,
      "hero_height_ratio": 1.12,
      "ground_y": 30.0,
      "source_animation_top": 12
    },
    "hero_survival_after": 540.0,
    "ground_shadow": {
      "offset_y": 30.0,
      "opacity": 0.42
    }
  },
  "frost_owl": {
    "id": "frost_owl",
    "name": "서리깃올빼미",
    "grade": "rare",
    "rarity": "rare",
    "role": "controller",
    "family": "frost_owl",
    "species": "beast",
    "base_cost": 14.0,
    "summon_exp": 14.0,
    "attack_type": "ranged",
    "base_stats": {
      "max_hp": 1,
      "attack_damage": 1,
      "move_speed": 85.0,
      "attack_range": 335.0,
      "attack_cooldown": 1.9,
      "exp_reward": 14,
      "projectile_speed": 310.0
    },
    "balance": {
      "health_share": 0.9,
      "damage_share": 0.72,
      "cycle_damage_multiplier": 1.0,
      "note": "얼음깃 직선탄이1초18% 둔화. 직접 화력보다 아군의 접근을 돕는다. 고유 능력·엘리트 기여를 몸체/직접DPS 예산에서 할인. 실전 승률 미검증."
    },
    "description": "얼음깃 직선탄이1초18% 둔화. 직접 화력보다 아군의 접근을 돕는다.",
    "special_augment_ids": [
      "frost_owl_special_1",
      "frost_owl_special_2",
      "frost_owl_special_3"
    ],
    "elite_skills": [
      {
        "name": "서리깃 부채",
        "description": "지정 방향으로 3갈래 직선탄. 각 공격력55% 피해, 회피 가능. 기본 공격의 상태효과를 계승.",
        "runtime": "monster",
        "kind": "fan",
        "initial_cooldown": 4.0,
        "cooldown": 18.0,
        "retry_interval": 0.35,
        "cast_range": 395.0,
        "spread": 0.22,
        "damage_multiplier": 0.55,
        "color": "a4e5ef",
        "id": "elite_frost_owl_1"
      },
      {
        "name": "동결 표식",
        "description": "대상 위치를0.65초 예고 후 반경115px 안 대상1명에 공격력100% 피해·1.3초35% 둔화. 피하면 불발.",
        "runtime": "monster",
        "kind": "strike",
        "initial_cooldown": 4.0,
        "cooldown": 19.0,
        "retry_interval": 0.35,
        "windup": 0.65,
        "cast_range": 240.0,
        "radius": 115.0,
        "damage_multiplier": 1.0,
        "color": "a4e5ef",
        "slow_multiplier": 0.65,
        "slow_duration": 1.3,
        "id": "elite_frost_owl_2"
      }
    ],
    "card_icon_path": "res://assets/art/monsters/frost_owl/frames/idle_01.png",
    "behavior": {
      "projectile": true,
      "color": "a4e5ef",
      "slow_multiplier": 0.82,
      "slow_duration": 1.0,
      "projectile_art": "frost_owl"
    },
    "normal_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/monsters/frost_owl/frames",
      "target_height": 123.0326797385621,
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
        6.0,
        -78.5
      ],
      "source_idle_bounds": [
        79,
        16,
        237,
        169
      ],
      "body_height": 104.0,
      "hero_height_ratio": 0.9629629629629629,
      "ground_y": 30.0,
      "source_animation_top": 12
    },
    "elite_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/elitemonster/frost_owl/frames",
      "target_height": 134.56695652173914,
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
        6.0,
        -81.0
      ],
      "source_idle_bounds": [
        81,
        13,
        241,
        174
      ],
      "body_height": 116.48000000000002,
      "hero_height_ratio": 1.0785185185185187,
      "ground_y": 30.0,
      "source_animation_top": 12
    },
    "hero_survival_after": 540.0,
    "ground_shadow": {
      "offset_y": 30.0,
      "opacity": 0.42
    }
  },
  "thorn_dryad": {
    "id": "thorn_dryad",
    "name": "가시덩굴드리아드",
    "grade": "rare",
    "rarity": "rare",
    "role": "controller",
    "family": "thorn_dryad",
    "species": "plant",
    "base_cost": 16.0,
    "summon_exp": 16.0,
    "attack_type": "melee",
    "base_stats": {
      "max_hp": 1,
      "attack_damage": 1,
      "move_speed": 76.0,
      "attack_range": 130.0,
      "attack_cooldown": 2.0,
      "exp_reward": 16,
      "projectile_speed": 0.0
    },
    "balance": {
      "health_share": 0.93,
      "damage_share": 0.73,
      "cycle_damage_multiplier": 1.0,
      "note": "근접 가시채찍에1.1초22% 둔화. 전선 뒤에서 묶으며 원거리 견제에 약하다. 고유 능력·엘리트 기여를 몸체/직접DPS 예산에서 할인. 실전 승률 미검증."
    },
    "description": "근접 가시채찍에1.1초22% 둔화. 전선 뒤에서 묶으며 원거리 견제에 약하다.",
    "special_augment_ids": [
      "thorn_dryad_special_1",
      "thorn_dryad_special_2",
      "thorn_dryad_special_3"
    ],
    "elite_skills": [
      {
        "name": "뿌리 얽기",
        "description": "대상 위치를0.65초 예고 후 반경115px 안 대상1명에 공격력110% 피해·1.5초40% 둔화. 피하면 불발.",
        "runtime": "monster",
        "kind": "strike",
        "initial_cooldown": 4.0,
        "cooldown": 18.0,
        "retry_interval": 0.35,
        "windup": 0.65,
        "cast_range": 240.0,
        "radius": 115.0,
        "damage_multiplier": 1.1,
        "color": "91b957",
        "slow_multiplier": 0.6,
        "slow_duration": 1.5,
        "id": "elite_thorn_dryad_1"
      },
      {
        "name": "숲의 가시울타리",
        "description": "주변240px 내 자신을 제외한 아군 최대3명에 각 최대체력12% 보호막. 중첩 없이 큰 잔량으로 갱신.",
        "runtime": "monster",
        "kind": "ally_ward",
        "initial_cooldown": 4.0,
        "cooldown": 20.0,
        "retry_interval": 0.35,
        "ward_radius": 240.0,
        "ward_count": 3,
        "ward_ratio": 0.12,
        "id": "elite_thorn_dryad_2"
      }
    ],
    "card_icon_path": "res://assets/art/monsters/thorn_dryad/frames/idle_01.png",
    "behavior": {
      "slow_multiplier": 0.78,
      "slow_duration": 1.1
    },
    "normal_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/monsters/thorn_dryad/frames",
      "target_height": 134.97435897435898,
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
        -4.5,
        -82.0
      ],
      "source_idle_bounds": [
        98,
        20,
        257,
        176
      ],
      "body_height": 112.0,
      "hero_height_ratio": 1.037037037037037,
      "ground_y": 30.0,
      "source_animation_top": 12
    },
    "elite_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/elitemonster/thorn_dryad/frames",
      "target_height": 152.88000000000002,
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
        -5.5,
        -85.5
      ],
      "source_idle_bounds": [
        100,
        23,
        261,
        183
      ],
      "body_height": 125.44000000000001,
      "hero_height_ratio": 1.1614814814814816,
      "ground_y": 30.0,
      "source_animation_top": 12
    },
    "hero_survival_after": 540.0,
    "ground_shadow": {
      "offset_y": 30.0,
      "opacity": 0.42
    }
  },
  "dusk_panther": {
    "id": "dusk_panther",
    "name": "황혼표범",
    "grade": "rare",
    "rarity": "rare",
    "role": "burst",
    "family": "dusk_panther",
    "species": "beast",
    "base_cost": 14.0,
    "summon_exp": 14.0,
    "attack_type": "melee",
    "base_stats": {
      "max_hp": 1,
      "attack_damage": 1,
      "move_speed": 132.0,
      "attack_range": 85.0,
      "attack_cooldown": 1.05,
      "exp_reward": 14,
      "projectile_speed": 0.0
    },
    "balance": {
      "health_share": 0.9,
      "damage_share": 0.84,
      "cycle_damage_multiplier": 1.0,
      "note": "생애 첫 기본공격180%, 체력25% 이하 대상에 피해20% 추가. 몸체가 약한 근접 마무리 딜러. 고유 능력·엘리트 기여를 몸체/직접DPS 예산에서 할인. 실전 승률 미검증."
    },
    "description": "생애 첫 기본공격180%, 체력25% 이하 대상에 피해20% 추가. 몸체가 약한 근접 마무리 딜러.",
    "special_augment_ids": [
      "dusk_panther_special_1",
      "dusk_panther_special_2",
      "dusk_panther_special_3"
    ],
    "elite_skills": [
      {
        "name": "달그림자 도약",
        "description": "대상 위치를0.65초 예고 후 반경115px 안 대상1명에 공격력180% 피해. 피하면 불발. 종료 후1.5초 이속20% 증가.",
        "runtime": "monster",
        "kind": "strike",
        "initial_cooldown": 4.0,
        "cooldown": 16.0,
        "retry_interval": 0.35,
        "windup": 0.65,
        "cast_range": 240.0,
        "radius": 115.0,
        "damage_multiplier": 1.8,
        "color": "a48add",
        "speed_multiplier": 1.2,
        "speed_duration": 1.5,
        "id": "elite_dusk_panther_1"
      },
      {
        "name": "황혼의 포식",
        "description": "대상 위치를0.65초 예고 후 반경115px 안 대상1명에 공격력120% 피해, 실제 체력피해의20% 회복. 피하면 불발.",
        "runtime": "monster",
        "kind": "strike",
        "initial_cooldown": 4.0,
        "cooldown": 22.0,
        "retry_interval": 0.35,
        "windup": 0.65,
        "cast_range": 240.0,
        "radius": 115.0,
        "damage_multiplier": 1.2,
        "color": "a48add",
        "lifesteal": 0.2,
        "id": "elite_dusk_panther_2"
      }
    ],
    "card_icon_path": "res://assets/art/monsters/dusk_panther/frames/idle_01.png",
    "behavior": {
      "first_multiplier": 1.8,
      "execute_threshold": 0.25,
      "execute_multiplier": 1.2
    },
    "normal_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/monsters/dusk_panther/frames",
      "target_height": 164.6551724137931,
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
        -83.5
      ],
      "source_idle_bounds": [
        33,
        63,
        237,
        179
      ],
      "body_height": 100.0,
      "hero_height_ratio": 0.9259259259259259,
      "ground_y": 30.0,
      "source_animation_top": 12
    },
    "elite_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/elitemonster/dusk_panther/frames",
      "target_height": 169.69696969696972,
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
        14.5,
        -88.0
      ],
      "source_idle_bounds": [
        31,
        56,
        240,
        188
      ],
      "body_height": 112.00000000000001,
      "hero_height_ratio": 1.0370370370370372,
      "ground_y": 30.0,
      "source_animation_top": 12
    },
    "hero_survival_after": 540.0,
    "ground_shadow": {
      "offset_y": 30.0,
      "opacity": 0.42
    }
  },
  "rune_sentinel": {
    "id": "rune_sentinel",
    "name": "룬방패수호병",
    "grade": "rare",
    "rarity": "rare",
    "role": "tank",
    "family": "rune_sentinel",
    "species": "construct",
    "base_cost": 18.0,
    "summon_exp": 18.0,
    "attack_type": "melee",
    "base_stats": {
      "max_hp": 1,
      "attack_damage": 1,
      "move_speed": 70.0,
      "attack_range": 100.0,
      "attack_cooldown": 2.2,
      "exp_reward": 18,
      "projectile_speed": 0.0
    },
    "balance": {
      "health_share": 0.83,
      "damage_share": 0.74,
      "cycle_damage_multiplier": 1.0,
      "note": "등장 보호막20%, 매3회 공격마다 주변200px 아군2명에6% 갱신형 보호막. 낮은 단독 화력. 고유 능력·엘리트 기여를 몸체/직접DPS 예산에서 할인. 실전 승률 미검증."
    },
    "description": "등장 보호막20%, 매3회 공격마다 주변200px 아군2명에6% 갱신형 보호막. 낮은 단독 화력.",
    "special_augment_ids": [
      "rune_sentinel_special_1",
      "rune_sentinel_special_2",
      "rune_sentinel_special_3"
    ],
    "elite_skills": [
      {
        "name": "룬의 방벽",
        "description": "주변240px 내 자신을 제외한 아군 최대3명에 각 최대체력15% 보호막. 중첩 없이 큰 잔량으로 갱신.",
        "runtime": "monster",
        "kind": "ally_ward",
        "initial_cooldown": 4.0,
        "cooldown": 20.0,
        "retry_interval": 0.35,
        "ward_radius": 240.0,
        "ward_count": 3,
        "ward_ratio": 0.15,
        "id": "elite_rune_sentinel_1"
      },
      {
        "name": "수호핵 재충전",
        "description": "자신의 보호막을 최대체력35%까지 보충. 남은 잔량과 합산하지 않고 큰 값으로 갱신.",
        "runtime": "monster",
        "kind": "self_ward",
        "initial_cooldown": 4.0,
        "cooldown": 22.0,
        "retry_interval": 0.35,
        "shield_ratio": 0.35,
        "id": "elite_rune_sentinel_2"
      }
    ],
    "card_icon_path": "res://assets/art/monsters/rune_sentinel/frames/idle_01.png",
    "behavior": {
      "shield_ratio": 0.2,
      "ward_every": 3,
      "ward_radius": 200.0,
      "ward_ratio": 0.06,
      "ward_count": 2
    },
    "normal_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/monsters/rune_sentinel/frames",
      "target_height": 183.0,
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
        -5.0,
        -84.0
      ],
      "source_idle_bounds": [
        60,
        52,
        248,
        180
      ],
      "body_height": 122.0,
      "hero_height_ratio": 1.1296296296296295,
      "ground_y": 30.0,
      "source_animation_top": 12
    },
    "elite_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/elitemonster/rune_sentinel/frames",
      "target_height": 198.84179104477613,
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
        -5.5,
        -85.5
      ],
      "source_idle_bounds": [
        62,
        49,
        249,
        183
      ],
      "body_height": 136.64000000000001,
      "hero_height_ratio": 1.2651851851851854,
      "ground_y": 30.0,
      "source_animation_top": 12
    },
    "hero_survival_after": 540.0,
    "ground_shadow": {
      "offset_y": 30.0,
      "opacity": 0.42
    }
  },
  "venom_scorpion": {
    "id": "venom_scorpion",
    "name": "독침전갈",
    "grade": "rare",
    "rarity": "rare",
    "role": "ranged",
    "family": "venom_scorpion",
    "species": "beast",
    "base_cost": 16.0,
    "summon_exp": 16.0,
    "attack_type": "ranged",
    "base_stats": {
      "max_hp": 1,
      "attack_damage": 1,
      "move_speed": 80.0,
      "attack_range": 300.0,
      "attack_cooldown": 2.1,
      "exp_reward": 16,
      "projectile_speed": 285.0
    },
    "balance": {
      "health_share": 0.85,
      "damage_share": 0.7,
      "cycle_damage_multiplier": 1.0,
      "note": "직선 독침 적중 시 현재체력0.2%를3초간 독 피해. 짧은 사거리·느린 공격과 낮은 직접 피해. 고유 능력·엘리트 기여를 몸체/직접DPS 예산에서 할인. 실전 승률 미검증."
    },
    "description": "직선 독침 적중 시 현재체력0.2%를3초간 독 피해. 짧은 사거리·느린 공격과 낮은 직접 피해.",
    "special_augment_ids": [
      "venom_scorpion_special_1",
      "venom_scorpion_special_2",
      "venom_scorpion_special_3"
    ],
    "elite_skills": [
      {
        "name": "독침 삼연사",
        "description": "지정 방향으로 3갈래 직선탄. 각 공격력60% 피해, 회피 가능. 기본 공격의 상태효과를 계승.",
        "runtime": "monster",
        "kind": "fan",
        "initial_cooldown": 4.0,
        "cooldown": 18.0,
        "retry_interval": 0.35,
        "cast_range": 360.0,
        "spread": 0.22,
        "damage_multiplier": 0.6,
        "color": "b0d96c",
        "id": "elite_venom_scorpion_1"
      },
      {
        "name": "비취 탈피",
        "description": "자신의 보호막을 최대체력25%까지 보충. 남은 잔량과 합산하지 않고 큰 값으로 갱신.",
        "runtime": "monster",
        "kind": "self_ward",
        "initial_cooldown": 4.0,
        "cooldown": 24.0,
        "retry_interval": 0.35,
        "shield_ratio": 0.25,
        "id": "elite_venom_scorpion_2"
      }
    ],
    "card_icon_path": "res://assets/art/monsters/venom_scorpion/frames/idle_01.png",
    "behavior": {
      "projectile": true,
      "color": "b0d96c",
      "poison_ratio": 0.002,
      "poison_duration": 3.0,
      "projectile_art": "venom_scorpion"
    },
    "normal_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/monsters/venom_scorpion/frames",
      "target_height": 127.46478873239437,
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
        -11.0,
        -78.5
      ],
      "source_idle_bounds": [
        61,
        27,
        255,
        169
      ],
      "body_height": 100.0,
      "hero_height_ratio": 0.9259259259259259,
      "ground_y": 30.0,
      "source_animation_top": 12
    },
    "elite_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/elitemonster/venom_scorpion/frames",
      "target_height": 137.5570469798658,
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
        -13.5,
        -79.5
      ],
      "source_idle_bounds": [
        64,
        22,
        267,
        171
      ],
      "body_height": 112.00000000000001,
      "hero_height_ratio": 1.0370370370370372,
      "ground_y": 30.0,
      "source_animation_top": 12
    },
    "hero_survival_after": 540.0,
    "ground_shadow": {
      "offset_y": 30.0,
      "opacity": 0.42
    }
  },
  "moon_moth": {
    "id": "moon_moth",
    "name": "달가루나방",
    "grade": "rare",
    "rarity": "rare",
    "role": "ranged",
    "family": "moon_moth",
    "species": "beast",
    "base_cost": 16.0,
    "summon_exp": 16.0,
    "attack_type": "ranged",
    "base_stats": {
      "max_hp": 1,
      "attack_damage": 1,
      "move_speed": 92.0,
      "attack_range": 320.0,
      "attack_cooldown": 1.7,
      "exp_reward": 16,
      "projectile_speed": 300.0
    },
    "balance": {
      "health_share": 0.88,
      "damage_share": 0.72,
      "cycle_damage_multiplier": 1.0,
      "note": "매3회 공격마다 주변240px 아군3명에 최대체력8% 갱신형 보호막. 사격을 지속해야 지원 가능. 고유 능력·엘리트 기여를 몸체/직접DPS 예산에서 할인. 실전 승률 미검증.",
      "role": "buffer"
    },
    "description": "매3회 공격마다 주변240px 아군3명에 최대체력8% 갱신형 보호막. 사격을 지속해야 지원 가능.",
    "special_augment_ids": [
      "moon_moth_special_1",
      "moon_moth_special_2",
      "moon_moth_special_3"
    ],
    "elite_skills": [
      {
        "name": "달빛 장막",
        "description": "주변240px 내 자신을 제외한 아군 최대3명에 각 최대체력16% 보호막. 중첩 없이 큰 잔량으로 갱신.",
        "runtime": "monster",
        "kind": "ally_ward",
        "initial_cooldown": 4.0,
        "cooldown": 20.0,
        "retry_interval": 0.35,
        "ward_radius": 240.0,
        "ward_count": 3,
        "ward_ratio": 0.16,
        "id": "elite_moon_moth_1"
      },
      {
        "name": "초승달 날갯짓",
        "description": "지정 방향으로 3갈래 직선탄. 각 공격력55% 피해, 회피 가능. 기본 공격의 상태효과를 계승.",
        "runtime": "monster",
        "kind": "fan",
        "initial_cooldown": 4.0,
        "cooldown": 18.0,
        "retry_interval": 0.35,
        "cast_range": 380.0,
        "spread": 0.22,
        "damage_multiplier": 0.55,
        "color": "cfb0ec",
        "id": "elite_moon_moth_2"
      }
    ],
    "card_icon_path": "res://assets/art/monsters/moon_moth/frames/idle_01.png",
    "behavior": {
      "projectile": true,
      "color": "cfb0ec",
      "ward_every": 3,
      "ward_radius": 240.0,
      "ward_ratio": 0.08,
      "ward_count": 3,
      "projectile_art": "moon_moth"
    },
    "normal_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/monsters/moon_moth/frames",
      "target_height": 142.68115942028984,
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
        -2.5,
        -77.5
      ],
      "source_idle_bounds": [
        64,
        29,
        243,
        167
      ],
      "body_height": 110.0,
      "hero_height_ratio": 1.0185185185185186,
      "ground_y": 30.0,
      "source_animation_top": 12
    },
    "elite_visual": {
      "mode": "frames",
      "asset_dir": "res://assets/art/elitemonster/moon_moth/frames",
      "target_height": 157.42222222222225,
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
        -2.0,
        -80.0
      ],
      "source_idle_bounds": [
        76,
        28,
        258,
        172
      ],
      "body_height": 123.20000000000002,
      "hero_height_ratio": 1.1407407407407408,
      "ground_y": 30.0,
      "source_animation_top": 12
    },
    "hero_survival_after": 540.0,
    "ground_shadow": {
      "offset_y": 30.0,
      "opacity": 0.42
    }
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
  },
  {
    "id": "cave_ant_special_1",
    "monster_id": "cave_ant",
    "name": "굴파기 행군",
    "description": "이동속도18% 증가.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "cave_ant_special_1",
    "effect_values": {
      "runtime_stat_multipliers": {
        "speed_multiplier": 1.18
      }
    }
  },
  {
    "id": "cave_ant_special_2",
    "monster_id": "cave_ant",
    "name": "단단한 큰턱",
    "description": "매3번째 기본공격125%→175% 피해.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "cave_ant_special_2",
    "effect_values": {
      "behavior": {
        "third_bonus": 0.75
      }
    }
  },
  {
    "id": "cave_ant_special_3",
    "monster_id": "cave_ant",
    "name": "튼튼한 외골격",
    "description": "최대체력25% 증가.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "cave_ant_special_3",
    "effect_values": {
      "stat_multipliers": {
        "hp": 1.25
      }
    }
  },
  {
    "id": "thorn_hedgehog_special_1",
    "monster_id": "thorn_hedgehog",
    "name": "달빛 가시",
    "description": "매3번째 가시 피해150%→200%.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "thorn_hedgehog_special_1",
    "effect_values": {
      "behavior": {
        "third_bonus": 1.0
      }
    }
  },
  {
    "id": "thorn_hedgehog_special_2",
    "monster_id": "thorn_hedgehog",
    "name": "멀리 뻗는 침",
    "description": "사거리260→340px·투사체속도350→450px/초.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "thorn_hedgehog_special_2",
    "effect_values": {
      "stat_overrides": {
        "attack_range": 340.0,
        "projectile_speed": 450.0
      }
    }
  },
  {
    "id": "thorn_hedgehog_special_3",
    "monster_id": "thorn_hedgehog",
    "name": "촘촘한 가시밭",
    "description": "공격 간격18% 감소.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "thorn_hedgehog_special_3",
    "effect_values": {
      "stat_multipliers": {
        "attack_cooldown": 0.82
      }
    }
  },
  {
    "id": "spore_mushroom_special_1",
    "monster_id": "spore_mushroom",
    "name": "끈끈한 균사",
    "description": "둔화20%→30%, 지속1→1.4초.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "spore_mushroom_special_1",
    "effect_values": {
      "behavior": {
        "slow_multiplier": 0.7,
        "slow_duration": 1.4
      }
    }
  },
  {
    "id": "spore_mushroom_special_2",
    "monster_id": "spore_mushroom",
    "name": "농축 독포자",
    "description": "포자 적중 시 현재체력0.8%를3초에 걸쳐 독 피해.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "spore_mushroom_special_2",
    "effect_values": {
      "behavior": {
        "poison_ratio": 0.008,
        "poison_duration": 3.0
      }
    }
  },
  {
    "id": "spore_mushroom_special_3",
    "monster_id": "spore_mushroom",
    "name": "두툼한 갓",
    "description": "최대체력30% 증가.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "spore_mushroom_special_3",
    "effect_values": {
      "stat_multipliers": {
        "hp": 1.3
      }
    }
  },
  {
    "id": "shell_crab_special_1",
    "monster_id": "shell_crab",
    "name": "겹겹 돌껍질",
    "description": "등장 보호막35%→55%. 기존 개체에는 증가분만1회 지급.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "shell_crab_special_1",
    "effect_values": {
      "behavior": {
        "shield_ratio": 0.55
      }
    }
  },
  {
    "id": "shell_crab_special_2",
    "monster_id": "shell_crab",
    "name": "바위 집게",
    "description": "공격력35% 증가.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "shell_crab_special_2",
    "effect_values": {
      "stat_multipliers": {
        "damage": 1.35
      }
    }
  },
  {
    "id": "shell_crab_special_3",
    "monster_id": "shell_crab",
    "name": "가벼운 집",
    "description": "이동속도22% 증가.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "shell_crab_special_3",
    "effect_values": {
      "runtime_stat_multipliers": {
        "speed_multiplier": 1.22
      }
    }
  },
  {
    "id": "swamp_toad_special_1",
    "monster_id": "swamp_toad",
    "name": "질긴 혀",
    "description": "혀 사거리155→210px.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "swamp_toad_special_1",
    "effect_values": {
      "stat_overrides": {
        "attack_range": 210.0
      }
    }
  },
  {
    "id": "swamp_toad_special_2",
    "monster_id": "swamp_toad",
    "name": "끈적한 침",
    "description": "둔화20%→35%, 지속0.8→1.2초.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "swamp_toad_special_2",
    "effect_values": {
      "behavior": {
        "slow_multiplier": 0.65,
        "slow_duration": 1.2
      }
    }
  },
  {
    "id": "swamp_toad_special_3",
    "monster_id": "swamp_toad",
    "name": "왕두꺼비 배",
    "description": "최대체력30% 증가.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "swamp_toad_special_3",
    "effect_values": {
      "stat_multipliers": {
        "hp": 1.3
      }
    }
  },
  {
    "id": "rag_scarecrow_special_1",
    "monster_id": "rag_scarecrow",
    "name": "추수의 시간",
    "description": "35% 이하 대상 공격 피해135%→175%.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "rag_scarecrow_special_1",
    "effect_values": {
      "behavior": {
        "execute_multiplier": 1.75
      }
    }
  },
  {
    "id": "rag_scarecrow_special_2",
    "monster_id": "rag_scarecrow",
    "name": "피 묻은 낫",
    "description": "공격으로 실제 감소시킨 체력의12% 회복.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "rag_scarecrow_special_2",
    "effect_values": {
      "behavior": {
        "lifesteal": 0.12
      }
    }
  },
  {
    "id": "rag_scarecrow_special_3",
    "monster_id": "rag_scarecrow",
    "name": "가벼운 짚단",
    "description": "이동속도15% 증가·공격 간격10% 감소.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "rag_scarecrow_special_3",
    "effect_values": {
      "runtime_stat_multipliers": {
        "speed_multiplier": 1.15
      },
      "stat_multipliers": {
        "attack_cooldown": 0.9
      }
    }
  },
  {
    "id": "rust_automaton_special_1",
    "monster_id": "rust_automaton",
    "name": "태엽 방벽",
    "description": "기본 보호막4%→7%, 최대2→3명.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "rust_automaton_special_1",
    "effect_values": {
      "behavior": {
        "ward_ratio": 0.07,
        "ward_count": 3
      }
    }
  },
  {
    "id": "rust_automaton_special_2",
    "monster_id": "rust_automaton",
    "name": "맞물린 톱니",
    "description": "아군 보호막 발동이 매3회→2회 공격.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "rust_automaton_special_2",
    "effect_values": {
      "behavior": {
        "ward_every": 2
      }
    }
  },
  {
    "id": "rust_automaton_special_3",
    "monster_id": "rust_automaton",
    "name": "덧댄 철판",
    "description": "최대체력25% 증가.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "rust_automaton_special_3",
    "effect_values": {
      "stat_multipliers": {
        "hp": 1.25
      }
    }
  },
  {
    "id": "iron_beetle_special_1",
    "monster_id": "iron_beetle",
    "name": "겹철 외피",
    "description": "등장 보호막40%→60%. 기존 개체는 증가분만1회 지급.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "iron_beetle_special_1",
    "effect_values": {
      "behavior": {
        "shield_ratio": 0.6
      }
    }
  },
  {
    "id": "iron_beetle_special_2",
    "monster_id": "iron_beetle",
    "name": "공성 뿔",
    "description": "첫 기본공격 피해140%→200%. 이미 소모한 첫 공격은 재충전하지 않음.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "iron_beetle_special_2",
    "effect_values": {
      "behavior": {
        "first_multiplier": 2.0
      }
    }
  },
  {
    "id": "iron_beetle_special_3",
    "monster_id": "iron_beetle",
    "name": "유연한 철관절",
    "description": "이동속도25% 증가.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "iron_beetle_special_3",
    "effect_values": {
      "runtime_stat_multipliers": {
        "speed_multiplier": 1.25
      }
    }
  },
  {
    "id": "lantern_wisp_special_1",
    "monster_id": "lantern_wisp",
    "name": "길 잃은 불씨",
    "description": "불씨탄의 추가 화상 피해30%→50%.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "lantern_wisp_special_1",
    "effect_values": {
      "behavior": {
        "burn_ratio": 0.5
      }
    }
  },
  {
    "id": "lantern_wisp_special_2",
    "monster_id": "lantern_wisp",
    "name": "긴 등불길",
    "description": "사거리360→460px·투사체속도315→420px/초.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "lantern_wisp_special_2",
    "effect_values": {
      "stat_overrides": {
        "attack_range": 460.0,
        "projectile_speed": 420.0
      }
    }
  },
  {
    "id": "lantern_wisp_special_3",
    "monster_id": "lantern_wisp",
    "name": "도깨비 심지",
    "description": "공격력25% 증가.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "lantern_wisp_special_3",
    "effect_values": {
      "stat_multipliers": {
        "damage": 1.25
      }
    }
  },
  {
    "id": "blade_mantis_special_1",
    "monster_id": "blade_mantis",
    "name": "월아 겹낫",
    "description": "매3번째 기본공격 피해180%→240%.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "blade_mantis_special_1",
    "effect_values": {
      "behavior": {
        "third_bonus": 1.4
      }
    }
  },
  {
    "id": "blade_mantis_special_2",
    "monster_id": "blade_mantis",
    "name": "사냥꾼의 본능",
    "description": "대상 체력이30% 이하이면 기본공격 피해25% 증가.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "blade_mantis_special_2",
    "effect_values": {
      "behavior": {
        "execute_threshold": 0.3,
        "execute_multiplier": 1.25
      }
    }
  },
  {
    "id": "blade_mantis_special_3",
    "monster_id": "blade_mantis",
    "name": "날선 관절",
    "description": "공격 간격15% 감소.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "blade_mantis_special_3",
    "effect_values": {
      "stat_multipliers": {
        "attack_cooldown": 0.85
      }
    }
  },
  {
    "id": "moss_deer_special_1",
    "monster_id": "moss_deer",
    "name": "무성한 녹각",
    "description": "기본 보호막6%→10%·보호 범위200→260px.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "moss_deer_special_1",
    "effect_values": {
      "behavior": {
        "ward_ratio": 0.1,
        "ward_radius": 260.0
      }
    }
  },
  {
    "id": "moss_deer_special_2",
    "monster_id": "moss_deer",
    "name": "신록의 맥동",
    "description": "보호막 발동이 매3회→2회 공격.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "moss_deer_special_2",
    "effect_values": {
      "behavior": {
        "ward_every": 2
      }
    }
  },
  {
    "id": "moss_deer_special_3",
    "monster_id": "moss_deer",
    "name": "숲길 걸음",
    "description": "이동속도20% 증가·최대체력15% 증가.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "moss_deer_special_3",
    "effect_values": {
      "runtime_stat_multipliers": {
        "speed_multiplier": 1.2
      },
      "stat_multipliers": {
        "hp": 1.15
      }
    }
  },
  {
    "id": "crystal_tortoise_special_1",
    "monster_id": "crystal_tortoise",
    "name": "겹수정 등딱지",
    "description": "등장 보호막30%→45%. 기존 개체는 증가분만1회 지급.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "crystal_tortoise_special_1",
    "effect_values": {
      "behavior": {
        "shield_ratio": 0.45
      }
    }
  },
  {
    "id": "crystal_tortoise_special_2",
    "monster_id": "crystal_tortoise",
    "name": "단단한 결정핵",
    "description": "최대체력20% 증가.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "crystal_tortoise_special_2",
    "effect_values": {
      "stat_multipliers": {
        "hp": 1.2
      }
    }
  },
  {
    "id": "crystal_tortoise_special_3",
    "monster_id": "crystal_tortoise",
    "name": "구르는 수정발",
    "description": "이동속도20% 증가.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "crystal_tortoise_special_3",
    "effect_values": {
      "runtime_stat_multipliers": {
        "speed_multiplier": 1.2
      }
    }
  },
  {
    "id": "ember_salamander_special_1",
    "monster_id": "ember_salamander",
    "name": "살아있는 잿불",
    "description": "화상 총피해 공격력25%→45%.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "ember_salamander_special_1",
    "effect_values": {
      "behavior": {
        "burn_ratio": 0.45
      }
    }
  },
  {
    "id": "ember_salamander_special_2",
    "monster_id": "ember_salamander",
    "name": "긴 불숨",
    "description": "사거리355→435·투사체속도340→420.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "ember_salamander_special_2",
    "effect_values": {
      "stat_overrides": {
        "attack_range": 435.0,
        "projectile_speed": 420.0
      }
    }
  },
  {
    "id": "ember_salamander_special_3",
    "monster_id": "ember_salamander",
    "name": "뜨거운 박동",
    "description": "공격 간격12% 감소.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "ember_salamander_special_3",
    "effect_values": {
      "stat_multipliers": {
        "attack_cooldown": 0.88
      }
    }
  },
  {
    "id": "frost_owl_special_1",
    "monster_id": "frost_owl",
    "name": "매서운 서리깃",
    "description": "기본탄 둔화18%→27%.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "frost_owl_special_1",
    "effect_values": {
      "behavior": {
        "slow_multiplier": 0.73
      }
    }
  },
  {
    "id": "frost_owl_special_2",
    "monster_id": "frost_owl",
    "name": "늦겨울의 숨",
    "description": "기본탄 둔화1초→1.4초.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "frost_owl_special_2",
    "effect_values": {
      "behavior": {
        "slow_duration": 1.4
      }
    }
  },
  {
    "id": "frost_owl_special_3",
    "monster_id": "frost_owl",
    "name": "찬바람 활공",
    "description": "이동속도15%·투사체속도310→390.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "frost_owl_special_3",
    "effect_values": {
      "runtime_stat_multipliers": {
        "speed_multiplier": 1.15
      },
      "stat_overrides": {
        "projectile_speed": 390.0
      }
    }
  },
  {
    "id": "thorn_dryad_special_1",
    "monster_id": "thorn_dryad",
    "name": "휘감는 가시",
    "description": "기본공격 둔화22%→32%.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "thorn_dryad_special_1",
    "effect_values": {
      "behavior": {
        "slow_multiplier": 0.68
      }
    }
  },
  {
    "id": "thorn_dryad_special_2",
    "monster_id": "thorn_dryad",
    "name": "깊은 뿌리",
    "description": "최대체력25% 증가.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "thorn_dryad_special_2",
    "effect_values": {
      "stat_multipliers": {
        "hp": 1.25
      }
    }
  },
  {
    "id": "thorn_dryad_special_3",
    "monster_id": "thorn_dryad",
    "name": "뻗어가는 덩굴",
    "description": "공격 사거리130→180.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "thorn_dryad_special_3",
    "effect_values": {
      "stat_overrides": {
        "attack_range": 180.0
      }
    }
  },
  {
    "id": "dusk_panther_special_1",
    "monster_id": "dusk_panther",
    "name": "황혼의 기습",
    "description": "첫 기본공격180%→230%. 이미 소모한 첫 공격은 복구하지 않음.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "dusk_panther_special_1",
    "effect_values": {
      "behavior": {
        "first_multiplier": 2.3
      }
    }
  },
  {
    "id": "dusk_panther_special_2",
    "monster_id": "dusk_panther",
    "name": "끝장을 보는 발톱",
    "description": "처형 발동 체력25%→35%, 추가피해20%→30%.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "dusk_panther_special_2",
    "effect_values": {
      "behavior": {
        "execute_threshold": 0.35,
        "execute_multiplier": 1.3
      }
    }
  },
  {
    "id": "dusk_panther_special_3",
    "monster_id": "dusk_panther",
    "name": "포식의 숨결",
    "description": "실제 감소시킨 체력의12% 회복.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "dusk_panther_special_3",
    "effect_values": {
      "behavior": {
        "lifesteal": 0.12
      }
    }
  },
  {
    "id": "rune_sentinel_special_1",
    "monster_id": "rune_sentinel",
    "name": "이중 방호룬",
    "description": "등장 보호막20%→35%. 기존 개체는 증가분만1회 지급.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "rune_sentinel_special_1",
    "effect_values": {
      "behavior": {
        "shield_ratio": 0.35
      }
    }
  },
  {
    "id": "rune_sentinel_special_2",
    "monster_id": "rune_sentinel",
    "name": "공명 각인",
    "description": "공격 연동 아군 보호막6%→10%.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "rune_sentinel_special_2",
    "effect_values": {
      "behavior": {
        "ward_ratio": 0.1
      }
    }
  },
  {
    "id": "rune_sentinel_special_3",
    "monster_id": "rune_sentinel",
    "name": "넓은 수호진",
    "description": "공격 연동 보호 범위200→270px·대상2→3명.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "rune_sentinel_special_3",
    "effect_values": {
      "behavior": {
        "ward_radius": 270.0,
        "ward_count": 3
      }
    }
  },
  {
    "id": "venom_scorpion_special_1",
    "monster_id": "venom_scorpion",
    "name": "농축 독낭",
    "description": "독 총피해 현재체력0.2%→0.35%.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "venom_scorpion_special_1",
    "effect_values": {
      "behavior": {
        "poison_ratio": 0.0035
      }
    }
  },
  {
    "id": "venom_scorpion_special_2",
    "monster_id": "venom_scorpion",
    "name": "가벼운 독침",
    "description": "사거리300→390·투사체속도285→390.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "venom_scorpion_special_2",
    "effect_values": {
      "stat_overrides": {
        "attack_range": 390.0,
        "projectile_speed": 390.0
      }
    }
  },
  {
    "id": "venom_scorpion_special_3",
    "monster_id": "venom_scorpion",
    "name": "탈피 갑각",
    "description": "최대체력20% 증가.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "venom_scorpion_special_3",
    "effect_values": {
      "stat_multipliers": {
        "hp": 1.2
      }
    }
  },
  {
    "id": "moon_moth_special_1",
    "monster_id": "moon_moth",
    "name": "짙은 달가루",
    "description": "공격 연동 아군 보호막8%→12%.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "moon_moth_special_1",
    "effect_values": {
      "behavior": {
        "ward_ratio": 0.12
      }
    }
  },
  {
    "id": "moon_moth_special_2",
    "monster_id": "moon_moth",
    "name": "만월의 박동",
    "description": "아군 보호막 발동 매3회→2회 공격.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "moon_moth_special_2",
    "effect_values": {
      "behavior": {
        "ward_every": 2
      }
    }
  },
  {
    "id": "moon_moth_special_3",
    "monster_id": "moon_moth",
    "name": "은빛 비늘날개",
    "description": "최대체력15%·이동속도15% 증가.",
    "augment_type": "special",
    "max_stack": 1,
    "icon": "",
    "effect_type": "moon_moth_special_3",
    "effect_values": {
      "stat_multipliers": {
        "hp": 1.15
      },
      "runtime_stat_multipliers": {
        "speed_multiplier": 1.15
      }
    }
  }
]
