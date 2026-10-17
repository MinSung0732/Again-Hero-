extends Node2D
## Pooled, aim-at-cast projectile. Swept collision only against the intended life;
## no global groups, homing, room-crossing physics or per-frame allocations.
const HIT := preload("res://src/monsters/frontier_attack.gd")
const ART := preload("res://src/data/frontier_projectile_art_catalog.gd")
const POOL_KEY := "frontier_bolt"
var active := false
var direction := Vector2.RIGHT
var speed := 1.0
var max_range := 1.0
var traveled := 0.0
var damage := 1
var tint := Color.WHITE
var fire := false
var source: WeakRef
var intended: WeakRef
var authority: WeakRef
var target_handle := Vector3i.ZERO
var payload: Dictionary = {}
var action: RefCounted
var visual_frames: SpriteFrames
var visual_rect := Rect2()
var visual_clock := 0.0
var visual_frame := 0

func _ready() -> void:
	set_meta("combat_attack_type","ranged")
	deactivate_for_pool()

func setup(owner: Node2D, target: Node2D, aim: Vector2, amount: int, config: Dictionary, token: RefCounted) -> void:
	source = weakref(owner)
	intended = weakref(target)
	authority = weakref(owner.combat_authority) if is_instance_valid(owner.combat_authority) else null
	var battle = authority.get_ref() if authority != null else null
	target_handle = battle.get_battle_entity_handle(target) if is_instance_valid(battle) and battle.has_method("get_battle_entity_handle") else Vector3i.ZERO
	direction = aim.normalized() if aim.length_squared() > 0.001 else Vector2.RIGHT
	speed = maxf(float(config.get("projectile_speed",300.0)),1.0)
	max_range = maxf(float(config.get("projectile_range",400.0)),1.0)
	traveled = 0.0
	damage = maxi(amount,1)
	payload = config.duplicate(true)
	action = token
	tint = Color(String(config.get("color","ff8844")))
	fire = String(config.get("color","")) == "ff8844"
	# Content selects art; pooled bolts may change species on every acquisition.
	var profile: Dictionary = ART.PROFILES.get(String(config.get("projectile_art","")),{})
	visual_frames = profile.get("frames")
	visual_clock = 0.0
	visual_frame = 0
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if visual_frames != null:
		var texture := visual_frames.get_frame_texture(&"projectile",0)
		var size := texture.get_size()*float(profile.scale)
		visual_rect = Rect2(-size*0.5,size)
	rotation = direction.angle()
	active = true
	show()
	set_physics_process(true)
	queue_redraw()
	add_to_group("monster_projectiles")

func _physics_process(delta: float) -> void:
	if not active: return
	if visual_frames != null:
		visual_clock += delta
		var next_frame := int(visual_clock*visual_frames.get_animation_speed(&"projectile")) % visual_frames.get_frame_count(&"projectile")
		if next_frame != visual_frame:
			visual_frame = next_frame
			queue_redraw()
	var battle = authority.get_ref() if authority != null else null
	var target = intended.get_ref() if intended != null else null
	if target_handle != Vector3i.ZERO and (not is_instance_valid(battle) or battle.resolve_battle_entity(target_handle) != target):
		_finish()
		return
	var start := global_position
	var distance := minf(speed*delta,maxf(max_range-traveled,0.0))
	global_position += direction*distance
	traveled += distance
	if HIT.target_alive(target) and target is Node2D:
		var point := Geometry2D.get_closest_point_to_segment(target.global_position,start,global_position)
		if point.distance_squared_to(target.global_position) <= 24.0*24.0:
			var owner = source.get_ref() if source != null else null
			HIT.hit(target,damage,owner if is_instance_valid(owner) else self,payload,action)
			_finish()
			return
	if traveled >= max_range: _finish()

func _finish() -> void:
	if not active: return
	active = false
	var battle = authority.get_ref() if authority != null else null
	if is_instance_valid(battle) and battle.has_method("recycle_projectile"):
		battle.recycle_projectile(self,POOL_KEY)
	else: queue_free()

func deactivate_for_pool() -> void:
	active = false
	source = null
	intended = null
	authority = null
	target_handle = Vector3i.ZERO
	payload.clear()
	action = null
	visual_frames = null
	visual_rect = Rect2()
	visual_clock = 0.0
	visual_frame = 0
	hide()
	set_physics_process(false)
	if is_in_group("monster_projectiles"): remove_from_group("monster_projectiles")

func _draw() -> void:
	if not active: return
	if visual_frames != null:
		draw_texture_rect(visual_frames.get_frame_texture(&"projectile",visual_frame),visual_rect,false)
		return
	draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE*1.5)
	# Fail-soft fallback only for missing/unknown art profiles.
	if fire:
		draw_rect(Rect2(-18,-3,24,6),Color("963745"))
		draw_rect(Rect2(-10,-6,18,12),tint)
		draw_rect(Rect2(-3,-3,12,6),Color("fff0a0"))
	else:
		draw_rect(Rect2(-10,-3,20,6),tint)
		draw_rect(Rect2(-6,-7,12,14),tint.darkened(.3))
		draw_rect(Rect2(-3,-3,6,6),Color("f2c9ff"))
