extends SceneTree
const FIELD := preload("res://src/battle/stage1_battlefield.gd")
const THEMES := preload("res://src/data/battlefield_theme_catalog.gd")
const MAPS := preload("res://src/data/ranked_map_catalog.gd")
const CARPETS := preload("res://src/data/online_loading_catalog.gd").CARPETS
const FOOTPRINTS := preload("res://src/data/prop_footprint_catalog.gd").FOOTPRINTS
const MEASURE := preload("res://tools/measure_prop_footprints.gd")

func check(ok: bool, message: String) -> void:
	if not ok: push_error(message); quit(1); assert(ok,message)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	for path in FOOTPRINTS:
		var image := Image.load_from_file(path)
		check(not image.is_empty() and MEASURE.measure(image) == FOOTPRINTS[path], "footprint measurement " + path)
	for id in THEMES.ids():
		var theme: Dictionary = THEMES.get_theme(id)
		for key in theme.overrides:
			check(FIELD.TEXTURE_PATHS.has(key), "unknown override " + key)
			check(ResourceLoader.exists(theme.overrides[key]), "missing override " + theme.overrides[key])
	var parent := Node2D.new(); root.add_child(parent)
	var field = FIELD.new(); parent.add_child(field)
	field.configure("stage_1",Vector2(3200,3200))
	check(field.depth_prop_roots.size() == 19 and field.collision_layer_root.get_child_count() == 20 and field.background_decor_layer.get_child_count() == 78, "castle baseline")
	check_solid_geometry(field, "castle")
	check_top_wall(field, "castle")
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
			check_top_wall(field, id)
			var actual := []
			var depth_index := 0
			var solids := 0
			for item in theme.layout:
				if item.key in ["swamp_thorn_bush", "swamp_bone_pile", "meadow_flower_patch", "crystal", "flag_a", "flag_b"]:
					check(item.kind != "solid", "low decoration collision " + id + " " + item.key)
				check(item.pos.x >= 0.0 and item.pos.x <= 1.0 and item.pos.y >= 0.0 and item.pos.y <= 1.0, "layout bounds " + id)
				for mirrored in range(2 if item.get("mirror", false) else 1):
					var pos: Vector2 = item.pos * size
					if mirrored == 1: pos.x = size - pos.x
					if item.kind == "solid":
						solids += 1
						check(item.collision.x <= field.textures[item.key].get_width() * item.scale * 0.6, "solid width " + id + " " + item.key)
						check(item.collision.y >= 30 and item.collision.y <= 45, "solid height " + id + " " + item.key)
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
			check_solid_geometry(field, id)
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

func check_top_wall(field, id: String) -> void:
	var bottom: float = FIELD.TOP_WALL_Y + field.textures.wall_large.get_height() * FIELD.PERIMETER_WALL_SCALE * 0.5
	check(is_equal_approx(field.get_top_wall_collision_bottom(), bottom), "wall image bottom " + id)
	var boundary: StaticBody2D = field.collision_layer_root.get_child(0)
	var shape: RectangleShape2D = boundary.get_child(0).shape
	check(boundary.collision_layer == FIELD.BOUNDARY_COLLISION_LAYER and is_equal_approx(boundary.position.y + shape.size.y * 0.5, bottom), "wall collision bottom " + id)

func check_solid_geometry(field, id: String) -> void:
	for body in field.collision_layer_root.get_children():
		if body.collision_layer != FIELD.DECOR_COLLISION_LAYER: continue
		var shape: RectangleShape2D = body.get_child(0).shape
		var ground: Vector2 = body.position + Vector2(0, shape.size.y * 0.5)
		var found := false
		for prop in field.depth_prop_roots:
			if not prop.position.is_equal_approx(ground): continue
			var sprite: Sprite2D = prop.get_child(0)
			var data: Dictionary = FOOTPRINTS.get(sprite.texture.resource_path, {})
			check(not data.is_empty(), "missing footprint " + id)
			var base: Rect2 = data.base
			var sx: float = sprite.scale.x
			var center: float = base.position.x + base.size.x * 0.5 - sprite.texture.get_width() * 0.5
			if sprite.flip_h: center = -center
			var base_center: float = prop.position.x + sprite.position.x + center * sx
			var bottom: float = prop.position.y + sprite.position.y + (base.end.y - sprite.texture.get_height() * 0.5) * sx
			check(absf(body.position.x - base_center) + shape.size.x * 0.5 <= base.size.x * sx * 0.5 + 0.01, "collision outside base " + id)
			check(absf(ground.y - bottom) <= 4.0, "collision bottom " + id)
			check(shape.size.y >= 28.0 and shape.size.y <= 40.0, "collision height " + id)
			found = true
			break
		check(found, "collision without prop " + id)
