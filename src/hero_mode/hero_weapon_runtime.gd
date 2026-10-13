extends RefCounted
const DATA := preload("res://src/data/hero_weapon_catalog.gd")
const HIT := preload("res://src/systems/monster_hit_context.gd")
const TARGETS := preload("res://src/systems/hero_target_policy.gd")
const EFFECT_LIMIT := 48
const PROJECTILE_LIMIT := 64
const MODE := preload("res://src/data/hero_mode_catalog.gd")
const AFFLICTIONS := preload("res://src/systems/received_afflictions.gd")
const ART := preload("res://src/ui/hero_weapon_art.gd")
const NATIVE := preload("res://src/hero_mode/hero_weapon_native_runtime.gd")
const GEOMETRY := preload("res://src/hero_mode/hero_weapon_geometry.gd")
const EMPTY_ART: Array[Texture2D] = []
var native_skills: RefCounted
var art: Dictionary = {}
var magazines: Dictionary = {}
var hero
var levels: Dictionary = {}
var passives: Dictionary = {}
var evolved: Dictionary = {}
var weapon_ids: Array[String] = []
var available_weapons: Array = []
var cooldowns: Dictionary = {}
var scratch: Array = []
var effects: Array[Dictionary] = []
var fields: Array[Dictionary] = []
var field_cursor := 0
var effect_cursor := 0
var power := 1.0
var haste := 1.0
var projectile_speed := 1.0
var damage_multiplier := 1.0
var base_max_hp := 1200
var base_move_speed := 270.0
var base_pickup_radius := 150.0
var base_exp_multiplier := 1.0
var projectiles: Array[Dictionary] = []
var projectile_cursor := 0
var authority: Node
var visual_clock := 0.0
var chest_serial := 0
var last_applied_chest := 0
var shield_left := 0.0
var owned_shield := 0.0

func install(host) -> void:
	hero = host
	authority = hero.get_parent()
	base_max_hp = int(hero.max_hp); base_move_speed = float(hero.move_speed)
	base_pickup_radius = float(hero.exp_pickup_radius); base_exp_multiplier = float(hero.exp_gain_multiplier)
	for index in range(PROJECTILE_LIMIT):
		projectiles.append({"active":false,"handle":Vector3i.ZERO,"position":Vector2.ZERO,"damage":0,"rank":1,"color":Color.WHITE,"age":0.0,"delay":0.0,"data":{},"melee":false,"reach":0.0,"traveled":0.0})
	available_weapons = DATA.weapon_pool(String(hero.hero_id))
	if hero.has_method("_acquire_projectile"):
		native_skills = NATIVE.new(); native_skills.install(hero)
		for id in available_weapons:
			var pattern := String(DATA.WEAPONS[id].pattern)
			# Native actors own their cached textures; do not duplicate their bitmaps.
			art[id] = EMPTY_ART if NATIVE.SCENES.has(pattern) or pattern == "summon" else ART.sequence(String(DATA.WEAPONS[id].get("effect_dir","")))
	for index in range(EFFECT_LIMIT):
		effects.append({"left":0.0,"duration":0.0,"a":Vector2.ZERO,"b":Vector2.ZERO,"radius":0.0,"pattern":"","color":Color.WHITE,"orbit_count":4,"orbit_speed":3.0,"orbit_ratio":0.7})
	for index in range(8): fields.append({"left":0.0,"tick":0.0,"origin":Vector2.ZERO,"radius":0.0,"damage":0,"cap":9,"interval":0.5,"follow":false,"data":{},"rank":1})
	add(String(DATA.STARTERS.get(hero.hero_id,"ranged_rookie_arcane_bolt")))

func add(id: String) -> bool:
	if DATA.is_weapon(id):
		if id not in available_weapons: return false
		if int(levels.get(id,0)) >= DATA.MAX_LEVEL: return false
		if not levels.has(id):
			if weapon_ids.size() >= DATA.WEAPON_SLOTS: return false
			weapon_ids.append(id); cooldowns[id] = 0.0
			magazines[id] = int(DATA.WEAPONS[id].get("magazine",0))
		levels[id] = int(levels.get(id,0))+1
		hero.build_counts[id] = levels[id]
		return true
	if not DATA.PASSIVES.has(id) or int(passives.get(id,0)) >= DATA.MAX_LEVEL: return false
	if not passives.has(id) and passives.size() >= DATA.PASSIVE_SLOTS: return false
	passives[id] = int(passives.get(id,0))+1
	hero.build_counts[id] = passives[id]
	var data: Dictionary = DATA.PASSIVES[id]
	var rank := int(passives[id])
	var bonus := float(data.value)*rank
	match String(data.stat):
		"power": power = 1.0+bonus
		"haste": haste = 1.0/(1.0+bonus)
		"projectile": projectile_speed = 1.0+bonus
		"armor": damage_multiplier = 1.0-minf(bonus,0.30)
		"vitality":
			var increase: int = roundi(base_max_hp*float(data.value)*rank)-roundi(base_max_hp*float(data.value)*(rank-1))
			hero.max_hp += increase; hero.heal_direct(increase)
		"mobility": hero.move_speed = base_move_speed*(1.0+bonus)
		"magnet": hero.exp_pickup_radius = base_pickup_radius*(1.0+bonus)
		"learning": hero.exp_gain_multiplier = base_exp_multiplier*(1.0+bonus)
	return true

func candidates() -> Array:
	var options: Array = []
	for id in available_weapons:
		if int(levels.get(id,0)) >= DATA.MAX_LEVEL: continue
		if not levels.has(id) and weapon_ids.size() >= DATA.WEAPON_SLOTS: continue
		options.append(_card(id,int(levels.get(id,0))+1))
	for id in DATA.PASSIVES:
		if int(passives.get(id,0)) >= DATA.MAX_LEVEL: continue
		if not passives.has(id) and passives.size() >= DATA.PASSIVE_SLOTS: continue
		options.append(_card(id,int(passives.get(id,0))+1))
	# Guarantee an owned upgrade when available; two other choices still explore.
	var result: Array = []
	var owned: Array = []
	for card in options:
		if levels.has(card.id): owned.append(card)
	if not owned.is_empty():
		var chosen: Dictionary = owned[randi_range(0,owned.size()-1)]
		result.append(chosen); options.erase(chosen)
	options.shuffle()
	while result.size() < 3 and not options.is_empty(): result.append(options.pop_back())
	if result.is_empty(): result.append({"id":"survival_restore","name":"완성된 빌드 · 회복","description":"모든 선택이 최대 레벨입니다. 최대 HP의 15%를 회복합니다."})
	return result

func _card(id: String, next_level: int) -> Dictionary:
	var data: Dictionary = DATA.WEAPONS.get(id,DATA.PASSIVES.get(id,{}))
	return {"id":id,"name":("무기" if DATA.is_weapon(id) else "보조")+" · "+String(data.name)+" Lv.%d" % next_level,"description":DATA.description(id,next_level)}

func choose(id: String) -> bool:
	if id == "survival_restore": hero.heal_direct(roundi(hero.max_hp*0.15)); return true
	return add(id)

func roll_chest() -> Dictionary:
	var eligible: Array[String] = []
	for id in weapon_ids:
		if int(levels[id]) == DATA.MAX_LEVEL and not evolved.has(id): eligible.append(id)
	var evolution := not eligible.is_empty()
	if not evolution:
		for id in weapon_ids:
			if int(levels[id]) < DATA.MAX_LEVEL: eligible.append(id)
	chest_serial += 1
	if eligible.is_empty(): return {"serial":chest_serial,"id":"survival_restore","evolution":false,"name":"생명의 축복","description":"모든 무기가 완성됐습니다. 최대 HP 25% 회복","applied":false}
	var id := eligible[randi_range(0,eligible.size()-1)]
	return {"serial":chest_serial,"id":id,"evolution":evolution,"name":String(DATA.WEAPONS[id].evolution) if evolution else String(DATA.WEAPONS[id].name)+" Lv.%d" % (int(levels[id])+1),"description":"피해 ×1.8 · 타격 수 +2 · 범위 +25% · 재사용 대기시간 -20%" if evolution else "보유 무기 +1레벨","applied":false}

func apply_chest(receipt: Dictionary) -> bool:
	if bool(receipt.get("applied",false)) or int(receipt.get("serial",-1)) != chest_serial or chest_serial <= last_applied_chest: return false
	var id := String(receipt.get("id",""))
	if id == "survival_restore": hero.heal_direct(roundi(hero.max_hp*0.25))
	elif bool(receipt.get("evolution",false)):
		if int(levels.get(id,0)) != DATA.MAX_LEVEL or evolved.has(id): return false
		evolved[id] = true
	else:
		if not levels.has(id) or not add(id): return false
	receipt["applied"] = true
	last_applied_chest = chest_serial
	return true

func build_tags() -> Dictionary:
	var result: Dictionary = {}
	for id in weapon_ids:
		for tag in DATA.WEAPONS[id].tags: result[tag] = int(result.get(tag,0))+int(levels[id])
	if passives.has("survival_mobility"): result["mobility"] = int(passives.survival_mobility)
	return result

func summary() -> String:
	var parts: PackedStringArray = []
	for id in weapon_ids:
		parts.append(String(DATA.WEAPONS[id].evolution) if evolved.has(id) else String(DATA.WEAPONS[id].name)+" Lv.%d/10" % int(levels[id]))
	return " · ".join(parts)

func tick(delta: float) -> void:
	visual_clock += delta
	_tick_projectiles(delta)
	var redraw := false
	for effect in effects:
		if float(effect.left) <= 0.0: continue
		effect.left = maxf(0.0,float(effect.left)-delta); redraw = true
	if redraw: hero.queue_redraw()
	if shield_left > 0.0:
		shield_left -= delta
		if shield_left <= 0.0:
			hero.shield_hp = maxf(0.0,hero.shield_hp-owned_shield); owned_shield = 0.0
	if hero.silence_timer > 0.0 or hero.imposed_skill_cooldown > 0.0 or hero.petrify_timer > 0.0: return
	for field in fields:
		if float(field.left) <= 0.0: continue
		hero.queue_redraw()
		field.left = maxf(0.0,float(field.left)-delta)
		if bool(field.follow): field.origin = hero.global_position
		field.tick = float(field.tick)-delta
		if float(field.tick) > 0.0: continue
		field.tick = float(field.interval)
		hero._fill_monster_nodes_near(field.origin,float(field.radius),scratch)
		var count := 0
		for raw in scratch:
			var actor := raw as Node2D
			if not TARGETS.is_detectable(actor): continue
			_hit(actor,int(field.damage),"field",int(field.rank),field.data); count += 1
			if count >= int(field.cap): break
	for id in weapon_ids:
		cooldowns[id] = maxf(0.0,float(cooldowns[id])-delta*hero.get_paralysis_attack_multiplier())
		if float(cooldowns[id]) > 0.0: continue
		_cast(id)
		cooldowns[id] = float(DATA.WEAPONS[id].cooldown)*haste*(1.0-0.035*(int(levels[id])-1))*(0.8 if evolved.has(id) else 1.0)
		if int(DATA.WEAPONS[id].get("magazine",0)) > 0 and int(magazines[id]) <= 0:
			cooldowns[id] += float(DATA.WEAPONS[id].get("reload",1.6))
			magazines[id] = int(DATA.WEAPONS[id].magazine)

func _cast(id: String) -> void:
	var data: Dictionary = DATA.WEAPONS[id]
	var rank := int(levels[id])
	var awakened := evolved.has(id)
	var origin: Vector2 = hero.global_position
	var reach: float = GEOMETRY.reach(data,rank,awakened)
	var damage: int = maxi(1,roundi(hero.attack_damage*float(data.power)*power*(1.0+0.18*(rank-1))*(1.8 if awakened else 1.0)))
	damage = maxi(1,roundi(damage*(1.0+float(data.get("low_hp_bonus",0.0))*(1.0-float(hero.current_hp)/maxf(hero.max_hp,1)))))
	var hits := int(data.get("base_hits",1))+int(rank/5)+(2 if awakened else 0)
	var pattern := String(data.pattern)
	var color := Color(String(data.color))
	hero._fill_monster_nodes_near(origin,reach,scratch)
	# Existing world-query registry/grid supplies detectable candidates; no group scan.
	var closest: Node2D = null
	var closest_distance := INF
	for raw in scratch:
		var actor := raw as Node2D
		if not TARGETS.is_detectable(actor): continue
		var distance: float = origin.distance_squared_to(actor.global_position)
		if distance < closest_distance: closest_distance = distance; closest = actor
	var direction: Vector2 = hero.player_move_input.normalized()
	if is_instance_valid(closest): direction = origin.direction_to(closest.global_position)
	if direction.length_squared() < 0.01: direction = Vector2.RIGHT
	if is_instance_valid(closest) or pattern == "summon" or pattern == "guard" or pattern == "heal": _pose(direction)
	if native_skills != null and native_skills.cast(data,origin,direction,closest,damage,reach,hits,rank,projectile_speed,awakened):
		hero._damage_treasure_chests(origin,minf(reach,220.0),damage)
		return
	if bool(data.get("cleanse",false)):
		hero.poison_timer = 0.0; hero.poison_tick_timer = 0.0; hero.poison_damage_remaining = 0; hero.poison_ticks_remaining = 0; hero.poison_source = null
		hero.damage_poison_tracker.clear(); hero.burn_runtime.clear(); hero.slow_timer = 0.0; hero.move_multiplier = 1.0
		hero.set_meta("poison_active",false); hero.set_meta("burn_active",false); hero._set_poison_flash(false)
	if is_instance_valid(closest) and float(data.get("hp_cost",0.0)) > 0.0:
		hero.current_hp = maxi(1,hero.current_hp-maxi(1,roundi(hero.current_hp*float(data.hp_cost))))
		hero.health_changed.emit(hero.current_hp,hero.max_hp)
	if pattern in ["combo","burst"]:
		if not is_instance_valid(closest): return
		var shots := mini(hits,6)
		if int(data.get("magazine",0)) > 0:
			shots = mini(shots,int(magazines[id])); magazines[id] = int(magazines[id])-shots
		for index in shots: _launch_projectile(closest,origin,damage,rank,color,data,index*float(data.get("hit_interval",0.14)),pattern == "combo",reach)
		hero._damage_treasure_chests(origin,minf(reach,220.0),damage)
		hero.attack_pose_timer = 0.25
		return
	if pattern == "poison":
		var field: Dictionary = fields[field_cursor]; field_cursor = (field_cursor+1)%fields.size()
		field.origin = closest.global_position if is_instance_valid(closest) else origin
		field.left = float(data.get("field_duration",3.0)); field.tick = 0.0; field.interval = float(data.get("field_interval",0.5)); field.radius = reach*float(data.get("field_radius_ratio",0.45)); field.damage = maxi(1,roundi(damage*float(data.get("field_power",0.25)))); field.cap = mini(24,4+hits*5)
		field.follow = bool(data.get("field_follow",false)); field.data = data; field.rank = rank
		if bool(field.follow): field.origin = origin
		field["frames"] = ART.cache.get(String(data.get("effect_dir","")),EMPTY_ART)
		field["color"] = color
		hero.queue_redraw()
		hero._damage_treasure_chests(origin,minf(reach,220.0),damage)
		return
	if pattern == "heal": hero.heal_direct(roundi(hero.max_hp*(float(data.get("heal_ratio",0.015))+rank*0.002)))
	if pattern == "guard":
		var shield: float = hero.max_hp*(float(data.get("shield_ratio",0.04))+rank*0.006)*(1.5 if awakened else 1.0)
		# Replace only this runtime's grant; preserve other shield sources.
		hero.shield_hp = maxf(0.0,hero.shield_hp-owned_shield)+shield; owned_shield = shield; shield_left = float(data.get("shield_duration",3.0))
	var cap := mini(24,4+hits*5) if pattern in ["nova","frost","guard","heal"] else mini(int(data.get("hit_cap",hits)),hits+4) if pattern in ["slash","beam","orbit"] else hits
	var struck := 0
	if pattern in ["bolt","chain"] and is_instance_valid(closest):
		if pattern == "bolt": _launch_projectile(closest,origin,damage,rank,color,data,0.0,false,reach)
		else:
			_hit(closest,damage,pattern,rank,data)
			_effect(origin,closest.global_position,22.0,pattern,color,data)
		struck = 1
	for raw in scratch:
		if struck >= cap: break
		var actor := raw as Node2D
		if not TARGETS.is_detectable(actor): continue
		if actor == closest and pattern in ["bolt","chain"]: continue
		if pattern == "chain" and is_instance_valid(closest) and actor.global_position.distance_squared_to(closest.global_position) > pow(float(data.get("chain_radius",200.0)),2): continue
		var offset: Vector2 = actor.global_position-origin
		if not GEOMETRY.contains(pattern,offset,direction,reach,rank,data): continue
		if pattern == "bolt": _launch_projectile(actor,origin,damage,rank,color,data,0.0,false,reach)
		else: _hit(actor,damage,pattern,rank,data)
		struck += 1
		if pattern == "chain": _effect(closest.global_position if is_instance_valid(closest) else origin,actor.global_position,20.0,pattern,color,data)
	if pattern == "beam": _effect(origin,origin+direction*reach,GEOMETRY.beam_half_width(rank),pattern,color,data)
	elif pattern not in ["bolt","chain"]: _effect(origin,origin+direction*reach,reach,pattern,color,data)
	hero._damage_treasure_chests(origin,minf(reach,220.0),damage)
func _pose(direction: Vector2) -> void:
	hero.attack_pose_timer = 0.25
	if is_instance_valid(hero.hero_sprite) and hero.hero_sprite.sprite_frames.has_animation(&"attack"): hero.hero_sprite.play(&"attack")
	if direction.x != 0.0: hero._face_attack_direction(direction.x)

# Generation handles prevent a recycled monster instance from receiving an old shot.
func _launch_projectile(actor: Node2D, origin: Vector2, damage: int, rank: int, color: Color, data: Dictionary = {}, delay: float = 0.0, melee: bool = false, reach: float = 0.0) -> void:
	if not is_instance_valid(authority) or not authority.has_method("get_battle_entity_handle"): return
	var handle: Vector3i = authority.call("get_battle_entity_handle",actor)
	if handle == Vector3i.ZERO: return
	for offset in range(PROJECTILE_LIMIT):
		var index := (projectile_cursor+offset)%PROJECTILE_LIMIT
		var shot: Dictionary = projectiles[index]
		if bool(shot.active): continue
		projectile_cursor = (index+1)%PROJECTILE_LIMIT
		shot.active = true; shot.handle = handle; shot.position = origin
		shot.damage = damage; shot.rank = rank; shot.color = color; shot.age = 0.0
		shot.data = data; shot.delay = delay; shot.melee = melee; shot.reach = reach if reach > 0 else float(data.get("range",900.0)); shot.traveled = 0.0
		hero.queue_redraw()
		return

func _tick_projectiles(delta: float) -> void:
	var redraw := false
	for shot in projectiles:
		if not bool(shot.active): continue
		shot.delay = maxf(0.0,float(shot.delay)-delta)
		if float(shot.delay) > 0.0: continue
		redraw = true; shot.age = float(shot.age)+delta
		var actor: Node2D = authority.call("resolve_battle_entity",shot.handle) as Node2D if is_instance_valid(authority) else null
		if not TARGETS.is_detectable(actor) or float(shot.age) > 3.0:
			shot.active = false; continue
		if bool(shot.melee):
			shot.active = false
			if hero.global_position.distance_squared_to(actor.global_position) <= pow(float(shot.reach),2) and hero.silence_timer <= 0.0:
				_effect(hero.global_position,actor.global_position,12.0,"chain",shot.color,shot.data)
				_hit(actor,int(shot.damage),"slash",int(shot.rank),shot.data)
			continue
		var remaining := maxf(0.0,float(shot.reach)-float(shot.traveled))
		var step := minf(MODE.PROJECTILE_SPEED*projectile_speed*delta,remaining)
		var position: Vector2 = shot.position
		shot.position = position.move_toward(actor.global_position,step)
		shot.traveled = float(shot.traveled)+position.distance_to(shot.position)
		if position.distance_to(actor.global_position) <= step+GEOMETRY.PROJECTILE_RADIUS:
			shot.active = false
			_hit(actor,int(shot.damage),"bolt",int(shot.rank),shot.data)
		elif float(shot.traveled) >= float(shot.reach): shot.active = false
	if redraw: hero.queue_redraw()

func _hit(actor: Node2D, damage: int, pattern: String, rank: int, data: Dictionary = {}) -> void:
	var before := int(actor.get("current_hp"))
	if before > 0 and float(data.get("execute_ratio",0.0)) > 0.0 and before <= float(actor.get("max_hp"))*float(data.execute_ratio): damage = maxi(damage,before)
	HIT.hit(actor,damage,"melee" if pattern == "slash" else "ranged",hero)
	var lost := maxi(0,before-int(actor.get("current_hp"))) if is_instance_valid(actor) else 0
	if lost > 0 and float(data.get("lifesteal",0.0)) > 0.0: hero.heal_direct(roundi(lost*float(data.lifesteal)))
	if not TARGETS.is_detectable(actor): return
	if lost > 0 and (pattern == "frost" or data.has("slow_multiplier")):
		AFFLICTIONS.apply_slow(actor,float(data.get("slow_multiplier",maxf(0.35,0.85-rank*0.04))),float(data.get("slow_duration",2.0)))
	# Poison uses frequent damage pulses; it does not reuse hero-target poison APIs.

func _effect(a: Vector2,b: Vector2,radius: float,pattern: String,color: Color,data: Dictionary = {}) -> void:
	var effect: Dictionary = effects[effect_cursor]
	effect_cursor = (effect_cursor+1)%EFFECT_LIMIT
	effect.a = a; effect.b = b; effect.radius = radius; effect.pattern = pattern; effect.color = color
	effect["frames"] = ART.cache.get(String(data.get("effect_dir","")),EMPTY_ART)
	effect["follow"] = bool(data.get("field_follow",false))
	effect.orbit_count = int(data.get("orbit_count",4)); effect.orbit_speed = float(data.get("orbit_speed",3.0)); effect.orbit_ratio = float(data.get("orbit_ratio",0.7))
	effect["shape"] = GEOMETRY.sector(radius) if pattern == "slash" else GEOMETRY.beam(a.distance_to(b),radius) if pattern == "beam" else PackedVector2Array()
	effect.duration = 0.28
	effect.left = effect.duration; hero.queue_redraw()

func draw() -> void:
	for field in fields:
		if float(field.left) > 0.0:
			_draw_area(hero.to_local(field.origin),float(field.radius),field.get("color",Color.WHITE),field.get("frames",EMPTY_ART),fmod(visual_clock,1.0))
	for shot in projectiles:
		if bool(shot.active) and not bool(shot.melee) and float(shot.delay) <= 0.0:
			var position: Vector2 = hero.to_local(shot.position)
			hero.draw_circle(position,GEOMETRY.PROJECTILE_RADIUS,shot.color)
			hero.draw_circle(position,5.0,Color.WHITE)
	for effect in effects:
		if float(effect.left) <= 0.0: continue
		var ratio: float = float(effect.left)/float(effect.duration)
		var a: Vector2 = hero.to_local(effect.a)
		if bool(effect.get("follow",false)): a = Vector2.ZERO
		var b: Vector2 = hero.to_local(effect.b)
		var color: Color = effect.color; color.a = ratio*0.8
		var radius: float = effect.radius
		var frames: Array = effect.get("frames",EMPTY_ART)
		match String(effect.pattern):
			"beam","slash":
				hero.draw_set_transform(a,(b-a).angle())
				hero.draw_colored_polygon(effect.shape,Color(color,ratio*0.13))
				hero.draw_polyline(effect.shape,color,3.0)
				if not frames.is_empty():
					var texture: Texture2D = frames[mini(int((1-ratio)*frames.size()),frames.size()-1)]
					var length := a.distance_to(b)
					var rect := Rect2(Vector2(length*0.2,-length*0.3),Vector2.ONE*length*0.6) if effect.pattern == "slash" else Rect2(Vector2(0,-radius),Vector2(sqrt(maxf(0,length*length-radius*radius)),radius*2))
					hero.draw_texture_rect(texture,rect,false,Color(1,1,1,ratio*0.85))
				hero.draw_set_transform(Vector2.ZERO)
			"chain": hero.draw_line(a,b,color,5.0)
			"bolt":
				hero.draw_line(a,b,Color(color,ratio*0.3),3.0)
				hero.draw_circle(a.lerp(b,1.0-ratio),12.0,color)
			"orbit":
				var inner := GEOMETRY.orbit_inner(radius,float(effect.orbit_ratio))
				var outer := GEOMETRY.orbit_outer(radius,float(effect.orbit_ratio))
				hero.draw_arc(a,(inner+outer)*0.5,0,TAU,48,Color(color,ratio*0.14),outer-inner)
				hero.draw_arc(a,inner,0,TAU,48,color,3.0); hero.draw_arc(a,outer,0,TAU,48,color,3.0)
				for index in int(effect.orbit_count): hero.draw_circle(a+Vector2.from_angle(visual_clock*float(effect.orbit_speed)+index*TAU/float(effect.orbit_count))*(inner+outer)*0.5,minf(18,(outer-inner)*0.5),color)
			_:
				_draw_area(a,radius,Color(color,ratio),frames,1.0-ratio)

func _draw_area(center: Vector2, radius: float, color: Color, frames: Array, progress: float) -> void:
	if not frames.is_empty():
		var texture: Texture2D = frames[mini(int(progress*frames.size()),frames.size()-1)]
		var diameter := radius*sqrt(2.0)
		hero.draw_texture_rect(texture,Rect2(center-Vector2.ONE*diameter*0.5,Vector2.ONE*diameter),false,Color(1,1,1,color.a*0.75))
	hero.draw_circle(center,radius,Color(color,color.a*0.10))
	hero.draw_arc(center,radius,0.0,TAU,48,color,3.0)
