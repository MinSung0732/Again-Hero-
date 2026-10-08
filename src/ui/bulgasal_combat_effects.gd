extends RefCounted
const DATA := preload("res://src/data/bulgasal_behavior_catalog.gd")
static var textures: Dictionary = {}
static var packs: Dictionary = {}
const SPECS := {
	"rock_pick":[1,1,9,120.0], "rock_fly":[1,10,15,120.0*DATA.ROCK_VISUAL_SCALE], "impact":[1,16,20,400.0],
	"burrow":[2,1,9,135.0], "emerge":[2,10,18,180.0],
	"leap":[3,1,7,180.0], "leap_impact":[3,8,9,250.0], "wave":[3,10,20,135.0],
	"retreat":[3,1,9,180.0], "pillar":[4,1,21,100.0*DATA.PILLAR_VISUAL_SCALE],
}

static func warm() -> void:
	for kind in SPECS:
		get_pack(kind)

static func get_pack(kind: String) -> Dictionary:
	if packs.has(kind):
		return packs[kind]
	var spec: Array = SPECS[kind]
	var anchor: Vector2 = DATA.EFFECT_ANCHORS[spec[0]]
	var frames: Array[Texture2D] = []
	var union := Rect2i()
	for index in range(spec[1], spec[2] + 1):
		var path := DATA.ROOT + "effect%d/effect_%02d.png" % [spec[0], index]
		if not textures.has(path):
			textures[path] = load(path) as Texture2D
		var texture: Texture2D = textures[path]
		if texture == null:
			push_error("Bulgasal effect missing: " + path)
			continue
		frames.append(texture)
		var bounds := texture.get_image().get_used_rect()
		if kind != "pillar" or index == 6:
			union = bounds if union.size == Vector2i.ZERO else union.merge(bounds)
	var factor := float(spec[3]) / maxf(float(union.size.x), 1.0)
	if kind == "rock_fly":
		# Fixed union center across all flight frames; rotation must not orbit a ground anchor.
		anchor = Vector2(union.position)+Vector2(union.size)*0.5
	packs[kind] = {"frames":frames,"scale":factor,"anchor":anchor}
	return packs[kind]

static func draw_frame(target: Node2D, kind: String, index: int, point: Vector2, rotation: float = 0.0) -> void:
	var pack := get_pack(kind)
	if pack.frames.is_empty():
		return
	var texture: Texture2D = pack.frames[clampi(index, 0, pack.frames.size()-1)]
	var factor := float(pack.scale)
	target.draw_set_transform(point, rotation, Vector2.ONE)
	target.draw_texture_rect(texture, Rect2(-pack.anchor*factor, texture.get_size()*factor), false)
	target.draw_set_transform(Vector2.ZERO)
