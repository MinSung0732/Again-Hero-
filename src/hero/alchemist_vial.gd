extends Node2D

signal landed(world_position: Vector2, direct_target: Node)

const PROJECTILE_TEXTURE := preload("res://assets/art/heroes/stage7_alchemist/frames/effect1/effect_01.png")
const BREAK_TEXTURES := [
	preload("res://assets/art/heroes/stage7_alchemist/frames/effect5/effect_01.png"),
	preload("res://assets/art/heroes/stage7_alchemist/frames/effect5/effect_02.png"),
	preload("res://assets/art/heroes/stage7_alchemist/frames/effect5/effect_03.png"),
	preload("res://assets/art/heroes/stage7_alchemist/frames/effect5/effect_04.png"),
]

@onready var projectile_sprite: Sprite2D = $Projectile
@onready var break_sprite: AnimatedSprite2D = $Break

var phase: int = 0
var flight_origin := Vector2.ZERO
var flight_target := Vector2.ZERO
var flight_duration: float = 0.46
var flight_elapsed: float = 0.0
var arc_height: float = 120.0
var direct_hit_target: Node = null

func _ready() -> void:
	projectile_sprite.texture = PROJECTILE_TEXTURE
	projectile_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	break_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	frames.add_animation("break")
	frames.set_animation_speed("break", 14.0)
	frames.set_animation_loop("break", false)
	for texture in BREAK_TEXTURES:
		frames.add_frame("break", texture)
	break_sprite.sprite_frames = frames
	break_sprite.animation_finished.connect(_on_break_finished)
	_deactivate()

func is_available() -> bool:
	return phase == 0

func launch(
	origin: Vector2,
	target: Vector2,
	duration: float,
	height: float,
	direct_target: Node = null
) -> void:
	flight_origin = origin
	flight_target = target
	flight_duration = maxf(duration, 0.08)
	flight_elapsed = 0.0
	arc_height = maxf(height, 0.0)
	direct_hit_target = direct_target
	phase = 1
	global_position = origin
	visible = true
	projectile_sprite.visible = true
	break_sprite.visible = false
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if phase != 1:
		return
	flight_elapsed += delta
	var t := clampf(flight_elapsed / flight_duration, 0.0, 1.0)
	global_position = flight_origin.lerp(flight_target, t)
	global_position.y -= 4.0 * arc_height * t * (1.0 - t)
	if t < 1.0:
		return
	global_position = flight_target
	projectile_sprite.visible = false
	break_sprite.visible = true
	phase = 2
	set_physics_process(false)
	landed.emit(flight_target, direct_hit_target)
	direct_hit_target = null
	break_sprite.stop()
	break_sprite.frame = 0
	break_sprite.play("break")

func _on_break_finished() -> void:
	if phase == 2:
		_deactivate()

func _deactivate() -> void:
	phase = 0
	direct_hit_target = null
	visible = false
	projectile_sprite.visible = false
	break_sprite.visible = false
	set_physics_process(false)
