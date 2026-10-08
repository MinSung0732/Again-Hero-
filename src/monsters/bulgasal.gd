extends "res://src/monsters/orc.gd"
const DATA := preload("res://src/data/bulgasal_behavior_catalog.gd")
const FX := preload("res://src/ui/bulgasal_combat_effects.gd")
const PILLARS := preload("res://src/monsters/bulgasal_pillars.gd")
const TARGET_POLICY := preload("res://src/systems/hero_target_policy.gd")
const TELEGRAPH := preload("res://src/ui/circular_attack_telegraph.gd")
const DRAW_LAYER := preload("res://src/ui/bulgasal_combat_draw_layer.gd")
const AUDIO := preload("res://src/data/bulgasal_audio_catalog.gd")
const SFX_BANK := preload("res://src/audio/event_sfx_bank.gd")
var audio_bank: Node
var burrow_phased := false
var burrow_saved_layer := 0
var burrow_saved_mask := 0
var body_radius := 0.0
var fragment_origin := Vector2.ZERO
var fragment_distances := PackedFloat32Array()
var fragment_positions := PackedVector2Array()
var fragment_states := PackedInt32Array() # 0 inactive, 1 flying, 2 bursting
var fragment_ages := PackedFloat32Array()
var effect_layer: Node2D
var gauge_layer: Node2D
var channel_left_extent := 0.0
var channel_right_extent := 0.0
var rock_rotation := 0.0
var burrow_rotation := 0.0
const CHANNEL := preload("res://src/systems/channel_runtime.gd")
var pillars: Node2D
var channel = CHANNEL.new()
var summon_snapshot := 0
var attack_snapshot := 0
var transcend_level := 0
var gauge := 0.0
var skill_cooldowns := PackedFloat32Array([0.0,0.0,0.0])
var phase := "fall"
var phase_elapsed := 0.0
var visual_rest := Vector2.ZERO
var visual_head_y := -118.0
var landing_position := Vector2.ZERO
var interaction_timer := 0.0
var received_hits := 0
var retreat_pending := 0
var retreat_direction := Vector2.ZERO
var stun_remaining := 0.0
var silence_remaining := 0.0
var rock_active := false
var rock_position := Vector2.ZERO
var rock_target := Vector2.ZERO
var rock_origin := Vector2.ZERO
var rock_distance := 0.0
var rock_total_distance := 0.0
var impact_position := Vector2.ZERO
var impact_remaining := 0.0
var impact_kind := "impact"
var wave_active := false
var wave_origin := Vector2.ZERO
var wave_distance := 0.0
var wave_visual_distance := -1.0
var wave_hit := false
var wave_primary_hit := false
var saved_collision_layer := 2
var saved_collision_mask := 3
var wave_directions := PackedVector2Array()

func _init() -> void:
	monster_type = "bulgasal"
	monster_role = "tank"
	for stat in DATA.BASE:
		set(stat, DATA.BASE[stat])
	fragment_distances.resize(DATA.FRAGMENT_COUNT)
	fragment_positions.resize(DATA.FRAGMENT_COUNT)
	fragment_states.resize(DATA.FRAGMENT_COUNT)
	fragment_ages.resize(DATA.FRAGMENT_COUNT)
	for index in range(DATA.FRAGMENT_COUNT):
		wave_directions.append(Vector2.RIGHT.rotated(float(index)*TAU/8.0))

func configure_transcendence(deaths: int, level: int) -> void:
	summon_snapshot = maxi(deaths,0)
	transcend_level = clampi(level,0,5)
	max_hp = int(DATA.BASE.max_hp)+summon_snapshot
	current_hp = max_hp

func configure_attack_snapshot(tank_deaths: int) -> void:
	attack_snapshot = maxi(tank_deaths,0)
	attack_damage = int(round(DATA.BASE.attack_damage+attack_snapshot*DATA.DAMAGE_PER_TANK_DEATH))

func on_ally_death(_point: Vector2) -> void:
	if dying or current_hp <= 0:
		return
	summon_snapshot += 1
	max_hp += 1 # Cumulative death growth; does not heal previous damage.

func _ready() -> void:
	super._ready()
	body_radius = $CollisionShape2D.shape.radius
	visual.apply_visual_profile(DATA.PROFILE)
	var texture: Texture2D = visual.sprite_frames.get_frame_texture(&"idle",0)
	var union := Rect2i()
	var idle_union := Rect2i()
	for animation_name in visual.sprite_frames.get_animation_names():
		for index in range(visual.sprite_frames.get_frame_count(animation_name)):
			var bounds: Rect2i = visual.sprite_frames.get_frame_texture(animation_name,index).get_image().get_used_rect()
			union = bounds if union.size == Vector2i.ZERO else union.merge(bounds)
			if animation_name == &"idle":
				idle_union = bounds if idle_union.size == Vector2i.ZERO else idle_union.merge(bounds)
	var factor := DATA.VISIBLE_HEIGHT/maxf(float(union.size.y),1.0)
	visual.scale = Vector2.ONE*factor
	# All uploaded body frames have the same fixed feet anchor, not per-frame bounds.
	visual.position = -(Vector2(229,223)-texture.get_size()*0.5)*factor
	visual_rest = visual.position
	visual_head_y = visual_rest.y+(union.position.y-texture.get_height()*0.5)*factor
	channel_left_extent = (229.0-float(idle_union.position.x))*factor
	channel_right_extent = (float(idle_union.end.x)-229.0)*factor
	effect_layer = DRAW_LAYER.new()
	effect_layer.name = "CombatEffects"
	effect_layer.actor = self
	effect_layer.z_index = 1
	add_child(effect_layer)
	gauge_layer = DRAW_LAYER.new()
	gauge_layer.name = "CombatGauges"
	gauge_layer.actor = self
	gauge_layer.status = true
	gauge_layer.z_index = 3
	add_child(gauge_layer)
	audio_bank = SFX_BANK.new()
	add_child(audio_bank)
	audio_bank.configure(AUDIO.CUES,combat_authority,true)
	FX.warm()
	pillars = PILLARS.new()
	pillars.actor = self
	pillars.authority = combat_authority
	add_child(pillars)
	visual.position.y = visual_rest.y-360.0

func get_gauge_regen() -> float:
	return minf(maxf(float(combat_authority.command_regen_per_second),0.0)*DATA.REGEN_RATIO,DATA.REGEN_CAP) if is_instance_valid(combat_authority) else 0.0

func _paused() -> bool:
	return is_instance_valid(combat_authority) and (combat_authority.battle_over or combat_authority.external_pause or combat_authority.demon_augment_selection_active)

func _physics_process(delta: float) -> void:
	if dying or current_hp <= 0 or _paused():
		return
	if is_instance_valid(combat_authority):
		hero = combat_authority.hero
	gauge = minf(DATA.GAUGE_MAX,gauge+get_gauge_regen()*delta)
	for index in range(3):
		skill_cooldowns[index] -= delta
	interaction_timer = maxf(interaction_timer-delta,0.0)
	attack_timer = maxf(attack_timer-delta,0.0)
	hit_flash_timer = maxf(hit_flash_timer-delta,0.0)
	impact_remaining = maxf(impact_remaining-delta,0.0)
	_tick_rock(delta)
	_tick_waves(delta)
	_tick_fragments(delta)
	var blocked := stun_remaining > 0.0 or silence_remaining > 0.0 or bool(get_meta("stun_active",false)) or bool(get_meta("silence_active",false)) or MONSTER_RUNTIME_COMMON.is_forced_movement_locked(self)
	blocked = blocked and not is_action_control_immune()
	stun_remaining = maxf(stun_remaining-delta,0.0)
	silence_remaining = maxf(silence_remaining-delta,0.0)
	phase_elapsed += delta
	velocity = Vector2.ZERO
	match phase:
		"fall":
			var progress := clampf(phase_elapsed/DATA.SPAWN_FALL_SECONDS,0.0,1.0)
			visual.position.y = visual_rest.y-360.0*(1.0-progress*progress)
			if progress >= 1.0:
				_set_phase("idle")
				_show_impact("impact",global_position,"land")
				pillars.regenerate()
		"pick":
			if phase_elapsed >= DATA.ROCK_PICK_SECONDS+DATA.ROCK_HOLD_SECONDS:
				if _hero_alive():
					_launch_rock(hero.global_position)
				_set_phase("idle")
		"burrow":
			if _hero_alive() and stun_remaining <= 0.0 and not bool(get_meta("stun_active",false)):
				_move_towards(hero.global_position,delta,DATA.BURROW_SPEED_RATIO)
				if global_position.distance_squared_to(hero.global_position) <= attack_range*attack_range:
					if _deal_hero_damage(int(round(attack_damage*DATA.BURROW_DAMAGE)),transcend_level>=4):
						hero.apply_healing_reduction(3.0,0.25)
					_show_impact("emerge",global_position)
					_end_burrow()
			if phase == "burrow" and phase_elapsed >= DATA.BURROW_SECONDS:
				_end_burrow()
		"channel":
			if channel.tick(delta,blocked):
				landing_position = global_position
				_set_phase("launch")
			elif not channel.active:
				_set_phase("idle")
		"launch":
			visual.position.y = visual_rest.y-phase_elapsed/0.35*360.0
			if phase_elapsed >= 0.35:
				visual.visible = false
				saved_collision_layer = collision_layer
				saved_collision_mask = collision_mask
				collision_layer = 0
				collision_mask = 0
				TARGET_POLICY.set_hidden(self,true)
				_set_phase("air")
		"air":
			if phase_elapsed >= DATA.AIR_SECONDS:
				visual.visible = true
				collision_layer = saved_collision_layer
				collision_mask = saved_collision_mask
				_set_phase("land")
		"land":
			visual.position.y = visual_rest.y-360.0*(1.0-clampf(phase_elapsed/0.25,0.0,1.0))
			if phase_elapsed >= 0.25:
				TARGET_POLICY.set_hidden(self,false)
				global_position = landing_position
				visual.position = visual_rest
				wave_primary_hit = _hero_in(landing_position,get_leap_radius()) and hero.take_damage(int(round(attack_damage*DATA.LEAP_DAMAGE)),self)
				if wave_primary_hit:
					hero.apply_stun(3.0)
				_show_impact("leap_impact",landing_position)
				wave_active = true
				wave_origin = landing_position
				wave_distance = 0.0
				wave_visual_distance = 0.0
				wave_hit = false
				_set_phase("idle")
		"retreat":
			_move_direction(retreat_direction,DATA.RETREAT_DISTANCE/DATA.RETREAT_SECONDS,delta)
			if phase_elapsed >= DATA.RETREAT_SECONDS:
				_set_phase("quake")
		"quake":
			if phase_elapsed >= 0.9:
				pillars.shatter_all(true)
				add_stacking_shield(DATA.RETREAT_SHIELD)
				_set_phase("regenerate")
		"regenerate":
			if phase_elapsed >= 1.55:
				pillars.regenerate()
				_set_phase("idle")
		"idle":
			if stun_remaining <= 0.0 and not bool(get_meta("stun_active",false)) and not MONSTER_RUNTIME_COMMON.is_forced_movement_locked(self):
				_tick_idle(delta)
			else:
				_update_visual_motion(0.0,false)
	effect_layer.queue_redraw()
	gauge_layer.queue_redraw()

func _tick_idle(delta: float) -> void:
	if not _hero_alive():
		_update_visual_motion(0.0,false)
		return
	if retreat_pending > 0:
		retreat_pending -= 1
		retreat_direction = (global_position-hero.global_position).normalized()
		if retreat_direction.is_zero_approx():
			retreat_direction = Vector2.LEFT
		_set_phase("retreat")
		return
	if _try_cast():
		return
	var pillar_index: int = pillars.nearest(global_position,DATA.PILLAR_INTERACTION)
	if pillar_index >= 0 and interaction_timer <= 0.0:
		_update_visual_motion(0.0,false)
		interaction_timer = 0.75
		visual.play_attack()
		pillars.shatter(pillar_index,true,randf()<DATA.EAT_CHANCE)
		return
	var offset := hero.global_position-global_position
	if offset.length_squared() > attack_range*attack_range:
		_move_towards(hero.global_position,delta)
	else:
		_update_visual_motion(offset.x,false)
		if attack_timer <= 0.0:
			attack_timer = attack_cooldown
			visual.play_attack()
			hero.take_damage(attack_damage,self)

func _move_towards(point: Vector2, delta: float, speed_ratio: float = 1.0) -> void:
	var offset := point-global_position
	_move_direction(offset.normalized(),minf(move_speed*speed_ratio,offset.length()/maxf(delta,0.0001)),delta)

func _move_direction(direction: Vector2, speed: float, _delta: float) -> void:
	if stun_remaining > 0.0 or MONSTER_RUNTIME_COMMON.is_forced_movement_locked(self):
		return
	if phase == "burrow" and not direction.is_zero_approx():
		burrow_rotation = direction.angle()
	velocity = direction*speed*MONSTER_RUNTIME_COMMON.get_external_movement_multiplier(self)
	if phase == "burrow":
		# Clear only pillars reached along this bounded movement sweep before collision.
		pillars.shatter_segment(global_position,global_position+velocity*_delta,body_radius)
	move_and_slide()
	_update_visual_motion(direction.x,not velocity.is_zero_approx())

func _try_cast() -> bool:
	if silence_remaining > 0.0 or bool(get_meta("silence_active",false)):
		return false
	for index in DATA.CAST_PRIORITY:
		if index == 2 and global_position.distance_squared_to(hero.global_position) > DATA.LEAP_CAST_RANGE*DATA.LEAP_CAST_RANGE:
			continue
		if skill_cooldowns[index] > 0.0 or gauge+0.0001 < DATA.COSTS[index] or (index == 0 and rock_active):
			continue
		gauge = maxf(gauge-DATA.COSTS[index],0.0)
		skill_cooldowns[index] = DATA.COOLDOWNS[index]
		if index == 0:
			_set_phase("pick")
		elif index == 1:
			burrow_rotation = (hero.global_position-global_position).angle()
			_set_phase("burrow")
			visual.visible = false
		else:
			channel.begin(DATA.CHANNEL_SECONDS)
			_set_phase("channel")
		return true
	return false

func _set_phase(next: String) -> void:
	if burrow_phased and next != "burrow":
		_restore_burrow_collision()
	if next == "burrow" and transcend_level >= 4 and not burrow_phased:
		burrow_saved_layer = collision_layer
		burrow_saved_mask = collision_mask
		burrow_phased = true
		collision_layer = 0
		collision_mask = 12 # Keep terrain/arena walls; phase through actors and pillars.
		TARGET_POLICY.set_hidden(self,true)
	if is_instance_valid(audio_bank):
		if next == "burrow": audio_bank.play_cue("burrow")
		if phase == "burrow" and next != "burrow": audio_bank.stop_cue("burrow")
	if next == "launch":
		TARGET_POLICY.set_hidden(self,true)
	phase = next
	visual_moving_state = -1
	if next != "burrow" and next != "air":
		_update_visual_motion(0.0,false)
	phase_elapsed = 0.0
	velocity = Vector2.ZERO

func _end_burrow() -> void:
	visual.visible = true
	visual.position = visual_rest
	visual_moving_state = -1
	_set_phase("idle")

func apply_stun(seconds: float) -> void:
	if is_action_control_immune(): return
	stun_remaining = maxf(stun_remaining,seconds)
	if phase == "channel":
		channel.cancel()
		_set_phase("idle")

func apply_silence(seconds: float) -> void:
	if is_action_control_immune(): return
	silence_remaining = maxf(silence_remaining,seconds)
	if phase == "channel":
		channel.cancel()
		_set_phase("idle")

func _launch_rock(point: Vector2) -> void:
	rock_origin = global_position
	rock_position = rock_origin
	rock_target = point # Target snapshot; never retargets the moving hero.
	rock_rotation = (point-rock_origin).angle()
	rock_total_distance = rock_origin.distance_to(point)
	rock_distance = 0.0
	rock_active = true
	visual.play_attack()

func _tick_rock(delta: float) -> void:
	if not rock_active:
		return
	var previous := rock_position
	rock_distance = minf(rock_distance+DATA.ROCK_SPEED*delta,rock_total_distance)
	rock_position = rock_origin.lerp(rock_target,rock_distance/maxf(rock_total_distance,0.001))
	pillars.shatter_segment(previous,rock_position)
	if rock_distance >= rock_total_distance:
		rock_active = false
		_show_impact("impact",rock_target)
		resolve_rock_impact(rock_target)

func get_pillar_capacity() -> int:
	return DATA.PILLAR_MAX+(DATA.UPGRADED_PILLAR_BONUS if transcend_level>=3 else 0)

func get_eat_shield_ratio() -> float:
	return DATA.UPGRADED_EAT_SHIELD if transcend_level>=3 else DATA.EAT_SHIELD

func get_leap_radius() -> float:
	return DATA.LEAP_RADIUS*(DATA.UPGRADED_LEAP_RADIUS_RATIO if transcend_level>=5 else 1.0)

func is_action_control_immune() -> bool:
	return transcend_level>=5 and phase=="channel" and channel.active

func is_forced_movement_immune() -> bool:
	return is_action_control_immune()

func is_movement_effect_immune() -> bool:
	return is_action_control_immune()

func _restore_burrow_collision() -> void:
	collision_layer = burrow_saved_layer
	collision_mask = burrow_saved_mask
	burrow_phased = false
	TARGET_POLICY.set_hidden(self,false)

func _deal_hero_damage(amount: int, ignore_invulnerability: bool) -> bool:
	return hero.take_followup_damage(amount,self) if ignore_invulnerability else hero.take_damage(amount,self)

func resolve_rock_impact(point: Vector2) -> void:
	_resolve_rock_area(point,1.0)
	if transcend_level>=2:
		# Eight preallocated independent projectiles; never recurse into another split.
		fragment_origin = point
		for index in range(DATA.FRAGMENT_COUNT):
			fragment_distances[index] = 0.0
			fragment_positions[index] = point
			fragment_states[index] = 1
			fragment_ages[index] = 0.0

func _resolve_rock_area(point: Vector2, ratio: float) -> void:
	if not _hero_in(point,DATA.ROCK_OUTER_RADIUS*ratio): return
	if _hero_in(point,DATA.ROCK_INNER_RADIUS*ratio):
		if _deal_hero_damage(int(round(attack_damage*DATA.ROCK_INNER_DAMAGE*ratio)),transcend_level>=1):
			hero.apply_stun(2.0*ratio)
	elif _deal_hero_damage(int(round(attack_damage*DATA.ROCK_OUTER_DAMAGE*ratio)),transcend_level>=1):
		# apply_slow takes speed multiplier, so halve the reduction (50% -> 25%).
		hero.apply_slow(1.0-0.5*ratio,2.0*ratio)

func _tick_fragments(delta: float) -> void:
	for index in range(DATA.FRAGMENT_COUNT):
		if fragment_states[index]==0: continue
		fragment_ages[index] += delta
		if fragment_states[index]==2:
			if fragment_ages[index]>=0.5: fragment_states[index]=0
			continue
		var previous := fragment_positions[index]
		fragment_distances[index] = minf(fragment_distances[index]+DATA.ROCK_SPEED*delta,DATA.FRAGMENT_RANGE)
		var point := fragment_origin+wave_directions[index]*fragment_distances[index]
		var collided := false
		if _hero_alive():
			var closest := Geometry2D.get_closest_point_to_segment(hero.global_position,previous,point)
			if closest.distance_squared_to(hero.global_position)<=pow(DATA.ROCK_INNER_RADIUS*DATA.FRAGMENT_RATIO,2):
				point = closest
				collided = true
		fragment_positions[index] = point
		pillars.shatter_segment(previous,point)
		if collided or fragment_distances[index]>=DATA.FRAGMENT_RANGE:
			fragment_states[index] = 2
			fragment_ages[index] = 0.0
			_resolve_rock_area(point,DATA.FRAGMENT_RATIO)

func play_pillar_sound(eaten: bool) -> void:
	if is_instance_valid(audio_bank): audio_bank.play_cue("eat" if eaten else "pillar")

func _tick_waves(delta: float) -> void:
	if wave_visual_distance >= 0.0:
		wave_visual_distance += DATA.WAVE_SPEED*delta
		if wave_visual_distance > DATA.WAVE_RANGE+DATA.WAVE_TRAIL_SPACING*(DATA.WAVE_TRAIL_COUNT-1):
			wave_visual_distance = -1.0
	if not wave_active:
		return
	var previous := wave_distance
	wave_distance = minf(wave_distance+DATA.WAVE_SPEED*delta,DATA.WAVE_RANGE)
	if not wave_hit and _hero_alive():
		for direction in wave_directions:
			var closest := Geometry2D.get_closest_point_to_segment(hero.global_position,wave_origin+direction*previous,wave_origin+direction*wave_distance)
			if closest.distance_squared_to(hero.global_position) <= DATA.WAVE_RADIUS*DATA.WAVE_RADIUS:
				wave_hit = true # Shared across all rays and future frames, even if immune.
				var damage := int(round(attack_damage*DATA.WAVE_DAMAGE))
				# Follow up only our accepted landing hit; preserve immunity for other cases.
				var accepted: bool = hero.take_followup_damage(damage,self) if wave_primary_hit else hero.take_damage(damage,self)
				if accepted:
					hero.apply_slow(0.7,2.0)
				break
	if wave_distance >= DATA.WAVE_RANGE:
		wave_active = false

func hit_aftershock(point: Vector2) -> void:
	if _hero_in(point,DATA.AFTERSHOCK_RADIUS):
		hero.take_damage(int(round(attack_damage*DATA.AFTERSHOCK_DAMAGE)),self)

func add_stacking_shield(ratio: float) -> void:
	var total := int(get_meta("support_shield_hp",0))+int(round(max_hp*ratio))
	set_meta("support_shield_hp",total)
	set_meta("support_shield_capacity",total)

func _hero_alive() -> bool:
	return is_instance_valid(hero) and int(hero.current_hp)>0

func _hero_in(point: Vector2, radius: float) -> bool:
	return _hero_alive() and hero.global_position.distance_squared_to(point) <= radius*radius

func take_damage(amount: int) -> void:
	if dying or current_hp<=0 or phase == "air" or (phase == "burrow" and transcend_level>=4) or amount <= 0:
		return
	received_hits += 1
	if received_hits >= 10:
		received_hits -= 10
		retreat_pending += 1
	super.take_damage(int(round(amount*DATA.BURROW_DAMAGE_RATIO)) if phase == "burrow" else amount)

func _begin_death() -> void:
	if burrow_phased: _restore_burrow_collision()
	fragment_states.fill(0)
	if is_instance_valid(audio_bank): audio_bank.stop_all()
	TARGET_POLICY.set_hidden(self,false)
	channel.cancel()
	rock_active = false
	wave_active = false
	wave_visual_distance = -1.0
	visual.visible = true
	visual.position = visual_rest
	if is_instance_valid(pillars):
		pillars.finish_death()
	super._begin_death()
	effect_layer.queue_redraw()
	gauge_layer.queue_redraw()

func _show_impact(kind: String, point: Vector2, cue: String = "") -> void:
	if is_instance_valid(audio_bank):
		audio_bank.play_cue(cue if not cue.is_empty() else "land" if kind=="leap_impact" else "emerge" if kind=="emerge" else "rock")
	impact_kind = kind
	impact_position = point
	impact_remaining = float(FX.get_pack(kind).frames.size())/10.0

func _draw() -> void:
	# Body is normalized to Z0 by castle depth sorting. Draw in explicit front layers.
	pass

func draw_status_overlay(target: Node2D) -> void:
	if dying or not is_instance_valid(visual):
		return
	if phase != "air":
		var hp_y := visual_head_y-17.0
		var gauge_y := hp_y-6.0-DATA.BAR_GAP
		target.draw_rect(Rect2(-35,hp_y,70,7),Color("202024"))
		target.draw_rect(Rect2(-35,hp_y,70*float(current_hp)/maxi(max_hp,1),7),Color("4cd965"))
		target.draw_rect(Rect2(-35,gauge_y,70,6),Color("332709"))
		target.draw_rect(Rect2(-35,gauge_y,70*gauge/DATA.GAUGE_MAX,6),Color("ffdb3b"))
		if int(get_meta("support_shield_hp",0)) > 0:
			var shield: float = float(get_meta("support_shield_hp",0))
			var capacity := maxf(float(get_meta("support_shield_capacity",shield)),1.0)
			var shield_y := gauge_y-6.0-DATA.BAR_GAP
			target.draw_rect(Rect2(-35,shield_y,70,6),Color("202c40"))
			target.draw_rect(Rect2(-35,shield_y,70*clampf(shield/capacity,0.0,1.0),6),Color("61ddff"))
	if phase == "channel":
		var channel_x := (channel_left_extent if visual.flip_h else channel_right_extent)+DATA.CHANNEL_MARGIN
		target.draw_rect(Rect2(channel_x,visual_head_y,6,DATA.VISIBLE_HEIGHT),Color("292426"))
		var filled: float = DATA.VISIBLE_HEIGHT*channel.progress()
		target.draw_rect(Rect2(channel_x,visual_head_y+DATA.VISIBLE_HEIGHT-filled,6,filled),Color("ffe693"))

func draw_combat_overlay(target: Node2D) -> void:
	if dying or not is_instance_valid(visual):
		return
	if phase == "pick":
		FX.draw_frame(target,"rock_pick",mini(int(phase_elapsed/DATA.ROCK_PICK_SECONDS*9),8),Vector2.ZERO)
	elif phase == "burrow":
		FX.draw_frame(target,"burrow",get_burrow_frame(),Vector2.ZERO,burrow_rotation)
	elif phase == "launch":
		FX.draw_frame(target,"leap",mini(int(phase_elapsed/0.35*7),6),Vector2.ZERO)
	elif phase == "quake":
		FX.draw_frame(target,"retreat",mini(int(phase_elapsed*10),8),Vector2.ZERO)
	if phase == "channel":
		TELEGRAPH.draw_area(target,Vector2.ZERO,get_leap_radius(),channel.progress())
	if phase == "air" or phase == "land":
		target.draw_arc(to_local(landing_position),get_leap_radius(),0,TAU,64,Color("ffcc80"),1.0,false)
	if rock_active:
		var progress := rock_distance/maxf(rock_total_distance,0.001)
		FX.draw_frame(target,"rock_fly",mini(int(progress*6),5),to_local(rock_position),rock_rotation)
		target.draw_arc(to_local(rock_target),DATA.ROCK_OUTER_RADIUS,0,TAU,72,Color("ffcc80"),1.0,false)
		target.draw_arc(to_local(rock_target),DATA.ROCK_INNER_RADIUS,0,TAU,64,Color("ffee99"),1.0,false)
	if impact_remaining > 0.0:
		var duration := float(FX.get_pack(impact_kind).frames.size())/10.0
		FX.draw_frame(target,impact_kind,int((duration-impact_remaining)*10.0),to_local(impact_position),0.0,DATA.UPGRADED_LEAP_RADIUS_RATIO if impact_kind=="leap_impact" and transcend_level>=5 else 1.0)
	for index in range(DATA.FRAGMENT_COUNT):
		if fragment_states[index]==1:
			FX.draw_frame(target,"rock_fly",mini(int(fragment_distances[index]/DATA.FRAGMENT_RANGE*6),5),to_local(fragment_positions[index]),wave_directions[index].angle(),DATA.FRAGMENT_RATIO)
		elif fragment_states[index]==2:
			FX.draw_frame(target,"impact",mini(int(fragment_ages[index]*10),4),to_local(fragment_positions[index]),0.0,DATA.FRAGMENT_RATIO)
	if wave_visual_distance >= 0.0:
		# Staggered visual train only; the leading damage sweep remains unchanged.
		for direction in wave_directions:
			for trail in range(DATA.WAVE_TRAIL_COUNT):
				var distance := wave_visual_distance-float(trail)*DATA.WAVE_TRAIL_SPACING
				if distance < 0.0 or distance > DATA.WAVE_RANGE:
					continue
				FX.draw_frame(target,"wave",mini(int(distance/DATA.WAVE_RANGE*11),10),to_local(wave_origin+direction*distance),direction.angle())

func get_burrow_frame() -> int:
	var tick := int(phase_elapsed*DATA.BURROW_FPS)
	return tick if tick<DATA.BURROW_LOOP_FIRST else DATA.BURROW_LOOP_FIRST+(tick-DATA.BURROW_LOOP_FIRST)%DATA.BURROW_LOOP_COUNT
