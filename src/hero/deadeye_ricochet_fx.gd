extends Node2D

const POOL_KEY := "deadeye_ricochet_fx"

var direction: Vector2 = Vector2.RIGHT
var elapsed := 0.0
var lifetime := 0.12
var trail_length := 74.0

func setup(new_direction: Vector2) -> void:
	elapsed = 0.0
	visible = true
	set_process(true)
	direction = new_direction.normalized()
	if direction.length_squared() <= 0.0:
		direction = Vector2.RIGHT
	rotation = direction.angle()
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= lifetime:
		_finish()
		return
	queue_redraw()

func _finish() -> void:
	var parent := get_parent()
	if is_instance_valid(parent) and parent.has_method("recycle_transient_fx"):
		parent.call("recycle_transient_fx", self, POOL_KEY)
	else:
		queue_free()


func deactivate_for_pool() -> void:
	elapsed = 0.0
	set_process(false)
	visible = false


func _draw() -> void:
	var progress := clampf(elapsed / maxf(lifetime, 0.001), 0.0, 1.0)
	var alpha := 1.0 - progress
	var spark_scale := 1.0 + progress * 0.35

	# 짧은 청백색 잔광 트레일.
	draw_line(
		Vector2.ZERO,
		Vector2(trail_length * (1.0 - progress * 0.25), 0.0),
		Color(0.72, 0.94, 1.0, alpha * 0.78),
		3.0
	)
	draw_line(
		Vector2.ZERO,
		Vector2(trail_length * 0.62, 0.0),
		Color(1.0, 0.86, 0.30, alpha),
		1.5
	)

	# 도탄 지점의 노란/청백색 스파크.
	draw_circle(Vector2.ZERO, 7.0 * spark_scale, Color(1.0, 0.88, 0.30, alpha * 0.80))
	draw_circle(Vector2.ZERO, 3.2 * spark_scale, Color(0.90, 0.98, 1.0, alpha))
	for angle in [0.55, -0.55, 1.15, -1.15]:
		var spark_dir := Vector2.from_angle(angle)
		draw_line(
			spark_dir * 4.0,
			spark_dir * (18.0 + 8.0 * progress),
			Color(0.82, 0.95, 1.0, alpha * 0.90),
			2.0
		)
