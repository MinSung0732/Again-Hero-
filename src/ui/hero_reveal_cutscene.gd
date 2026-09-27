extends CanvasLayer
class_name HeroRevealCutscene

signal bgm_start_requested(stage_id: String)
signal finished

const EFFECT_DIR := "res://assets/art/UI/diagonal_battle_30_frames"
const LOADING_DIR := "res://assets/art/UI/loading/loadingframes"
const EFFECT_FRAME_COUNT := 30
const LOADING_FRAME_COUNT := 8
const EFFECT_FRAME_SECONDS := 0.05
const REVEAL_SECONDS := 0.48
const REVEAL_HOLD_SECONDS := 0.35
const LOADING_FRAME_SECONDS := 0.10
const LOADING_LOOPS := 2
const OUTRO_SECONDS := 0.22

@onready var root: Control = $Root
@onready var effect_frame: TextureRect = $Root/EffectFrame
@onready var hero_portrait: TextureRect = $Root/HeroPortrait
@onready var title_panel: Panel = $Root/TitlePanel
@onready var title_label: Label = $Root/Title
@onready var true_name_label: Label = $Root/TrueName
@onready var loading_panel: Panel = $Root/LoadingPanel
@onready var loading_logo: TextureRect = $Root/LoadingLogo
@onready var loading_text: Label = $Root/LoadingText

static var _effect_frames: Array[Texture2D] = []
static var _loading_frames: Array[Texture2D] = []

var _active: bool = false
var _stage_id: String = ""
var _portrait_material: ShaderMaterial


func _ready() -> void:
	visible = false
	_portrait_material = hero_portrait.material as ShaderMaterial


func play_reveal(data: Dictionary) -> void:
	if _active:
		return

	_stage_id = String(data.get("stage_id", ""))
	title_label.text = String(data.get("title", "용사"))
	var unlocked := bool(data.get("true_name_unlocked", false))
	var true_name := String(data.get("true_name", ""))
	if unlocked and not true_name.is_empty():
		true_name_label.text = "진명 : %s" % true_name
	else:
		true_name_label.text = "진명 : ???"

	var portrait_path := String(data.get("portrait_path", ""))
	hero_portrait.texture = _load_texture(portrait_path)
	if hero_portrait.texture == null:
		finished.emit()
		return

	_ensure_frame_cache()
	_active = true
	visible = true
	root.modulate = Color.WHITE
	effect_frame.visible = true
	hero_portrait.visible = true
	hero_portrait.scale = Vector2(0.94, 0.94)
	title_panel.visible = false
	title_label.modulate.a = 0.0
	true_name_label.modulate.a = 0.0
	loading_panel.visible = false
	loading_logo.visible = false
	loading_text.visible = false
	if _portrait_material != null:
		_portrait_material.set_shader_parameter("silhouette_strength", 1.0)

	call_deferred("_run_sequence")


func _run_sequence() -> void:
	for frame in _effect_frames:
		if not _active:
			return
		effect_frame.texture = frame
		await get_tree().create_timer(EFFECT_FRAME_SECONDS).timeout

	if not _active:
		return

	bgm_start_requested.emit(_stage_id)
	await _reveal_hero()
	if not _active:
		return

	await get_tree().create_timer(REVEAL_HOLD_SECONDS).timeout
	await _play_fake_loading()
	if not _active:
		return

	var tween := create_tween()
	tween.tween_property(root, "modulate:a", 0.0, OUTRO_SECONDS)
	await tween.finished

	_active = false
	visible = false
	finished.emit()


func _reveal_hero() -> void:
	title_panel.visible = true
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(
		hero_portrait,
		"scale",
		Vector2(1.04, 1.04),
		REVEAL_SECONDS
	)
	tween.tween_property(
		title_label,
		"modulate:a",
		1.0,
		REVEAL_SECONDS * 0.75
	)
	tween.tween_property(
		true_name_label,
		"modulate:a",
		1.0,
		REVEAL_SECONDS
	)
	if _portrait_material != null:
		tween.tween_method(
			func(value: float) -> void:
				_portrait_material.set_shader_parameter(
					"silhouette_strength",
					value
				),
			1.0,
			0.0,
			REVEAL_SECONDS
		)
	await tween.finished

	var settle := create_tween()
	settle.set_trans(Tween.TRANS_QUAD)
	settle.set_ease(Tween.EASE_OUT)
	settle.tween_property(
		hero_portrait,
		"scale",
		Vector2.ONE,
		0.16
	)
	await settle.finished


func _play_fake_loading() -> void:
	loading_panel.visible = true
	loading_logo.visible = true
	loading_text.visible = true
	var total_steps := LOADING_FRAME_COUNT * LOADING_LOOPS
	for index in range(total_steps):
		if not _active:
			return
		loading_logo.texture = _loading_frames[index % LOADING_FRAME_COUNT]
		var dot_count := (index % 3) + 1
		loading_text.text = "침입 기록 동기화 중%s" % ".".repeat(dot_count)
		await get_tree().create_timer(LOADING_FRAME_SECONDS).timeout


func _ensure_frame_cache() -> void:
	if _effect_frames.is_empty():
		for index in range(1, EFFECT_FRAME_COUNT + 1):
			var path := "%s/effect_%02d.png" % [EFFECT_DIR, index]
			var texture := _load_texture(path)
			if texture != null:
				_effect_frames.append(texture)

	if _loading_frames.is_empty():
		for index in range(1, LOADING_FRAME_COUNT + 1):
			var path := "%s/loading_logo_%02d.png" % [LOADING_DIR, index]
			var texture := _load_texture(path)
			if texture != null:
				_loading_frames.append(texture)


func _load_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var resource = load(path)
	return resource as Texture2D if resource is Texture2D else null
