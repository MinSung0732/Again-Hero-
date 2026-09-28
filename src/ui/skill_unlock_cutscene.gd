extends CanvasLayer
class_name SkillUnlockCutscene

signal finished

const DEFAULT_HOLD_SECONDS := 1.05
const INTRO_SECONDS := 0.20
const OUTRO_SECONDS := 0.18

@onready var root: Control = $BattleFrame
@onready var artwork: TextureRect = $BattleFrame/Artwork
@onready var flash: ColorRect = $BattleFrame/Flash

var _active: bool = false
var _art_material: ShaderMaterial


func _ready() -> void:
	visible = false
	_art_material = artwork.material as ShaderMaterial


func play_unlock(data: Dictionary) -> void:
	if _active:
		return

	var texture_path := String(data.get("cutscene_texture_path", ""))
	artwork.texture = _load_texture(texture_path)
	if artwork.texture == null:
		finished.emit()
		return

	_active = true
	visible = true
	root.modulate = Color(1.0, 1.0, 1.0, 0.0)
	artwork.position = Vector2.ZERO
	artwork.scale = Vector2(1.075, 1.075)
	artwork.rotation = deg_to_rad(-0.35)
	flash.color = Color(1.0, 0.86, 0.48, 0.0)
	_set_shader_value("reveal_progress", 0.0)
	_set_shader_value("glow_pulse", 0.0)

	call_deferred("_run_sequence", data)


func _run_sequence(data: Dictionary) -> void:
	var intro := create_tween()
	intro.set_parallel(true)
	intro.set_trans(Tween.TRANS_QUART)
	intro.set_ease(Tween.EASE_OUT)
	intro.tween_property(root, "modulate:a", 1.0, INTRO_SECONDS)
	intro.tween_property(artwork, "scale", Vector2.ONE, INTRO_SECONDS)
	intro.tween_property(artwork, "rotation", 0.0, INTRO_SECONDS)
	intro.tween_method(
		func(value: float) -> void:
			_set_shader_value("reveal_progress", value),
		0.0,
		1.0,
		INTRO_SECONDS
	)
	intro.tween_property(flash, "color:a", 0.42, INTRO_SECONDS * 0.45)
	await intro.finished
	if not _active:
		return

	var flash_out := create_tween()
	flash_out.tween_property(flash, "color:a", 0.0, 0.16)

	var hold_seconds := maxf(
		float(data.get("cutscene_hold_seconds", DEFAULT_HOLD_SECONDS)),
		0.35
	)
	var live_motion := create_tween()
	live_motion.set_parallel(true)
	live_motion.set_trans(Tween.TRANS_SINE)
	live_motion.set_ease(Tween.EASE_IN_OUT)
	live_motion.tween_property(
		artwork,
		"scale",
		Vector2(1.022, 1.022),
		hold_seconds
	)
	live_motion.tween_method(
		func(value: float) -> void:
			_set_shader_value("glow_pulse", value),
		0.0,
		1.0,
		hold_seconds
	)
	await live_motion.finished
	if not _active:
		return

	var outro := create_tween()
	outro.set_parallel(true)
	outro.set_trans(Tween.TRANS_QUAD)
	outro.set_ease(Tween.EASE_IN)
	outro.tween_property(root, "modulate:a", 0.0, OUTRO_SECONDS)
	outro.tween_property(
		artwork,
		"scale",
		Vector2(1.055, 1.055),
		OUTRO_SECONDS
	)
	await outro.finished

	_active = false
	visible = false
	artwork.texture = null
	finished.emit()


func _set_shader_value(parameter: StringName, value: float) -> void:
	if _art_material != null:
		_art_material.set_shader_parameter(parameter, value)


func _load_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var resource = load(path)
	return resource as Texture2D if resource is Texture2D else null
