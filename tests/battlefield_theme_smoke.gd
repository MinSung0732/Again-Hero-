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
	var parent := Node2D.new(); root.add_child(parent)
	var field = FIELD.new(); parent.add_child(field)
	field.configure("stage_1",Vector2(3200,3200))
	check(field.depth_prop_roots.size() == 19 and field.collision_layer_root.get_child_count() == 20 and field.background_decor_layer.get_child_count() == 78, "castle baseline")
	check(field.textures.size() == FIELD.TEXTURE_PATHS.size(), "castle texture keys")
	for key in FIELD.TEXTURE_PATHS:
		check(field.textures.has(key), "castle key " + key)
		if key in CARPETS:
			var original: Texture2D = load(FIELD.TEXTURE_PATHS[key])
			var image := original.get_image(); image.convert(Image.FORMAT_RGBA8)
			for y in image.get_height(): field._strip_carpet_row(image,y)
			check(field.textures[key].get_image().get_data() == image.get_data(), "castle carpet " + key)
		else: check(field.textures[key].resource_path == FIELD.TEXTURE_PATHS[key], "castle path " + key)
	var counts := []
	for id in ["cursed_swamp", "sunlit_meadow"]:
		var theme: Dictionary = THEMES.get_theme(id)
		for key in theme.extra_textures:
			check(ResourceLoader.exists(theme.extra_textures[key]), "missing extra " + key)
		var positions := []
		for size in [2560.0, 4000.0]:
			field.configure("stage_1", Vector2(size,size), id)
			var actual := []
			var depth_index := 0
			var solids := 0
			for item in theme.layout:
				check(item.pos.x >= 0.0 and item.pos.x <= 1.0 and item.pos.y >= 0.0 and item.pos.y <= 1.0, "layout bounds " + id)
				for mirrored in range(2 if item.get("mirror", false) else 1):
					var pos: Vector2 = item.pos * size
					if mirrored == 1: pos.x = size - pos.x
					if item.kind == "solid":
						solids += 1
						check(pos.distance_to(Vector2.ONE * size * 0.5) >= 300.0, "hero start blocked " + id)
					if item.kind == "ground":
						var found := false
						for sprite in field.background_decor_layer.get_children():
							if sprite.position.is_equal_approx(pos) and sprite.texture == field.textures[item.key]: found = true
						check(found, "missing ground " + id)
						actual.append(pos)
					else:
						var prop: Node2D = field.depth_prop_roots[depth_index]
						check(prop.position.is_equal_approx(pos), "prop position " + id)
						actual.append(prop.position)
						depth_index += 1
			check(field.depth_prop_roots.size() == depth_index and field.collision_layer_root.get_child_count() == solids + 1, "layout counts " + id)
			if positions.is_empty(): positions = actual
			else:
				for i in actual.size(): check(actual[i].is_equal_approx(positions[i] * (4000.0 / 2560.0)), "position scaling " + id)
		counts.append([field.depth_prop_roots.size(), field.collision_layer_root.get_child_count()])
		field.configure("stage_1",Vector2(3200,3200),id)
		check(field.textures.throne.resource_path == "res://assets/art/maps/" + id + "/centerpiece.png", "themed throne " + id)
		check(field.floor_damage_paths.is_empty(), "no floor damage " + id)
		field.render_only = true
		field.configure("stage_1",Vector2(3200,3200),id)
		check(field.collision_layer_root.get_child_count() == 0, "render only collisions " + id)
		field.render_only = false
	check(counts[0][0] != counts[1][0] and counts[0][1] != counts[1][1], "distinct themes")
	for count in counts: check(count[0] != 19 and count[1] != 20, "distinct castle")
	print("THEME COUNTS ", counts)
	field.configure("stage_1", Vector2(3200,3200), "castle")
	field.render_only = true
	field.configure("stage_1", Vector2(3200,3200), "castle")
	check(field.collision_layer_root.get_child_count() == 0, "render only castle collisions")
	field.render_only = false
	var loaded: bool = await field.configure_async("stage_1", Vector2(2560,2560), func(): return true, func(_progress): pass, "cursed_swamp")
	check(loaded and field.textures.has("swamp_dead_tree") and field.depth_prop_roots.size() == counts[0][0], "async themed layout")
	field.configure("stage_1",Vector2(3200,3200),"invalid")
	check(field.theme_id == "castle" and field.textures.throne.resource_path == FIELD.TEXTURE_PATHS.throne, "invalid theme fallback")
	for entry in MAPS.all(): check(entry.theme in THEMES.ids(), "map theme " + entry.id)
	parent.queue_free()
	print("PASS battlefield themes")
	quit()
