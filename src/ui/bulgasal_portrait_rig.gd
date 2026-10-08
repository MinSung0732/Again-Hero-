extends Node2D
## Native original-art mesh rig. Not a Cubism model or generated replacement anatomy.
const ORIGINAL := "res://assets/art/effects/gatcha/bulgasal/rig_v1/approved_fullbody.png"
const CANVAS := Vector2(768, 1280)
const COLUMNS := 49
const ROWS := 81
var portrait: Node2D
var mesh: Polygon2D
var bones: Array[Bone2D] = []
var vertex_weights: Array[PackedFloat32Array] = []
var mane_outline := PackedVector2Array([Vector2(490, 220), Vector2(710, 245), Vector2(850, 350), Vector2(971, 510), Vector2(971, 890), Vector2(750, 890), Vector2(700, 790), Vector2(760, 690), Vector2(700, 530), Vector2(540, 450)])
var hand_outline := PackedVector2Array([Vector2(710, 600), Vector2(850, 605), Vector2(900, 780), Vector2(830, 850), Vector2(735, 820), Vector2(670, 690)])

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var texture := load(ORIGINAL) as Texture2D
	if texture == null:
		push_error("Missing original Bulgasal artwork")
		return
	var source_size := texture.get_size()
	portrait = Node2D.new()
	portrait.name = "OriginalArtworkRig"
	var factor := minf(CANVAS.x / source_size.x, CANVAS.y / source_size.y)
	portrait.scale = Vector2.ONE * factor
	portrait.position = (CANVAS - source_size * factor) * 0.5
	add_child(portrait)
	var skeleton := Skeleton2D.new()
	portrait.add_child(skeleton)
	var pivots := [Vector2.ZERO, Vector2(555, 335), Vector2(690, 490), Vector2(450, 865), Vector2(505, 1110), Vector2(785, 990), Vector2(830, 1170), Vector2(480, 665), Vector2(290, 600), Vector2(720, 630)]
	for index in range(pivots.size()):
		var bone := Bone2D.new()
		bone.name = ["FixedBody", "ManeRoot", "ManeTip", "ClothRoot", "ClothTip", "TailRoot", "TailTip", "BreathingChest", "LeftArmBreath", "RightArmBreath"][index]
		bone.position = pivots[index]
		bone.rest = Transform2D(0.0, bone.position)
		bone.set_autocalculate_length_and_angle(false)
		bone.length = 30.0
		skeleton.add_child(bone)
		bones.append(bone)
		vertex_weights.append(PackedFloat32Array())
	var vertices := PackedVector2Array()
	var triangles: Array[PackedInt32Array] = []
	for y in range(ROWS):
		for x in range(COLUMNS):
			var point := Vector2(float(x) / float(COLUMNS - 1), float(y) / float(ROWS - 1)) * source_size
			vertices.append(point)
			var weights := _weights_at(point)
			for bone in range(bones.size()):
				vertex_weights[bone].append(weights[bone])
	for y in range(ROWS - 1):
		for x in range(COLUMNS - 1):
			var first := y * COLUMNS + x
			triangles.append(PackedInt32Array([first, first + 1, first + COLUMNS + 1]))
			triangles.append(PackedInt32Array([first, first + COLUMNS + 1, first + COLUMNS]))
	mesh = Polygon2D.new()
	mesh.name = "SharedSeamOriginalMesh"
	mesh.texture = texture
	mesh.polygon = vertices
	mesh.uv = vertices
	mesh.polygons = triangles
	mesh.antialiased = false
	portrait.add_child(mesh)
	mesh.skeleton = mesh.get_path_to(skeleton)
	for index in range(bones.size()):
		mesh.add_bone(skeleton.get_path_to(bones[index]), vertex_weights[index])
	set_time(0.0)

func _weights_at(point: Vector2) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	result.resize(10)
	# Protect the original face/horns and load-bearing feet/legs from wind deformation.
	var right_leg := PackedVector2Array([Vector2(585, 910), Vector2(730, 980), Vector2(820, 1120), Vector2(940, 1290), Vector2(971, 1540), Vector2(770, 1540), Vector2(680, 1235), Vector2(610, 1080)])
	if (point.x < 540.0 and point.y < 510.0) or point.y > 1280.0 or (point.x < 390.0 and point.y > 960.0) or Geometry2D.is_point_in_polygon(point, right_leg):
		result[0] = 1.0
		return result
	# Original visible regions share vertices; fixed anatomy stays continuous with flexible tips.
	if Geometry2D.is_point_in_polygon(point, mane_outline) and not Geometry2D.is_point_in_polygon(point, hand_outline):
		var weight := _feather(point, mane_outline, 38.0) * smoothstep(510.0, 690.0, point.x)
		var tip := smoothstep(490.0, 790.0, point.y)
		result[1] = weight * (1.0 - tip)
		result[2] = weight * tip
	var cloth := PackedVector2Array([Vector2(405, 790), Vector2(555, 840), Vector2(645, 1270), Vector2(465, 1200), Vector2(345, 900)])
	if Geometry2D.is_point_in_polygon(point, cloth):
		var weight := _feather(point, cloth, 24.0) * smoothstep(815.0, 930.0, point.y)
		var tip := smoothstep(955.0, 1200.0, point.y)
		result[3] = weight * (1.0 - tip)
		result[4] = weight * tip
	var tail := PackedVector2Array([Vector2(790, 920), Vector2(965, 840), Vector2(971, 1165), Vector2(910, 1270), Vector2(775, 1130)])
	if Geometry2D.is_point_in_polygon(point, tail):
		var weight := _feather(point, tail, 30.0)
		var tip := smoothstep(1030.0, 1210.0, point.y)
		result[5] = weight * (1.0 - tip)
		result[6] = weight * tip
	if point.y > 490.0 and point.y < 815.0 and point.x > 350.0 and point.x < 680.0:
		result[7] = sin((point.y - 490.0) / 325.0 * PI) * sin((point.x - 350.0) / 330.0 * PI) * 0.8
	if point.y > 545.0 and point.y < 775.0:
		if point.x > 130.0 and point.x < 350.0:
			result[8] = sin((point.x - 130.0) / 220.0 * PI) * sin((point.y - 545.0) / 230.0 * PI) * 0.5
		elif point.x > 650.0 and point.x < 795.0:
			result[9] = sin((point.x - 650.0) / 145.0 * PI) * sin((point.y - 545.0) / 230.0 * PI) * 0.35
	var total := 0.0
	for index in range(1, 10):
		total += result[index]
	if total > 1.0:
		for index in range(1, 10):
			result[index] /= total
		total = 1.0
	result[0] = 1.0 - total
	return result

func _feather(point: Vector2, outline: PackedVector2Array, distance: float) -> float:
	var nearest := INF
	for index in range(outline.size()):
		nearest = minf(nearest, point.distance_to(Geometry2D.get_closest_point_to_segment(point, outline[index], outline[(index + 1) % outline.size()])))
	return smoothstep(0.0, distance, nearest)

func set_time(seconds: float) -> void:
	if bones.is_empty():
		return
	var wind := seconds * 1.9
	bones[1].rotation = deg_to_rad(sin(wind) * 0.8)
	bones[2].rotation = deg_to_rad((sin(wind - 0.55) + sin(0.55)) * 1.05)
	bones[3].rotation = deg_to_rad(sin(wind - 0.2) + sin(0.2)) * 0.45
	bones[4].rotation = deg_to_rad((sin(wind - 0.75) + sin(0.75)) * 0.7)
	bones[5].rotation = deg_to_rad(sin(seconds * 1.4) * 0.3)
	bones[6].rotation = deg_to_rad((sin(seconds * 1.4 - 0.5) + sin(0.5)) * 0.45)
	var breathing := sin(seconds * TAU / 3.6)
	bones[7].position.y = 665.0 - breathing * 1.1
	bones[8].position.y = 600.0 - breathing * 0.65
	bones[9].position.y = 630.0 - breathing * 0.5
