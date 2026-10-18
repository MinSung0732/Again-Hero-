extends RefCounted
const DATA := preload("res://src/data/zeus_behavior_catalog.gd")
static var packs: Dictionary = {}

static func get_pack(kind: String) -> Dictionary:
	if packs.has(kind):
		return packs[kind]
	var spec: Dictionary = DATA.EFFECTS[kind]
	var frames: Array[Texture2D] = []
	var union := Rect2i()
	var canvas := Vector2.ZERO
	for index in range(int(spec.first), int(spec.last) + 1):
		var path := DATA.EFFECT_ROOT + "%s/%s_%02d.png" % [spec.folder,spec.prefix,index]
		var texture: Texture2D = load(path) as Texture2D if ResourceLoader.exists(path) else null
		var image := texture.get_image() if texture != null else null
		if image == null and FileAccess.file_exists(path):
			image = Image.load_from_file(path)
			if image != null and not image.is_empty(): texture = ImageTexture.create_from_image(image)
		if image == null or image.is_empty() or texture == null:
			continue
		if image.is_compressed() and image.decompress() != OK:
			continue
		var bounds := image.get_used_rect()
		union = bounds if union.size == Vector2i.ZERO else union.merge(bounds)
		canvas = Vector2(image.get_size())
		frames.append(texture)
	var scale_factor := float(spec.size) / maxf(float(maxi(union.size.x,union.size.y)),1.0)
	var anchor := Vector2(union.position) + Vector2(union.size) * 0.5
	if bool(spec.get("feet",false)):
		anchor.y = union.end.y
	var pack := {"frames":frames,"scale":scale_factor,"anchor":anchor,"canvas":canvas}
	packs[kind] = pack
	return pack

static func draw_frame(owner: Node2D, kind: String, index: int, point: Vector2, enlargement: float = 1.0, tint: Color = Color.WHITE) -> void:
	var pack := get_pack(kind)
	var frames: Array = pack.frames
	if frames.is_empty():
		return
	var factor := float(pack.scale) * enlargement
	owner.draw_texture_rect(frames[clampi(index,0,frames.size()-1)],Rect2(point - pack.anchor * factor,pack.canvas * factor),false,tint)
