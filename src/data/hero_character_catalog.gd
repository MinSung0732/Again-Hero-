extends RefCounted

# Stable character IDs are separate from the selected battlefield and weapon IDs.
const DEFAULT_HERO := "ranged_rookie"
const ORDER := ["ranged_rookie","swift_hunter","sword_shield_hero","pistol_hero","archmage_hero","madness_hero","chemical_hero","summoner_hero","purifier_hero","sage_astra"]
const CHARACTERS := {
	"ranged_rookie":{"name":"견습마도사","stage":"stage_1","style":"마력탄·결계·별빛으로 안전하게 성장하는 마법사"},
	"swift_hunter":{"name":"날렵한 용사","stage":"stage_2","style":"단검·독침·그림자 무기로 빠르게 빈틈을 노리는 암살자"},
	"sword_shield_hero":{"name":"검과 방패의 용사","stage":"stage_3","style":"검격·방패·깃발로 포위를 버티는 전사"},
	"pistol_hero":{"name":"권총의 용사","stage":"stage_4","style":"권총·산탄·저격·수류탄으로 거리를 지키는 사수"},
	"archmage_hero":{"name":"대마법 용사","stage":"stage_5","style":"화염·냉기·번개·대지로 넓은 전장을 제어하는 마도사"},
	"madness_hero":{"name":"광기의 용사","stage":"stage_6","style":"혈검·혈륜·흡혈 파동으로 위험 속에서 싸우는 검사"},
	"chemical_hero":{"name":"화학의 용사","stage":"stage_7","style":"산성·독성·냉각 약병과 회복제로 구역을 만드는 연금술사"},
	"summoner_hero":{"name":"이계의 용사","stage":"stage_8","style":"수호체·정찰체·이계의 문으로 공세를 막는 소환사"},
	"purifier_hero":{"name":"정화의 용사","stage":"stage_9","style":"성광·정화·성창과 축복으로 생존하는 성직자"},
	"sage_astra":{"name":"대현자 아스트라","stage":"stage_10","style":"별빛·혜성·중력·빙점으로 전장을 다루는 대현자"},
}
# Lv.1, no permanent research/passives. Unlock order grants kit options,
# not unconditional upgrades; weapon periods/ranges remain weapon-owned.
const STARTING_STATS := {
	"ranged_rookie":{"max_hp":1200,"attack_damage":26,"move_speed":270.0,"exp_pickup_radius":165.0},
	"swift_hunter":{"max_hp":980,"attack_damage":25,"move_speed":315.0,"exp_pickup_radius":140.0},
	"sword_shield_hero":{"max_hp":1500,"attack_damage":24,"move_speed":245.0,"exp_pickup_radius":155.0},
	"pistol_hero":{"max_hp":1080,"attack_damage":27,"move_speed":290.0,"exp_pickup_radius":150.0},
	"archmage_hero":{"max_hp":1050,"attack_damage":30,"move_speed":255.0,"exp_pickup_radius":175.0},
	"madness_hero":{"max_hp":1150,"attack_damage":28,"move_speed":280.0,"exp_pickup_radius":135.0},
	"chemical_hero":{"max_hp":1200,"attack_damage":25,"move_speed":255.0,"exp_pickup_radius":165.0},
	"summoner_hero":{"max_hp":1100,"attack_damage":23,"move_speed":250.0,"exp_pickup_radius":180.0},
	"purifier_hero":{"max_hp":1250,"attack_damage":22,"move_speed":260.0,"exp_pickup_radius":160.0},
	"sage_astra":{"max_hp":1100,"attack_damage":24,"move_speed":265.0,"exp_pickup_radius":175.0},
}
static func get_character(id: String) -> Dictionary:
	return CHARACTERS.get(id,{})
static func hero_for_stage(stage: String) -> String:
	for id in ORDER:
		if String(CHARACTERS[id].stage) == stage: return id
	return ""
static func stage_for_hero(id: String) -> String:
	return String(CHARACTERS.get(id,{}).get("stage",""))
