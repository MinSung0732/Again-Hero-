extends RefCounted
const DATA := preload("res://src/data/manticore_behavior_catalog.gd")
static var packs: Dictionary = {}

static func prepare(kind: int) -> void:
	if packs.has(kind):
		return
	var directory := DATA.ROOT+"/effect%d/"%(kind+1)
	var canvas: Vector2 = DATA.EFFECT_CANVASES[kind]
	var frames: Array[Texture2D] = []
	for index in range(1,int(DATA.EFFECT_COUNTS[kind])+1):
		var texture := load(directory+"effect_%02d.png"%index) as Texture2D
		if texture != null:
			frames.append(texture)
	packs[kind] = {"frames":frames,"canvas":canvas,"anchor":DATA.EFFECT_ANCHORS[kind],"scale":float(DATA.EFFECT_HEIGHTS[kind])/maxf(canvas.y,1.0)}

static func draw_frame(owner: Node2D, kind: int, index: int, point: Vector2, enlargement: float = 1.0) -> void:
	if not packs.has(kind):
		return
	var pack: Dictionary = packs[kind]
	var frames: Array = pack.frames
	if frames.is_empty():
		return
	var factor := float(pack.scale)*enlargement
	owner.draw_texture_rect(frames[clampi(index,0,frames.size()-1)],Rect2(point-pack.anchor*factor,pack.canvas*factor),false)

static func draw_oriented(owner: Node2D, kind: int, index: int, point: Vector2, angle: float, enlargement: float = 1.0) -> void:
	owner.draw_set_transform(point,angle,Vector2.ONE)
	draw_frame(owner,kind,index,Vector2.ZERO,enlargement)
	owner.draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)

static func draw_projectile(owner: Node2D, index: int, point: Vector2, angle: float, enlargement: float) -> void:
	if not packs.has(1): return
	var pack: Dictionary = packs[1]
	var factor := float(pack.scale)*enlargement
	# effect2 01/02 point right; center their luminous tip, not the smoke's ground anchor.
	owner.draw_set_transform(point,angle,Vector2.ONE)
	owner.draw_texture_rect(pack.frames[clampi(index,0,1)],Rect2(-DATA.METEOR_PROJECTILE_ANCHOR*factor,pack.canvas*factor),false)
	owner.draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
