extends SceneTree

const FX := preload("res://src/data/zeus_lightning_catalog.gd")
const PREVIEW := preload("res://src/dev/zeus_rig_preview.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var sheet := Image.load_from_file(FX.SHEET)
	assert(sheet.get_size() == Vector2i(1024, 1024) and sheet.detect_alpha() != Image.ALPHA_NONE)
	for index in range(4):
		var frame := Image.load_from_file("res://assets/art/effects/gatcha/zeus/lightning_v2/lightning_%02d.png" % (index + 1))
		assert(frame.get_size() == Vector2i(FX.CELL))
		var bounds := frame.get_used_rect()
		assert(bounds.position.x >= 32 and bounds.position.y >= 32)
		assert(bounds.end.x <= 480 and bounds.end.y <= 480)
		assert(sheet.get_region(Rect2i(Vector2i(index % 2, index / 2) * 512, Vector2i(512, 512))).get_data() == frame.get_data())
	var preview := PREVIEW.new()
	root.add_child(preview)
	preview.set_process(false)
	await process_frame
	assert(preview.effects.frames.size() == 4)
	assert(preview.rig.modulate.a == 0.0 and preview.name_label.modulate.a == 0.0)
	for mesh in preview.rig.meshes:
		assert(mesh.material == preview.reveal_material)
	var cached: Texture2D = preview.effects.frames[0].atlas
	for view_size in [Vector2(540, 960), Vector2(360, 800), Vector2(1080, 1920), Vector2(960, 540)]:
		preview.size = view_size
		preview._layout()
		assert(Rect2(Vector2.ZERO, view_size).encloses(Rect2(preview.name_label.position, preview.name_label.size)))
		assert((preview.rig.global_transform * Vector2(384, 1200)).y < preview.name_label.position.y)
		var previous_edge := -0.08
		for frame in range(301):
			var t := float(frame) / 60.0
			preview.set_time(t)
			preview.effects.update_origin()
			assert(preview.effects.origin.is_equal_approx(preview.rig.spell_origin()))
			assert(preview.effects.frames[0].atlas == cached)
			assert(FX.discharge(t) >= 0.0 and FX.discharge(t) <= 1.0)
			assert(FX.shake(t).length() <= 8.0)
			assert(preview.rig.bones[0].scale == Vector2.ONE)
			var edge: float = preview.reveal_material.get_shader_parameter("reveal_edge")
			assert(edge >= previous_edge and edge >= -0.081 and edge <= 1.081)
			previous_edge = edge
			if t <= 1.35:
				assert(is_equal_approx(edge, -0.08))
			if t >= 2.45:
				assert(is_equal_approx(edge, 1.08))
			if t < 3.55:
				assert(preview.name_label.modulate.a == 0.0)
		preview.set_time(4.2)
		assert(preview.name_label.modulate.a == 1.0)
	assert(FX.discharge(0.0) == 0.0 and FX.discharge(5.0) == 0.0)
	assert(FX.discharge(FX.RELEASE) > 0.99)
	assert(FX.shake(1.89) == Vector2.ZERO and FX.shake(3.0) == Vector2.ZERO)
	preview.set_time(0.0)
	assert(preview.rig.modulate.a == 0.0 and preview.name_label.modulate.a == 0.0)
	assert(is_equal_approx(float(preview.reveal_material.get_shader_parameter("reveal_edge")), -0.08))
	preview.free()
	print("Zeus lightning PNG/cache/tip/timeline/4 ratios/silhouette wipe/name margins/reset PASS")
	quit()
