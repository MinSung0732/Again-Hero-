extends RefCounted
class_name MonsterCatalog

const ORDER := [
	"slime",
	"spider",
	"orc",
	"bomb_rat",
	"skeleton",
	"skeleton_archer",
	"kobolt",
	"bat",
	"goblin",
	"goblin_thrower",
	"ghost",
	"banshee",
	"dullahan",
	"kraken",
	"medusa",
	"mummy",
	"powwow_mummy",
	"scorpion",
	"succubus",
	"wolf",
]

const DULLAHAN_BEHAVIOR := preload("res://src/data/dullahan_behavior_catalog.gd")

const KRAKEN_BEHAVIOR := preload("res://src/data/kraken_behavior_catalog.gd")
const MEDUSA_BEHAVIOR := preload("res://src/data/medusa_behavior_catalog.gd")
const MONSTERS := {
	"wolf": {
		"id":"wolf", "name":"늑대", "role":"swarm", "family":"wolf", "species":"beast", "grade":"advanced", "rarity":"uncommon", "attack_type":"melee",
		"base_cost":5.0, "summon_exp":5.0, "default_unlocked":false,
		"description":"빠른 근접 2연격(공격력을 절반씩 분배). 반경250 내 아군 늑대 사망 시1초 하울링 후10초 공격력+15%. 중첩 없이 갱신, 남은 버프2초 이하에서만 재시전.",
		"base_stats":preload("res://src/data/wolf_behavior_catalog.gd").BASE,
		"card_icon_path":"res://assets/art/monsters/wolf/frames/idle_01.png",
		"ground_shadow":{"size":Vector2(80,20), "offset_y":43.0, "opacity":0.35},
		"special_augment_ids":["wolf_crushing_fang","wolf_blood_scent","wolf_iron_howl"],
		"elite_visual":preload("res://src/data/wolf_behavior_catalog.gd").ELITE_VISUAL,
		"elite_skills":[{"runtime":"monster", "id":"elite_wolf_pack_hunt", "name":"무리사냥", "description":"1초간 시전 후 뒤쪽에서 이속+30% 일반 늑대12마리 소환. 증강 적용, 분산 생성.", "initial_cooldown":5.0, "cooldown":20.0, "retry_interval":0.25}],
		"scene":preload("res://src/monsters/Wolf.tscn"),
	},
	"succubus": {
		"id":"succubus", "name":"서큐버스", "role":"controller", "family":"succubus", "species":"humanoid", "grade":"legendary", "rarity":"legendary", "attack_type":"melee",
		"base_cost":13.5, "summon_exp":13.5, "default_unlocked":false,
		"description":"공용 적중 15회에 2초 매혹(공격·기술 봉인, 시전자 접근, 이속 -40%). 종료 후 7초 면역. 매혹 대상 추가 피해15%. 치명 피해 시1회 생존하고3초 잠입(행동 정지·무적·반투명).",
		"base_stats":preload("res://src/data/succubus_behavior_catalog.gd").BASE,
		"card_icon_path":"res://assets/art/monsters/Succubus/frames/idle_01.png",
		"ground_shadow":{"size":Vector2(72,22), "offset_y":43.0, "opacity":0.35},
		"special_augment_ids":["succubus_shadow_recovery","succubus_shadow_ambush","succubus_danger_sense"],
		"elite_visual":preload("res://src/data/succubus_behavior_catalog.gd").ELITE_VISUAL,
		"elite_skills":[
			{"runtime":"monster", "id":"elite_succubus_cut", "kind":"cut", "name":"절개", "description":"용사 뒤로 순간이동 후 공격력150% 타격.", "initial_cooldown":0.0, "cooldown":15.0, "damage_multiplier":1.5, "retry_interval":0.25},
			{"runtime":"monster", "id":"elite_succubus_drain", "kind":"drain", "name":"정기흡수", "description":"이전 흡수 이후 실제 준 피해를 비우고55% 회복.", "initial_cooldown":6.0, "cooldown":20.0, "heal_ratio":0.55, "retry_interval":0.25},
			{"runtime":"monster", "id":"elite_succubus_waltz", "kind":"waltz", "name":"유혹의 왈츠", "description":"받는 피해50% 감소.2.5초간0.5초마다 무작위 각도로 순간이동·타격(총 공격력200%), 실제 준 피해40% 회복.", "initial_cooldown":10.0, "cooldown":60.0, "duration":2.5, "interval":0.5, "damage_multiplier":2.0, "heal_ratio":0.4, "damage_taken_multiplier":0.5, "alpha":0.5, "retry_interval":0.25}
		],
		"scene":preload("res://src/monsters/Succubus.tscn"),
	},
	"scorpion": {
		"id":"scorpion", "name":"전갈", "role":"swarm", "family":"scorpion", "species":"beast", "grade":"normal", "rarity":"common", "attack_type":"melee",
		"base_cost":3.0, "summon_exp":3.0, "default_unlocked":false,
		"description":"빠른 근접 물량 몬스터. 실제 준 피해만큼 10초간 중독 추가 피해. 같은 개체·타격별 중독 중첩/갱신 없음.",
		"base_stats":preload("res://src/data/scorpion_behavior_catalog.gd").BASE,
		"card_icon_path":"res://assets/art/monsters/Scorpion/frames/idle_01.png",
		"ground_shadow":{"size":Vector2(76,20), "offset_y":34.0, "opacity":0.35},
		"special_augment_ids":["scorpion_rapid_venom","scorpion_twin_sting","scorpion_death_swamp"],
		"elite_visual":preload("res://src/data/scorpion_behavior_catalog.gd").ELITE_VISUAL,
		"elite_skills":[{"runtime":"monster", "id":"elite_scorpion_consume", "name":"약육강식", "description":"반경 250 내 가까운 일반 전갈 1마리 섭취. 최대 체력·공격력·이속·초당 공격횟수 합산. 섭취 사망은 경험치·킬 없음.", "initial_cooldown":3.0, "cooldown":7.0, "radius":250.0, "retry_interval":0.25}],
		"scene":preload("res://src/monsters/Scorpion.tscn"),
	},
	"powwow_mummy": {
		"id":"powwow_mummy", "name":"미라 주술사", "role":"ranged", "family":"powwow_mummy", "species":"undead", "grade":"rare", "rarity":"rare", "attack_type":"ranged",
		"base_cost":4.5, "summon_exp":4.5, "default_unlocked":false,
		"description":"사거리 지름 475, 투사체 속도 275. 20초마다 다른 아군 1개체에 무작위 버프: 용기(10초 공격 +15%, 실드 최대 HP 10%) / 회복(잃은 HP 5%) / 날렵(10초 이속 +50%). 같은 버프 중첩 없이 갱신.",
		"base_stats":preload("res://src/data/powwow_mummy_behavior_catalog.gd").BASE,
		"card_icon_path":"res://assets/art/monsters/powwowmummy/frames/idle_01.png",
		"ground_shadow":{"size":Vector2(68,22),"offset_y":41.0,"opacity":0.35},
		"special_augment_ids":["powwow_mummy_brave_chant","powwow_mummy_restoring_chant","powwow_mummy_quick_ritual"],
		"elite_visual":preload("res://src/data/powwow_mummy_behavior_catalog.gd").ELITE_VISUAL,
		"elite_skills":[{"runtime":"monster","passive":true,"id":"elite_powwow_mummy_multicast","name":"다중시전","description":"버프 주기마다 3종을 서로 다른 아군에게 시전. 실제 기본공격 적중마다 다음 버프 대기 -1초.","initial_cooldown":0.0,"cooldown":0.0,"hit_cooldown_reduction":1.0}],
		"scene":preload("res://src/monsters/PowwowMummy.tscn"),
	},
	"mummy": {
		"id":"mummy", "name":"미라", "role":"tank", "family":"mummy", "species":"undead", "grade":"advanced", "rarity":"uncommon", "attack_type":"melee",
		"base_cost":7.0, "summon_exp":7.0, "default_unlocked":false,
		"description":"소환 시 최대 체력 50%의 실드. 체력·공격·이속·공속 중간인 근거리 탱커.",
		"base_stats":preload("res://src/data/mummy_behavior_catalog.gd").BASE,
		"card_icon_path":"res://assets/art/monsters/mummy/frames/idle_01.png",
		"ground_shadow":{"size":Vector2(70,22), "offset_y":41.0, "opacity":0.35},
		"special_augment_ids":["mummy_eternal_bandage","mummy_broken_seal","mummy_dry_wound"],
		"elite_visual":preload("res://src/data/mummy_behavior_catalog.gd").ELITE_VISUAL,
		"elite_skills":[{"runtime":"monster", "passive":true, "id":"elite_mummy_curse", "name":"미라의 저주", "description":"실제 타격 시 2초간 대상 받는 피해 +20% (갱신). 접근 이동속도 상시 +30%.", "initial_cooldown":0.0, "cooldown":0.0, "duration":2.0, "damage_increase":0.20, "move_speed_multiplier":1.30}],
		"scene":preload("res://src/monsters/Mummy.tscn"),
	},
	"medusa": {
		"id":"medusa", "name":"메두사", "role":"controller", "family":"medusa", "species":"humanoid", "grade":"rare", "rarity":"rare", "attack_type":"melee",
		"base_cost":7.0, "summon_exp":7.0, "default_unlocked":false,
		"description":"몬스터와 충돌·밀어내기 없음. 추적 중 초당 이속 +10%, 최대 2배. 실제 적중 시 초기화. 메두사 공용 적중 10스택에 2.5초 석화 (이동만 불가). 석화마다 필요 스택 +1.",
		"base_stats":MEDUSA_BEHAVIOR.BASE,
		"card_icon_path":"res://assets/art/monsters/medusa/frames/idle_01.png",
		"ground_shadow":{"size":Vector2(66,20), "offset_y":39.0, "opacity":0.35},
		"special_augment_ids":["medusa_serpent_momentum","medusa_stone_shatter","medusa_stone_residue"],
		"elite_visual":MEDUSA_BEHAVIOR.ELITE_VISUAL,
		"elite_skills":[{"runtime":"monster", "passive":true, "id":"elite_medusa_hidden_poison", "name":"숨겨진 독", "description":"반경 250 내 메두사에 중독 타격 부여. 실제 피해를 5초에 걸쳐 추가 적용. 같은 개체 중첩·갱신 없음, 다른 개체는 별도 중독.", "initial_cooldown":0.0, "cooldown":0.0, "radius":250.0, "duration":5.0, "refresh_interval":0.2, "buff_linger":0.35}],
		"scene":preload("res://src/monsters/Medusa.tscn"),
	},
	"kraken": {
		"id":"kraken", "name":"크라켄", "role":"ranged", "family":"kraken", "species":"beast", "grade":"legendary", "rarity":"legendary", "attack_type":"ranged",
		"base_cost":15.0, "summon_exp":15.0, "default_unlocked":false,
		"can_be_elite":false, "can_be_giant":false, "spawn_at_max_range":true,
		"description":"고정형 · 지름 2000 사거리. 용사 주변 지름 200 안에 촉수 3개를 2초간 순차 타격 (각 공격력의 1/3). 실제 적중 3회마다 개체 공격력 +0.1%. 사망 시 자신 중심 8방향 촉수 일격. 엘리트·대형몹 없음.",
		"base_stats":KRAKEN_BEHAVIOR.BASE,
		"card_icon_path":"res://assets/art/monsters/Kraken/frames/idle_01.png",
		"ground_shadow":{"size":Vector2(160,40), "offset_y":65.0, "opacity":0.38},
		"special_augment_ids":["kraken_abyss_escape", "kraken_tentacle_barrage", "kraken_abyss_titan"],
		"scene":preload("res://src/monsters/Kraken.tscn"),
	},
	"dullahan": {
		"id": "dullahan", "name": "망령 기사", "role": "tank", "family": "dullahan", "species": "undead", "grade": "legendary", "rarity": "legendary", "attack_type": "melee",
		"base_cost": 12.0, "summon_exp": 12.0, "default_unlocked": false,
		"description": "사망 시 1회 15% 체력으로 부활. 실제 준 피해의 40% 회복. HP 20% 이하에서 위험감지: 이속 +225%로 이탈 후 3초간 휴식하며 HP 50%까지 회복 (쿨 20초).",
		"base_stats": DULLAHAN_BEHAVIOR.BASE,
		"passive": DULLAHAN_BEHAVIOR.PASSIVE,
		"danger_sense": DULLAHAN_BEHAVIOR.DANGER,
		"card_icon_path": "res://assets/art/monsters/Dullahan/frames/idle_01.png",
		"ground_shadow": {"size": Vector2(148, 44), "offset_y": 74.0, "opacity": 0.38},
		"special_augment_ids": ["dullahan_dead_wall", "dullahan_soul_shackles", "dullahan_immortal_thirst"],
		"elite_visual": {"mode": "frames", "asset_dir": "res://assets/art/elitemonster/Dullahan/frames", "target_height": 280.0, "animations": {
			"idle": {"prefix":"idle", "count":4, "fps":6.0, "loop":true}, "move": {"prefix":"walk", "count":6, "fps":9.0, "loop":true},
			"attack": {"prefix":"atk", "count":4, "fps":10.0, "loop":false}, "hit": {"files":["hit_01.png", "hit-02.png"], "count":2, "fps":12.0, "loop":false},
			"death": {"prefix":"dead", "count":7, "fps":10.0, "loop":false}}},
		"elite_skills": [
			{"runtime":"monster", "id":"elite_dullahan_march", "name":"진격", "description":"반경 250 내 0레벨·무증강 해골 전사/궁병 10마리를 5초간 순차 소환. 죽음 역재생 후 행동 시작.", "initial_cooldown":10.0, "cooldown":40.0, "count":10, "interval":0.5, "radius":250.0, "summon_ids":["skeleton", "skeleton_archer"], "summon_modifiers":{"fixed_base_stats":true}},
			{"runtime":"monster", "id":"elite_dullahan_charge", "name":"망령돌진", "description":"소환 시 1회, 5초간 접근 이동속도 200%.", "initial_cooldown":0.0, "cooldown":0.0, "once":true, "duration":5.0, "speed_multiplier":2.0},
			{"runtime":"monster", "id":"elite_dullahan_slam", "name":"강타", "description":"붉은 예고 후 공격 프레임 종료 시 공격력 2배 피해와 1.5초 기절.", "initial_cooldown":5.0, "cooldown":30.0, "windup":0.35, "damage_multiplier":2.0, "stun_duration":1.5}
		],
		"scene": preload("res://src/monsters/Dullahan.tscn"),
	},
	"banshee": {
		"id": "banshee", "name": "밴시", "role": "controller",
		"family": "banshee", "species": "undead", "grade": "advanced", "rarity": "uncommon",
		"attack_type": "melee", "base_cost": 6.5, "summon_exp": 6.5,
		"default_unlocked": false,
		"description": "빠르게 배회하다 공격 예고 후 3배속 돌진. 적중 시 1초간 10% 둔화와 현재 체력 0.5% 추가 피해.",
		"base_stats": {
			"max_hp": 88, "move_speed": 110.0, "attack_damage": 4,
			"attack_range": 62.0, "attack_cooldown": 1.0, "exp_reward": 26,
			"detection_range": 420.0, "charge_speed_multiplier": 3.0,
			"slow_multiplier": 0.90, "slow_duration": 1.0,
		},
		"card_icon_path": "res://assets/art/monsters/Banshee/frames/idle_01.png",
		"ground_shadow": {"size": Vector2(58, 18), "offset_y": 27.0, "opacity": 0.34},
		"special_augment_ids": ["banshee_bleeding", "banshee_charge_stealth", "banshee_death_possession"],
		"elite_visual": {
			"mode": "frames", "asset_dir": "res://assets/art/elitemonster/Banshee/frames", "target_height": 112.0,
			"animations": {
				"idle": {"prefix": "idle", "count": 4, "fps": 8.0, "loop": true},
				"move": {"prefix": "walk", "count": 6, "fps": 11.0, "loop": true},
				"attack": {"prefix": "atk", "count": 6, "fps": 12.0, "loop": false},
				"hit": {"prefix": "hit", "count": 2, "fps": 14.0, "loop": false},
				"death": {"prefix": "dead", "count": 5, "fps": 10.0, "loop": false},
			},
		},
		"elite_skills": [{
			"id": "elite_banshee_possession", "name": "빙의",
			"description": "최대 체력 20%를 소모해 2초 공포. 공포 종료 후 3초간 빙의 불가.",
			"initial_cooldown": 5.0, "cooldown": 20.0,
			"duration": 2.0, "self_max_hp_cost": 0.20,
		}],
		"scene": preload("res://src/monsters/Banshee.tscn"),
	},
	"slime": {
		"id": "slime",
		"name": "슬라임",
		"role": "swarm",
		"species": "liquid",
		"grade": "normal",
		"attack_type": "melee",
		"base_cost": 3.0,
		"summon_exp": 3.0,
		"base_stats": {
			"max_hp": 72,
			"move_speed": 122.0,
			"attack_damage": 9,
			"attack_range": 72.0,
			"attack_cooldown": 1.10,
		},
		"default_unlocked": true,
		"rarity": "common",
		"card_icon_path": "res://assets/art/monsters/slime/frames/idle_01.png",
		"ground_shadow": {
			"size": Vector2(62.0, 20.0),
			"offset_y": 27.0,
			"opacity": 0.48,
		},
		"special_augment_ids": [
			"slime_cell_division",
			"slime_residual_mucus",
			"slime_pack_instinct",
		],
		"elite_visual": {
			"mode": "frames",
			"asset_dir": "res://assets/art/elitemonster/slime/frames",
			"target_height": 80.0,
			"animations": {
				"idle": {"prefix": "idle", "count": 4, "fps": 6.0, "loop": true},
				"move": {"prefix": "walk", "count": 4, "fps": 10.0, "loop": true},
				"attack": {"prefix": "atk", "count": 3, "fps": 14.0, "loop": false},
				"hit": {"prefix": "hit", "count": 4, "fps": 14.0, "loop": false},
				"death": {"prefix": "death", "count": 4, "fps": 10.0, "loop": false},
			},
		},
		"elite_skills": [
			{
				"id": "elite_slime_proliferation",
				"name": "분열증식",
				"description": "일반 슬라임 12기 투척 · 0.25초 간격",
				"initial_cooldown": 3.0,
				"cooldown": 20.0,
				"spawn_count": 12,
				"spawn_interval": 0.25,
				"launch_distance_min": 105.0,
				"launch_distance_max": 190.0,
				"arc_duration": 0.55,
				"arc_height": 82.0,
			},
		],
		"scene": preload("res://src/monsters/Slime.tscn"),
	},
	"spider": {
		"id": "spider",
		"name": "거미",
		"role": "controller",
		"species": "beast",
		"grade": "normal",
		"attack_type": "ranged",
		"base_cost": 7.0,
		"summon_exp": 7.0,
		"base_stats": {
			"max_hp": 45,
			"move_speed": 150.0,
			"attack_damage": 5,
			"attack_range": 300.0,
			"attack_cooldown": 1.35,
			"slow_multiplier": 0.72,
			"slow_duration": 1.5,
		},
		"default_unlocked": true,
		"rarity": "common",
		"card_icon_path": "res://assets/art/monsters/spider/frames/idle_01.png",
		"ground_shadow": {
			"size": Vector2(68.0, 22.0),
			"offset_y": 31.0,
			"opacity": 0.50,
		},
		"special_augment_ids": [
			"spider_triple_web",
			"spider_sticky_web",
			"spider_binding",
		],
		"elite_visual": {
			"mode": "sequence",
			"asset_dir": "res://assets/art/elitemonster/spider/frames",
			"target_height": 88.0,
			"animations": {
				"idle": {"start": 1, "count": 4, "fps": 6.0, "loop": true},
				"move": {"start": 5, "count": 6, "fps": 10.0, "loop": true},
				"attack": {"start": 11, "count": 8, "fps": 14.0, "loop": false},
				"death": {"start": 19, "count": 4, "fps": 10.0, "loop": false},
			},
		},
		"elite_skills": [
			{
				"id": "elite_spider_web_nest",
				"name": "거미집",
				"description": "지름 500 · 5초 · 용사 이속 -50% · 아군 이속 +15%",
				"initial_cooldown": 3.0,
				"cooldown": 25.0,
				"duration": 5.0,
				"radius": 250.0,
				"hero_slow_multiplier": 0.50,
				"monster_speed_multiplier": 1.15,
				"tick_interval": 0.20,
				"effect_path": "res://assets/art/monsters/spider/frames/effect/frame_07.png",
			},
		],
		"scene": preload("res://src/monsters/Spider.tscn"),
	},
	"orc": {
		"id": "orc",
		"name": "오크",
		"role": "tank",
		"species": "beast",
		"grade": "normal",
		"attack_type": "melee",
		"base_cost": 18.0,
		"summon_exp": 18.0,
		"base_stats": {
			"max_hp": 140,
			"move_speed": 78.0,
			"attack_damage": 18,
			"attack_range": 82.0,
			"attack_cooldown": 1.45,
		},
		"default_unlocked": true,
		"rarity": "common",
		"card_icon_path": "res://assets/art/monsters/orc/frames/idle_01.png",
		"ground_shadow": {
			"size": Vector2(82.0, 26.0),
			"offset_y": 38.0,
			"opacity": 0.52,
		},
		"special_augment_ids": [
			"orc_berserk",
			"orc_rage_stacks",
			"orc_last_charge",
		],
		"elite_visual": {
			"mode": "sequence",
			"asset_dir": "res://assets/art/elitemonster/orc/frames",
			"target_height": 104.0,
			"animations": {
				"idle": {"start": 1, "count": 4, "fps": 6.0, "loop": true},
				"move": {"start": 5, "count": 6, "fps": 10.0, "loop": true},
				"attack": {"start": 11, "count": 6, "fps": 14.0, "loop": false},
				"hit": {"start": 17, "count": 4, "fps": 14.0, "loop": false},
				"death": {"start": 21, "count": 3, "fps": 10.0, "loop": false},
			},
		},
		"elite_skills": [
			{
				"id": "elite_orc_frenzy",
				"name": "광분",
				"description": "돌진 피해 150% · 1초간 99% 둔화",
				"initial_cooldown": 0.0,
				"cooldown": 20.0,
				"charge_speed_multiplier": 5.0,
				"max_charge_duration": 2.5,
				"damage_multiplier": 1.50,
				"slow_multiplier": 0.01,
				"slow_duration": 1.0,
			},
		],
		"scene": preload("res://src/monsters/Orc.tscn"),
	},
	"skeleton": {
		"id": "skeleton",
		"name": "해골 전사",
		"role": "tank",
		"species": "undead",
		"grade": "normal",
		"attack_type": "melee",
		"base_cost": 9.0,
		"summon_exp": 9.0,
		"base_stats": {
			"max_hp": 105,
			"move_speed": 112.0,
			"attack_damage": 10,
			"attack_range": 78.0,
			"attack_cooldown": 1.25,
			"hits_per_attack": 2,
			"hit_damage_multiplier": 1.0,
			"second_hit_delay": 0.14,
		},
		"default_unlocked": false,
		"rarity": "common",
		"card_icon_path": "res://assets/art/monsters/skelleton/frames/idle_01.png",
		"ground_shadow": {
			"size": Vector2(72.0, 23.0),
			"offset_y": 60.0,
			"opacity": 0.50,
		},
		"special_augment_ids": [
			"skeleton_return_of_dead",
			"skeleton_bone_bond",
			"skeleton_necrotic_guard",
		],
		"elite_visual": {
			"mode": "frames",
			"asset_dir": "res://assets/art/elitemonster/skelleton/frames",
			"target_height": 170.0,
			"animations": {
				"idle": {"prefix": "idle", "count": 4, "fps": 6.0, "loop": true},
				"move": {"prefix": "walk", "count": 6, "fps": 10.0, "loop": true},
				"attack": {"prefix": "attack", "count": 6, "fps": 14.0, "loop": false},
				"hit": {"prefix": "hit", "count": 3, "fps": 14.0, "loop": false},
				"death": {"prefix": "dead", "count": 4, "fps": 10.0, "loop": false},
			},
		},
		"elite_skills": [
			{
				"id": "elite_skeleton_ambush",
				"name": "암습",
				"description": "2초 은신 · 받는 피해 -50% · 다음 2타 피해 +50%",
				"initial_cooldown": 2.0,
				"cooldown": 15.0,
				"duration": 2.0,
				"damage_taken_multiplier": 0.50,
				"attack_damage_multiplier": 1.50,
				"opacity": 0.32,
			},
		],
		"scene": preload("res://src/monsters/Skeleton.tscn"),
	},
	"skeleton_archer": {
		"id": "skeleton_archer",
		"name": "해골 궁병",
		"role": "ranged",
		"species": "undead",
		"grade": "normal",
		"attack_type": "ranged",
		"base_cost": 7.5,
		"summon_exp": 7.5,
		"base_stats": {
			"max_hp": 48,
			"move_speed": 88.0,
			"attack_damage": 8,
			"attack_range": 137.5,
			"attack_range_diameter": 275.0,
			"attack_cooldown": 1.55,
			"projectile_speed": 300.0,
			"projectile_range": 190.0,
		},
		"default_unlocked": false,
		"rarity": "common",
		"card_icon_path": "res://assets/art/monsters/skelletonarcher/frames/idle_01.png",
		"ground_shadow": {
			"size": Vector2(64.0, 20.0),
			"offset_y": 44.0,
			"opacity": 0.48,
		},
		"special_augment_ids": [
			"skeleton_archer_power_shot",
			"skeleton_archer_revive",
			"skeleton_archer_triple_shot",
		],
		"elite_visual": {
			"mode": "frames",
			"asset_dir": "res://assets/art/elitemonster/skelletonarcher/frames",
			"target_height": 112.0,
			"animations": {
				"idle": {"prefix": "idle", "count": 4, "fps": 6.0, "loop": true},
				"move": {"prefix": "walk", "count": 5, "fps": 9.0, "loop": true},
				"attack": {"prefix": "atk", "count": 7, "fps": 14.0, "loop": false},
				"hit": {"prefix": "hit", "count": 3, "fps": 14.0, "loop": false},
				"death": {"prefix": "dead", "count": 5, "fps": 10.0, "loop": false},
			},
		},
		"elite_skills": [
			{
				"id": "elite_skeleton_archer_arrow_rain",
				"name": "화살비",
				"description": "지름 275 · 화살 12발×3회 · 피해 130% · 1초간 25% 둔화",
				"initial_cooldown": 2.0,
				"cooldown": 17.0,
				"radius": 137.5,
				"telegraph_delay": 0.25,
				"wave_interval": 0.35,
				"wave_count": 3,
				"arrows_per_wave": 12,
				"damage_multiplier": 1.30,
				"slow_multiplier": 0.75,
				"slow_duration": 1.0,
				"line_width": 2.0,
				"line_segments": 32,
				"arrow_fall_distance": 170.0,
				"arrow_fall_duration": 0.22,
				"arrow_target_size": 52.0,
				"arrow_texture_path": "res://assets/art/elitemonster/skelletonarcher/frames/effect1/normal_01.png",
			},
		],
		"scene": preload("res://src/monsters/SkeletonArcher.tscn"),
	},
	"kobolt": {
		"id": "kobolt",
		"name": "코볼트",
		"role": "ranged",
		"species": "beast",
		"grade": "normal",
		"attack_type": "ranged",
		"base_cost": 10.0,
		"summon_exp": 10.0,
		"base_stats": {
			"max_hp": 95,
			"attack_damage": 28,
			"attack_range": 750.0,
			"attack_range_diameter": 1500.0,
			"attack_cooldown": 1.80,
			"projectile_speed": 385.0,
			"projectile_range": 750.0,
		},
		"default_unlocked": false,
		"rarity": "common",
		"card_icon_path": "res://assets/art/monsters/kobolt/frames/idle_01.png",
		"ground_shadow": {
			"size": Vector2(70.0, 22.0),
			"offset_y": 32.0,
			"opacity": 0.50,
		},
		"special_augment_ids": [
			"kobolt_projectile_speed",
			"kobolt_unlimited_range",
			"kobolt_giant_fusion",
		],
		"elite_visual": {
			"mode": "frames",
			"asset_dir": "res://assets/art/elitemonster/kobolt/frames",
			"target_height": 124.0,
			"animations": {
				"idle": {"prefix": "idle", "count": 4, "fps": 6.0, "loop": true},
				"attack": {"prefix": "atk", "count": 4, "fps": 14.0, "loop": false},
				"hit": {"prefix": "hit", "count": 2, "fps": 14.0, "loop": false},
				"death": {"prefix": "dead", "count": 3, "fps": 10.0, "loop": false},
			},
		},
		"elite_skills": [
			{
				"id": "elite_kobolt_fighting_spirit",
				"name": "투쟁심",
				"description": "5초간 공격속도 +60%",
				"initial_cooldown": 2.0,
				"cooldown": 10.0,
				"duration": 5.0,
				"attack_speed_multiplier": 1.60,
				"tint": Color(1.0, 0.68, 0.68, 1.0),
			},
		],
		"scene": preload("res://src/monsters/Kobolt.tscn"),
	},
	"bat": {
		"id": "bat",
		"name": "박쥐",
		"role": "swarm",
		"species": "beast",
		"grade": "normal",
		"attack_type": "melee",
		"base_cost": 3.0,
		"summon_exp": 3.0,
		"base_stats": {
			"max_hp": 72,
			"move_speed": 72.0,
			"attack_damage": 6,
			"attack_range": 62.0,
			"attack_cooldown": 0.62,
			"detection_range": 420.0,
			"charge_speed_multiplier": 3.75,
		},
		"default_unlocked": false,
		"rarity": "common",
		"card_icon_path": "res://assets/art/monsters/bat/frames/idle_01.png",
		"ground_shadow": {
			"size": Vector2(58.0, 18.0),
			"offset_y": 27.0,
			"opacity": 0.42,
		},
		"special_augment_ids": [
			"bat_lifesteal",
			"bat_permanent_charge",
			"bat_echo_summon",
		],
		"elite_visual": {
			"mode": "frames",
			"asset_dir": "res://assets/art/elitemonster/bat/frames",
			"target_height": 112.0,
			"animations": {
				"idle": {"prefix": "idle", "count": 4, "fps": 8.0, "loop": true},
				"move": {"prefix": "walk", "count": 6, "fps": 11.0, "loop": true},
				"attack": {"prefix": "atk", "count": 6, "fps": 16.0, "loop": false},
				"hit": {"prefix": "hit", "count": 3, "fps": 14.0, "loop": false},
				"death": {"prefix": "dead", "count": 4, "fps": 10.0, "loop": false},
			},
		},
		"elite_skills": [
			{
				"id": "elite_bat_poison_fang",
				"name": "독이빨",
				"description": "타격 시 3초 독 · 현재 HP의 5% 피해 · 재타격 갱신",
				"passive": true,
				"initial_cooldown": 0.0,
				"duration": 3.0,
				"total_current_hp_ratio": 0.05,
				"tick_interval": 0.50,
			},
		],
		"scene": preload("res://src/monsters/Bat.tscn"),
	},
	"goblin": {
		"id": "goblin",
		"name": "고블린",
		"role": "swarm",
		"species": "beast",
		"family": "goblin",
		"grade": "normal",
		"attack_type": "melee",
		"base_cost": 5.4,
		"summon_exp": 5.4,
		"base_stats": {
			"max_hp": 84,
			"move_speed": 155.0,
			"attack_damage": 7,
			"attack_range": 68.0,
			"attack_cooldown": 0.72,
		},
		"default_unlocked": false,
		"rarity": "common",
		"card_icon_path": "res://assets/art/monsters/goblin/frames/idle_01.png",
		"ground_shadow": {
			"size": Vector2(62.0, 20.0),
			"offset_y": 30.0,
			"opacity": 0.48,
		},
		"special_augment_ids": [
			"goblin_spawn_stealth",
			"goblin_survivor_growth",
			"goblin_pack_mastery",
		],
		"elite_visual": {
			"mode": "frames",
			"asset_dir": "res://assets/art/elitemonster/goblin/frames",
			"target_height": 118.0,
			"animations": {
				"idle": {"prefix": "idle", "count": 4, "fps": 7.0, "loop": true},
				"move": {"prefix": "walk", "count": 6, "fps": 11.0, "loop": true},
				"attack": {"prefix": "atk", "count": 6, "fps": 16.0, "loop": false},
				"hit": {"prefix": "hit", "count": 3, "fps": 14.0, "loop": false},
				"death": {"prefix": "dead", "count": 4, "fps": 10.0, "loop": false},
			},
		},
		"elite_skills": [
			{
				"id": "elite_goblin_commander",
				"name": "지휘관",
				"description": "지름 600 · 고블린 이속 +15% · 5초마다 HP 10% 쉴드",
				"passive": true,
				"runtime_tick": true,
				"initial_cooldown": 0.0,
				"radius": 300.0,
				"aura_tick_interval": 0.20,
				"shield_refresh_interval": 5.0,
				"shield_max_hp_ratio": 0.10,
				"speed_multiplier": 1.15,
				"line_width": 2.0,
				"line_segments": 48,
			},
		],
		"scene": preload("res://src/monsters/Goblin.tscn"),
	},
	"goblin_thrower": {
		"id": "goblin_thrower",
		"name": "고블린투척병",
		"role": "ranged",
		"species": "beast",
		"family": "goblin",
		"grade": "normal",
		"attack_type": "ranged",
		"base_cost": 5.4,
		"summon_exp": 5.4,
		"base_stats": {
			"max_hp": 56,
			"move_speed": 82.0,
			"attack_damage": 7,
			"attack_range": 275.0,
			"attack_range_diameter": 550.0,
			"attack_cooldown": 1.20,
			"projectile_speed": 380.0,
			"projectile_range": 340.0,
		},
		"default_unlocked": false,
		"rarity": "common",
		"card_icon_path": "res://assets/art/monsters/goblinthrower/frames/idle_01.png",
		"ground_shadow": {
			"size": Vector2(62.0, 20.0),
			"offset_y": 30.0,
			"opacity": 0.48,
		},
		"special_augment_ids": [
			"goblin_thrower_heavy_rock",
			"goblin_thrower_retreat_heal",
			"goblin_thrower_rapid_fire",
		],
		"elite_visual": {
			"mode": "frames",
			"asset_dir": "res://assets/art/elitemonster/goblinthrower/frames",
			"target_height": 124.0,
			"animations": {
				"idle": {"prefix": "idle", "count": 4, "fps": 7.0, "loop": true},
				"move": {"prefix": "walk", "count": 6, "fps": 9.0, "loop": true},
				"attack": {"prefix": "atk", "count": 5, "fps": 12.0, "loop": false},
				"hit": {"prefix": "hit", "count": 3, "fps": 14.0, "loop": false},
				"death": {"prefix": "dead", "count": 4, "fps": 10.0, "loop": false},
			},
		},
		"elite_skills": [
			{
				"id": "elite_goblin_thrower_bombardment",
				"name": "폭탄 투하",
				"description": "지름 220 · 폭탄 10개 · 1초 후 공격력 150% 폭발",
				"initial_cooldown": 3.0,
				"cooldown": 20.0,
				"radius": 110.0,
				"bomb_count": 10,
				"bomb_interval": 0.15,
				"projectile_speed": 650.0,
				"fuse_duration": 1.0,
				"damage_multiplier": 1.50,
				"explosion_radius": 52.0,
			},
		],
		"scene": preload("res://src/monsters/GoblinThrower.tscn"),
	},
	"ghost": {
		"id": "ghost",
		"name": "유령",
		"role": "controller",
		"species": "gas",
		"grade": "normal",
		"attack_type": "ranged",
		"base_cost": 6.1,
		"summon_exp": 6.1,
		"base_stats": {
			"max_hp": 92,
			"move_speed": 54.0,
			"attack_damage": 4,
			"attack_range": 275.0,
			"attack_range_diameter": 550.0,
			"attack_cooldown": 2.40,
			"projectile_speed": 500.0,
			"projectile_range": 360.0,
		},
		"default_unlocked": false,
		"rarity": "common",
		"card_icon_path": "res://assets/art/monsters/ghost/frames/idle_01.png",
		"ground_shadow": {
			"size": Vector2(58.0, 18.0),
			"offset_y": 29.0,
			"opacity": 0.34,
		},
		"special_augment_ids": [
			"ghost_phase_shift",
			"ghost_stack_slow",
			"ghost_death_empower",
		],
		"elite_visual": {
			"mode": "frames",
			"asset_dir": "res://assets/art/elitemonster/ghost/frames",
			"target_height": 138.0,
			"animations": {
				"idle": {"prefix": "idle", "count": 5, "fps": 7.0, "loop": true},
				"move": {"prefix": "walk", "count": 5, "fps": 8.0, "loop": true},
				"attack": {"prefix": "atk", "count": 5, "fps": 10.0, "loop": false},
				"hit": {"prefix": "hit", "count": 3, "fps": 12.0, "loop": false},
				"death": {"prefix": "dead", "count": 4, "fps": 9.0, "loop": false},
			},
		},
		"elite_skills": [{
			"id": "elite_ghost_fear",
			"name": "공포",
			"description": "1.5초 공포 · 공격 봉인 · 도주 이속 +50%",
			"initial_cooldown": 3.0,
			"cooldown": 15.0,
			"duration": 1.5,
			"move_speed_multiplier": 1.50,
		}],
		"scene": preload("res://src/monsters/Ghost.tscn"),
	},
	"bomb_rat": {
		"id": "bomb_rat",
		"name": "폭탄쥐",
		"role": "burst",
		"species": "beast",
		"grade": "normal",
		"attack_type": "self_destruct",
		"base_cost": 12.0,
		"summon_exp": 12.0,
		"base_stats": {
			"max_hp": 36,
			"move_speed": 175.0,
			"self_destruct_range": 78.0,
			"self_destruct_fuse": 0.30,
			"explosion_radius": 150.0,
			"explosion_damage": 28,
		},
		"default_unlocked": false,
		"rarity": "common",
		"card_icon_path": "res://assets/art/monsters/bombrat/frames/frame_01.png",
		"ground_shadow": {
			"size": Vector2(60.0, 20.0),
			"offset_y": 27.0,
			"opacity": 0.48,
		},
		"special_augment_ids": [
			"bomb_rat_litter",
			"bomb_rat_powder_overload",
			"bomb_rat_unstable_powder",
		],
		"elite_visual": {
			"mode": "sequence",
			"asset_dir": "res://assets/art/elitemonster/bombrat/frames",
			"target_height": 78.0,
			"animations": {
				"idle": {"start": 1, "count": 4, "fps": 6.0, "loop": true},
				"move": {"start": 5, "count": 6, "fps": 11.0, "loop": true},
				"attack": {"start": 11, "count": 6, "fps": 14.0, "loop": false},
				"death": {"start": 17, "count": 4, "fps": 10.0, "loop": false},
			},
		},
		"elite_skills": [
			{
				"id": "elite_bomb_rat_vibration",
				"name": "진동감지",
				"description": "4초간 이속 +200% · 최대 HP 150% 쉴드",
				"initial_cooldown": 0.0,
				"cooldown": 20.0,
				"duration": 4.0,
				"move_speed_multiplier": 3.0,
				"shield_max_hp_multiplier": 1.50,
			},
		],
		"scene": preload("res://src/monsters/BombRat.tscn"),
	},
}

const ROLE_LABELS := {
	"swarm": "물량",
	"controller": "제어",
	"tank": "탱커",
	"ranged": "원거리",
	"burst": "폭발",
}

const SPECIES_LABELS := {
	"humanoid": "인간형",
	"beast": "짐승",
	"liquid": "액체",
	"undead": "언데드",
	"gas": "기체",
}

const ATTACK_TYPE_LABELS := {
	"melee": "근접",
	"ranged": "원거리",
	"self_destruct": "자폭",
}

const GRADE_LABELS := {
	"rare": "희귀",
	"legendary": "전설",
	"advanced": "고급",
	"normal": "일반",
}

const RARITY_COMBAT_PROFILES := {
	"uncommon": {"hp_multiplier": 1.0, "damage_multiplier": 1.0, "move_speed_multiplier": 1.0, "attack_cooldown_multiplier": 1.0},
	"common": {
		"hp_multiplier": 1.00,
		"damage_multiplier": 1.00,
		"move_speed_multiplier": 1.00,
		"attack_cooldown_multiplier": 1.00,
	},
	"rare": {
		"hp_multiplier": 1.10,
		"damage_multiplier": 1.12,
		"move_speed_multiplier": 1.03,
		"attack_cooldown_multiplier": 0.96,
	},
	"legendary": {
		"hp_multiplier": 1.22,
		"damage_multiplier": 1.25,
		"move_speed_multiplier": 1.05,
		"attack_cooldown_multiplier": 0.92,
	},
}

# Permanent growth remains additive and separate from base rarity combat stats.
const MAX_UPGRADE_LEVEL := 30
const SHARD_RESEARCH_POINTS := 1
const RARITY_UPGRADE_PROFILES := {
	"common": {
		"label": "일반",
		"hp_per_level": 0.02,
		"damage_per_level": 0.02,
		"shards_required": 30,
		"configured": true,
	},
	"advanced": {
		"label": "고급",
		"hp_per_level": 0.035,
		"damage_per_level": 0.035,
		"shards_required": 30,
		"configured": true,
	},
	"uncommon": {
		"label": "고급",
		"hp_per_level": 0.035,
		"damage_per_level": 0.035,
		"shards_required": 30,
		"configured": true,
	},
	"rare": {
		"label": "희귀",
		"hp_per_level": 0.05,
		"damage_per_level": 0.05,
		"shards_required": 30,
		"configured": true,
	},
	"legendary": {
		"label": "전설",
		"hp_per_level": 0.07,
		"damage_per_level": 0.07,
		"shards_required": 25,
		"configured": true,
	},
	"transcendent": {
		"label": "초월",
		"hp_per_level": 0.10,
		"damage_per_level": 0.10,
		"shards_required": 15,
		"configured": true,
	},
}

static func get_monster(monster_id: String) -> Dictionary:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	return data.duplicate(true)

static func get_elite_visual_profile(monster_id: String) -> Dictionary:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	var profile = data.get("elite_visual", {})
	if typeof(profile) != TYPE_DICTIONARY:
		return {}
	return Dictionary(profile).duplicate(true)

static func get_elite_skills(monster_id: String) -> Array:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	var raw_skills = data.get("elite_skills", [])
	if typeof(raw_skills) != TYPE_ARRAY:
		return []
	return Array(raw_skills).duplicate(true)

static func get_ground_shadow_config(monster_id: String) -> Dictionary:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	var config = data.get("ground_shadow", {})
	if typeof(config) != TYPE_DICTIONARY:
		return {}
	return Dictionary(config).duplicate(true)

static func get_scene(monster_id: String) -> PackedScene:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	var scene = data.get("scene")
	return scene as PackedScene

static func get_monster_name(monster_id: String) -> String:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	return String(data.get("name", monster_id))

static func get_role(monster_id: String) -> String:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	return String(data.get("role", "unknown"))

static func get_species(monster_id: String) -> String:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	return String(data.get("species", "unknown"))


static func get_family(monster_id: String) -> String:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	return String(data.get("family", ""))


static func node_has_species(
	target_node: Node,
	species_id: String
) -> bool:
	if not is_instance_valid(target_node):
		return false

	var normalized_species := species_id.strip_edges().to_lower()
	if normalized_species.is_empty():
		return false

	var runtime_species := String(
		target_node.get_meta("monster_species", "")
	).strip_edges().to_lower()
	if runtime_species == normalized_species:
		return true

	var monster_type_value = target_node.get("monster_type")
	if monster_type_value != null:
		var monster_id := String(monster_type_value)
		if get_species(monster_id).strip_edges().to_lower() == normalized_species:
			return true

	# Legacy compatibility only. New monsters should be classified by species
	# in this catalog so every species-based effect picks them up automatically.
	if normalized_species == "undead":
		if (
			bool(target_node.get_meta("undead", false))
			or bool(target_node.get_meta("is_undead", false))
			or target_node.is_in_group("undead")
		):
			return true
		if monster_type_value != null:
			var legacy_type := String(monster_type_value).to_lower()
			return (
				"undead" in legacy_type
				or "skeleton" in legacy_type
				or "zombie" in legacy_type
				or "ghoul" in legacy_type
			)
	return false


static func is_undead_node(target_node: Node) -> bool:
	return node_has_species(target_node, "undead")


static func get_grade(monster_id: String) -> String:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	return String(data.get("grade", "normal"))


static func get_rarity(monster_id: String) -> String:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	return String(data.get("rarity", "common"))


static func get_rarity_combat_profile(monster_id: String) -> Dictionary:
	var rarity := get_rarity(monster_id)
	var profile = RARITY_COMBAT_PROFILES.get(
		rarity,
		RARITY_COMBAT_PROFILES["common"]
	)
	return Dictionary(profile).duplicate(true)


static func get_rarity_upgrade_profile(monster_id: String) -> Dictionary:
	var rarity := get_rarity(monster_id)
	var profile = RARITY_UPGRADE_PROFILES.get(rarity, {})
	if typeof(profile) != TYPE_DICTIONARY:
		return {}
	return Dictionary(profile).duplicate(true)


static func get_attack_type(monster_id: String) -> String:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	return String(data.get("attack_type", ""))

static func get_base_cost(monster_id: String) -> float:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	return float(data.get("base_cost", 0.0))

static func get_summon_exp(monster_id: String) -> float:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	return maxf(float(data.get("summon_exp", 0.0)), 0.0)

static func get_base_stats(monster_id: String) -> Dictionary:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	var stats = data.get("base_stats", {})
	if typeof(stats) != TYPE_DICTIONARY:
		return {}
	return Dictionary(stats).duplicate(true)

static func get_role_label(role_id: String) -> String:
	return String(ROLE_LABELS.get(role_id, role_id))

static func get_species_label(species_id: String) -> String:
	return String(SPECIES_LABELS.get(species_id, species_id))

static func get_grade_label(grade_id: String) -> String:
	return String(GRADE_LABELS.get(grade_id, grade_id))

static func get_attack_type_label(attack_type_id: String) -> String:
	return String(
		ATTACK_TYPE_LABELS.get(attack_type_id, attack_type_id)
	)

static func get_ids() -> Array[String]:
	var result: Array[String] = []
	for monster_id in ORDER:
		if MONSTERS.has(monster_id):
			result.append(String(monster_id))
	return result

static func is_default_unlocked(monster_id: String) -> bool:
	var data: Dictionary = MONSTERS.get(monster_id, {})
	return bool(data.get("default_unlocked", false))

static func get_shards_required(monster_id: String) -> int:
	return maxi(int(get_rarity_upgrade_profile(monster_id).get("shards_required", 30)), 1)
