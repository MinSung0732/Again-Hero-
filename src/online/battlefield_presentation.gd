extends Node2D
## Reuse castle layout/texture processing; never create client collision bodies.
const FIELD := preload("res://src/battle/stage1_battlefield.gd")
const SAMPLE := preload("res://src/online/presentation_snapshot.gd")
const DATA := preload("res://src/data/online_presentation_catalog.gd")
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
	field.configure(value.stage,Vector2(value.bounds[0],value.bounds[1]))
	var sampler := SAMPLE.new()
	sampler.coordinate_space = get_parent().get_global_transform().affine_inverse()
	prop_commands.clear()
	for prop in field.depth_prop_roots:
		sampler.append_tree(prop,-2,prop_commands)
		prop.visible = false # Interleave these commands with actors in the view.
	descriptor = value.duplicate(true); rebuilds += 1
	z_index = DATA.BACKGROUND_Z
	return true
