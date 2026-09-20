extends Node2D

signal stats_changed(hero_hp: int, hero_max_hp: int, monsters_left: int)
signal battle_finished(message: String, player_won: bool)

const HERO_SCENE := preload("res://src/hero/Hero.tscn")
const SLIME_SCENE := preload("res://src/monsters/Slime.tscn")

const FIELD_SIZE := Vector2(1080, 1380)
const FIELD_CENTER := Vector2(540, 690)

var hero: Node2D
var monsters_alive: int = 0
var battle_over: bool = false

func _ready() -> void:
	queue_redraw()
	_start_battle()

func _start_battle() -> void:
	battle_over = false

	hero = HERO_SCENE.instantiate() as Node2D
	add_child(hero)
	hero.position = FIELD_CENTER
	hero.connect("health_changed", Callable(self, "_on_hero_health_changed"))
	hero.connect("died", Callable(self, "_on_hero_died"))

	var spawn_positions: Array[Vector2] = [
		Vector2(150, 170),
		Vector2(930, 170),
		Vector2(150, 1180),
		Vector2(930, 1180),
		Vector2(540, 100),
		Vector2(540, 1280),
	]

	for spawn_position in spawn_positions:
		_spawn_slime(spawn_position)

	_emit_stats()

func _spawn_slime(spawn_position: Vector2) -> void:
	var slime := SLIME_SCENE.instantiate() as Node2D
	add_child(slime)
	slime.position = spawn_position
	slime.connect("died", Callable(self, "_on_slime_died").bind(slime))
	monsters_alive += 1

func _on_hero_health_changed(current_hp: int, max_hp_value: int) -> void:
	stats_changed.emit(current_hp, max_hp_value, monsters_alive)

func _on_slime_died(_slime: Node) -> void:
	if battle_over:
		return

	monsters_alive = maxi(monsters_alive - 1, 0)
	_emit_stats()

	if monsters_alive <= 0:
		_finish_battle("슬라임 전멸!\n이번 실험은 실패했습니다.", false)

func _on_hero_died() -> void:
	if battle_over:
		return

	_emit_stats(0)
	_finish_battle("용사 처치!\n마왕의 첫 승리입니다.", true)

func _finish_battle(message: String, player_won: bool) -> void:
	battle_over = true

	if is_instance_valid(hero):
		hero.set_physics_process(false)

	for node in get_tree().get_nodes_in_group("monsters"):
		if is_instance_valid(node):
			node.set_physics_process(false)

	battle_finished.emit(message, player_won)

func _emit_stats(hero_hp_override: int = -1) -> void:
	var hp := 0
	var max_hp_value := 0

	if is_instance_valid(hero):
		hp = int(hero.get("current_hp"))
		max_hp_value = int(hero.get("max_hp"))

	if hero_hp_override >= 0:
		hp = hero_hp_override

	stats_changed.emit(hp, max_hp_value, monsters_alive)

func get_snapshot() -> Dictionary:
	var hp := 0
	var max_hp_value := 0

	if is_instance_valid(hero):
		hp = int(hero.get("current_hp"))
		max_hp_value = int(hero.get("max_hp"))

	return {
		"hero_hp": hp,
		"hero_max_hp": max_hp_value,
		"monsters_left": monsters_alive,
		"battle_over": battle_over,
	}

func _draw() -> void:
	var field_rect := Rect2(Vector2(24, 12), FIELD_SIZE - Vector2(48, 24))
	draw_rect(field_rect, Color(0.075, 0.085, 0.105), true)
	draw_rect(field_rect, Color(0.28, 0.32, 0.4), false, 4.0)

	draw_circle(FIELD_CENTER, 92.0, Color(0.1, 0.12, 0.15), false, 3.0)
	draw_line(FIELD_CENTER + Vector2(0, -110), FIELD_CENTER + Vector2(0, 110), Color(0.15, 0.18, 0.22), 2.0)
	draw_line(FIELD_CENTER + Vector2(-110, 0), FIELD_CENTER + Vector2(110, 0), Color(0.15, 0.18, 0.22), 2.0)
