extends "res://src/monsters/goblin_thrower_projectile.gd"
const SHAMAN_POOL_KEY := "powwow_mummy_projectile"
static var shaman_frames: Dictionary = {}
var source_ref: WeakRef

func _on_body_entered(body: Node) -> void:
	if not active or not is_instance_valid(body) or body.is_queued_for_deletion() or (not body.is_in_group("hero") and not body.is_in_group("hero_summons")):
		return
	active = false
	set_deferred("monitoring",false)
	set_physics_process(false)
	if body.has_method("take_damage"):
		var before := int(body.get("current_hp"))
		var shield_before := float(body.get("shield_hp")) if body.get("shield_hp") != null else 0.0
		var source: Node = source_ref.get_ref() if source_ref != null else null
		if body.is_in_group("hero"):
			body.call("take_damage",damage,source)
		else:
			body.call("take_damage",damage)
		var shield_after := float(body.get("shield_hp")) if body.get("shield_hp") != null else 0.0
		if (before > int(body.get("current_hp")) or shield_before > shield_after) and is_instance_valid(source) and source.has_method("on_projectile_damage"):
			source.call("on_projectile_damage")
	call_deferred("_finish_projectile")

func _get_frames() -> SpriteFrames:
	var key := "elite" if elite_visual else "normal"
	if shaman_frames.has(key):
		return shaman_frames[key]
	var directory := "res://assets/art/%s/powwowmummy/frames/effect1" % ("elitemonster" if elite_visual else "monsters")
	var frames := SpriteFrames.new()
	frames.add_animation(&"fly")
	frames.set_animation_speed(&"fly",10.0)
	for i in range(1,3):
		var texture := _load_texture("%s/Projectile_%02d.png" % [directory,i])
		if texture != null:
			frames.add_frame(&"fly",texture)
	if frames.get_frame_count(&"fly") > 0:
		var texture := frames.get_frame_texture(&"fly",0)
		frames.set_meta("visual_scale",64.0 / maxf(texture.get_width(),texture.get_height()))
	shaman_frames[key] = frames
	return frames

func _finish_projectile() -> void:
	active = false
	var parent := get_parent()
	if is_instance_valid(parent) and parent.has_method("recycle_projectile"):
		parent.call("recycle_projectile",self,SHAMAN_POOL_KEY)
	else:
		queue_free()

func deactivate_for_pool() -> void:
	source_ref = null
	super.deactivate_for_pool()
