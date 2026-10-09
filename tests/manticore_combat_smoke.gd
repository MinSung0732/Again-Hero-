extends SceneTree
const SCENE := preload("res://src/monsters/Manticore.tscn")
const DATA := preload("res://src/data/manticore_behavior_catalog.gd")
const RUNTIME := preload("res://src/systems/transcendence_runtime.gd")
const BURN := preload("res://src/systems/burn_runtime.gd")
const POISON := preload("res://src/systems/damage_poison_tracker.gd")
var failures := 0
class Target extends Node2D:
	var current_hp := 1000000
	var max_hp := 1000000
	var damage := 0
	var is_dying := false
	var reject := false
	var burns := 0
	var bleed_refresh := false
	var slow := 1.0
	var poison = POISON.new()
	func take_damage(amount: int, _source: Node = null) -> bool:
		if reject: return false
		damage += amount
		return true
	func take_followup_damage(amount: int, source: Node) -> bool: return take_damage(amount,source)
	func take_status_damage(amount: int, source: Node) -> bool: return take_damage(amount,source)
	func take_recorded_poison_damage(amount: int, source: Node) -> bool: return take_damage(amount,source)
	func apply_bleed(_seconds: float, _source: Node, ratio: float, refresh: bool) -> bool:
		assert(ratio == 0.03)
		if get_meta("bleed_active",false) and not refresh: return false
		set_meta("bleed_active",true)
		bleed_refresh = refresh
		return true
	func apply_burn(_seconds: float, _damage: int, _source: Node) -> bool:
		burns += 1
		return true
	func apply_damage_poison(seconds: float, damage_value: int, source: Node, channel: int) -> bool:
		return poison.apply(source,damage_value,seconds,channel)
	func apply_slow(multiplier: float, _seconds: float) -> void: slow = multiplier
class Authority extends Node2D:
	var hero: Node2D
	var battle_over := false
	var external_pause := false
	var demon_augment_selection_active := false
	var command_regen_per_second := 22.0
	var allies: Array = []
	var invalidations := 0
	func fill_local_monsters_in_rect(rect: Rect2, result: Array) -> void:
		for ally in allies:
			if rect.has_point(ally.global_position): result.append(ally)
	func invalidate_monster_spatial_snapshot() -> void: invalidations += 1
class Ally extends Node2D:
	var current_hp := 10000
	func take_damage(amount: int) -> void: current_hp -= amount
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("MANTICORE: "+message)
func run() -> void:
	root.get_node("CloudStore").stop()
	root.get_node("LoginGateway").remember_session_enabled = false
	var runtime = RUNTIME.new()
	runtime.configure("manticore",DATA.RULES)
	runtime.record_damage(-10.0)
	runtime.record_damage(399.0)
	check(not runtime.ready,"399 locked and negative ignored")
	check(runtime.record_damage(1.0),"400 unlocked")
	runtime.consume()
	check(not runtime.record_damage(1000),"one use")
	runtime.configure("manticore",DATA.RULES)
	check(runtime.satisfy_conditions_for_test(),"local test unlock")
	var authority := Authority.new()
	root.add_child(authority)
	var target := Target.new()
	authority.add_child(target)
	authority.hero = target
	var actor = SCENE.instantiate()
	actor.configure_combat_context(target,authority)
	actor.configure_transcendence(400,0)
	authority.add_child(actor)
	actor.set_physics_process(false)
	actor.visual.set_physics_process(false)
	check(actor.attack_damage == 65 and actor.max_hp == 1750,"snapshot per-hit15%/2 and HP50%")
	check(actor.get_gauge_regen()==15.0 and actor.effective_range()==325.0,"regen cap and radius")
	var ally := Ally.new()
	authority.add_child(ally)
	authority.allies = [ally,actor]
	actor._arrival_explosion()
	check(target.damage==88 and ally.current_hp==9912 and actor.current_hp==1750,"arrival135% friendly fire excludes self")
	actor.arrival = 0.0
	actor.visual.modulate.a = 1.0
	target.position = Vector2(100,0)
	actor._tick_motion(0.01)
	check(actor.motion==actor.Motion.FOCUS and actor.focus==1.0,"1s concentration")
	actor._tick_motion(1.0)
	check(actor.motion==actor.Motion.HUNT and actor.collision_mask==0 and actor.collision_layer==0,"collision-free guided flight")
	actor._tick_motion(1.0)
	var before := target.damage
	actor._tick_motion(0.01)
	actor._tick_motion(0.12)
	check(target.damage-before==130 and actor.motion==actor.Motion.TRACK,"two65hits and retreat")
	var retreat_start: Vector2 = actor.position
	var retreat_end: Vector2 = actor.destination
	target.position += Vector2(80,100)
	for i in range(3):
		actor._tick_motion(0.1)
		check(actor.destination.is_equal_approx(retreat_end),"moving hero never steers retreat destination")
		check(absf((actor.position-retreat_start).cross(retreat_end-retreat_start))<0.1,"retreat follows straight path, no orbit")
	actor._tick_motion(1.0)
	check(actor.motion==actor.Motion.REST and actor.attack_timer==1.5 and actor.collision_mask==3 and actor.collision_layer==2,"interval only after retreat")
	var stopped: Vector2 = actor.position
	target.position += Vector2(900,200)
	for i in range(10): actor._tick_motion(0.1)
	check(actor.position.is_equal_approx(stopped) and actor.motion==actor.Motion.REST,"retreat waits despite moving out-of-range target")
	actor._tick_motion(0.6)
	check(actor.velocity.length()>0.0,"approach resumes after complete cooldown")
	check(is_equal_approx(actor.visual.scale.y*actor.visual.sprite_frames.get_frame_texture(&"idle",0).get_image().get_used_rect().size.y,148.5),"body enlarged1.35 with feet anchored")
	actor.basic_hits = 4
	actor._register_basic_hit()
	check(target.get_meta("bleed_active",false) and actor.basic_hits==0,"five hits bleed")
	actor.motion = actor.Motion.COMBO
	actor.combo_hits = 0
	actor.combo_timer = 0
	actor.triple = true
	actor.triple_success = true
	before = target.damage
	for i in range(3): actor._tick_motion(0.12)
	check(target.damage-before==163 and actor.get_meta("support_shield_hp",0)==70,"triple 50% and stacking4%shield")
	actor.position = Vector2.ZERO
	target.position = actor._flame_point(0)+Vector2(100,0)
	actor.flame_remaining = 30.0
	before = target.damage
	for i in range(100): actor._tick_flames(0.01)
	actor._tick_flames(0.001)
	check(target.damage-before==65 and target.burns==1,"contact1s exact100% and75%burn trigger")
	target.position = Vector2(500,0)
	actor._tick_flames(0.1)
	check(actor.flame_contact[0]==0.0,"contact break resets burn progress")
	actor.transcend_level = 4
	check(actor.flame_count()==2 and actor.flame_cost()==25.0 and actor.effective_range()==350.0 and actor.wave_range()==730.0,"T1/T4")
	actor.transcend_level = 2
	actor.basic_hits = 3
	actor._register_basic_hit()
	check(target.bleed_refresh,"T2 four hits refreshing bleed")
	actor.transcend_level = 5
	check(actor.wave_speed()==500.0 and actor.wave_duration()==7.5,"T5 speed/duration")
	actor.wave_remaining = 7.5
	actor._shoot_wave(Vector2.RIGHT)
	check(actor.attack_timer==1.0 and actor.motion==actor.Motion.TRACK,"T5 interval and random leap")
	actor.position = Vector2.ZERO
	target.position = Vector2(30,0)
	actor.wave_age.fill(-1.0)
	actor.flame_remaining = 0.0
	actor.wave_remaining = 1.0
	actor._shoot_wave(Vector2.RIGHT)
	before = target.damage
	actor._tick_waves(0.1)
	actor._tick_waves(0.1)
	check(target.damage-before==130 and target.slow==0.7,"wave swept hit once200% and slow")
	actor.wave_age[0] = actor.wave_length[0]/actor.wave_speed()+0.45
	check(actor._wave_segment_frame(0,0)==-1 and actor._wave_segment_frame(0,3)>=4 and actor._wave_segment_frame(0,8)<4,"first pillars vanish while later pillars remain")
	check(actor._wave_end_age(0)>actor.wave_age[0],"wave slot survives staggered disappearance")
	var ended_damage := target.damage
	target.position = actor.wave_origin[0]+actor.wave_direction[0]*actor.wave_length[0]
	actor.wave_hit[0] = 0
	actor._tick_waves(0.01)
	check(target.damage==ended_damage,"fading wave does not hit again at endpoint")
	actor.meteor_state.fill(0)
	actor.meteor_cast = 0.0
	actor.meteor_spawned = 0
	actor.meteor_center = Vector2.ZERO
	actor._tick_meteors(2.0)
	check(actor.meteor_spawned==10,"ten meteors over2seconds")
	for i in range(10): check(actor.meteor_dest[i].length()<=300.0,"uniform random points inside scatter")
	actor.meteor_state.fill(0)
	actor.meteor_state[0] = 1
	actor.meteor_age[0] = 0.0
	actor.meteor_points[0] = target.position
	actor.meteor_dest[0] = target.position
	before = target.damage
	actor._tick_meteors(0.01)
	check(target.damage-before==114 and target.poison.entries.size()==1,"meteor175% and poison")
	check(not target.apply_damage_poison(3.0,130,actor,70),"poison no stack or refresh")
	before = target.damage
	target.poison.tick(target,3.0)
	check(target.damage-before==130,"poison total200%")
	actor.meteor_state.fill(0)
	actor.meteor_state[0] = 2
	actor.meteor_age[0] = 0.0
	actor.cloud_fraction[0] = 0.0
	before = target.damage
	for i in range(200): actor._tick_meteors(0.01)
	check(absi(target.damage-before-60000)<=1,"cloud6% total over2s at currentHP")
	actor.current_hp = 100
	actor.set_meta("support_shield_hp",0)
	actor.take_damage(100000)
	check(actor.escaped and actor.current_hp==263 and actor.guard_remaining==5.0 and actor.get_meta("support_shield_hp")==350,"T3 lethal escape lostHP15%, shield20%, DR5s")
	actor.guard_remaining = 0.0
	actor.set_meta("support_shield_hp",0)
	actor.take_damage(100000)
	check(actor.dying,"second lethal kills")
	var sideways := Target.new()
	authority.add_child(sideways)
	var hit_shape := CollisionShape2D.new()
	hit_shape.name = "CollisionShape2D"
	hit_shape.shape = CircleShape2D.new()
	hit_shape.shape.radius = 28.0
	sideways.add_child(hit_shape)
	var hunter = SCENE.instantiate()
	hunter.configure_combat_context(sideways,authority)
	authority.add_child(hunter)
	hunter.set_physics_process(false)
	hunter.visual.set_physics_process(false)
	hunter.position = Vector2(44,0)
	hunter.motion = hunter.Motion.FOCUS
	hunter.focus = 0.0
	hunter._tick_motion(0.0)
	check(hunter.hunt_contact_radius==44.0,"combined actual circle radii16+28 cached per hunt")
	sideways.position = Vector2(0,5)
	hunter._tick_motion(1.0/60.0)
	check(hunter.motion==hunter.Motion.COMBO,"tangential hero at body contact enters combo, no circular chase")
	hunter._tick_motion(0.01)
	hunter._tick_motion(0.12)
	check(sideways.damage==70 and hunter.motion==hunter.Motion.TRACK,"contact still hits35x2 then retreats")
	hunter._tick_motion(1.0)
	check(hunter.collision_layer==2 and hunter.collision_mask==3,"flight restores both collision settings")
	# A fast target crosses the flight path between samples without ending inside the contact radius.
	hunter.position = Vector2.ZERO
	sideways.position = Vector2(-100,0)
	hunter.motion = hunter.Motion.FOCUS
	hunter.focus = 0.0
	hunter._tick_motion(0.0)
	sideways.position = Vector2(100,0)
	hunter._tick_motion(1.0/60.0)
	check(hunter.motion==hunter.Motion.COMBO,"relative swept contact catches crossing target")
	check(is_equal_approx(absf(hunter._flame_point(0).x-hunter.position.x),81.0),"heads spaced162 across body")
	# Flight and locomotion share facing state, including a direction already cached by the parent.
	hunter._update_visual_motion(1.0,true)
	hunter._face_flight(Vector2.LEFT,0)
	check(hunter.visual.flip_h and hunter.visual_facing_sign==-1,"flight updates cached facing left")
	hunter._update_visual_motion(1.0,true)
	check(not hunter.visual.flip_h,"walk faces right after left flight")
	hunter._face_flight(Vector2.RIGHT,3)
	hunter._update_visual_motion(-1.0,true)
	check(hunter.visual.flip_h,"walk faces left after right flight")
	for facing in [-1.0,1.0]:
		hunter._set_visual_facing(facing)
		for animation in [&"idle",&"move",&"attack"]:
			hunter.visual.animation = animation
			for frame in range(hunter.visual.sprite_frames.get_frame_count(animation)):
				hunter.visual.frame = frame
				hunter._sync_visual_anchor()
				var texture: Texture2D = hunter.visual.sprite_frames.get_frame_texture(animation,frame)
				var used := Rect2(texture.get_image().get_used_rect())
				var sign_x := -1.0 if hunter.visual.flip_h else 1.0
				var drawn_center: float = hunter.visual.position.x+(used.get_center().x-texture.get_width()*0.5)*hunter.visual.scale.x*sign_x
				check(is_equal_approx(hunter.status_layer.position.x,drawn_center),"HP/mana centered on drawn frame in both facings")
	hunter._end_motion()
	hunter._update_visual_motion(1.0,true)
	hunter.visual._physics_process(0.25)
	check(hunter.visual.animation==&"move","walk animation resumes after flight cooldown")
	# Each individual pillar finishes 01..04 instead of holding a different static frame per segment.
	hunter.wave_length[0] = 680.0
	for segment in range(13):
		var birth: float = segment*DATA.WAVE_SPACING/hunter.wave_speed()
		for frame in range(4):
			hunter.wave_age[0] = birth+(frame+0.5)*DATA.WAVE_GROW_FRAME_SECONDS
			check(hunter._wave_segment_frame(0,segment)==frame,"pillar plays entire growth sequence01..04")
		hunter.wave_age[0] = birth-0.001
		check(hunter._wave_segment_frame(0,segment)==-1,"unborn pillar not shown")
	var burn = BURN.new()
	burn.apply(1.0,49,target)
	before = target.damage
	for i in range(100): burn.update(target,0.01)
	burn.update(target,0.001)
	check(target.damage-before==49 and burn.remaining==0.0,"burn exact rounded total independent of frame step")
	burn.apply(1.0,49,target)
	burn.update(target,0.3)
	burn.apply(1.0,75,target)
	before = target.damage
	burn.update(target,1.0)
	check(target.damage-before==75,"burn refresh replaces budget")
	authority.queue_free()
	await process_frame
	print("MANTICORE_COMBAT "+("PASS" if failures==0 else "FAIL"))
	quit(0 if failures==0 else 1)
