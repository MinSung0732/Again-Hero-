extends StaticBody2D

signal destroyed(drop_position: Vector2)

@export var max_hp: int = 100
var current_hp: int = 100
var hit_flash_timer := 0.0
var destroyed_flag := false

func _ready() -> void:
	add_to_group("treasure_chests")
	current_hp = maxi(max_hp, 1)
	queue_redraw()

func take_damage(amount: int) -> bool:
	if destroyed_flag or amount <= 0:
		return false
	current_hp = maxi(current_hp - amount, 0)
	hit_flash_timer = 0.12
	queue_redraw()
	if current_hp <= 0:
		destroyed_flag = true
		destroyed.emit(global_position)
		queue_free()
	return true

func _process(delta: float) -> void:
	if hit_flash_timer > 0.0:
		var previous_hit_flash := hit_flash_timer
		hit_flash_timer = maxf(hit_flash_timer - delta, 0.0)
		if previous_hit_flash > 0.0 and hit_flash_timer <= 0.0:
			queue_redraw()

func _draw() -> void:
	var wood := Color(0.58, 0.34, 0.16)
	if hit_flash_timer > 0.0:
		wood = Color(1.0, 0.92, 0.62)
	draw_rect(Rect2(-28, -22, 56, 44), Color(0.18, 0.12, 0.08), true)
	draw_rect(Rect2(-25, -19, 50, 38), wood, true)
	draw_rect(Rect2(-25, -3, 50, 7), Color(0.82, 0.66, 0.24), true)
	draw_rect(Rect2(-5, -8, 10, 16), Color(0.95, 0.82, 0.32), true)
	draw_line(Vector2(-25, -19), Vector2(25, 19), Color(0.30, 0.18, 0.10), 3.0)
	draw_line(Vector2(25, -19), Vector2(-25, 19), Color(0.30, 0.18, 0.10), 3.0)

	var hp_ratio := clampf(float(current_hp) / float(maxi(max_hp, 1)), 0.0, 1.0)
	draw_rect(Rect2(-28, -32, 56, 5), Color(0.10, 0.08, 0.06, 0.90), true)
	draw_rect(Rect2(-27, -31, 54.0 * hp_ratio, 3), Color(0.94, 0.70, 0.20), true)
