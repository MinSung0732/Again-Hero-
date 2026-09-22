extends Node

const GAME_FONT_PATH := "res://assets/fonts/Galmuri11.ttf"
const GAME_THEME_PATH := "res://src/ui/game_theme.tres"

var game_font: Font
var game_theme: Theme

func _ready() -> void:
	if not ResourceLoader.exists(GAME_FONT_PATH):
		push_warning("Game font not found: %s" % GAME_FONT_PATH)
		return

	game_font = load(GAME_FONT_PATH) as Font
	if game_font == null:
		push_warning("Game font failed to load: %s" % GAME_FONT_PATH)
		return

	if ResourceLoader.exists(GAME_THEME_PATH):
		game_theme = load(GAME_THEME_PATH) as Theme

	ThemeDB.fallback_font = game_font
	print("Game font file: %s" % GAME_FONT_PATH)
	print("Game font resource: %s" % game_font.resource_path)
	print(
		"Game theme: %s"
		% (
			game_theme.resource_path
			if game_theme != null
			else "<none>"
		)
	)

	get_tree().node_added.connect(_on_node_added)
	call_deferred("_apply_font_to_tree", get_tree().root)
	call_deferred("_debug_report_fonts")

func _on_node_added(node: Node) -> void:
	if node is Control:
		_apply_font_to_control(node as Control)

func _apply_font_to_tree(root: Node) -> void:
	if root == null:
		return

	if root is Control:
		_apply_font_to_control(root as Control)

	for child in root.get_children():
		_apply_font_to_tree(child)

func _debug_report_fonts() -> void:
	var checks := [
		{
			"label": "Lobby Title",
			"path": "/root/Lobby/SafeArea/Layout/Header/HeaderMargin/HeaderVBox/Title",
		},
		{
			"label": "Main Status",
			"path": "/root/Main/HUD/TopSafe/TopLayout/Status",
		},
	]

	for check in checks:
		var node := get_node_or_null(String(check.get("path", "")))
		if node == null or not (node is Control):
			print("%s font: <node not found>" % String(check.get("label", "UI")))
			continue

		var control := node as Control
		var resolved_font := control.get_theme_font("font")
		var resource_path := "<built-in>"
		if resolved_font != null and not resolved_font.resource_path.is_empty():
			resource_path = resolved_font.resource_path

		print(
			"%s font: %s"
			% [
				String(check.get("label", "UI")),
				resource_path,
			]
		)

func _apply_font_to_control(control: Control) -> void:
	if game_theme != null and control.theme == null:
		control.theme = game_theme

	if game_font != null:
		control.add_theme_font_override("font", game_font)
