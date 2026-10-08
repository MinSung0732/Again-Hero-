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
	check(rig.parts.size() == 16, "All 16 separate parts must exist")
	check(rig.flexible_bones.size() == 3, "Mane, cloth and tail need independent bones")
	var initial: Array[Transform2D] = []
	for part in rig.parts:
		initial.append(part.transform)
	var count := get_node_count()
	for sample in range(300):
		preview.set_time(float(sample) / 60.0)
		for index in range(rig.parts.size()):
			var part: Node2D = rig.parts[index]
			check(part.transform == initial[index], "Calibrated part transform changed: " + String(part.name))
		for bones in rig.flexible_bones:
			check(is_zero_approx(bones[0].rotation), "Flexible root moved")
	check(get_node_count() == count, "Per-frame node growth")
	preview.set_time(0.0)
	check(is_zero_approx(preview.label.modulate.a), "Name visible before reveal")
	preview.set_time(4.8)
	check(is_equal_approx(preview.label.modulate.a, 1.0), "Final name missing")
	for viewport_size in [Vector2(540, 960), Vector2(360, 800), Vector2(768, 1024), Vector2(960, 540)]:
		preview.size = viewport_size
		preview._layout()
		var design_rect := Rect2(preview.stage.position, Vector2(540, 960) * preview.stage.scale)
		check(Rect2(Vector2.ZERO, viewport_size).encloses(design_rect), "Design canvas clipped at " + str(viewport_size))
	print("BULGASAL_RIG_VERIFY: ", "PASS" if failures == 0 else "FAIL", " parts=16 flexible=3 samples=300 aspect_ratios=4 failures=", failures)
	quit(0 if failures == 0 else 1)
