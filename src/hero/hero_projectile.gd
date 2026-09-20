extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 680.0
var max_range: float = 420.0
var damage: int = 34
var traveled_distance: float = 0.0

func _ready() -> void:
	add_to_group("hero_projectiles")
	body_entered.connect(_on_body_entered)
	queue_redraw()

func setup(new_direction: Vector2, new_damage: int, new_speed: float, new_max_range: float) -> void:
	direction = new_direction.normalized()
	damage = new_damage
	speed = new_speed
	max_range = new_max_range

func _physics_process(delta: float) -> void:
	var step := direction * speed * delta
	global_position += step
	traveled_distance += step.length()

	if traveled_distance >= max_range:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body == null or body.is_queued_for_deletion():
		return

	if body.is_in_group("monsters") and body.has_method("take_damage"):
		body.call("take_damage", damage)
		queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 9.0, Color(0.95, 0.86, 0.32))
	draw_circle(Vector2.ZERO, 4.0, Color(1.0, 1.0, 0.82))
