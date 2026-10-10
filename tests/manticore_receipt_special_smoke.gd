extends SceneTree
const H = preload("res://tests/manticore_receipt_helper.gd")
const W = preload("res://tests/manticore_wave_receipt_helper.gd")
const RESULT = preload("res://src/systems/battle_damage_receipt.gd")
const BEFORE = preload("res://tests/manticore_before.gd")
const AFTER = preload("res://src/monsters/manticore.gd")
const POPUPS = preload("res://tests/popups.gd")
class Authority extends Node:
	var requests: Array = []
	func clamp_monster_wander_position(point):
		requests.append(point)
		return Vector2(-100,0)
var checks := 0
var failures := 0
var h
func check(value: bool,message: String):
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func _initialize():call_deferred("run")
func actor(script,hp,shield,escaped,guard,level):
	var a = h.actor(script,hp,shield)
	a.max_hp = 1550
	a.escaped = escaped
	a.guard_remaining = guard
	a.transcend_level = level
	a.hero = a.get_parent().hero
	a.hero.position = Vector2(100,0)
	a.collision_layer = 2
	a.collision_mask = 3
	a.flame_remaining = 15.0
	a.wave_remaining = 5.0
	return a
func state(a):
	return [a.current_hp,a.dying,a.events,a.escaped,a.guard_remaining,a.motion,a.destination,
		a.get_meta("support_shield_hp"),a.get_meta("support_shield_capacity",0),
		a.collision_layer,a.collision_mask,a.get_meta("ignore_monster_separation",false),
		a.visual.animation,a.flame_remaining,a.wave_remaining,a.meteor_state,a.wave_age]
func run():
	h = H.new()
	h.root = root
	var r = RESULT.new()
	for hp in [-1,0,1,60,600,1550]:
		for escaped in [false,true]:
			for guard in [0.0,5.0]:
				for level in [0,2,3,4,5]:
					for shield in [0,100,300]:
						for amount in [0,1,100,4000]:
							var old = actor(BEFORE,hp,shield,escaped,guard,level)
							var fresh = actor(AFTER,hp,shield,escaped,guard,level)
							old.take_damage(amount)
							check(fresh.take_damage_with_result(amount,r),"first escape receipt completes")
							check(state(old)==state(fresh),"HP/recovery/shield/track/audio/death parity")
							var reduced = roundi(amount*(0.6 if guard>0 else 1.0))
							var absorbed = mini(shield,reduced) if amount>0 else 0
							check(r.hp_damage==maxi(hp-fresh.current_hp,0) and r.shield_absorbed==absorbed,"actual HP decrease; shield consumption before generated shield")
							check(r.accepted==(r.hp_damage+r.shield_absorbed>0) and r.death_started==fresh.dying,"escape and actual death separated")
							check(r.requested_damage==amount and r.identity_verified,"original request before guard reduction")
							h.cleanup(old)
							h.cleanup(fresh)
	# HP may rise during first escape; do not invent a zero-HP damage stage.
	var a = actor(AFTER,60,0,false,0.0,3)
	a.take_damage_with_result(100,r)
	check(a.current_hp==233 and a.escaped and not r.accepted and r.hp_damage==0 and not r.death_started,"immediate recovery increases HP; no phantom damage/death")
	check(a.guard_remaining==5.0 and a.get_meta("support_shield_hp")==310,"3rd transcend guard and generated shield")
	check(a.motion==a.Motion.TRACK and a.destination==Vector2(-650,0) and a.collision_layer==0 and a.collision_mask==0,"first escape double-range collision-free track")
	check(a.events==[["cue","escape"],["cue","retreat"],"stop_visual"],"legacy first escape sound/visual order")
	a._end_motion()
	check(a.motion==a.Motion.REST and a.collision_layer==2 and a.collision_mask==3 and not a.get_meta("ignore_monster_separation"),"track exit collision/separation restoration")
	check(a.attack_timer==1.5 and a.events[-1]==["play",&"idle"],"track exit attack delay and idle")
	a.take_damage_with_result(1000,r)
	check(r.shield_absorbed==310 and r.hp_damage==233 and r.death_started and a.dying,"later reduced lethal consumes shield then starts real death")
	check(a.events[-3]== "stop_audio" and a.events[-2]==["cue","death"] and a.events[-1]=="death","death audio precedes actual parent death")
	check(a.flame_remaining==0.0 and a.wave_remaining==0.0 and a.meteor_state==PackedInt32Array([0,0,0,0,0,0,0,0,0,0]) and a.wave_age==PackedFloat32Array([-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1]),"death cancels all active skill arrays")
	h.cleanup(a)
	# Track fallback at overlap, boundary clamping and increased flame range.
	a = actor(AFTER,600,0,false,0.0,4)
	a.hero.position = Vector2.ZERO
	var authority = Authority.new()
	a.get_parent().add_child(authority)
	a.combat_authority = authority
	a.take_damage_with_result(1000,r)
	check(authority.requests==[Vector2(-700,0)] and a.destination==Vector2(-100,0),"escape overlap fallback and actual destination clamp")
	check(r.hp_damage==367 and r.accepted and not r.death_started,"recovery can leave actual HP loss without death")
	h.cleanup(a)
	# Native legacy HP0 behavior is preserved; no added HP<=0 rejection.
	a = actor(AFTER,0,0,false,0.0,0)
	check(a.take_damage_with_result(1,r) and a.current_hp==233 and a.escaped and not r.accepted,"original first escape from HP0 still works")
	h.cleanup(a)
	a = actor(AFTER,0,0,true,0.0,0)
	check(a.take_damage_with_result(1,r) and r.death_started and not r.accepted,"HP0 after escape still reaches existing death guard")
	h.cleanup(a)
	# Requested/visual damage remains uncapped; result reports clamped HP loss.
	a = actor(AFTER,23,0,true,0.0,0)
	a.take_damage_with_result(10000,r)
	check(a.events[0]==10000 and r.hp_damage==23 and r.requested_damage==10000,"popup amount preserved independently of actual HP damage")
	h.cleanup(a)
	# The escape cue runs before assignment; nested result records its own writes.
	a = actor(AFTER,600,0,false,0.0,0)
	var inner = RESULT.new()
	a.audio_bank.callback = func(cue):
		if cue=="escape":
			a.audio_bank.callback = Callable()
			a.take_damage_with_result(7,inner)
	check(a.take_damage_with_result(1000,r) and r.hp_damage==360 and inner.hp_damage==7 and a.current_hp==233,"separate buffers measure actual assignments after nested cue")
	h.cleanup(a)
	a = actor(AFTER,60,0,false,0.0,3)
	var nested_ok := [false]
	a.audio_bank.callback = func(cue):
		if cue=="escape":
			a.audio_bank.callback = Callable()
			nested_ok[0] = a.take_damage_with_result(7,r)
	check(not a.take_damage_with_result(100,r),"escape cue same-buffer reentry invalidates outer")
	check(nested_ok[0] and r.complete and r.hp_damage==7 and r.requested_damage==7 and a.current_hp==233 and not r.death_started,"newer cue result preserved without replay")
	h.cleanup(a)
	# New survival shield cannot erase the snapshot of shield already consumed.
	a = actor(AFTER,600,100,false,0.0,3)
	a.take_damage_with_result(1000,r)
	check(r.shield_absorbed==100 and a.get_meta("support_shield_hp")==310 and r.hp_damage==367,"consumed shield distinct from generated survival shield")
	h.cleanup(a)
	# Death cleanup callback can close the common guard or overwrite the receipt.
	for mode in ["guard","overwrite"]:
		a = actor(AFTER,60,0,true,0.0,0)
		a.audio_bank.callback = func(cue):
			if cue=="stop_all":
				a.audio_bank.callback = Callable()
				if mode=="guard":a.dying = true
				else:a.take_damage_with_result(7,r)
		var completed = a.take_damage_with_result(100,r)
		if mode=="guard":
			check(completed and r.hp_damage==60 and not r.death_started and a.events.count("death")==0,"audio closes actual common guard")
		else:
			check(not completed and r.complete and not r.accepted and r.death_started and r.requested_damage==7 and a.events.count("death")==1,"nested HP0 hit starts actual death; no stale outer write")
		h.cleanup(a)
	# Actual wave: first escape and later death use distinct damage results.
	var w = W.new()
	w.root = root
	var shot = load("res://tests/wave_projectile_after.gd")
	var world = w.world(shot,60,0,100)
	world.a.escaped = false
	world.a.max_hp = 1550
	world.a.hero = world.hero
	w.sweep(world)
	check(world.hero.kills==0 and world.hero.hits==2 and world.a.current_hp==233 and world.a.motion==world.a.Motion.TRACK,"wave first escape not kill")
	world.hero.monsters = [world.a]
	world.p.setup("berserker_wave",Vector2.RIGHT,1000,700.0,700.0,{},world.hero)
	world.p.set_physics_process(false)
	w.sweep(world)
	check(world.hero.kills==1 and world.a.dying,"later wave starts actual death once")
	w.cleanup(world)
	world = w.world(shot,60,0,100)
	world.a.escaped = false
	world.a.max_hp = 1550
	world.a.audio_bank.callback = func(cue):
		if cue=="escape":
			world.a.audio_bank.callback = Callable()
			world.a.take_damage_with_result(7,world.p._wave_damage_receipt)
	w.sweep(world)
	check(world.hero.kills==0 and world.hero.hits==2 and world.a.current_hp==233 and world.a.events.count(["cue","escape"])==1,"wave invalidation never repeats first escape")
	w.cleanup(world)
	world = w.world(shot,0,10,100)
	w.sweep(world)
	check(world.a.dying and world.p._wave_damage_receipt.accepted and world.p._wave_damage_receipt.death_started,"HP0 shield hit may begin native death")
	check(world.hero.kills==0 and world.hero.hits==2,"preexisting HP0 target gets no new kill reward")
	w.cleanup(world)
	POPUPS.callback = Callable()
	print("Manticore special checks: ",checks,"; failures: ",failures)
	quit(1 if failures else 0)
