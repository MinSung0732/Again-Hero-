extends Node2D
const CLOCK_GUMIHO_REFLECTED_PROJECTILE = preload("res://src/systems/battle_clock.gd")
var target_ref: WeakRef
var source_ref: WeakRef
var damage := 0
var speed := 400.0
var lifetime := 0.0
var active := false
@onready var sprite: Sprite2D = $Sprite
func configure(source: Node2D, target: Node2D, original: Node2D, amount: int) -> void:
	active = true; lifetime = 0.0; speed = 400.0; show(); set_physics_process(true); sprite.texture = null
	source_ref = weakref(source); target_ref = weakref(target); damage = amount; global_position = original.global_position
	var original_speed = original.get("speed")
	if original_speed != null: speed = maxf(float(original_speed),50.0)
	for child in original.get_children():
		var texture: Texture2D
		if child is Sprite2D: texture = child.texture
		elif child is AnimatedSprite2D and child.sprite_frames != null and child.sprite_frames.get_frame_count(child.animation) > child.frame:
			texture = child.sprite_frames.get_frame_texture(child.animation,child.frame)
		if texture != null:
			sprite.texture = texture; sprite.scale = child.scale; break
	queue_redraw()
func _physics_process(delta: float) -> void:
	delta = CLOCK_GUMIHO_REFLECTED_PROJECTILE.scaled(self, delta)
	if not active: return
	lifetime += delta
	var target = target_ref.get_ref() if target_ref != null else null
	if not is_instance_valid(target) or lifetime > 8.0 or int(target.get("current_hp")) <= 0: _finish(); return
	var distance := global_position.distance_to(target.global_position)
	if distance <= speed*delta+16.0:
		var source = source_ref.get_ref() if source_ref != null else null
		target.call("take_damage",damage,source)
		_finish(); return
	var direction := global_position.direction_to(target.global_position)
	global_position += direction*speed*delta; rotation = direction.angle()
func _draw() -> void:
	if not is_instance_valid(sprite) or sprite.texture == null: draw_circle(Vector2.ZERO,5.0,Color(0.6,0.3,1.0))

func _finish() -> void:
	if not active: return
	var authority := get_parent()
	if is_instance_valid(authority) and authority.has_method("recycle_projectile"): authority.recycle_projectile(self,"gumiho_reflection")
	else: active = false; queue_free()
func deactivate_for_pool() -> void:
	active = false; hide(); set_physics_process(false); target_ref = null; source_ref = null
