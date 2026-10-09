extends Node2D
## Native Live2D-style shared mesh: visible partitions weight continuous geometry.
## Original face, hands and legs remain fixed. No missing surfaces are invented.
const ROOT := "res://assets/art/effects/gatcha/shuten_doji/rig_v1/"
const COLS := 49
const ROWS := 81
const CANVAS := Vector2(768, 1280)
const PARTS := ["04_kanabo_handle_tassel_visible.png","09_back_hair_visible.png","12_sake_gourds_visible.png","15_left_coat_tails_visible.png","16_right_coat_tails_visible.png","17_waist_sashes_tassels_visible.png"]
const PIVOTS := [Vector2.ZERO,Vector2(554,742),Vector2(368,650),Vector2(337,820),Vector2(270,830),Vector2(450,830),Vector2(363,823)]
const AMPLITUDES := [0.0,2.6,2.1,1.4,2.8,-2.8,1.8]
var mesh: Polygon2D
var bones: Array[Bone2D] = []

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var masks: Array[Image] = []
	for part in PARTS:
		masks.append((load(ROOT + "parts/" + part) as Texture2D).get_image())
	var skeleton := Skeleton2D.new()
	add_child(skeleton)
	var weights: Array[PackedFloat32Array] = []
	for i in range(PIVOTS.size()):
		var bone := Bone2D.new()
		bone.name = "FixedAnatomy" if i == 0 else "FlexiblePart" + str(i)
		bone.position = PIVOTS[i]
		bone.rest = Transform2D(0.0, bone.position)
		bone.set_autocalculate_length_and_angle(false)
		bone.length = 25
		skeleton.add_child(bone)
		bones.append(bone)
		weights.append(PackedFloat32Array())
	var vertices := PackedVector2Array()
	var triangles: Array[PackedInt32Array] = []
	for y in range(ROWS):
		for x in range(COLS):
			var point := Vector2(float(x) / (COLS - 1), float(y) / (ROWS - 1)) * CANVAS
			vertices.append(point)
			var assigned := 0.0
			for i in range(masks.size()):
				var alpha := masks[i].get_pixel(mini(int(point.x), 767), mini(int(point.y), 1279)).a
				var distance_from_root: float = point.y-PIVOTS[i+1].y
				var amount := alpha * smoothstep(0.0, 140.0, distance_from_root)
				weights[i + 1].append(amount)
				assigned += amount
			weights[0].append(maxf(0.0, 1.0 - assigned))
	_soften_weights(weights)
	for y in range(ROWS - 1):
		for x in range(COLS - 1):
			var a := y * COLS + x
			triangles.append(PackedInt32Array([a, a + 1, a + COLS + 1]))
			triangles.append(PackedInt32Array([a, a + COLS + 1, a + COLS]))
	mesh = Polygon2D.new()
	mesh.texture = load("res://assets/art/Transcendent_monster/Shuten-doji/shuten-doji_actual_reassembly.png")
	mesh.polygon = vertices
	mesh.uv = vertices
	mesh.polygons = triangles
	mesh.antialiased = false
	add_child(mesh)
	mesh.skeleton = mesh.get_path_to(skeleton)
	for i in range(bones.size()):
		mesh.add_bone(skeleton.get_path_to(bones[i]), weights[i])
	set_time(0.0)

func _soften_weights(weights: Array[PackedFloat32Array]) -> void:
	# Partition edges are sharp; stronger rotation needs a gradual shared skin.
	# Only initialization: six diffusion passes prevent triangles folding at seams.
	for bone in range(1, weights.size()):
		for pass_index in range(6):
			var source := weights[bone]
			var softened := PackedFloat32Array()
			softened.resize(COLS * ROWS)
			for y in range(ROWS):
				for x in range(COLS):
					var index := y * COLS + x
					softened[index] = (source[index] * 4.0 + source[y * COLS + maxi(x - 1, 0)] + source[y * COLS + mini(x + 1, COLS - 1)] + source[maxi(y - 1, 0) * COLS + x] + source[mini(y + 1, ROWS - 1) * COLS + x]) / 8.0
			weights[bone] = softened
	for index in range(COLS * ROWS):
		var total := 0.0
		for bone in range(1, weights.size()):
			total += weights[bone][index]
		weights[0][index] = maxf(0.0, 1.0 - total)

func set_time(seconds: float) -> void:
	# Roots stay pinned to the shared mesh; flexible tips carry the stronger motion.
	# A reveal gust opens wings/tail, then decays into a slower living idle.
	var gust := smoothstep(1.5, 2.2, seconds) * (1.0 - smoothstep(2.65, 3.55, seconds))
	for i in range(1, bones.size()):
		var phase := float(i) * 0.31
		var wave := sin(seconds * 2.0 - phase) + sin(phase)
		var opening := gust * (0.3 if i < 4 else 1.0)
		bones[i].rotation = deg_to_rad(clampf((wave + opening) * AMPLITUDES[i], -8.0, 8.0))
		var breath := sin(seconds * TAU / 3.2 - phase) + sin(phase)
		bones[i].position = PIVOTS[i] + Vector2(0.0, -breath * (1.8 if i > 3 else 0.7))
