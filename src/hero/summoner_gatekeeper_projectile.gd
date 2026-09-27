extends Node2D

signal released(projectile: Node2D)

const FLY_TEXTURE_PATH := "res://assets/art/heroes/stage8_summoner/frames/effect1/projectile_01.png"
const HIT_TEXTURE_PATH := "res://assets/art/heroes/stage8_summoner/frames/effect1/projectile_02.png"
const HIT_RADIUS := 30.0
const IMPACT_SECONDS := 0.10

@onready var sprite: Sprite2D = $Sprite

var active: bool = false
var target: Node2D = null
var direction: Vector2 = Vector2.RIGHT
var speed: float = 560.0
var max_range: float = 760.0
var damage: int = 1
var traveled: float = 0.0
var impact_timer: float = 0.0
var fly_texture: Texture2D
var hit_texture: Texture2D


func _ready() -> void:
	fly_texture = _load_texture(FLY_TEXTURE_PATH)
	hit_texture = _load_texture(HIT_TEXTURE_PATH)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	deactivate()


func activate(
	world_position: Vector2,
	new_target: Node2D,
	new_damage: int,
	new_speed: float,
	new_max_range: float
) -> void:
	global_position = world_position
	target = new_target
	damage = maxi(new_damage, 1)
	speed = maxf(new_speed, 1.0)
	max_range = maxf(new_max_range, 1.0)
	traveled = 0.0
	impact_timer = 0.0
	direction = Vector2.RIGHT
	if is_instance_valid(target):
		direction = global_position.direction_to(target.global_position)
	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT
	sprite.texture = fly_texture
	sprite.scale = Vector2(0.42, 0.42)
	sprite.rotation = direction.angle()
	active = true
	visible = true
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	if not active:
		return

	if impact_timer > 0.0:
		impact_timer = maxf(impact_timer - delta, 0.0)
		if impact_timer <= 0.0:
			deactivate()
		return

	if is_instance_valid(target) and not target.is_queued_for_deletion():
		if global_position.distance_squared_to(target.global_position) <= HIT_RADIUS * HIT_RADIUS:
			_impact_target()
			return

	var step := direction * speed * delta
	global_position += step
	traveled += step.length()
	if traveled >= max_range:
		deactivate()


func _impact_target() -> void:
	if is_instance_valid(target) and target.has_method("take_damage"):
		target.call("take_damage", damage)
	sprite.texture = hit_texture
	sprite.scale = Vector2(0.48, 0.48)
	sprite.rotation = 0.0
	impact_timer = IMPACT_SECONDS


func deactivate() -> void:
	if not active and not visible:
		return
	active = false
	target = null
	visible = false
	set_physics_process(false)
	released.emit(self)


func is_available() -> bool:
	return not active


func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var resource = load(path)
		if resource is Texture2D:
			return resource
	return null
