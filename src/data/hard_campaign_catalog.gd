extends RefCounted
class_name HardCampaignCatalog

# Release hard mode one demon stage at a time; hero-perspective hard is separate.
const RELEASED_DEMON_STAGES := ["stage_1", "stage_2", "stage_3"]

const HERO_STATS := {
	"hp_multiplier": 1.88,
	"damage_multiplier": 1.88,
	"move_speed_multiplier": 1.10,
	"attack_speed_multiplier": 1.10,
	"regeneration_multiplier": 1.10,
}

# Ordinary run rewards only. First clear and all-clear rewards are independent.
const RUN_REWARDS := {
	"victory": 1.75,
	"defeat": 1.30,
	"abandon": 1.00,
}
const FIRST_CLEAR := {"research": 500, "gold": 1000, "demon_token": 30}
const ALL_CLEAR := {"gold": 3000, "demon_token": 100}

const STAGE_1 := {
	"hero_id": "ranged_rookie",
	"awakening_hp_ratio": 0.50,
	"awakening_method": "activate_hard_stage1",
	"awakening_skill_id": "hard_stage1_overload",
	"awakening_name": "마력 과부하",
	"cutscene_texture_path": "res://assets/art/heroes/stage1_mage/cutscene/stage1_hero_cutscene.png",
	"cutscene_hold_seconds": 1.05,
	"min_projectiles": 3,
	"piercer_every_attacks": 3,
	"piercer_windup_seconds": 0.70,
	"weakness_seconds": 2.00,
	"weakness_damage_taken_increase": 0.20,
}

const STAGE_2 := {
	"hero_id": "swift_hunter",
	"awakening_hp_ratio": 0.50,
	"awakening_method": "activate_hard_stage2",
	"awakening_skill_id": "hard_stage2_shadow_hunt",
	"awakening_name": "그림자 사냥",
	"cutscene_texture_path": "res://assets/art/heroes/stage2_rogue/cutscene/stage2_hero_cutscene.png",
	"cutscene_hold_seconds": 1.05,
	"extra_assassination_hits": 2,
	"final_strike_warning_seconds": 0.45,
	"weakness_seconds": 1.80,
	"weakness_damage_taken_increase": 0.20,
	"weakness_move_speed_multiplier": 0.55,
	"final_strike_mark_radius": 62.0,
}

const STAGE_3 := {
	"hero_id": "sword_shield_hero",
	"awakening_hp_ratio": 0.50,
	"awakening_method": "activate_hard_stage3",
	"awakening_skill_id": "hard_stage3_unyielding_guardian",
	"awakening_name": "불굴의 수호자",
	"cutscene_texture_path": "res://assets/art/heroes/stage3_fighter/cutscene/stage3_hero_cutscene.png",
	"cutscene_hold_seconds": 1.05,
	"guard_seconds": 4.0,
	"front_damage_reduction": 0.50,
	"counter_damage_ratio": 0.25,
	"counter_range": 185.0,
	"guard_move_multiplier": 0.70,
	"rear_hit_threshold": 3,
	"rear_dot_threshold": -0.35,
	"recovery_seconds": 1.50,
	"break_seconds": 2.0,
	"break_damage_taken_increase": 0.20,
}

static func awakening_for(stage_id: String) -> Dictionary:
	match stage_id:
		"stage_1":
			return STAGE_1
		"stage_2":
			return STAGE_2
		"stage_3":
			return STAGE_3
	return {}


static func demon_stage_available(stage_id: String) -> bool:
	return stage_id in RELEASED_DEMON_STAGES

static func run_reward_multiplier(outcome: String) -> float:
	return maxf(float(RUN_REWARDS.get(outcome, 1.0)), 0.0)
