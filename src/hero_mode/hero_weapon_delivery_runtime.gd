extends RefCounted
## 24 retained emitters: at most 3 per owned weapon. No Nodes or whole-world scans.
const RULES := preload("res://src/data/hero_weapon_delivery_catalog.gd")
const TARGETS := preload("res://src/systems/hero_target_policy.gd")
const LIMIT := 24
const WARNING := 0.6
var _runtime: WeakRef
var host:
	get: return _runtime.get_ref()
var slots: Array[Dictionary] = []
var scratch: Array = []
var clock := 0.0
func install(runtime) -> void:
	_runtime = weakref(runtime)
	for index in LIMIT:
		slots.append({"left":0.0,"mode":"","id":"","origin":Vector2.ZERO,"radius":0.0,"orbit_radius":0.0,"count":1,"tick":0.0,"interval":0.5,"damage":0,"rank":1,"data":{},"frames":[],"color":Color.WHITE,"warning":0.0,"age":0.0,"duration":1.0,"phase":0.0})
func cast(id: String,data: Dictionary,origin: Vector2,damage: int,reach: float,rank: int) -> bool:
	var rule := RULES.spec(id,data)
	if rule.is_empty(): return false
	var mode := String(rule.mode)
	var count := clampi(int(rule.get("count",1))+maxi(0,int(data.get("field_count",1))-1),1,3)
	if mode == "orbit": count = 1
	if mode == "sentry": count = clampi(int(rule.get("count",1))+int(data.get("bonus_hits",0))/3,1,2)
	# Refresh the existing weapon's emitters. Recasting never stacks indefinitely.
	for slot in slots:
		if slot.id == id: slot.left = 0.0
	var cooldown := maxf(0.25,float(data.cooldown)*float(data.cooldown_scale)*host.haste)
	var duration := clampf(maxf(float(rule.get("duration",3.5)),float(data.get("field_duration",0.0)))*host.duration_bonus,1.0,10.0)
	var interval := maxf(0.12,float(data.get("field_interval",rule.get("interval",0.55))))
	var budget_interval := float(rule.get("interval",0.55))
	if mode == "sentry":
		budget_interval = 0.75
		interval = maxf(0.2,0.75*host.haste)
	if mode == "orbit": duration = maxf(duration,cooldown+0.1)
	for index in count:
		var slot := _free()
		if slot.is_empty(): break
		slot.id = id; slot.mode = mode; slot.data = data; slot.rank = rank
		slot.left = duration; slot.duration = duration; slot.age = 0.0; slot.tick = 0.0
		slot.interval = interval; slot.warning = WARNING if mode == "random" else index*0.4 if mode == "trail" else 0.0
		slot.phase = TAU*index/count; slot.count = clampi(int(data.get("orbit_count",4)),2,10)
		slot.origin = origin
		slot.radius = clampf(reach*0.32,45.0,180.0)
		slot.orbit_radius = reach*float(data.get("orbit_ratio",0.7))
		if mode == "orbit": slot.radius = clampf(reach*0.17,30.0,65.0)
		if mode == "sentry":
			slot.origin = _clamp(origin+Vector2.from_angle(TAU*index/count)*90.0)
			slot.radius = minf(reach,750.0)
		elif mode == "random": slot.origin = _random_map_point(origin,reach,index,count)
		elif mode == "trail":
			var move: Vector2 = host.hero.player_move_input.normalized()
			if move.is_zero_approx(): move = Vector2.RIGHT.rotated(index*TAU/count)
			slot.origin = _clamp(origin-move*index*float(slot.radius)*1.1)
		# Nominal per-target budget per cast, shared across zones; orbit pays for contact gaps.
		var budget := float(rule.get("budget",2.0))
		slot.damage = maxi(1,roundi(damage*budget*budget_interval/(cooldown if mode == "orbit" else float(rule.get("duration",3.5))*count)))
		slot.frames = host.art.get(id,[]); slot.color = Color(String(data.color))
	host.hero.queue_redraw()
	return true
func _free() -> Dictionary:
	for slot in slots:
		if float(slot.left) <= 0.0: return slot
	return {}
func _clamp(point: Vector2) -> Vector2:
	if host.authority.has_method("_clamp_manual_spawn_position"): return host.authority._clamp_manual_spawn_position(point)
	return point
func _random_map_point(origin: Vector2,reach: float,index: int,count: int) -> Vector2:
	# Stratified sectors, fixed world positions. Never snap onto the nearest enemy.
	var bounds: Vector2 = host.authority.current_map_size
	var center := bounds*0.5
	var local_point := origin+Vector2.from_angle(TAU*(index+randf())/count)*randf_range(reach*0.35,reach*1.35)
	if index%2 == 0: local_point = Vector2(randf_range(70.0,maxf(70.0,bounds.x-70.0)),randf_range(70.0,maxf(70.0,bounds.y-70.0)))
	return _clamp(local_point if bounds.x > 0.0 else center)
func tick(delta: float) -> void:
	clock += delta
	for slot in slots:
		if float(slot.left) <= 0.0: continue
		host.hero.queue_redraw()
		slot.age = float(slot.age)+delta
		if float(slot.warning) > 0.0:
			if slot.mode == "trail": slot.origin = _clamp(host.hero.global_position)
			slot.warning = maxf(0.0,float(slot.warning)-delta); continue
		slot.left = maxf(0.0,float(slot.left)-delta)
		if float(slot.left) <= 0.0: continue
		var mode := String(slot.mode)
		if mode in ["orbit","aura"]: slot.origin = host.hero.global_position
		slot.tick = float(slot.tick)-delta
		if float(slot.tick) > 0.0: continue
		slot.tick = float(slot.interval)
		if mode == "orbit":
			for index in int(slot.count): host.hero._damage_treasure_chests(orbit_point(slot,index),float(slot.radius),int(slot.damage))
		elif mode != "sentry": host.hero._damage_treasure_chests(slot.origin,float(slot.radius),int(slot.damage))
		var query_radius := float(slot.orbit_radius)+float(slot.radius) if mode == "orbit" else float(slot.radius)
		host.hero._fill_monster_nodes_near(slot.origin,query_radius,scratch)
		var nearest: Node2D = null
		var distance := INF
		for raw in scratch:
			var actor := raw as Node2D
			if not TARGETS.is_detectable(actor): continue
			var offset: Vector2 = actor.global_position-Vector2(slot.origin)
			if offset.length_squared() > query_radius*query_radius: continue
			if mode == "sentry":
				if offset.length_squared() < distance: nearest = actor; distance = offset.length_squared()
				continue
			if mode == "orbit" and not orbit_contact(slot,actor.global_position): continue
			host._hit(actor,int(slot.damage),"field",int(slot.rank),slot.data)
		if mode == "sentry" and is_instance_valid(nearest):
			for extra in 1+mini(2,int(slot.data.get("extra_projectiles",0))):
				host._launch_projectile(nearest,slot.origin,int(slot.damage),int(slot.rank),slot.color,slot.data,float(extra)*0.08,false,float(slot.radius))
func orbit_point(slot: Dictionary,index: int) -> Vector2:
	return Vector2(slot.origin)+Vector2.from_angle(clock*float(slot.data.get("orbit_speed",2.4))+TAU*index/int(slot.count))*float(slot.orbit_radius)
func orbit_contact(slot: Dictionary,point: Vector2) -> bool:
	for index in int(slot.count):
		if orbit_point(slot,index).distance_squared_to(point) <= float(slot.radius)*float(slot.radius): return true
	return false
func draw() -> void:
	for slot in slots:
		if float(slot.left) <= 0.0: continue
		var color: Color = slot.color
		if float(slot.warning) > 0.0:
			host.hero.draw_arc(host.hero.to_local(slot.origin),float(slot.radius),0,TAU,32,Color(color,0.5),2.0)
			continue
		if slot.mode == "orbit":
			for index in int(slot.count): _draw(slot,orbit_point(slot,index),float(slot.radius))
		elif slot.mode == "sentry": _draw(slot,slot.origin,32.0)
		else: _draw(slot,slot.origin,float(slot.radius))
func _draw(slot: Dictionary,point: Vector2,radius: float) -> void:
	host._draw_area(host.hero.to_local(point),radius,slot.color,slot.frames,host._loop_progress(slot.frames,clock))
