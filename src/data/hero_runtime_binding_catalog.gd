extends RefCounted
## Runtime bindings only. Shared property lists are borrowed read-only; callers
## retaining a mutable snapshot must duplicate at that boundary.
const EMPTY_PROFILE := {}
const EMPTY_PROPERTIES := []
const ARCHMAGE_SKILL_KEYS: Array[String] = [
	"combustion",
	"ice_bolt",
	"earth_spikes",
	"holy_power",
	"chain_dagger",
	"harmony",
	"storm",
]

const PROPERTY_COOLDOWNS := {
	"grand_sage_astra": {
		"properties": [&"sage_skill1_cooldown_timer", &"sage_skill2_cooldown_timer", &"sage_skill3_cooldown_timer", &"sage_skill4_cooldown_timer"],
		"conditional_skill": &"sage_skill_5",
		"expanded_properties": [&"sage_skill1_cooldown_timer", &"sage_skill2_cooldown_timer", &"sage_skill3_cooldown_timer", &"sage_skill4_cooldown_timer", &"sage_skill5_cooldown_timer"],
	},
	"cleric_purifier": {
		"properties": [&"purifier_crown_cooldown", &"purifier_orb_cooldown", &"purifier_cleansing_cooldown"],
		"conditional_skill": &"purifier_fourth_skill",
		"expanded_properties": [&"purifier_crown_cooldown", &"purifier_orb_cooldown", &"purifier_cleansing_cooldown", &"purifier_gungnir_cooldown"],
	},
	"summoner_gatekeeper": {
		"properties": [&"summoner_gatekeeper_cooldown", &"summoner_scout_cooldown", &"summoner_hound_cooldown", &"summoner_watcher_cooldown"],
		"unlock_property": &"summoner_open_gate_unlocked",
		"expanded_properties": [&"summoner_gatekeeper_cooldown", &"summoner_scout_cooldown", &"summoner_hound_cooldown", &"summoner_watcher_cooldown", &"summoner_open_gate_cooldown"],
	},
	"alchemist_chemical": {
		"properties": [&"alchemist_mixture_field_cooldown", &"alchemist_mystery_cauldron_cooldown", &"alchemist_emergency_cooldown"],
	},
	"ranged_kiter": {
		"properties": [&"ultimate_cooldown_timer", &"shield_cooldown_timer", &"channel_cooldown_timer"],
	},
	"rogue_combo": {
		"properties": [&"rogue_slash_cooldown_timer", &"ultimate_cooldown_timer"],
	},
	"sword_shield": {
		"properties": [&"fighter_charge_cooldown_timer"],
	},
	"pistol_gunner": {
		"properties": [&"gunner_backstep_cooldown", &"gunner_cylinder_cooldown", &"gunner_deadeye_cooldown"],
	},
	"berserker_madness": {
		"properties": [&"berserker_skill1_cooldown", &"berserker_skill2_cooldown", &"berserker_skill3_cooldown", &"berserker_skill4_cooldown"],
	},
}
const DICTIONARY_COOLDOWNS := {
	"archmage_elementalist": {
		"keys": ARCHMAGE_SKILL_KEYS,
		"config_property": &"archmage_skill_config",
		"timers_property": &"archmage_skill_cooldowns",
	},
}

# The player pose and specialized AI owner must stay paired. Unknown/ranged
# archetypes retain the common AI path and the shared Stage1 pose callback.
const DEFAULT_POSE_TICK := &"_update_stage1_pose_visual"
const ACTION_BINDINGS := {
	"rogue_combo": {"physics": &"_physics_process_rogue", "pose": &"_update_rogue_pose_visual"},
	"sword_shield": {"physics": &"_physics_process_fighter", "pose": &"_update_fighter_pose_visual"},
	"pistol_gunner": {"physics": &"_physics_process_gunner", "pose": &"_update_gunner_pose_visual"},
	"berserker_madness": {"physics": &"_physics_process_berserker", "pose": &"_update_berserker_pose_visual"},
	"alchemist_chemical": {"physics": &"_physics_process_alchemist", "pose": &"_update_alchemist_pose_visual"},
	"summoner_gatekeeper": {"physics": &"_physics_process_summoner", "pose": &"_update_summoner_pose_visual"},
	"archmage_elementalist": {"common_runtime": &"_update_archmage_skill_runtime"},
}
