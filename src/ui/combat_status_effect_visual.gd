extends AnimatedSprite2D
class_name CombatStatusEffectVisual

const CATALOG := preload("res://src/data/combat_effect_catalog.gd")

static var _frames_cache: Dictionary = {}

const VISIBILITY_CHECK_INTERVAL := 0.10

var target: Node
var effect_type: String = ""
var _visibility_check_timer: float = 0.0
var _last_active: bool = false
var _profile: Dictionary = {}
var _pulse_active := false


static func show_on(owner: Node2D, kind: String, mirrored: bool = false) -> CombatStatusEffectVisual:
	if not is_instance_valid(owner) or owner.is_queued_for_deletion() or not CATALOG.EFFECTS.has(kind):
		return null
	var child_name := "StatusFX_" + kind
	var effect := owner.get_node_or_null(NodePath(child_name)) as CombatStatusEffectVisual
	if effect == null:
		effect = CombatStatusEffectVisual.new()
		effect.name = child_name
		owner.add_child(effect)
		effect.setup(owner, kind)
	effect.flip_h = mirrored
	effect._pulse_active = bool(effect._profile.get("pulse", false))
	if effect._pulse_active:
		effect.stop()
		effect.frame = 0
		effect._last_active = false
	effect.set_process(true)
	effect._visibility_check_timer = 0.0
	effect._process(0.0)
	return effect

func setup(new_target: Node, new_effect_type: String) -> void:
	target = new_target
	effect_type = new_effect_type
	_profile = CATALOG.EFFECTS.get(effect_type, {})
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 9
	centered = true

	var cached = _frames_cache.get(effect_type)
	var frames: SpriteFrames
	if cached is SpriteFrames:
		frames = cached
	else:
		frames = SpriteFrames.new()
		if frames.has_animation("default"):
			frames.remove_animation("default")
		frames.add_animation("fx")
		frames.set_animation_loop("fx", true)

		match effect_type:
			"slow":
				frames.set_animation_speed("fx", 12.0)
				for index in range(1, 9):
					var texture := _load_texture(
						"res://assets/art/effects/debuff/frames/slow_%02d.png" % index
					)
					if texture != null:
						frames.add_frame("fx", texture)
			"poison":
				frames.set_animation_speed("fx",10.0)
				for index in range(1,5):
					var texture := _load_texture("res://assets/art/effects/debuff/poison_frames/poison_%02d.png" % index)
					if texture != null:
						frames.add_frame("fx",texture)
			"stun":
				frames.set_animation_speed("fx", 10.0)
				for index in range(1, 5):
					var texture := _load_texture("res://assets/art/effects/debuff/stun_frames/stun_%02d.png" % index)
					if texture != null:
						frames.add_frame("fx", texture)
			"fear":
				frames.set_animation_speed("fx", 10.0)
				for index in range(1, 5):
					var texture := _load_texture(
						"res://assets/art/effects/debuff/fear_frames/fear_%02d.png" % index
					)
					if texture != null:
						frames.add_frame("fx", texture)
			"orc_rage":
				frames.set_animation_speed("fx", 14.0)
				for index in range(1, 9):
					var texture := _load_texture(
						"res://assets/art/effects/buff/frames/orc_rage/rage_%02d.png" % index
					)
					if texture != null:
						frames.add_frame("fx", texture)
			_:
				if not _profile.is_empty():
					frames.set_animation_speed("fx", CATALOG.FPS)
					frames.set_animation_loop("fx", not bool(_profile.get("pulse", false)))
					var frame_path := String(_profile["path"])
					if not frame_path.begins_with("res://"):
						frame_path = "res://assets/art/effects/" + frame_path
					for index in range(1, CATALOG.FRAME_COUNT + 1):
						var texture := _load_texture(frame_path % index)
						if texture != null:
							frames.add_frame("fx", texture)

		_frames_cache[effect_type] = frames

	match effect_type:
		"slow":
			var target_archetype := ""
			var archetype_value = target.get("hero_archetype") if is_instance_valid(target) else null
			if archetype_value != null:
				target_archetype = String(archetype_value)
			if target_archetype == "summoner_gatekeeper":
				# Stage 8 uses a feet/root node origin and a much taller body.
				# Center the slow aura above the feet and enlarge it so the
				# animation rises around the full silhouette instead of
				# floating around the wrong point.
				scale = Vector2(0.28, 0.28)
				position = Vector2(0.0, -44.0)
			else:
				scale = Vector2(0.20, 0.20)
				position = Vector2(0.0, 18.0)
		"poison":
			scale = Vector2(0.34,0.34)
			position = Vector2(0,-10)
		"stun":
			scale = Vector2(0.34, 0.34)
			position = Vector2(0.0, -34.0)
		"fear":
			scale = Vector2(0.34, 0.34)
			position = Vector2(0.0, -6.0)
			modulate = Color.WHITE
		"orc_rage":
			scale = Vector2(0.34, 0.34)
			position = Vector2(0.0, -10.0)
		_:
			if not _profile.is_empty():
				var is_hero := target.is_in_group("hero")
				var size := CATALOG.HERO_SCALE if is_hero else CATALOG.MONSTER_SCALE
				position = _profile.get("offset", Vector2.ZERO)
				if is_hero and String(target.get("hero_archetype")) == "summoner_gatekeeper":
					size *= 1.4
					position.y -= 62.0
				scale = Vector2(size, size)

	sprite_frames = frames
	visible = false
	stop()
	_visibility_check_timer = randf_range(0.0, VISIBILITY_CHECK_INTERVAL)
	if not _profile.is_empty():
		animation_finished.connect(_on_pulse_finished)
		set_process(false)


func _on_pulse_finished() -> void:
	if bool(_profile.get("pulse", false)):
		_pulse_active = false
		_last_active = false
		visible = false
		stop()
		set_process(false)

func _process(delta: float) -> void:
	if not is_instance_valid(target) or target.is_queued_for_deletion():
		queue_free()
		return
	if not _profile.is_empty():
		# Battle modals stop actor physics, so freeze new effect playback too.
		speed_scale = 1.0 if target.is_physics_processing() else 0.0

	_visibility_check_timer -= delta
	if _visibility_check_timer > 0.0:
		return
	_visibility_check_timer = VISIBILITY_CHECK_INTERVAL

	var lod_suspended := bool(
		target.get_meta("visual_lod_suspended", false)
	)
	if lod_suspended:
		# Reset the remembered state so an effect that stays active while
		# offscreen starts again immediately when the monster returns.
		_last_active = false
		if visible or is_playing():
			visible = false
			stop()
		if not _profile.is_empty() and (bool(_profile.get("pulse", false)) or not _is_configured_effect_active()):
			_pulse_active = false
			set_process(false)
		return

	var active := false
	match effect_type:
		"slow":
			active = _is_slow_active()
		"poison":
			active = bool(target.get_meta("poison_active",false))
		"stun":
			active = bool(target.get_meta("stun_active", false))
		"fear":
			active = _is_fear_active()
		"orc_rage":
			active = bool(target.get_meta("orc_berserk_visual_active", false))
		_:
			if not _profile.is_empty():
				active = _is_configured_effect_active()
			if not active:
				set_process(false)

	if active == _last_active:
		return

	_last_active = active
	visible = active
	if active:
		if sprite_frames != null and sprite_frames.get_frame_count("fx") > 0:
			play("fx")
	else:
		stop()


func _is_configured_effect_active() -> bool:
	if int(target.get("current_hp")) <= 0:
		return false
	if _profile.has("property"):
		var value = target.get(String(_profile["property"]))
		return value == _profile["equals"] if _profile.has("equals") else value != null and float(value) > 0.0
	if _profile.has("meta"):
		return float(target.get_meta(String(_profile["meta"]), 0.0)) > float(_profile.get("threshold", 0.0))
	return _pulse_active

func _is_slow_active() -> bool:
	var slow_value = target.get("slow_timer")
	if slow_value != null and float(slow_value) > 0.0:
		return true

	var now := Time.get_ticks_msec()
	if int(target.get_meta("gunner_slow_until", 0)) > now:
		return true
	if int(target.get_meta("archmage_root_until", 0)) > now:
		return true
	if int(target.get_meta("movement_slow_until", 0)) > now:
		return true
	if int(target.get_meta("sage_ice_slow_until", 0)) > now:
		return true
	if int(target.get_meta("sage_ice_root_until", 0)) > now:
		return true
	if int(target.get_meta("sage_radiance_slow_until", 0)) > now:
		return true
	return false


func _is_fear_active() -> bool:
	if not is_instance_valid(target):
		return false
	var fear_value = target.get("fear_timer")
	if fear_value != null and float(fear_value) > 0.0:
		return true
	return bool(target.get_meta("fear_active", false))


func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var loaded = load(path)
		if loaded is Texture2D:
			return loaded
	if FileAccess.file_exists(path):
		var image := Image.new()
		if image.load(path) == OK:
			return ImageTexture.create_from_image(image)
	return null
