extends Node2D
## Development rig: actual 16 uploaded PNGs, no single-image stretch.
const ROOT := "res://assets/art/effects/gatcha/bulgasal/rig_v1/"
var upper: Node2D
var limbs: Array[Sprite2D] = []
var flexible_bones: Array[Array] = []
var flexible_kinds: Array[String] = []
var parts: Array[Node2D] = []
var layout: Dictionary
var _textures: Dictionary = {}

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	layout = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "layout.json"))
	upper = Node2D.new()
	upper.name = "BreathingUpperBody"
	upper.position = Vector2(380, 640)
	add_child(upper)
	for spec: Dictionary in layout.parts:
		var host: Node2D = upper if spec.parent == "upper" else self
		var layer := Node2D.new()
		layer.name = spec.id
		layer.position = Vector2(spec.center[0], spec.center[1]) - (upper.position if host == upper else Vector2.ZERO)
		layer.rotation = deg_to_rad(float(spec.rotation_degrees))
		layer.scale = Vector2.ONE * float(layout.uniform_scale)
		layer.z_index = int(spec.z)
		host.add_child(layer)
		parts.append(layer)
		var rect := Rect2(float(spec.region[0]), float(spec.region[1]), float(spec.region[2]), float(spec.region[3]))
		var tex := _load_texture(ROOT + String(spec.file))
		if tex == null:
			continue
		if not String(spec.motion).is_empty():
			_build_flexible(layer, tex, rect, String(spec.motion))
		else:
			var sprite := Sprite2D.new()
			sprite.texture = tex
			sprite.region_enabled = true
			sprite.region_rect = rect
			layer.add_child(sprite)
			limbs.append(sprite)
	_add_joint_overlays()
	set_time(0.0)

func _load_texture(path: String) -> Texture2D:
	if _textures.has(path):
		return _textures[path]
	var tex := load(path) as Texture2D
	if tex == null:
		push_error("Missing imported texture: " + path)
		return null
	_textures[path] = tex
	return tex

func _build_flexible(layer: Node2D, tex: Texture2D, rect: Rect2, kind: String) -> void:
	var skeleton := Skeleton2D.new()
	layer.add_child(skeleton)
	var bones: Array[Bone2D] = []
	for i in range(3):
		var bone := Bone2D.new()
		bone.name = "PinnedRoot" if i == 0 else "Flow_%d" % i
		bone.position = Vector2(0, -rect.size.y * 0.5 + rect.size.y * i * 0.28)
		bone.rest = Transform2D(0.0, bone.position)
		bone.set_autocalculate_length_and_angle(false)
		bone.length = 40.0
		skeleton.add_child(bone)
		bones.append(bone)
	var vertices := PackedVector2Array()
	var uv := PackedVector2Array()
	var triangles: Array[PackedInt32Array] = []
	var weights: Array[PackedFloat32Array] = [PackedFloat32Array(), PackedFloat32Array(), PackedFloat32Array()]
	for y in range(19):
		for x in range(13):
			var fraction := Vector2(float(x) / 12.0, float(y) / 18.0)
			vertices.append(fraction * rect.size - rect.size * 0.5)
			uv.append(rect.position + fraction * rect.size)
			# Roots are genuinely pinned. Tips move with lag, no whole-part scale.
			var middle := smoothstep(0.18, 0.55, fraction.y)
			var tip := smoothstep(0.55, 0.94, fraction.y)
			weights[0].append(1.0 - middle)
			weights[1].append(middle * (1.0 - tip))
			weights[2].append(middle * tip)
	for y in range(18):
		for x in range(12):
			var a := y * 13 + x
			triangles.append(PackedInt32Array([a, a + 1, a + 14]))
			triangles.append(PackedInt32Array([a, a + 14, a + 13]))
	var mesh := Polygon2D.new()
	mesh.texture = tex
	mesh.polygon = vertices
	mesh.uv = uv
	mesh.polygons = triangles
	mesh.antialiased = false
	layer.add_child(mesh)
	mesh.skeleton = mesh.get_path_to(skeleton)
	for i in range(3):
		mesh.add_bone(skeleton.get_path_to(bones[i]), weights[i])
	flexible_bones.append(bones)
	flexible_kinds.append(kind)

func _add_joint_overlays() -> void:
	var tex := _load_texture(ROOT + "joint_patch_atlas.png")
	if tex == null:
		return
	var size_half := tex.get_size() * 0.5
	# Generated patch plates conceal draft tube-end cuts. Not original-pixel-identical art.
	var patches := [
		[Vector2(135, 547), Vector2(120, 118), 0, true, 0.2],
		[Vector2(546, 596), Vector2(155, 140), 0, true, -0.4],
		[Vector2(704, 577), Vector2(73, 86), 1, true, -0.2],
		[Vector2(185, 887), Vector2(158, 134), 2, false, -0.2],
		[Vector2(483, 884), Vector2(130, 122), 2, false, 0.2],
		[Vector2(236, 1102), Vector2(115, 76), 3, false, 0.2],
	]
	for patch: Array in patches:
		var sprite := Sprite2D.new()
		var host: Node2D = upper if patch[3] else self
		sprite.texture = tex
		sprite.region_enabled = true
		var cell := int(patch[2])
		sprite.region_rect = Rect2(Vector2(cell % 2, cell / 2) * size_half, size_half)
		sprite.scale = Vector2(patch[1]) / size_half
		sprite.position = Vector2(patch[0]) - (upper.position if host == upper else Vector2.ZERO)
		sprite.rotation = float(patch[4])
		sprite.z_index = 24
		host.add_child(sprite)

func set_time(seconds: float) -> void:
	if upper == null:
		return
	# Foot/leg positions and every calibrated scale stay untouched.
	upper.position.y = 640.0 - sin(seconds * TAU / 3.6) * 1.8
	upper.rotation = deg_to_rad(sin(seconds * TAU / 3.6 - 0.2) * 0.10)
	for index in range(flexible_bones.size()):
		var bones: Array = flexible_bones[index]
		var kind := flexible_kinds[index]
		var amplitude := 1.8 if kind == "hair" else 1.2 if kind == "cloth" else 0.45
		var phase := 0.4 if kind == "hair" else 1.2 if kind == "cloth" else 2.0
		bones[0].rotation = 0.0
		bones[1].rotation = deg_to_rad(sin(seconds * 2.0 - phase) * amplitude)
		bones[2].rotation = deg_to_rad(sin(seconds * 2.0 - phase - 0.65) * amplitude * 1.7)
