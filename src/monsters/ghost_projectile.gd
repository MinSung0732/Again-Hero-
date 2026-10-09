extends Area2D

const NORMAL_TEXTURE_PATH := (
	"res://assets/art/monsters/ghost/frames/effect1/Projectile_01.png"
)
const ELITE_TEXTURE_PATH := (
	"res://assets/art/elitemonster/ghost/frames/effect1/Projectile_01.png"
)
const POOL_KEY := "ghost_projectile"
const TARGET_SIZE := 48.0

static var _texture_cache: Dictionary = {}

var direction: Vector2 = Vector2.RIGHT
var speed: float = 500.0
var max_range: float = 360.0
var damage: int = 4
var traveled_distance: float = 0.0
var active: bool = false
var elite_visual: bool = false

@onready var projectile_sprite: Sprite2D = $ProjectileSprite


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	deactivate_for_pool()


func setup(
	new_direction: Vector2,
	new_damage: int,
	new_speed: float,
	new_max_range: float,
	use_elite_visual: bool,
	new_size_multiplier: float = 1.0
) -> void:
	direction = new_direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	damage = maxi(new_damage, 1)
	speed = maxf(new_speed, 1.0)
	max_range = maxf(new_max_range, 1.0)
	elite_visual = use_elite_visual
	traveled_distance = 0.0
	active = true
	rotation = direction.angle()
	scale = Vector2.ONE * maxf(new_size_multiplier, 0.1)
	if not is_in_group("monster_projectiles"):
		add_to_group("monster_projectiles")
	visible = true
	monitoring = true
	set_physics_process(true)
	_apply_visual()


func _physics_process(delta: float) -> void:
	if not active:
		return
	var step := direction * speed * delta
	global_position += step
	traveled_distance += step.length()
	if traveled_distance >= max_range:
		_finish_projectile()


func _on_body_entered(body: Node) -> void:
	if (
		not active
		or body == null
		or body.is_queued_for_deletion()
		or not body.is_in_group("hero")
	):
		return

	active = false
	set_deferred("monitoring", false)
	set_physics_process(false)

	if body.has_method("take_damage"):
		body.call("take_damage", damage, _combat_source())

	var authority := get_parent()
	if (
		is_instance_valid(authority)
		and authority.has_method("register_ghost_projectile_hit")
	):
		authority.call("register_ghost_projectile_hit")

	# Recycle outside the body_entered signal callback. Area2D monitoring
	# cannot be changed synchronously while the physics query is flushing.
	call_deferred("_finish_projectile")


func _apply_visual() -> void:
	var texture := _get_texture()
	if texture == null:
		return
	projectile_sprite.texture = texture
	projectile_sprite.texture_filter = (
		CanvasItem.TEXTURE_FILTER_NEAREST
	)
	var source_size := maxf(
		float(maxi(texture.get_width(), texture.get_height())),
		1.0
	)
	projectile_sprite.scale = (
		Vector2.ONE * (TARGET_SIZE / source_size)
	)
	projectile_sprite.visible = true


func _get_texture() -> Texture2D:
	var path := (
		ELITE_TEXTURE_PATH
		if elite_visual
		else NORMAL_TEXTURE_PATH
	)
	var cached = _texture_cache.get(path)
	if cached is Texture2D:
		return cached as Texture2D
	if ResourceLoader.exists(path):
		var loaded = load(path)
		if loaded is Texture2D:
			_texture_cache[path] = loaded
			return loaded as Texture2D
	return null


func _finish_projectile() -> void:
	var authority := get_parent()
	if (
		is_instance_valid(authority)
		and authority.has_method("recycle_projectile")
	):
		authority.call(
			"recycle_projectile",
			self,
			POOL_KEY
		)
	else:
		queue_free()


func deactivate_for_pool() -> void:
	if has_meta("combat_source"):
		remove_meta("combat_source")
	active = false
	traveled_distance = 0.0
	direction = Vector2.RIGHT
	speed = 500.0
	max_range = 360.0
	damage = 4
	elite_visual = false
	rotation = 0.0
	scale = Vector2.ONE
	if is_in_group("monster_projectiles"):
		remove_from_group("monster_projectiles")
	monitoring = false
	set_physics_process(false)
	visible = false
	if is_instance_valid(projectile_sprite):
		projectile_sprite.visible = false
		projectile_sprite.texture = null
		projectile_sprite.scale = Vector2.ONE

func _combat_source() -> Node:
	var reference = get_meta("combat_source",null)
	return reference.get_ref() if reference is WeakRef else null
