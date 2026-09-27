extends CanvasLayer
class_name StageIntroCutscene

signal finished(skipped: bool)

const ACTIVE_SCALE := Vector2(1.07, 1.07)
const INACTIVE_SCALE := Vector2(0.94, 0.94)
const ACTIVE_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const INACTIVE_COLOR := Color(0.26, 0.27, 0.32, 0.72)
const SPEAKER_TWEEN_SECONDS := 0.16

@onready var root: Control = $Root
@onready var location_label: Label = $Root/Location
@onready var demon_portrait: TextureRect = $Root/DemonPortrait
@onready var hero_portrait: TextureRect = $Root/HeroPortrait
@onready var demon_name: Label = $Root/DemonName
@onready var hero_name: Label = $Root/HeroName
@onready var dialogue_speaker: Label = $Root/DialoguePanel/Speaker
@onready var dialogue_text: Label = $Root/DialoguePanel/Text
@onready var next_hint: Label = $Root/DialoguePanel/NextHint
@onready var skip_button: Button = $Root/SkipButton

var _lines: Array = []
var _line_index: int = -1
var _hero_display_name: String = "용사"
var _active: bool = false
var _speaker_tween: Tween


func _ready() -> void:
	visible = false
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
	demon_name.text = "마왕"
	hero_name.text = _hero_display_name
	skip_button.visible = allow_skip
	skip_button.disabled = not allow_skip
	next_hint.text = "화면을 터치하여 계속  ▶"

	_line_index = 0
	_active = true
	visible = true
	_reset_portrait_state()
	call_deferred("_show_current_line")


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
	if speaker == "demon":
		dialogue_speaker.text = "마왕"
		_focus_speaker(true)
	else:
		dialogue_speaker.text = _hero_display_name
		_focus_speaker(false)


func _focus_speaker(demon_is_speaking: bool) -> void:
	if _speaker_tween != null and _speaker_tween.is_valid():
		_speaker_tween.kill()

	demon_portrait.pivot_offset = demon_portrait.size * 0.5
	hero_portrait.pivot_offset = hero_portrait.size * 0.5

	var demon_scale := ACTIVE_SCALE if demon_is_speaking else INACTIVE_SCALE
	var hero_scale := INACTIVE_SCALE if demon_is_speaking else ACTIVE_SCALE
	var demon_color := ACTIVE_COLOR if demon_is_speaking else INACTIVE_COLOR
	var hero_color := INACTIVE_COLOR if demon_is_speaking else ACTIVE_COLOR

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
		demon_name,
		"modulate",
		ACTIVE_COLOR if demon_is_speaking else INACTIVE_COLOR,
		SPEAKER_TWEEN_SECONDS
	)
	_speaker_tween.tween_property(
		hero_name,
		"modulate",
		INACTIVE_COLOR if demon_is_speaking else ACTIVE_COLOR,
		SPEAKER_TWEEN_SECONDS
	)


func _reset_portrait_state() -> void:
	demon_portrait.scale = Vector2.ONE
	hero_portrait.scale = Vector2.ONE
	demon_portrait.modulate = ACTIVE_COLOR
	hero_portrait.modulate = ACTIVE_COLOR
	demon_name.modulate = ACTIVE_COLOR
	hero_name.modulate = ACTIVE_COLOR


func _on_skip_pressed() -> void:
	if not _active or not skip_button.visible:
		return
	_finish(true)


func _finish(skipped: bool) -> void:
	if not _active:
		return
	_active = false
	if _speaker_tween != null and _speaker_tween.is_valid():
		_speaker_tween.kill()
	_speaker_tween = null
	visible = false
	finished.emit(skipped)
