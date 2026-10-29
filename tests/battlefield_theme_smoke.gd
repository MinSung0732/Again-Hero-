extends SceneTree
const FIELD := preload("res://src/battle/stage1_battlefield.gd")
const THEMES := preload("res://src/data/battlefield_theme_catalog.gd")
const MAPS := preload("res://src/data/ranked_map_catalog.gd")
const CARPETS := preload("res://src/data/online_loading_catalog.gd").CARPETS

func check(ok: bool, message: String) -> void:
	if not ok: push_error(message); quit(1); assert(ok,message)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	for id in THEMES.ids():
		var theme: Dictionary = THEMES.get_theme(id)
		for key in theme.overrides:
			check(FIELD.TEXTURE_PATHS.has(key), "unknown override " + key)
			check(ResourceLoader.exists(theme.overrides[key]), "missing override " + theme.overrides[key])
	var field = FIELD.new(); root.add_child(field)
	field.configure("stage_1",Vector2(3200,3200))
	check(field.textures.size() == FIELD.TEXTURE_PATHS.size(), "castle texture keys")
	for key in FIELD.TEXTURE_PATHS:
		check(field.textures.has(key), "castle key " + key)
		if key in CARPETS:
			var original: Texture2D = load(FIELD.TEXTURE_PATHS[key])
			var image := original.get_image(); image.convert(Image.FORMAT_RGBA8)
			for y in image.get_height(): field._strip_carpet_row(image,y)
			check(field.textures[key].get_image().get_data() == image.get_data(), "castle carpet " + key)
		else: check(field.textures[key].resource_path == FIELD.TEXTURE_PATHS[key], "castle path " + key)
	for id in ["cursed_swamp", "sunlit_meadow"]:
		field.configure("stage_1",Vector2(3200,3200),id)
		check(field.textures.throne.resource_path == "res://assets/art/maps/" + id + "/centerpiece.png", "themed throne " + id)
		check(field.floor_damage_paths.is_empty(), "no floor damage " + id)
	field.configure("stage_1",Vector2(3200,3200),"invalid")
	check(field.theme_id == "castle" and field.textures.throne.resource_path == FIELD.TEXTURE_PATHS.throne, "invalid theme fallback")
	for entry in MAPS.all(): check(entry.theme in THEMES.ids(), "map theme " + entry.id)
	field.queue_free()
	print("PASS battlefield themes")
	quit()
