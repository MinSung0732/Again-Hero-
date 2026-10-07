extends Node2D

const ROOT := "res://assets/art/effects/battle_summon/zeus/"
const TEXTURES := [
	preload("res://assets/art/effects/battle_summon/zeus/parts/body_remaining_visible.png"),
	preload("res://assets/art/effects/battle_summon/zeus/parts/staff_upper.png"),
	preload("res://assets/art/effects/battle_summon/zeus/parts/head_visible.png"),
	preload("res://assets/art/effects/battle_summon/zeus/parts/front_hand_sleeve_visible.png"),
	preload("res://assets/art/effects/battle_summon/zeus/parts/left_hair_visible.png"),
	preload("res://assets/art/effects/battle_summon/zeus/parts/left_cloth_visible.png"),
	preload("res://assets/art/effects/battle_summon/zeus/parts/right_cloth_visible.png"),
]
const NAMES := ["body_remaining_visible", "staff_upper", "head_visible", "front_hand_sleeve_visible", "left_hair_visible", "left_cloth_visible", "right_cloth_visible"]
var meshes: Array[Polygon2D] = []

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Shared rest geometry/UVs: all seven layers occupy the exact 768x1280 canvas.
	var vertices := PackedVector2Array()
	var triangles: Array[PackedInt32Array] = []
	for y in range(41):
		for x in range(25):
			vertices.append(Vector2(x * 32, y * 32))
	for y in range(40):
		for x in range(24):
			var i := y * 25 + x
			triangles.append(PackedInt32Array([i, i + 1, i + 25]))
			triangles.append(PackedInt32Array([i + 1, i + 26, i + 25]))
	for index in range(TEXTURES.size()):
		var mesh := Polygon2D.new()
		mesh.name = NAMES[index]
		mesh.polygon = vertices
		mesh.uv = vertices
		mesh.polygons = triangles
		mesh.texture = TEXTURES[index]
		add_child(mesh)
		meshes.append(mesh)

func set_time(_seconds: float) -> void:
	pass # Motion is a shared tiny GPU displacement, never independent layer rotation.

func spell_origin() -> Vector2:
	return to_global(Vector2(550, 375))
