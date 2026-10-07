extends "res://src/ui/zeus_rig_cutscene_view.gd"

func _create_rig() -> Node2D:
	return preload("res://src/ui/zeus_assembled_portrait.gd").new()

func _reveal_shader() -> Shader:
	return preload("res://src/ui/zeus_assembled_reveal.gdshader")

func set_time(seconds: float) -> void:
	super.set_time(seconds)
	name_label.modulate.a = smoothstep(3.15, 3.5, seconds)
	reveal_material.set_shader_parameter("motion_time", seconds)
	reveal_material.set_shader_parameter("reveal_edge", lerpf(-0.08, 1.08, smoothstep(0.85, 1.7, seconds)))
