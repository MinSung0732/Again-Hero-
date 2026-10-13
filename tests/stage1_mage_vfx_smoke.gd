extends SceneTree

const VFX := preload("res://src/ui/stage1_mage_vfx.gd")
var failed := false

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	for kind in ["projectile", "effect_01", "effect_02", "effect_03"]:
		var count := int(VFX.FRAME_COUNTS[kind])
		for index in range(1, count + 1):
			var texture := VFX.frame(kind, index)
			if texture == null or texture.get_size() != Vector2(128, 128):
				failed = true
				push_error("Stage1 VFX frame missing/invalid: %s:%d" % [kind, index])
			elif VFX.frame(kind, index) != texture:
				failed = true
				push_error("Stage1 VFX atlas not cached: %s:%d" % [kind, index])
		if VFX.frame(kind, count + 1) != null:
			failed = true
			push_error("Stage1 VFX invalid index accepted: " + kind)
	print("STAGE1_MAGE_VFX_SMOKE_" + ("FAILED" if failed else "OK"))
	quit(1 if failed else 0)
