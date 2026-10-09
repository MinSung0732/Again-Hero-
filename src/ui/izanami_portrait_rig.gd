extends Node2D
## Seam-continuous native mesh from the exact static reassembly.
## Visible partitions supply local weights; no missing anatomy is invented.
const ROOT := "res://assets/art/effects/gatcha/izanami/rig_v1/"
const COLS := 33
const ROWS := 53
const CANVAS := Vector2(768,1280)
const PARTS := ["07_left_hair_visible.png","08_right_hair_visible.png","05_left_sleeve_visible.png","06_right_sleeve_visible.png","10_left_lower_robe_sashes_visible.png","11_right_lower_robe_sashes_visible.png"]
const PIVOTS := [Vector2.ZERO,Vector2(330,430),Vector2(490,430),Vector2(350,600),Vector2(450,600),Vector2(370,790),Vector2(430,790)]
var mesh: Polygon2D
var bones: Array[Bone2D] = []
func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var masks: Array[Image] = []
	for part in PARTS:
		masks.append((load(ROOT+"parts/"+part) as Texture2D).get_image())
	var skeleton := Skeleton2D.new()
	add_child(skeleton)
	var weights: Array[PackedFloat32Array] = []
	for i in range(PIVOTS.size()):
		var bone := Bone2D.new()
		bone.name = "FixedAnatomy" if i==0 else "WindPart"+str(i)
		bone.position = PIVOTS[i]
		bone.rest = Transform2D(0.0,bone.position)
		bone.set_autocalculate_length_and_angle(false)
		bone.length = 25
		skeleton.add_child(bone)
		bones.append(bone)
		weights.append(PackedFloat32Array())
	var vertices := PackedVector2Array()
	var triangles: Array[PackedInt32Array] = []
	for y in range(ROWS):
		for x in range(COLS):
			var point := Vector2(float(x)/(COLS-1),float(y)/(ROWS-1))*CANVAS
			vertices.append(point)
			var assigned := 0.0
			for i in range(masks.size()):
				var mask := masks[i]
				var alpha := mask.get_pixel(mini(int(point.x),767),mini(int(point.y),1279)).a
				var amount := alpha*smoothstep(PIVOTS[i+1].y,PIVOTS[i+1].y+160,point.y)
				weights[i+1].append(amount)
				assigned += amount
			weights[0].append(maxf(0.0,1.0-assigned))
	for y in range(ROWS-1):
		for x in range(COLS-1):
			var a := y*COLS+x
			triangles.append(PackedInt32Array([a,a+1,a+COLS+1]))
			triangles.append(PackedInt32Array([a,a+COLS+1,a+COLS]))
	mesh = Polygon2D.new()
	mesh.texture = load(ROOT+"actual_reassembly.png")
	mesh.polygon = vertices
	mesh.uv = vertices
	mesh.polygons = triangles
	mesh.antialiased = false
	add_child(mesh)
	mesh.skeleton = mesh.get_path_to(skeleton)
	for i in range(bones.size()):
		mesh.add_bone(skeleton.get_path_to(bones[i]),weights[i])
	set_time(0.0)
func set_time(seconds: float) -> void:
	for i in range(1,bones.size()):
		var lag := float(i)*0.23
		var wave := sin(seconds*1.8-lag)+sin(lag)
		var amplitude := 0.65 if i<3 else 0.28
		bones[i].rotation = deg_to_rad(wave*amplitude)
		bones[i].position = PIVOTS[i]+Vector2(0,-sin(seconds*TAU/3.8)*0.55)
