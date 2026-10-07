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
	var cached: Texture2D = preview.effects.frames[0].atlas
	for view_size in [Vector2(540, 960), Vector2(360, 800), Vector2(1080, 1920), Vector2(960, 540)]:
		preview.size = view_size
		preview._layout()
		for frame in range(301):
			var t := float(frame) / 60.0
			preview.set_time(t)
			preview.effects.update_origin()
			assert(preview.effects.origin.is_equal_approx(preview.rig.spell_origin()))
			assert(preview.effects.frames[0].atlas == cached)
			assert(FX.discharge(t) >= 0.0 and FX.discharge(t) <= 1.0)
			assert(FX.shake(t).length() <= 8.0)
			assert(preview.rig.bones[0].scale == Vector2.ONE)
		preview.set_time(4.2)
		assert(preview.name_label.modulate.a == 1.0)
	assert(FX.discharge(0.0) == 0.0 and FX.discharge(5.0) == 0.0)
	assert(FX.discharge(FX.RELEASE) > 0.99)
	assert(FX.shake(1.89) == Vector2.ZERO and FX.shake(3.0) == Vector2.ZERO)
	preview.free()
	print("Zeus lightning PNG/alpha/gutters/atlas cache/tip tracking/timeline/4 aspect ratios PASS")
	quit()
