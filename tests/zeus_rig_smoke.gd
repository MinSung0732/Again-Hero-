extends SceneTree
const RIG := preload("res://src/ui/zeus_portrait_rig.gd")
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var rig := RIG.new()
	root.add_child(rig)
	await process_frame
	assert(rig.vertex_count == 1025 and rig.triangle_count == 1920)
	assert(rig.meshes.size() == 8 and rig.bones.size() == 8)
	for vertex in range(rig.vertex_count):
		var total := 0.0
		for weights in rig.weight_cache:
			assert(weights[vertex] >= 0.0 and weights[vertex] <= 1.0)
			total += weights[vertex]
		assert(is_equal_approx(total,1.0))
	assert(rig._weights(Vector2(480,1160)) == PackedFloat32Array([1,0,0,0,0,0,0,0]))
	var texture: Texture2D = rig.meshes[0].texture
	for mesh in rig.meshes:
		assert(mesh.texture == texture and mesh.get_bone_count() == 8)
		assert(mesh.uv == mesh.polygon and not mesh.antialiased)
	rig.set_time(0)
	var original := rig.spell_origin()
	assert(original.is_equal_approx(Vector2(550,375)))
	var previous := rig.bones[3].rotation
	for frame in range(301):
		rig.set_time(float(frame)/60.0)
		assert(absf(rig.bones[3].rotation-previous)<0.02)
		previous = rig.bones[3].rotation
		assert(rig.bones[0].rotation == 0.0)
		assert(rig.bones[0].scale == Vector2.ONE)
	rig.set_time(1.4)
	assert(rig.spell_origin().distance_to(original)>10.0)
	assert(rig.spell_origin().is_equal_approx(rig.bones[3].global_transform*rig.tip.position))
	rig.set_time(5)
	assert(rig.spell_origin().is_equal_approx(original))
	print("Zeus rig weights/shared texture/bones/continuous motion/attached origin/fixed feet PASS")
	rig.free()
	quit()
