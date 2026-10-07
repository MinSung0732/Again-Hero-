extends "res://src/monsters/goblin_thrower_projectile.gd"
const YUKI_POOL_KEY := "yuki_onna_projectile"
static var yuki_frames: Dictionary = {}
var source_ref: WeakRef
var slow_ratio := 0.1
var slow_cap := 10

func _on_body_entered(body: Node) -> void:
	if not active or not is_instance_valid(body) or body.is_queued_for_deletion() or (not body.is_in_group("hero") and not body.is_in_group("hero_summons")):
		return
	active = false
	set_deferred("monitoring",false)
	set_physics_process(false)
	if body.has_method("take_damage") and body.get("current_hp") != null:
		var before := int(body.get("current_hp"))
		var shield_before := float(body.get("shield_hp")) if body.get("shield_hp") != null else 0.0
		var source: Node = source_ref.get_ref() if source_ref != null else null
		if body.is_in_group("hero"):
			body.call("take_damage",damage,source)
		else:
			body.call("take_damage",damage)
		var shield_after := float(body.get("shield_hp")) if body.get("shield_hp") != null else 0.0
		if (before > int(body.get("current_hp")) or shield_before > shield_after) and is_instance_valid(get_parent()):
			get_parent().yuki_runtime.apply_hit(body,slow_ratio,slow_cap,source)
	call_deferred("_finish_projectile")

func _get_frames() -> SpriteFrames:
	var key := "elite" if elite_visual else "normal"
	if yuki_frames.has(key):
		return yuki_frames[key]
	var directory := "res://assets/art/%s/Yuki-onna/frames/effect1" % ("elitemonster" if elite_visual else "monsters")
	var frames := SpriteFrames.new()
	frames.add_animation(&"fly")
	frames.set_animation_speed(&"fly",12.0)
	for index in range(1,9):
		var texture := _load_texture("%s/Projectile_%02d.png" % [directory,index])
		if texture != null:
			frames.add_frame(&"fly",texture)
	if frames.get_frame_count(&"fly") > 0:
		var texture := frames.get_frame_texture(&"fly",0)
		frames.set_meta("visual_scale",64.0 / maxf(texture.get_width(),texture.get_height()))
	yuki_frames[key] = frames
	return frames

func _finish_projectile() -> void:
	active = false
	var parent := get_parent()
	if is_instance_valid(parent) and parent.has_method("recycle_projectile"):
		parent.recycle_projectile(self,YUKI_POOL_KEY)
	else:
		queue_free()

func deactivate_for_pool() -> void:
	source_ref = null
	slow_ratio = 0.1
	slow_cap = 10
	super.deactivate_for_pool()
