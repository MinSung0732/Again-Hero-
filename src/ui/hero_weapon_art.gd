extends RefCounted
# Load six equipped-kit effect sequences once; drawing never reads the disk.
static var cache: Dictionary = {}
static func sequence(directory: String) -> Array[Texture2D]:
	if cache.has(directory): return cache[directory]
	var result: Array[Texture2D] = []
	var tree := Engine.get_main_loop() as SceneTree
	var warmup := tree.root.get_node_or_null("PresentationWarmup") if tree != null else null
	var files := DirAccess.get_files_at(directory)
	files.sort()
	for file in files:
		var name := String(file).trim_suffix(".remap")
		if not name.ends_with(".png"): continue
		var path := directory+"/"+name
		var texture: Texture2D = warmup.get_texture(path) if warmup != null else null
		if texture == null:
			if ResourceLoader.exists(path): texture = load(path) as Texture2D
			else:
				var bitmap := Image.load_from_file(path)
				if bitmap != null and not bitmap.is_empty(): texture = ImageTexture.create_from_image(bitmap)
		if texture != null: result.append(texture)
	cache[directory] = result
	return result
