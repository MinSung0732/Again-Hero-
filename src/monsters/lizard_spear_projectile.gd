extends Area2D
const CLOCK_LIZARD_SPEAR_PROJECTILE = preload("res://src/systems/battle_clock.gd")
const DATA := preload("res://src/data/lizardman_spearman_behavior_catalog.gd")
const POOL_KEY := "lizard_spear_projectile"
var life_revision := 0
var active := false
var direction := Vector2.RIGHT
var speed := 280.0
var max_range := 185.0
var traveled := 0.0
var damage := 1
var source: WeakRef
@onready var visual = $Visual

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	deactivate_for_pool()

func setup(owner: Node,aim: Vector2,amount: int,range_limit: float,elite: bool) -> void:
	life_revision += 1
	source = weakref(owner)
	direction = aim.normalized() if aim.length_squared() > 0.001 else Vector2.RIGHT
	speed = DATA.PROJECTILE_SPEED
	max_range = range_limit
	damage = amount
	traveled = 0.0
	active = true
	rotation = direction.angle()
	show()
	set_deferred("monitoring",true)
	set_physics_process(true)
	add_to_group("monster_projectiles")
	visual.apply_visual_profile(DATA.PROJECTILE_ELITE if elite else DATA.PROJECTILE_NORMAL)

func _physics_process(delta: float) -> void:
	delta = CLOCK_LIZARD_SPEAR_PROJECTILE.scaled(self, delta)
	if not active: return
	var step := minf(speed*delta,maxf(max_range-traveled,0.0))
	global_position += direction*step
	traveled += step
	if traveled >= max_range: _finish()

func _on_body_entered(body: Node) -> void:
	if not active or not is_instance_valid(body) or body.is_queued_for_deletion(): return
	if not body.is_in_group("hero") and not body.is_in_group("hero_summons"): return
	var revision := life_revision
	active = false
	var owner = source.get_ref() if source != null else null
	if body.has_method("take_damage"):
		var landed = body.call("take_damage",damage,owner)
		if landed != false and is_instance_valid(owner) and owner.has_method("on_spear_contact"):
			owner.on_spear_contact(body)
	call_deferred("_finish",revision)

func _finish(expected_revision: int = -1) -> void:
	if expected_revision >= 0 and expected_revision != life_revision: return
	active = false
	set_deferred("monitoring",false)
	set_physics_process(false)
	var parent := get_parent()
	if is_instance_valid(parent) and parent.has_method("recycle_projectile"):
		parent.recycle_projectile(self,POOL_KEY)
	else: queue_free()

func deactivate_for_pool() -> void:
	life_revision += 1
	active = false
	source = null
	traveled = 0.0
	hide()
	monitoring = false
	set_physics_process(false)
	if is_in_group("monster_projectiles"): remove_from_group("monster_projectiles")
