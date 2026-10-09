extends SceneTree
const SCENE := preload("res://src/monsters/Izanami.tscn")
const DATA := preload("res://src/data/izanami_behavior_catalog.gd")
const RUNTIME := preload("res://src/systems/transcendence_runtime.gd")
var failures := 0
class Target extends Node2D:
	signal status_applied(kind: String)
	signal accepted_damage_hit(source: Node)
	var current_hp := 1000000
	var is_dying := false
	var damage := 0
	var stun := 0.0
	var silence := 0.0
	var slow := 1.0
	var slow_events := 0
	var reject_damage := false
	func take_damage(amount: int, source: Node) -> bool:
		if reject_damage:
			return false
		damage += amount
		accepted_damage_hit.emit(source)
		return true
	func take_status_damage(amount: int, source: Node) -> bool: return take_damage(amount,source)
	func apply_slow(ratio: float, _seconds: float) -> void:
		slow_events += 1
		slow = ratio
		status_applied.emit("slow")
	func apply_stun(seconds: float) -> void:
		stun = seconds
		status_applied.emit("stun")
	func apply_silence(seconds: float) -> bool:
		silence = seconds
		status_applied.emit("silence")
		return true
	func apply_damage_taken_increase(_seconds: float, _ratio: float) -> bool:
		status_applied.emit("vulnerability")
		return true
class Authority extends Node2D:
	var hero: Node2D
	var battle_over := false
	var external_pause := false
	var demon_augment_selection_active := false
	var command_regen_per_second := 20.0
	var allies: Array = []
	func fill_local_monsters_in_rect(rect: Rect2, result: Array) -> void:
		for ally in allies:
			if rect.has_point(ally.global_position): result.append(ally)
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("IZANAMI: "+message)
func run() -> void:
	var runtime = RUNTIME.new()
	runtime.configure("izanami",DATA.RULES)
	for i in range(49): runtime.record_summon("control")
	for i in range(3): runtime.record_status()
	check(not runtime.ready,"49/3 locked")
	runtime.record_summon("tank")
	check(not runtime.ready,"other role excluded")
	check(runtime.record_summon("controller"),"50/3 unlock includes existing controller role")
	runtime.consume()
	check(not runtime.record_status() and not runtime.ready,"one summon only")
	runtime.configure("izanami",DATA.RULES)
	check(runtime.satisfy_conditions_for_test(),"explicit local unlock")
	var authority := Authority.new()
	root.add_child(authority)
	var target := Target.new()
	authority.add_child(target)
	authority.hero = target
	var actor = SCENE.instantiate()
	actor.configure_combat_context(target,authority)
	actor.configure_transcendence(3,0)
	check(actor.max_hp==1085 and actor.attack_damage==58,"cumulative1.5 HP rounding")
	actor.configure_transcendence(10,0)
	authority.add_child(actor)
	actor.set_physics_process(false)
	actor.visual.set_physics_process(false)
	check(actor.max_hp==1095 and actor.attack_damage==65 and actor.summon_snapshot==10,"snapshot stats")
	check(actor.get_gauge_regen()==15 and actor.attack_range==275,"regen/range diameter")
	# A distant target must be approached, while close targets trigger sustained retreat.
	actor.attack_timer = 100.0
	target.position = Vector2(700,0)
	actor._tick_retreat_and_heal(1.0/60.0)
	check(actor.velocity.x > 0 and actor.cached_direction_to_hero.x > 0,"approach outside attack/skill range")
	actor.gauge = 20.0
	actor._try_cast()
	check(actor.gauge == 20.0 and actor.ghost_remaining == 0.0,"no distant skill spend")
	target.position = actor.position+Vector2(500,0)
	actor._try_cast()
	check(actor.ghost_remaining > 0 and actor.gauge == 0.0,"cast while approaching within skill range")
	actor.ghost_remaining = 0.0
	actor.ghost_hits = 0
	target.damage = 0
	target.silence = 0
	target.slow = 1.0
	target.position = actor.position+Vector2(200,0)
	actor._tick_retreat_and_heal(1.0/60.0)
	check(actor.velocity.x < 0 and actor.cached_direction_to_hero.x > 0,"retreat while facing target")
	target.position = actor.position+Vector2(230,0)
	actor._tick_retreat_and_heal(1.0/60.0)
	check(actor.velocity.x < 0,"retreat continues through hysteresis band")
	target.position = actor.position+Vector2(250,0)
	actor.attack_timer = 0.0
	actor._tick_retreat_and_heal(1.0/60.0)
	check(actor.velocity == Vector2.ZERO and target.damage == 65,"hold and basic attack within range")
	target.damage = 0
	actor.position = Vector2.ZERO
	target.position = Vector2.ZERO
	for level in range(6):
		actor.transcend_level = level
		check(actor.skill_cooldown(1)==(2.0 if level>=3 else (4.0 if level>=1 else 8.0)),"level cooldown")
		check(is_equal_approx(actor.fire_radius(),117.0 if level>=3 else 90.0),"level warning/hit radius")
		check(actor.torii_duration()==(15.0 if level>=4 else 10.0),"gate duration")
	actor.transcend_level = 0
	actor.ghost_remaining = 7.0
	for i in range(12): target.take_damage(1,null)
	check(is_equal_approx(target.silence,3.0) and target.slow==0.01 and actor.ghost_remaining==0 and target.damage==113,"12 all-source hits bind once")
	var before := target.damage
	target.take_damage(1,null)
	check(target.damage==before+1,"no recursive/repeated bind")
	actor.transcend_level = 1
	actor.passive_hits = 0
	actor.passive_statuses = 0
	var slow_before := target.slow_events
	actor._create_fire()
	before = target.damage
	for i in range(300): actor._tick_fire(0.01)
	actor._tick_fire(0.01)
	check(target.damage-before==241,"170% plus exactly200% DOT rounded budgets")
	check(actor.passive_hits == 1 and actor.passive_statuses == 1,"one hit/status stack per entire fire lifetime")
	check(target.slow_events-slow_before > 1,"slow refresh still applied every tick")
	actor._create_fire()
	actor._tick_fire(0.5)
	check(actor.passive_hits == 2 and actor.passive_statuses == 2,"new fire cast earns fresh stacks")
	actor.fire_age.fill(-1.0)
	actor._create_fire()
	target.reject_damage = true
	actor._tick_fire(0.5)
	check(actor.passive_hits == 2 and actor.fire_hit_counted[0] == 0,"rejected hits do not consume first stack")
	target.reject_damage = false
	actor._tick_fire(0.5)
	check(actor.passive_hits == 3 and actor.fire_hit_counted[0] == 1,"later accepted DOT earns first stack")
	actor.fire_age.fill(-1.0)
	actor.passive_hits = 0
	actor.passive_statuses = 0
	actor.ghost_remaining = 7.0
	actor.ghost_hits = 0
	for i in range(12): actor._deal_damage(1,true,false)
	check(actor.ghost_remaining == 0 and actor.passive_hits == 1 and actor.passive_statuses == 2,"DOT ghost hits still trigger independent counted bind")
	actor.passive_hits = 0
	for i in range(12): actor._hit(1.0)
	check(actor.passive_hits == 12,"separate basic attacks all count")

	actor.transcend_level = 0
	actor._create_fire()
	before = target.damage
	actor._tick_fire(0.74)
	check(target.damage==before,"warning first")
	target.position = Vector2(1000,1000)
	actor._tick_fire(0.02)
	check(target.damage==before,"snapshot position allows dodge")
	actor.fan_remaining = 2.0
	actor.fan_spawned = 0
	actor.fan_direction = Vector2.RIGHT
	for i in range(20): actor._tick_spirits(0.1)
	check(actor.fan_spawned==8 and actor.spirit_state.size()==8,"bounded8 fan slots")
	for i in range(100): actor._tick_spirits(0.1)
	check(actor.spirit_state.count(0)==8,"spirits expire")
	check(not actor.torii_layer.z_as_relative and actor.torii_layer.z_index < 0 and actor.torii_layer.z_index > -20,"gate behind normalized bodies and above castle floor")
	check(actor.effect_layer.z_index==8 and actor.status_layer.z_index==12,"other effects and bars retain foreground layers")
	actor.set_meta("support_shield_hp",7)
	var shield_step := int(round(actor.max_hp*0.04))
	for level in range(6):
		actor.transcend_level = level
		actor._create_torii()
	check(int(actor.get_meta("support_shield_hp"))==7+6*shield_step,"every level stacks4% on existing shield; slot replacement also grants once")
	actor.fire_age.fill(-1.0)
	actor.ghost_remaining = 0.0
	actor.passive_hits = 12
	actor.passive_statuses = 4
	actor._physics_process(0.01)
	check(int(actor.get_meta("support_shield_hp"))==7+7*shield_step,"both passive thresholds create only one gate and one shield grant")
	actor._physics_process(0.01)
	actor._tick_torii(30.0)
	check(int(actor.get_meta("support_shield_hp"))==7+7*shield_step,"ticks and gate expiration do not grant again or remove shield")
	var hp_before: int = actor.current_hp
	actor.take_damage(10)
	check(actor.current_hp==hp_before and int(actor.get_meta("support_shield_hp"))==7+7*shield_step-10,"incoming damage consumes stacked shield before HP")
	actor.take_damage(int(actor.get_meta("support_shield_hp"))+3)
	check(actor.current_hp==hp_before-3 and int(actor.get_meta("support_shield_hp"))==0,"shield overflow reaches HP exactly")
	actor.transcend_level = 0
	actor.torii_points[0] = target.position
	actor.torii_age[0] = 1.0
	check(actor.aura_modifier(target,"incoming")==1.2 and actor.aura_modifier(target,"outgoing")==0.85,"enemy aura")
	actor.position = target.position
	check(actor.aura_modifier(actor,"outgoing")==1.15 and actor.aura_modifier(actor,"incoming")==0.8,"ally aura")
	actor.transcend_level = 4
	check(actor.aura_modifier(actor,"incoming")==0.6,"lv4 defense")
	actor.transcend_level = 5
	authority.allies.append(actor)
	actor.torii_points[0] = Vector2.ZERO
	actor.torii_age[0] = 1.0
	actor.position = Vector2(0,1)
	actor.clock = 1.0
	actor._tick_torii(0.11)
	actor.position = Vector2(0,-1)
	actor.clock = 1.11
	actor._tick_torii(0.11)
	check(actor.aura_modifier(actor,"speed")==1.4 and actor.aura_modifier(actor,"incoming")==0.3,"gate crossing lv5 buffs")
	actor.position = Vector2(1000,1000)
	actor.clock = 2.2
	check(actor.aura_modifier(actor,"incoming")==1.0 and actor.aura_modifier(actor,"speed")==1.4,"crossing defense1sec/speed5sec independently expire")
	actor.clock = 6.2
	check(actor.aura_modifier(actor,"speed")==1.0,"speed expires")
	authority.external_pause = true
	var time: float = actor.clock
	actor._physics_process(1)
	check(actor.clock==time,"simulation pause freezes all lifetimes")
	authority.external_pause = false
	actor._begin_death()
	check(actor.torii_age.count(-1.0)==4 and actor.aura_modifier(target,"incoming")==1.0,"death clears aura/helpers")
	actor._create_torii()
	check(int(actor.get_meta("support_shield_hp"))==0 and actor.torii_age.count(-1.0)==4,"dead actor cannot generate gates or regain shield")
	authority.free()
	print("IZANAMI_COMBAT: "+("PASS" if failures==0 else "FAILED"))
	quit(0 if failures==0 else 1)
