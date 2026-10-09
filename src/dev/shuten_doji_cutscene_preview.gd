extends Control

const OVERLAY := preload("res://src/ui/gacha_reveal_overlay.gd")
const PLAYER := preload("res://src/ui/transcendent_cutscene_player.gd")
var _overlay
var _player

func _ready() -> void:
	theme = Theme.new()
	theme.default_font = load("res://assets/fonts/Galmuri11.ttf")
	# Standalone F6 scene: synthetic display results, never calls draw/award/save APIs.
	_overlay = OVERLAY.new()
	add_child(_overlay)
	_player = PLAYER.new()
	add_child(_player)
	var menu := VBoxContainer.new()
	menu.position = Vector2(30, 30)
	add_child(menu)
	for option in ["슈텐-도지 컷신만 미리보기", "1회 결과 연결", "10+1회 · 슈텐-도지 3개 결과 연결"]:
		var button := Button.new()
		button.text = option
		button.custom_minimum_size = Vector2(470, 72)
		menu.add_child(button)
		button.pressed.connect(_preview.bind(menu.get_child_count() - 1))
	_player.finished.connect(func(): print("shuten_doji preview completed; no rewards written"))

func _preview(mode: int) -> void:
	if mode == 0:
		_player.play("shuten_doji")
		return
	_overlay.present(sample_results(mode == 2))

static func sample_results(multi: bool) -> Array:
	var results: Array = []
	for index in range(11 if multi else 1):
		var shuten_doji := not multi or index in [1, 5, 9]
		var path := "res://assets/art/Transcendent_monster/Shuten-doji/frames/idle_01.png" if shuten_doji else ""
		results.append({
			"monster_id": "shuten_doji" if shuten_doji else "slime",
			"name": "슈텐-도지" if shuten_doji else "슬라임",
			"rarity": "transcendent" if shuten_doji else "common",
			"shards": 1, "icon": _preview_icon(path),
		})
	return results

static func _preview_icon(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		var texture := load(path) as Texture2D
		if texture != null:
			return texture
	if FileAccess.file_exists(path):
		var image := Image.load_from_file(path)
		if image != null and not image.is_empty():
			return ImageTexture.create_from_image(image)
	return null
