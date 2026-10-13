extends RefCounted
const DATA := preload("res://src/data/hero_weapon_catalog.gd")
const HIT := preload("res://src/systems/monster_hit_context.gd")
const TARGETS := preload("res://src/systems/hero_target_policy.gd")
const EFFECT_LIMIT := 48
var hero
var levels: Dictionary = {}
var passives: Dictionary = {}
var evolved: Dictionary = {}
var weapon_ids: Array[String] = []
var cooldowns: Dictionary = {}
var scratch: Array = []
var effects: Array[Dictionary] = []
var fields: Array[Dictionary] = []
var field_cursor := 0
var effect_cursor := 0
var power := 1.0
var haste := 1.0
var visual_clock := 0.0
var chest_serial := 0
var last_applied_chest := 0
var shield_left := 0.0
var owned_shield := 0.0

func install(host) -> void:
	hero = host
	for index in range(EFFECT_LIMIT):
		effects.append({"left":0.0,"duration":0.0,"a":Vector2.ZERO,"b":Vector2.ZERO,"radius":0.0,"pattern":"","color":Color.WHITE})
	for index in range(8): fields.append({"left":0.0,"tick":0.0,"origin":Vector2.ZERO,"radius":0.0,"damage":0,"cap":9})
	add(String(DATA.STARTERS.get(hero.hero_id,"weapon_basic_ranged_rookie")))

func add(id: String) -> bool:
	if DATA.is_weapon(id):
		if int(levels.get(id,0)) >= DATA.MAX_LEVEL: return false
		if not levels.has(id):
			if weapon_ids.size() >= DATA.WEAPON_SLOTS: return false
			weapon_ids.append(id); cooldowns[id] = 0.0
		levels[id] = int(levels.get(id,0))+1
		hero.build_counts[id] = levels[id]
		return true
	if not DATA.PASSIVES.has(id) or int(passives.get(id,0)) >= DATA.MAX_LEVEL: return false
	if not passives.has(id) and passives.size() >= DATA.PASSIVE_SLOTS: return false
	passives[id] = int(passives.get(id,0))+1
	hero.build_counts[id] = passives[id]
	match id:
		"survival_power": power = 1.0+0.08*int(passives[id])
		"survival_haste": haste = 1.0-0.04*int(passives[id])
		"survival_vitality":
			var increase: int = 60
			hero.max_hp += increase; hero.heal_direct(increase)
		"survival_mobility": hero.move_speed += 8.1
		"survival_learning": hero.exp_gain_multiplier = 1.0+0.08*int(passives[id])
	return true

func candidates() -> Array:
	var options: Array = []
	for id in DATA.WEAPONS:
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
		field.left = maxf(0.0,float(field.left)-delta)
		field.tick = float(field.tick)-delta
		if float(field.tick) > 0.0: continue
		field.tick = 0.5
		hero._fill_monster_nodes_near(field.origin,float(field.radius),scratch)
		var count := 0
		for raw in scratch:
			var actor := raw as Node2D
			if not TARGETS.is_detectable(actor): continue
			HIT.hit(actor,int(field.damage),"ranged",hero); count += 1
			if count >= int(field.cap): break
	for id in weapon_ids:
		cooldowns[id] = maxf(0.0,float(cooldowns[id])-delta*hero.get_paralysis_attack_multiplier())
		if float(cooldowns[id]) > 0.0: continue
		_cast(id)
		cooldowns[id] = float(DATA.WEAPONS[id].cooldown)*haste*(1.0-0.035*(int(levels[id])-1))*(0.8 if evolved.has(id) else 1.0)

func _cast(id: String) -> void:
	var data: Dictionary = DATA.WEAPONS[id]
	var rank := int(levels[id])
	var awakened := evolved.has(id)
	var origin: Vector2 = hero.global_position
	var reach: float = float(data.range)*(1.0+0.035*(rank-1))*(1.25 if awakened else 1.0)
	var damage: int = maxi(1,roundi(hero.attack_damage*float(data.power)*power*(1.0+0.18*(rank-1))*(1.8 if awakened else 1.0)))
	var hits := 1+int(rank/5)+(2 if awakened else 0)
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
	if pattern == "poison":
		var field: Dictionary = fields[field_cursor]; field_cursor = (field_cursor+1)%fields.size()
		field.origin = closest.global_position if is_instance_valid(closest) else origin
		field.left = 3.0; field.tick = 0.0; field.radius = reach*0.45; field.damage = maxi(1,roundi(damage*0.25)); field.cap = mini(24,4+hits*5)
		_effect(field.origin,field.origin,float(field.radius),pattern,color)
		hero._damage_treasure_chests(origin,minf(reach,220.0),damage)
		return
	if pattern == "heal": hero.heal_direct(roundi(hero.max_hp*(0.015+rank*0.002)))
	if pattern == "guard":
		var shield: float = hero.max_hp*(0.04+rank*0.006)*(1.5 if awakened else 1.0)
		hero.shield_hp = maxf(hero.shield_hp,shield); owned_shield = shield; shield_left = 3.0
	var cap := mini(24,4+hits*5) if pattern in ["nova","frost","poison","guard","heal"] else hits
	var struck := 0
	if pattern in ["bolt","chain"] and is_instance_valid(closest):
		_hit(closest,damage,pattern,rank)
		_effect(origin,closest.global_position,22.0,pattern,color); struck = 1
	for raw in scratch:
		if struck >= cap: break
		var actor := raw as Node2D
		if not TARGETS.is_detectable(actor): continue
		if actor == closest and pattern in ["bolt","chain"]: continue
		var offset: Vector2 = actor.global_position-origin
		if pattern == "slash" and offset.normalized().dot(direction) < 0.35: continue
		if pattern == "beam" and (offset.dot(direction) < 0.0 or absf(offset.cross(direction)) > 40.0+rank*5.0): continue
		if pattern == "orbit" and absf(offset.length()-reach*0.7) > 100.0: continue
		_hit(actor,damage,pattern,rank); struck += 1
		if pattern in ["chain","bolt"]: _effect(origin,actor.global_position,20.0,pattern,color)
	if pattern == "beam": _effect(origin,origin+direction*reach,28.0+rank*3.0,pattern,color)
	elif pattern not in ["bolt","chain"]: _effect(origin,origin+direction*reach,reach,pattern,color)
	hero._damage_treasure_chests(origin,minf(reach,220.0),damage)
	hero.attack_pose_timer = 0.25
	if is_instance_valid(hero.hero_sprite) and hero.hero_sprite.sprite_frames.has_animation(&"attack"):
		hero.hero_sprite.play(&"attack")
	if direction.x != 0.0: hero._face_attack_direction(direction.x)

func _hit(actor: Node2D, damage: int, pattern: String, rank: int) -> void:
	HIT.hit(actor,damage,"melee" if pattern == "slash" else "ranged",hero)
	if not TARGETS.is_detectable(actor): return
	if pattern == "frost" and actor.has_method("apply_slow"): actor.call("apply_slow",maxf(0.35,0.85-rank*0.04),2.0)
	# Poison uses frequent damage pulses; it does not reuse hero-target poison APIs.

func _effect(a: Vector2,b: Vector2,radius: float,pattern: String,color: Color) -> void:
	var effect: Dictionary = effects[effect_cursor]
	effect_cursor = (effect_cursor+1)%EFFECT_LIMIT
	effect.a = a; effect.b = b; effect.radius = radius; effect.pattern = pattern; effect.color = color
	effect.duration = 3.0 if pattern == "poison" else 1.5 if pattern == "orbit" else 0.28
	effect.left = effect.duration; hero.queue_redraw()

func draw() -> void:
	for effect in effects:
		if float(effect.left) <= 0.0: continue
		var ratio: float = float(effect.left)/float(effect.duration)
		var a: Vector2 = hero.to_local(effect.a)
		var b: Vector2 = hero.to_local(effect.b)
		var color: Color = effect.color; color.a = ratio*0.8
		var radius: float = effect.radius
		match String(effect.pattern):
			"beam","chain": hero.draw_line(a,b,color,maxf(3.0,radius*ratio*0.25))
			"bolt":
				hero.draw_line(a,b,Color(color,ratio*0.3),3.0)
				hero.draw_circle(a.lerp(b,1.0-ratio),12.0,color)
			"slash": hero.draw_arc(a,radius,(b-a).angle()-1.0,(b-a).angle()+1.0,16,color,9.0*ratio+2.0)
			"orbit":
				for index in range(4): hero.draw_circle(a+Vector2.from_angle(visual_clock*3.0+index*TAU/4.0)*radius*0.7,18.0,color)
			_:
				hero.draw_circle(a,radius*(1.0-ratio*0.4),Color(color,ratio*0.10))
				hero.draw_arc(a,radius*(1.0-ratio*0.4),0.0,TAU,32,color,4.0)
