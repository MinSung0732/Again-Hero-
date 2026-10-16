extends RefCounted
## Bounded MAX actions: 24 moving/trap/counter/zone slots, 64 generation-safe marks.
const TARGETS := preload("res://src/systems/hero_target_policy.gd")
const LIMIT := 24
const MARK_LIMIT := 64
var _runtime: WeakRef
var host:
	get: return _runtime.get_ref()
var slots: Array[Dictionary] = []
var marks: Array[Dictionary] = []
var mark_lookup: Dictionary = {}
var free_marks: Array[int] = []
var query: Array = []
var proc_ready: Dictionary = {}
var clock := 0.0
var enabled := false
func install(runtime) -> void:
	_runtime = weakref(runtime)
	for index in LIMIT:
		slots.append({"left":0.0,"kind":"","id":"","origin":Vector2.ZERO,"position":Vector2.ZERO,"target":Vector2.ZERO,"direction":Vector2.RIGHT,"radius":1.0,"damage":0,"data":{},"rule":{},"age":0.0,"phase":0,"tick":0.0,"absorbed":0.0,"threshold":1.0,"victims":{}})
	for index in MARK_LIMIT:
		free_marks.append(index)
		marks.append({"index":index,"left":0.0,"key":Vector4i.ZERO,"handle":Vector3i.ZERO,"count":0,"data":{}})
func _free(kind: String,id: String) -> Dictionary:
	# Recast replaces only persistent support from this weapon, never duplicates it.
	if kind in ["counter","sanctuary"]:
		for slot in slots:
			if slot.kind == kind and slot.id == id: slot.left = 0.0
	for slot in slots:
		if float(slot.left) <= 0.0:
			slot.victims.clear(); slot.kind = kind; slot.id = id; slot.age = 0.0; slot.phase = 0; slot.tick = 0.0; slot.absorbed = 0.0
			return slot
	return {}
func _queue(kind: String,data: Dictionary,origin: Vector2,target: Vector2,damage: int,radius: float,rule: Dictionary,life: float) -> void:
	enabled = true
	var slot := _free(kind,String(data.get("weapon_id","")))
	if slot.is_empty(): return
	slot.left = life; slot.origin = origin; slot.position = origin; slot.target = target
	slot.direction = origin.direction_to(target) if origin != target else Vector2.RIGHT
	slot.damage = damage; slot.radius = radius; slot.rule = rule
	slot.data = data.get("evolution_secondary_data",data)
	slot.threshold = maxf(1.0,host.shield_amount(host.hero.max_hp*(float(data.get("shield_ratio",.04))+int(data.get("growth_rank",10))*.006))*.65)
func on_cast(data: Dictionary,origin: Vector2,direction: Vector2,target: Node2D,damage: int,reach: float) -> void:
	var rule: Dictionary = data.get("max_mechanic",{})
	if rule.is_empty(): return
	var kind := String(rule.mechanic)
	if kind in ["fork","mark","reap","orbit","relay_turret","reactive_zone","detonating_trail"]: return
	var center: Vector2 = target.global_position if TARGETS.is_detectable(target) else origin+direction*minf(reach,260.0)
	var extra := maxi(1,roundi(damage*float(rule.ratio)))
	var radius := minf(float(rule.radius)*float(data.get("area_scale",1.0)),380.0)
	match kind:
		"return":
			if not TARGETS.is_detectable(target): return
			_queue(kind,data,origin,center+direction*70.0,extra,radius,rule,2.4)
		"cross", "front_echo":
			if not TARGETS.is_detectable(target): return
			_queue(kind,data,origin if kind == "front_echo" else center,(origin if kind == "front_echo" else center)+direction,extra,radius,rule,1.5)
		"mine":
			if not TARGETS.is_detectable(target): return
			for index in int(rule.count):
				var point := _clamp(center+direction.orthogonal()*(index*2-1)*radius*0.6)
				_queue(kind,data,point,point,maxi(1,extra/int(rule.count)),radius,rule,2.4)
		"sanctuary": _queue(kind,data,origin,origin,extra,radius,rule,3.0)
		"counter": _queue(kind,data,origin,origin,extra,radius,rule,minf(float(data.get("shield_duration",3.0)),5.0))
		"command": _command(data,center,extra,radius,rule)
func on_native_basic(data: Dictionary,origin: Vector2,target: Node2D,damage: int,reach: float) -> void:
	# Native starter actors retain their original hit path. A visible, bounded
	# companion round carries MAX mark/fork behavior without relabeling skills.
	if String(data.get("max_mechanic",{}).get("mechanic","")) not in ["mark","fork","reap"] or not TARGETS.is_detectable(target): return
	host._launch_projectile(target,origin,maxi(1,roundi(damage*.35)),10,Color(String(data.color)),data,0.0,false,reach)
func _command(data: Dictionary,target: Vector2,damage: int,radius: float,rule: Dictionary) -> void:
	if not is_instance_valid(host.authority) or host.authority.get("active_hero_summons") == null: return
	# Existing active registry, at most 3 survival summons; no inactive pool scan.
	var count := 0
	for actor_id in host.authority.active_hero_summons:
		var actor = host.authority.active_hero_summons[actor_id]
		if count >= 3: break
		if not is_instance_valid(actor) or actor.get("owner_hero") != host.hero: continue
		var shape := String(rule.shape)
		if shape == "shots":
			var nearest := _nearest(target,280.0,null)
			if nearest != null: host._launch_projectile(nearest,actor.global_position,maxi(1,damage/3),10,Color(String(data.color)),data.evolution_secondary_data,count*.08,false,750.0)
		else: _queue("return" if shape == "return" else "cross" if shape == "cross" else "command_nova",data,actor.global_position,target,maxi(1,damage/3),28.0 if shape == "return" else radius,rule,2.4)
		count += 1
func on_hit(actor: Node2D,handle: Vector3i,point: Vector2,lost: int,killed: bool,data: Dictionary,damage: int) -> void:
	if lost <= 0 or bool(data.get("evolution_secondary",false)): return
	var rule: Dictionary = data.get("max_mechanic",{})
	if rule.is_empty(): return
	var kind := String(rule.mechanic)
	if kind == "mark" and TARGETS.is_detectable(actor) and handle != Vector3i.ZERO:
		enabled = true
		var key := Vector4i(handle.x,handle.y,handle.z,int(rule.index)+1)
		var index: int = int(mark_lookup.get(key,-1))
		if index < 0:
			if free_marks.is_empty(): return
			index = free_marks.pop_back()
			var old: Dictionary = marks[index]
			old.key = key; old.handle = handle; old.count = 0; old.data = data; mark_lookup[key] = index
		var mark: Dictionary = marks[index]; mark.count = int(mark.count)+1; mark.left = 3.0
		if int(mark.count) >= 3:
			mark_lookup.erase(key); mark.left = 0.0; free_marks.append(index)
			host._splash(point,maxi(1,roundi(damage*float(rule.ratio))),float(rule.radius)*float(data.get("area_scale",1.0)),null,data.evolution_secondary_data)
	elif (kind == "fork" or kind == "reap" and killed) and clock >= float(proc_ready.get(data.weapon_id,0.0)):
		proc_ready[data.weapon_id] = clock+0.45
		var secondary: Dictionary = data.evolution_secondary_data
		var extra := maxi(1,roundi(damage*float(rule.ratio)))
		if kind == "reap":
			var next := _nearest(point,float(rule.radius),actor)
			if next != null: _queue("return",data,point,next.global_position,extra,28.0,rule,2.4)
		else:
			host.hero._fill_monster_nodes_near(point,float(rule.radius),query)
			var fired := 0
			for other in query:
				if other == actor or not TARGETS.is_detectable(other) or other.global_position.distance_squared_to(point) > float(rule.radius)*float(rule.radius): continue
				host._launch_projectile(other,point,extra,10,Color(String(data.color)),secondary,fired*.08,false,float(rule.radius))
				fired += 1
				if fired >= 2: break
			if fired == 0 and TARGETS.is_detectable(actor): host._launch_projectile(actor,point,extra,10,Color(String(data.color)),secondary,.08,false,float(rule.radius))
func _nearest(point: Vector2,radius: float,excluded: Node2D) -> Node2D:
	host.hero._fill_monster_nodes_near(point,radius,query)
	var result: Node2D; var best := radius*radius
	for actor in query:
		if actor == excluded or not TARGETS.is_detectable(actor): continue
		var distance: float = actor.global_position.distance_squared_to(point)
		if distance <= best: best = distance; result = actor
	return result
func on_shield_absorbed(amount: float) -> void:
	if amount <= 0: return
	for slot in slots:
		if float(slot.left) > 0 and slot.kind == "counter": slot.absorbed = float(slot.absorbed)+amount
func tick(delta: float) -> void:
	clock += delta
	if not enabled: return
	for mark in marks:
		if float(mark.left) <= 0: continue
		mark.left = maxf(0.0,float(mark.left)-delta)
		if float(mark.left) <= 0:
			mark_lookup.erase(mark.key); free_marks.append(int(mark.index))
		host.hero.queue_redraw()
	for slot in slots:
		if float(slot.left) <= 0: continue
		slot.left = maxf(0.0,float(slot.left)-delta); slot.age = float(slot.age)+delta
		if host.hero.current_hp <= 0: slot.left = 0.0; continue
		var kind := String(slot.kind)
		if kind == "return": _travel(slot,delta)
		elif kind in ["cross","front_echo","command_nova"]:
			if float(slot.age) >= float(slot.rule.get("delay",.35)):
				_burst(slot); slot.left = 0.0
		elif kind == "mine":
			if float(slot.age) >= .35 and (_nearest(slot.origin,float(slot.radius)*.7,null) != null or float(slot.left) <= 0):
				_burst(slot); slot.left = 0.0
		elif kind == "counter":
			if int(slot.phase) == 0:
				slot.phase = 1
			if float(slot.left) > 0 and float(slot.absorbed) >= float(slot.threshold):
				slot.origin = host.hero.global_position
				var aimed := _nearest(slot.origin,float(slot.radius),null)
				if aimed != null: slot.direction = Vector2(slot.origin).direction_to(aimed.global_position)
				if String(slot.rule.shape) == "return":
					var target := _nearest(slot.origin,500.0,null)
					if target != null: _queue("return",slot.data,slot.origin,target.global_position,int(slot.damage),28.0,slot.rule,2.4)
				else: _burst(slot)
				host.hero.heal_direct(roundi(host.hero.max_hp*float(slot.rule.get("heal",0.0))))
				slot.left = 0.0
		elif kind == "sanctuary":
			if float(slot.left) <= 0: continue
			slot.tick = float(slot.tick)-delta
			if float(slot.tick) <= 0:
				slot.tick = .6
				_burst(slot)
				if host.hero.global_position.distance_squared_to(slot.origin) <= float(slot.radius)*float(slot.radius): host.hero.heal_direct(roundi(host.hero.max_hp*float(slot.rule.heal)))
		host.hero.queue_redraw()
func _travel(slot: Dictionary,delta: float) -> void:
	var destination: Vector2 = slot.target if int(slot.phase) == 0 else host.hero.global_position
	var previous: Vector2 = slot.position
	slot.position = previous.move_toward(destination,950.0*delta)
	var center := (previous+Vector2(slot.position))*.5
	var radius := float(slot.radius)
	host.hero._fill_monster_nodes_near(center,previous.distance_to(slot.position)*.5+radius,query)
	for actor in query:
		if not TARGETS.is_detectable(actor): continue
		var handle: Vector3i = host.authority.get_battle_entity_handle(actor)
		if handle == Vector3i.ZERO or slot.victims.has(handle): continue
		var closest := Geometry2D.get_closest_point_to_segment(actor.global_position,previous,slot.position)
		if closest.distance_squared_to(actor.global_position) > radius*radius: continue
		if slot.victims.size() >= 32: break
		slot.victims[handle] = true
		host._hit(actor,int(slot.damage),"nova",10,slot.data)
	if Vector2(slot.position).distance_squared_to(destination) < 1.0:
		if int(slot.phase) == 0: slot.phase = 1; slot.victims.clear()
		else: slot.left = 0.0
func _burst(slot: Dictionary) -> void:
	var center: Vector2 = slot.origin
	var radius := float(slot.radius)
	if slot.kind == "front_echo":
		var forward: Vector2 = slot.direction
		host.hero._fill_monster_nodes_near(center,radius,query)
		for actor in query:
			if not TARGETS.is_detectable(actor): continue
			var offset: Vector2 = actor.global_position-center
			if offset.length_squared() <= radius*radius and (offset.is_zero_approx() or offset.normalized().dot(forward) >= .35): host._hit(actor,int(slot.damage),"slash",10,slot.data)
		host._effect(center,center+forward*radius,radius,"slash",Color(String(slot.data.color)),slot.data)
		return
	var cross: bool = slot.kind == "cross" or String(slot.rule.get("shape","")) == "cross" and slot.kind != "mine"
	if not cross:
		host._splash(center,int(slot.damage),radius,null,slot.data)
		return
	var direction: Vector2 = Vector2(slot.direction).rotated(float(slot.rule.get("angle",0.0)))
	host.hero._fill_monster_nodes_near(center,radius,query)
	for actor in query:
		if not TARGETS.is_detectable(actor): continue
		var offset: Vector2 = actor.global_position-center
		if offset.length_squared() > radius*radius: continue
		if absf(offset.cross(direction)) > 26.0 and absf(offset.dot(direction)) > 26.0: continue
		host._hit(actor,int(slot.damage),"nova",10,slot.data)
	for index in 2:
		var aim: Vector2 = direction if index == 0 else direction.orthogonal()
		host._effect(center-aim*radius,center+aim*radius,26.0,"beam",Color(String(slot.data.color)),slot.data)
func _clamp(point: Vector2) -> Vector2:
	if host.authority.has_method("_clamp_manual_spawn_position"): return host.authority._clamp_manual_spawn_position(point)
	return point
func draw() -> void:
	if not enabled: return
	for slot in slots:
		if float(slot.left) <= 0 or slot.kind == "counter": continue
		var point: Vector2 = slot.position if slot.kind == "return" else slot.origin
		var radius: float = float(slot.radius)
		if slot.kind == "return":
			host._draw_area(host.hero.to_local(point),radius,Color(String(slot.data.color)),host.art.get(slot.id,[]),fmod(float(slot.age)*8,1.0))
		else:
			host.hero.draw_arc(host.hero.to_local(point),radius,0,TAU,32,Color(Color(String(slot.data.color)),.8),3.0)
			if slot.kind == "cross":
				var aim := Vector2(slot.direction).rotated(float(slot.rule.get("angle",0)))
				for index in 2:
					var direction: Vector2 = aim if index == 0 else aim.orthogonal()
					host.hero.draw_line(host.hero.to_local(point-direction*radius),host.hero.to_local(point+direction*radius),Color("ffe8a3"),2.0)
	for mark in marks:
		if float(mark.left) <= 0: continue
		var actor: Node2D = host.authority.resolve_battle_entity(mark.handle)
		if not TARGETS.is_detectable(actor): continue
		host.hero.draw_arc(host.hero.to_local(actor.global_position),20.0,0,TAU*int(mark.count)/3.0,16,Color("ffe8a3"),3.0)
