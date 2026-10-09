extends "res://src/monsters/goblin_thrower.gd"
const DATA := preload("res://src/data/shuten_doji_behavior_catalog.gd")
const FX := preload("res://src/ui/shuten_doji_combat_effects.gd")
const AFFLICTIONS := preload("res://src/systems/received_afflictions.gd")
const AUDIO := preload("res://src/data/shuten_doji_audio_catalog.gd")
const SFX_BANK := preload("res://src/audio/event_sfx_bank.gd")
var audio_bank: Node
var transcend_level := 0
var gauge := 0.0
var clock := 0.0
var arrival := DATA.ARRIVAL_SECONDS
var cooldowns := PackedFloat32Array([0,0,0])
var released := false
var revival_used := false
var revival_remaining := 0.0
var revival_heal_fraction := 0.0
var basic_hits := 0
var attack_remaining := 0.0
var attack_hit := false
var attack_point := Vector2.ZERO
var fog_cast_age := -1.0
var fog_cast_spawned := 0
var fog_cast_total := 12
var fog_cast_center := Vector2.ZERO
var action_serial := 0
var fog_cast_action := 0
var credited_actions: Dictionary = {}
var stale_actions: Array[int] = []
var fog_age := PackedFloat32Array()
var fog_life := PackedFloat32Array()
var fog_power := PackedFloat32Array()
var fog_damage := PackedFloat32Array()
var fog_action := PackedInt32Array()
var fog_points := PackedVector2Array()
var blast_age := PackedFloat32Array()
var blast_points := PackedVector2Array()
var chain_age := PackedFloat32Array()
var chain_state := PackedByteArray()
var chain_points := PackedVector2Array()
var chain_targets: Array[WeakRef] = []
var chain_action := PackedInt32Array()
var chain_damage := PackedFloat32Array()
var chain_paid := PackedInt32Array()
var chain_immunity: Dictionary = {}
var nearby_allies: Array = []
var nearby_enemies: Array = []
var records: Dictionary = {}
var stale_records: Array[int] = []
var query_timer := 0.0
var maintenance_timer := 0.0
var self_fog_power := 0.0
var shield_fraction := 0.0
var effect_layer: Node2D
var head_y := -110.0
@onready var status_layer: Node2D = $StatusLayer
func _init() -> void:
	monster_type = "shuten_doji"
	monster_role = "control"
	for key in DATA.BASE: set(key,DATA.BASE[key])
	fog_age.resize(DATA.FOG_CAPACITY)
	fog_age.fill(-1)
	fog_life.resize(DATA.FOG_CAPACITY)
	fog_power.resize(DATA.FOG_CAPACITY)
	fog_damage.resize(DATA.FOG_CAPACITY)
	fog_action.resize(DATA.FOG_CAPACITY)
	fog_points.resize(DATA.FOG_CAPACITY)
	blast_age.resize(DATA.FOG_CAPACITY)
	blast_age.fill(-1)
	blast_points.resize(DATA.FOG_CAPACITY)
	chain_age.resize(DATA.CHAIN_CAPACITY)
	chain_state.resize(DATA.CHAIN_CAPACITY)
	chain_points.resize(DATA.CHAIN_CAPACITY)
	chain_targets.resize(DATA.CHAIN_CAPACITY)
	chain_action.resize(DATA.CHAIN_CAPACITY)
	chain_damage.resize(DATA.CHAIN_CAPACITY)
	chain_paid.resize(DATA.CHAIN_CAPACITY)
func configure_transcendence(_count: int, level: int) -> void:
	transcend_level = clampi(level,0,5)
	# Growth comes from this actor's successful status actions, not DOT ticks.
	max_hp = DATA.BASE.max_hp
	attack_damage = DATA.BASE.attack_damage
	current_hp = max_hp
func _apply_normal_visual_profile() -> void:
	visual.apply_visual_profile(DATA.PROFILE)
	var texture: Texture2D = visual.sprite_frames.get_frame_texture(&"idle",0)
	var bounds := texture.get_image().get_used_rect()
	var factor := 110.0/maxf(bounds.size.y,1)
	visual.scale = Vector2.ONE*factor
	# Authored fixed body-root/ground anchor, shared by all base frames.
	visual.position = -(Vector2(192,260)-texture.get_size()*0.5)*factor
	head_y = visual.position.y+(bounds.position.y-texture.get_height()*0.5)*factor
func _ready() -> void:
	super._ready()
	audio_bank = SFX_BANK.new()
	add_child(audio_bank)
	audio_bank.configure(AUDIO.CUES,combat_authority,true)
	status_layer.z_as_relative = false
	status_layer.z_index = 12
	status_layer.draw.connect(_draw_status)
	effect_layer = Node2D.new()
	effect_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	effect_layer.z_as_relative = false
	effect_layer.z_index = 7
	add_child(effect_layer)
	effect_layer.draw.connect(_draw_effects)
	for kind in range(4): FX.prepare(kind)
func get_gauge_regen() -> float:
	return minf(maxf(float(combat_authority.command_regen_per_second),0),15) if is_instance_valid(combat_authority) else 0.0
func _physics_process(delta: float) -> void:
	if dying or current_hp <= 0: return
	if is_instance_valid(combat_authority) and (combat_authority.battle_over or combat_authority.external_pause or combat_authority.demon_augment_selection_active): return
	clock += delta
	gauge = minf(100,gauge+get_gauge_regen()*delta)
	for i in range(3): cooldowns[i] = maxf(0,cooldowns[i]-delta)
	_refresh_targets(delta)
	_tick_fogs(delta)
	_tick_chains(delta)
	for i in range(DATA.FOG_CAPACITY):
		if blast_age[i] >= 0:
			blast_age[i] += delta
			if blast_age[i] >= 0.8: blast_age[i] = -1
	if revival_remaining > 0:
		_tick_revival(delta)
	elif arrival > 0:
		arrival = maxf(0,arrival-delta)
		velocity = Vector2.RIGHT*move_speed*0.12
		move_and_slide()
		_update_visual_motion(1,true)
	elif is_instance_valid(hero) and hero.current_hp > 0:
		_tick_motion(delta)
	effect_layer.queue_redraw()
	status_layer.queue_redraw()
func _next_action() -> int:
	action_serial += 1
	return action_serial
func _credit_status(action: int) -> void:
	if credited_actions.has(action): return
	credited_actions[action] = clock
	attack_damage += 1
	max_hp += 1
	current_hp += 1
func _record(target: Node2D) -> Dictionary:
	var id := target.get_instance_id()
	if not records.has(id):
		var fractions := PackedFloat32Array()
		fractions.resize(DATA.FOG_CAPACITY)
		records[id] = {"reference":weakref(target),"fractions":fractions}
	return records[id]
func _refresh_targets(delta: float) -> void:
	query_timer -= delta
	maintenance_timer -= delta
	if maintenance_timer <= 0:
		maintenance_timer = 1.0
		stale_records.clear()
		for id in records:
			var target = records[id].reference.get_ref()
			if not is_instance_valid(target) or target.current_hp <= 0 or ("active" in target and not target.active): stale_records.append(id)
		for id in stale_records: records.erase(id)
		stale_actions.clear()
		for id in credited_actions:
			if clock-float(credited_actions[id]) > 60: stale_actions.append(id)
		for id in stale_actions: credited_actions.erase(id)
		stale_actions.clear()
		for id in chain_immunity:
			if float(chain_immunity[id]) <= clock: stale_actions.append(id)
		for id in stale_actions: chain_immunity.erase(id)
	if query_timer > 0: return
	query_timer = 0.2
	if is_instance_valid(combat_authority):
		nearby_allies.clear()
		var area := Rect2(global_position-Vector2.ONE*450,Vector2.ONE*900)
		for i in range(DATA.FOG_CAPACITY):
			if fog_age[i] >= 0: area = area.merge(Rect2(fog_points[i]-Vector2.ONE*150,Vector2.ONE*300))
		if combat_authority.has_method("fill_local_monsters_in_rect"): combat_authority.fill_local_monsters_in_rect(area,nearby_allies)
		if combat_authority.has_method("fill_active_enemy_summons"): combat_authority.fill_active_enemy_summons(nearby_enemies)
func _tick_motion(delta: float) -> void:
	var direction: Vector2 = hero.global_position-global_position
	if bool(get_meta("stun_active",false)) or MONSTER_RUNTIME_COMMON.is_forced_movement_locked(self):
		velocity = Vector2.ZERO
		attack_remaining = 0
		visual.show()
		return
	if attack_remaining > 0:
		attack_remaining = maxf(0,attack_remaining-delta)
		if not attack_hit and attack_remaining <= 0.30:
			attack_hit = true
			if direction.length_squared() <= pow(attack_range+30,2) and _damage(hero,attack_damage,false):
				_audio("hit")
				_on_basic_hit()
		if attack_remaining <= 0:
			if released: _spawn_fog(global_position,15,0.5,_next_action())
			visual.show()
			visual.play(&"idle")
			attack_timer = attack_cooldown
		return
	if bool(get_meta("stun_active",false)) or MONSTER_RUNTIME_COMMON.is_forced_movement_locked(self):
		velocity = Vector2.ZERO
		return
	if not bool(get_meta("silence_active",false)):
		_try_cast()
	attack_timer = maxf(0,attack_timer-delta)
	if direction.length_squared() > attack_range*attack_range:
		velocity = direction.normalized()*move_speed*(1-self_fog_power*0.8)*MONSTER_RUNTIME_COMMON.get_external_movement_multiplier(self)
		move_and_slide()
		_update_visual_motion(direction.x,true)
	else:
		velocity = Vector2.ZERO
		_update_visual_motion(direction.x,false)
		if attack_timer <= 0:
			_audio("swing")
			attack_remaining = 0.6
			attack_hit = false
			attack_point = global_position
			if released: visual.hide()
			else: visual.play_attack()
func _on_basic_hit() -> void:
	basic_hits += 1
	if released:
		for i in range(3): cooldowns[i] = maxf(0,cooldowns[i]-1)
		current_hp = mini(max_hp,current_hp+int(round((max_hp-current_hp)*0.01)))
		if basic_hits >= 20:
			basic_hits = 0
			_apply_stun(hero,2.5,_next_action())
			if transcend_level >= 4: _add_shield(max_hp*0.05)
func _try_cast() -> void:
	var sum_remaining := 0.0
	var active := 0
	for i in range(DATA.FOG_CAPACITY):
		if fog_age[i] < 0: continue
		sum_remaining += fog_life[i]-fog_age[i]
		active += 1
	if active > 0 and fog_cast_age < 0 and sum_remaining <= DATA.BLAST_THRESHOLD:
		_ignite()
	if hero.global_position.distance_squared_to(global_position) > DATA.CAST_RANGE*DATA.CAST_RANGE: return
	if cooldowns[0] <= 0 and gauge >= 30 and fog_cast_age < 0:
		_cast_fog()
	elif cooldowns[2] <= 0 and gauge >= 20:
		_cast_chain(hero)
func _cast_fog() -> void:
	_audio("mist")
	gauge -= 30
	cooldowns[0] = 20
	fog_cast_age = 0
	fog_cast_spawned = 0
	fog_cast_total = 19 if transcend_level >= 2 else 12
	fog_cast_center = global_position
	fog_cast_action = _next_action()
func _spawn_fog(point: Vector2, life: float, power: float, action: int) -> bool:
	for i in range(DATA.FOG_CAPACITY):
		if fog_age[i] >= 0: continue
		fog_age[i] = 0
		fog_points[i] = point
		fog_life[i] = life
		fog_power[i] = power
		fog_damage[i] = attack_damage*power
		fog_action[i] = action
		for id in records: records[id].fractions[i] = 0
		return true
	return false
func _tick_fogs(delta: float) -> void:
	if fog_cast_age >= 0:
		fog_cast_age += delta
		var needed := mini(fog_cast_total,int(floor(fog_cast_age/DATA.FOG_CAST_SECONDS*fog_cast_total)))
		while fog_cast_spawned < needed:
			var index := fog_cast_spawned
			var angle := index*2.3999632297
			var radius := sqrt((index+0.5)/fog_cast_total)*DATA.FOG_SPREAD
			_spawn_fog(fog_cast_center+Vector2.RIGHT.rotated(angle)*radius,randf_range(DATA.FOG_LIFE_MIN,DATA.FOG_LIFE_MAX),1,fog_cast_action)
			fog_cast_spawned += 1
		if fog_cast_spawned >= fog_cast_total: fog_cast_age = -1
	self_fog_power = 0
	for i in range(DATA.FOG_CAPACITY):
		if fog_age[i] < 0: continue
		var step := minf(delta,fog_life[i]-fog_age[i])
		fog_age[i] += delta
		if global_position.distance_squared_to(fog_points[i]) <= DATA.FOG_RADIUS*DATA.FOG_RADIUS:
			self_fog_power = maxf(self_fog_power,fog_power[i])
		_apply_fog(hero,i,step)
		for target in nearby_allies:
			if target != self: _apply_fog(target,i,step)
		for target in nearby_enemies: _apply_fog(target,i,step)
		if fog_age[i] >= fog_life[i]: fog_age[i] = -1
	if transcend_level >= 1 and self_fog_power > 0:
		shield_fraction += max_hp*0.02*self_fog_power*delta
		var amount := int(floor(shield_fraction))
		if amount > 0:
			shield_fraction -= amount
			_add_shield(amount)
func _apply_fog(target: Node2D, index: int, step: float) -> void:
	if not is_instance_valid(target) or target.current_hp <= 0 or ("active" in target and not target.active): return
	if target.global_position.distance_squared_to(fog_points[index]) > DATA.FOG_RADIUS*DATA.FOG_RADIUS: return
	var record := _record(target)
	record.fractions[index] += fog_damage[index]*step/fog_life[index]
	var amount := int(floor(float(record.fractions[index])))
	if amount > 0:
		record.fractions[index] -= amount
		_damage(target,amount,true,true)
	if target.current_hp > 0 and AFFLICTIONS.apply_slow(target,1-0.5*fog_power[index],0.3): _credit_status(fog_action[index])
func _ignite() -> void:
	_audio("ignite")
	var action := _next_action()
	var count := 0
	for i in range(DATA.FOG_CAPACITY):
		if fog_age[i] < 0: continue
		count += 1
		blast_age[i] = 0
		blast_points[i] = fog_points[i]
		_blast_target(hero,fog_points[i],action)
		for target in nearby_allies:
			if target != self: _blast_target(target,fog_points[i],action)
		for target in nearby_enemies: _blast_target(target,fog_points[i],action)
		fog_age[i] = -1
	cooldowns[0] = maxf(0,cooldowns[0]-count*2)
	self_fog_power = 0
func _blast_target(target: Node2D, point: Vector2, action: int) -> void:
	if not is_instance_valid(target) or target.current_hp <= 0 or ("active" in target and not target.active) or target.global_position.distance_squared_to(point) > DATA.BLAST_RADIUS*DATA.BLAST_RADIUS: return
	var bleeding := bool(target.get_meta("bleed_active",false))
	_damage(target,int(round(attack_damage*1.75)),true)
	if bleeding: _apply_stun(target,2,action)
	elif target.current_hp > 0:
		if AFFLICTIONS.apply_bleed_current(target,7,0.06,self): _credit_status(action)
func _apply_stun(target: Node2D, seconds: float, action: int) -> void:
	if target.current_hp <= 0: return
	AFFLICTIONS.apply_stun(target,seconds)
	_credit_status(action)
func _cast_chain(target: Node2D) -> bool:
	for i in range(DATA.CHAIN_CAPACITY):
		if chain_state[i] != 0: continue
		_audio("chain")
		gauge -= 20
		cooldowns[2] = 60
		chain_state[i] = 1
		chain_age[i] = 0
		chain_points[i] = global_position+Vector2(0,-30)
		chain_targets[i] = weakref(target)
		chain_action[i] = _next_action()
		chain_damage[i] = attack_damage*2.5
		chain_paid[i] = 0
		return true
	return false
func _tick_chains(delta: float) -> void:
	for i in range(DATA.CHAIN_CAPACITY):
		if chain_state[i] == 0: continue
		var target = chain_targets[i].get_ref()
		if not is_instance_valid(target) or target.current_hp <= 0 or ("active" in target and not target.active):
			chain_state[i] = 0
			continue
		chain_age[i] += delta
		if chain_state[i] == 1:
			if chain_age[i] > DATA.CHAIN_MAX_SECONDS:
				chain_state[i] = 0
				continue
			chain_points[i] = chain_points[i].move_toward(target.global_position+Vector2(0,-30),DATA.CHAIN_SPEED*delta)
			if chain_points[i].distance_squared_to(target.global_position+Vector2(0,-30)) <= 18*18:
				_bind_chain(i,target)
			elif chain_age[i] > DATA.CHAIN_MAX_SECONDS: chain_state[i] = 0
		else:
			var total := int(round(chain_damage[i]*minf(chain_age[i]/3,1)))
			var amount := total-chain_paid[i]
			chain_paid[i] = total
			if amount > 0: _damage(target,amount,true,true)
			if chain_age[i] >= 3: chain_state[i] = 0
func _bind_chain(index: int, target: Node2D) -> bool:
	var id := target.get_instance_id()
	if float(chain_immunity.get(id,0)) > clock:
		chain_state[index] = 0
		return false
	var travel := chain_age[index]
	var refund := 0.5 if transcend_level >= 3 else 0.4 if travel >= 30 else 0.3 if travel >= 20 else 0.2 if travel >= 10 else 0.0
	cooldowns[2] = maxf(0,cooldowns[2]-60*refund)
	_audio("bind")
	chain_immunity[id] = clock+13
	chain_state[index] = 2
	chain_age[index] = 0
	AFFLICTIONS.apply_slow(target,0.01,3)
	AFFLICTIONS.apply_silence(target,3)
	_credit_status(chain_action[index])
	return true
func _damage(target: Node2D, amount: int, followup: bool = true, dot: bool = false) -> bool:
	if not is_instance_valid(target) or target.current_hp <= 0: return false
	if target == hero:
		if dot: return bool(target.take_status_damage(amount,self))
		return bool(target.take_followup_damage(amount,self)) if followup else bool(target.take_damage(amount,self))
	if "monster_type" in target:
		target.take_damage(amount)
		return true
	return bool(target.take_damage(amount,self))
func _add_shield(amount: float) -> void:
	var total := int(get_meta("support_shield_hp",0))+int(round(amount))
	set_meta("support_shield_hp",total)
	set_meta("support_shield_capacity",total)
func take_damage(amount: int) -> void:
	if dying or amount <= 0 or revival_remaining > 0: return
	var reduced := int(round(amount*(1-0.7*self_fog_power)*(0.7 if released and transcend_level >= 4 else 1)))
	var damage := MONSTER_RUNTIME_COMMON.consume_support_shield(self,reduced)
	if damage <= 0: return
	var next_hp := maxi(current_hp-damage,0)
	if not revival_used and (next_hp <= 0 or (transcend_level >= 5 and next_hp <= max_hp*0.5)):
		current_hp = maxi(next_hp,1)
		_start_revival()
		return
	current_hp = next_hp
	DAMAGE_NUMBERS.show(self,damage)
	if current_hp <= 0: _begin_death()
func _start_revival() -> void:
	_audio("release")
	revival_used = true
	revival_remaining = DATA.REVIVAL_SECONDS
	revival_heal_fraction = 0
	attack_remaining = 0
	velocity = Vector2.ZERO
	visual.show()
	visual.stop()
	visual.animation = &"death"
	visual.frame = 2
func _tick_revival(delta: float) -> void:
	var step := minf(delta,revival_remaining)
	revival_remaining = maxf(0,revival_remaining-delta)
	revival_heal_fraction += max_hp*step/DATA.REVIVAL_SECONDS
	var amount := int(floor(revival_heal_fraction))
	revival_heal_fraction -= amount
	var excess := maxi(current_hp+amount-max_hp,0)
	current_hp = mini(max_hp,current_hp+amount)
	if transcend_level >= 5 and excess > 0: _add_shield(excess)
	var age := DATA.REVIVAL_SECONDS-revival_remaining
	if age < 0.45: visual.frame = maxi(0,2-int(age/0.15))
	else: visual.hide()
	if revival_remaining <= 0:
		released = true
		basic_hits = 0
		visual.show()
		visual.play(&"idle")
func _begin_death() -> void:
	if is_instance_valid(effect_layer): effect_layer.hide()
	if is_instance_valid(status_layer): status_layer.hide()
	if is_instance_valid(audio_bank): audio_bank.stop_all()
	fog_age.fill(-1)
	blast_age.fill(-1)
	chain_state.fill(0)
	visual.show()
	super._begin_death()
func on_ally_death(_point: Vector2) -> void: pass
func _draw() -> void:
	if is_instance_valid(status_layer): status_layer.queue_redraw()
func _draw_status() -> void:
	if dying: return
	status_layer.draw_rect(Rect2(-29,head_y-16,58,6),Color("202027"))
	status_layer.draw_rect(Rect2(-29,head_y-16,58*float(current_hp)/max_hp,6),Color("4de873"))
	status_layer.draw_rect(Rect2(-29,head_y-23,58,4),Color("302511"))
	status_layer.draw_rect(Rect2(-29,head_y-23,58*gauge/100,4),Color("ffdb3b"))
	var shield := float(get_meta("support_shield_hp",0))
	if shield > 0: status_layer.draw_rect(Rect2(-29,head_y-29,58*minf(shield/maxf(float(get_meta("support_shield_capacity",shield)),1),1),4),Color("61ddff"))
func _draw_effects() -> void:
	if dying: return
	for i in range(DATA.FOG_CAPACITY):
		if fog_age[i] >= 0:
			var remaining := fog_life[i]-fog_age[i]
			var alpha := 0.5
			if remaining < 1.5: alpha *= 0.35+0.65*absf(sin(8/maxf(remaining,0.15)))
			FX.draw_frame(effect_layer,0,int(fog_age[i]*8)%8,fog_points[i]-global_position,1,alpha)
		if blast_age[i] >= 0: FX.draw_frame(effect_layer,1,mini(7,int(blast_age[i]*10)),blast_points[i]-global_position)
	for i in range(DATA.CHAIN_CAPACITY):
		if chain_state[i] == 0: continue
		var point := chain_points[i]
		var frame := mini(2,int(chain_age[i]*5)) if chain_age[i] < 0.6 else 2+int(chain_age[i]*6)%2
		if chain_state[i] == 2:
			var target = chain_targets[i].get_ref()
			if not is_instance_valid(target): continue
			point = target.global_position+Vector2(0,-30)
			frame = 5+int(chain_age[i]*8)%3
		FX.draw_frame(effect_layer,2,frame,point-global_position)
	if revival_remaining > 0 and DATA.REVIVAL_SECONDS-revival_remaining >= 0.45:
		FX.draw_frame(effect_layer,3,mini(1,int((DATA.REVIVAL_SECONDS-revival_remaining-0.45)*4)),Vector2.ZERO,1,1,visual.flip_h)
	elif attack_remaining > 0 and released:
		FX.draw_frame(effect_layer,3,2+mini(5,int((0.6-attack_remaining)*10)),Vector2.ZERO,1,1,visual.flip_h)


func _audio(cue: String) -> void:
	if is_instance_valid(audio_bank): audio_bank.play_cue(cue)
