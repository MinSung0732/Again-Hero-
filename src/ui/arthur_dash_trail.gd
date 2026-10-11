extends Node2D
# Fixed draw slots share existing skill textures. No per-rush Sprite allocation.
const DATA := preload("res://src/data/arthur_behavior_catalog.gd")
var ages := PackedFloat32Array()
var poses: Array[Transform2D] = []
var textures: Array[Texture2D] = []
var next_slot := 0
var distance_to_next := 0.0
func _init() -> void:
	ages.resize(DATA.DASH_TRAIL_POOL)
	ages.fill(-1)
	poses.resize(DATA.DASH_TRAIL_POOL)
	textures.resize(DATA.DASH_TRAIL_POOL)
	top_level = true
	z_as_relative = false
	z_index = 1 # Arthur body z2 + visual z-1; inserted before the body.
	show_behind_parent = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
func begin(visual: AnimatedSprite2D) -> void:
	distance_to_next = DATA.DASH_TRAIL_SPACING
	_stamp(visual,Vector2.ZERO)
func advance_segment(visual: AnimatedSprite2D, previous: Vector2, current: Vector2) -> void:
	var length := previous.distance_to(current)
	if length <= 0.001: return
	var direction := (current-previous)/length
	var cursor := distance_to_next
	# Bound work even with a stalled/very long physics tick.
	var emitted := 0
	while cursor <= length and emitted < DATA.DASH_TRAIL_POOL:
		_stamp(visual,previous+direction*cursor-current)
		cursor += DATA.DASH_TRAIL_SPACING
		emitted += 1
	distance_to_next = cursor-length
	if distance_to_next <= 0: distance_to_next = DATA.DASH_TRAIL_SPACING-fposmod(length-cursor,DATA.DASH_TRAIL_SPACING)
func _stamp(visual: AnimatedSprite2D, displacement: Vector2) -> void:
	var pose := visual.global_transform
	pose.origin += displacement
	if visual.flip_h: pose.x = -pose.x
	if visual.flip_v: pose.y = -pose.y
	poses[next_slot] = pose
	textures[next_slot] = visual.sprite_frames.get_frame_texture(visual.animation,visual.frame)
	ages[next_slot] = 0
	next_slot = (next_slot+1)%DATA.DASH_TRAIL_POOL
	queue_redraw()
func tick(delta: float) -> void:
	var changed := false
	for i in range(ages.size()):
		if ages[i] < 0: continue
		ages[i] += delta
		if ages[i] >= DATA.DASH_TRAIL_LIFETIME:
			ages[i] = -1
			textures[i] = null
		changed = true
	if changed: queue_redraw()
func clear() -> void:
	ages.fill(-1)
	textures.fill(null)
	queue_redraw()
func _draw() -> void:
	for offset in range(ages.size()):
		var i := (next_slot+offset)%ages.size()
		if ages[i] < 0 or textures[i] == null: continue
		var alpha := DATA.DASH_TRAIL_ALPHA*(1.0-ages[i]/DATA.DASH_TRAIL_LIFETIME)
		draw_set_transform_matrix(poses[i])
		draw_texture(textures[i],-textures[i].get_size()*0.5,Color(0.8,0.9,1,alpha))
	draw_set_transform_matrix(Transform2D.IDENTITY)
