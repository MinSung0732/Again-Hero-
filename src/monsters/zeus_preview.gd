extends Node2D

# Collection/formation art skeleton only. Battle creation is gated by the
# catalog until actual Zeus stats and abilities are specified.
func _ready() -> void:
	$Visual.apply_visual_profile(preload("res://src/data/zeus_visual_catalog.gd").PROFILE)
