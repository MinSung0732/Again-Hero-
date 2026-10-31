extends RefCounted
class_name HardCampaignCatalog

# Release hard mode one demon stage at a time; hero-perspective hard is separate.
const RELEASED_DEMON_STAGES := ["stage_1"]

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
	"cutscene_texture_path": "res://assets/art/heroes/stage1_mage/cutscene/stage1_hero_cutscene.png",
	"cutscene_hold_seconds": 1.05,
	"min_projectiles": 3,
	"piercer_every_attacks": 3,
	"piercer_windup_seconds": 0.70,
	"weakness_seconds": 2.00,
	"weakness_damage_taken_increase": 0.20,
}

static func demon_stage_available(stage_id: String) -> bool:
	return stage_id in RELEASED_DEMON_STAGES

static func run_reward_multiplier(outcome: String) -> float:
	return maxf(float(RUN_REWARDS.get(outcome, 1.0)), 0.0)
