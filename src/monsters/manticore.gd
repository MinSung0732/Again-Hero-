extends "res://src/monsters/goblin_thrower.gd"
const DATA := preload("res://src/data/manticore_behavior_catalog.gd")
const FX := preload("res://src/ui/manticore_combat_effects.gd")
const AFFLICTIONS := preload("res://src/systems/received_afflictions.gd")
const CHANNEL := preload("res://src/ui/channel_gauge.gd")
enum Motion { REST, FOCUS, HUNT, COMBO, TRACK }
var motion := Motion.REST
var transcend_level := 0
var summon_snapshot := 0
var gauge := 0.0
var clock := 0.0
var arrival := DATA.ARRIVAL_SECONDS
var arrival_hit := false
var focus := 0.0
var flight_age := 0.0
var destination := Vector2.ZERO
var combo_timer := 0.0
var combo_hits := 0
var combo_accepted := false
var triple := false
var triple_success := false
var basic_hits := 0
var escaped := false
var guard_remaining := 0.0
var flame_remaining := 0.0
var wave_remaining := 0.0
var cooldowns := PackedFloat32Array([0.0,0.0,0.0])
var flame_contact := PackedFloat32Array([0.0,0.0])
var flame_paid := PackedInt32Array([0,0])
var flame_stop := PackedFloat32Array([0.0,0.0])
var meteor_cast := -1.0
var meteor_spawned := 0
var meteor_center := Vector2.ZERO
var meteor_state := PackedInt32Array()
var meteor_age := PackedFloat32Array()
var meteor_points := PackedVector2Array()
var meteor_dest := PackedVector2Array()
var cloud_fraction := PackedFloat32Array()
var wave_age := PackedFloat32Array()
var wave_origin := PackedVector2Array()
var wave_direction := PackedVector2Array()
var wave_length := PackedFloat32Array()
var wave_hit := PackedByteArray()
var cloud_frames: Array[Texture2D] = []
var local_allies: Array = []
var other_enemies: Array = []
var enemy_records: Dictionary = {}
var stale_enemy_ids: Array[int] = []
var enemy_refresh := 0.0
var channel_right := 42.0
var channel_left := 42.0
var visual_head_y := -110.0
var effect_layer: Node2D
@onready var status_layer: Node2D = $StatusLayer
func _init() -> void:
	monster_type = "manticore"
	monster_role = "exploder"
	for stat in DATA.BASE:
		set(stat,DATA.BASE[stat])
	meteor_state.resize(10)
	meteor_age.resize(10)
	meteor_points.resize(10)
	meteor_dest.resize(10)
	cloud_fraction.resize(10)
	wave_age.resize(DATA.WAVE_CAPACITY)
	wave_age.fill(-1.0)
	wave_origin.resize(DATA.WAVE_CAPACITY)
	wave_direction.resize(DATA.WAVE_CAPACITY)
	wave_length.resize(DATA.WAVE_CAPACITY)
	wave_hit.resize(DATA.WAVE_CAPACITY)
func configure_transcendence(count: int, level: int) -> void:
	summon_snapshot = maxi(count,0)
	transcend_level = clampi(level,0,5)
	max_hp = int(round(1550.0+summon_snapshot*0.5))
	attack_damage = int(round(35.0+summon_snapshot*0.075))
	current_hp = max_hp
func _apply_normal_visual_profile() -> void:
	visual.apply_visual_profile(DATA.PROFILE)
	var texture: Texture2D = visual.sprite_frames.get_frame_texture(&"idle",0)
	var bounds := texture.get_image().get_used_rect()
	var factor := 110.0/maxf(float(bounds.size.y),1.0)
	visual.scale = Vector2.ONE*factor
	visual.position = -(Vector2(bounds.get_center().x,bounds.end.y)-texture.get_size()*0.5)*factor
	visual_head_y = -float(bounds.size.y)*factor
	channel_right = float(bounds.size.x)*factor*0.5+8.0
	channel_left = channel_right
func _ready() -> void:
	super._ready()
	status_layer.z_as_relative = false
	status_layer.z_index = 12
	status_layer.draw.connect(_draw_status)
	effect_layer = Node2D.new()
	effect_layer.z_as_relative = false
	effect_layer.z_index = 8
	effect_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(effect_layer)
	effect_layer.draw.connect(_draw_effects)
	for kind in range(4): FX.prepare(kind)
	for i in range(1,9):
		cloud_frames.append(load("res://assets/art/monsters/Scorpion/frames/effect1/effect_%02d.png"%i))
	visual.modulate.a = 0.0
func get_gauge_regen() -> float:
	return minf(maxf(float(combat_authority.command_regen_per_second),0.0),15.0) if is_instance_valid(combat_authority) else 0.0
func effective_range() -> float:
	# All named basic ranges are diameters; +50 is therefore +25 radius.
	return DATA.BASE.attack_range+(25.0 if transcend_level >= 4 and flame_remaining > 0.0 else 0.0)
func wave_range() -> float:
	# Explicit skill travel distance 680 overrides the basic diameter 650.
	return DATA.WAVE_RANGE+(50.0 if transcend_level >= 4 and flame_remaining > 0.0 else 0.0)
func wave_speed() -> float:
	return DATA.WAVE_SPEED+(50.0 if transcend_level >= 5 else 0.0)
func wave_duration() -> float:
	return DATA.WAVE_SECONDS*(1.5 if transcend_level >= 5 else 1.0)
func flame_count() -> int: return 2 if transcend_level >= 1 else 1
func flame_cost() -> float: return 25.0 if transcend_level >= 4 else 50.0
func _physics_process(delta: float) -> void:
	if dying or current_hp <= 0: return
	if is_instance_valid(combat_authority) and (combat_authority.battle_over or combat_authority.external_pause or combat_authority.demon_augment_selection_active): return
	clock += delta
	gauge = minf(100.0,gauge+get_gauge_regen()*delta)
	guard_remaining = maxf(guard_remaining-delta,0.0)
	wave_remaining = maxf(wave_remaining-delta,0.0)
	for i in range(3): cooldowns[i] = maxf(cooldowns[i]-delta,0.0)
	_refresh_other_enemies(delta)
	_tick_meteors(delta)
	_tick_waves(delta)
	_tick_flames(delta)
	_tick_other_enemies(delta)
	if arrival > 0.0:
		arrival = maxf(arrival-delta,0.0)
		if not arrival_hit:
			arrival_hit = true
			_arrival_explosion()
		visual.modulate.a = smoothstep(0.25,DATA.ARRIVAL_SECONDS,DATA.ARRIVAL_SECONDS-arrival)
	else:
		if is_instance_valid(hero) and hero.current_hp > 0:
			_try_cast()
			_tick_motion(delta)
		else:
			_end_motion()
	effect_layer.queue_redraw()
	status_layer.queue_redraw()
func _try_cast() -> void:
	if bool(get_meta("silence_active",false)) or bool(get_meta("stun_active",false)): return
	if global_position.distance_squared_to(hero.global_position) > wave_range()*wave_range(): return
	for i in range(3):
		var cost := flame_cost() if i == 0 else float(DATA.COSTS[i])
		if cooldowns[i] > 0.0 or gauge < cost: continue
		gauge -= cost
		cooldowns[i] = DATA.COOLDOWNS[i]
		match i:
			0:
				flame_remaining = DATA.FLAME_SECONDS
				flame_contact.fill(0.0)
				flame_paid.fill(0)
			1:
				meteor_cast = 0.0
				meteor_spawned = 0
				meteor_center = hero.global_position
			2: wave_remaining = wave_duration()
		return
func _tick_motion(delta: float) -> void:
	var offset := hero.global_position-global_position
	var direction := offset.normalized() if offset.length_squared() > 0.001 else Vector2.RIGHT
	if MONSTER_RUNTIME_COMMON.is_forced_movement_locked(self) or bool(get_meta("stun_active",false)):
		if motion == Motion.FOCUS: _end_motion()
		velocity = Vector2.ZERO
		return
	match motion:
		Motion.REST:
			attack_timer = maxf(attack_timer-delta,0.0)
			var radius := wave_range() if wave_remaining > 0.0 else effective_range()
			if offset.length_squared() > radius*radius:
				velocity = direction*move_speed*MONSTER_RUNTIME_COMMON.get_external_movement_multiplier(self)
				move_and_slide()
				_update_visual_motion(direction.x,true)
			else:
				velocity = Vector2.ZERO
				_update_visual_motion(direction.x,false)
				if attack_timer <= 0.0:
					if wave_remaining > 0.0: _shoot_wave(direction)
					else:
						motion = Motion.FOCUS
						focus = DATA.CHANNEL_SECONDS
		Motion.FOCUS:
			if bool(get_meta("silence_active",false)):
				_end_motion()
				return
			focus = maxf(focus-delta,0.0)
			if focus <= 0.0:
				motion = Motion.HUNT
				flight_age = 0.0
				_begin_flight()
		Motion.HUNT:
			flight_age += delta
			_face_flight(direction,0)
			var step := projectile_speed*delta
			if offset.length() <= step+16.0:
				global_position = hero.global_position-direction*16.0
				motion = Motion.COMBO
				combo_hits = 0
				combo_accepted = false
				combo_timer = 0.0
				triple = bool(hero.get_meta("bleed_active",false))
				triple_success = true
			else:
				global_position += direction*step
			MONSTER_RUNTIME_COMMON.notify_forced_position_change(self)
			if flight_age >= 5.0: _end_motion()
		Motion.COMBO:
			combo_timer -= delta
			if combo_timer <= 0.0:
				var accepted := _hit(0.5 if combo_hits == 2 else 1.0,combo_hits > 0)
				combo_accepted = combo_accepted or accepted
				triple_success = triple_success and accepted
				combo_hits += 1
				if accepted and combo_hits <= 2:
					_register_basic_hit()
					triple = triple or bool(hero.get_meta("bleed_active",false))
				combo_timer = DATA.COMBO_INTERVAL
				if combo_hits >= (3 if triple else 2):
					if triple and triple_success: _add_shield(0.04)
					if combo_accepted: _start_track(effective_range())
					else: _end_motion()
		Motion.TRACK:
			var retreat := destination-global_position
			_face_flight(retreat.normalized(),3)
			global_position = global_position.move_toward(destination,projectile_speed*delta)
			MONSTER_RUNTIME_COMMON.notify_forced_position_change(self)
			if global_position.distance_squared_to(destination) < 0.01: _end_motion()
func _begin_flight() -> void:
	collision_mask = 0
	set_meta("ignore_monster_separation",true)
	visual.stop()
	visual.animation = &"attack"
func _face_flight(direction: Vector2, frame_start: int) -> void:
	visual.flip_h = direction.x < 0.0
	visual.frame = frame_start+int(clock*10.0)%3
func _start_track(distance: float) -> void:
	var away := (global_position-hero.global_position).normalized()
	if away.length_squared() < 0.01: away = Vector2.LEFT
	destination = _clamp_destination(global_position+away*distance)
	motion = Motion.TRACK
	_begin_flight()
func _end_motion() -> void:
	motion = Motion.REST
	collision_mask = 3
	set_meta("ignore_monster_separation",false)
	attack_timer = attack_cooldown/(1.5 if transcend_level >= 5 and wave_remaining > 0.0 else 1.0)
	if not dying: visual.play(&"idle")
func _hit(ratio: float, followup: bool = false) -> bool:
	if not is_instance_valid(hero) or hero.current_hp <= 0: return false
	var damage := maxi(int(round(attack_damage*ratio)),1)
	return bool(hero.take_followup_damage(damage,self)) if followup else bool(hero.take_damage(damage,self))
func _register_basic_hit() -> void:
	basic_hits += 1
	if basic_hits >= (4 if transcend_level >= 2 else 5):
		if hero.apply_bleed(10.0,self,0.03,transcend_level >= 2): basic_hits = 0
func _add_shield(ratio: float) -> void:
	var total := int(get_meta("support_shield_hp",0))+int(round(max_hp*ratio))
	set_meta("support_shield_hp",total)
	set_meta("support_shield_capacity",total)
func take_damage(amount: int) -> void:
	if dying or amount <= 0: return
	var damage := MONSTER_RUNTIME_COMMON.consume_support_shield(self,int(round(amount*(0.6 if guard_remaining > 0.0 else 1.0))))
	if damage <= 0: return
	if damage >= current_hp and not escaped:
		escaped = true
		current_hp = maxi(int(round(max_hp*0.15)),1)
		if transcend_level >= 3:
			guard_remaining = 5.0
			_add_shield(0.2)
		if is_instance_valid(hero): _start_track(effective_range()*2.0)
		return
	current_hp = maxi(current_hp-damage,0)
	DAMAGE_NUMBERS.show(self,damage)
	if current_hp <= 0: _begin_death()
func on_ally_death(_point: Vector2) -> void: pass
func _arrival_explosion() -> void:
	_refresh_other_enemies(1.0)
	var radius := DATA.ARRIVAL_RADIUS
	if is_instance_valid(hero) and global_position.distance_squared_to(hero.global_position) <= radius*radius: _hit(1.35)
	for enemy in other_enemies:
		if global_position.distance_squared_to(enemy.global_position) <= radius*radius:
			enemy.take_damage(maxi(int(round(attack_damage*1.35)),1),self)
	if is_instance_valid(combat_authority) and combat_authority.has_method("fill_local_monsters_in_rect"):
		local_allies.clear()
		combat_authority.fill_local_monsters_in_rect(Rect2(global_position-Vector2.ONE*radius,Vector2.ONE*radius*2.0),local_allies)
		for ally in local_allies:
			if is_instance_valid(ally) and ally != self and ally.current_hp > 0 and global_position.distance_squared_to(ally.global_position) <= radius*radius:
				ally.take_damage(maxi(int(round(attack_damage*1.35)),1))
func _flame_point(index: int) -> Vector2:
	return global_position+Vector2(-38.0 if index == 0 else 38.0,-30.0)
func _flame_direction(index: int) -> Vector2:
	if not is_instance_valid(hero): return Vector2.RIGHT
	var offset := hero.global_position-_flame_point(index)
	return offset.normalized() if offset.length_squared() > 0.001 else Vector2.RIGHT
func _flame_inside(index: int) -> bool:
	if not is_instance_valid(hero) or hero.current_hp <= 0: return false
	var offset := hero.global_position-_flame_point(index)
	# Flame is a narrow cone, not a circular invisible damage aura.
	var direction := _flame_direction(index)
	var along := offset.dot(direction)
	var across := absf(offset.cross(direction))
	return along >= 25.0 and along <= DATA.FLAME_RADIUS and across <= 14.0+along*0.28
func _tick_flames(delta: float) -> void:
	if flame_remaining <= 0.0: return
	var step := minf(delta,flame_remaining)
	flame_remaining = maxf(flame_remaining-delta,0.0)
	for i in range(flame_count()):
		if not _flame_inside(i):
			if flame_contact[i] > 0.0: flame_stop[i] = 0.3
			flame_contact[i] = 0.0
			flame_paid[i] = 0
			flame_stop[i] = maxf(flame_stop[i]-delta,0.0)
			continue
		flame_contact[i] += step
		var total := int(round(attack_damage*flame_contact[i]))
		var amount := total-flame_paid[i]
		flame_paid[i] = total
		if amount > 0: hero.take_status_damage(amount,self)
		if flame_contact[i] >= 1.0:
			hero.apply_burn(1.0,maxi(int(round(attack_damage*0.75)),1),self)
			flame_contact[i] -= 1.0
			flame_paid[i] -= attack_damage
func _tick_meteors(delta: float) -> void:
	if meteor_cast >= 0.0:
		meteor_cast += delta
		var needed := mini(10,int(meteor_cast/0.2))
		while meteor_spawned < needed:
			var i := meteor_spawned
			meteor_dest[i] = meteor_center+Vector2.RIGHT.rotated(randf()*TAU)*sqrt(randf())*DATA.METEOR_SCATTER
			meteor_points[i] = global_position+Vector2(0,-70)
			meteor_age[i] = 0.0
			meteor_state[i] = 1
			cloud_fraction[i] = 0.0
			meteor_spawned += 1
		if meteor_spawned >= 10: meteor_cast = -1.0
	for i in range(10):
		if meteor_state[i] == 0: continue
		meteor_age[i] += delta
		if meteor_state[i] == 1:
			meteor_points[i] = meteor_points[i].move_toward(meteor_dest[i],DATA.METEOR_SPEED*delta)
			if meteor_points[i].distance_squared_to(meteor_dest[i]) < 0.01:
				meteor_state[i] = 2
				meteor_age[i] = 0.0
				for enemy in other_enemies:
					if _enemy_in_meteor(enemy,i):
						enemy.take_damage(maxi(int(round(attack_damage*1.75)),1),self)
						AFFLICTIONS.apply_poison(enemy,3.0,int(round(attack_damage*2.0)),self,70)
				if _inside_meteor(i):
					_hit(1.75,true)
					hero.apply_damage_poison(3.0,int(round(attack_damage*2.0)),self,70)
		else:
			if _inside_meteor(i):
				var active_step := minf(delta,maxf(2.0-(meteor_age[i]-delta),0.0))
				cloud_fraction[i] += hero.current_hp*0.03*active_step
				var amount := int(floor(cloud_fraction[i]))
				if amount > 0:
					cloud_fraction[i] -= amount
					hero.take_status_damage(amount,self)
			if meteor_age[i] >= 2.0: meteor_state[i] = 0
func _inside_meteor(index: int) -> bool:
	return is_instance_valid(hero) and hero.current_hp > 0 and hero.global_position.distance_squared_to(meteor_dest[index]) <= DATA.METEOR_RADIUS*DATA.METEOR_RADIUS
func _shoot_wave(direction: Vector2) -> void:
	for i in range(DATA.WAVE_CAPACITY):
		if wave_age[i] >= 0.0: continue
		wave_age[i] = 0.0
		wave_origin[i] = global_position
		wave_direction[i] = direction
		wave_length[i] = wave_range()
		wave_hit[i] = 0
		for id in enemy_records: enemy_records[id].wave_mask = int(enemy_records[id].wave_mask) & ~(1 << i)
		_end_motion()
		_visual_call(&"play_attack")
		if transcend_level >= 5:
			destination = _clamp_destination(hero.global_position+Vector2.RIGHT.rotated(randf()*TAU)*wave_range())
			motion = Motion.TRACK
			_begin_flight()
		return
func _tick_waves(delta: float) -> void:
	for i in range(DATA.WAVE_CAPACITY):
		if wave_age[i] < 0.0: continue
		var previous := minf(wave_age[i]*wave_speed(),wave_length[i])
		wave_age[i] += delta
		var distance := minf(wave_age[i]*wave_speed(),wave_length[i])
		if wave_hit[i] == 0 and is_instance_valid(hero) and hero.current_hp > 0:
			var point := Geometry2D.get_closest_point_to_segment(hero.global_position,wave_origin[i]+wave_direction[i]*previous,wave_origin[i]+wave_direction[i]*distance)
			if point.distance_squared_to(hero.global_position) <= DATA.WAVE_WIDTH*DATA.WAVE_WIDTH:
				wave_hit[i] = 1
				if _hit(2.0,true): hero.apply_slow(0.7,3.0)
		if wave_age[i] >= wave_length[i]/wave_speed()+0.5: wave_age[i] = -1.0
func _begin_death() -> void:
	flame_remaining = 0.0
	wave_remaining = 0.0
	meteor_state.fill(0)
	wave_age.fill(-1.0)
	collision_mask = 0
	if is_instance_valid(effect_layer): effect_layer.queue_redraw()
	super._begin_death()
func _draw() -> void:
	if is_instance_valid(status_layer): status_layer.queue_redraw()
func _draw_status() -> void:
	if dying: return
	var y := visual_head_y-17.0
	status_layer.draw_rect(Rect2(-29,y,58,6),Color("202027"))
	status_layer.draw_rect(Rect2(-29,y,58*float(current_hp)/maxf(max_hp,1.0),6),Color("4de873"))
	status_layer.draw_rect(Rect2(-29,y-7,58,4),Color("302511"))
	status_layer.draw_rect(Rect2(-29,y-7,58*gauge/100.0,4),Color("ffdb3b"))
	var shield := float(get_meta("support_shield_hp",0))
	if shield > 0.0: status_layer.draw_rect(Rect2(-29,y-13,58*minf(shield/maxf(float(get_meta("support_shield_capacity",shield)),1.0),1.0),4),Color("61ddff"))
	if motion == Motion.FOCUS: CHANNEL.draw_on(status_layer,Vector2(channel_left if visual.flip_h else channel_right,visual_head_y+20),1.0-focus/DATA.CHANNEL_SECONDS)
func _draw_effects() -> void:
	if dying: return
	if arrival > 0.0: FX.draw_frame(effect_layer,1,2+mini(5,int((DATA.ARRIVAL_SECONDS-arrival)*6.0/DATA.ARRIVAL_SECONDS)),Vector2.ZERO)
	if motion == Motion.HUNT or motion == Motion.TRACK:
		FX.draw_frame(effect_layer,3,(int(clock*12.0)%4)+(4 if motion == Motion.TRACK else 0),Vector2.ZERO)
	if flame_remaining > 0.0:
		for i in range(flame_count()):
			var point := _flame_point(i)-global_position
			var frame := 1+int(clock*12.0)%4 if flame_contact[i] > 0.0 else (5+mini(2,int((0.3-flame_stop[i])*10.0)) if flame_stop[i] > 0.0 else 0)
			FX.draw_oriented(effect_layer,0,frame,point,_flame_direction(i).angle() if is_instance_valid(hero) else 0.0)
	for i in range(10):
		if meteor_state[i] == 0: continue
		var point := meteor_dest[i]-global_position
		if meteor_state[i] == 1:
			effect_layer.draw_arc(point,DATA.METEOR_RADIUS,0,TAU,40,Color("b8ff87"),1.0,false)
			FX.draw_frame(effect_layer,1,int(clock*12.0)%2,meteor_points[i]-global_position,0.45)
		else:
			if meteor_age[i] < 0.6: FX.draw_frame(effect_layer,1,2+mini(5,int(meteor_age[i]*10.0)),point)
			if not cloud_frames.is_empty():
				var texture: Texture2D = cloud_frames[int(clock*8.0)%8]
				var factor := DATA.METEOR_RADIUS*2.0/386.0
				effect_layer.draw_texture_rect(texture,Rect2(point-Vector2(203,341)*factor,texture.get_size()*factor),false,Color(1,1,1,0.6))
	for i in range(DATA.WAVE_CAPACITY):
		if wave_age[i] < 0.0: continue
		var travel := wave_length[i]/wave_speed()
		var distance := minf(wave_age[i]*wave_speed(),wave_length[i])
		var segments := maxi(int(ceil(distance/55.0)),1)
		for segment in range(segments):
			var fade := maxf(wave_age[i]-travel-float(segment)/maxf(segments,1)*0.18,0.0)
			var frame := segment%4 if wave_age[i] < travel else 4+mini(3,int(fade*10.0))
			FX.draw_oriented(effect_layer,2,frame,wave_origin[i]+wave_direction[i]*minf(segment*55.0,distance)-global_position,wave_direction[i].angle())

func _clamp_destination(point: Vector2) -> Vector2:
	return combat_authority.clamp_monster_wander_position(point) if is_instance_valid(combat_authority) and combat_authority.has_method("clamp_monster_wander_position") else point

func _refresh_other_enemies(delta: float) -> void:
	enemy_refresh -= delta
	if enemy_refresh > 0.0: return
	enemy_refresh = 0.25
	if not is_instance_valid(combat_authority) or not combat_authority.has_method("fill_active_enemy_summons"): return
	combat_authority.fill_active_enemy_summons(other_enemies)
	stale_enemy_ids.clear()
	for id in enemy_records:
		var enemy = enemy_records[id].reference.get_ref()
		if not is_instance_valid(enemy) or enemy.current_hp <= 0 or ("active" in enemy and not enemy.active): stale_enemy_ids.append(id)
	for id in stale_enemy_ids: enemy_records.erase(id)
	for enemy in other_enemies:
		var id: int = enemy.get_instance_id()
		if not enemy_records.has(id):
			enemy_records[id] = {"reference":weakref(enemy),"contact":PackedFloat32Array([0,0]),"paid":PackedInt32Array([0,0]),"cloud":PackedFloat32Array([0,0,0,0,0,0,0,0,0,0]),"wave_mask":0}
func _enemy_in_meteor(enemy: Node2D, index: int) -> bool:
	return enemy.global_position.distance_squared_to(meteor_dest[index]) <= DATA.METEOR_RADIUS*DATA.METEOR_RADIUS
func _tick_other_enemies(delta: float) -> void:
	for enemy in other_enemies:
		if not is_instance_valid(enemy) or enemy.current_hp <= 0: continue
		var record: Dictionary = enemy_records[enemy.get_instance_id()]
		for head in range(flame_count()):
			var offset: Vector2 = enemy.global_position-_flame_point(head)
			var direction := _flame_direction(head)
			var along := offset.dot(direction)
			var inside := flame_remaining > 0.0 and along >= 25.0 and along <= DATA.FLAME_RADIUS and absf(offset.cross(direction)) <= 14.0+along*0.28
			if not inside:
				record.contact[head] = 0.0
				record.paid[head] = 0
				continue
			record.contact[head] += delta
			var total := int(round(attack_damage*float(record.contact[head])))
			var amount := total-int(record.paid[head])
			record.paid[head] = total
			if amount > 0: enemy.take_damage(amount,self)
			if float(record.contact[head]) >= 1.0:
				AFFLICTIONS.apply_burn(enemy,1.0,maxi(int(round(attack_damage*0.75)),1),self)
				record.contact[head] -= 1.0
				record.paid[head] -= attack_damage
		for i in range(10):
			if meteor_state[i] != 2 or not _enemy_in_meteor(enemy,i): continue
			record.cloud[i] += enemy.current_hp*0.03*minf(delta,maxf(2.0-meteor_age[i]+delta,0.0))
			var amount := int(floor(float(record.cloud[i])))
			if amount > 0:
				record.cloud[i] -= amount
				enemy.take_damage(amount,self)
		for i in range(DATA.WAVE_CAPACITY):
			if wave_age[i] < 0.0 or (int(record.wave_mask) & (1 << i)) != 0: continue
			var distance := minf(wave_age[i]*wave_speed(),wave_length[i])
			var previous := minf(maxf(wave_age[i]-delta,0.0)*wave_speed(),wave_length[i])
			var point := Geometry2D.get_closest_point_to_segment(enemy.global_position,wave_origin[i]+wave_direction[i]*previous,wave_origin[i]+wave_direction[i]*distance)
			if point.distance_squared_to(enemy.global_position) <= DATA.WAVE_WIDTH*DATA.WAVE_WIDTH:
				record.wave_mask = int(record.wave_mask) | (1 << i)
				enemy.take_damage(maxi(int(round(attack_damage*2.0)),1),self)
				AFFLICTIONS.apply_slow(enemy,0.7,3.0)
