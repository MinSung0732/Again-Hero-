extends "res://src/monsters/orc.gd"
const DATA := preload("res://src/data/arthur_behavior_catalog.gd")
const TRAIL := preload("res://src/ui/arthur_dash_trail.gd")
const FX := preload("res://src/ui/arthur_combat_effects.gd")
const CHANNEL := preload("res://src/systems/channel_runtime.gd")
const GATE := preload("res://src/monsters/arthur_avalon_gate.gd")
const BLESSING := preload("res://src/systems/arthur_blessing.gd")
const AUDIO := preload("res://src/data/arthur_audio_catalog.gd")
const SFX := preload("res://src/audio/event_sfx_bank.gd")
var audio_bank: Node
var transcend_level := 0
var summon_snapshot := 0
var gauge := 0.0
var cooldowns := PackedFloat32Array([0,0,0])
var gate_boost_count := 0
var channel = CHANNEL.new()
var channel_kind := -1
var excalibur_remaining := 0.0
var dash_remaining := 0.0
var dash_direction := Vector2.RIGHT
var dash_origin := Vector2.ZERO
var landing_collision := KinematicCollision2D.new()
var saved_collision_layer := 0
var saved_collision_mask := 0
var dash_collision_disabled := false
var dash_step := 0
var dash_hits := PackedByteArray([0,0,0])
var dash_hit_ids: Dictionary = {}
var allies: Array = []
var enemies: Array = []
var arrival_remaining := 1.2
var shielded_arrival := false
var fx_age := PackedFloat32Array([-1,-1,-1,-1])
var clock := 0.0
var head_y := -120.0
var dash_trail: Node2D
var front_effects: Node2D
@onready var status_layer: Node2D = $StatusLayer
func _init() -> void:
	monster_type = "arthur"
	monster_role = "tank"
	for key in DATA.BASE: set(key,DATA.BASE[key])
func configure_transcendence(count: int, level: int) -> void:
	transcend_level = clampi(level,0,5)
	summon_snapshot = maxi(count,0)
	max_hp = int(round(DATA.BASE.max_hp+summon_snapshot*DATA.GROWTH.max_hp))
	attack_damage = int(round(DATA.BASE.attack_damage+summon_snapshot*DATA.GROWTH.attack_damage))
	current_hp = max_hp
func _ready() -> void:
	super._ready()
	visual.apply_visual_profile(DATA.PROFILE)
	var texture: Texture2D = visual.sprite_frames.get_frame_texture(&"idle",0)
	var bounds := texture.get_image().get_used_rect()
	var factor := DATA.BODY_HEIGHT/maxf(bounds.size.y,1)
	visual.scale = Vector2.ONE*factor
	visual.position = -(Vector2(195,241)-texture.get_size()*0.5)*factor
	head_y = visual.position.y+(bounds.position.y-texture.get_height()*0.5)*factor
	status_layer.z_as_relative = false
	status_layer.z_index = 12
	status_layer.draw.connect(_draw_status)
	dash_trail = TRAIL.new()
	dash_trail.name = "DashTrail"
	add_child(dash_trail)
	dash_trail.global_transform = Transform2D.IDENTITY
	front_effects = Node2D.new()
	front_effects.name = "CombatEffectsFront"
	front_effects.z_as_relative = false
	front_effects.z_index = DATA.COMBAT_EFFECT_Z
	add_child(front_effects)
	front_effects.draw.connect(_draw_combat_effects)
	audio_bank = SFX.new()
	add_child(audio_bank)
	audio_bank.configure(AUDIO.CUES,combat_authority,true)
	for i in range(4): FX.prepare(i)
func get_gauge_regen() -> float:
	return minf(maxf(float(combat_authority.command_regen_per_second),0),15) if is_instance_valid(combat_authority) else 0.0
func _physics_process(delta: float) -> void:
	if dying or current_hp <= 0: return
	if not is_instance_valid(combat_authority) or combat_authority.battle_over or combat_authority.external_pause or combat_authority.demon_augment_selection_active: return
	dash_trail.tick(delta)
	clock += delta
	gauge = minf(DATA.GAUGE_MAX,gauge+get_gauge_regen()*delta)
	for i in range(3): cooldowns[i] = maxf(cooldowns[i]-delta,0)
	for i in range(4):
		if fx_age[i] >= 0: fx_age[i] = fx_age[i]+delta if fx_age[i] < 0.8 else -1
	excalibur_remaining = maxf(excalibur_remaining-delta,0)
	if not shielded_arrival:
		shielded_arrival = true
		_audio("arrival")
		for id in combat_authority.active_monsters:
			var actor = combat_authority.active_monsters[id]
			if _alive(actor): add_shield(actor,int(round(max_hp*DATA.ARRIVAL_SHIELD)))
	if arrival_remaining > 0:
		arrival_remaining = maxf(arrival_remaining-delta,0)
		velocity = Vector2.ZERO
	elif channel.active:
		attack_timer = maxf(attack_timer-delta,0)
		_hold_skill()
		velocity = Vector2.ZERO
		if channel.tick(delta,_blocked() or bool(get_meta("silence_active",false))): _finish_channel()
		elif channel.interrupted:
			channel_kind = -1
			_restore_combat_pose()
	elif dash_remaining > 0:
		_tick_dash(delta)
	elif not _blocked():
		if not is_instance_valid(hero) or hero.current_hp <= 0: _refresh_combat_target()
		if is_instance_valid(hero) and hero.current_hp > 0:
			_try_cast()
			if not channel.active:
				if excalibur_remaining > 0 and attack_timer <= 0 and not bool(get_meta("silence_active",false)):
					if global_position.distance_squared_to(hero.global_position)<=DATA.DASH_DISTANCE*DATA.DASH_DISTANCE: _start_dash_channel()
					else:
						velocity = global_position.direction_to(hero.global_position)*move_speed*MONSTER_RUNTIME_COMMON.get_external_movement_multiplier(self)
						move_and_slide()
						visual.flip_h = velocity.x < 0
						visual.play_locomotion(true)
				elif excalibur_remaining <= 0 or bool(get_meta("silence_active",false)): super._physics_process(delta)
				else: attack_timer = maxf(attack_timer-delta,0)
	else: velocity = Vector2.ZERO
	queue_redraw()
	status_layer.queue_redraw()
	front_effects.queue_redraw()
func _blocked() -> bool:
	return MONSTER_RUNTIME_COMMON.is_forced_movement_locked(self) or bool(get_meta("stun_active",false))
func _try_cast() -> void:
	if _blocked() or bool(get_meta("silence_active",false)): return
	for i in range(3):
		var cost: float = float(DATA.COSTS[i])-(DATA.GATE_COST_REDUCTION if i==1 and transcend_level>=3 else 0)
		if cooldowns[i]>0 or gauge<cost or (i==0 and excalibur_remaining>0): continue
		gauge -= cost
		cooldowns[i] = DATA.COOLDOWNS[i]
		match i:
			0:
				excalibur_remaining = DATA.DASH_DURATION
				attack_timer = 0
				_audio("charge")
			1:
				channel_kind = 1
				channel.begin(DATA.GATE_CHANNEL)
				_hold_skill()
				_audio("gate_charge")
			2: cast_blessing()
		return
func _hold_skill() -> void:
	# Stopping a previous attack must not leave its locomotion lock latched.
	visual._one_shot_locked = false
	visual.set_lod_suspended(false)
	visual_lod_suspended = false
	visual.animation = &"skill"
	visual.frame = 0
	visual.stop()
	# A pending locomotion transition on the Visual's own physics tick otherwise
	# replaces this stopped skill pose with idle/move before the channel completes.
	visual.set_physics_process(false)
	visual._one_shot_locked = true
func _restore_combat_pose() -> void:
	visual._one_shot_locked = false
	visual_moving_state = -1
	# Rush/channel write flip_h directly, bypassing Orc's cached facing sign.
	# Invalidate before normal motion so an unchanged target side still updates.
	visual_facing_sign = 0
	var direction_x := 0.0
	if is_instance_valid(hero): direction_x = global_position.direction_to(hero.global_position).x
	_update_visual_motion(direction_x,false)
func _start_dash_channel() -> void:
	attack_timer = attack_cooldown/DATA.DASH_HASTE
	channel_kind = 0
	channel.begin(DATA.DASH_CHANNEL)
	_hold_skill()
	if is_instance_valid(hero): visual.flip_h = hero.global_position.x < global_position.x
func _finish_channel() -> void:
	if channel_kind == 1:
		var gate = GATE.new()
		gate.setup(combat_authority,self,DATA.GATE_UPGRADED_DURATION if transcend_level>=3 else DATA.GATE_DURATION)
		gate.position = combat_authority.to_local(global_position)
		combat_authority.add_child(gate)
		_audio("gate")
		_restore_combat_pose()
	else:
		dash_step = 0
		dash_hits.fill(0)
		_begin_dash()
	channel_kind = -1
func _begin_dash() -> void:
	if not _alive(hero):
		dash_remaining = 0
		_restore_dash_collision()
		_restore_combat_pose()
		return
	if not dash_collision_disabled:
		saved_collision_layer = collision_layer
		saved_collision_mask = collision_mask
		collision_layer = 0
		collision_mask = 0
		dash_collision_disabled = true
	velocity = Vector2.ZERO
	global_position = _clamp_dash_point(global_position)
	dash_origin = global_position
	dash_direction = global_position.direction_to(hero.global_position)
	if dash_direction == Vector2.ZERO: dash_direction = Vector2.RIGHT
	dash_remaining = _bounded_dash_distance()
	if dash_remaining <= 0.001:
		_restore_dash_collision()
		_restore_combat_pose()
		return
	dash_hit_ids.clear()
	fx_age[0] = 0
	visual.flip_h = dash_direction.x < 0
	_hold_skill()
	dash_trail.begin(visual)
	_audio("dash")
func _tick_dash(delta: float) -> void:
	attack_timer = maxf(attack_timer-delta,0)
	if _blocked():
		dash_remaining = 0
		_restore_dash_collision()
		velocity = Vector2.ZERO
		_restore_combat_pose()
		return
	_hold_skill()
	var previous := global_position
	var distance := minf(dash_remaining,DATA.DASH_SPEED*delta*(DATA.DASH_FOLLOWUP_SPEED if dash_step>0 else 1.0))
	# Clamp also guards accumulated Vector2 float rounding at the last boundary tick.
	global_position = _clamp_dash_point(previous+dash_direction*distance)
	dash_trail.advance_segment(visual,previous,global_position)
	dash_remaining -= distance
	MONSTER_RUNTIME_COMMON.notify_forced_position_change(self)
	# A swept segment prevents tunneling. Each actor is touched once per rush.
	_hit_dash_enemy(hero,previous,global_position)
	if combat_authority.hero != hero: _hit_dash_enemy(combat_authority.hero,previous,global_position)
	if combat_authority.has_method("fill_active_enemy_summons"):
		combat_authority.fill_active_enemy_summons(enemies)
		for enemy in enemies:
			if enemy != hero: _hit_dash_enemy(enemy,previous,global_position)
	combat_authority.fill_monsters_near((previous+global_position)*0.5,distance*0.5+DATA.DASH_WIDTH+32,allies)
	for actor in allies:
		if actor==self or not _alive(actor) or dash_hit_ids.has(actor.get_instance_id()): continue
		if _segment_hits(previous,global_position,actor.global_position):
			dash_hit_ids[actor.get_instance_id()] = true
			add_shield(actor,int(round(max_hp*DATA.DASH_SHIELD)))
	if dash_remaining <= 0:
		if transcend_level>=5 and dash_step<2 and _alive(hero):
			dash_step += 1
			_begin_dash()
		else:
			if dash_hits[0]>0 and dash_hits[1]>0 and dash_hits[2]>0: current_hp += int(round((max_hp-current_hp)*DATA.DASH_HEAL))
			_restore_dash_collision()
			_restore_combat_pose()
func _hit_dash_enemy(enemy: Node2D, previous: Vector2, point: Vector2) -> void:
	if not _alive(enemy) or dash_hit_ids.has(enemy.get_instance_id()) or not _segment_hits(previous,point,enemy.global_position): return
	dash_hit_ids[enemy.get_instance_id()] = true
	var amount := maxi(int(round(attack_damage*DATA.DASH_DAMAGE*(DATA.DASH_FOLLOWUP_DAMAGE if dash_step>0 else 1.0))),1)
	var accepted := false
	if dash_step>0 and enemy.has_method("take_status_damage"): accepted = bool(enemy.take_status_damage(amount,self))
	elif dash_step>0 and enemy.has_method("take_followup_damage"): accepted = bool(enemy.take_followup_damage(amount,self))
	else: accepted = bool(enemy.take_damage(amount,self))
	if enemy==hero: dash_hits[dash_step] = 1 if accepted else 0
func _segment_hits(a: Vector2, b: Vector2, p: Vector2) -> bool:
	return Geometry2D.get_closest_point_to_segment(p,a,b).distance_squared_to(p) <= DATA.DASH_WIDTH*DATA.DASH_WIDTH
func _restore_dash_collision() -> void:
	if not dash_collision_disabled: return
	# Check static footprints only, once at landing. Ignore crowded friendly bodies.
	# Retained collision result avoids per-probe query arrays or global decor scans.
	collision_mask = saved_collision_mask & DATA.DASH_STATIC_MASK
	if collision_mask != 0 and _landing_blocked(global_position):
		var end := global_position
		var length := end.distance_to(dash_origin)
		var found := false
		for probe in range(1,DATA.DASH_LANDING_PROBES+1):
			var candidate := _clamp_dash_point(end-dash_direction*minf(float(probe)*DATA.DASH_LANDING_STEP,length))
			if not _landing_blocked(candidate):
				global_position = candidate
				found = true
				break
			if float(probe)*DATA.DASH_LANDING_STEP >= length: break
		# Rare case: a manual summon already began inside a footprint. Bounded
		# radial recovery also works at corners; every candidate stays in map bounds.
		if not found:
			for ring in range(DATA.DASH_ESCAPE_RINGS):
				for direction in range(DATA.DASH_ESCAPE_DIRECTIONS):
					var radius := DATA.DASH_LANDING_STEP*pow(2.0,ring+1)
					var candidate := _clamp_dash_point(end+Vector2.RIGHT.rotated(TAU*direction/DATA.DASH_ESCAPE_DIRECTIONS)*radius)
					if not _landing_blocked(candidate):
						global_position = candidate
						found = true
						break
				if found: break
		MONSTER_RUNTIME_COMMON.notify_forced_position_change(self)
	collision_layer = saved_collision_layer
	collision_mask = saved_collision_mask
	dash_collision_disabled = false
func _landing_blocked(point: Vector2) -> bool:
	var placement := global_transform
	placement.origin = point
	return test_move(placement,Vector2.ZERO,landing_collision,0.5,true)
func _clamp_dash_point(point: Vector2) -> Vector2:
	if is_instance_valid(combat_authority) and combat_authority.has_method("clamp_monster_wander_position"):
		return combat_authority.to_global(combat_authority.clamp_monster_wander_position(combat_authority.to_local(point)))
	return point
func _bounded_dash_distance() -> float:
	if not combat_authority.has_method("clamp_monster_wander_position"): return DATA.DASH_DISTANCE
	var origin_local: Vector2 = combat_authority.to_local(dash_origin)
	var direction_local: Vector2 = combat_authority.to_local(dash_origin+dash_direction)-origin_local
	var end_local: Vector2 = combat_authority.to_local(_clamp_dash_point(dash_origin+dash_direction*DATA.DASH_DISTANCE))
	var delta := end_local-origin_local
	var limit := DATA.DASH_DISTANCE
	if absf(direction_local.x)>0.0001: limit = minf(limit,maxf(delta.x/direction_local.x,0))
	if absf(direction_local.y)>0.0001: limit = minf(limit,maxf(delta.y/direction_local.y,0))
	return limit
static func _alive(actor: Node) -> bool:
	if not is_instance_valid(actor) or actor.is_queued_for_deletion(): return false
	var hp = actor.get("current_hp")
	# Hero uses is_dying; monsters use dying. bool(null) raises a runtime error
	# on the real Hero and prevented _begin_dash despite the old mock passing.
	return hp != null and int(hp)>0 and actor.get("dying") != true and actor.get("is_dying") != true
static func add_shield(actor: Node2D, amount: int) -> void:
	if not _alive(actor): return
	var shield := int(actor.get_meta("support_shield_hp",0))+maxi(amount,0)
	actor.set_meta("support_shield_hp",shield)
	actor.set_meta("support_shield_capacity",maxi(shield,int(actor.get_meta("support_shield_capacity",0))))
	actor.queue_redraw()
func cast_blessing() -> void:
	combat_authority.fill_monsters_near(global_position,DATA.BLESSING_RADIUS,allies)
	for actor in allies:
		if _alive(actor) and global_position.distance_squared_to(actor.global_position)<=DATA.BLESSING_RADIUS*DATA.BLESSING_RADIUS:
			BLESSING.grant(actor,int(round(actor.max_hp*(DATA.BLESSING_UPGRADED_RATIO if transcend_level>=4 else DATA.BLESSING_RATIO))),DATA.BLESSING_UPGRADED_DURATION if transcend_level>=4 else DATA.BLESSING_DURATION,combat_authority)
	fx_age[2] = 0
	_audio("blessing")
func block_chance() -> float:
	return DATA.BLOCK_BASE+(DATA.BLOCK_FIRST if transcend_level>=1 else 0.0)+(DATA.BLOCK_SECOND if transcend_level>=2 else 0.0)
func take_damage(amount: int) -> void: _apply_arthur_damage(amount)
func supports_damage_receipt() -> bool: return get_script().resource_path=="res://src/monsters/arthur.gd"
func take_damage_with_result(amount: int, receipt) -> bool:
	if receipt==null:
		take_damage(amount)
		return false
	var revision: int = receipt.begin(self,amount)
	if not supports_damage_receipt():
		take_damage(amount)
		return false
	_apply_arthur_damage(amount,receipt,revision)
	return receipt.finish(revision)
func _apply_arthur_damage(amount: int, receipt = null, revision: int = 0) -> void:
	if not dying and current_hp>0 and amount>0 and randf()<block_chance():
		fx_age[3] = 0
		_audio("block")
		return
	_apply_orc_damage(amount,receipt,revision)
	if (channel.active or dash_remaining > 0) and not dying: _hold_skill()
func aura_modifier(actor: Node2D, kind: String) -> float:
	return 1.0+gate_boost_count*DATA.GATE_CASTER_ATTACK_PER_ALLY if actor==self and kind=="outgoing" and not dying else 1.0
func on_ally_death(_point: Vector2) -> void: pass
func _begin_death() -> void: _begin_arthur_death()
func _begin_death_with_result(receipt = null, revision: int = 0) -> void: _begin_arthur_death(receipt,revision)
func _begin_arthur_death(receipt = null, revision: int = 0) -> void:
	channel.cancel()
	dash_trail.clear()
	dash_remaining = 0
	if is_instance_valid(audio_bank): audio_bank.stop_all()
	_restore_dash_collision()
	_begin_orc_standard_death(receipt,revision)
func _audio(cue: String) -> void:
	if is_instance_valid(audio_bank): audio_bank.play_cue(cue)
func _draw() -> void:
	pass # Skill art lives in its retained foreground layer, never below the body.
func _draw_combat_effects() -> void:
	if dying: return
	for i in range(4):
		if i == 1: continue
		if fx_age[i]>=0:
			if i==0:
				front_effects.draw_set_transform(Vector2(0,-50),dash_direction.angle(),Vector2.ONE)
				FX.draw_frame(front_effects,i,mini(7,int(fx_age[i]*10)),Vector2.ZERO)
				front_effects.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
			else: FX.draw_frame(front_effects,i,mini(7,int(fx_age[i]*10)),Vector2(0,-40))
func _draw_status() -> void:
	if dying: return
	var width := 86.0
	var shield := int(get_meta("support_shield_hp",0))+int(get_meta("arthur_blessing_hp",0))
	if shield>0:
		var capacity := maxi(int(get_meta("support_shield_capacity",0))+int(get_meta("arthur_blessing_capacity",0)),1)
		draw_status_bar(Rect2(-width*0.5,head_y-25,width,6),float(shield)/capacity,Color("61ddff"))
	draw_status_bar(Rect2(-width*0.5,head_y-15,width,8),float(current_hp)/maxi(max_hp,1),Color(0.3,0.9,0.45))
	draw_status_bar(Rect2(-width*0.5,head_y-5,width,4),gauge/DATA.GAUGE_MAX,Color(1,0.86,0.18))
	if channel.active: draw_status_bar(Rect2(visual.position.x+45,head_y,5,80),channel.progress(),Color(0.9,0.9,1))
func draw_status_bar(rect: Rect2, ratio: float, color: Color) -> void:
	status_layer.draw_rect(rect,Color(0.1,0.1,0.14))
	var fill := rect
	if rect.size.y>rect.size.x:
		fill.size.y *= clampf(ratio,0,1)
		fill.position.y += rect.size.y-fill.size.y
	else: fill.size.x *= clampf(ratio,0,1)
	status_layer.draw_rect(fill,color)

func _attack_target(target: Node2D) -> void:
	_audio("swing")
	target.call("take_damage",attack_damage,self)
