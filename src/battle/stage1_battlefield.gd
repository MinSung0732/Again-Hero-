extends Node2D
class_name Stage1Battlefield

# Stage 1~10: the same Demon Castle throne hall deteriorates as intruders advance.
# All floor drawing and prop construction happen only when a battle is configured.
const FLOOR_STEP := Vector2(171.0, 175.0)
const FLOOR_DRAW_SIZE := Vector2(171.0, 175.0)
const DECOR_COLLISION_LAYER := 1 << 2
# Layer 4 is reserved for hard castle boundaries that phase/ghost movement
# must never ignore. Decorative props remain on layer 3.
const BOUNDARY_COLLISION_LAYER := 1 << 3
const CARPET_STEP_Y := 154.0
const PERIMETER_WALL_SCALE := 0.96
const PERIMETER_WALL_OVERLAP := 44.0
const PERIMETER_OUTSET := 58.0
const TOP_WALL_Y := 62.0
const TOP_WALL_COLLISION_BOTTOM := 190.0
const TOP_WALL_COLLISION_HEIGHT := 190.0

const THRONE_GROUND_Y := 560.0
const THRONE_BRAZIER_OFFSET_X := 470.0
const SIDE_PILLAR_X := 390.0
const SIDE_PILLAR_START_Y := 940.0
const SIDE_PILLAR_STEP_Y := 520.0
const SIDE_PILLAR_COUNT := 4
const INNER_PROP_X := 680.0
const INNER_PROP_START_Y := 1200.0
const INNER_PROP_STEP_Y := 520.0
const CASTLE_STAGE_MIN := 1
const CASTLE_STAGE_MAX := 10

const TILE_ROOT := "res://assets/art/UI/tiles"
const FLOOR_ROOT := TILE_ROOT + "/again_hero_A_48_black_grid"
const WALL_ROOT := TILE_ROOT + "/again_hero_B_walls"
const OBJECT_ROOT := TILE_ROOT + "/again_hero_C_objects"

const TEXTURE_PATHS := {
	"floor": FLOOR_ROOT + "/tile_001.png",
	"floor_damage_1": FLOOR_ROOT + "/tile_014.png",
	"floor_damage_2": FLOOR_ROOT + "/tile_015.png",
	"floor_damage_3": FLOOR_ROOT + "/tile_016.png",
	"floor_damage_4": FLOOR_ROOT + "/tile_017.png",
	"floor_damage_5": FLOOR_ROOT + "/tile_047.png",
	"rug_long": FLOOR_ROOT + "/tile_022.png",
	"rug_torn_1": FLOOR_ROOT + "/tile_043.png",
	"rug_torn_2": FLOOR_ROOT + "/tile_044.png",
	"rug_torn_3": FLOOR_ROOT + "/tile_045.png",
	"rug_torn_4": FLOOR_ROOT + "/tile_046.png",
	"wall_large": WALL_ROOT + "/wall_top_001.png",
	"wall_broken_1": WALL_ROOT + "/wall_broken_001.png",
	"wall_broken_2": WALL_ROOT + "/wall_broken_002.png",
	"wall_broken_3": WALL_ROOT + "/wall_broken_003.png",
	"wall_broken_4": WALL_ROOT + "/wall_broken_004.png",
	"wall_broken_5": WALL_ROOT + "/wall_broken_005.png",
	"wall_broken_6": WALL_ROOT + "/wall_broken_006.png",
	"wall_broken_7": WALL_ROOT + "/wall_broken_007.png",
	"wall_broken_8": WALL_ROOT + "/wall_broken_008.png",
	"wall_arch": WALL_ROOT + "/wall_arch_001.png",
	"wall_arch_broken": WALL_ROOT + "/wall_arch_broken_001.png",
	"wall_banner": WALL_ROOT + "/wall_top_002.png",
	"wall_window": WALL_ROOT + "/wall_door_001.png",
	"wall_corner": WALL_ROOT + "/wall_corner_outer_001.png",
	"pillar_a": OBJECT_ROOT + "/pillar_001.png",
	"pillar_b": OBJECT_ROOT + "/pillar_002.png",
	"pillar_broken": OBJECT_ROOT + "/pillar_003.png",
	"debris_a": OBJECT_ROOT + "/debris_001.png",
	"debris_b": OBJECT_ROOT + "/debris_002.png",
	"debris_c": OBJECT_ROOT + "/debris_003.png",
	"ruins": OBJECT_ROOT + "/ruins_001.png",
	"throne": OBJECT_ROOT + "/throne_001.png",
	"altar": OBJECT_ROOT + "/altar_001.png",
	"brazier": OBJECT_ROOT + "/brazier_001.png",
	"crystal": OBJECT_ROOT + "/crystal_001.png",
	"flag_a": OBJECT_ROOT + "/flag_001.png",
	"flag_b": OBJECT_ROOT + "/flag_002.png",
	"statue": OBJECT_ROOT + "/statue_001.png",
}

var battlefield_size := Vector2(3200.0, 3200.0)
var stage_active := false
var current_stage_number := 1
var textures: Dictionary = {}
var background_decor_layer: Node2D
var collision_layer_root: Node2D
var depth_prop_roots: Array[Node2D] = []


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_process(false)
	set_physics_process(false)
	visible = false


func _stage_number_from_id(stage_id: String) -> int:
	if not stage_id.begins_with("stage_"):
		return 0
	return stage_id.trim_prefix("stage_").to_int()


func _destruction_level() -> int:
	return clampi(current_stage_number - CASTLE_STAGE_MIN, 0, 9)


func _stable_roll(a: int, b: int, salt: int = 0) -> int:
	# Stage-independent coordinates mean damage accumulates in the same places
	# instead of reshuffling every run/stage.
	return posmod(a * 37 + b * 61 + a * b * 13 + salt * 17, 100)


func configure(stage_id: String, map_size: Vector2) -> void:
	current_stage_number = _stage_number_from_id(stage_id)
	stage_active = (
		current_stage_number >= CASTLE_STAGE_MIN
		and current_stage_number <= CASTLE_STAGE_MAX
	)
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
			push_warning("Castle battlefield texture missing: %s" % path)
			continue
		var resource = load(path)
		if resource is Texture2D:
			textures[String(key)] = resource


func _texture(key: String) -> Texture2D:
	var value = textures.get(key)
	return value as Texture2D if value is Texture2D else null


func _floor_texture_for_cell(column: int, row: int) -> Texture2D:
	var base_floor := _texture("floor")
	var destruction := _destruction_level()
	if destruction <= 0:
		return base_floor

	# 3% more damaged cells per destruction step. Because the roll is stage
	# independent, damage accumulates at existing coordinates as stages rise.
	var damage_threshold := mini(27, destruction * 3)
	if _stable_roll(column, row, 3) >= damage_threshold:
		return base_floor

	var max_variant := 1 + mini(4, floori(float(destruction) / 2.0))
	var variant := 1 + posmod(_stable_roll(column, row, 11), max_variant)
	var damaged := _texture("floor_damage_%d" % variant)
	return damaged if damaged != null else base_floor


func _draw_floor() -> void:
	var floor_texture := _texture("floor")
	if floor_texture == null:
		return

	var columns := ceili(battlefield_size.x / FLOOR_STEP.x)
	var rows := ceili(battlefield_size.y / FLOOR_STEP.y)
	for row in range(rows):
		for column in range(columns):
			var cell_texture := _floor_texture_for_cell(column, row)
			if cell_texture == null:
				cell_texture = floor_texture
			draw_texture_rect(
				cell_texture,
				Rect2(
					Vector2(
						float(column) * FLOOR_STEP.x,
						float(row) * FLOOR_STEP.y
					),
					FLOOR_DRAW_SIZE
				),
				false,
				Color(0.65, 0.59, 0.77, 1.0)
			)


func _carpet_texture_for_segment(segment_index: int) -> Texture2D:
	var runner := _texture("rug_long")
	var destruction := _destruction_level()
	if destruction < 3:
		return runner

	# Carpet tears start at Stage 4 and accumulate at stable segment positions.
	var damage_threshold := mini(49, (destruction - 2) * 7)
	if _stable_roll(segment_index, 0, 29) >= damage_threshold:
		return runner

	var max_variant := 2 if destruction < 6 else 4
	var variant := 1 + posmod(_stable_roll(segment_index, 0, 41), max_variant)
	var torn := _texture("rug_torn_%d" % variant)
	return torn if torn != null else runner


func _draw_royal_carpet() -> void:
	var runner := _texture("rug_long")
	if runner == null:
		return

	var center_x := battlefield_size.x * 0.5
	var start_y := 470.0
	var end_y := battlefield_size.y + CARPET_STEP_Y
	var y := start_y
	var segment_index := 0

	while y < end_y:
		var segment_texture := _carpet_texture_for_segment(segment_index)
		if segment_texture == null:
			segment_texture = runner
		draw_texture_rect(
			segment_texture,
			Rect2(
				Vector2(
					center_x - FLOOR_DRAW_SIZE.x * 0.5,
					y
				),
				FLOOR_DRAW_SIZE
			),
			false
		)
		y += CARPET_STEP_Y
		segment_index += 1


func _add_background_visual(
	key: String,
	world_position: Vector2,
	scale_factor: float = 1.0,
	flip_h: bool = false,
	z_offset: int = 0,
	rotation_radians: float = 0.0
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
	sprite.rotation = rotation_radians
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
	sort_root.name = "CastleDepthProp"
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
	size: Vector2,
	collision_layer_value: int = DECOR_COLLISION_LAYER
) -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var body := StaticBody2D.new()
	body.collision_layer = collision_layer_value
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


func _add_mirrored_solid_prop(
	key: String,
	left_x: float,
	ground_y: float,
	scale_factor: float,
	collision_size: Vector2
) -> void:
	_add_solid_depth_prop(
		key,
		Vector2(left_x, ground_y),
		scale_factor,
		collision_size
	)
	_add_solid_depth_prop(
		key,
		Vector2(battlefield_size.x - left_x, ground_y),
		scale_factor,
		collision_size,
		true
	)


func _add_mirrored_depth_prop(
	key: String,
	left_x: float,
	ground_y: float,
	scale_factor: float
) -> void:
	_add_depth_prop_visual(
		key,
		Vector2(left_x, ground_y),
		scale_factor
	)
	_add_depth_prop_visual(
		key,
		Vector2(battlefield_size.x - left_x, ground_y),
		scale_factor,
		true
	)


func _wall_key_for_slot(slot_index: int, salt: int) -> String:
	var destruction := _destruction_level()
	if destruction <= 0:
		return "wall_large"

	var break_threshold := mini(72, destruction * 8)
	if _stable_roll(slot_index, salt, 53) >= break_threshold:
		return "wall_large"

	var mild_variant := 1 + posmod(_stable_roll(slot_index, salt, 59), 4)
	if destruction < 5:
		return "wall_broken_%d" % mild_variant

	var severe_threshold := mini(70, (destruction - 4) * 14)
	if _stable_roll(slot_index, salt, 67) < severe_threshold:
		var severe_variant := 5 + posmod(_stable_roll(slot_index, salt, 71), 4)
		return "wall_broken_%d" % severe_variant
	return "wall_broken_%d" % mild_variant


func _build_top_wall() -> void:
	var wall_texture := _texture("wall_large")
	if wall_texture == null:
		return

	var panel_width := float(wall_texture.get_width()) * PERIMETER_WALL_SCALE
	var repeat_step := maxf(
		120.0,
		panel_width - PERIMETER_WALL_OVERLAP
	)
	var x := panel_width * 0.5 - PERIMETER_WALL_OVERLAP * 0.5
	var slot_index := 0

	# The upper wall remains inside the arena for the interior-castle read.
	# Its full visual band is solid (0..190 px), so actors cannot occupy the
	# narrow strip behind the wall and get trapped there.
	while x < battlefield_size.x + panel_width * 0.5:
		_add_background_visual(
			_wall_key_for_slot(slot_index, 1),
			Vector2(x, TOP_WALL_Y),
			PERIMETER_WALL_SCALE
		)
		x += repeat_step
		slot_index += 1

	_add_collision(
		Vector2(
			battlefield_size.x * 0.5,
			TOP_WALL_COLLISION_BOTTOM
		),
		Vector2(
			battlefield_size.x,
			TOP_WALL_COLLISION_HEIGHT
		),
		BOUNDARY_COLLISION_LAYER
	)


func _build_side_walls() -> void:
	var wall_texture := _texture("wall_large")
	if wall_texture == null:
		return

	var panel_length := float(wall_texture.get_width()) * PERIMETER_WALL_SCALE
	var repeat_step := maxf(
		120.0,
		panel_length - PERIMETER_WALL_OVERLAP
	)
	var y := panel_length * 0.5 - PERIMETER_WALL_OVERLAP * 0.5
	var slot_index := 0

	while y < battlefield_size.y + panel_length * 0.5:
		var wall_key := _wall_key_for_slot(slot_index, 2)
		_add_background_visual(
			wall_key,
			Vector2(-PERIMETER_OUTSET, y),
			PERIMETER_WALL_SCALE,
			false,
			0,
			-PI * 0.5
		)
		_add_background_visual(
			wall_key,
			Vector2(battlefield_size.x + PERIMETER_OUTSET, y),
			PERIMETER_WALL_SCALE,
			true,
			0,
			PI * 0.5
		)
		y += repeat_step
		slot_index += 1


func _build_bottom_wall() -> void:
	var wall_texture := _texture("wall_large")
	var arch_texture := _texture("wall_arch")
	if wall_texture == null:
		return

	var center_x := battlefield_size.x * 0.5
	var panel_width := float(wall_texture.get_width()) * PERIMETER_WALL_SCALE
	var repeat_step := maxf(
		120.0,
		panel_width - PERIMETER_WALL_OVERLAP
	)
	var doorway_half_width := 145.0
	if arch_texture != null:
		doorway_half_width = (
			float(arch_texture.get_width()) * PERIMETER_WALL_SCALE * 0.5
			+ 12.0
		)

	var x := panel_width * 0.5 - PERIMETER_WALL_OVERLAP * 0.5
	var wall_y := battlefield_size.y + PERIMETER_OUTSET
	var slot_index := 0

	while x < battlefield_size.x + panel_width * 0.5:
		if absf(x - center_x) > doorway_half_width:
			_add_background_visual(
				_wall_key_for_slot(slot_index, 3),
				Vector2(x, wall_y),
				PERIMETER_WALL_SCALE,
				false,
				0,
				PI
			)
		x += repeat_step
		slot_index += 1

	var arch_key := "wall_arch"
	if _destruction_level() >= 5:
		arch_texture = _texture("wall_arch_broken")
		arch_key = "wall_arch_broken"

	if arch_texture != null:
		# Most of the doorway remains outside the arena; only the upper arch
		# intrudes into view, so it reads as part of the boundary instead of
		# stealing combat space.
		_add_background_visual(
			arch_key,
			Vector2(center_x, battlefield_size.y + 72.0),
			PERIMETER_WALL_SCALE,
			false,
			1
		)


func _build_destruction_debris() -> void:
	var destruction := _destruction_level()
	if destruction >= 1:
		_add_mirrored_depth_prop("debris_c", 520.0, 1020.0, 0.52)
	if destruction >= 3:
		_add_mirrored_depth_prop("debris_a", 470.0, 1560.0, 0.50)
	if destruction >= 5:
		_add_mirrored_depth_prop("debris_b", 500.0, 2120.0, 0.48)
	if destruction >= 7:
		_add_mirrored_depth_prop("debris_c", 360.0, 2720.0, 0.58)
	if destruction >= 8:
		_add_mirrored_depth_prop("ruins", 260.0, 1880.0, 0.48)
	if destruction >= 9:
		_add_mirrored_depth_prop("ruins", 300.0, 2860.0, 0.54)


func _build_castle_decor() -> void:
	_build_top_wall()
	_build_side_walls()
	_build_bottom_wall()

	var center_x := battlefield_size.x * 0.5
	var destruction := _destruction_level()

	# Hanging ornaments disappear in pairs as the wall structure gives way.
	if destruction < 4:
		_add_background_visual(
			"crystal",
			Vector2(center_x - 1080.0, 92.0),
			0.62,
			false,
			2
		)
		_add_background_visual(
			"crystal",
			Vector2(center_x + 1080.0, 92.0),
			0.62,
			true,
			2
		)
	if destruction < 6:
		_add_background_visual(
			"flag_a",
			Vector2(center_x - 720.0, 108.0),
			0.66,
			false,
			2
		)
		_add_background_visual(
			"flag_a",
			Vector2(center_x + 720.0, 108.0),
			0.66,
			true,
			2
		)
	if destruction < 8:
		_add_background_visual(
			"flag_b",
			Vector2(center_x - 360.0, 114.0),
			0.58,
			false,
			2
		)
		_add_background_visual(
			"flag_b",
			Vector2(center_x + 360.0, 114.0),
			0.58,
			true,
			2
		)

	# Throne remains the visual anchor even in the ruined late stages.
	_add_solid_depth_prop(
		"throne",
		Vector2(center_x, THRONE_GROUND_Y),
		0.92,
		Vector2(300.0, 74.0)
	)
	_add_solid_depth_prop(
		"brazier",
		Vector2(center_x - THRONE_BRAZIER_OFFSET_X, THRONE_GROUND_Y + 150.0),
		0.72,
		Vector2(82.0, 58.0)
	)
	_add_solid_depth_prop(
		"brazier",
		Vector2(center_x + THRONE_BRAZIER_OFFSET_X, THRONE_GROUND_Y + 150.0),
		0.72,
		Vector2(82.0, 58.0),
		true
	)

	# One mirrored pillar pair breaks at Stages 3, 5, 7, and 9. Collision
	# footprints stay identical, so destruction remains visual rather than a
	# hidden gameplay geometry change.
	for index in range(SIDE_PILLAR_COUNT):
		var ground_y := SIDE_PILLAR_START_Y + float(index) * SIDE_PILLAR_STEP_Y
		var pillar_key := "pillar_a" if index % 2 == 0 else "pillar_b"
		var break_stage := 3 + index * 2
		if current_stage_number >= break_stage:
			pillar_key = "pillar_broken"
		_add_mirrored_solid_prop(
			pillar_key,
			SIDE_PILLAR_X,
			ground_y,
			0.82,
			Vector2(86.0, 72.0)
		)

	_add_mirrored_solid_prop(
		"altar",
		INNER_PROP_X,
		INNER_PROP_START_Y,
		0.62,
		Vector2(158.0, 66.0)
	)
	_add_mirrored_solid_prop(
		"brazier",
		INNER_PROP_X,
		INNER_PROP_START_Y + INNER_PROP_STEP_Y,
		0.62,
		Vector2(70.0, 50.0)
	)
	_add_mirrored_solid_prop(
		"brazier",
		INNER_PROP_X,
		INNER_PROP_START_Y + INNER_PROP_STEP_Y * 2.0,
		0.62,
		Vector2(70.0, 50.0)
	)
	_add_mirrored_solid_prop(
		"statue",
		INNER_PROP_X,
		INNER_PROP_START_Y + INNER_PROP_STEP_Y * 3.0,
		0.70,
		Vector2(118.0, 74.0)
	)

	_build_destruction_debris()


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
	# Faint inlaid seal remains in world space under every actor/projectile.
	var seal_center := battlefield_size * 0.5
	var seal_color := Color(0.53, 0.39, 0.69, 0.17)
	draw_arc(seal_center, 280.0, 0.0, TAU, 64, seal_color, 4.0)
	draw_arc(seal_center, 252.0, 0.0, TAU, 64, seal_color, 2.0)
	for index in range(8):
		var direction := Vector2.from_angle(index * TAU / 8.0)
		draw_line(seal_center + direction * 220.0, seal_center + direction * 310.0, seal_color, 3.0)
		draw_line(seal_center + direction * 190.0, seal_center + direction.rotated(TAU * 3.0 / 8.0) * 190.0, seal_color, 2.0)
	draw_rect(
		Rect2(Vector2.ZERO, battlefield_size),
		Color(0.24, 0.17, 0.28, 0.86),
		false,
		8.0
	)
