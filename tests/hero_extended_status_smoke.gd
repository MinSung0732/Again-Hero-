extends SceneTree
const H = preload("res://tests/hero_status_receipt_helper.gd")
const A = preload("res://src/hero/hero.gd")
const B = preload("res://tests/hero_status_before.gd")
const D = preload("res://tests/hero_status_derived.gd")
const R = preload("res://src/systems/battle_status_receipt.gd")
const ACTION = preload("res://src/systems/status_action_scope.gd")
class Sprite extends Node2D:
	var speed_scale := 3.0
var checks := 0
var failures := 0
var h
func check(v: bool,msg: String):
	checks += 1
	if not v:
		failures += 1
		push_error(msg)
func _initialize():call_deferred("run")
func actor(script,hp := 100,dying := false,resistance := 0.0,timer := 0.0):
	var a = h.actor(script,hp,dying,resistance)
	a.hero_sprite.free()
	a.hero_sprite = Sprite.new()
	a.hero_sprite.self_modulate = Color(0.8,0.7,0.6,1.0)
	a.add_child(a.hero_sprite)
	a.position = Vector2(50,60)
	a.fear_timer = timer
	a.paralysis_timer = timer
	a.paralysis_ratio = 0.75 if timer>0 else 0.0
	a.petrify_timer = timer
	return a
func state(a):
	return [h.state(a),a.fear_timer,a.fear_origin,a.fear_speed_multiplier,a.possession_immunity_timer,
		a.fear_source.global_position if is_instance_valid(a.fear_source) else null,a.paralysis_timer,a.paralysis_ratio,
		a.attack_timer,a.rogue_slash_cooldown_timer,a.petrify_timer,a.petrify_anchor,a.petrify_release_slow,
		a.petrify_release_slow_duration,a.hero_sprite.self_modulate,a.fx_events,
		a.get_meta("fear_active",false),a.get_meta("petrify_active",false)]
func legacy(a,kind,source,duration,strength):
	match kind:
		"fear":
			a.apply_fear(source,duration,strength)
			return a.current_hp>0 and not a.is_dying
		"paralysis":return a.apply_paralysis(strength,duration)
		"petrify":return a.apply_petrify(duration,0.5,2.0)
	return false
func result(a,kind,source,duration,strength,r):
	match kind:
		"fear":return a.apply_fear_with_result(source,duration,r,strength)
		"paralysis":return a.apply_paralysis_with_result(strength,duration,r)
		"petrify":return a.apply_petrify_with_result(duration,r,0.5,2.0)
	return false
func run():
	h = H.new()
	h.root = root
	var r = R.new()
	var source = Node2D.new()
	root.add_child(source)
	source.position = Vector2(10,20)
	for kind in ["fear","paralysis","petrify"]:
		for hp in [0,1,100]:
			for dying in [false,true]:
				for duration in [-1.0,0.0,0.05,5.0]:
					for resist in [0.0,0.5,1.0]:
						for timer in [0.0,2.0,20.0]:
							for strength in [-1.0,0.5,0.75,2.0]:
								var old = actor(B,hp,dying,resist,timer)
								var a = actor(A,hp,dying,resist,timer)
								var accepted = legacy(old,kind,source,duration,strength)
								check(result(a,kind,source,duration,strength,r) and r.complete,"extended supported result completed")
								check(state(old)==state(a),"extended original state/signal/visual order preserved")
								check(r.accepted==accepted,"actual accepted guard result")
								check(r.status_id==StringName(kind) and r.requested_duration==duration and r.requested_strength==(1.0 if kind=="petrify" else strength) and r.identity_verified,"extended original request/identity")
								if accepted:
									var actual_strength = a.fear_speed_multiplier if kind=="fear" else (a.paralysis_ratio if kind=="paralysis" else 1.0)
									check(r.applied_duration==a.get(kind+"_timer") and r.applied_strength==actual_strength,"actual applied timer and strength")
								else:check(r.applied_duration==0 and r.applied_strength==0,"extended rejected payload cleared")
								h.cleanup(old)
								h.cleanup(a)
	# Existing paralysis refresh has no raw AI/status-action event; retain this policy.
	var a = actor(A)
	a.apply_paralysis_with_result(0.75,10.0,r)
	check(r.accepted and a.paralysis_timer==10.0 and a.get_meta("raw")==0 and a.get_meta("credits")==0,"paralysis existing event policy")
	a.apply_paralysis_with_result(0.75,1.0,r)
	check(r.accepted and a.paralysis_timer==1.0,"same-strength paralysis overwrites with shorter duration")
	a.apply_paralysis_with_result(0.5,20.0,r)
	check(not r.accepted and a.paralysis_timer==1.0,"weaker paralysis cannot prolong")
	h.cleanup(a)
	# A missing fear source preserves the original fallback origin and speed clamp.
	a = actor(A)
	a.apply_fear_with_result(null,-1.0,r,0.1)
	check(r.accepted and r.applied_duration==0.05 and r.applied_strength==1.0 and a.fear_origin==a.global_position-Vector2.RIGHT,"fear null-source negative-duration legacy behavior")
	h.cleanup(a)
	# Delayed petrify residue uses the original cast token and restores ambient scope.
	a = actor(A)
	var tint = a.hero_sprite.self_modulate
	var token = ACTION.Token.new()
	var previous = ACTION.begin(a,token)
	a.apply_petrify_with_result(1.0,r,0.5,2.0)
	ACTION.finish(a,previous)
	check(r.accepted and a.get_meta("raw")==1 and a.get_meta("credits")==1 and a.petrify_status_action==token,"petrify original cast captured")
	var ambient = ACTION.Token.new()
	previous=ACTION.begin(a,ambient)
	a._tick_petrify(2.0)
	check(a.petrify_timer==0 and not a.get_meta("petrify_active") and a.hero_sprite.self_modulate==tint,"petrify tint/state restored")
	check(a.slow_timer==2.0 and a.move_multiplier==0.5 and a.get_meta("raw")==2 and a.get_meta("credits")==1,"residue slow does not duplicate cast credit")
	check(ACTION.current(a)==ambient and not ambient.counted and a.petrify_status_action==null,"ambient token restored and stored token released")
	check(r.status_id==&"petrify" and r.applied_duration==1.0,"later residue does not overwrite receipt")
	ACTION.finish(a,previous)
	h.cleanup(a)
	# Signal and visual callbacks can reuse one buffer, without retries or older writes.
	for kind in ["fear","paralysis","petrify"]:
		a = actor(A)
		var gate := [false]
		var nested := [false]
		var callback = func(_kind):
			if gate[0]:return
			gate[0]=true
			nested[0]=a.apply_silence_with_result(3.0,r)
		if kind=="paralysis":a.fx_callback=callback
		else:a.status_applied.connect(callback)
		check(not result(a,kind,source,1.0,1.5,r),"extended callback invalidates outer buffer")
		check(nested[0] and r.complete and r.accepted and r.status_id==&"silence" and r.applied_duration==3.0,"extended latest nested result retained")
		h.cleanup(a)
		a = actor(A)
		var inner = R.new()
		gate=[false]
		callback=func(_kind):
			if gate[0]:return
			gate[0]=true
			a.apply_silence_with_result(3.0,inner)
		if kind=="paralysis":a.fx_callback=callback
		else:a.status_applied.connect(callback)
		check(result(a,kind,source,1.0,1.5,r) and r.accepted and inner.accepted and r.status_id==StringName(kind),"extended independent buffers complete")
		h.cleanup(a)
		a = actor(A)
		check(not result(a,kind,source,1.0,1.5,null) and a.get_meta("raw")==(0 if kind=="paralysis" else 1),"extended null result calls legacy once")
		h.cleanup(a)
		a = actor(D)
		check(not result(a,kind,source,1.0,1.5,r) and a.legacy_calls==1 and not r.complete,"extended derived legacy override once")
		h.cleanup(a)
	# Record before visual callback; capture application even when callback replaces timer.
	for kind in ["paralysis","petrify"]:
		a=actor(A)
		var observed := []
		a.fx_callback=func(_kind):
			observed.append([r.accepted,r.applied_duration,r.applied_strength])
			a.set(kind+"_timer",0.0)
		check(result(a,kind,source,1.0,1.0,r) and r.accepted and r.applied_duration==1.0,"application snapshot precedes visual mutation")
		check(observed==[[true,1.0,1.0]] and a.get(kind+"_timer")==0.0,"visual callback original mutation retained")
		h.cleanup(a)
	source.free()
	print("Hero extended status checks: %d; failures: %d" % [checks,failures])
	quit(1 if failures else 0)
