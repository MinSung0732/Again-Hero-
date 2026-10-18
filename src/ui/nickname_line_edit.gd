extends LineEdit
## Never rewrite text or force the caret to the end during IME composition.
const RULES := preload("res://src/data/nickname_catalog.gd")
var _previous := ""
var _navigation_revision := 0

func _ready() -> void:
	# A composing Korean syllable may temporarily exceed the final name length.
	# Validate committed text instead of truncating the platform IME buffer.
	max_length = 0
	text_direction = Control.TEXT_DIRECTION_LTR
	keep_editing_on_text_submit = true
	placeholder_text = "%d~%d글자" % [RULES.MIN_LENGTH, RULES.MAX_LENGTH]
	_previous = text
	text_changed.connect(_text_committed)
	gui_input.connect(_navigation_input)

func _navigation_input(event: InputEvent) -> void:
	if (event is InputEventKey and event.pressed and event.keycode in [KEY_LEFT, KEY_RIGHT, KEY_HOME, KEY_END]) or (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		_navigation_revision += 1

func _text_committed(value: String) -> void:
	var before := _previous
	_previous = value
	# Some PC IMEs leave the caret at the insertion anchor after committing.
	# Correct only that stale position; native typing/mid-text edits stay intact.
	if value.length() <= before.length(): return
	var prefix := 0
	while prefix < before.length() and before[prefix] == value[prefix]: prefix += 1
	var suffix := 0
	while suffix < before.length()-prefix and before[before.length()-1-suffix] == value[value.length()-1-suffix]: suffix += 1
	var end := value.length()-suffix
	_repair_committed_caret.call_deferred(value, prefix, end, _navigation_revision)

func _repair_committed_caret(value: String, start: int, end: int, revision: int) -> void:
	if revision == _navigation_revision and is_inside_tree() and not has_ime_text() and text == value and not has_selection() and caret_column == start:
		caret_column = end

func committed_name() -> String:
	# Check/confirm must include the final composing syllable on PC and mobile.
	apply_ime()
	return text

func set_generated_name(value: String) -> void:
	_navigation_revision += 1
	cancel_ime()
	text = value
	_previous = value
	caret_column = value.length()
	text_changed.emit(value)
