extends SceneTree
const A = preload("res://src/hero/hero.gd")
const B = preload("res://tests/hero_status_before.gd")
const D = preload("res://tests/hero_status_derived.gd")
const R = preload("res://src/systems/battle_status_receipt.gd")
const REG = preload("res://src/systems/battle_entity_registry.gd")
const ACTION = preload("res://src/systems/status_action_scope.gd")
class Scope extends Node:
	var registry = REG.new()
	func get_battle_entity_handle(n):return registry.get_handle(n)
	func resolve_battle_entity(handle):return registry.resolve(handle)
class Sprite extends Node:
	var speed_scale := 3.0
var checks := 0
var failures := 0
func check(v: bool,msg: String):
	checks += 1
	if not v:
		failures += 1
		push_error(msg)
func _initialize():call_deferred("run")
func actor(script,hp := 100,dying := false,resistance := 0.0,timer := 0.0,multiplier := 1.0):
	var scope = Scope.new()
	root.add_child(scope)
	scope.registry.begin_session(1)
	var a = script.new()
	scope.add_child(a)
	scope.registry.activate(a)
	a.current_hp = hp
	a.is_dying = dying
	a.resistance = resistance
	a.slow_timer = timer
	a.stun_timer = timer
	a.silence_timer = timer
	a.move_multiplier = multiplier
	a.velocity = Vector2(20,30)
	a.hero_sprite = Sprite.new()
	a.add_child(a.hero_sprite)
	a.set_meta("raw",0)
	a.set_meta("credits",0)
	a.set_meta("event_state",[])
	a.status_applied.connect(func(kind):
		a.set_meta("raw",a.get_meta("raw")+1)
		a.get_meta("event_state").append([kind,a.slow_timer,a.stun_timer,a.silence_timer,a.move_multiplier,a.velocity,a.hero_sprite.speed_scale])
	)
	a.status_action_applied.connect(func(_kind):a.set_meta("credits",a.get_meta("credits")+1))
	return a
func cleanup(a):a.get_parent().free()
func legacy(a,kind,multiplier,duration):
	match kind:
		"slow":a.apply_slow(multiplier,duration)
		"stun":a.apply_stun(duration)
		"silence":a.apply_silence(duration)
func result(a,kind,multiplier,duration,r):
	match kind:
		"slow":return a.apply_slow_with_result(multiplier,duration,r)
		"stun":return a.apply_stun_with_result(duration,r)
		"silence":return a.apply_silence_with_result(duration,r)
	return false
func state(a):
	return [a.slow_timer,a.stun_timer,a.silence_timer,a.move_multiplier,a.velocity,a.hero_sprite.speed_scale,a.stun_sprite_speed,
		a.get_meta("stun_active",false),a.get_meta("silence_active",false),a.get_meta("raw"),a.get_meta("credits"),a.get_meta("event_state"),a.status_effect_events.size()]
func run():
	var r = R.new()
	for kind in ["slow","stun","silence"]:
		for hp in [0,1,100]:
			for dying in [false,true]:
				for duration in [-1.0,0.0,0.05,1.0,10.0]:
					for resist in [0.0,0.5,1.0]:
						for timer in [0.0,2.0,20.0]:
							for multiplier in [-1.0,0.5,1.0,2.0]:
								var old = actor(B,hp,dying,resist,timer,0.8)
								var a = actor(A,hp,dying,resist,timer,0.8)
								legacy(old,kind,multiplier,duration)
								check(result(a,kind,multiplier,duration,r) and r.complete,"supported completed result")
								check(state(old)==state(a),"original state/raw event timing/AI memory preserved")
								check(r.accepted==(a.get_meta("raw")>0),"legacy accepted application including unchanged refresh")
								check(r.status_id==StringName(kind) and r.requested_duration==duration and r.requested_strength==(1.0-multiplier if kind=="slow" else 1.0),"original status request")
								check(r.identity_verified and r.victim_life==a.get_parent().registry.get_handle(a) and r.victim_instance_id==a.get_instance_id(),"registry life identity")
								if r.accepted:
									check(r.applied_duration==a.get(kind+"_timer") and r.applied_strength==(1.0-a.move_multiplier if kind=="slow" else 1.0),"resulting timer/strength snapshot")
								else:check(r.applied_duration==0.0 and r.applied_strength==0.0,"rejected result resets previous payload")
								cleanup(old)
								cleanup(a)
	# Existing action credit is per attack/cast; raw refreshes remain available to AI.
	var a = actor(A)
	var token = ACTION.Token.new()
	var previous = ACTION.begin(a,token)
	for i in range(10):
		result(a,"slow",0.5,1.0,r)
		result(a,"stun",1.0,1.0,r)
		result(a,"silence",1.0,1.0,r)
	ACTION.finish(a,previous)
	check(a.get_meta("raw")==30 and a.get_meta("credits")==1 and token.counted,"thirty refreshes one action credit")
	check(ACTION.current(a)==null and a.status_effect_events.size()==30,"scope restored and raw AI memory retained")
	previous=ACTION.begin(a,ACTION.Token.new())
	result(a,"slow",0.5,1.0,r)
	ACTION.finish(a,previous)
	check(a.get_meta("credits")==2,"next originating action counts separately")
	a.ai_memory_clock = 20.0
	a._prune_status_memory()
	check(a.status_effect_events.size()==31,"exact twenty-second AI boundary retained")
	a.ai_memory_clock = 20.01
	a._prune_status_memory()
	check(a.status_effect_events.size()==0,"expired AI memory released")
	cleanup(a)
	for kind in ["slow","stun","silence"]:
		# Same-buffer signal callback invalidates outer result without retrying.
		a = actor(A)
		var nested := [false]
		var callback: Callable
		var reentered := [false]
		callback = func(_kind):
			if reentered[0]:return
			reentered[0]=true
			nested[0]=result(a,"silence",1.0,3.0,r)
		a.status_applied.connect(callback)
		check(not result(a,kind,0.5,1.0,r),"nested signal invalidates older receipt")
		check(nested[0] and r.complete and r.accepted and r.status_id==&"silence" and r.applied_duration==3.0 and a.get_meta("raw")==2,"latest nested status result preserved")
		cleanup(a)
		# Separate buffers each report their actual resulting state.
		a = actor(A)
		var inner = R.new()
		reentered = [false]
		callback = func(_kind):
			if reentered[0]:return
			reentered[0]=true
			result(a,"silence",1.0,3.0,inner)
		a.status_applied.connect(callback)
		check(result(a,kind,0.5,1.0,r) and r.accepted and inner.accepted and r.status_id==StringName(kind),"separate signal buffers complete independently")
		cleanup(a)
		# Null receipt retains legacy operation once, return false is not rejection.
		a = actor(A)
		check(not result(a,kind,0.5,1.0,null) and a.get_meta("raw")==1,"null receipt invokes legacy once")
		cleanup(a)
		a = actor(D)
		check(not result(a,kind,0.5,1.0,r) and not r.complete and a.legacy_calls==1 and not r.accepted,"derived override invoked once without falsely supported result")
		cleanup(a)
	# A freed unregistered actor has no retained Node in the scalar receipt.
	a = A.new()
	root.add_child(a)
	check(a.apply_slow_with_result(0.5,1.0,r) and not r.identity_verified and r.victim_life==Vector3i.ZERO,"unregistered local status has unverified identity")
	a.free()
	check(r.complete and r.accepted,"receipt does not own actor lifetime")
	print("Hero status receipt checks: %d; failures: %d" % [checks,failures])
	quit(1 if failures else 0)
