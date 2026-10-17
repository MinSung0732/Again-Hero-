extends RefCounted
## Survival-only secondary hit. Per-actor scratch storage; bounded spatial query,
## no group scans, recursive proc chains, nodes or per-hit temporary containers.
const TARGETS := preload("res://src/systems/hero_target_policy.gd")
const HIT := preload("res://src/systems/monster_hit_context.gd")
var radius := 0.0
var ratio := 0.0
var limit := 0
var mode := ""
var scratch: Array = []
var flash_left := 0.0
var flash_origin := Vector2.ZERO
var flash_direction := Vector2.RIGHT
var striking := false

func configure(config: Dictionary) -> void:
	radius = maxf(0.0,float(config.get("summon_area_radius",0.0)))
	ratio = maxf(0.0,float(config.get("summon_area_ratio",0.0)))
	limit = clampi(int(config.get("summon_area_targets",0)),0,10)
	mode = String(config.get("summon_area_mode",""))

func copy_from(other: RefCounted) -> void:
	radius = other.radius; ratio = other.ratio; limit = other.limit; mode = other.mode
	flash_left = 0.0

func reset() -> void:
	radius = 0.0; ratio = 0.0; limit = 0; mode = ""
	flash_left = 0.0; scratch.clear()

func tick(delta: float) -> void:
	flash_left = maxf(0.0,flash_left-delta)

func strike(emitter: Node2D, primary_id: int, impact: Vector2, amount: int, kind: String, source: Node) -> int:
	if radius <= 0.0 or ratio <= 0.0 or limit <= 0 or striking: return 0
	var battle := emitter.get_parent()
	if not is_instance_valid(battle) or not battle.has_method("fill_monsters_near"): return 0
	striking = true
	flash_origin = emitter.global_position if mode == "whirl" else impact
	flash_direction = emitter.global_position.direction_to(impact)
	if flash_direction.is_zero_approx(): flash_direction = Vector2.RIGHT
	flash_left = .16
	battle.fill_monsters_near(flash_origin,radius,scratch)
	var count := 0
	for target in scratch:
		if not is_instance_valid(target) or target.get_instance_id() == primary_id or not TARGETS.is_detectable(target) or not target is Node2D: continue
		if (target.get("current_hp") != null and int(target.current_hp) <= 0) or bool(target.get("dying")): continue
		if target.has_method("is_combat_targetable") and not target.is_combat_targetable(): continue
		if target.global_position.distance_squared_to(flash_origin) > radius*radius: continue
		if mode == "cleave":
			var offset: Vector2 = target.global_position-emitter.global_position
			if not offset.is_zero_approx() and offset.normalized().dot(flash_direction) < .35: continue
		HIT.hit(target,maxi(1,roundi(amount*ratio)),kind,source)
		count += 1
		if count >= limit: break
	scratch.clear()
	striking = false
	emitter.queue_redraw()
	return count

func draw(canvas: Node2D) -> void:
	if flash_left <= 0.0 or radius <= 0.0: return
	var center := canvas.to_local(flash_origin)
	var fade := flash_left/.16
	var visual_radius := radius/maxf(absf(canvas.global_scale.x),.01)
	var start := flash_direction.angle()-acos(.35) if mode == "cleave" else 0.0
	var end := flash_direction.angle()+acos(.35) if mode == "cleave" else TAU
	canvas.draw_arc(center,visual_radius,start,end,32,Color(.65,.45,1.0,.75*fade),3.0)
	canvas.draw_arc(center,visual_radius*.72,start,end,24,Color(.85,.75,1.0,.5*fade),2.0)
