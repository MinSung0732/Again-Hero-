extends RefCounted

const POOL_KEY := "hero_basic_projectile"
const DEFAULT_SPEED := 680.0
const DEFAULT_RANGE := 420.0
const DEFAULT_DAMAGE := 34
const CHEST_HIT_RADIUS := 36.0
const EMPTY_PROFILE := {}
const PROFILES := {
	"ranged_rookie": {
		"flight_animation": &"fly", "scale": Vector2.ONE,
		"animations": [{"name": &"fly", "fps": 12.0, "loop": true, "paths": [
				"res://assets/art/projectiles/stage1_mage/projectile_01.png",
				"res://assets/art/projectiles/stage1_mage/projectile_02.png",
				"res://assets/art/projectiles/stage1_mage/projectile_03.png",
				"res://assets/art/projectiles/stage1_mage/projectile_04.png",
			]}],
	},
	"purifier_hero": {
		"flight_animation": &"fly", "impact_animation": &"impact",
		"damage_multiplier_method": &"get_purifier_holy_damage_multiplier",
		"scale": Vector2(0.46, 0.46), "nearest": true,
		"animations": [
			{"name": &"fly", "fps": 14.0, "loop": true, "paths": [
				"res://assets/art/heroes/stage9_prist/frames/effect1/effect_01.png",
				"res://assets/art/heroes/stage9_prist/frames/effect1/effect_02.png",
				"res://assets/art/heroes/stage9_prist/frames/effect1/effect_03.png",
				"res://assets/art/heroes/stage9_prist/frames/effect1/effect_04.png",
				"res://assets/art/heroes/stage9_prist/frames/effect1/effect_05.png",
				"res://assets/art/heroes/stage9_prist/frames/effect1/effect_06.png",
			]},
			{"name": &"impact", "fps": 18.0, "loop": false, "paths": [
				"res://assets/art/heroes/stage9_prist/frames/effect1/effect_07.png",
				"res://assets/art/heroes/stage9_prist/frames/effect1/effect_08.png",
				"res://assets/art/heroes/stage9_prist/frames/effect1/effect_09.png",
				"res://assets/art/heroes/stage9_prist/frames/effect1/effect_10.png",
			]},
		],
	},
}

static func profile(hero_id: String) -> Dictionary:
	# Immutable shared metadata, no per-hit Dictionary copy or file load.
	return PROFILES.get(hero_id, EMPTY_PROFILE)
