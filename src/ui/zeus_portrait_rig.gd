extends Node2D

const DATA := preload("res://src/data/zeus_portrait_rig_catalog.gd")
var skeleton: Skeleton2D
var animation_player: AnimationPlayer
var tip: Marker2D
var meshes: Array[Polygon2D] = []
var bones: Array[Bone2D] = []
var vertex_count := 0
var triangle_count := 0
var weight_cache: Array[PackedFloat32Array] = []

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var image := Image.load_from_file(DATA.TEXTURE)
	if image == null:
		return
	var texture := ImageTexture.create_from_image(image)
	skeleton = Skeleton2D.new()
	skeleton.name = "Skeleton"
	add_child(skeleton)
	for data in DATA.BONES:
		var bone := Bone2D.new()
		bone.name = data.id
		bone.position = data.pivot
		bone.rest = Transform2D(0, data.pivot)
		bone.set_autocalculate_length_and_angle(false)
		bone.length = 50
		skeleton.add_child(bone)
		bones.append(bone)
	tip = Marker2D.new()
	tip.name = "SpellOrigin"
	tip.position = DATA.TIP - DATA.BONES[3].pivot
	bones[3].add_child(tip)
	_build_mesh(texture)
	_build_animation()
	set_time(0)

# Calculated once. All mesh parts share vertex coordinates and skin weights:
# moving a boundary never tears a hole between adjacent parts.
func _weights(point: Vector2) -> PackedFloat32Array:
	var weights := PackedFloat32Array([1,0,0,0,0,0,0,0])
	var x := point.x
	var y := point.y
	# Keep both ankles/feet rigid at the original ground anchor.
	if y > 1060 and x > 285 and x < 530:
		return weights
	var arm_right := smoothstep(430, 490, x) * (1.0 - smoothstep(590, 720, y))
	if x > 500 and y < 620:
		arm_right = 1.0
	var arm_left := (1.0 - smoothstep(260, 330, x)) * smoothstep(460, 500, y) * (1.0 - smoothstep(585, 630, y)) * smoothstep(110, 150, x)
	var head := smoothstep(210, 270, x) * (1.0 - smoothstep(430, 485, x)) * (1.0 - smoothstep(435, 485, y))
	var hair_left := (1.0 - smoothstep(200, 290, x)) * smoothstep(295, 375, y) * (1.0 - smoothstep(460, 530, y))
	var hair_right := smoothstep(410, 465, x) * (1.0 - smoothstep(570, 680, y)) * (1.0 - arm_right)
	var cloth_left := (1.0 - smoothstep(240, 315, x)) * smoothstep(660, 800, y)
	var cloth_right := smoothstep(455, 520, x) * smoothstep(710, 830, y)
	weights[1] = head
	weights[2] = arm_left * (1.0-arm_right)
	weights[3] = arm_right
	weights[4] = hair_left * (1.0-arm_left)
	weights[5] = hair_right
	weights[6] = cloth_left
	weights[7] = cloth_right
	var total := 0.0
	for index in range(1,8):
		total += weights[index]
	weights[0] = maxf(0.0, 1.0-total)
	total += weights[0]
	for index in range(8):
		weights[index] /= total
	return weights

func _build_mesh(texture: Texture2D) -> void:
	var vertices := PackedVector2Array()
	var columns := DATA.GRID.x + 1
	var groups: Array = []
	for index in range(8):
		groups.append([])
		weight_cache.append(PackedFloat32Array())
	for y in range(DATA.GRID.y+1):
		for x in range(columns):
			var point := Vector2(float(x)/DATA.GRID.x, float(y)/DATA.GRID.y) * DATA.SIZE
			vertices.append(point)
			var weights := _weights(point)
			for index in range(8):
				weight_cache[index].append(weights[index])
	vertex_count = vertices.size()
	for y in range(DATA.GRID.y):
		for x in range(DATA.GRID.x):
			var a := y*columns+x
			var center := (vertices[a]+vertices[a+columns+1])*0.5
			var weights := _weights(center)
			var group := 0
			for index in range(1,8):
				if weights[index] > weights[group]:
					group = index
			if center.x > 450 and center.x < 610 and center.y > 625 and center.y < 700:
				group = 5
			groups[group].append(PackedInt32Array([a,a+1,a+columns+1]))
			groups[group].append(PackedInt32Array([a,a+columns+1,a+columns]))
			triangle_count += 2
	for index in range(8):
		if groups[index].is_empty():
			continue
		var mesh := Polygon2D.new()
		mesh.name = DATA.PARTS[index]
		mesh.texture = texture
		mesh.polygon = vertices
		mesh.uv = vertices
		mesh.polygons = groups[index]
		mesh.antialiased = false
		add_child(mesh)
		mesh.skeleton = mesh.get_path_to(skeleton)
		for bone_index in range(8):
			mesh.add_bone(skeleton.get_path_to(bones[bone_index]), weight_cache[bone_index])
		meshes.append(mesh)

func _build_animation() -> void:
	animation_player = AnimationPlayer.new()
	animation_player.name = "AnimationPlayer"
	add_child(animation_player)
	var animation := Animation.new()
	animation.length = 5.0
	for index in range(1,8):
		var track := animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track, NodePath("Skeleton/%s:rotation" % DATA.BONES[index].id))
		animation.track_set_interpolation_type(track, Animation.INTERPOLATION_CUBIC)
		for key in range(DATA.TIMES.size()):
			animation.track_insert_key(track, DATA.TIMES[key], deg_to_rad(float(DATA.ROTATIONS[key][index])))
	var library := AnimationLibrary.new()
	library.add_animation("skill", animation)
	animation_player.add_animation_library("",library)
	animation_player.play("skill")
	animation_player.pause()

func set_time(seconds: float) -> void:
	if animation_player != null:
		animation_player.seek(clampf(seconds,0.0,5.0),true)

func spell_origin() -> Vector2:
	return tip.global_position if tip != null else global_position
