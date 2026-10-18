extends Node2D
var area_attack = preload("res://src/hero/summon_area_attack.gd").new()

const HERO_TARGET_POLICY := preload("res://src/systems/hero_target_policy.gd")

signal released(projectile: Node2D)

const FLY_TEXTURE_PATH := "res://assets/art/heroes/stage8_summoner/frames/effect1/projectile_01.png"
const HIT_TEXTURE_PATH := "res://assets/art/heroes/stage8_summoner/frames/effect1/projectile_02.png"
const FIT := preload("res://src/ui/hero_weapon_visual_fit.gd")
var fly_bounds := Rect2()
var hit_bounds := Rect2()

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
	fly_bounds = FIT.warm(PackedStringArray([FLY_TEXTURE_PATH]))
	hit_bounds = FIT.warm(PackedStringArray([HIT_TEXTURE_PATH]))
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	deactivate()


func activate(
	world_position: Vector2,
	new_target: Node2D,
	new_damage: int,
	new_speed: float,
	new_max_range: float
) -> void:
	area_attack.reset()
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
	sprite.offset = Vector2.ZERO
	_fit_survival_sprite(fly_bounds,52.0)
	sprite.rotation = direction.angle()
	active = true
	visible = true
	if not is_in_group("hero_summon_projectiles"):
		add_to_group("hero_summon_projectiles")
	set_physics_process(true)


func _fit_survival_sprite(bounds: Rect2, size: float) -> void:
	if not bool(get_meta("survival_presentation",false)) or not bounds.has_area(): return
	sprite.scale = Vector2.ONE*size/maxf(bounds.size.x,bounds.size.y)
	sprite.offset = -bounds.get_center()


func _physics_process(delta: float) -> void:
	if not active:
		return
	area_attack.tick(delta)
	if area_attack.flash_left > 0.0: queue_redraw()
	if is_instance_valid(target) and not HERO_TARGET_POLICY.is_detectable(target):
		target = null

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
	if HERO_TARGET_POLICY.is_detectable(target) and target.has_method("take_damage"):
		if preload("res://src/systems/monster_hit_context.gd").reflect_projectile(target,damage,self,self):
			deactivate()
			return
		var area_origin: Vector2 = target.global_position
		var area_primary_id: int = target.get_instance_id()
		preload("res://src/systems/monster_hit_context.gd").hit(target, damage, "ranged", self)
		area_attack.strike(self,area_primary_id,area_origin,damage,"ranged",self)
	sprite.texture = hit_texture
	sprite.scale = Vector2(0.48, 0.48)
	sprite.offset = Vector2.ZERO
	_fit_survival_sprite(hit_bounds,56.0)
	sprite.rotation = 0.0
	impact_timer = IMPACT_SECONDS


func deactivate() -> void:
	area_attack.reset()
	if not active and not visible:
		return
	active = false
	target = null
	visible = false
	set_physics_process(false)
	if is_in_group("hero_summon_projectiles"):
		remove_from_group("hero_summon_projectiles")
	released.emit(self)


func is_available() -> bool:
	return not active


func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var resource = load(path)
		if resource is Texture2D:
			return resource
	return null

func _draw() -> void:
	if active: area_attack.draw(self)
