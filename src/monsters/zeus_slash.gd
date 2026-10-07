extends Node2D
const DATA := preload("res://src/data/zeus_behavior_catalog.gd")
const FX := preload("res://src/ui/zeus_combat_effects.gd")
var active := false
var source_ref: WeakRef
var target_ref: WeakRef
var direction := Vector2.RIGHT
var distance := 0.0
var age := 0.0
var damage := 0
var ignore_invulnerability := false
var has_hit := false
var history := PackedVector2Array()
var history_count := 0
var history_head := 0
var trail_clock := 0.0

func _ready() -> void:
	history.resize(18)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	deactivate_for_pool()

func setup(heading: Vector2, source: Node, target: Node) -> void:
	direction = heading if heading.length_squared() > 0.0 else Vector2.RIGHT
	source_ref = weakref(source)
	target_ref = weakref(target)
	damage = int(round(source.attack_damage*(DATA.SLASH_UPGRADED_DAMAGE if source.transcend_level >= 2 else DATA.SLASH_DAMAGE)))
	ignore_invulnerability = source.transcend_level >= 2
	distance = 0.0
	age = 0.0
	history_count = 0
	history_head = 0
	trail_clock = 0.0
	has_hit = false
	active = true
	show()
	add_to_group("monster_projectiles")
	set_physics_process(true)

func deactivate_for_pool() -> void:
	active = false
	source_ref = null
	target_ref = null
	hide()
	remove_from_group("monster_projectiles")
	set_physics_process(false)

func _physics_process(delta: float) -> void:
	if not active:
		return
	var battle := get_parent()
	if battle.battle_over or battle.external_pause or battle.demon_augment_selection_active:
		return
	var previous := global_position
	var step := minf(DATA.SLASH_SPEED*delta,DATA.SLASH_RANGE-distance)
	global_position += direction*step
	distance += step
	age += delta
	trail_clock += delta
	if trail_clock >= 0.025:
		trail_clock = 0.0
		history[history_head] = global_position
		history_head = (history_head+1)%history.size()
		history_count = mini(history_count+1,history.size())
	var target = target_ref.get_ref() if target_ref != null else null
	if not has_hit and is_instance_valid(target) and int(target.current_hp) > 0:
		var closest := Geometry2D.get_closest_point_to_segment(target.global_position,previous,global_position)
		if closest.distance_squared_to(target.global_position) <= DATA.SLASH_HIT_RADIUS*DATA.SLASH_HIT_RADIUS:
			has_hit = true
			var source = source_ref.get_ref() if source_ref != null else null
			var accepted: bool = target.take_followup_damage(damage,source) if ignore_invulnerability else target.take_damage(damage,source)
			if accepted and is_instance_valid(source):
				source.apply_paralysis_to(target,DATA.SLASH_PARALYSIS)
			elif accepted:
				target.apply_paralysis(DATA.SLASH_PARALYSIS,DATA.STATUS_SECONDS)
	if distance >= DATA.SLASH_RANGE:
		battle.recycle_projectile(self,"zeus_slash")
	else:
		queue_redraw()

func _draw() -> void:
	if not active:
		return
	var frame := mini(int(age*10),3) if age < 0.4 else (5+mini(int((distance-(DATA.SLASH_RANGE-130))/65),1) if distance > DATA.SLASH_RANGE-130 else 4)
	var rotation_angle := direction.angle()
	draw_set_transform(Vector2.ZERO,rotation_angle)
	for index in range(history_count):
		var slot := (history_head-history_count+index+history.size())%history.size()
		var point := (history[slot]-global_position).rotated(-rotation_angle)
		FX.draw_frame(self,"slash",4,point,1.0,Color(1,1,1,0.08+0.20*float(index)/maxf(history_count,1)))
	FX.draw_frame(self,"slash",frame,Vector2.ZERO)
	draw_set_transform(Vector2.ZERO)
