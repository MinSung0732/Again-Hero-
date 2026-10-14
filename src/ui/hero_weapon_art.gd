extends RefCounted
# Load the selected kit effect sequences once; drawing never reads the disk.
const LAYOUTS := preload("res://src/data/hero_effect_layout_catalog.gd")
static var cache: Dictionary = {}
static func sequence(directory: String) -> Array[Texture2D]:
	if cache.has(directory): return cache[directory]
	var result: Array[Texture2D] = []
	var tree := Engine.get_main_loop() as SceneTree
	var warmup := tree.root.get_node_or_null("PresentationWarmup") if tree != null else null
	if directory.is_empty() or not DirAccess.dir_exists_absolute(directory):
		cache[directory] = result; return result
	var files: PackedStringArray = []
	if LAYOUTS.REGIONS.has(directory):
		for index in range(1, LAYOUTS.FRAME_COUNT+1): files.append("effect_%02d.png" % index)
	else:
		files = DirAccess.get_files_at(directory)
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
	if LAYOUTS.REGIONS.has(directory):
		result = _apply_region(result, LAYOUTS.REGIONS[directory])
	else:
		result = _trim_common_margin(result)
	cache[directory] = result
	return result

static func _trim_common_margin(frames: Array[Texture2D]) -> Array[Texture2D]:
	if frames.is_empty(): return frames
	var dimensions := frames[0].get_size()
	var center := dimensions*0.5
	var extent := 0.0
	for texture in frames:
		if texture.get_size() != dimensions: return frames
		var bitmap := texture.get_image()
		if bitmap == null or bitmap.is_empty(): return frames
		var bounds := Rect2(bitmap.get_used_rect())
		if not bounds.has_area(): continue
		extent = maxf(extent,maxf(maxf(absf(bounds.position.x-center.x),absf(bounds.end.x-center.x)),maxf(absf(bounds.position.y-center.y),absf(bounds.end.y-center.y))))
	# One symmetric crop for the whole animation: retain authored center, phases
	# and two transparent pixels. Never resize or center each frame separately.
	extent = minf(ceilf(extent)+2.0,minf(center.x,center.y))
	if extent <= 2.0 or extent*2 >= minf(dimensions.x,dimensions.y): return frames
	var region := Rect2(center-Vector2.ONE*extent,Vector2.ONE*extent*2)
	var result: Array[Texture2D] = []
	for texture in frames:
		var atlas := AtlasTexture.new(); atlas.atlas = texture; atlas.region = region; atlas.filter_clip = true
		result.append(atlas)
	return result

static func _apply_region(frames: Array[Texture2D], region: Rect2) -> Array[Texture2D]:
	if region == Rect2(0,0,128,128): return frames
	var result: Array[Texture2D] = []
	for texture in frames:
		var atlas := AtlasTexture.new(); atlas.atlas = texture; atlas.region = region; atlas.filter_clip = true
		result.append(atlas)
	return result

static func retain_sequences(directories: Dictionary) -> void:
	# Entry-only eviction. Live actors keep their own frame references.
	for directory in cache.keys():
		if not directories.has(directory): cache.erase(directory)
