extends RefCounted

const SWAMP := "res://assets/art/maps/cursed_swamp/"
const MEADOW := "res://assets/art/maps/sunlit_meadow/"
const THEMES := {
	"castle":{"name":"성", "overrides":{}, "prop_tint":Color(0.68,0.60,0.79,1), "floor_damage":true, "strip_carpet":true},
	"cursed_swamp":{"name":"저주받은 늪지", "overrides":{"illustrated_floor":SWAMP + "floor.png", "rug_long":SWAMP + "floor_alt.png", "rug_torn_1":SWAMP + "floor_alt.png", "rug_torn_2":SWAMP + "floor_alt.png", "rug_torn_3":SWAMP + "floor_alt.png", "rug_torn_4":SWAMP + "floor_alt.png", "wall_large":SWAMP + "wall_top.png", "wall_broken_1":SWAMP + "wall_top.png", "wall_broken_2":SWAMP + "wall_top.png", "wall_broken_3":SWAMP + "wall_top.png", "wall_broken_4":SWAMP + "wall_top.png", "wall_broken_5":SWAMP + "wall_top.png", "wall_broken_6":SWAMP + "wall_top.png", "wall_broken_7":SWAMP + "wall_top.png", "wall_broken_8":SWAMP + "wall_top.png", "wall_banner":SWAMP + "wall_top.png", "wall_window":SWAMP + "wall_top.png", "wall_corner":SWAMP + "wall_top.png", "wall_arch":SWAMP + "wall_gate.png", "wall_arch_broken":SWAMP + "wall_gate.png", "throne":SWAMP + "centerpiece.png", "brazier":SWAMP + "torch.png", "pillar_a":SWAMP + "pillar.png", "pillar_b":SWAMP + "pillar.png", "pillar_broken":SWAMP + "pillar.png", "statue":SWAMP + "deco_a.png", "altar":SWAMP + "deco_a.png", "ruins":SWAMP + "deco_a.png", "crystal":SWAMP + "deco_b.png", "debris_a":SWAMP + "deco_b.png", "debris_b":SWAMP + "deco_b.png", "debris_c":SWAMP + "deco_b.png", "flag_a":SWAMP + "deco_c.png", "flag_b":SWAMP + "deco_c.png"}, "prop_tint":Color(0.80,0.92,0.78), "floor_damage":false, "strip_carpet":false},
	"sunlit_meadow":{"name":"햇살 숲 평원", "overrides":{"illustrated_floor":MEADOW + "floor.png", "rug_long":MEADOW + "floor_alt.png", "rug_torn_1":MEADOW + "floor_alt.png", "rug_torn_2":MEADOW + "floor_alt.png", "rug_torn_3":MEADOW + "floor_alt.png", "rug_torn_4":MEADOW + "floor_alt.png", "wall_large":MEADOW + "wall_top.png", "wall_broken_1":MEADOW + "wall_top.png", "wall_broken_2":MEADOW + "wall_top.png", "wall_broken_3":MEADOW + "wall_top.png", "wall_broken_4":MEADOW + "wall_top.png", "wall_broken_5":MEADOW + "wall_top.png", "wall_broken_6":MEADOW + "wall_top.png", "wall_broken_7":MEADOW + "wall_top.png", "wall_broken_8":MEADOW + "wall_top.png", "wall_banner":MEADOW + "wall_top.png", "wall_window":MEADOW + "wall_top.png", "wall_corner":MEADOW + "wall_top.png", "wall_arch":MEADOW + "wall_gate.png", "wall_arch_broken":MEADOW + "wall_gate.png", "throne":MEADOW + "centerpiece.png", "brazier":MEADOW + "torch.png", "pillar_a":MEADOW + "pillar.png", "pillar_b":MEADOW + "pillar.png", "pillar_broken":MEADOW + "pillar.png", "statue":MEADOW + "deco_a.png", "altar":MEADOW + "deco_a.png", "ruins":MEADOW + "deco_a.png", "crystal":MEADOW + "deco_b.png", "debris_a":MEADOW + "deco_b.png", "debris_b":MEADOW + "deco_b.png", "debris_c":MEADOW + "deco_b.png", "flag_a":MEADOW + "deco_c.png", "flag_b":MEADOW + "deco_c.png"}, "prop_tint":Color(1,1,1), "floor_damage":false, "strip_carpet":false},
}

static func get_theme(id: String) -> Dictionary:
	return THEMES.get(id, THEMES.castle).duplicate(true)

static func ids() -> Array[String]:
	var result: Array[String] = []
	for id in THEMES: result.append(id)
	return result
