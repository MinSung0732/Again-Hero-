extends CanvasLayer
class_name StageIntroCutscene

signal finished(skipped: bool)

const ACTIVE_SCALE := Vector2(1.025, 1.025)
const INACTIVE_SCALE := Vector2(0.965, 0.965)
const ACTIVE_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const INACTIVE_COLOR := Color(0.38, 0.40, 0.48, 0.68)
const ACTIVE_NAME_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const INACTIVE_NAME_COLOR := Color(0.45, 0.47, 0.54, 0.58)
const DEMON_SPEAKER_COLOR := Color(1.0, 0.80, 0.43, 1.0)
const HERO_SPEAKER_COLOR := Color(0.58, 0.82, 1.0, 1.0)
const DEMON_ACCENT_COLOR := Color(0.94, 0.57, 0.22, 0.95)
const HERO_ACCENT_COLOR := Color(0.30, 0.64, 1.0, 0.95)
const SPEAKER_TWEEN_SECONDS := 0.20
const TEXT_FADE_SECONDS := 0.10
const INTRO_FADE_SECONDS := 0.24
const DEMON_ACTIVE_SHIFT := Vector2(14.0, -6.0)
const DEMON_INACTIVE_SHIFT := Vector2(-4.0, 4.0)
const HERO_ACTIVE_SHIFT := Vector2(-14.0, -6.0)
const HERO_INACTIVE_SHIFT := Vector2(4.0, 4.0)

@onready var root: Control = $Root
@onready var location_label: Label = $Root/Location
@onready var demon_portrait: TextureRect = $Root/DemonPortrait
@onready var hero_portrait: TextureRect = $Root/HeroPortrait
@onready var demon_name_plate: Panel = $Root/DemonNamePlate
@onready var hero_name_plate: Panel = $Root/HeroNamePlate
@onready var demon_name: Label = $Root/DemonNamePlate/DemonName
@onready var hero_name: Label = $Root/HeroNamePlate/HeroName
@onready var dialogue_speaker: Label = $Root/DialoguePanel/Speaker
@onready var dialogue_text: Label = $Root/DialoguePanel/Text
@onready var speaker_accent: ColorRect = $Root/DialoguePanel/SpeakerAccent
@onready var next_hint: Label = $Root/DialoguePanel/NextHint
@onready var skip_button: Button = $Root/SkipButton

var _lines: Array = []
var _line_index: int = -1
var _hero_display_name: String = "용사"
var _active: bool = false
var _current_speaker: String = ""
var _speaker_tween: Tween
var _text_tween: Tween
var _intro_tween: Tween
var _demon_base_position: Vector2 = Vector2.ZERO
var _hero_base_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	visible = false
	_demon_base_position = demon_portrait.position
	_hero_base_position = hero_portrait.position
	root.gui_input.connect(_on_root_gui_input)
	skip_button.pressed.connect(_on_skip_pressed)


func play_dialogue(dialogue: Dictionary, allow_skip: bool) -> void:
	var raw_lines = dialogue.get("lines", [])
	_lines = raw_lines.duplicate(true) if raw_lines is Array else []
	if _lines.is_empty():
		finished.emit(false)
		return

	_hero_display_name = String(dialogue.get("hero_name", "용사"))
	location_label.text = String(dialogue.get("location", ""))
	var portrait_path := String(dialogue.get("hero_portrait_path", ""))
	var portrait_texture := _load_texture(portrait_path)
	if portrait_texture != null:
		hero_portrait.texture = portrait_texture
	demon_name.text = "마왕"
	hero_name.text = _hero_display_name
	skip_button.visible = allow_skip
	skip_button.disabled = not allow_skip
	next_hint.text = "화면을 터치하여 계속  ▶"

	_line_index = 0
	_current_speaker = ""
	_active = true
	visible = true
	_reset_portrait_state()
	_play_intro_fade()
	call_deferred("_show_current_line")


func _play_intro_fade() -> void:
	if _intro_tween != null and _intro_tween.is_valid():
		_intro_tween.kill()

	root.modulate = Color(1.0, 1.0, 1.0, 0.0)
	demon_portrait.position = _demon_base_position + Vector2(-12.0, 8.0)
	hero_portrait.position = _hero_base_position + Vector2(12.0, 8.0)

	_intro_tween = create_tween()
	_intro_tween.set_parallel(true)
	_intro_tween.set_trans(Tween.TRANS_QUAD)
	_intro_tween.set_ease(Tween.EASE_OUT)
	_intro_tween.tween_property(
		root,
		"modulate:a",
		1.0,
		INTRO_FADE_SECONDS
	)


func _on_root_gui_input(event: InputEvent) -> void:
	if not _active:
		return

	var advance := false
	if event is InputEventScreenTouch:
		advance = (event as InputEventScreenTouch).pressed
	elif event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		advance = (
			mouse_event.pressed
			and mouse_event.button_index == MOUSE_BUTTON_LEFT
		)

	if not advance:
		return

	_advance()
	root.accept_event()


func _unhandled_key_input(event: InputEvent) -> void:
	if not _active or not event.is_pressed():
		return
	if event.is_action("ui_accept"):
		_advance()
		get_viewport().set_input_as_handled()


func _advance() -> void:
	_line_index += 1
	if _line_index >= _lines.size():
		_finish(false)
		return
	_show_current_line()


func _show_current_line() -> void:
	if not _active:
		return
	if _line_index < 0 or _line_index >= _lines.size():
		return

	var line = _lines[_line_index]
	if typeof(line) != TYPE_DICTIONARY:
		_advance()
		return

	var entry: Dictionary = line
	var speaker := String(entry.get("speaker", "hero"))
	dialogue_text.text = String(entry.get("text", ""))
	_animate_dialogue_text()

	if speaker == "demon":
		dialogue_speaker.text = "마왕"
		dialogue_speaker.add_theme_color_override(
			"font_color",
			DEMON_SPEAKER_COLOR
		)
		speaker_accent.color = DEMON_ACCENT_COLOR
	elif speaker == "narration":
		dialogue_speaker.text = ""
		dialogue_speaker.add_theme_color_override(
			"font_color",
			Color(0.78, 0.80, 0.86, 0.90)
		)
		speaker_accent.color = Color(0.42, 0.44, 0.52, 0.55)
	else:
		dialogue_speaker.text = _hero_display_name
		dialogue_speaker.add_theme_color_override(
			"font_color",
			HERO_SPEAKER_COLOR
		)
		speaker_accent.color = HERO_ACCENT_COLOR

	# Consecutive lines from the same speaker should feel like one continuous
	# conversation beat instead of repeatedly zooming in and out.
	if speaker != _current_speaker:
		_current_speaker = speaker
		if speaker == "narration":
			_focus_narration()
		else:
			_focus_speaker(speaker == "demon")


func _animate_dialogue_text() -> void:
	if _text_tween != null and _text_tween.is_valid():
		_text_tween.kill()

	dialogue_text.modulate = Color(1.0, 1.0, 1.0, 0.34)
	_text_tween = create_tween()
	_text_tween.set_trans(Tween.TRANS_QUAD)
	_text_tween.set_ease(Tween.EASE_OUT)
	_text_tween.tween_property(
		dialogue_text,
		"modulate:a",
		1.0,
		TEXT_FADE_SECONDS
	)


func _focus_speaker(demon_is_speaking: bool) -> void:
	if _speaker_tween != null and _speaker_tween.is_valid():
		_speaker_tween.kill()

	demon_portrait.pivot_offset = demon_portrait.size * 0.5
	hero_portrait.pivot_offset = hero_portrait.size * 0.5

	var demon_scale := ACTIVE_SCALE if demon_is_speaking else INACTIVE_SCALE
	var hero_scale := INACTIVE_SCALE if demon_is_speaking else ACTIVE_SCALE
	var demon_color := ACTIVE_COLOR if demon_is_speaking else INACTIVE_COLOR
	var hero_color := INACTIVE_COLOR if demon_is_speaking else ACTIVE_COLOR
	var demon_position := _demon_base_position + (
		DEMON_ACTIVE_SHIFT if demon_is_speaking else DEMON_INACTIVE_SHIFT
	)
	var hero_position := _hero_base_position + (
		HERO_INACTIVE_SHIFT if demon_is_speaking else HERO_ACTIVE_SHIFT
	)

	demon_portrait.z_index = 5 if demon_is_speaking else 3
	hero_portrait.z_index = 3 if demon_is_speaking else 5

	_speaker_tween = create_tween()
	_speaker_tween.set_parallel(true)
	_speaker_tween.set_trans(Tween.TRANS_QUAD)
	_speaker_tween.set_ease(Tween.EASE_OUT)
	_speaker_tween.tween_property(
		demon_portrait,
		"scale",
		demon_scale,
		SPEAKER_TWEEN_SECONDS
	)
	_speaker_tween.tween_property(
		hero_portrait,
		"scale",
		hero_scale,
		SPEAKER_TWEEN_SECONDS
	)
	_speaker_tween.tween_property(
		demon_portrait,
		"position",
		demon_position,
		SPEAKER_TWEEN_SECONDS
	)
	_speaker_tween.tween_property(
		hero_portrait,
		"position",
		hero_position,
		SPEAKER_TWEEN_SECONDS
	)
	_speaker_tween.tween_property(
		demon_portrait,
		"modulate",
		demon_color,
		SPEAKER_TWEEN_SECONDS
	)
	_speaker_tween.tween_property(
		hero_portrait,
		"modulate",
		hero_color,
		SPEAKER_TWEEN_SECONDS
	)
	_speaker_tween.tween_property(
		demon_name_plate,
		"modulate",
		ACTIVE_NAME_COLOR if demon_is_speaking else INACTIVE_NAME_COLOR,
		SPEAKER_TWEEN_SECONDS
	)
	_speaker_tween.tween_property(
		hero_name_plate,
		"modulate",
		INACTIVE_NAME_COLOR if demon_is_speaking else ACTIVE_NAME_COLOR,
		SPEAKER_TWEEN_SECONDS
	)


func _focus_narration() -> void:
	if _speaker_tween != null and _speaker_tween.is_valid():
		_speaker_tween.kill()

	demon_portrait.pivot_offset = demon_portrait.size * 0.5
	hero_portrait.pivot_offset = hero_portrait.size * 0.5
	_speaker_tween = create_tween()
	_speaker_tween.set_parallel(true)
	_speaker_tween.set_trans(Tween.TRANS_QUAD)
	_speaker_tween.set_ease(Tween.EASE_OUT)
	_speaker_tween.tween_property(
		demon_portrait,
		"scale",
		INACTIVE_SCALE,
		SPEAKER_TWEEN_SECONDS
	)
	_speaker_tween.tween_property(
		hero_portrait,
		"scale",
		INACTIVE_SCALE,
		SPEAKER_TWEEN_SECONDS
	)
	_speaker_tween.tween_property(
		demon_portrait,
		"modulate",
		INACTIVE_COLOR,
		SPEAKER_TWEEN_SECONDS
	)
	_speaker_tween.tween_property(
		hero_portrait,
		"modulate",
		INACTIVE_COLOR,
		SPEAKER_TWEEN_SECONDS
	)
	_speaker_tween.tween_property(
		demon_name_plate,
		"modulate",
		INACTIVE_NAME_COLOR,
		SPEAKER_TWEEN_SECONDS
	)
	_speaker_tween.tween_property(
		hero_name_plate,
		"modulate",
		INACTIVE_NAME_COLOR,
		SPEAKER_TWEEN_SECONDS
	)


func _reset_portrait_state() -> void:
	demon_portrait.scale = Vector2.ONE
	hero_portrait.scale = Vector2.ONE
	demon_portrait.position = _demon_base_position
	hero_portrait.position = _hero_base_position
	demon_portrait.modulate = ACTIVE_COLOR
	hero_portrait.modulate = ACTIVE_COLOR
	demon_name_plate.modulate = ACTIVE_NAME_COLOR
	hero_name_plate.modulate = ACTIVE_NAME_COLOR
	dialogue_text.modulate = ACTIVE_COLOR


func _on_skip_pressed() -> void:
	if not _active or not skip_button.visible:
		return
	_finish(true)


func _finish(skipped: bool) -> void:
	if not _active:
		return
	_active = false

	for tween in [_speaker_tween, _text_tween, _intro_tween]:
		if tween != null and tween.is_valid():
			tween.kill()

	_speaker_tween = null
	_text_tween = null
	_intro_tween = null
	visible = false
	finished.emit(skipped)


func _load_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var resource = load(path)
	return resource as Texture2D if resource is Texture2D else null
