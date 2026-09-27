extends CanvasLayer
class_name HeroRevealCutscene

signal bgm_start_requested(stage_id: String)
signal finished

const EFFECT_DIR := "res://assets/art/UI/talk_light_only_30_frames"
const LOADING_DIR := "res://assets/art/UI/loading/loadingframes"
const EFFECT_FRAME_COUNT := 30
const LOADING_FRAME_COUNT := 8
const EFFECT_FRAME_SECONDS := 0.038
const REVEAL_SECONDS := 0.42
const REVEAL_HOLD_SECONDS := 0.22
const LOADING_FRAME_SECONDS := 0.08
const LOADING_LOOPS := 2
const OUTRO_SECONDS := 0.22
const STINGER_PARTS := [
	"res://assets/audio/sfx/hero_reveal_stinger_data/part_00.tres",
	"res://assets/audio/sfx/hero_reveal_stinger_data/part_01.tres",
	"res://assets/audio/sfx/hero_reveal_stinger_data/part_02.tres",
	"res://assets/audio/sfx/hero_reveal_stinger_data/part_03.tres",
	"res://assets/audio/sfx/hero_reveal_stinger_data/part_04.tres",
]

@onready var root: Control = $Root
@onready var effect_frame: TextureRect = $Root/EffectFrame
@onready var hero_portrait: TextureRect = $Root/HeroPortrait
@onready var title_panel: Panel = $Root/TitlePanel
@onready var title_label: Label = $Root/Title
@onready var true_name_label: Label = $Root/TrueName
@onready var loading_panel: Panel = $Root/LoadingPanel
@onready var loading_logo: TextureRect = $Root/LoadingLogo
@onready var loading_text: Label = $Root/LoadingText
@onready var reveal_stinger: AudioStreamPlayer = $RevealStinger

static var _effect_frames: Array[Texture2D] = []
static var _loading_frames: Array[Texture2D] = []
static var _stinger_stream: AudioStreamOggVorbis

var _active: bool = false
var _stage_id: String = ""
var _portrait_material: ShaderMaterial


func _ready() -> void:
	visible = false
	_portrait_material = hero_portrait.material as ShaderMaterial
	reveal_stinger.stream = _load_reveal_stinger()


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
	effect_frame.texture = (
		_effect_frames[0]
		if not _effect_frames.is_empty()
		else null
	)
	effect_frame.visible = true
	hero_portrait.visible = true
	hero_portrait.scale = Vector2(0.84, 0.84)
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
	if reveal_stinger.stream != null:
		reveal_stinger.play()

	for frame in _effect_frames:
		if not _active:
			return
		effect_frame.texture = frame
		await get_tree().create_timer(EFFECT_FRAME_SECONDS).timeout

	if not _active:
		return

	await _reveal_hero()
	if not _active:
		return

	await get_tree().create_timer(REVEAL_HOLD_SECONDS).timeout
	await _play_fake_loading()
	if not _active:
		return

	if reveal_stinger.playing:
		await reveal_stinger.finished
	if not _active:
		return

	bgm_start_requested.emit(_stage_id)
	await get_tree().create_timer(0.18).timeout
	if not _active:
		return

	var tween := create_tween()
	tween.tween_property(root, "modulate:a", 0.0, OUTRO_SECONDS)
	await tween.finished

	_active = false
	if reveal_stinger.playing:
		reveal_stinger.stop()
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
		Vector2(0.98, 0.98),
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
		Vector2(0.94, 0.94),
		0.14
	)
	await settle.finished


func _play_fake_loading() -> void:
	loading_panel.visible = false
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


func _load_reveal_stinger() -> AudioStreamOggVorbis:
	if _stinger_stream != null:
		return _stinger_stream

	var encoded := ""
	for path in STINGER_PARTS:
		if not ResourceLoader.exists(path):
			return null
		var resource = load(path)
		if resource == null or not resource.has_meta("base64"):
			return null
		encoded += String(resource.get_meta("base64"))

	var audio_bytes := Marshalls.base64_to_raw(encoded)
	if audio_bytes.is_empty():
		return null

	_stinger_stream = AudioStreamOggVorbis.load_from_buffer(audio_bytes)
	return _stinger_stream


func _load_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var resource = load(path)
	return resource as Texture2D if resource is Texture2D else null
