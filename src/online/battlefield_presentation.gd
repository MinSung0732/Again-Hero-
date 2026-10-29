extends Node2D
## Reuse castle layout/texture processing; never create client collision bodies.
const FIELD := preload("res://src/battle/stage1_battlefield.gd")
const SAMPLE := preload("res://src/online/presentation_snapshot.gd")
const DATA := preload("res://src/data/online_presentation_catalog.gd")
const THEMES := preload("res://src/data/battlefield_theme_catalog.gd")
var field
var descriptor := {}
var prop_commands: Array = []
var rebuilds := 0
func prepare(value: Dictionary) -> bool:
	if not DATA.battlefield_valid(value): return false
	visible = true
	if descriptor == value: return true
	transform = Transform2D.IDENTITY; z_index = 0
	if field == null:
		field = FIELD.new(); field.render_only = true; add_child(field)
	field.configure(value.stage,Vector2(value.bounds[0],value.bounds[1]),_theme(value))
	_capture(value)
	return true

func prepare_async(value: Dictionary,current: Callable,progress: Callable) -> bool:
	if not DATA.battlefield_valid(value): return false
	if not current.is_valid() or not current.call(): return false
	if descriptor == value: visible = true; progress.call(1.0); return true
	descriptor = {}; prop_commands.clear()
	visible = true; transform = Transform2D.IDENTITY; z_index = 0
	if field == null:
		field = FIELD.new(); field.render_only = true; add_child(field)
	if not await field.configure_async(value.stage,Vector2(value.bounds[0],value.bounds[1]),current,progress,_theme(value)): return false
	if not current.is_valid() or not current.call(): return false
	_capture(value); return true
func _theme(value: Dictionary) -> String:
	var id = value.get("theme", "castle")
	return id if id is String and id in THEMES.ids() else "castle"

func _capture(value: Dictionary) -> void:
	# The view can resize/reposition us while an asynchronous load yields.
	transform = Transform2D.IDENTITY; z_index = 0
	var sampler := SAMPLE.new()
	sampler.coordinate_space = get_parent().get_global_transform().affine_inverse()
	prop_commands.clear()
	for prop in field.depth_prop_roots:
		sampler.append_tree(prop,-2,prop_commands)
		prop.visible = false # Interleave these commands with actors in the view.
	descriptor = value.duplicate(true); rebuilds += 1
	z_index = DATA.BACKGROUND_Z
