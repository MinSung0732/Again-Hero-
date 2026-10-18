extends Node2D

const HERO_PRESENTATION = preload("res://src/data/hero_presentation_catalog.gd")
class DrawRecorder extends RefCounted:
	var commands: Array = []
	func draw_rect(rect: Rect2, color: Color, filled: bool):
		commands.append([&"rect", rect, color, filled])
class GaugeRecorder extends RefCounted:
	func draw_on(overlay, _hero, y: float, width: float):
		overlay.commands.append([&"gauge", y, width])
class COMBAT_DELAY extends RefCounted:
	static func now_msec(node) -> int:
		return node.fixture_now

var hero_archetype: String = "unknown"
var is_dying := false
var bar_queries: Array = []
var status_overlay = DrawRecorder.new()
var player_control_gauge = GaugeRecorder.new()
var player_controlled := false
var player_weapons = null
var gunner_magazine_size := 6
var gunner_ammo := 3
var gunner_reloading := false
var gunner_reload_timer := 1.2
var gunner_config: Dictionary = {}
var fixture_slots := 3
var fixture_active := 1
var alchemist_gas := 40.0
var alchemist_gas_max := 100.0
var ultimate_charge := 50.0
var ultimate_config: Dictionary = {}
var purifier_gauge_config: Dictionary = {}
var berserker_config: Dictionary = {}
var current_hp := 50
var max_hp := 100
var shield_hp := 10.0
var shield_max_hp := 20.0
var hero_sprite: AnimatedSprite2D
var berserker_reviving := false
var hit_pose_timer := 0.0
var attack_pose_timer := 0.0
var berserker_skill3_active := false
var fighter_charge_active := false
var hero_animation_last_restart_name: StringName = &""
var hero_animation_last_restart_msec := 0
var fixture_now := 1000
var anchors: Array = []

func _init():
	hero_sprite = AnimatedSprite2D.new()
	add_child(hero_sprite)
	var frames := SpriteFrames.new()
	for animation in [&"death", &"hit", &"dash_start", &"dash_finish", &"attack", &"run", &"move", &"idle", &"custom"]:
		frames.add_animation(animation)
		for i in range(3):
			frames.add_frame(animation, ImageTexture.create_from_image(Image.create(4, 4, false, Image.FORMAT_RGBA8)))
	hero_sprite.sprite_frames = frames

func _get_summoner_slot_capacity() -> int:
	bar_queries.append(&"capacity")
	return fixture_slots

func _get_active_summon_count() -> int:
	bar_queries.append(&"active")
	return fixture_active

func _apply_stage9_sprite_anchor() -> void:
	anchors.append([hero_sprite.animation, hero_sprite.frame, hero_sprite.flip_h])

func animation_state():
	return [hero_sprite.animation, hero_sprite.frame, hero_sprite.frame_progress, hero_sprite.speed_scale, hero_sprite.is_playing(), hero_animation_last_restart_name, hero_animation_last_restart_msec]
