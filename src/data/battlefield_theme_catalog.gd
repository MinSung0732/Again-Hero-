extends RefCounted

const SWAMP := "res://assets/art/maps/cursed_swamp/"
const MEADOW := "res://assets/art/maps/sunlit_meadow/"
const EFFECTS := {
	"swamp_slow":{"target":"hero", "stat":"move_speed", "value":-0.25, "label":"늪: 이동속도", "tint":Color(0.35,0.65,0.35)},
	"thorn_sting":{"target":"hero", "stat":"damage_per_second", "value":0.01, "label":"가시: 초당 최대 체력 피해", "tint":Color(0.7,0.3,0.35)},
	"meadow_bloom":{"target":"hero", "stat":"heal_per_second", "value":0.01, "label":"꽃: 초당 최대 체력 회복", "tint":Color(0.95,0.55,0.75)},
	"well_blessing":{"target":"hero", "stat":"attack_speed", "value":0.15, "label":"우물: 공격속도", "tint":Color(0.4,0.75,1.0)},
}
const EXTRAS := {
	"cursed_swamp": {"swamp_dead_tree": SWAMP + "dead_tree.png", "swamp_bone_pile": SWAMP + "bone_pile.png", "swamp_mire_pool": SWAMP + "mire_pool.png", "swamp_thorn_bush": SWAMP + "thorn_bush.png"},
	"sunlit_meadow": {"meadow_oak_tree": MEADOW + "oak_tree.png", "meadow_haystack": MEADOW + "haystack.png", "meadow_stone_well": MEADOW + "stone_well.png", "meadow_flower_patch": MEADOW + "flower_patch.png"},
}
const LAYOUTS := {
	"cursed_swamp": [
		{"key":"throne", "pos":Vector2(0.5,0.15), "scale":0.9, "kind":"solid", "collision":Vector2(110,70)},
		{"key":"swamp_dead_tree", "pos":Vector2(0.20,0.24), "scale":1.0, "kind":"solid", "collision":Vector2(100,70), "mirror":true},
		{"key":"pillar_a", "pos":Vector2(0.36,0.29), "scale":0.9, "kind":"solid", "collision":Vector2(80,65), "mirror":true},
		{"key":"swamp_dead_tree", "pos":Vector2(0.12,0.46), "scale":1.0, "kind":"solid", "collision":Vector2(100,70), "mirror":true},
		{"key":"swamp_dead_tree", "pos":Vector2(0.30,0.43), "scale":1.0, "kind":"solid", "collision":Vector2(100,70)},
		{"key":"pillar_a", "pos":Vector2(0.73,0.49), "scale":0.9, "kind":"solid", "collision":Vector2(80,65)},
		{"key":"swamp_dead_tree", "pos":Vector2(0.22,0.68), "scale":1.0, "kind":"solid", "collision":Vector2(100,70), "mirror":true},
		{"key":"pillar_b", "pos":Vector2(0.39,0.75), "scale":0.9, "kind":"solid", "collision":Vector2(80,65)},
		{"key":"swamp_dead_tree", "pos":Vector2(0.70,0.79), "scale":1.0, "kind":"solid", "collision":Vector2(100,70)},
		{"key":"swamp_mire_pool", "pos":Vector2(0.15,0.32), "scale":1.2, "kind":"ground", "mirror":true, "effect":"swamp_slow", "radius":120.0},
		{"key":"swamp_mire_pool", "pos":Vector2(0.42,0.62), "scale":1.1, "kind":"ground", "effect":"swamp_slow", "radius":120.0},
		{"key":"swamp_mire_pool", "pos":Vector2(0.76,0.63), "scale":1.2, "kind":"ground", "effect":"swamp_slow", "radius":120.0},
		{"key":"swamp_mire_pool", "pos":Vector2(0.48,0.88), "scale":1.0, "kind":"ground", "effect":"swamp_slow", "radius":120.0},
		{"key":"swamp_thorn_bush", "pos":Vector2(0.15,0.58), "scale":0.8, "kind":"depth", "mirror":true, "effect":"thorn_sting", "radius":110.0},
		{"key":"swamp_thorn_bush", "pos":Vector2(0.39,0.36), "scale":0.8, "kind":"solid", "collision":Vector2(80,60), "effect":"thorn_sting", "radius":110.0},
		{"key":"swamp_bone_pile", "pos":Vector2(0.25,0.83), "scale":0.8, "kind":"depth", "mirror":true},
		{"key":"swamp_bone_pile", "pos":Vector2(0.62,0.27), "scale":0.8, "kind":"depth"},
		{"key":"crystal", "pos":Vector2(0.10,0.74), "scale":0.7, "kind":"depth", "mirror":true},
		{"key":"crystal", "pos":Vector2(0.60,0.69), "scale":0.7, "kind":"depth"},
		{"key":"brazier", "pos":Vector2(0.28,0.18), "scale":0.7, "kind":"depth", "mirror":true},
		{"key":"brazier", "pos":Vector2(0.13,0.87), "scale":0.7, "kind":"depth", "mirror":true},
	],
	"sunlit_meadow": [
		{"key":"throne", "pos":Vector2(0.5,0.14), "scale":0.9, "kind":"solid", "collision":Vector2(110,70)},
		{"key":"meadow_oak_tree", "pos":Vector2(0.13,0.25), "scale":1.0, "kind":"solid", "collision":Vector2(120,70), "mirror":true},
		{"key":"meadow_oak_tree", "pos":Vector2(0.16,0.70), "scale":1.0, "kind":"solid", "collision":Vector2(120,70), "mirror":true},
		{"key":"meadow_haystack", "pos":Vector2(0.34,0.12), "scale":0.9, "kind":"solid", "collision":Vector2(85,60)},
		{"key":"meadow_haystack", "pos":Vector2(0.66,0.89), "scale":0.9, "kind":"solid", "collision":Vector2(85,60)},
		{"key":"meadow_stone_well", "pos":Vector2(0.86,0.48), "scale":0.9, "kind":"solid", "collision":Vector2(95,70), "effect":"well_blessing", "radius":150.0},
		{"key":"meadow_flower_patch", "pos":Vector2(0.20,0.36), "scale":1.0, "kind":"ground", "mirror":true, "effect":"meadow_bloom", "radius":120.0},
		{"key":"meadow_flower_patch", "pos":Vector2(0.32,0.23), "scale":1.0, "kind":"ground", "effect":"meadow_bloom", "radius":120.0},
		{"key":"meadow_flower_patch", "pos":Vector2(0.72,0.29), "scale":1.0, "kind":"ground", "effect":"meadow_bloom", "radius":120.0},
		{"key":"meadow_flower_patch", "pos":Vector2(0.22,0.81), "scale":1.0, "kind":"ground", "effect":"meadow_bloom", "radius":120.0},
		{"key":"meadow_flower_patch", "pos":Vector2(0.76,0.74), "scale":1.0, "kind":"ground", "effect":"meadow_bloom", "radius":120.0},
		{"key":"meadow_flower_patch", "pos":Vector2(0.48,0.80), "scale":1.0, "kind":"ground", "effect":"meadow_bloom", "radius":120.0},
		{"key":"brazier", "pos":Vector2(0.29,0.17), "scale":0.7, "kind":"depth", "mirror":true},
		{"key":"brazier", "pos":Vector2(0.14,0.85), "scale":0.7, "kind":"depth", "mirror":true},
		{"key":"flag_a", "pos":Vector2(0.23,0.14), "scale":0.7, "kind":"depth", "mirror":true},
	],
}
const THEMES := {
	"castle":{"name":"성", "overrides":{}, "prop_tint":Color(0.68,0.60,0.79,1), "floor_damage":true, "strip_carpet":true},
	"cursed_swamp":{"name":"저주받은 늪지", "overrides":{"illustrated_floor":SWAMP + "floor.png", "rug_long":SWAMP + "floor_alt.png", "rug_torn_1":SWAMP + "floor_alt.png", "rug_torn_2":SWAMP + "floor_alt.png", "rug_torn_3":SWAMP + "floor_alt.png", "rug_torn_4":SWAMP + "floor_alt.png", "wall_large":SWAMP + "wall_top.png", "wall_broken_1":SWAMP + "wall_top.png", "wall_broken_2":SWAMP + "wall_top.png", "wall_broken_3":SWAMP + "wall_top.png", "wall_broken_4":SWAMP + "wall_top.png", "wall_broken_5":SWAMP + "wall_top.png", "wall_broken_6":SWAMP + "wall_top.png", "wall_broken_7":SWAMP + "wall_top.png", "wall_broken_8":SWAMP + "wall_top.png", "wall_banner":SWAMP + "wall_top.png", "wall_window":SWAMP + "wall_top.png", "wall_corner":SWAMP + "wall_top.png", "wall_arch":SWAMP + "wall_gate.png", "wall_arch_broken":SWAMP + "wall_gate.png", "throne":SWAMP + "centerpiece.png", "brazier":SWAMP + "torch.png", "pillar_a":SWAMP + "pillar.png", "pillar_b":SWAMP + "pillar.png", "pillar_broken":SWAMP + "pillar.png", "statue":SWAMP + "deco_a.png", "altar":SWAMP + "deco_a.png", "ruins":SWAMP + "deco_a.png", "crystal":SWAMP + "deco_b.png", "debris_a":SWAMP + "deco_b.png", "debris_b":SWAMP + "deco_b.png", "debris_c":SWAMP + "deco_b.png", "flag_a":SWAMP + "deco_c.png", "flag_b":SWAMP + "deco_c.png"}, "prop_tint":Color(0.80,0.92,0.78), "floor_damage":false, "strip_carpet":false},
	"sunlit_meadow":{"name":"햇살 숲 평원", "overrides":{"illustrated_floor":MEADOW + "floor.png", "rug_long":MEADOW + "floor_alt.png", "rug_torn_1":MEADOW + "floor_alt.png", "rug_torn_2":MEADOW + "floor_alt.png", "rug_torn_3":MEADOW + "floor_alt.png", "rug_torn_4":MEADOW + "floor_alt.png", "wall_large":MEADOW + "wall_top.png", "wall_broken_1":MEADOW + "wall_top.png", "wall_broken_2":MEADOW + "wall_top.png", "wall_broken_3":MEADOW + "wall_top.png", "wall_broken_4":MEADOW + "wall_top.png", "wall_broken_5":MEADOW + "wall_top.png", "wall_broken_6":MEADOW + "wall_top.png", "wall_broken_7":MEADOW + "wall_top.png", "wall_broken_8":MEADOW + "wall_top.png", "wall_banner":MEADOW + "wall_top.png", "wall_window":MEADOW + "wall_top.png", "wall_corner":MEADOW + "wall_top.png", "wall_arch":MEADOW + "wall_gate.png", "wall_arch_broken":MEADOW + "wall_gate.png", "throne":MEADOW + "centerpiece.png", "brazier":MEADOW + "torch.png", "pillar_a":MEADOW + "pillar.png", "pillar_b":MEADOW + "pillar.png", "pillar_broken":MEADOW + "pillar.png", "statue":MEADOW + "deco_a.png", "altar":MEADOW + "deco_a.png", "ruins":MEADOW + "deco_a.png", "crystal":MEADOW + "deco_b.png", "debris_a":MEADOW + "deco_b.png", "debris_b":MEADOW + "deco_b.png", "debris_c":MEADOW + "deco_b.png", "flag_a":MEADOW + "deco_c.png", "flag_b":MEADOW + "deco_c.png"}, "prop_tint":Color(1,1,1), "floor_damage":false, "strip_carpet":false},
}

static func get_theme(id: String) -> Dictionary:
	var result: Dictionary = THEMES.get(id, THEMES.castle).duplicate(true)
	result["extra_textures"] = EXTRAS.get(id, {}).duplicate(true)
	result["layout"] = LAYOUTS.get(id, []).duplicate(true)
	return result

static func ids() -> Array[String]:
	var result: Array[String] = []
	for id in THEMES: result.append(id)
	return result
