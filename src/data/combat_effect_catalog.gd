extends RefCounted

# Per-actor, cached animations. Paths retain the uploaded asset spelling.
const EFFECTS := {
	"wolf_howl": {"path":"buff/gold_attack_ring/gold_attack_ring_frame_%02d.png", "property":"howl_buff_timer", "offset":Vector2.ZERO},
	"wolf_pack_agility": {"path":"buff/speed_up/speed_up_frame_%02d.png", "meta":"wolf_pack_speed_multiplier", "threshold":1.0, "offset":Vector2.ZERO},
	"charm": {"path": "buff/heart_magic/heart_magic_frame_%02d.png", "property": "charm_timer", "offset": Vector2(0, -40)},
	"petrify": {"path": "debuff/stone_explosion/stone_explosion_frame_%02d.png", "property": "petrify_timer", "offset": Vector2(0, 18)},
	"bleed": {"path": "debuff/blood_splash/blood_splash_frame_%02d.png", "property": "bleed_timer", "offset": Vector2(0, -10)},
	"healing_reduction": {"path": "debuff/dark_heal_block/dark_heal_block_frame_%02d.png", "property": "healing_reduction_timer", "offset": Vector2(0, -10)},
	"dullahan_regen": {"path": "buff/green_heal_aura/green_heal_aura_frame_%02d.png", "property": "danger_state", "equals": 2, "offset": Vector2(0, 40)},
	"support_courage": {"path": "buff/gold_attack_ring/gold_attack_ring_frame_%02d.png", "meta": "support_damage_multiplier", "threshold": 1.0, "offset": Vector2(0, 25)},
	"support_agility": {"path": "buff/speed_up/speed_up_frame_%02d.png", "meta": "support_speed_multiplier", "threshold": 1.0, "offset": Vector2(0, 40)},
	"support_heal": {"path": "buff/green_heal/green_heal_frame_%02d.png", "pulse": true, "offset": Vector2.ZERO},
	"succubus_cut": {"path": "res://assets/art/elitemonster/Succubus/frames/effect1/blood_slash_frame_%02d.png", "pulse": true, "offset": Vector2.ZERO},
}
const FRAME_COUNT := 8
const FPS := 12.0
const MONSTER_SCALE := 0.22
const HERO_SCALE := 0.28

# Fit visible pixels, not the large transparent asset canvas.
const MONSTER_BUFF_LAYOUTS := {
	"wolf_howl": {"anchor":"feet", "width_ratio":1.45},
	"wolf_pack_agility": {"anchor":"feet", "width_ratio":1.45},
	"dullahan_regen": {"anchor": "feet", "width_ratio": 1.45},
	"support_courage": {"anchor": "feet", "width_ratio": 1.45},
	"support_agility": {"anchor": "feet", "width_ratio": 1.45},
	"support_heal": {"anchor": "body", "width_ratio": 1.20},
	"orc_rage": {"anchor": "body", "width_ratio": 1.25},
}
