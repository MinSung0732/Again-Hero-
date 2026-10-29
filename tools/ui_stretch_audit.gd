extends SceneTree

var rows := {}
var nodes_seen := 0
var scenes_seen := 0
var failures: Array[String] = []
var scene_label := ""

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var out := ""
	for i in range(args.size() - 1):
		if args[i] == "--out": out = args[i + 1]
	if out.is_empty() or not out.is_absolute_path():
		printerr("An absolute --out path is required")
		quit(1); return
	root.size = Vector2i(1080, 1920)
	var paths := ["res://src/lobby/Lobby.tscn", "res://src/main/Main.tscn", "res://src/hero_mode/HeroMode.tscn", "res://src/online/OnlineMatch.tscn|hero", "res://src/online/OnlineMatch.tscn|demon"]
	var dir := DirAccess.open("res://src/ui")
	if dir:
		dir.list_dir_begin()
		var name := dir.get_next()
		while not name.is_empty():
			if name.ends_with(".tscn"): paths.append("res://src/ui/" + name)
			name = dir.get_next()
	for entry in paths:
		var parts: PackedStringArray = entry.split("|")
		var packed = load(parts[0])
		if not packed is PackedScene or not packed.can_instantiate():
			failures.append(entry); continue
		if parts.size() > 1:
			root.get_node("SceneTransition").set("_entry_options", {"role": parts[1]})
		var instance = packed.instantiate()
		if instance == null:
			failures.append(entry); continue
		if parts[0].begins_with("res://src/ui/") and not instance is Control:
			instance.free(); continue
		scene_label = entry
		root.size = Vector2i(1080, 1920)
		root.add_child(instance)
		await process_frame
		await process_frame
		scenes_seen += 1
		walk(instance)
		instance.queue_free()
		await process_frame
	var file := FileAccess.open(out, FileAccess.WRITE)
	if file == null:
		printerr("Cannot write output: ", out, " error ", FileAccess.get_open_error()); quit(1); return
	file.store_line("texture\tproblem\tcount\tscenes_and_nodes\toriginal\tdisplay\tscale\tdistortion\t9slice\tmargins\tmode\tfilter")
	for key in rows:
		var row: Dictionary = rows[key]
		file.store_line("\t".join([row.texture, row.problem, str(row.count), row.locations, row.original, row.display, row.scale, row.distortion, row.slice, row.margins, row.mode, row.filter]))
	file.close()
	print("AUDIT scenes=", scenes_seen, " nodes=", nodes_seen, " grouped=", rows.size(), " flagged=", rows.values().filter(func(r): return r.problem != "").size())
	print("LOAD_FAILURES ", failures)
	quit()

func walk(node: Node) -> void:
	if node is Control:
		var c: Control = node
		var found := false
		if c is TextureRect and c.texture:
			found = true
			record(c, c.texture, "TextureRect:" + str(c.stretch_mode) + "/expand:" + str(c.expand_mode), c.stretch_mode == TextureRect.STRETCH_SCALE, [0,0,0,0])
		if c is NinePatchRect and c.texture:
			found = true
			record(c, c.texture, "NinePatchRect", true, [c.patch_margin_left,c.patch_margin_top,c.patch_margin_right,c.patch_margin_bottom], true)
		if c is TextureButton:
			for state in ["normal", "pressed", "hover", "disabled", "focused"]:
				var tex = c.get("texture_" + state)
				if tex:
					found = true
					record(c, tex, "TextureButton:" + state + "/stretch:" + str(c.stretch_mode), c.stretch_mode == TextureButton.STRETCH_SCALE, [0,0,0,0])
		if c is Button and c.icon:
			found = true
			record(c, c.icon, "Button.icon (control bounds)", false, [0,0,0,0])
		for style in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed", "panel", "read_only"]:
			if c.has_theme_stylebox(style):
				var box = c.get_theme_stylebox(style)
				if box is StyleBoxTexture and box.texture:
					found = true
					var margins = [box.texture_margin_left,box.texture_margin_top,box.texture_margin_right,box.texture_margin_bottom]
					record(c, box.texture, "style:" + style, true, margins, margins.max() > 0)
		if found: nodes_seen += 1
	for child in node.get_children(): walk(child)

func record(c: Control, tex: Texture2D, mode: String, ignores_aspect: bool, margins: Array, slice := false) -> void:
	var original := tex.get_size()
	var shown := c.get_global_rect().size
	if original.x <= 0 or original.y <= 0: return
	var sx := shown.x / original.x
	var sy := shown.y / original.y
	var distortion := absf(sx / sy - 1.0) if sy > 0 else 0.0
	var filter := c.texture_filter
	var parent := c.get_parent()
	while filter == CanvasItem.TEXTURE_FILTER_PARENT_NODE and parent is CanvasItem:
		filter = parent.texture_filter
		parent = parent.get_parent()
	var nearest := filter == CanvasItem.TEXTURE_FILTER_NEAREST or filter == CanvasItem.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	var issues: Array[String] = []
	if shown.x > 0 and shown.y > 0:
		if not slice and ignores_aspect and distortion > 0.05: issues.append("distortion")
		if not slice and maxf(sx,sy) > 2.0: issues.append("upscale")
		if nearest and (absf(sx-roundf(sx)) >= 0.1 or absf(sy-roundf(sy)) >= 0.1): issues.append("noninteger_nearest")
		if slice and (margins[0]+margins[2] > shown.x or margins[1]+margins[3] > shown.y): issues.append("margins_exceed")
	var path := tex.resource_path
	if path.is_empty(): path = "<embedded:" + tex.get_class() + ":" + str(tex.get_instance_id()) + ">"
	var problem := ",".join(issues)
	var key := path + "|" + problem
	var location := scene_label + ":" + str(c.get_path()) + " [" + mode + "]"
	if rows.has(key):
		rows[key].count += 1
		rows[key].locations += " ; " + location
		# Preserve all distinct measurements for asset sizing.
		var measurement := "%.2fx%.2f" % [shown.x, shown.y]
		if not rows[key].display.split(" ; ").has(measurement):
			rows[key].display += " ; " + measurement
			rows[key].scale += " ; " + ("%.3f,%.3f" % [sx,sy])
			rows[key].distortion += " ; " + ("%.3f" % distortion)
	else:
		rows[key] = {"texture":path, "problem":problem, "count":1, "locations":location, "original":"%.2fx%.2f" % [original.x,original.y], "display":"%.2fx%.2f" % [shown.x,shown.y], "scale":"%.3f,%.3f" % [sx,sy], "distortion":"%.3f" % distortion, "slice":str(slice), "margins":str(margins), "mode":mode, "filter":str(filter)}


