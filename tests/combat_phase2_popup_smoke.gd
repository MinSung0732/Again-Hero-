extends SceneTree
const SCENE := preload("res://src/ui/DamageNumber.tscn")
var checks := 0
var failures := 0
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: run.call_deferred()
func original_script():
	var script := GDScript.new(); script.source_code = FileAccess.get_file_as_string("res://tests/fixtures/combat_phase2/damage_number_before.gd.txt")
	check(script.reload() == OK,"load original popup")
	return script
func state(popup) -> Array:
	return [popup.numeric_amount,popup.numeric_prefix,popup.elapsed,popup.position,popup.scale,popup.modulate,popup.pool_active,popup.visible,popup.can_merge_damage(),popup.can_merge_heal(),popup.value_label.text,popup.value_label.get_theme_color("font_color")]
func run() -> void:
	var old = SCENE.instantiate(); old.set_script(original_script()); root.add_child(old); old.set_process(false)
	var current = SCENE.instantiate(); root.add_child(current); current.set_process(false)
	for heal in [false,true]:
		seed(451); old.setup_heal(1) if heal else old.setup(1)
		seed(451); current.setup_heal(1) if heal else current.setup(1)
		for frame in 90:
			if frame < 20:
				for hit in 12:
					var color := Color(.2+hit*.03,.8,.5,1)
					if heal: old.add_heal(3,color); current.add_heal(3,color)
					else: old.add_damage(3,color); current.add_damage(3,color)
					check(old.numeric_amount == current.numeric_amount,"merge amount immediate")
			old._process(1.0/60); current._process(1.0/60)
			check(state(old) == state(current),"render-boundary state parity "+str(frame))
	# Reusing a dirty popup must discard the previous owner's pending text/color.
	current.setup(20); current.add_damage(30,Color.RED); current.setup_heal(7,Color.GREEN); current._process(0)
	check(current.value_label.text == "+7" and current.value_label.get_theme_color("font_color") == Color.GREEN,"pool reuse clears pending damage")
	current.add_heal(8); current.setup_text("immune",Color.BLUE); current._process(0)
	check(current.value_label.text == "immune" and current.value_label.get_theme_color("font_color") == Color.BLUE,"text reuse clears pending heal")
	current.setup(1); current.add_damage(2); var pending_text: String = current.value_label.text
	current.process_mode = Node.PROCESS_MODE_DISABLED
	await process_frame
	check(current.value_label.text == pending_text and current.numeric_amount == 3,"paused popup does not flush/move")
	current._process(0); check(current.value_label.text == "3","next display flushes exact sum")
	old.free(); current.free()
	print("COMBAT_PHASE2_POPUP checks=",checks," failures=",failures); quit(1 if failures else 0)
