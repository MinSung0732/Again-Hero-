extends RefCounted
## Character resources/passives reuse HeroProfiles, independent of weapon ranks.
const ARCHETYPES := {
	"ranged_kiter":{"label":"마력","config":"ultimate_config","max":"charge_max","regen":"charge_per_second","attack":"charge_on_attack","signature":"ranged_rookie_magic_lance","ensure":"_ensure_stage1_audio_runtime","audio":"_play_stage1_audio","arg":&"basic"},
	"rogue_combo":{"label":"암살","config":"ultimate_config","max":"charge_max","regen":"charge_per_second","attack":"charge_on_attack","signature":"swift_hunter_shadow_bomb","ensure":"_ensure_rogue_audio_runtime","audio":"_play_rogue_combo_audio","arg":0,"native_basic":"_rogue_combo_attack"},
	"sword_shield":{"label":"막기","ensure":"_ensure_fighter_audio_runtime","audio":"_play_fighter_slash_audio"},
	"pistol_gunner":{"label":"탄약","ensure":"_ensure_gunner_audio_runtime","audio":"_play_gunner_basic_shot_audio","ammo_weapons":["pistol_hero_revolver","pistol_hero_rifle","pistol_hero_ricochet"]},
	"archmage_elementalist":{"label":"원소","config":"archmage_skill_config","max":"gauge_max","regen":"gauge_per_second","attack":"gauge_per_basic_attack","ensure":"_ensure_archmage_audio_runtime","audio":"_play_archmage_basic_audio","arg":"fire","native_basic":"_fire_archmage_projectile","pools":["archmage_projectile"]},
	"berserker_madness":{"label":"광기","ensure":"_ensure_berserker_audio_runtime","audio":"_play_berserker_basic_audio"},
	"alchemist_chemical":{"label":"가스","ensure":"_ensure_alchemist_runtime","audio_path":"res://assets/audio/sfx/alchemist_vial_throw.wav","impact_path":"res://assets/audio/sfx/alchemist_vial_break.wav","gas_costs":{"chemical_hero_acid_vial":["basic_gas_cost"],"chemical_hero_poison_flask":["mixture_field","gas_cost"],"chemical_hero_cryo_vial":["basic_gas_cost"],"chemical_hero_acid_cannon":["basic_gas_cost"]},"gas_periods":{"chemical_hero_poison_flask":["mixture_field","cooldown"]}},
	"summoner_gatekeeper":{"label":"소환","ensure":"_ensure_summoner_runtime","player":"summoner_basic_audio"},
	"cleric_purifier":{"label":"신성","ensure":"_ensure_purifier_basic_audio","audio":"_play_purifier_basic_audio"},
	"grand_sage_astra":{"label":"마력","ensure":"_ensure_sage_runtime","player":"sage_basic_audio","native_basic":"_fire_sage_projectile","pools":["sage_basic_projectile","sage_piercing_projectile"]},
}
