extends RefCounted
## 24 retained emitters: at most 3 per owned weapon. No Nodes or whole-world scans.
const RULES := preload("res://src/data/hero_weapon_delivery_catalog.gd")
const TARGETS := preload("res://src/systems/hero_target_policy.gd")
const GEOMETRY := preload("res://src/hero_mode/hero_weapon_geometry.gd")
const LIMIT := 24
const VISUAL_COUNT := 10
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
		var visual_ids: Array[int] = []
		visual_ids.resize(VISUAL_COUNT * 2)
		slots.append({"left":0.0,"mode":"","id":"","origin":Vector2.ZERO,"radius":0.0,"orbit_radius":0.0,"count":1,"tick":0.0,"interval":0.5,"damage":0,"rank":1,"data":{},"frames":[],"color":Color.WHITE,"warning":0.0,"age":0.0,"duration":1.0,"phase":0.0,"detonated":false,"evolution_damage":0,"relay_phase":0,"max_kind":"","orbit_shape":"","gen":0,"visual_ids":visual_ids,"visual_index":0})
func cast(id: String,data: Dictionary,origin: Vector2,damage: int,reach: float,rank: int,target: Node2D = null) -> bool:
	var rule := RULES.spec(id,data)
	if rule.is_empty(): return false
	var mode := String(rule.mode)
	var count := clampi(int(rule.get("count",1))+maxi(0,int(data.get("field_count",1))-1),1,3)
	if mode == "orbit": count = 1
	if mode == "sentry": count = clampi(int(rule.get("count",1))+int(data.get("bonus_hits",0))/3,1,2)
	# Refresh the existing weapon's emitters. Recasting never stacks indefinitely.
	for slot in slots:
		if slot.id == id:
			if float(slot.left) > 0 and ((slot.max_kind == "detonating_trail" and float(slot.age) >= .65) or (slot.max_kind == "reactive_zone" and float(slot.warning) <= 0)): _detonate(slot)
			slot.left = 0.0
	var cooldown := maxf(0.25,float(data.cooldown)*float(data.cooldown_scale)*host.haste)
	var duration := clampf(maxf(float(rule.get("duration",3.5))*host.duration_bonus,float(data.get("field_duration",0.0))),1.0,10.0)
	var interval := maxf(0.12,float(data.get("field_interval",rule.get("interval",0.55))))
	var budget_interval := float(rule.get("interval",0.55))
	if mode == "sentry":
		budget_interval = 0.75
		interval = maxf(0.2,0.75*host.haste)
	if mode == "orbit": duration = maxf(duration,cooldown+0.1)
	# Thrown emitters gain one landing per extra projectile on the next distinct enemies;
	# the per-landing budget stays the base share, so multishot adds damage like other shots.
	var extras := mini(2,int(data.get("extra_projectiles",0))) if bool(rule.get("thrown",false)) else 0
	if extras > 0: host.pick_extra_targets(origin,reach,target,extras)
	for index in count+extras:
		if index >= count:
			var extra: int = index-count
			target = host.extra_targets[extra] if extra < host.extra_targets.size() else target
		var slot := _free()
		if slot.is_empty(): break
		host._activate_visual(slot)
		slot.visual_index = 0
		for visual_index in VISUAL_COUNT * 2:
			host.visual_generation += 1
			slot.visual_ids[visual_index] = host.visual_generation
		slot.id = id; slot.mode = mode; slot.data = data; slot.rank = rank
		slot.left = duration; slot.duration = duration; slot.age = 0.0; slot.tick = 0.0
		slot.interval = interval; slot.warning = float(rule.get("duration",1.0)) if mode == "bombard" else WARNING+index*0.18 if mode == "fault" else WARNING if mode in ["random","sigil"] else index*0.4 if mode == "trail" else 0.0
		if mode in ["lob","lob_burst"]: slot.warning = .7
		slot["launch"] = origin; slot["landing"] = _clamp(target.global_position if TARGETS.is_detectable(target) else origin)
		if index >= count and (index-count >= host.extra_targets.size()):
			slot.landing = _clamp(Vector2(slot.landing)+Vector2.RIGHT.rotated(TAU*float(index-count+1)/float(extras+1))*clampf(reach*0.32,45.0,180.0))
		slot.phase = TAU*index/count; slot.count = clampi(int(data.get("orbit_count",4)),2,10)
		slot.origin = origin
		slot.radius = clampf(reach*0.32,45.0,180.0)
		slot.orbit_radius = reach*float(data.get("orbit_ratio",0.7))
		if mode == "orbit": slot.radius = clampf(reach*0.17,30.0,65.0)
		if mode == "sentry":
			slot.origin = _clamp(origin+Vector2.from_angle(TAU*index/count)*90.0)
			slot.radius = minf(reach,750.0)
		elif mode == "random": slot.origin = _random_map_point(origin,reach,index,count)
		elif mode in ["sigil","bombard"]: slot.origin = Vector2(slot.landing) if index >= count else _clamp(target.global_position if TARGETS.is_detectable(target) else origin)
		elif mode == "fault":
			var aim := origin.direction_to(target.global_position) if TARGETS.is_detectable(target) else Vector2.RIGHT
			slot.origin = _clamp(origin+aim*reach*float(index+1)/float(count))
		elif mode == "trail":
			var move: Vector2 = host.hero.player_move_input.normalized()
			if move.is_zero_approx(): move = Vector2.RIGHT.rotated(index*TAU/count)
			slot.origin = _clamp(origin-move*index*float(slot.radius)*1.1)
		# Nominal per-target budget per cast, shared across zones; orbit pays for contact gaps.
		var budget := float(rule.get("budget",2.0))*float(data.get("awakening_budget",1.0))
		slot.damage = maxi(1,roundi(damage*budget*interval/(cooldown if mode == "orbit" else duration*count)))
		if mode in ["bombard","trap","fault","lob_burst"]: slot.damage = maxi(1,roundi(damage*budget/count))
		if float(data.get("awakening_lob_spread",0))>0 and count>1 and mode in ["lob","lob_burst","sigil","random","consecrate"]:
			var spread:=Vector2.RIGHT.rotated(TAU*index/count)*float(data.awakening_lob_spread)
			slot.landing=_clamp(Vector2(slot.landing)+spread)
			if mode not in ["lob","lob_burst"]:slot.origin=slot.landing
		slot.frames = host.art.get(id,[]); slot.color = Color(String(data.color))
		slot.max_kind = String(data.get("max_mechanic",{}).get("mechanic","")); slot.orbit_shape = String(data.get("max_mechanic",{}).get("shape",""))
		slot.detonated = false; slot.relay_phase = floori(clock/2.0)
		slot.evolution_damage = maxi(1,roundi(damage*float(data.get("max_mechanic",{}).get("ratio",0.0))/count))
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
			slot.warning = maxf(0.0,float(slot.warning)-delta)
			if float(slot.warning)<=0.0 and slot.mode in ["lob","lob_burst"]: slot.origin = slot.landing
			if float(slot.warning) <= 0.0 and slot.mode in ["bombard","fault","lob_burst"]:
				host._splash(slot.origin,int(slot.damage),float(slot.radius),null,slot.data)
				slot.left = 0.0
			continue
		slot.left = maxf(0.0,float(slot.left)-delta)
		if float(slot.left) <= 0.0:
			if String(slot.max_kind) in ["detonating_trail","reactive_zone"]: _detonate(slot)
			continue
		var mode := String(slot.mode)
		if mode == "trap":
			host.hero._fill_monster_nodes_near(slot.origin,float(slot.radius),scratch)
			for actor in scratch:
				if TARGETS.is_detectable(actor) and actor.global_position.distance_squared_to(slot.origin) <= float(slot.radius)*float(slot.radius):
					host._splash(slot.origin,int(slot.damage),float(slot.radius),null,slot.data)
					slot.left = 0.0; break
			continue
		if mode == "sentry" and String(slot.max_kind) == "relay_turret" and int(slot.relay_phase) != floori(clock/2.0):
			slot.relay_phase = floori(clock/2.0)
			var previous: Vector2 = slot.origin
			slot.origin = _clamp(host.hero.global_position+Vector2.from_angle(float(slot.phase)+clock)*90.0)
			host._effect(previous,slot.origin,18.0,"chain",slot.color,slot.data)
		if mode in ["orbit","aura"]: slot.origin = host.hero.global_position
		slot.tick = float(slot.tick)-delta
		if float(slot.tick) > 0.0: continue
		slot.tick = float(slot.interval)
		if mode == "consecrate" and host.hero.global_position.distance_squared_to(slot.origin) <= float(slot.radius)*float(slot.radius):
			host.hero.heal_direct(maxi(1,roundi(host.hero.max_hp*.001)))
		if mode == "orbit":
			for index in int(slot.count): host.hero._damage_treasure_chests(orbit_point(slot,index),float(slot.radius),int(slot.damage))
		elif mode != "sentry": host.hero._damage_treasure_chests(slot.origin,float(slot.radius),int(slot.damage))
		var query_radius := float(slot.orbit_radius)*(1.45 if not String(slot.max_kind).is_empty() else 1.0)+float(slot.radius) if mode == "orbit" else float(slot.radius)
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
			if String(slot.max_kind) == "reactive_zone" and not bool(slot.detonated): _detonate(slot)
			host._hit(actor,int(slot.damage),"field",int(slot.rank),slot.data)
		if mode == "sentry" and is_instance_valid(nearest):
			host._launch_projectile(nearest,slot.origin,int(slot.damage),int(slot.rank),slot.color,slot.data,0.0,false,float(slot.radius))
			host.hero._fill_monster_nodes_near(slot.origin,float(slot.radius),host.scratch)
			host._launch_extras(nearest,slot.origin,int(slot.damage),int(slot.rank),slot.color,slot.data,float(slot.radius),mini(2,int(slot.data.get("extra_projectiles",0))),0.08)
func _detonate(slot: Dictionary) -> void:
	if bool(slot.detonated) or int(slot.evolution_damage) <= 0: return
	slot.detonated = true
	host._splash(slot.origin,int(slot.evolution_damage),float(slot.radius)*1.25,null,slot.data.evolution_secondary_data)
func orbit_point(slot: Dictionary,index: int) -> Vector2:
	var radius := float(slot.orbit_radius)
	var spin := clock*float(slot.data.get("orbit_speed",2.4))
	var shape := String(slot.orbit_shape)
	if not String(slot.max_kind).is_empty():
		if shape == "counter":
			if index%2 == 0: radius *= .65; spin = -spin
		elif shape == "spiral": radius *= 1.0+.35*sin(clock*1.8+index*.9)
		elif shape == "breathing": radius *= 1.0+.4*sin(clock*1.8)
	return Vector2(slot.origin)+Vector2.from_angle(spin+TAU*index/int(slot.count))*radius
func orbit_contact(slot: Dictionary,point: Vector2) -> bool:
	for index in int(slot.count):
		if orbit_point(slot,index).distance_squared_to(point) <= float(slot.radius)*float(slot.radius): return true
	return false
func draw() -> void:
	visit_visuals(_draw_visual)
# Shared presentation sampling: clients use the authoritative slot geometry.
func visit_visuals(visitor: Callable) -> void:
	for slot in slots:
		if float(slot.left) <= 0.0: continue
		var color: Color = slot.color
		if float(slot.warning)>0.0 and slot.mode in ["lob","lob_burst"]:
			var progress := clampf(1.0-float(slot.warning)/.7,0.0,1.0)
			var point: Vector2 = Vector2(slot.launch).lerp(slot.landing,progress)+Vector2(0,-sin(progress*PI)*85.0)
			visitor.call(slot,point,22.0,color,false)
			visitor.call(slot,Vector2(slot.landing),float(slot.radius),Color(color,.4),true)
			continue
		if float(slot.warning) > 0.0:
			visitor.call(slot,Vector2(slot.origin),float(slot.radius),Color(color,.5),true)
			continue
		if slot.mode == "orbit":
			for index in int(slot.count):
				slot.visual_index = index
				visitor.call(slot,orbit_point(slot,index),float(slot.radius),color,false)
		elif slot.mode == "sentry": visitor.call(slot,Vector2(slot.origin),32.0,color,false)
		else: visitor.call(slot,Vector2(slot.origin),float(slot.radius),color,false)
func _draw_visual(slot: Dictionary,point: Vector2,radius: float,color: Color,warning: bool) -> void:
	if warning:
		if host.attack_range_visible:
			host.hero.draw_arc(host.hero.to_local(point),radius,0,TAU,24 if slot.mode in ["lob","lob_burst"] else 32,Color(GEOMETRY.WARNING_COLOR,color.a),GEOMETRY.WARNING_WIDTH)
	else: _draw(slot,point,radius)
func _draw(slot: Dictionary,point: Vector2,radius: float) -> void:
	host._draw_area(host.hero.to_local(point),radius,slot.color,slot.frames,host._loop_progress(slot.frames,clock))
