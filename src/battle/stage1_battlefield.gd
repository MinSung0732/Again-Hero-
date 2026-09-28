extends Node2D
class_name Stage1Battlefield

# Stage 1: RPG-style Demon Castle throne hall.
# Floor drawing and prop construction happen once when the battle starts.
const FLOOR_STEP := Vector2(171.0, 175.0)
const FLOOR_DRAW_SIZE := Vector2(171.0, 175.0)
const DECOR_COLLISION_LAYER := 1 << 2

const TILE_ROOT := "res://assets/art/UI/tiles"
const FLOOR_ROOT := TILE_ROOT + "/again_hero_A_48_black_grid"
const WALL_ROOT := TILE_ROOT + "/again_hero_B_walls"
const OBJECT_ROOT := TILE_ROOT + "/again_hero_C_objects"

const TEXTURE_PATHS := {
	"floor": FLOOR_ROOT + "/tile_001.png",
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
var background_decor_layer: Node2D
var collision_layer_root: Node2D
var depth_prop_roots: Array[Node2D] = []


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_process(false)
	set_physics_process(false)
	visible = false


func configure(stage_id: String, map_size: Vector2) -> void:
	stage_active = stage_id == "stage_1"
	visible = stage_active

	_ensure_layers()
	_clear_children(background_decor_layer)
	_clear_children(collision_layer_root)
	_clear_depth_props()

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
	if not is_instance_valid(background_decor_layer):
		background_decor_layer = Node2D.new()
		background_decor_layer.name = "BackgroundDecorLayer"
		background_decor_layer.z_index = 1
		add_child(background_decor_layer)

	if not is_instance_valid(collision_layer_root):
		collision_layer_root = Node2D.new()
		collision_layer_root.name = "CollisionLayer"
		add_child(collision_layer_root)


func _clear_children(parent_node: Node) -> void:
	if not is_instance_valid(parent_node):
		return
	for child in parent_node.get_children():
		child.free()


func _clear_depth_props() -> void:
	for prop_root in depth_prop_roots:
		if is_instance_valid(prop_root):
			prop_root.free()
	depth_prop_roots.clear()


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


func _draw_floor() -> void:
	var floor_texture := _texture("floor")
	if floor_texture == null:
		return

	# One seamless base tile only. Mixing different masonry patterns per cell
	# created visible square patches because their grout layouts do not match.
	var columns := ceili(battlefield_size.x / FLOOR_STEP.x) + 1
	var rows := ceili(battlefield_size.y / FLOOR_STEP.y) + 1
	for row in range(rows):
		for column in range(columns):
			draw_texture_rect(
				floor_texture,
				Rect2(
					Vector2(
						float(column) * FLOOR_STEP.x,
						float(row) * FLOOR_STEP.y
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
	var start_y := 500.0
	var end_y := battlefield_size.y - 430.0
	var y := start_y

	while y < end_y:
		var current := runner
		if y + FLOOR_STEP.y >= end_y and runner_end != null:
			current = runner_end
		draw_texture_rect(
			current,
			Rect2(
				Vector2(
					center_x - FLOOR_DRAW_SIZE.x * 0.5,
					y
				),
				FLOOR_DRAW_SIZE
			),
			false
		)
		y += FLOOR_STEP.y

	if cross != null:
		draw_texture_rect(
			cross,
			Rect2(
				Vector2(
					center_x - FLOOR_DRAW_SIZE.x * 0.5,
					center_y - FLOOR_DRAW_SIZE.y * 0.5
				),
				FLOOR_DRAW_SIZE
			),
			false
		)


func _add_background_visual(
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
	background_decor_layer.add_child(sprite)
	return sprite


func _add_depth_prop_visual(
	key: String,
	ground_position: Vector2,
	scale_factor: float = 1.0,
	flip_h: bool = false
) -> Node2D:
	var texture := _texture(key)
	var world_parent := get_parent() as Node2D
	if texture == null or not is_instance_valid(world_parent):
		return null

	# The direct child sits on the object's ground contact point. Battle's
	# native Y-sort then gives the desired top-down rule:
	# actor above this Y -> prop covers actor; actor below -> actor covers prop.
	var sort_root := Node2D.new()
	sort_root.name = "Stage1DepthProp"
	sort_root.position = ground_position
	sort_root.z_index = 0
	world_parent.add_child(sort_root)
	depth_prop_roots.append(sort_root)

	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(scale_factor, scale_factor)
	sprite.flip_h = flip_h
	sprite.position = Vector2(
		0.0,
		-float(texture.get_height()) * scale_factor * 0.5
	)
	sprite.z_index = 0
	sort_root.add_child(sprite)
	return sort_root


func _add_collision(
	ground_position: Vector2,
	size: Vector2
) -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var body := StaticBody2D.new()
	body.collision_layer = DECOR_COLLISION_LAYER
	body.collision_mask = 0
	# Only the footprint/base blocks movement. The tall upper art is intentionally
	# non-solid so actors can route behind it and be hidden by Y-sort.
	body.position = ground_position + Vector2(0.0, -size.y * 0.5)

	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)
	collision_layer_root.add_child(body)


func _add_solid_depth_prop(
	key: String,
	ground_position: Vector2,
	scale_factor: float,
	collision_size: Vector2,
	flip_h: bool = false
) -> void:
	_add_depth_prop_visual(
		key,
		ground_position,
		scale_factor,
		flip_h
	)
	_add_collision(ground_position, collision_size)


func _build_top_wall() -> void:
	var y := 105.0
	var spacing := 210.0
	var slot_count := maxi(
		1,
		ceili((battlefield_size.x - 120.0) / spacing)
	)
	var center_slot := floori(float(slot_count) * 0.5)

	for slot in range(slot_count):
		var x := 80.0 + float(slot) * spacing
		if x > battlefield_size.x - 70.0:
			break

		var wall_key := "wall_large"
		if slot == center_slot:
			wall_key = "wall_window"
		elif slot % 3 == 1:
			wall_key = "wall_banner"

		_add_background_visual(
			wall_key,
			Vector2(x, y),
			0.96,
			false,
			0
		)

	_add_background_visual(
		"wall_corner",
		Vector2(105.0, 128.0),
		0.94,
		false,
		1
	)
	_add_background_visual(
		"wall_corner",
		Vector2(battlefield_size.x - 105.0, 128.0),
		0.94,
		true,
		1
	)


func _build_castle_decor() -> void:
	_build_top_wall()

	var center_x := battlefield_size.x * 0.5

	# Background hanging decoration has no collision.
	_add_background_visual(
		"flag_a",
		Vector2(center_x - 690.0, 290.0),
		0.80,
		false,
		2
	)
	_add_background_visual(
		"flag_b",
		Vector2(center_x + 690.0, 300.0),
		0.72,
		true,
		2
	)

	# Depth props use their bottom/ground point as Y-sort origin. Collision is
	# deliberately limited to the pedestal/feet region.
	_add_solid_depth_prop(
		"throne",
		Vector2(center_x, 585.0),
		0.92,
		Vector2(300.0, 74.0)
	)
	_add_solid_depth_prop(
		"brazier",
		Vector2(center_x - 470.0, 735.0),
		0.72,
		Vector2(82.0, 58.0)
	)
	_add_solid_depth_prop(
		"brazier",
		Vector2(center_x + 470.0, 735.0),
		0.72,
		Vector2(82.0, 58.0),
		true
	)

	var side_x_left := 345.0
	var side_x_right := battlefield_size.x - 345.0
	var pillar_ys := [1030.0, 1700.0, 2370.0]
	for index in range(pillar_ys.size()):
		var ground_y := float(pillar_ys[index])
		var pillar_key := "pillar_a" if index % 2 == 0 else "pillar_b"
		_add_solid_depth_prop(
			pillar_key,
			Vector2(side_x_left, ground_y),
			0.82,
			Vector2(86.0, 72.0)
		)
		_add_solid_depth_prop(
			pillar_key,
			Vector2(side_x_right, ground_y),
			0.82,
			Vector2(86.0, 72.0),
			true
		)

	_add_solid_depth_prop(
		"altar",
		Vector2(680.0, 1390.0),
		0.62,
		Vector2(158.0, 66.0)
	)
	_add_solid_depth_prop(
		"altar",
		Vector2(battlefield_size.x - 680.0, 1390.0),
		0.62,
		Vector2(158.0, 66.0),
		true
	)

	_add_solid_depth_prop(
		"crystal",
		Vector2(560.0, 830.0),
		0.74,
		Vector2(62.0, 54.0)
	)
	_add_solid_depth_prop(
		"crystal",
		Vector2(battlefield_size.x - 560.0, 830.0),
		0.74,
		Vector2(62.0, 54.0),
		true
	)

	_add_solid_depth_prop(
		"statue",
		Vector2(610.0, battlefield_size.y - 500.0),
		0.70,
		Vector2(118.0, 74.0)
	)
	_add_solid_depth_prop(
		"statue",
		Vector2(battlefield_size.x - 610.0, battlefield_size.y - 500.0),
		0.70,
		Vector2(118.0, 74.0),
		true
	)

	# Entrance is near the lower boundary and only its threshold blocks passage.
	_add_solid_depth_prop(
		"door",
		Vector2(center_x, battlefield_size.y - 45.0),
		0.78,
		Vector2(220.0, 66.0)
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
