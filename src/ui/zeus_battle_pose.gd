extends Node2D
const PORTRAIT := preload("res://assets/art/effects/battle_summon/zeus/battle_cast_v1.png")
const MOTION := preload("res://src/ui/zeus_battle_pose_motion.gdshader")
var meshes: Array[Polygon2D] = []
var eye_material: ShaderMaterial
var pose_material: ShaderMaterial
# Normalized tip is recorded after inspecting the generated battle pose.
const SPELL_ANCHOR := Vector2(0.84140062, 0.19753086)

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var canvas := PORTRAIT.get_size()
	var vertices := PackedVector2Array()
	var triangles: Array[PackedInt32Array] = []
	for y in range(41):
		for x in range(25):
			vertices.append(Vector2(x / 24.0, y / 40.0) * canvas)
	for y in range(40):
		for x in range(24):
			var i := y * 25 + x
			triangles.append(PackedInt32Array([i, i+1, i+25]))
			triangles.append(PackedInt32Array([i+1, i+26, i+25]))
	var mesh := Polygon2D.new()
	mesh.polygon = vertices
	mesh.uv = vertices
	mesh.polygons = triangles
	mesh.texture = PORTRAIT
	pose_material = ShaderMaterial.new()
	pose_material.shader = MOTION
	pose_material.set_shader_parameter("canvas_size", canvas)
	mesh.material = pose_material
	add_child(mesh)
	meshes.append(mesh)
	var patch := Polygon2D.new()
	patch.name = "ClosedEyesOverlay"
	patch.polygon = PackedVector2Array([Vector2(360,470),Vector2(550,470),Vector2(550,615),Vector2(360,615)])
	patch.texture = preload("res://assets/art/effects/battle_summon/zeus/battle_closed_eyes_v1.png")
	var extent: Vector2 = patch.texture.get_size()
	patch.uv = PackedVector2Array([Vector2.ZERO,Vector2(extent.x,0),extent,Vector2(0,extent.y)])
	eye_material = ShaderMaterial.new()
	eye_material.shader = preload("res://src/ui/zeus_battle_eye_mask.gdshader")
	patch.material = eye_material
	add_child(patch)

func set_time(seconds: float) -> void:
	pose_material.set_shader_parameter("motion_time", seconds)

func spell_origin() -> Vector2:
	return to_global(PORTRAIT.get_size() * SPELL_ANCHOR)

func canvas_size() -> Vector2:
	return PORTRAIT.get_size()

func set_eye_closed(amount: float) -> void:
	eye_material.set_shader_parameter("eye_closed",clampf(amount,0.0,1.0))
