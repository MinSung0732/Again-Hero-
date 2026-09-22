extends RefCounted
class_name HeroAugmentCatalog

const TAG_LABELS := {
	"damage": "화력",
	"projectile": "투사체",
	"attack_speed": "공격속도",
	"durability": "내구",
	"survival": "생존",
	"mobility": "기동",
	"kite": "카이팅",
	"range": "사거리",
	"recovery": "회복",
	"area": "광역",
	"resistance": "저항",
	"growth": "성장",
	"ammo": "장탄",
	"reload": "장전",
	"headshot": "헤드샷",
	"deadeye": "데드아이",
	"evasion": "회피",
	"gunner": "권총",
}

const AUGMENTS = [
	{
		"id": "projectile_power",
		"name": "탄환 강화",
		"description": "기본 공격 투사체 +1, 부채꼴 확산 (최대 4중첩)",
		"base_score": 8.0,
		"max_stack": 4,
		"tags": ["projectile", "area"],
		"effects": [
			{"op": "advance_projectile_fan"},
		],
		"ai_rules": [
			{"source": "nearby_linear", "weight": 0.55, "cap": 3.3},
			{"source": "current_type_ratio", "key": "slime", "weight": 3.0},
			{"source": "current_role_ratio", "key": "swarm", "weight": 2.2},
			{"source": "recent_type_ratio", "key": "slime", "weight": 2.4},
			{"source": "recent_role_ratio", "key": "swarm", "weight": 1.8},
		],
		"synergy_rules": [
			{"source": "build_tag_stacks", "key": "attack_speed", "weight": 0.55, "cap": 2.20},
			{"source": "build_tag_stacks", "key": "range", "weight": 0.35, "cap": 1.40},
		],
	},
	{
		"id": "common_attack_training",
		"name": "공격 단련",
		"description": "공격력 +2 (최대 20중첩)",
		"base_score": 6.9,
		"max_stack": 20,
		"tags": ["damage"],
		"effects": [
			{"op": "add_stat", "target": "attack_damage", "value": 2},
		],
		"ai_rules": [
			{"source": "hp_ratio_min", "value": 0.50, "bonus": 0.35},
			{"source": "recent_events_linear", "weight": 0.05, "cap": 0.8},
		],
		"synergy_rules": [
			{"source": "build_tag_stacks", "key": "attack_speed", "weight": 0.35, "cap": 1.40},
		],
	},
	{
		"id": "rapid_strikes",
		"name": "속공 훈련",
		"description": "공격속도 +2% (최대 20중첩)",
		"base_score": 6.8,
		"max_stack": 20,
		"tags": ["attack_speed", "damage"],
		"effects": [
			{"op": "advance_common_attack_speed"},
		],
		"ai_rules": [
			{"source": "nearby_linear", "weight": 0.35, "cap": 2.1},
			{"source": "recent_events_linear", "weight": 0.06, "cap": 0.9},
		],
		"synergy_rules": [
			{"source": "build_tag_stacks", "key": "damage", "weight": 0.35, "cap": 1.40},
		],
	},
	{
		"id": "iron_body",
		"name": "강인한 육체",
		"description": "최대 HP +20, HP +20",
		"base_score": 7.0,
		"max_stack": 10,
		"tags": ["durability", "survival"],
		"effects": [
			{"op": "add_stat", "target": "max_hp", "value": 20},
			{"op": "heal", "value": 20},
		],
		"ai_rules": [
			{"source": "hp_missing", "weight": 5.0},
			{"source": "current_type_ratio", "key": "orc", "weight": 2.5},
			{"source": "current_role_ratio", "key": "tank", "weight": 1.5},
			{"source": "recent_type_ratio", "key": "orc", "weight": 1.5},
			{"source": "recent_role_ratio", "key": "tank", "weight": 0.8},
			{"source": "hp_ratio_max", "value": 0.55, "bonus": 1.0},
		],
		"synergy_rules": [
			{"source": "build_tag_stacks", "key": "recovery", "weight": 1.00, "cap": 2.00},
		],
	},
	{
		"id": "healing_efficiency",
		"name": "회복 증폭",
		"description": "회복 아이템 회복량 +3% (최대 20중첩)",
		"base_score": 5.8,
		"max_stack": 20,
		"tags": ["recovery", "survival"],
		"effects": [
			{"op": "add_stat", "target": "heal_item_multiplier", "value": 0.03, "max": 1.60},
		],
		"ai_rules": [
			{"source": "hp_missing", "weight": 5.5},
			{"source": "hp_ratio_max", "value": 0.50, "bonus": 1.2},
			{"source": "recent_events_linear", "weight": 0.06, "cap": 0.8},
		],
		"synergy_rules": [
			{"source": "build_tag_stacks", "key": "durability", "weight": 0.35, "cap": 1.4},
			{"source": "build_tag_stacks", "key": "recovery", "weight": 0.30, "cap": 1.2},
		],
	},
	{
		"id": "pursuit",
		"name": "민첩한 발놀림",
		"description": "이동속도 +8",
		"base_score": 6.0,
		"max_stack": 10,
		"tags": ["mobility", "kite"],
		"effects": [
			{"op": "add_stat", "target": "move_speed", "value": 8.0},
		],
		"ai_rules": [
			{"source": "distance", "divisor": 220.0, "cap": 2.3},
			{"source": "current_type_ratio", "key": "spider", "weight": 3.5},
			{"source": "current_role_ratio", "key": "controller", "weight": 2.0},
			{"source": "recent_type_ratio", "key": "spider", "weight": 3.0},
			{"source": "recent_role_ratio", "key": "controller", "weight": 1.6},
			{"source": "recent_status_weight", "key": "slow", "weight": 0.45, "cap": 2.7},
			{"source": "total_count_max", "value": 2, "bonus": 0.5},
		],
		"synergy_rules": [
			{"source": "build_tag_stacks", "key": "range", "weight": 0.70, "cap": 2.10},
		],
	},
	{
		"id": "slow_resistance",
		"name": "둔화 적응",
		"description": "둔화 저항 +5%",
		"base_score": 4.8,
		"max_stack": 10,
		"tags": ["resistance", "mobility", "survival"],
		"effects": [
			{"op": "add_status_resistance", "status": "slow", "value": 0.05, "max": 0.50},
		],
		"ai_rules": [
			{"source": "recent_status_weight", "key": "slow", "weight": 1.10, "cap": 6.6},
			{"source": "recent_type_ratio", "key": "spider", "weight": 1.8},
			{"source": "recent_role_ratio", "key": "controller", "weight": 1.4},
			{"source": "current_type_ratio", "key": "spider", "weight": 1.2},
		],
		"synergy_rules": [
			{"source": "build_tag_stacks", "key": "mobility", "weight": 0.45, "cap": 1.35},
			{"source": "build_tag_stacks", "key": "kite", "weight": 0.35, "cap": 1.05},
		],
	},
	{
		"id": "long_reach",
		"name": "사거리 확장",
		"description": "공격/투사체 최대 사거리 +35",
		"base_score": 5.5,
		"max_stack": 3,
		"tags": ["range", "kite"],
		"effects": [
			{"op": "add_stat", "target": "attack_range", "value": 35.0},
		],
		"ai_rules": [
			{"source": "distance", "divisor": 180.0, "cap": 2.7},
			{"source": "current_type_ratio", "key": "spider", "weight": 1.8},
			{"source": "recent_type_ratio", "key": "spider", "weight": 1.4},
			{"source": "recent_role_ratio", "key": "controller", "weight": 0.8},
			{"source": "nearby_count_eq", "value": 0, "bonus": 0.7},
		],
		"synergy_rules": [
			{"source": "build_tag_stacks", "key": "mobility", "weight": 0.70, "cap": 2.10},
			{"source": "build_tag_stacks", "key": "damage", "weight": 0.30, "cap": 0.90},
		],
	},
	{
		"id": "arcane_burst",
		"name": "폭발 탄환",
		"description": "투사체 적중 시 주변 적에게 광역 피해",
		"base_score": 5.8,
		"max_stack": 4,
		"tags": ["area", "projectile"],
		"effects": [
			{"op": "add_stat", "target": "projectile_splash_radius", "value": 70.0, "max": 180.0},
			{"op": "add_stat", "target": "projectile_splash_damage_ratio", "value": 0.28, "max": 0.70},
		],
		"ai_rules": [
			{"source": "nearby_linear", "weight": 0.70, "cap": 3.5},
			{"source": "current_type_ratio", "key": "slime", "weight": 4.5},
			{"source": "current_role_ratio", "key": "swarm", "weight": 3.0},
			{"source": "recent_type_ratio", "key": "slime", "weight": 4.0},
			{"source": "recent_role_ratio", "key": "swarm", "weight": 2.5},
			{"source": "recent_events_linear", "weight": 0.14, "cap": 1.4},
			{"source": "total_count_min", "value": 5, "bonus": 1.2},
		],
		"synergy_rules": [
			{"source": "build_tag_stacks", "key": "attack_speed", "weight": 0.55, "cap": 1.65},
			{"source": "build_tag_stacks", "key": "damage", "weight": 0.35, "cap": 1.05},
		],
	},
	{
		"id": "battle_recovery",
		"name": "전투 회복",
		"description": "즉시 HP 90 회복",
		"base_score": 5.0,
		"max_stack": 3,
		"tags": ["recovery", "survival"],
		"effects": [
			{"op": "heal", "value": 90},
		],
		"ai_rules": [
			{"source": "hp_missing", "weight": 8.0},
			{"source": "current_role_ratio", "key": "tank", "weight": 0.8},
			{"source": "recent_role_ratio", "key": "tank", "weight": 0.5},
			{"source": "hp_ratio_min", "value": 0.80, "bonus": -2.5},
			{"source": "hp_ratio_max", "value": 0.45, "bonus": 2.0},
		],
		"synergy_rules": [
			{"source": "build_tag_stacks", "key": "durability", "weight": 0.80, "cap": 2.40},
		],
	},
	{
		"id": "exp_training",
		"name": "경험 축적",
		"description": "경험치 획득량 +4%",
		"base_score": 6.4,
		"max_stack": 10,
		"tags": ["growth"],
		"effects": [
			{"op": "add_stat", "target": "exp_gain_multiplier", "value": 0.04, "max": 1.40},
		],
	},
	{
		"id": "exp_magnet",
		"name": "경험 흡수",
		"description": "경험치 획득 범위 +15",
		"base_score": 5.8,
		"max_stack": 10,
		"tags": ["growth", "range"],
		"effects": [
			{"op": "add_stat", "target": "exp_pickup_radius", "value": 15.0},
		],
	},
	{
		"id": "rogue_edge",
		"name": "예리한 연격",
		"description": "연격 피해 +10% (최대 +50%)",
		"base_score": 7.8,
		"max_stack": 5,
		"tags": ["damage"],
		"effects": [
			{"op": "add_stat", "target": "rogue_combo_damage_multiplier", "value": 0.10, "max": 1.50},
		],
	},
	{
		"id": "rogue_tempo",
		"name": "연격 가속",
		"description": "연격 마무리 후딜 -3%",
		"base_score": 7.2,
		"max_stack": 4,
		"tags": ["attack_speed", "mobility"],
		"effects": [
			{"op": "add_stat", "target": "rogue_combo_recovery_multiplier", "value": -0.03, "min": 0.88},
		],
	},
	{
		"id": "rogue_guard",
		"name": "난도질 방어",
		"description": "난도질 쉴드량 +2% 최대 HP",
		"base_score": 6.8,
		"max_stack": 4,
		"tags": ["durability", "survival", "area"],
		"effects": [
			{"op": "add_stat", "target": "rogue_slash_shield_ratio_bonus", "value": 0.02, "max": 0.08},
		],
	},
	{
		"id": "rogue_hunt",
		"name": "끈질긴 급습",
		"description": "급습-암살 공격 횟수 +1",
		"base_score": 6.6,
		"max_stack": 4,
		"tags": ["damage", "mobility"],
		"effects": [
			{"op": "add_stat", "target": "rogue_assassination_hit_bonus", "value": 1, "max": 4},
		],
	},
	{
		"id": "rogue_execution",
		"name": "처형 감각",
		"description": "일반 몬스터 처형 기준 +2%",
		"base_score": 6.2,
		"max_stack": 3,
		"tags": ["damage"],
		"effects": [
			{"op": "add_stat", "target": "rogue_execute_threshold_bonus", "value": 0.02, "max": 0.06},
		],
	},
	{
		"id": "rogue_bloodthirst",
		"name": "피의 갈증",
		"description": "직접 피해 흡혈 +2% (최대 20%)",
		"base_score": 6.9,
		"max_stack": 10,
		"tags": ["recovery", "survival", "damage"],
		"effects": [
			{"op": "add_stat", "target": "rogue_lifesteal_ratio", "value": 0.02, "max": 0.20},
		],
	},
	{
		"id": "fighter_guard_wall",
		"name": "견고한 방패",
		"description": "막기 쉴드 +최대 HP 3%",
		"base_score": 7.2,
		"max_stack": 10,
		"tags": ["durability", "survival"],
		"effects": [
			{"op": "add_stat", "target": "fighter_guard_shield_ratio_bonus", "value": 0.03, "max": 0.30},
		],
		"ai_rules": [
			{"source": "hp_missing", "weight": 5.0},
			{"source": "nearby_linear", "weight": 0.35, "cap": 2.5},
		],
	},
	{
		"id": "fighter_revenge",
		"name": "복수의 방패",
		"description": "막기 종료 반격 피해 +5%",
		"base_score": 6.8,
		"max_stack": 5,
		"tags": ["damage", "area"],
		"effects": [
			{"op": "add_stat", "target": "fighter_guard_release_ratio_bonus", "value": 0.05, "max": 0.25},
		],
		"ai_rules": [
			{"source": "nearby_linear", "weight": 0.45, "cap": 3.0},
			{"source": "recent_events_linear", "weight": 0.08, "cap": 1.0},
		],
	},
	{
		"id": "fighter_thorns",
		"name": "가시 방패",
		"description": "막기 중 받은 원본 피해의 3% 반사",
		"base_score": 6.4,
		"max_stack": 5,
		"tags": ["damage", "survival"],
		"effects": [
			{"op": "add_stat", "target": "fighter_reflect_ratio", "value": 0.03, "max": 0.15},
		],
		"ai_rules": [
			{"source": "nearby_linear", "weight": 0.55, "cap": 3.3},
			{"source": "hp_missing", "weight": 2.5},
		],
	},
	{
		"id": "fighter_guard_mastery",
		"name": "수호 숙련",
		"description": "막기 피해 감소 +3%",
		"base_score": 7.0,
		"max_stack": 5,
		"tags": ["durability", "survival"],
		"effects": [
			{"op": "add_stat", "target": "fighter_guard_damage_reduction_bonus", "value": 0.03, "max": 0.15},
		],
		"ai_rules": [
			{"source": "hp_missing", "weight": 5.5},
			{"source": "current_role_ratio", "key": "tank", "weight": 1.6},
		],
	},

	{
		"id": "fighter_charge",
		"name": "방패 충전",
		"description": "막기 충전시간 -0.5초",
		"base_score": 6.3,
		"max_stack": 5,
		"tags": ["survival", "growth"],
		"effects": [
			{"op": "add_stat", "target": "fighter_guard_charge_seconds", "value": -0.5, "min": 17.5},
		],
	},
	{
		"id": "fighter_sword_mastery",
		"name": "숙련된 검사",
		"description": "베기/찌르기 피해 +6%",
		"base_score": 7.3,
		"max_stack": 10,
		"tags": ["damage"],
		"effects": [
			{"op": "add_stat", "target": "fighter_basic_damage_multiplier", "value": 0.06, "max": 1.60},
		],
		"ai_rules": [
			{"source": "hp_ratio_min", "value": 0.60, "bonus": 0.7},
		],
	},
	{
		"id": "fighter_slash_mastery",
		"name": "베기 숙련",
		"description": "베기 발생 시 추가 베기 +1타. 최대 2중첩(총 3연격), 추가타 처치 시 적 1마리당 HP 10 회복",
		"base_score": 7.6,
		"max_stack": 2,
		"tags": ["damage", "area", "recovery"],
		"effects": [
			{"op": "advance_fighter_slash_mastery"},
		],
		"ai_rules": [
			{"source": "nearby_linear", "weight": 0.70, "cap": 4.2},
			{"source": "current_role_ratio", "key": "swarm", "weight": 2.0},
			{"source": "hp_missing", "weight": 1.3},
		],
	},
	{
		"id": "fighter_slash_width",
		"name": "넓은 베기",
		"description": "베기 좌우 범위 +10",
		"base_score": 6.0,
		"max_stack": 5,
		"tags": ["area", "damage"],
		"effects": [
			{"op": "add_stat", "target": "fighter_slash_half_width_bonus", "value": 10.0, "max": 50.0},
		],
		"ai_rules": [
			{"source": "nearby_linear", "weight": 0.60, "cap": 3.6},
			{"source": "current_role_ratio", "key": "swarm", "weight": 2.2},
		],
	},
	{
		"id": "fighter_thrust_training",
		"name": "관통 찌르기",
		"description": "찌르기 사거리 +15, 피해 +3%",
		"base_score": 6.1,
		"max_stack": 5,
		"tags": ["range", "damage"],
		"effects": [
			{"op": "add_stat", "target": "fighter_thrust_length_bonus", "value": 15.0, "max": 75.0},
			{"op": "add_stat", "target": "fighter_thrust_damage_bonus", "value": 0.03, "max": 0.15},
		],
		"ai_rules": [
			{"source": "distance", "divisor": 170.0, "cap": 2.4},
			{"source": "nearby_count_max", "value": 2, "bonus": 0.8},
		],
	},
	{
		"id": "fighter_courage",
		"name": "용기백배",
		"description": "기본 3연속 돌진 후 추가 돌진 확률 15%, 이후 중첩당 +3% (최대 36%). 최대 6회까지 돌진",
		"base_score": 7.5,
		"max_stack": 8,
		"tags": ["damage", "mobility", "area"],
		"effects": [
			{"op": "advance_fighter_courage"},
		],
		"ai_rules": [
			{"source": "nearby_linear", "weight": 0.55, "cap": 3.3},
			{"source": "current_role_ratio", "key": "swarm", "weight": 1.8},
			{"source": "hp_missing", "weight": 1.5},
		],
		"synergy_rules": [
			{"source": "build_tag_stacks", "key": "mobility", "weight": 0.35, "cap": 1.4},
			{"source": "build_tag_stacks", "key": "damage", "weight": 0.25, "cap": 1.0},
		],
	},
	{
		"id": "fighter_charge_recovery",
		"name": "승전의 호흡",
		"description": "검방 돌격 처치 시 HP 8 회복, 중첩당 +2 (최대 26)",
		"base_score": 6.6,
		"max_stack": 10,
		"tags": ["recovery", "survival", "mobility"],
		"effects": [
			{"op": "advance_fighter_charge_recovery"},
		],
		"ai_rules": [
			{"source": "hp_missing", "weight": 5.0},
			{"source": "nearby_linear", "weight": 0.45, "cap": 2.7},
			{"source": "current_role_ratio", "key": "swarm", "weight": 1.8},
		],
		"synergy_rules": [
			{"source": "build_tag_stacks", "key": "mobility", "weight": 0.45, "cap": 1.35},
			{"source": "build_tag_stacks", "key": "recovery", "weight": 0.35, "cap": 1.05},
		],
	},
	{
		"id": "rogue_ruthless_strike",
		"name": "무자비한 일격",
		"description": "기본 연격 돌진 횟수 +1 (3타 → 4타)",
		"base_score": 8.1,
		"max_stack": 1,
		"tags": ["damage", "mobility"],
		"effects": [
			{"op": "add_stat", "target": "rogue_bonus_combo_hits", "value": 1, "max": 1},
		],
	}
,
	{
		"id": "gunner_fast_reload",
		"name": "속사 실린더",
		"description": "재장전 시간 -8% (최대 5중첩)",
		"base_score": 6.7,
		"max_stack": 5,
		"tags": ["gunner", "reload", "ammo"],
		"effects": [{"op": "gunner_fast_reload"}],
		"ai_rules": [
			{"source": "context_linear", "key": "gunner_ammo_empty_pressure", "weight": 3.4, "cap": 3.4},
			{"source": "context_min", "key": "gunner_reload_state", "value": 0.5, "bonus": 1.5},
			{"source": "recent_role_ratio", "key": "swarm", "weight": 1.4}
		],
		"synergy_rules": [{"source": "build_tag_stacks", "key": "ammo", "weight": 0.35, "cap": 1.4}]
	},
	{
		"id": "gunner_extended_cylinder",
		"name": "확장 실린더",
		"description": "최대 장탄 +1 (최대 6중첩)",
		"base_score": 6.9,
		"max_stack": 6,
		"tags": ["gunner", "ammo", "deadeye"],
		"effects": [{"op": "gunner_expand_magazine"}],
		"ai_rules": [
			{"source": "context_linear", "key": "gunner_ammo_empty_pressure", "weight": 2.8, "cap": 2.8},
			{"source": "recent_events_linear", "weight": 0.05, "cap": 0.8}
		],
		"synergy_rules": [{"source": "build_tag_stacks", "key": "deadeye", "weight": 0.45, "cap": 1.8}]
	},
	{
		"id": "gunner_fanning",
		"name": "패닝",
		"description": "랜덤 탄환 확산각 감소 (최대 5중첩)",
		"base_score": 6.5,
		"max_stack": 5,
		"tags": ["gunner", "damage", "projectile"],
		"effects": [{"op": "gunner_tighten_spread"}],
		"ai_rules": [
			{"source": "current_role_ratio", "key": "tank", "weight": 1.8},
			{"source": "total_count_max", "value": 5, "bonus": 0.8}
		],
		"synergy_rules": [{"source": "build_tag_stacks", "key": "headshot", "weight": 0.30, "cap": 1.2}]
	},
	{
		"id": "gunner_ricochet_pressure",
		"name": "도탄 사격",
		"description": "관통 후 다음 적 명중 피해가 점점 증가 (최대 5중첩)",
		"base_score": 6.8,
		"max_stack": 5,
		"tags": ["gunner", "projectile", "area"],
		"effects": [{"op": "gunner_penetration_ramp"}],
		"ai_rules": [
			{"source": "nearby_linear", "weight": 0.45, "cap": 2.7},
			{"source": "current_role_ratio", "key": "swarm", "weight": 2.4},
			{"source": "recent_role_ratio", "key": "swarm", "weight": 1.8}
		],
		"synergy_rules": [{"source": "build_tag_stacks", "key": "attack_speed", "weight": 0.30, "cap": 1.2}]
	},
	{
		"id": "gunner_deadly_aim",
		"name": "치명적 조준",
		"description": "헤드샷 확률 +3% (최대 8중첩)",
		"base_score": 6.9,
		"max_stack": 8,
		"tags": ["gunner", "headshot", "damage"],
		"effects": [{"op": "gunner_headshot_chance"}],
		"ai_rules": [
			{"source": "hp_ratio_min", "value": 0.55, "bonus": 0.6},
			{"source": "current_role_ratio", "key": "tank", "weight": 1.6}
		],
		"synergy_rules": [{"source": "build_tag_stacks", "key": "headshot", "weight": 0.50, "cap": 2.0}]
	},
	{
		"id": "gunner_large_caliber",
		"name": "대구경 탄환",
		"description": "헤드샷 피해 배율 +0.05 (최대 6중첩)",
		"base_score": 6.4,
		"max_stack": 6,
		"tags": ["gunner", "headshot", "damage"],
		"effects": [{"op": "gunner_headshot_damage"}],
		"ai_rules": [{"source": "current_role_ratio", "key": "tank", "weight": 2.2}],
		"synergy_rules": [{"source": "build_augment_stacks", "key": "gunner_deadly_aim", "weight": 0.65, "cap": 2.6}]
	},
	{
		"id": "gunner_snap_reload",
		"name": "속전속결",
		"description": "퀵드로 확률 +1% (최대 7중첩)",
		"base_score": 6.1,
		"max_stack": 7,
		"tags": ["gunner", "reload", "ammo"],
		"effects": [{"op": "gunner_quickdraw_chance"}],
		"ai_rules": [
			{"source": "context_linear", "key": "gunner_ammo_empty_pressure", "weight": 2.5, "cap": 2.5},
			{"source": "context_min", "key": "gunner_reload_state", "value": 0.5, "bonus": 1.0}
		],
		"synergy_rules": [{"source": "build_tag_stacks", "key": "reload", "weight": 0.35, "cap": 1.4}]
	},
	{
		"id": "gunner_tactical_retreat",
		"name": "전술 후퇴",
		"description": "백스텝 쿨타임 -0.5초, 거리 +10 (최대 6중첩)",
		"base_score": 6.5,
		"max_stack": 6,
		"tags": ["gunner", "evasion", "mobility", "survival"],
		"effects": [{"op": "gunner_tactical_retreat"}],
		"ai_rules": [
			{"source": "context_linear", "key": "gunner_surround_pressure", "weight": 3.2, "cap": 4.2},
			{"source": "hp_missing", "weight": 2.5}
		],
		"synergy_rules": [{"source": "build_tag_stacks", "key": "evasion", "weight": 0.40, "cap": 1.6}]
	},
	{
		"id": "gunner_afterimage_shot",
		"name": "잔상 사격",
		"description": "백스텝 시 이전 위치에서 자동 사격, 중첩당 2발 추가 (최대 3중첩)",
		"base_score": 6.8,
		"max_stack": 3,
		"tags": ["gunner", "evasion", "damage"],
		"effects": [{"op": "gunner_afterimage_shot"}],
		"ai_rules": [{"source": "context_linear", "key": "gunner_surround_pressure", "weight": 2.8, "cap": 3.6}],
		"synergy_rules": [{"source": "build_augment_stacks", "key": "gunner_tactical_retreat", "weight": 0.75, "cap": 2.25}]
	},
	{
		"id": "gunner_forced_ejection",
		"name": "강제 배출",
		"description": "실린더 타격 넉백 +15, 슬로우 지속 +0.3초 (최대 5중첩)",
		"base_score": 6.6,
		"max_stack": 5,
		"tags": ["gunner", "reload", "survival", "area"],
		"effects": [{"op": "gunner_cylinder_control"}],
		"ai_rules": [
			{"source": "context_linear", "key": "gunner_surround_pressure", "weight": 3.0, "cap": 4.0},
			{"source": "context_min", "key": "gunner_reload_state", "value": 0.5, "bonus": 1.2}
		],
		"synergy_rules": [{"source": "build_tag_stacks", "key": "reload", "weight": 0.35, "cap": 1.4}]
	},
	{
		"id": "gunner_impact_cylinder",
		"name": "충격 실린더",
		"description": "실린더 타격에 공격력 비례 피해 추가 (최대 5중첩)",
		"base_score": 6.4,
		"max_stack": 5,
		"tags": ["gunner", "reload", "damage", "area"],
		"effects": [{"op": "gunner_cylinder_damage"}],
		"ai_rules": [
			{"source": "context_linear", "key": "gunner_surround_pressure", "weight": 2.7, "cap": 3.5},
			{"source": "nearby_linear", "weight": 0.30, "cap": 1.8}
		],
		"synergy_rules": [{"source": "build_augment_stacks", "key": "gunner_forced_ejection", "weight": 0.55, "cap": 2.2}]
	},
	{
		"id": "gunner_deadeye_focus",
		"name": "데드아이 - 집중 사격",
		"description": "데드아이 발사 간격 -7% (최대 5중첩)",
		"base_score": 6.6,
		"max_stack": 5,
		"tags": ["gunner", "deadeye", "attack_speed"],
		"effects": [{"op": "gunner_deadeye_focus"}],
		"ai_rules": [{"source": "context_linear", "key": "gunner_deadeye_cluster_score", "weight": 0.55, "cap": 3.3}],
		"synergy_rules": [{"source": "build_tag_stacks", "key": "ammo", "weight": 0.35, "cap": 1.4}]
	},
	{
		"id": "gunner_deadeye_storm",
		"name": "데드아이 - 탄환 폭풍",
		"description": "데드아이 장탄당 발사 수 +0.25 (최대 4중첩)",
		"base_score": 6.9,
		"max_stack": 4,
		"tags": ["gunner", "deadeye", "ammo", "area"],
		"effects": [{"op": "gunner_deadeye_storm"}],
		"ai_rules": [
			{"source": "context_linear", "key": "gunner_deadeye_cluster_score", "weight": 0.65, "cap": 3.9},
			{"source": "current_role_ratio", "key": "swarm", "weight": 1.5}
		],
		"synergy_rules": [{"source": "build_augment_stacks", "key": "gunner_extended_cylinder", "weight": 0.55, "cap": 2.2}]
	},
	{
		"id": "gunner_fugitive_instinct",
		"name": "도망자의 본능",
		"description": "HP 40% 이하 백스텝 발동 확률 +8% (최대 5중첩)",
		"base_score": 6.3,
		"max_stack": 5,
		"tags": ["gunner", "evasion", "survival"],
		"effects": [{"op": "gunner_low_hp_backstep"}],
		"ai_rules": [
			{"source": "hp_missing", "weight": 4.2},
			{"source": "hp_ratio_max", "value": 0.40, "bonus": 2.0},
			{"source": "context_linear", "key": "gunner_surround_pressure", "weight": 1.8, "cap": 2.4}
		],
		"synergy_rules": [{"source": "build_tag_stacks", "key": "evasion", "weight": 0.45, "cap": 1.8}]
	},
	{
		"id": "gunner_reload_cover",
		"name": "장전 엄호",
		"description": "재장전 중 이동속도 +6% (최대 5중첩)",
		"base_score": 6.2,
		"max_stack": 5,
		"tags": ["gunner", "reload", "mobility", "survival"],
		"effects": [{"op": "gunner_reload_cover"}],
		"ai_rules": [
			{"source": "context_min", "key": "gunner_reload_state", "value": 0.5, "bonus": 1.5},
			{"source": "context_linear", "key": "gunner_surround_pressure", "weight": 2.2, "cap": 3.0}
		],
		"synergy_rules": [{"source": "build_tag_stacks", "key": "reload", "weight": 0.40, "cap": 1.6}]
	}

]

static func roll_candidates(
	count: int = 3,
	build_counts: Dictionary = {},
	allowed_ids: Array = []
) -> Array:
	var pool: Array = []

	for raw_augment in AUGMENTS:
		var augment: Dictionary = raw_augment
		var augment_id := String(augment.get("id", ""))
		var max_stack := int(augment.get("max_stack", 0))
		var current_stack := int(build_counts.get(augment_id, 0))

		if not allowed_ids.is_empty() and augment_id not in allowed_ids:
			continue

		if max_stack > 0 and current_stack >= max_stack:
			continue

		pool.append(augment.duplicate(true))

	pool.shuffle()

	var result: Array = []
	var take_count: int = mini(count, pool.size())
	for index in range(take_count):
		result.append(pool[index])

	return result

static func get_augment(augment_id: String) -> Dictionary:
	for augment in AUGMENTS:
		if String(augment.get("id", "")) == augment_id:
			return augment.duplicate(true)
	return {}

static func get_tag_label(tag_id: String) -> String:
	return String(TAG_LABELS.get(tag_id, tag_id))

static func get_build_tag_counts(build_counts: Dictionary) -> Dictionary:
	var tag_counts := {}

	for raw_augment_id in build_counts.keys():
		var augment_id := String(raw_augment_id)
		var stacks := int(build_counts.get(augment_id, 0))
		if stacks <= 0:
			continue

		var augment := get_augment(augment_id)
		for raw_tag in augment.get("tags", []):
			var tag := String(raw_tag)
			tag_counts[tag] = int(tag_counts.get(tag, 0)) + stacks

	return tag_counts
