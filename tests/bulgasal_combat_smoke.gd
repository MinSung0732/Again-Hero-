extends SceneTree
const SCENE := preload("res://src/monsters/Bulgasal.tscn")
const DATA := preload("res://src/data/bulgasal_behavior_catalog.gd")
const RUNTIME := preload("res://src/systems/transcendence_runtime.gd")
const ZEUS := preload("res://src/data/zeus_behavior_catalog.gd")
var failures := 0

class Target extends Node2D:
	var current_hp := 1000000
	var damage_taken := 0
	var hits := 0
	var stunned := 0.0
	var slowed := 1.0
	var heal_reduction := 0.0
	func take_damage(amount: int, _source: Node) -> bool:
		damage_taken += amount
		hits += 1
		return true
	func take_followup_damage(amount: int, source: Node) -> bool:
		return take_damage(amount,source)
	func apply_stun(seconds: float) -> void: stunned = seconds
	func apply_slow(ratio: float, _seconds: float) -> void: slowed = ratio
	func apply_healing_reduction(_seconds: float, ratio: float) -> bool:
		heal_reduction = ratio
		return true

class Authority extends Node2D:
	var hero: Node2D
	var battle_over := false
	var external_pause := false
	var demon_augment_selection_active := false
	var command_regen_per_second := 6.0
	var current_map_size := Vector2(2000,2000)

func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("BULGASAL: " + message)

func run() -> void:
	var rules = RUNTIME.new()
	rules.configure("bulgasal",DATA.RULES)
	for index in range(64): rules.record_summon("tank")
	for index in range(100): rules.record_ally_death()
	check(not rules.ready,"AND needs65 real tanks")
	rules.record_summon("swarm")
	check(not rules.ready,"other roles cannot fulfill tank condition")
	rules.record_summon("tank")
	check(rules.ready,"65 tanks AND100 deaths")
	rules.consume()
	check(not rules.record_summon("tank") and not rules.ready,"once per battle")
	rules.configure("bulgasal",DATA.RULES)
	check(rules.tanks_summoned==0 and rules.allies_died==0,"restart resets")
	check(rules.satisfy_conditions_for_test() and rules.ready,"explicit local unlock supports new metrics")
	check(ZEUS.BASE.move_speed==290 and ZEUS.BASE.attack_cooldown==1.3 and ZEUS.REGEN_RATIO==1.0 and ZEUS.REGEN_CAP==15.0,"Zeus requested tuning")
	var authority := Authority.new()
	root.add_child(authority)
	var target := Target.new()
	authority.add_child(target)
	authority.hero = target
	target.position = Vector2(500,500)
	var actor = SCENE.instantiate()
	actor.configure_combat_context(target,authority)
	actor.configure_transcendence(100,0)
	authority.add_child(actor)
	actor.set_physics_process(false)
	actor.pillars.set_physics_process(false)
	actor.position = Vector2(300,500)
	check(actor.max_hp==1950 and actor.gauge==0 and DATA.GAUGE_MAX==60,"HP death snapshot and gauge")
	check(actor.get_gauge_regen()==6,"regen100% augmented command")
	authority.command_regen_per_second = 100
	check(actor.get_gauge_regen()==15,"regen15cap")
	authority.external_pause = true
	actor._physics_process(1)
	check(actor.phase_elapsed==0 and actor.gauge==0,"pause freezes summon/gauge")
	authority.external_pause = false
	actor._physics_process(0.6)
	check(actor.phase=="idle" and actor.pillars.bodies.size()==8,"fall landing and fixed pillar pool")
	var hp_before: int = actor.current_hp
	actor.on_ally_death(Vector2.ZERO)
	check(actor.max_hp==1951 and actor.current_hp==hp_before,"future death adds max HP without heal")
	target.position = Vector2(500,500)
	actor.resolve_rock_impact(Vector2(500,500))
	check(target.hits==1 and target.damage_taken==450 and target.stunned==2,"inner hit300%, only once")
	target.position = Vector2(750,500)
	actor.resolve_rock_impact(Vector2(500,500))
	check(target.hits==2 and target.damage_taken==713 and target.slowed==0.5,"outer175% and slow50%")
	actor._launch_rock(Vector2(500,500))
	target.position = Vector2(1000,500)
	actor._tick_rock(1)
	check(actor.rock_target==Vector2(500,500) and not actor.rock_active and target.hits==2,"snapshot doesn't follow moving hero")
	actor.add_stacking_shield(0.05)
	var first_shield := int(actor.get_meta("support_shield_hp"))
	actor.add_stacking_shield(0.05)
	check(int(actor.get_meta("support_shield_hp"))==first_shield*2,"eaten shields stack")
	actor.set_meta("support_shield_hp",0)
	actor._set_phase("burrow")
	actor.take_damage(100)
	check(actor.current_hp==hp_before-40,"burrow damage reduction60%")
	actor._end_burrow()
	actor.received_hits=9
	actor.take_damage(1)
	check(actor.retreat_pending==1,"10 accepted hits queue retreat")
	actor.channel.begin(2)
	actor._set_phase("channel")
	actor.skill_cooldowns[2]=20
	actor.apply_silence(1)
	check(actor.phase=="idle" and actor.channel.interrupted and actor.skill_cooldowns[2]==20,"silence interrupts but keeps cooldown")
	actor.channel.begin(2)
	actor._set_phase("channel")
	actor.apply_stun(1)
	check(actor.channel.interrupted and actor.phase=="idle","stun cancels channel")
	actor.stun_remaining=0
	actor.silence_remaining=0
	actor.channel.begin(2)
	actor._set_phase("channel")
	actor._physics_process(2)
	check(actor.phase=="launch","channel completes in combat time")
	actor.collision_mask=15
	actor._physics_process(0.35)
	check(actor.phase=="air" and actor.collision_mask==0 and not actor.visual.visible,"air hides body and disables collision")
	hp_before=actor.current_hp
	actor.take_damage(9999)
	check(actor.current_hp==hp_before,"airborne invulnerability")
	actor._physics_process(1)
	check(actor.phase=="land" and actor.collision_mask==15 and actor.visual.visible,"restore original castle mask")
	target.position=actor.landing_position
	actor._physics_process(0.25)
	check(actor.wave_active and target.stunned==3,"leap impact and waves")
	var wave_hits: int = target.hits
	actor._tick_waves(0.01)
	actor._tick_waves(1)
	check(target.hits==wave_hits+1,"8 rays shared one-hit guard")
	var pool = actor.pillars
	pool.states[0]=2
	pool.ages[0]=0
	pool.bodies[0].position=Vector2(500,500)
	pool.bodies[0].collision_layer=1
	var hits_before: int = target.hits
	actor._begin_death()
	check(pool.retiring and pool.states[0]==3 and pool.bodies[0].collision_layer==0 and target.hits==hits_before,"death destroys props without damage")
	check(pool.get_parent()==authority,"pillar death animation survives actor removal")
	actor.queue_free()
	pool.queue_free()
	authority.queue_free()
	await process_frame
	print("BULGASAL_COMBAT: ","PASS" if failures==0 else "FAIL", " failures=",failures)
	quit(0 if failures==0 else 1)
