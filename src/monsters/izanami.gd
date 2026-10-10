extends "res://src/monsters/goblin_thrower.gd"
const DATA := preload("res://src/data/izanami_behavior_catalog.gd")
const FX := preload("res://src/ui/izanami_combat_effects.gd")
const STATUS_SCOPE := preload("res://src/systems/status_action_scope.gd")
var ghost_action: RefCounted
var fan_action: RefCounted
var fire_actions: Array[RefCounted] = []
var spirit_actions: Array[RefCounted] = []
var transcend_level := 0
var summon_snapshot := 0
var gauge := 0.0
var clock := 0.0
var arrival := 1.5
var arrival_hit := false
var keeping_distance := false
var cooldowns := PackedFloat32Array([0.0,0.0,0.0])
var passive_hits := 0
var passive_statuses := 0
var ghost_remaining := 0.0
var ghost_hits := 0
var bind_remaining := 0.0
var fan_remaining := 0.0
var fan_spawned := 0
var fan_direction := Vector2.RIGHT
var effect_layer: Node2D
var torii_layer: Node2D
var visual_head_y := -110.0
@onready var status_layer: Node2D = $StatusLayer
# Fixed reusable slots: no helper monsters, physics shapes or scene churn.
var fire_age := PackedFloat32Array([-1.0,-1.0,-1.0,-1.0])
var fire_points := PackedVector2Array()
var fire_delay := PackedFloat32Array()
var fire_budget := PackedInt32Array()
var fire_paid := PackedInt32Array()
var fire_tick := PackedFloat32Array()
var spirit_state := PackedInt32Array()
var spirit_points := PackedVector2Array()
var spirit_destinations := PackedVector2Array()
var spirit_age := PackedFloat32Array()
var torii_age := PackedFloat32Array()
var torii_points := PackedVector2Array()
var torii_next := 0
var aura_tick := 0.0
var local_allies: Array = []
# Entries allocated only when an ally enters a gate; reused across gate refreshes.
var crossing_records: Dictionary = {}
var status_depth := 0
var count_current_hit := true
var target_visual: AnimatedSprite2D
var target_body_center := Vector2.ZERO
var fire_hit_counted := PackedByteArray([0,0,0,0])
var fire_slow_counted := PackedByteArray([0,0,0,0])
var prune_tick := 0.0
var stale_crossing_ids: Array[int] = []

func _init() -> void:
	fire_actions.resize(4)
	spirit_actions.resize(8)
	monster_type = "izanami"
	monster_role = "control"
	for stat in DATA.BASE:
		set(stat,DATA.BASE[stat])
	fire_points.resize(4)
	fire_delay.resize(4)
	fire_budget.resize(4)
	fire_paid.resize(4)
	fire_tick.resize(4)
	spirit_state.resize(8)
	spirit_points.resize(8)
	spirit_destinations.resize(8)
	spirit_age.resize(8)
	torii_age.resize(DATA.TORII_CAPACITY)
	torii_age.fill(-1.0)
	torii_points.resize(DATA.TORII_CAPACITY)

func configure_transcendence(count: int, level: int) -> void:
	summon_snapshot = maxi(count,0)
	transcend_level = clampi(level,0,5)
	max_hp = int(round(DATA.BASE.max_hp + summon_snapshot*DATA.STATUS_GROWTH.max_hp))
	attack_damage = int(round(DATA.BASE.attack_damage + summon_snapshot*DATA.STATUS_GROWTH.attack_damage))
	current_hp = max_hp

func _apply_normal_visual_profile() -> void:
	visual.apply_visual_profile(DATA.PROFILE)
	# All uploaded dot frames share their canvas; keep one scale and foot anchor.
	var texture: Texture2D = visual.sprite_frames.get_frame_texture(&"idle",0)
	if texture == null:
		return
	var bounds := texture.get_image().get_used_rect()
	var anchor := Vector2(bounds.get_center().x,bounds.end.y)-texture.get_size()*0.5
	var factor := 110.0/maxf(float(bounds.size.y),1.0)
	visual.scale = Vector2.ONE*factor
	visual.position = -anchor*factor
	visual_head_y = -float(bounds.size.y)*factor

func _ready() -> void:
	super._ready()
	status_layer.z_as_relative = false
	status_layer.z_index = 12
	status_layer.draw.connect(_draw_status)
	effect_layer = Node2D.new()
	effect_layer.name = "CombatEffects"
	effect_layer.z_as_relative = false
	effect_layer.z_index = 8
	effect_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(effect_layer)
	effect_layer.draw.connect(_draw_effects)
	torii_layer = Node2D.new()
	torii_layer.name = "ToriiEffects"
	torii_layer.z_as_relative = false
	torii_layer.z_index = DATA.TORII_WORLD_Z
	torii_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(torii_layer)
	torii_layer.draw.connect(_draw_torii)
	for kind in range(4):
		FX.prepare(kind)
	if is_instance_valid(hero):
		hero.accepted_damage_hit.connect(_on_accepted_hit)
		_cache_target_body_center()

func get_gauge_regen() -> float:
	return minf(maxf(float(combat_authority.command_regen_per_second),0.0),15.0) if is_instance_valid(combat_authority) else 0.0

func _physics_process(delta: float) -> void:
	if dying or current_hp <= 0:
		return
	if is_instance_valid(combat_authority) and (combat_authority.battle_over or combat_authority.external_pause or combat_authority.demon_augment_selection_active):
		return
	clock += delta
	gauge = minf(100.0,gauge+get_gauge_regen()*delta)
	for i in range(3):
		cooldowns[i] -= delta
	bind_remaining = maxf(bind_remaining-delta,0.0)
	ghost_remaining = maxf(ghost_remaining-delta,0.0)
	_tick_fire(delta)
	_tick_spirits(delta)
	_tick_torii(delta)
	if passive_hits >= 12 or passive_statuses >= 4:
		passive_hits = 0
		passive_statuses = 0
		_create_torii()
	if arrival > 0.0:
		arrival = maxf(arrival-delta,0.0)
		velocity = Vector2.ZERO
		if not arrival_hit and arrival <= 0.75:
			arrival_hit = true
			visual.play(&"hit")
			visual.frame = 1
		if arrival <= 0.0:
			visual.play(&"idle")
	else:
		if is_instance_valid(hero) and hero.current_hp > 0:
			_try_cast()
		super._physics_process(delta)
	effect_layer.queue_redraw()
	torii_layer.queue_redraw()
	queue_redraw()

func _refresh_combat_target() -> void:
	hero_target_refresh_timer = 0.25
	if is_instance_valid(combat_authority):
		hero = combat_authority.hero

func _tick_retreat_and_heal(delta: float) -> bool:
	var offset := hero.global_position-global_position
	var distance := offset.length()
	var facing := offset.normalized() if distance > 0.001 else Vector2.RIGHT
	cached_direction_to_hero = facing
	if distance < DATA.RETREAT_START_DISTANCE:
		keeping_distance = true
	elif distance >= DATA.HOLD_DISTANCE:
		keeping_distance = false
	var direction := Vector2.ZERO
	var remaining := 0.0
	if keeping_distance:
		direction = -facing
		remaining = DATA.HOLD_DISTANCE-distance
	elif distance > attack_range:
		direction = facing
		remaining = distance-DATA.HOLD_DISTANCE
	# Approach to cast/attack; hysteresis prevents retreat jitter at the boundary.
	var speed := move_speed*MONSTER_RUNTIME_COMMON.get_external_movement_multiplier(self)
	velocity = direction*minf(speed,remaining/maxf(delta,0.0001))
	if velocity.length_squared() > 0.01:
		move_and_slide()
	_update_visual_motion(facing.x,velocity.length_squared() > 0.01)
	if global_position.distance_squared_to(hero.global_position) <= attack_range*attack_range and attack_timer <= 0.0:
		attack_timer = attack_cooldown
		_visual_call(&"play_attack")
		_fire_projectile(hero.global_position-global_position)
	return true

func _fire_projectile(_offset: Vector2) -> void:
	_hit(1.0)

func _cache_target_body_center() -> void:
	target_visual = hero.get_node_or_null("HeroSprite") as AnimatedSprite2D
	if target_visual == null or target_visual.sprite_frames == null:
		return
	var texture := target_visual.sprite_frames.get_frame_texture(target_visual.animation,0)
	if texture == null:
		return
	# Cache alpha bounds at setup, never read image pixels in draw/physics loops.
	target_body_center = Vector2(texture.get_image().get_used_rect().get_center())
	if target_visual.centered:
		target_body_center -= texture.get_size()*0.5

func _target_body_point() -> Vector2:
	if is_instance_valid(target_visual):
		var center := target_body_center
		if target_visual.flip_h:
			center.x = -center.x
		if target_visual.flip_v:
			center.y = -center.y
		return target_visual.to_global(center+target_visual.offset)-global_position
	return hero.global_position-global_position+DATA.TARGET_BODY_CENTER_FALLBACK

func _hit(ratio: float, status_tick: bool = false) -> bool:
	return _deal_damage(maxi(int(round(attack_damage*ratio)),1),status_tick)

func _deal_damage(amount: int, status_tick: bool, count_passive: bool = true) -> bool:
	if not is_instance_valid(hero) or hero.current_hp <= 0:
		return false
	var previous := count_current_hit
	count_current_hit = count_passive
	var accepted := bool(hero.take_status_damage(amount,self)) if status_tick else bool(hero.take_damage(amount,self))
	count_current_hit = previous
	return accepted

func _on_accepted_hit(source: Node) -> void:
	var count_passive := count_current_hit
	# A nested ghost bind is a new hit, even when triggered by an uncounted DOT tick.
	count_current_hit = true
	if dying:
		return
	if source == self and count_passive:
		passive_hits += 1
	if ghost_remaining > 0.0:
		ghost_hits += 1
		if ghost_hits >= 12:
			# Clear before damage emits recursively: one bind per attachment.
			ghost_remaining = 0.0
			bind_remaining = 0.6
			_hit(1.55,true)
			_status("slow",0.01,3.0,true,ghost_action)
			_status("silence",0.0,3.0,true,ghost_action)

func _status(kind: String, strength: float, seconds: float, count_passive: bool = true, action: RefCounted = null) -> bool:
	if not is_instance_valid(hero) or hero.current_hp <= 0 or hero.is_dying:
		return false
	# Count only the authority's actual accepted events, not attempted casts.
	var previous_action := STATUS_SCOPE.begin(hero,action)
	status_depth = 0
	if not hero.status_applied.is_connected(_count_own_status):
		hero.status_applied.connect(_count_own_status)
	match kind:
		"slow": hero.apply_slow(strength,seconds)
		"stun": hero.apply_stun(seconds)
		"silence": hero.apply_silence(seconds)
		"vulnerability": hero.apply_damage_taken_increase(seconds,strength)
	hero.status_applied.disconnect(_count_own_status)
	STATUS_SCOPE.finish(hero,previous_action)
	if count_passive:
		passive_statuses += status_depth
	return status_depth > 0

func _count_own_status(_kind: String) -> void:
	status_depth += 1

func _try_cast() -> void:
	if bool(get_meta("silence_active",false)) or bool(get_meta("stun_active",false)):
		return
	if global_position.distance_squared_to(hero.global_position) > 550.0*550.0:
		return
	for i in range(3):
		var cost := float(DATA.COSTS[i]) * (0.5 if i == 2 and transcend_level >= 2 else 1.0)
		if cooldowns[i] > 0.0 or gauge < cost or (i == 0 and ghost_remaining > 0.0) or (i == 2 and fan_remaining > 0.0):
			continue
		gauge -= cost
		cooldowns[i] = skill_cooldown(i)
		_visual_call(&"play_attack")
		match i:
			0:
				ghost_action = STATUS_SCOPE.Token.new()
				ghost_remaining = 7.0
				ghost_hits = 0
				_status("vulnerability",0.15,7.0,true,ghost_action)
				_status("slow",0.88,7.0,true,ghost_action)
			1: _create_fire()
			2:
				fan_action = STATUS_SCOPE.Token.new()
				fan_remaining = 2.0
				fan_spawned = 0
				fan_direction = (hero.global_position-global_position).normalized()
		return

func skill_cooldown(index: int) -> float:
	if index == 1:
		return 2.0 if transcend_level >= 3 else (4.0 if transcend_level >= 1 else 8.0)
	return float(DATA.COOLDOWNS[index])

func fire_radius() -> float:
	return 90.0 * (1.3 if transcend_level >= 3 else 1.0)

func _create_fire() -> void:
	for i in range(4):
		if fire_age[i] >= 0.0:
			continue
		fire_actions[i] = STATUS_SCOPE.Token.new()
		fire_points[i] = hero.global_position
		fire_age[i] = 0.0
		fire_delay[i] = 0.0 if transcend_level >= 1 else 0.75
		fire_budget[i] = int(round(attack_damage*2.0))
		fire_paid[i] = 0
		fire_tick[i] = 0.0
		fire_hit_counted[i] = 0
		fire_slow_counted[i] = 0
		return

func _tick_fire(delta: float) -> void:
	for i in range(4):
		if fire_age[i] < 0.0:
			continue
		var before := fire_age[i]
		fire_age[i] += delta
		var inside := is_instance_valid(hero) and hero.global_position.distance_squared_to(fire_points[i]) <= fire_radius()*fire_radius()
		if before <= fire_delay[i] and fire_age[i] >= fire_delay[i]:
			if inside:
				if _deal_damage(maxi(int(round(attack_damage*1.7)),1),true,fire_hit_counted[i] == 0):
					fire_hit_counted[i] = 1
		if fire_age[i] < fire_delay[i]:
			continue
		fire_tick[i] -= delta
		var age := minf(fire_age[i]-fire_delay[i],3.0)
		if fire_tick[i] <= 0.0 or age >= 3.0:
			var total := int(round(fire_budget[i]*age/3.0))
			var amount := total-fire_paid[i]
			fire_paid[i] = total
			fire_tick[i] = 0.5
			if inside:
				if amount > 0:
					if _deal_damage(amount,true,fire_hit_counted[i] == 0):
						fire_hit_counted[i] = 1
				if _status("slow",0.7,2.0,fire_slow_counted[i] == 0,fire_actions[i]):
					fire_slow_counted[i] = 1
		if age >= 3.0:
			fire_age[i] = -1.0

func _tick_spirits(delta: float) -> void:
	if fan_remaining > 0.0:
		fan_remaining = maxf(fan_remaining-delta,0.0)
		var required := mini(8,1+int((2.0-fan_remaining)/0.25))
		while fan_spawned < required:
			var i := fan_spawned
			var direction := fan_direction.rotated(lerpf(-0.65,0.65,float(i)/7.0))
			spirit_actions[i] = fan_action
			spirit_points[i] = global_position
			spirit_destinations[i] = global_position + direction*randf_range(200.0,500.0)
			spirit_age[i] = 0.0
			spirit_state[i] = 1
			fan_spawned += 1
	for i in range(8):
		if spirit_state[i] == 0:
			continue
		spirit_age[i] += delta
		match spirit_state[i]:
			1:
				spirit_points[i] = spirit_points[i].move_toward(spirit_destinations[i],DATA.SPIRIT_THROW_SPEED*delta)
				if spirit_points[i].distance_squared_to(spirit_destinations[i]) < 1.0:
					spirit_state[i] = 2
					spirit_age[i] = 0.0
			2:
				spirit_points[i] = spirit_destinations[i] + Vector2(sin(spirit_age[i]*2.0+i)*22.0,cos(spirit_age[i]*1.6+i)*16.0)
				var radius := DATA.SPIRIT_DETECTION_RADIUS*(1.8 if transcend_level >= 2 else 1.0)
				if is_instance_valid(hero) and hero.current_hp > 0 and spirit_points[i].distance_squared_to(hero.global_position) <= radius*radius:
					spirit_state[i] = 3
				elif spirit_age[i] >= 5.0:
					spirit_state[i] = 0
			3:
				if not is_instance_valid(hero) or hero.current_hp <= 0 or spirit_age[i] >= 5.0:
					spirit_state[i] = 0
					continue
				spirit_points[i] = spirit_points[i].move_toward(hero.global_position,DATA.SPIRIT_DASH_SPEED*delta)
				if spirit_points[i].distance_squared_to(hero.global_position) < 16.0*16.0:
					_hit(1.2,true)
					_status("stun",0.0,1.5,true,spirit_actions[i])
					spirit_state[i] = 4
					spirit_age[i] = 0.0
			4:
				if spirit_age[i] >= 0.5:
					spirit_state[i] = 0

func _create_torii() -> void:
	if dying or current_hp <= 0:
		return
	var point := global_position
	if is_instance_valid(combat_authority) and combat_authority.has_method("_ensure_monster_spatial_grid"):
		combat_authority._ensure_monster_spatial_grid()
		var largest := 0
		# One pass over already built spatial buckets; no all-pairs neighbor search.
		for cell in combat_authority.monster_spatial_used_cells:
			var bucket: Array = combat_authority.monster_spatial_grid[cell]
			if bucket.size() > largest:
				largest = bucket.size()
				var sum := Vector2.ZERO
				for ally in bucket:
					sum += ally.global_position
				point = sum/float(largest)
	for id in crossing_records:
		crossing_records[id].seen[torii_next] = -1.0
	torii_points[torii_next] = point
	torii_age[torii_next] = 0.0
	torii_next = (torii_next+1)%DATA.TORII_CAPACITY
	var total := int(get_meta("support_shield_hp",0)) + int(round(max_hp*DATA.TORII_SHIELD_RATIO))
	set_meta("support_shield_hp",total)
	set_meta("support_shield_capacity",total)
	status_layer.queue_redraw()
	torii_layer.queue_redraw()

func torii_duration() -> float:
	return 15.0 if transcend_level >= 4 else 10.0

func _tick_torii(delta: float) -> void:
	prune_tick -= delta
	if prune_tick <= 0.0:
		prune_tick = 1.0
		stale_crossing_ids.clear()
		for id in crossing_records:
			if crossing_records[id].reference.get_ref() == null:
				stale_crossing_ids.append(id)
		for id in stale_crossing_ids:
			crossing_records.erase(id)
	for i in range(DATA.TORII_CAPACITY):
		if torii_age[i] >= 0.0:
			torii_age[i] += delta
			if torii_age[i] > torii_duration()+0.8:
				torii_age[i] = -1.0
	aura_tick -= delta
	if transcend_level < 5 or aura_tick > 0.0:
		return
	aura_tick = 0.1
	if not is_instance_valid(combat_authority) or not combat_authority.has_method("fill_local_monsters_in_rect"):
		return
	for i in range(DATA.TORII_CAPACITY):
		if torii_age[i] < 0.0 or torii_age[i] > torii_duration():
			continue
		local_allies.clear()
		combat_authority.fill_local_monsters_in_rect(Rect2(torii_points[i]-Vector2(210,210),Vector2(420,420)),local_allies)
		for ally in local_allies:
			if not is_instance_valid(ally) or ally.current_hp <= 0:
				continue
			var id: int = ally.get_instance_id()
			if not crossing_records.has(id):
				crossing_records[id] = {"reference":weakref(ally),"positions":PackedVector2Array([ally.global_position,ally.global_position,ally.global_position,ally.global_position]),"seen":PackedFloat32Array([-1.0,-1.0,-1.0,-1.0]),"speed":0.0,"guard":0.0}
			var record: Dictionary = crossing_records[id]
			var before: Vector2 = record.positions[i]-torii_points[i]
			var after: Vector2 = ally.global_position-torii_points[i]
			# Cross the opening's horizontal ground line, within its 175px half-width.
			if record.seen[i] >= 0.0 and clock-record.seen[i] <= 0.25 and before.y*after.y < 0.0 and absf(after.x) <= 175.0:
				record.speed = clock+5.0
				record.guard = clock+1.0
			record.positions[i] = ally.global_position
			record.seen[i] = clock

func aura_modifier(actor: Node2D, kind: String) -> float:
	if dying or current_hp <= 0 or not is_instance_valid(actor):
		return 1.0
	var enemy := actor == hero
	var inside := false
	for i in range(DATA.TORII_CAPACITY):
		if torii_age[i] >= 0.0 and torii_age[i] <= torii_duration() and actor.global_position.distance_squared_to(torii_points[i]) <= 175.0*175.0:
			inside = true
	var record = crossing_records.get(actor.get_instance_id(),null)
	match kind:
		"outgoing": return (0.85 if enemy else 1.15) if inside else 1.0
		"incoming":
			if not enemy and record != null and float(record.guard) > clock:
				return 0.3
			return (1.2 if enemy else (0.6 if transcend_level >= 4 else 0.8)) if inside else 1.0
		"speed": return 1.4 if not enemy and record != null and float(record.speed) > clock else 1.0
	return 1.0

func _begin_death() -> void:
	_begin_izanami_death()

func supports_damage_receipt() -> bool:
	return get_script().resource_path == "res://src/monsters/izanami.gd"

func _begin_death_with_result(receipt = null, receipt_revision: int = 0) -> void:
	_begin_izanami_death(receipt, receipt_revision)

func _begin_izanami_death(receipt = null, receipt_revision: int = 0) -> void:
	ghost_remaining = 0.0
	fan_remaining = 0.0
	fire_age.fill(-1.0)
	spirit_state.fill(0)
	torii_age.fill(-1.0)
	set_meta("support_shield_hp",0)
	crossing_records.clear()
	if is_instance_valid(hero) and hero.accepted_damage_hit.is_connected(_on_accepted_hit):
		hero.accepted_damage_hit.disconnect(_on_accepted_hit)
	effect_layer.queue_redraw()
	torii_layer.queue_redraw()
	super._begin_death_with_result(receipt, receipt_revision)

func _draw() -> void:
	if is_instance_valid(status_layer):
		status_layer.queue_redraw()

func _draw_status() -> void:
	if dying:
		return
	var y := visual_head_y-17.0
	var shield := float(get_meta("support_shield_hp",0))
	if shield > 0.0:
		status_layer.draw_rect(Rect2(-29,y-13,58*minf(shield/maxf(float(get_meta("support_shield_capacity",shield)),1.0),1.0),4),Color(0.35,0.75,1.0))
	status_layer.draw_rect(Rect2(-29,y,58,6),Color(0.12,0.12,0.14))
	status_layer.draw_rect(Rect2(-29,y,58*float(current_hp)/maxf(max_hp,1.0),6),Color(0.3,0.9,0.45))
	status_layer.draw_rect(Rect2(-29,y-7,58,4),Color(0.15,0.12,0.03))
	status_layer.draw_rect(Rect2(-29,y-7,58*gauge/100.0,4),Color(1.0,0.8,0.15))

func _draw_effects() -> void:
	if dying:
		return
	if is_instance_valid(hero):
		var point := hero.global_position-global_position
		if ghost_remaining > 0.0:
			var factor := float(DATA.EFFECT_HEIGHTS[0])/DATA.EFFECT_CANVASES[0].y
			var attachment := _target_body_point()+(DATA.EFFECT_ANCHORS[0]-DATA.GHOST_VISIBLE_CENTER)*factor
			FX.draw_frame(effect_layer,0,int(clock*7.0)%2,attachment)
		if bind_remaining > 0.0:
			FX.draw_frame(effect_layer,0,2+int((0.6-bind_remaining)*10.0),point)
	for i in range(4):
		if fire_age[i] < 0.0:
			continue
		var point := fire_points[i]-global_position
		if fire_age[i] < fire_delay[i]:
			effect_layer.draw_arc(point,fire_radius(),0,TAU,48,Color(0.8,0.55,1,0.9),1.5,false)
		else:
			var age := fire_age[i]-fire_delay[i]
			FX.draw_frame(effect_layer,1,mini(6,int(age*14.0)) if age < 0.5 else 5+int(age*7.0)%2,point,fire_radius()/90.0)
	for i in range(8):
		if spirit_state[i] == 0:
			continue
		var point := spirit_points[i]-global_position
		FX.draw_frame(effect_layer,2,3+mini(4,int(spirit_age[i]*10.0)) if spirit_state[i] == 4 else int(spirit_age[i]*8.0)%3,point)
		if spirit_state[i] == 2:
			var bar_y := (DATA.SPIRIT_VISIBLE_TOP-DATA.EFFECT_ANCHORS[2].y)*float(DATA.EFFECT_HEIGHTS[2])/DATA.EFFECT_CANVASES[2].y-DATA.SPIRIT_BAR_GAP
			effect_layer.draw_rect(Rect2(point+Vector2(-15,bar_y),Vector2(30,3)),Color(0.1,0.1,0.16))
			effect_layer.draw_rect(Rect2(point+Vector2(-15,bar_y),Vector2(30*(1.0-spirit_age[i]/5.0),3)),Color(0.7,0.5,1.0))

func _draw_torii() -> void:
	if dying:
		return
	for i in range(DATA.TORII_CAPACITY):
		if torii_age[i] < 0.0:
			continue
		var point := torii_points[i]-global_position
		var frame := mini(7,int(torii_age[i]*10.0))
		if torii_age[i] > torii_duration():
			frame = maxi(0,7-int((torii_age[i]-torii_duration())*10.0))
		var factor := float(DATA.EFFECT_HEIGHTS[3])/DATA.EFFECT_CANVASES[3].y
		var ground_aligned := point+(DATA.EFFECT_ANCHORS[3]-DATA.TORII_GROUND_CENTER)*factor
		FX.draw_frame(torii_layer,3,frame,ground_aligned)
		if torii_age[i] <= torii_duration():
			torii_layer.draw_arc(point,175.0,0,TAU,64,Color(0.7,0.4,0.95,0.5),1.0,false)
