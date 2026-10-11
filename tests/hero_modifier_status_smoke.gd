extends SceneTree
const H = preload("res://tests/hero_status_receipt_helper.gd")
const A = preload("res://src/hero/hero.gd")
const B = preload("res://tests/hero_status_before.gd")
const D = preload("res://tests/hero_status_derived.gd")
const R = preload("res://src/systems/battle_status_receipt.gd")
const ACTION = preload("res://src/systems/status_action_scope.gd")
class Source extends Node2D:
	var dying := false
var h
var checks := 0
var failures := 0
func check(v: bool,msg: String):
	checks += 1
	if not v:
		failures += 1
		push_error(msg)
func _initialize():call_deferred("run")
func state(a):
	return [h.state(a),a.healing_reduction_ratio,a.healing_reduction_timer,a.damage_taken_increase_ratio,
		a.damage_taken_increase_timer,a.charm_stacks,a.charm_timer,a.charm_immunity_timer,
		a.charm_source.get_ref() if a.charm_source!=null else null,a.charm_cooldown_properties,
		a.get_meta("charm_active",false),a.channeling,a.channel_end_calls,a.fx_events]
func legacy(a,kind,duration,value,source):
	match kind:
		"healing_reduction":return a.apply_healing_reduction(duration,value)
		"damage_taken_increase":return a.apply_damage_taken_increase(duration,value)
		"charm":return a.apply_charm(source,duration)
	return false
func result(a,kind,duration,value,source,r):
	match kind:
		"healing_reduction":return a.apply_healing_reduction_with_result(duration,value,r)
		"damage_taken_increase":return a.apply_damage_taken_increase_with_result(duration,value,r)
		"charm":return a.apply_charm_with_result(source,duration,r)
	return false
func run():
	h=H.new()
	h.root=root
	var r=R.new()
	var source=Source.new()
	root.add_child(source)
	for kind in ["healing_reduction","damage_taken_increase","charm"]:
		for hp in [0,1,1000]:
			for dying in [false,true]:
				for duration in [-1.0,0.0,0.05,3.0]:
					for value in [-1.0,0.0,0.5,2.0]:
						for resist in [0.0,0.5,1.0]:
							for existing in [0,1,2]:
								var old=h.actor(B,hp,dying,resist)
								var a=h.actor(A,hp,dying,resist)
								for target in [old,a]:
									target.channeling=true
									target.charm_stacks=2
									if existing==1:legacy(target,kind,5.0,0.8,source)
									if existing==2:target.charm_immunity_timer=3.0
								var accepted=legacy(old,kind,duration,value,source)
								check(result(a,kind,duration,value,source,r) and r.complete,"modifier completed supported application")
								check(state(old)==state(a),"modifier/charm original state and signal/FX/channel order")
								check(r.accepted==accepted and r.identity_verified,"modifier accepted guard/registry life")
								check(r.status_id==StringName(kind) and r.requested_duration==duration and r.requested_strength==(1.0 if kind=="charm" else value),"modifier original request retained")
								check(r.applied_damage_budget==0 and r.requested_damage==0,"modifier clears previous DOT budget")
								if accepted:
									check(r.applied_duration==a.get(kind+"_timer") and r.applied_strength==(1.0 if kind=="charm" else a.get(kind+"_ratio")),"modifier actual max timer/strength snapshot")
								else:check(r.applied_duration==0 and r.applied_strength==0,"modifier rejected resets payload")
								h.cleanup(old)
								h.cleanup(a)
	# Actual healing math and modifier expiry/clear remain unchanged.
	for value in [-1.0,0.0,0.5,2.0]:
		var old=h.actor(B)
		var a=h.actor(A)
		for kind in ["healing_reduction","damage_taken_increase"]:
			legacy(old,kind,2.0,value,source)
			result(a,kind,2.0,value,source,r)
		for delta in [0.5,1.5,1.0]:
			for amount in [-1,0,1,3,100,5000000000]:
				check(old._get_reduced_healing(amount)==a._get_reduced_healing(amount),"integer healing reduction unchanged")
			old._tick_received_modifiers(delta)
			a._tick_received_modifiers(delta)
			check(state(old)==state(a),"modifier tick/reset boundaries unchanged")
		old._clear_received_modifiers()
		a._clear_received_modifiers()
		check(state(old)==state(a),"modifier clear unchanged")
		h.cleanup(old)
		h.cleanup(a)
	# Actual charm stack-to-legacy bridge, immunity, weak source loss, death and overshoot.
	for scenario in ["expiry","dead_source","freed_source","clear"]:
		var local_source=Source.new()
		root.add_child(local_source)
		var old=h.actor(B)
		var a=h.actor(A)
		for i in range(int(A.SUCCUBUS_BEHAVIOR.CHARM.stacks)):
			check(old.register_succubus_hit(local_source)==a.register_succubus_hit(local_source),"succubus hit threshold bridge unchanged")
		check(state(old)==state(a) and a.charm_timer>0,"legacy stack bridge applies once")
		check(not a.apply_charm_with_result(local_source,1.0,r) or not r.accepted,"active charm rejects repeat")
		if scenario=="dead_source":local_source.dying=true
		if scenario=="freed_source":local_source.free()
		if scenario=="clear":
			old._clear_charm()
			a._clear_charm()
		for delta in [0.5,10.0,20.0]:
			check(old._tick_charm_timers(delta)==a._tick_charm_timers(delta) and state(old)==state(a),"charm source/lifetime/immunity overshoot unchanged")
		old._clear_charm()
		a._clear_charm()
		check(state(old)==state(a) and a.charm_cooldown_properties.is_empty(),"charm clear releases references")
		if is_instance_valid(local_source):local_source.free()
		h.cleanup(old)
		h.cleanup(a)
	var a=h.actor(A)
	check(a.apply_charm_with_result(null,1.0,r) and not r.accepted,"charm invalid source completed rejection")
	var token=ACTION.Token.new()
	var previous=ACTION.begin(a,token)
	for kind in ["healing_reduction","damage_taken_increase","charm"]:result(a,kind,3.0,0.5,source,r)
	ACTION.finish(a,previous)
	check(a.get_meta("raw")==3 and a.get_meta("credits")==1 and ACTION.current(a)==null,"three modifiers one originating action credit")
	h.cleanup(a)
	# Reentrant raw/visual callbacks cannot overwrite the newest result buffer.
	for kind in ["healing_reduction","damage_taken_increase","charm"]:
		for callback in ["signal","visual"]:
			if callback=="visual" and kind=="damage_taken_increase":continue
			a=h.actor(A)
			var gate := [false]
			var nested := [false]
			var cb=func(_kind):
				if gate[0]:return
				gate[0]=true
				nested[0]=a.apply_silence_with_result(1.0,r)
			if callback=="signal":a.status_applied.connect(cb)
			else:a.fx_callback=cb
			check(not result(a,kind,3.0,0.5,source,r),"nested overwrite invalidates older application result")
			check(nested[0] and r.complete and r.status_id==&"silence" and r.accepted,"newest nested payload remains usable")
			h.cleanup(a)
		a=h.actor(A)
		check(not result(a,kind,3.0,0.5,source,null) and a.get_meta("raw")==1,"modifier null buffer invokes legacy once")
		h.cleanup(a)
		a=h.actor(D)
		check(not result(a,kind,3.0,0.5,source,r) and not r.complete and a.legacy_calls==1,"derived override not bypassed or retried")
		h.cleanup(a)
		a=h.actor(A)
		var inner=R.new()
		var gate := [false]
		a.status_applied.connect(func(_kind):
			if gate[0]:return
			gate[0]=true
			a.apply_silence_with_result(1.0,inner)
		)
		check(result(a,kind,3.0,0.5,source,r) and r.accepted and inner.accepted,"separate result buffers remain independent")
		h.cleanup(a)
		a=h.actor(A)
		var observed := []
		a.status_applied.connect(func(_kind):
			observed.append([r.accepted,r.applied_duration,r.applied_strength])
			if kind=="charm":a._clear_charm()
			else:a._clear_received_modifiers()
		)
		check(result(a,kind,3.0,0.5,source,r) and observed==[[true,3.0,1.0 if kind=="charm" else 0.5]],"application snapshot recorded before signal clears state")
		h.cleanup(a)
	source.free()
	print("Hero modifier status receipt checks: ",checks," failures: ",failures)
	quit(1 if failures else 0)
