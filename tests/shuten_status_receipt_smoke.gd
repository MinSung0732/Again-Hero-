extends SceneTree
const H = preload("res://tests/hero_status_receipt_helper.gd")
const HERO = preload("res://src/hero/hero.gd")
const LEGACY = preload("res://tests/hero_status_legacy_only.gd")
const DERIVED = preload("res://tests/hero_status_derived.gd")
const PORT = preload("res://src/systems/received_afflictions.gd")
const OLD_PORT = preload("res://tests/afflictions_before.gd")
const A = preload("res://tests/shuten_status_after.gd")
const B = preload("res://tests/shuten_status_before.gd")
const R = preload("res://src/systems/battle_status_receipt.gd")
const ACTION = preload("res://src/systems/status_action_scope.gd")
class Generic extends Node2D:
	var current_hp := 10000
	var max_hp := 20000
	var active := true
	var fx_events: Array = []
	var fx_callback: Callable
	var damage_events: Array = []
	func take_status_damage(amount,source):
		damage_events.append([amount,source.get_instance_id() if is_instance_valid(source) else 0])
		current_hp=maxi(current_hp-amount,0)
		return amount>0
var h
var checks := 0
var failures := 0
func check(v: bool,msg: String):
	checks+=1
	if not v:
		failures+=1
		push_error(msg)
func _initialize():call_deferred("run")
func legacy(a,kind,duration,value,source,action=null):
	match kind:
		"slow":OLD_PORT.apply_slow(a,value,duration,action)
		"stun":OLD_PORT.apply_stun(a,duration,action)
		"silence":OLD_PORT.apply_silence(a,duration,action)
		"bleed":OLD_PORT.apply_bleed_current(a,duration,value,source,action)
func result(a,kind,duration,value,source,r,action=null):
	match kind:
		"slow":return PORT.apply_slow_with_result(a,value,duration,r,action)
		"stun":return PORT.apply_stun_with_result(a,duration,r,action)
		"silence":return PORT.apply_silence_with_result(a,duration,r,action)
		"bleed":return PORT.apply_bleed_current_with_result(a,duration,value,source,r,action)
	return false
func state(a):
	return [h.state(a),a.bleed_timer,a.bleed_duration,a.bleed_elapsed,a.bleed_tick_timer,a.bleed_total_damage,a.bleed_damage_applied,a.get_meta("bleed_active",false),a.fx_events]
func generic_state(a):
	var n=a.get_node_or_null("ReceivedAfflictions")
	return [a.current_hp,a.is_physics_processing(),a.get_meta("received_slow_multiplier",1.0),a.get_meta("stun_active",false),a.get_meta("silence_active",false),a.get_meta("bleed_active",false),a.fx_events,a.damage_events,
		[n.slow_remaining,n.stun_remaining,n.silence_remaining,n.bleed_remaining,n.bleed_duration,n.bleed_elapsed,n.bleed_budget,n.bleed_paid,n.physics_before_stun,n.is_physics_processing()] if n!=null else []]
func caller(script,target):
	var a=script.new()
	root.add_child(a)
	a.hero=target
	a._next_action()
	return a
func caller_state(a):
	return [a.damage_events,a.audio_events,a.cooldowns,a.chain_age,a.chain_state,a.chain_immunity.values(),a.records.size()]
func run():
	h=H.new()
	h.root=root
	var r=R.new()
	var source=Node2D.new()
	root.add_child(source)
	for kind in ["slow","stun","silence","bleed"]:
		for hp in [0,1,10000]:
			for dying in [false,true]:
				for duration in [-1.0,0.0,0.1,3.0]:
					for value in [-1.0,0.0,0.06,2.0]:
						for resist in [0.0,0.5,1.0]:
							for existing in [false,true]:
								var old=h.actor(HERO,hp,dying,resist)
								var a=h.actor(HERO,hp,dying,resist)
								if existing:
									legacy(old,kind,5.0,0.5,source)
									legacy(a,kind,5.0,0.5,source)
								var raw=a.get_meta("raw")
								legacy(old,kind,duration,value,source,ACTION.Token.new())
								check(result(a,kind,duration,value,source,r,ACTION.Token.new()) and r.complete,"native adapter completes including outer guard rejection")
								check(state(old)==state(a),"adapter original state/raw/scope/bleed conversion preserved")
								check(r.accepted==(a.get_meta("raw")>raw) and r.identity_verified,"adapter accepted actual application")
								check(r.status_id==StringName(kind) and r.requested_duration==duration,"adapter kind/duration reset")
								check(ACTION.current(a)==null,"adapter action restored")
								if r.accepted and kind=="bleed":check(r.applied_damage_budget==a.bleed_total_damage,"current HP ratio converted to native bleed scheduled budget")
								h.cleanup(old)
								h.cleanup(a)
	# Generic components keep exact legacy behavior, including their existing duration rules.
	for kind in ["slow","stun","silence","bleed"]:
		for hp in [0,1,10000]:
			for duration in [-1.0,0.0,1.0,3.0]:
				for value in [-1.0,0.0,0.06,2.0]:
					var old=Generic.new()
					var a=Generic.new()
					root.add_child(old)
					root.add_child(a)
					old.current_hp=hp
					a.current_hp=hp
					legacy(old,kind,duration,value,source)
					check(not result(a,kind,duration,value,source,r) and not r.complete,"generic status applies once with unavailable result")
					check(generic_state(old)==generic_state(a),"generic actual component fields/physics/visual preserved")
					if kind=="bleed" and duration>0 and hp>0:
						old.get_node("ReceivedAfflictions")._tick_extra(duration)
						a.get_node("ReceivedAfflictions")._tick_extra(duration)
						check(generic_state(old)==generic_state(a),"generic actual bleed lifetime/payment preserved")
					old.free()
					a.free()
	# A real generic component restores its target's prior physics state on expiry/clear.
	for initial_physics in [false,true]:
		var old=Generic.new()
		var a=Generic.new()
		root.add_child(old)
		root.add_child(a)
		old.set_physics_process(initial_physics)
		a.set_physics_process(initial_physics)
		legacy(old,"stun",1.0,0,source)
		result(a,"stun",1.0,0,source,r)
		old.get_node("ReceivedAfflictions")._tick_extra(2.0)
		a.get_node("ReceivedAfflictions")._tick_extra(2.0)
		check(generic_state(old)==generic_state(a) and a.is_physics_processing()==initial_physics,"generic stun resumes previous physics")
		OLD_PORT.reset_on(old)
		PORT.reset_on(a)
		check(generic_state(old)==generic_state(a) and not a.get_node("ReceivedAfflictions").is_physics_processing(),"generic reset retained component lifetime")
		old.free()
		a.free()
	for script in [LEGACY,DERIVED]:
		for kind in ["slow","stun","silence","bleed"]:
			var old=h.actor(script)
			var a=h.actor(script)
			legacy(old,kind,3.0,0.5,source)
			check(not result(a,kind,3.0,0.5,source,r) and not r.complete and state(old)==state(a),"legacy and derived adapter fallback unchanged")
			if script==DERIVED:check(a.legacy_calls==1,"derived override once")
			h.cleanup(old)
			h.cleanup(a)
	# Actual Shuten fog/blast/bind/stun callers with both native and generic targets.
	for generic in [false,true]:
		for kind in ["fog","blast","bleeding_blast","stun","chain"]:
			for hp in [0,1,10000]:
				for inside in [false,true]:
					var old_target=Generic.new() if generic else h.actor(HERO,hp)
					var target=Generic.new() if generic else h.actor(HERO,hp)
					if generic:
						root.add_child(old_target)
						root.add_child(target)
						old_target.current_hp=hp
						target.current_hp=hp
					old_target.global_position=Vector2.ZERO if inside else Vector2(1000,1000)
					target.global_position=old_target.global_position
					if kind=="bleeding_blast":
						old_target.set_meta("bleed_active",true)
						target.set_meta("bleed_active",true)
					var old=caller(B,old_target)
					var a=caller(A,target)
					for actor in [old,a]:
						match kind:
							"fog":actor._apply_fog(actor.hero,0,0.5)
							"blast","bleeding_blast":actor._blast_target(actor.hero,Vector2.ZERO,1)
							"stun":actor._apply_stun(actor.hero,2.0,1)
							"chain":actor._bind_chain(0,actor.hero)
					check(caller_state(old)==caller_state(a),"actual caller damage/audio/cooldown/chain state preserved")
					check((generic_state(old_target)==generic_state(target)) if generic else (state(old_target)==state(target)),"actual caller target original state preserved")
					if generic:check(not a.status_result_complete,"generic caller never infers native receipt")
					if kind=="chain" and not generic:check(a.status_result_complete and a.status_receipt.status_id==&"silence","chain latest result explicitly silence")
					if generic:
						old_target.free()
						target.free()
					else:
						h.cleanup(old_target)
						h.cleanup(target)
					old.free()
					a.free()
	var rejected=h.actor(HERO,10000)
	rejected.set_meta("bleed_active",true)
	check(result(rejected,"bleed",3,0.06,source,r) and not r.accepted and r.applied_damage_budget==0 and rejected.get_meta("raw")==0,"metadata bleed guard retained even if timer is zero")
	h.cleanup(rejected)
	for kind in ["fog","blast"]:
		var target=Generic.new()
		root.add_child(target)
		target.active=false
		var a=caller(A,target)
		if kind=="fog":a._apply_fog(target,0,1.0)
		else:a._blast_target(target,Vector2.ZERO,1)
		check(a.damage_events.is_empty() and not a.status_result_complete and target.get_node_or_null("ReceivedAfflictions")==null,"inactive generic caller does not allocate/apply")
		target.free()
		a.free()
	var a=h.actor(HERO,10000)
	var actor=caller(A,a)
	var id=actor.status_receipt.get_instance_id()
	for i in range(20):actor._apply_fog(a,0,0.01)
	actor._bind_chain(0,a)
	check(a.get_meta("raw")==22 and a.get_meta("credits")==1,"fog and chain same action raw ticks preserved one credit")
	check(actor.status_receipt.get_instance_id()==id and actor.status_receipt.revision==22,"caller reuses scalar buffer across effects")
	check(not actor._bind_chain(0,a) and not actor.status_result_complete,"immune bind invalidates earlier result availability")
	var ambient=ACTION.Token.new()
	var prev=ACTION.begin(a,ambient)
	result(a,"stun",1.0,0,source,r,ACTION.Token.new())
	check(ACTION.current(a)==ambient,"adapter restores ambient scope")
	ACTION.finish(a,prev)
	h.cleanup(a)
	actor.free()
	for kind in ["slow","stun","silence","bleed"]:
		a=h.actor(HERO,10000)
		var gate := [false]
		a.status_applied.connect(func(_kind):
			if gate[0]:return
			gate[0]=true
			a.apply_silence_with_result(2,r)
		)
		check(not result(a,kind,1,0.5,source,r) and r.complete and r.status_id==&"silence","adapter nested overwrite never retries")
		check(a.get_meta("raw")==2 and ACTION.current(a)==null,"adapter nested original events/scope once")
		h.cleanup(a)
		a=h.actor(HERO,10000)
		check(not result(a,kind,1,0.5,source,null) and a.get_meta("raw")==1,"null result adapter legacy once")
		h.cleanup(a)
	source.free()
	print("Shuten status adapter checks: ",checks," failures: ",failures)
	quit(1 if failures else 0)
