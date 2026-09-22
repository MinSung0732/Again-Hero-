extends Node

const GAME_FONT_PATH := "res://assets/fonts/Galmuri11.ttf"

var game_font: Font

func _ready() -> void:
	if not ResourceLoader.exists(GAME_FONT_PATH):
		push_warning(
			"Game font not found: %s" % GAME_FONT_PATH
		)
		return

	game_font = load(GAME_FONT_PATH) as Font
	if game_font == null:
		push_warning(
			"Game font failed to load: %s" % GAME_FONT_PATH
		)
		return

	ThemeDB.fallback_font = game_font
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_apply_font_to_tree", get_tree().root)

func _on_node_added(node: Node) -> void:
	if game_font == null:
		return
	if node is Control:
		_apply_font_to_control(node as Control)

func _apply_font_to_tree(root: Node) -> void:
	if game_font == null or root == null:
		return

	if root is Control:
		_apply_font_to_control(root as Control)

	for child in root.get_children():
		_apply_font_to_tree(child)

func _apply_font_to_control(control: Control) -> void:
	control.add_theme_font_override("font", game_font)
