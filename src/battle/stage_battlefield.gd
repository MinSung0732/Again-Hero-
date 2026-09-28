extends Node2D
class_name StageBattlefield

# Static, visual-only battlefield assembler.
# It is built once when a stage starts; nothing here runs every frame.
const FLOOR_STEP_X := 256.0
const FLOOR_STEP_Y := 206.0

const FLOOR_PLAIN := preload("res://assets/art/UI/tiles/stage1_tile_parts/tile_01_floor_plain.png")
const FLOOR_EMBLEM := preload("res://assets/art/UI/tiles/stage1_tile_parts/tile_02_floor_emblem.png")
const FLOOR_RUG_SQUARE := preload("res://assets/art/UI/tiles/stage1_tile_parts/tile_03_floor_rug_square.png")
const FLOOR_RUG_RUNNER := preload("res://assets/art/UI/tiles/stage1_tile_parts/tile_04_floor_rug_runner.png")
const WALL_BANNER := preload("res://assets/art/UI/tiles/stage1_tile_parts/tile_07_wall_banner.png")
const WALL_WINDOW := preload("res://assets/art/UI/tiles/stage1_tile_parts/tile_08_wall_window.png")
const WALL_CORNER_IN := preload("res://assets/art/UI/tiles/stage1_tile_parts/tile_09_wall_corner_in.png")
const WALL_CORNER_OUT := preload("res://assets/art/UI/tiles/stage1_tile_parts/tile_10_wall_corner_out.png")
const WALL_SIGIL := preload("res://assets/art/UI/tiles/stage1_tile_parts/tile_11_wall_sigil.png")
const WALL_LARGE_BANNER := preload("res://assets/art/UI/tiles/stage1_tile_parts/tile_12_wall_large_banner.png")
const PILLAR_PLAIN := preload("res://assets/art/UI/tiles/stage1_tile_parts/tile_13_pillar_plain.png")
const PILLAR_ORNATE := preload("res://assets/art/UI/tiles/stage1_tile_parts/tile_14_pillar_ornate.png")
const STAIRS_LEFT := preload("res://assets/art/UI/tiles/stage1_tile_parts/tile_15_stairs_left.png")
const STAIRS_RIGHT := preload("res://assets/art/UI/tiles/stage1_tile_parts/tile_16_stairs_right.png")
const DOOR_CLOSED := preload("res://assets/art/UI/tiles/stage1_tile_parts/tile_17_door_closed.png")
const DOOR_OPEN := preload("res://assets/art/UI/tiles/stage1_tile_parts/tile_18_door_open.png")
const THRONE := preload("res://assets/art/UI/tiles/stage1_tile_parts/tile_19_throne.png")
const BRAZIER := preload("res://assets/art/UI/tiles/stage1_tile_parts/tile_20_brazier.png")
const CRYSTAL_SCONCE := preload("res://assets/art/UI/tiles/stage1_tile_parts/tile_21_crystal_sconce.png")
const ALTAR := preload("res://assets/art/UI/tiles/stage1_tile_parts/tile_22_altar.png")

# Damaged/collapsed variants from the second uploaded tile set.
const DAMAGED_FLOORS := [
	preload("res://assets/art/UI/tiles/stage_tiles_frames/tile_00111.png"),
	preload("res://assets/art/UI/tiles/stage_tiles_frames/tile_001.png"),
	preload("res://assets/art/UI/tiles/stage_tiles_frames/tile_002.png"),
	preload("res://assets/art/UI/tiles/stage_tiles_frames/tile_002123.png"),
	preload("res://assets/art/UI/tiles/stage_tiles_frames/tile_003.png"),
	preload("res://assets/art/UI/tiles/stage_tiles_frames/tile_003333.png"),
	preload("res://assets/art/UI/tiles/stage_tiles_frames/tile_004.png"),
	preload("res://assets/art/UI/tiles/stage_tiles_frames/tile_0044.png"),
]
const DAMAGED_WALLS := [
	preload("res://assets/art/UI/tiles/stage_tiles_frames/tile_006.png"),
	preload("res://assets/art/UI/tiles/stage_tiles_frames/tile_007.png"),
	preload("res://assets/art/UI/tiles/stage_tiles_frames/tile_008.png"),
	preload("res://assets/art/UI/tiles/stage_tiles_frames/tile_010.png"),
	preload("res://assets/art/UI/tiles/stage_tiles_frames/tile_011.png"),
]
const DAMAGED_PILLARS := [
	preload("res://assets/art/UI/tiles/stage_tiles_frames/tile_009.png"),
	preload("res://assets/art/UI/tiles/stage_tiles_frames/tile_012.png"),
	preload("res://assets/art/UI/tiles/stage_tiles_frames/tile_013.png"),
	preload("res://assets/art/UI/tiles/stage_tiles_frames/tile_0162.png"),
]
const DAMAGED_ARCHES := [
	preload("res://assets/art/UI/tiles/stage_tiles_frames/tile_014.png"),
	preload("res://assets/art/UI/tiles/stage_tiles_frames/tile_0172.png"),
	preload("res://assets/art/UI/tiles/stage_tiles_frames/tile_0192.png"),
]
const DAMAGED_THRONE := preload("res://assets/art/UI/tiles/stage_tiles_frames/tile_0212.png")

var map_size := Vector2(3200.0, 3200.0)
var stage_number := 1
var ruin_ratio := 0.0
var floor_layer: Node2D
var decor_layer: Node2D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED


func configure(stage_data: Dictionary, battlefield_size: Vector2) -> void:
	map_size = Vector2(
		maxf(battlefield_size.x, 512.0),
		maxf(battlefield_size.y, 512.0)
	)
	stage_number = clampi(int(stage_data.get("number", 1)), 1, 10)
	# Stage 1 is intact. Stage 10 is the near-collapse target. The current
	# catalog ends at Stage 9, but this keeps Stage 10 visuals ready when its
	# gameplay profile is added.
	ruin_ratio = clampf(float(stage_number - 1) / 9.0, 0.0, 1.0)

	_ensure_layers()
	_clear_layer(floor_layer)
	_clear_layer(decor_layer)
	_build_floor()
	_build_central_carpet()
	_build_perimeter_architecture()
	_build_landmarks()
	queue_redraw()


func _ensure_layers() -> void:
	if not is_instance_valid(floor_layer):
		floor_layer = Node2D.new()
		floor_layer.name = "FloorLayer"
		floor_layer.z_index = 0
		add_child(floor_layer)
	if not is_instance_valid(decor_layer):
		decor_layer = Node2D.new()
		decor_layer.name = "DecorLayer"
		decor_layer.z_index = 1
		add_child(decor_layer)


func _clear_layer(layer: Node2D) -> void:
	if not is_instance_valid(layer):
		return
	for child in layer.get_children():
		child.free()


func _add_sprite(
	layer: Node2D,
	texture: Texture2D,
	world_position: Vector2,
	scale_factor: float = 1.0,
	flip_h: bool = false,
	z_offset: int = 0
) -> Sprite2D:
	if texture == null or not is_instance_valid(layer):
		return null
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = world_position
	sprite.scale = Vector2(scale_factor, scale_factor)
	sprite.flip_h = flip_h
	sprite.z_index = z_offset
	sprite.process_mode = Node.PROCESS_MODE_DISABLED
	layer.add_child(sprite)
	return sprite


func _cell_hash(cell_x: int, cell_y: int, salt: int = 0) -> int:
	var value := cell_x * 73856093
	value = value ^ (cell_y * 19349663)
	value = value ^ ((stage_number + salt) * 83492791)
	return absi(value)


func _pick_damaged_floor(cell_x: int, cell_y: int) -> Texture2D:
	var index := _cell_hash(cell_x, cell_y, 17) % DAMAGED_FLOORS.size()
	return DAMAGED_FLOORS[index]


func _build_floor() -> void:
	var columns := maxi(1, ceili(map_size.x / FLOOR_STEP_X))
	var rows := maxi(1, ceili(map_size.y / FLOOR_STEP_Y))
	var damage_threshold := int(round(ruin_ratio * 820.0))

	for row in range(rows):
		for column in range(columns):
			var roll := _cell_hash(column, row, 3) % 1000
			var texture: Texture2D = FLOOR_PLAIN
			if roll < damage_threshold:
				texture = _pick_damaged_floor(column, row)
			elif roll % 19 == 0:
				texture = FLOOR_EMBLEM

			_add_sprite(
				floor_layer,
				texture,
				Vector2(
					float(column) * FLOOR_STEP_X + FLOOR_STEP_X * 0.5,
					float(row) * FLOOR_STEP_Y + 126.0
				)
			)


func _build_central_carpet() -> void:
	var center_x := map_size.x * 0.5
	var center_y := map_size.y * 0.5
	var runner_y := 360.0
	var runner_end := center_y - FLOOR_STEP_Y * 0.45
	var runner_index := 0

	while runner_y < runner_end:
		var texture: Texture2D = FLOOR_RUG_RUNNER
		if stage_number >= 4:
			var damaged_roll := _cell_hash(runner_index, 0, 71) % 100
			if damaged_roll < int(round(ruin_ratio * 100.0)):
				texture = (
					DAMAGED_FLOORS[4]
					if damaged_roll % 2 == 0
					else DAMAGED_FLOORS[6]
				)
		_add_sprite(
			floor_layer,
			texture,
			Vector2(center_x, runner_y),
			1.0,
			false,
			2
		)
		runner_y += FLOOR_STEP_Y
		runner_index += 1

	var center_texture: Texture2D = FLOOR_RUG_SQUARE
	if stage_number >= 6:
		center_texture = DAMAGED_FLOORS[5]
	_add_sprite(
		floor_layer,
		center_texture,
		Vector2(center_x, center_y),
		1.0,
		false,
		3
	)


func _intact_wall_for_index(index: int) -> Texture2D:
	match index % 5:
		0:
			return WALL_BANNER
		1:
			return WALL_WINDOW
		2:
			return WALL_SIGIL
		3:
			return WALL_LARGE_BANNER
		_:
			return WALL_CORNER_IN


func _wall_for_slot(index: int) -> Texture2D:
	var roll := _cell_hash(index, 0, 101) % 1000
	var damaged_chance := int(round(ruin_ratio * 1000.0))
	if roll < damaged_chance:
		return DAMAGED_WALLS[_cell_hash(index, 1, 113) % DAMAGED_WALLS.size()]
	return _intact_wall_for_index(index)


func _pillar_for_slot(index: int) -> Texture2D:
	var roll := _cell_hash(index, 2, 137) % 1000
	if roll < int(round(ruin_ratio * 1000.0)):
		return DAMAGED_PILLARS[
			_cell_hash(index, 3, 149) % DAMAGED_PILLARS.size()
		]
	return PILLAR_ORNATE if index % 2 == 0 else PILLAR_PLAIN


func _build_perimeter_architecture() -> void:
	var top_y := 155.0
	var spacing := 620.0
	var slot := 0
	var x := 330.0
	while x < map_size.x - 330.0:
		_add_sprite(
			decor_layer,
			_wall_for_slot(slot),
			Vector2(x, top_y),
			0.92,
			false,
			0
		)
		x += spacing
		slot += 1

	# Vertical pillars keep the very large later-stage maps from looking like
	# an empty rectangle. They are visual-only so combat pathing is unchanged.
	var side_y := 520.0
	var side_slot := 0
	while side_y < map_size.y - 420.0:
		var left_texture := _pillar_for_slot(side_slot)
		var right_texture := _pillar_for_slot(side_slot + 19)
		_add_sprite(
			decor_layer,
			left_texture,
			Vector2(115.0, side_y),
			0.88,
			false,
			0
		)
		_add_sprite(
			decor_layer,
			right_texture,
			Vector2(map_size.x - 115.0, side_y),
			0.88,
			true,
			0
		)
		side_y += 760.0
		side_slot += 1

	# From the middle stages onward, a few collapsed archways appear around the
	# perimeter. Density grows with the castle's destruction level.
	var arch_count := maxi(stage_number - 3, 0)
	for arch_index in range(arch_count):
		var side := arch_index % 2
		var lane := float(arch_index / 2 + 1) / float(maxi((arch_count + 1) / 2 + 1, 2))
		var y := lerpf(720.0, map_size.y - 620.0, lane)
		var x_position := 250.0 if side == 0 else map_size.x - 250.0
		_add_sprite(
			decor_layer,
			DAMAGED_ARCHES[
				_cell_hash(arch_index, side, 173) % DAMAGED_ARCHES.size()
			],
			Vector2(x_position, y),
			0.78,
			side == 1,
			1
		)


func _build_landmarks() -> void:
	var center_x := map_size.x * 0.5
	var throne_texture: Texture2D = THRONE
	if stage_number >= 5:
		throne_texture = DAMAGED_THRONE
	_add_sprite(
		decor_layer,
		throne_texture,
		Vector2(center_x, 330.0),
		0.90,
		false,
		2
	)

	# Entry/exit read as the same castle across stages, but the gate visibly
	# fails as the invasion progresses.
	var gate_texture: Texture2D = DOOR_CLOSED
	if stage_number >= 3:
		gate_texture = DOOR_OPEN
	if stage_number >= 7:
		gate_texture = DAMAGED_ARCHES[
			_cell_hash(stage_number, 0, 211) % DAMAGED_ARCHES.size()
		]
	_add_sprite(
		decor_layer,
		gate_texture,
		Vector2(center_x, map_size.y - 180.0),
		0.88,
		false,
		1
	)

	# Symmetric side landmarks give Stage 1 a deliberate throne-room layout.
	# Later stages retain the same silhouette while more of the surrounding
	# architecture becomes damaged.
	var landmark_y := minf(760.0, map_size.y * 0.24)
	_add_sprite(
		decor_layer,
		BRAZIER,
		Vector2(center_x - 520.0, landmark_y),
		0.72,
		false,
		1
	)
	_add_sprite(
		decor_layer,
		BRAZIER,
		Vector2(center_x + 520.0, landmark_y),
		0.72,
		true,
		1
	)
	_add_sprite(
		decor_layer,
		CRYSTAL_SCONCE,
		Vector2(center_x - 780.0, landmark_y + 340.0),
		0.70,
		false,
		1
	)
	_add_sprite(
		decor_layer,
		CRYSTAL_SCONCE,
		Vector2(center_x + 780.0, landmark_y + 340.0),
		0.70,
		true,
		1
	)

	if stage_number <= 4:
		_add_sprite(
			decor_layer,
			ALTAR,
			Vector2(center_x, map_size.y * 0.72),
			0.72,
			false,
			1
		)
	else:
		# The altar/stair composition is progressively lost after Stage 4.
		_add_sprite(
			decor_layer,
			STAIRS_LEFT,
			Vector2(center_x - 250.0, map_size.y * 0.72),
			0.62,
			false,
			1
		)
		if stage_number <= 7:
			_add_sprite(
				decor_layer,
				STAIRS_RIGHT,
				Vector2(center_x + 250.0, map_size.y * 0.72),
				0.62,
				false,
				1
			)


func _draw() -> void:
	var darkness := ruin_ratio
	var background := Color(
		lerpf(0.060, 0.028, darkness),
		lerpf(0.052, 0.026, darkness),
		lerpf(0.072, 0.040, darkness),
		1.0
	)
	draw_rect(Rect2(Vector2.ZERO, map_size), background, true)
	draw_rect(
		Rect2(Vector2.ZERO, map_size),
		Color(0.25, 0.20, 0.28, 0.92),
		false,
		8.0
	)
