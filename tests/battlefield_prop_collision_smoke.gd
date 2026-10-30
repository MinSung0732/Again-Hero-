extends SceneTree
const FIELD := preload("res://src/battle/stage1_battlefield.gd")
const THEMES := preload("res://src/data/battlefield_theme_catalog.gd")
func check(ok: bool, message: String) -> void:
	if not ok: push_error(message); quit(1); assert(ok, message)
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	var field = FIELD.new(); root.add_child(field)
	field.configure("stage_1", Vector2(3200, 3200), "castle")
	var castle_sizes := []
	for body in field.collision_layer_root.get_children():
		if body.collision_layer == FIELD.DECOR_COLLISION_LAYER:
			castle_sizes.append(body.get_child(0).shape.size)
	var widths := [250.516, 82.0, 82.0, 75.768, 75.768, 79.212, 79.212, 75.768, 75.768, 79.212, 79.212, 133.238, 133.238, 70.0, 70.0, 70.0, 70.0, 91.63, 91.63]
	check(castle_sizes.size() == widths.size(), "castle count")
	for i in widths.size(): check(castle_sizes[i].is_equal_approx(Vector2(widths[i], 40.0)), "castle collision size " + str(i))
	for id in THEMES.ids():
		var layout: Array = THEMES.get_theme(id).layout
		if layout.is_empty(): continue
		for map_size in [2560.0, 4000.0]:
			field.configure("stage_1", Vector2.ONE * map_size, id)
			var rectangles: Array[Rect2] = []
			var body_index := 1
			for item in layout:
				if item.kind != "solid": continue
				for mirrored in range(2 if item.get("mirror", false) else 1):
					var body: StaticBody2D = field.collision_layer_root.get_child(body_index); body_index += 1
					var shape: RectangleShape2D = body.get_child(0).shape
					var data: Dictionary = field._prop_footprint(item.key)
					check(data.has("contact"), "missing contact " + id + " " + item.key)
					var contact: Rect2 = data.contact
					var base: Rect2 = data.base
					var flip: bool = item.get("flip", false) != (mirrored == 1)
					var pos: Vector2 = item.pos * map_size
					if mirrored == 1: pos.x = map_size - pos.x
					var dx: float = (contact.get_center().x - base.get_center().x) * item.scale
					if flip: dx = -dx
					var expected_size: Vector2 = (contact.size * item.scale).max(FIELD.MIN_CONTACT_SIZE)
					var expected_center := pos + Vector2(dx, (contact.get_center().y - base.end.y) * item.scale)
					var rect := Rect2(body.position - shape.size * 0.5, shape.size)
					check(rect.position.x >= 0 and rect.end.x <= map_size and rect.position.y >= 0 and rect.end.y <= map_size, "map boundary " + id)
					for other in rectangles:
						check(not rect.grow(32.0).intersects(other.grow(32.0)), "blocked passage " + id)
					rectangles.append(rect)
					check(shape.size.is_equal_approx(expected_size), "size " + id + " " + item.key)
					check(body.position.is_equal_approx(expected_center), "center " + id + " " + item.key)
					if map_size == 2560.0 and mirrored == 0: print("COMPARE ", id, " ", item.key, " ", data.used.size.x * item.scale, " ", shape.size.x, " ", shape.size.y)
	field.queue_free(); print("PASS prop collision"); quit()
