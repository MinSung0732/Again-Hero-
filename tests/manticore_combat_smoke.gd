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
	check(actor.motion==actor.Motion.HUNT and actor.collision_mask==0,"collision-free guided flight")
	actor._tick_motion(1.0)
	var before := target.damage
	actor._tick_motion(0.01)
	actor._tick_motion(0.12)
	check(target.damage-before==130 and actor.motion==actor.Motion.TRACK,"two65hits and retreat")
	actor._tick_motion(1.0)
	check(actor.motion==actor.Motion.REST and actor.attack_timer==1.5 and actor.collision_mask==3,"interval only after retreat")
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
	target.position = Vector2(80,-30)
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
