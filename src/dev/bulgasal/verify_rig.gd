extends SceneTree
## Isolated fixture: --headless --path <project> --script res://src/dev/bulgasal/verify_rig.gd
var failures := 0

func _initialize() -> void:
	verify.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func verify() -> void:
	var scene := load("res://src/dev/bulgasal/cutscene_preview.tscn") as PackedScene
	var preview = scene.instantiate()
	root.add_child(preview)
	preview.set_process(false)
	await process_frame
	var rig = preview.rig
	check(rig.get_child_count() == 1, "Draft parts or overlays remain active")
	check(rig.mesh.texture.resource_path == rig.ORIGINAL, "Original artwork not used")
	check(is_equal_approx(rig.portrait.scale.x, rig.portrait.scale.y), "Artwork aspect ratio distorted")
	check(rig.bones.size() == 10, "Independent rig bones missing")
	check(rig.mesh.polygon.size() == 3969, "Detailed deformation mesh missing")
	for vertex in range(rig.mesh.polygon.size()):
		var total := 0.0
		for weights in rig.vertex_weights:
			total += weights[vertex]
		check(is_equal_approx(total, 1.0), "Weights are not normalized")
	for fixed_point in [Vector2(350, 380), Vector2(210, 1300), Vector2(830, 1400), Vector2(795, 1130)]:
		check(is_equal_approx(rig._weights_at(fixed_point)[0], 1.0), "Face or legs assigned wind weights")
	rig.set_time(0.0)
	for bone in rig.bones:
		check(bone.transform.is_equal_approx(bone.rest), "Neutral pose differs from original")
	var initial: Transform2D = rig.portrait.transform
	var count := get_node_count()
	for sample in range(300):
		preview.set_time(float(sample) / 60.0)
		check(rig.bones[0].transform == rig.bones[0].rest, "Fixed root moved")
		check(rig.portrait.transform == initial, "Original fullbody container changed during playback")
	check(get_node_count() == count, "Per-frame node growth")
	var art_bounds := Rect2(rig.portrait.position, rig.mesh.texture.get_size() * rig.portrait.scale)
	check(Rect2(Vector2.ZERO, rig.CANVAS).encloses(art_bounds), "Original source canvas clipped")
	preview.set_time(0.0)
	check(is_zero_approx(preview.label.modulate.a), "Name visible before reveal")
	preview.set_time(4.8)
	check(is_equal_approx(preview.label.modulate.a, 1.0), "Final name missing")
	for viewport_size in [Vector2(540, 960), Vector2(360, 800), Vector2(768, 1024), Vector2(960, 540)]:
		preview.size = viewport_size
		preview._layout()
		var design_rect := Rect2(preview.stage.position, Vector2(540, 960) * preview.stage.scale)
		check(Rect2(Vector2.ZERO, viewport_size).encloses(design_rect), "Design canvas clipped at " + str(viewport_size))
	print("BULGASAL_RIG_VERIFY: ", "PASS" if failures == 0 else "FAIL", " original_artwork=1 bones=10 mesh_vertices=3969 samples=300 aspect_ratios=4 failures=", failures)
	quit(0 if failures == 0 else 1)
