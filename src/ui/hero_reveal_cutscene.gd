extends CanvasLayer
class_name HeroRevealCutscene

signal bgm_start_requested(stage_id: String)
signal finished

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
@onready var effect_frame: ColorRect = $Root/EffectFrame
@onready var hero_portrait: TextureRect = $Root/HeroPortrait
@onready var title_panel: Panel = $Root/TitlePanel
@onready var title_label: Label = $Root/Title
@onready var header_label: Label = $Root/Header
@onready var true_name_label: Label = $Root/TrueName
@onready var loading_progress: ProgressBar = $Root/LoadingProgress
@onready var name_divider: ColorRect = $Root/NameDivider
@onready var loading_text: Label = $Root/LoadingText
@onready var reveal_stinger: AudioStreamPlayer = $RevealStinger

static var _stinger_stream: AudioStreamOggVorbis

var _active: bool = false
var _stage_id: String = ""
var _portrait_material: ShaderMaterial
var _magic_material: ShaderMaterial
var _reveal_tween: Tween


func _ready() -> void:
	visible = false
	_portrait_material = hero_portrait.material as ShaderMaterial
	_magic_material = effect_frame.material as ShaderMaterial
	root.resized.connect(_sync_magic_size)
	_sync_magic_size()
	reveal_stinger.stream = _load_reveal_stinger()
	reveal_stinger.bus = &"SFX"


func _sync_magic_size() -> void:
	if _magic_material != null:
		_magic_material.set_shader_parameter("viewport_size", root.size)


func _set_magic_phase(phase: float) -> void:
	if _magic_material != null:
		_magic_material.set_shader_parameter("phase", phase)
	if _portrait_material != null:
		var reveal := smoothstep(0.55, 1.0, phase)
		_portrait_material.set_shader_parameter("silhouette_strength", 1.0 - reveal * 0.82)


func play_reveal(data: Dictionary) -> void:
	if _active:
		return

	_stage_id = String(data.get("stage_id", ""))
	header_label.text = "STAGE %02d · 침입자 발견" % maxi(_stage_id.trim_prefix("stage_").to_int(), 1)
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

	_active = true
	visible = true
	root.modulate = Color.WHITE
	_set_magic_phase(0.0)
	_magic_material.set_shader_parameter("fade", 1.0)
	effect_frame.visible = true
	hero_portrait.visible = true
	hero_portrait.scale = Vector2(0.84, 0.84)
	title_panel.visible = false
	title_label.modulate.a = 0.0
	true_name_label.modulate.a = 0.0
	loading_progress.visible = false
	loading_progress.value = 0.0
	name_divider.visible = false
	loading_text.visible = false
	if _portrait_material != null:
		_portrait_material.set_shader_parameter("silhouette_strength", 1.0)

	call_deferred("_run_sequence")


func _run_sequence() -> void:
	if reveal_stinger.stream != null:
		reveal_stinger.play()

	# Thirty authored timing steps, interpolated at the actual display rate.
	# No frame PNG swapping/decoding and no stretched low-resolution flash.
	_reveal_tween = create_tween()
	for index in range(EFFECT_FRAME_COUNT):
		_reveal_tween.tween_method(
			_set_magic_phase,
			float(index) / EFFECT_FRAME_COUNT,
			float(index + 1) / EFFECT_FRAME_COUNT,
			EFFECT_FRAME_SECONDS
		)
	await _reveal_tween.finished

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
	name_divider.visible = true
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
	tween.tween_method(
		func(value: float) -> void:
			_magic_material.set_shader_parameter("fade", value),
		1.0, 0.35, REVEAL_SECONDS
	)
	if _portrait_material != null:
		tween.tween_method(
			func(value: float) -> void:
				_portrait_material.set_shader_parameter(
					"silhouette_strength",
					value
				),
			0.18,
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
	loading_progress.visible = true
	loading_text.visible = true
	var total_steps := LOADING_FRAME_COUNT * LOADING_LOOPS
	for index in range(total_steps):
		if not _active:
			return
		var dot_count := (index % 3) + 1
		loading_text.text = "전투 준비 중%s" % ".".repeat(dot_count)
		loading_progress.value = float(index + 1) / float(total_steps) * 100.0
		await get_tree().create_timer(LOADING_FRAME_SECONDS).timeout


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
	var cached := PresentationWarmup.get_texture(path)
	if cached != null:
		return cached
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var resource = load(path)
	return resource as Texture2D if resource is Texture2D else null


func warm_render_resources(portrait_path: String) -> void:
	# Compile/render the real procedural and silhouette materials while covered.
	hero_portrait.texture = _load_texture(portrait_path)
	visible = true
	hero_portrait.visible = true
	effect_frame.visible = true
	name_divider.visible = false
	loading_text.visible = false
	loading_progress.visible = false
	title_panel.visible = false
	title_label.modulate.a = 0.0
	true_name_label.modulate.a = 0.0
	for phase in [0.0, 0.5, 1.0]:
		_set_magic_phase(phase)
		if DisplayServer.get_name() == "headless":
			await get_tree().process_frame
		else:
			await RenderingServer.frame_post_draw
	visible = false
	_set_magic_phase(0.0)


func _exit_tree() -> void:
	_active = false
	if _reveal_tween != null and _reveal_tween.is_valid():
		_reveal_tween.kill()
