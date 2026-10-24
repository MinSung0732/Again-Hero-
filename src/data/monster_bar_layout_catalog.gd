extends RefCounted
## Solo status-bar anchors for monsters whose draw code uses literal Y positions.
const FIXED_Y := {
	"bat":-65.0,"bomb_rat":-48.0,"ghost":-56.0,"goblin":-58.0,
	"goblin_thrower":-54.0,"kobolt":-56.0,"orc":-59.0,"medusa":-59.0,
	"skeleton":-55.0,"skeleton_archer":-51.0,"slime":-44.0,"spider":-43.0,
}
const HEAD_OFFSETS := {
	"arthur":["head_y",-15.0],"bulgasal":["visual_head_y",-17.0],
	"izanami":["visual_head_y",-17.0],"manticore":["visual_head_y",-17.0],
	"shuten_doji":["head_y",-16.0],"zeus":["visual_head_y",-30.0],
}
const GAUGE_CAPACITIES := {
	"arthur":preload("res://src/data/arthur_behavior_catalog.gd").GAUGE_MAX,
	"bulgasal":preload("res://src/data/bulgasal_behavior_catalog.gd").GAUGE_MAX,
	"gumiho":preload("res://src/data/gumiho_behavior_catalog.gd").CHARM_STACKS,
}
static func y(actor: Node2D) -> float:
	var value = actor.get("status_bar_head_y")
	if value != null: return float(value)
	value = actor.get("status_bar_y")
	if value != null: return float(value)
	var id := String(actor.get("monster_type"))
	if FIXED_Y.has(id): return float(FIXED_Y[id])
	if HEAD_OFFSETS.has(id):
		var anchor: Array = HEAD_OFFSETS[id]
		return float(actor.get(anchor[0])) + float(anchor[1])
	if id == "dullahan":
		var visual := actor.get_node_or_null("Visual") as AnimatedSprite2D
		if visual != null and visual.sprite_frames != null and visual.sprite_frames.has_animation("idle"):
			var frame := visual.sprite_frames.get_frame_texture("idle",0)
			if frame != null: return -float(frame.get_height())*visual.scale.y*0.5-12.0
		return -127.0
	return -54.0
static func gauge_capacity(actor: Node2D) -> float:
	return float(GAUGE_CAPACITIES.get(String(actor.get("monster_type")),100.0))
