extends Area2D

const FRAME_DIR := "res://assets/art/heroes/stage4_gunner/frames/effect"
const FRAME_COUNT := 13
const FPS := 22.0

var direction := Vector2.RIGHT
var speed := 920.0
var max_range := 760.0
var damage := 28
var traveled := 0.0
var headshot := false
var hit_ids: Dictionary = {}

@onready var visual: AnimatedSprite2D = $Visual

func _ready() -> void:
	add_to_group("hero_projectiles")
	body_entered.connect(_on_body_entered)
	_apply_visual()

func setup(new_direction: Vector2, new_damage: int, new_speed: float, new_range: float, is_headshot: bool = false) -> void:
	direction = new_direction.normalized()
	damage = maxi(new_damage, 1)
	speed = maxf(new_speed, 1.0)
	max_range = maxf(new_range, 1.0)
	headshot = is_headshot
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	var step := direction * speed * delta
	global_position += step
	traveled += step.length()
	if traveled >= max_range:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body == null or body.is_queued_for_deletion():
		return
	if not body.is_in_group("monsters") or not body.has_method("take_damage"):
		return
	var id := body.get_instance_id()
	if hit_ids.has(id):
		return
	hit_ids[id] = true
	if headshot and body.has_method("take_damage_colored"):
		body.call("take_damage_colored", damage, Color(1.0, 0.18, 0.12, 1.0))
	else:
		body.call("take_damage", damage)

func _apply_visual() -> void:
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")
	frames.add_animation(&"fly")
	frames.set_animation_loop(&"fly", true)
	frames.set_animation_speed(&"fly", FPS)
	for i in range(1, FRAME_COUNT + 1):
		var path := "%s/effect_projectile_%02d.png" % [FRAME_DIR, i]
		if not ResourceLoader.exists(path):
			continue
		var tex = load(path)
		if tex is Texture2D:
			frames.add_frame(&"fly", tex)
	if frames.get_frame_count(&"fly") > 0:
		visual.sprite_frames = frames
		visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		visual.visible = true
		visual.play(&"fly")
	else:
		visual.visible = false
		queue_redraw()

func _draw() -> void:
	if not visual.visible:
		draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.82, 0.22))
