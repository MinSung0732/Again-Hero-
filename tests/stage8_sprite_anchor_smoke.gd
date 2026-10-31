extends SceneTree
## Stage 8's authored body anchor is (180,257) in each 512x288 frame.
## Both movement turns and weapon-driven attack turns must mirror its X offset.
const HERO := preload("res://src/hero/hero.gd")
const CELL_CENTER_X := 256.0
const BODY_ANCHOR_X := 180.0
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, reason: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("STAGE8_ANCHOR: "+reason)

func check_center(sprite: AnimatedSprite2D, reason: String) -> void:
	var local_x := BODY_ANCHOR_X-CELL_CENTER_X
	var visual_x := sprite.offset.x+(-local_x if sprite.flip_h else local_x)
	check(is_equal_approx(visual_x,0.0),reason)
	check(is_equal_approx(sprite.offset.y,-84.0),reason+" vertical anchor stays fixed")

func run() -> void:
	var hero := HERO.new()
	var sprite := AnimatedSprite2D.new()
	hero.add_child(sprite)
	hero.hero_sprite = sprite
	hero.hero_archetype = "summoner_gatekeeper"
	hero.facing_switch_delay = 0.0
	hero.facing_min_horizontal_speed = 1.0
	hero._apply_stage8_sprite_anchor()
	check_center(sprite,"walk/right initial anchor")

	# A movement-facing change was missing the Stage 8 mirror compensation.
	hero._update_facing_from_horizontal(-200.0,0.1)
	hero._update_facing_from_horizontal(-200.0,0.1)
	check(sprite.flip_h,"walking faces left")
	check_center(sprite,"walk/left anchor")

	# Player-controlled weapons frequently face a target opposite movement.
	hero._face_attack_direction(200.0)
	check(not sprite.flip_h,"attack faces right")
	check_center(sprite,"attack/right anchor")
	hero._face_attack_direction(-200.0)
	check(sprite.flip_h,"attack faces left")
	check_center(sprite,"attack/left anchor")

	# Resuming movement must not keep the prior attack direction's offset.
	hero._update_facing_from_horizontal(200.0,0.1)
	hero._update_facing_from_horizontal(200.0,0.1)
	check(not sprite.flip_h,"walking returns right")
	check_center(sprite,"walk/right restored anchor")
	hero.free()
	print("STAGE8_ANCHOR checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
