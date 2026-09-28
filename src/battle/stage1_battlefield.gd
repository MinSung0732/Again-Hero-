extends Node2D
class_name Stage1Battlefield

# Stage 1 only: a static RPG-style Demon Castle hall assembled from the
# uploaded floor / wall / object assets. It is built once at battle start.
const FLOOR_STEP := Vector2(170.0, 170.0)
const FLOOR_DRAW_SIZE := Vector2(172.0, 176.0)
const DECOR_COLLISION_LAYER := 3

const TILE_ROOT := "res://assets/art/UI/tiles"
const FLOOR_ROOT := TILE_ROOT + "/again_hero_A_48_black_grid"
const WALL_ROOT := TILE_ROOT + "/again_hero_B_walls"
const OBJECT_ROOT := TILE_ROOT + "/again_hero_C_objects"

const TEXTURE_PATHS := {
	"floor_a": FLOOR_ROOT + "/tile_001.png",
	"floor_b": FLOOR_ROOT + "/tile_002.png",
	"floor_c": FLOOR_ROOT + "/tile_009.png",
	"floor_d": FLOOR_ROOT + "/tile_010.png",
	"rug_runner": FLOOR_ROOT + "/tile_026.png",
	"rug_end": FLOOR_ROOT + "/tile_027.png",
	"rug_cross": FLOOR_ROOT + "/tile_042.png",
	"wall_large": WALL_ROOT + "/wall_top_001.png",
	"wall_banner": WALL_ROOT + "/wall_top_002.png",
	"wall_window": WALL_ROOT + "/wall_door_001.png",
	"wall_corner": WALL_ROOT + "/wall_corner_outer_001.png",
	"pillar_a": OBJECT_ROOT + "/pillar_001.png",
	"pillar_b": OBJECT_ROOT + "/pillar_002.png",
	"throne": OBJECT_ROOT + "/throne_001.png",
	"altar": OBJECT_ROOT + "/altar_001.png",
	"brazier": OBJECT_ROOT + "/brazier_001.png",
	"crystal": OBJECT_ROOT + "/crystal_001.png",
	"flag_a": OBJECT_ROOT + "/flag_001.png",
	"flag_b": OBJECT_ROOT + "/flag_002.png",
	"door": OBJECT_ROOT + "/door_001.png",
	"statue": OBJECT_ROOT + "/statue_001.png",
}

var battlefield_size := Vector2(3200.0, 3200.0)
var stage_active := false
var textures: Dictionary = {}
var decor_layer: Node2D
var collision_layer_root: Node2D


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_process(false)
	set_physics_process(false)
	visible = false


func configure(stage_id: String, map_size: Vector2) -> void:
	stage_active = stage_id == "stage_1"
	visible = stage_active

	_ensure_layers()
	_clear_children(decor_layer)
	_clear_children(collision_layer_root)

	if not stage_active:
		queue_redraw()
		return

	battlefield_size = Vector2(
		maxf(map_size.x, 800.0),
		maxf(map_size.y, 800.0)
	)
	_ensure_textures()
	_build_castle_decor()
	queue_redraw()


func _ensure_layers() -> void:
	if not is_instance_valid(decor_layer):
		decor_layer = Node2D.new()
		decor_layer.name = "DecorLayer"
		decor_layer.z_index = 1
		add_child(decor_layer)

	if not is_instance_valid(collision_layer_root):
		collision_layer_root = Node2D.new()
		collision_layer_root.name = "CollisionLayer"
		add_child(collision_layer_root)


func _clear_children(parent_node: Node) -> void:
	if not is_instance_valid(parent_node):
		return
	for child in parent_node.get_children():
		child.free()


func _ensure_textures() -> void:
	if not textures.is_empty():
		return
	for key in TEXTURE_PATHS.keys():
		var path := String(TEXTURE_PATHS[key])
		if not ResourceLoader.exists(path):
			push_warning("Stage 1 battlefield texture missing: %s" % path)
			continue
		var resource = load(path)
		if resource is Texture2D:
			textures[String(key)] = resource


func _texture(key: String) -> Texture2D:
	var value = textures.get(key)
	return value as Texture2D if value is Texture2D else null


func _floor_texture_for_cell(column: int, row: int) -> Texture2D:
	var hash_value := absi(
		column * 92821
		+ row * 68917
		+ column * row * 37
	)
	match hash_value % 12:
		0, 1:
			return _texture("floor_b")
		2:
			return _texture("floor_c")
		3:
			return _texture("floor_d")
		_:
			return _texture("floor_a")


func _draw_floor() -> void:
	var columns := ceili(battlefield_size.x / FLOOR_STEP.x) + 1
	var rows := ceili(battlefield_size.y / FLOOR_STEP.y) + 1
	for row in range(rows):
		for column in range(columns):
			var floor_texture := _floor_texture_for_cell(column, row)
			if floor_texture == null:
				continue
			draw_texture_rect(
				floor_texture,
				Rect2(
					Vector2(
						float(column) * FLOOR_STEP.x - 1.0,
						float(row) * FLOOR_STEP.y - 2.0
					),
					FLOOR_DRAW_SIZE
				),
				false
			)


func _draw_royal_carpet() -> void:
	var runner := _texture("rug_runner")
	var runner_end := _texture("rug_end")
	var cross := _texture("rug_cross")
	if runner == null:
		return

	var center_x := battlefield_size.x * 0.5
	var center_y := battlefield_size.y * 0.5
	var rug_rect_size := FLOOR_DRAW_SIZE

	var y := 510.0
	while y < battlefield_size.y - 360.0:
		var current := runner
		if y + FLOOR_STEP.y >= battlefield_size.y - 360.0 and runner_end != null:
			current = runner_end
		draw_texture_rect(
			current,
			Rect2(
				Vector2(
					center_x - rug_rect_size.x * 0.5,
					y
				),
				rug_rect_size
			),
			false
		)
		y += FLOOR_STEP.y

	if cross != null:
		draw_texture_rect(
			cross,
			Rect2(
				Vector2(
					center_x - rug_rect_size.x * 0.5,
					center_y - rug_rect_size.y * 0.5
				),
				rug_rect_size
			),
			false
		)


func _add_visual(
	key: String,
	world_position: Vector2,
	scale_factor: float = 1.0,
	flip_h: bool = false,
	z_offset: int = 0
) -> Sprite2D:
	var texture := _texture(key)
	if texture == null:
		return null

	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = world_position
	sprite.scale = Vector2(scale_factor, scale_factor)
	sprite.flip_h = flip_h
	sprite.z_index = z_offset
	decor_layer.add_child(sprite)
	return sprite


func _add_collision(
	world_position: Vector2,
	size: Vector2
) -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var body := StaticBody2D.new()
	body.collision_layer = DECOR_COLLISION_LAYER
	body.collision_mask = 0
	body.position = world_position

	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)
	collision_layer_root.add_child(body)


func _add_solid_decor(
	key: String,
	world_position: Vector2,
	scale_factor: float,
	collision_size: Vector2,
	collision_offset: Vector2,
	flip_h: bool = false,
	z_offset: int = 0
) -> void:
	_add_visual(
		key,
		world_position,
		scale_factor,
		flip_h,
		z_offset
	)
	_add_collision(
		world_position + collision_offset,
		collision_size
	)


func _build_top_wall() -> void:
	var y := 112.0
	var spacing := 210.0
	var slot_count := maxi(
		1,
		ceili((battlefield_size.x - 120.0) / spacing)
	)
	var center_slot := slot_count / 2

	for slot in range(slot_count):
		var x := 80.0 + float(slot) * spacing
		if x > battlefield_size.x - 70.0:
			break

		var wall_key := "wall_large"
		if slot == center_slot:
			wall_key = "wall_window"
		elif slot % 3 == 1:
			wall_key = "wall_banner"

		_add_visual(
			wall_key,
			Vector2(x, y),
			0.96,
			false,
			0
		)

	# Corners visually close the upper throne-room wall. Battlefield bounds
	# already prevent movement outside the map, so the wall art itself does
	# not add a second hidden collision strip.
	_add_visual(
		"wall_corner",
		Vector2(105.0, 132.0),
		0.94,
		false,
		1
	)
	_add_visual(
		"wall_corner",
		Vector2(battlefield_size.x - 105.0, 132.0),
		0.94,
		true,
		1
	)


func _build_castle_decor() -> void:
	_build_top_wall()

	var center_x := battlefield_size.x * 0.5

	# Royal focal point.
	_add_solid_decor(
		"throne",
		Vector2(center_x, 440.0),
		0.92,
		Vector2(300.0, 76.0),
		Vector2(0.0, 126.0),
		false,
		3
	)
	_add_solid_decor(
		"brazier",
		Vector2(center_x - 470.0, 590.0),
		0.72,
		Vector2(82.0, 66.0),
		Vector2(0.0, 104.0),
		false,
		2
	)
	_add_solid_decor(
		"brazier",
		Vector2(center_x + 470.0, 590.0),
		0.72,
		Vector2(82.0, 66.0),
		Vector2(0.0, 104.0),
		true,
		2
	)
	_add_visual(
		"flag_a",
		Vector2(center_x - 690.0, 280.0),
		0.80,
		false,
		2
	)
	_add_visual(
		"flag_b",
		Vector2(center_x + 690.0, 290.0),
		0.72,
		true,
		2
	)

	# Side architecture stays well away from the central combat lane so the
	# existing AI can kite around it without creating enclosed pockets.
	var side_x_left := 345.0
	var side_x_right := battlefield_size.x - 345.0
	var pillar_ys := [900.0, 1570.0, 2240.0]
	for index in range(pillar_ys.size()):
		var y := float(pillar_ys[index])
		var pillar_key := "pillar_a" if index % 2 == 0 else "pillar_b"
		_add_solid_decor(
			pillar_key,
			Vector2(side_x_left, y),
			0.82,
			Vector2(84.0, 72.0),
			Vector2(0.0, 108.0),
			false,
			1
		)
		_add_solid_decor(
			pillar_key,
			Vector2(side_x_right, y),
			0.82,
			Vector2(84.0, 72.0),
			Vector2(0.0, 108.0),
			true,
			1
		)

	_add_solid_decor(
		"altar",
		Vector2(670.0, 1230.0),
		0.62,
		Vector2(158.0, 68.0),
		Vector2(0.0, 94.0),
		false,
		2
	)
	_add_solid_decor(
		"altar",
		Vector2(battlefield_size.x - 670.0, 1230.0),
		0.62,
		Vector2(158.0, 68.0),
		Vector2(0.0, 94.0),
		true,
		2
	)

	_add_solid_decor(
		"crystal",
		Vector2(555.0, 650.0),
		0.74,
		Vector2(64.0, 58.0),
		Vector2(0.0, 92.0),
		false,
		2
	)
	_add_solid_decor(
		"crystal",
		Vector2(battlefield_size.x - 555.0, 650.0),
		0.74,
		Vector2(64.0, 58.0),
		Vector2(0.0, 92.0),
		true,
		2
	)

	_add_solid_decor(
		"statue",
		Vector2(610.0, battlefield_size.y - 650.0),
		0.70,
		Vector2(112.0, 76.0),
		Vector2(0.0, 104.0),
		false,
		2
	)
	_add_solid_decor(
		"statue",
		Vector2(battlefield_size.x - 610.0, battlefield_size.y - 650.0),
		0.70,
		Vector2(112.0, 76.0),
		Vector2(0.0, 104.0),
		true,
		2
	)

	# The entrance sits close to the map boundary, leaving the main field open.
	_add_solid_decor(
		"door",
		Vector2(center_x, battlefield_size.y - 150.0),
		0.78,
		Vector2(220.0, 68.0),
		Vector2(0.0, 116.0),
		false,
		2
	)


func _draw() -> void:
	if not stage_active:
		return

	draw_rect(
		Rect2(Vector2.ZERO, battlefield_size),
		Color(0.035, 0.029, 0.045),
		true
	)
	_draw_floor()
	_draw_royal_carpet()
	draw_rect(
		Rect2(Vector2.ZERO, battlefield_size),
		Color(0.24, 0.17, 0.28, 0.86),
		false,
		8.0
	)
