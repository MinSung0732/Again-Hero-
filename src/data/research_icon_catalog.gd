extends RefCounted
# Reuse shipped pixel icons by research purpose; atlas textures remain cached.
const SOURCES := {
	"monster_power":"survival_power",
	"monster_vitality":"survival_vitality",
	"monster_mobility":"survival_mobility",
	"monster_attack_speed":"survival_haste",
	"summon_efficiency":"summoner_hero_rift_orbit",
	"mana_cycle":"ranged_rookie_pulse_staff",
	"mana_reservoir":"ranged_rookie_arcane_bolt",
	"rapid_experiment":"chemical_hero_antidote_capsule",
	"tactical_notebook":"survival_learning",
}

const HERO_SOURCES := {
	"vitality":"survival_vitality", "regeneration":"survival_recovery",
	"power":"survival_power", "shield":"survival_armor",
	"mobility":"survival_mobility", "haste":"survival_haste",
	"siphon":"survival_siphon", "gold":"purifier_hero_saint_reliquary",
	"learning":"survival_learning", "magnet":"survival_magnet",
	"area":"survival_area", "ranged_reach":"survival_reach",
}
