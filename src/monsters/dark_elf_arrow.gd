extends Area2D
const CLOCK_DARK_ELF_ARROW = preload("res://src/systems/battle_clock.gd")
const DATA := preload("res://src/data/dark_elf_archer_behavior_catalog.gd")
const POOL_KEY := "dark_elf_arrow"
var life_revision := 0
var active := false
var impacting := false
var direction := Vector2.RIGHT
var speed := DATA.BASE.projectile_speed
var max_range := DATA.BASE.projectile_range
var traveled := 0.0
var damage := 1
var bypass_invulnerability := false
var source: WeakRef
var intended_target: WeakRef
@onready var visual = $Visual

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	visual.animation_finished.connect(_on_animation_finished)
	set_meta("combat_attack_type","ranged")
	deactivate_for_pool()

func setup(owner: Node,aim: Vector2,amount: int,range_limit: float,bypass: bool,target: Node = null) -> void:
	life_revision += 1
	source = weakref(owner)
	intended_target = weakref(target) if is_instance_valid(target) else null
	direction = aim.normalized() if aim.length_squared() > 0.001 else Vector2.RIGHT
	speed = DATA.BASE.projectile_speed
	max_range = range_limit
	damage = maxi(amount,1)
	bypass_invulnerability = bypass
	traveled = 0.0; active = true; impacting = false
	rotation = direction.angle()
	show(); set_deferred("monitoring",true); set_physics_process(true)
	add_to_group("monster_projectiles")
	visual.apply_visual_profile(DATA.ARROW_VISUAL)

func _physics_process(delta: float) -> void:
	delta = CLOCK_DARK_ELF_ARROW.scaled(self, delta)
	if not active or impacting: return
	var start := global_position
	var step := minf(speed*delta,maxf(max_range-traveled,0.0))
	global_position += direction*step
	traveled += step
	var target = intended_target.get_ref() if intended_target != null else null
	if is_instance_valid(target) and target is Node2D:
		var point := Geometry2D.get_closest_point_to_segment(target.global_position,start,global_position)
		if point.distance_squared_to(target.global_position) <= 24.0*24.0: _on_body_entered(target)
	if active and not impacting and traveled >= max_range: _finish()

func _on_body_entered(body: Node) -> void:
	if not active or impacting or not is_instance_valid(body) or body.is_queued_for_deletion(): return
	if not body.is_in_group("hero") and not body.is_in_group("hero_summons"): return
	impacting = true
	set_deferred("monitoring",false); set_physics_process(false)
	var owner = source.get_ref() if source != null else null
	var combat_source: Node = owner if is_instance_valid(owner) else self
	if bypass_invulnerability and body.has_method("take_followup_damage"):
		body.call("take_followup_damage",damage,combat_source)
	elif body.has_method("take_damage"):
		body.call("take_damage",damage,combat_source)
	visual.play(&"impact")

func _on_animation_finished() -> void:
	if active and impacting: call_deferred("_finish",life_revision)

func _finish(expected_revision: int = -1) -> void:
	if expected_revision >= 0 and expected_revision != life_revision: return
	if not active: return
	active = false
	set_deferred("monitoring",false); set_physics_process(false)
	var parent := get_parent()
	if is_instance_valid(parent) and parent.has_method("recycle_projectile"): parent.recycle_projectile(self,POOL_KEY)
	else: queue_free()

func deactivate_for_pool() -> void:
	life_revision += 1
	active = false; impacting = false; bypass_invulnerability = false
	source = null; intended_target = null; traveled = 0.0
	hide(); monitoring = false; set_physics_process(false)
	if is_instance_valid(visual): visual.stop()
	if is_in_group("monster_projectiles"): remove_from_group("monster_projectiles")
