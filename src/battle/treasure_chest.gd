extends StaticBody2D

signal destroyed(drop_position: Vector2)

@export var max_hp: int = 60
var current_hp: int = 60
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
		hit_flash_timer = maxf(hit_flash_timer - delta, 0.0)
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
