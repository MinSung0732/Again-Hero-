extends SceneTree
const H = preload("res://tests/hero_status_receipt_helper.gd")
const A = preload("res://src/hero/hero.gd")
const B = preload("res://tests/hero_status_before.gd")
const D = preload("res://tests/hero_status_derived.gd")
const R = preload("res://src/systems/battle_status_receipt.gd")
const ACTION = preload("res://src/systems/status_action_scope.gd")
var h
var checks := 0
var failures := 0
func check(v: bool,msg: String):
	checks += 1
	if not v:
		failures += 1
		push_error(msg)
func _initialize():call_deferred("run")
func entries(a):
	var values := []
	for id in a.damage_poison_tracker.entries:
		var e = a.damage_poison_tracker.entries[id]
		values.append([id,e.total,e.duration,e.elapsed,e.applied,e.tick])
	return values
func state(a):
	return [h.state(a),a.poison_timer,a.poison_tick_interval,a.poison_ticks_remaining,a.poison_damage_remaining,
		a.poison_tick_timer,a.poison_flash_timer,a.poison_flash_active,a.modulate,
		a.bleed_timer,a.bleed_duration,a.bleed_elapsed,a.bleed_tick_timer,a.bleed_total_damage,a.bleed_damage_applied,
		a.burn_runtime.remaining,a.burn_runtime.duration,a.burn_runtime.elapsed,a.burn_runtime.total,a.burn_runtime.paid,
		a.burn_runtime.tick,a.burn_runtime.revision,entries(a),a.damage_events,a.current_hp,a.fx_events,
		a.get_meta("poison_active",false),a.get_meta("bleed_active",false),a.get_meta("burn_active",false)]
func legacy(a,kind,duration,value,source,refresh := false):
	match kind:
		"poison":
			a.apply_poison(duration,value,0.5,source)
			return a.current_hp>0 and not a.is_dying
		"damage_poison":return a.apply_damage_poison(duration,int(value),source)
		"bleed":return a.apply_bleed(duration,source,value,refresh)
		"burn":return a.apply_burn(duration,int(value),source)
	return false
func result(a,kind,duration,value,source,r,refresh := false):
	match kind:
		"poison":return a.apply_poison_with_result(duration,value,r,0.5,source)
		"damage_poison":return a.apply_damage_poison_with_result(duration,int(value),source,r)
		"bleed":return a.apply_bleed_with_result(duration,r,source,value,refresh)
		"burn":return a.apply_burn_with_result(duration,int(value),r,source)
	return false
func run():
	h=H.new()
	h.root=root
	var r = R.new()
	var source = Node.new()
	root.add_child(source)
	for kind in ["poison","damage_poison","bleed","burn"]:
		for hp in [0,1,1000]:
			for dying in [false,true]:
				for duration in [-1.0,0.0,0.1,3.0]:
					for value in [-1.0,0.0,0.06,200.0]:
						for active in [false,true]:
							for refresh in [false,true]:
								var old = h.actor(B,hp,dying)
								var a = h.actor(A,hp,dying)
								if active:
									legacy(old,kind,2.0,100.0,source)
									legacy(a,kind,2.0,100.0,source)
								var accepted = legacy(old,kind,duration,value,source,refresh)
								check(result(a,kind,duration,value,source,r,refresh) and r.complete,"DOT result completed")
								check(state(old)==state(a),"DOT original guards/budgets/FX/events preserved")
								check(r.accepted==accepted and r.identity_verified,"DOT accepted guard and identity")
								var id = "poison" if kind=="damage_poison" else kind
								check(r.status_id==StringName(id) and r.requested_duration==duration and r.requested_damage==(int(value) if kind in ["damage_poison","burn"] else 0),"DOT original request and int budget")
								if accepted:
									var budget = a.poison_damage_remaining if kind=="poison" else (a.bleed_total_damage if kind=="bleed" else (a.burn_runtime.total if kind=="burn" else int(value)))
									check(r.applied_damage_budget==budget,"DOT recorded scheduled budget")
									var seconds=a.poison_timer if kind=="poison" else (a.bleed_timer if kind=="bleed" else (a.burn_runtime.remaining if kind=="burn" else duration))
									check(r.applied_duration==seconds,"actual DOT scheduled duration")
								else:check(r.applied_damage_budget==0 and r.applied_duration==0,"DOT rejection resets previous budget")
								h.cleanup(old)
								h.cleanup(a)
	# Tick actual original code with simulated incoming damage; preserve integer distribution.
	for kind in ["poison","damage_poison","bleed","burn"]:
		for deltas in [[0.25,0.25,0.5,1.0,1.0],[1.0,1.0,1.0],[3.1]]:
			var old=h.actor(B,10000)
			var a=h.actor(A,10000)
			legacy(old,kind,3.0,0.06 if kind in ["poison","bleed"] else 200.0,source)
			result(a,kind,3.0,0.06 if kind in ["poison","bleed"] else 200.0,source,r)
			var original_budget=r.applied_damage_budget
			for delta in deltas:
				for target in [old,a]:
					match kind:
						"poison":target._update_poison(delta)
						"damage_poison":target._update_damage_poison(delta)
						"bleed":target._update_bleed(delta)
						"burn":target.burn_runtime.update(target,delta)
				check(state(old)==state(a),"DOT cumulative tick distribution unchanged")
			check(r.applied_damage_budget==original_budget and r.complete,"later DOT ticks do not rewrite application result")
			h.cleanup(old)
			h.cleanup(a)
	# Source/channel dedupe, independent channels, expiry and source loss.
	var a=h.actor(A,10000)
	check(a.apply_damage_poison_with_result(3.0,100,source,r) and r.accepted,"damage poison first source")
	a.apply_damage_poison_with_result(1.0,200,source,r)
	check(not r.accepted and a.damage_poison_tracker.entries.size()==1,"same-source poison cannot refresh/stack")
	a.apply_damage_poison_with_result(1.0,200,source,r,1)
	check(r.accepted and a.damage_poison_tracker.entries.size()==2,"independent channel accepted")
	a._update_damage_poison(4.0)
	check(a.damage_poison_tracker.entries.is_empty() and not a.get_meta("poison_active"),"damage poison expiry releases entries")
	a.apply_damage_poison_with_result(1.0,200,null,r)
	check(not r.accepted,"damage poison requires valid source")
	h.cleanup(a)
	# All effects in one action still count once; independent next action counts again.
	a=h.actor(A,10000)
	var token=ACTION.Token.new()
	var previous=ACTION.begin(a,token)
	for kind in ["poison","damage_poison","bleed","burn"]:result(a,kind,3.0,0.06 if kind in ["poison","bleed"] else 200.0,source,r)
	ACTION.finish(a,previous)
	check(a.get_meta("raw")==4 and a.get_meta("credits")==1,"four DOT applications one originating action")
	check(ACTION.current(a)==null,"DOT action scope restored")
	h.cleanup(a)
	# Same buffer in status signal retains latest nested payload, including non-DOT reset.
	for kind in ["poison","damage_poison","bleed","burn"]:
		a=h.actor(A,10000)
		var gate := [false]
		var nested := [false]
		a.status_applied.connect(func(_kind):
			if gate[0]:return
			gate[0]=true
			nested[0]=a.apply_silence_with_result(3.0,r)
		)
		check(not result(a,kind,3.0,0.06 if kind in ["poison","bleed"] else 200.0,source,r),"DOT signal invalidates older receipt")
		check(nested[0] and r.status_id==&"silence" and r.complete and r.applied_damage_budget==0 and r.requested_damage==0,"nested non-DOT resets budget and survives older writer")
		h.cleanup(a)
		a=h.actor(A,10000)
		check(not result(a,kind,3.0,200.0,source,null) and a.get_meta("raw")==1,"DOT null receipt calls legacy once")
		h.cleanup(a)
		a=h.actor(D,10000)
		check(not result(a,kind,3.0,200.0,source,r) and a.legacy_calls==1 and not r.complete,"DOT derived override once")
		h.cleanup(a)
	# Separate buffers and visual callbacks preserve the application before mutation.
	for kind in ["poison","damage_poison","bleed","burn"]:
		a=h.actor(A,10000)
		var inner=R.new()
		var gate := [false]
		a.status_applied.connect(func(_kind):
			if gate[0]:return
			gate[0]=true
			a.apply_silence_with_result(1.0,inner)
		)
		check(result(a,kind,3.0,0.06 if kind in ["poison","bleed"] else 200.0,source,r) and r.accepted and r.applied_damage_budget>0 and inner.accepted,"separate DOT buffer unaffected by nested status")
		h.cleanup(a)
	for kind in ["bleed","burn"]:
		a=h.actor(A,10000)
		var observed := []
		a.fx_callback=func(_kind):
			observed.append([r.accepted,r.applied_damage_budget])
			if kind=="burn":a._clear_burn()
			else:a._clear_bleed()
		check(result(a,kind,3.0,200.0,source,r) and r.accepted and r.applied_damage_budget>0 and observed==[[true,r.applied_damage_budget]],"DOT budget recorded before visual clears effect")
		h.cleanup(a)
	for kind in ["burn","damage_poison"]:
		a=h.actor(A,10000)
		var temporary=Node.new()
		root.add_child(temporary)
		result(a,kind,1.0,200.0,temporary,r)
		temporary.free()
		if kind=="burn":a.burn_runtime.update(a,2.0)
		else:a._update_damage_poison(2.0)
		check(a.damage_events==[[200,0]] and a.current_hp==9800,"freed weak source does not drop scheduled DOT budget")
		h.cleanup(a)
	# Budget stays int64 and records pending damage rather than inflicted HP damage.
	a=h.actor(A,10000)
	var large := 5000000000
	a.apply_burn_with_result(3.0,large,r)
	check(r.requested_damage==large and r.applied_damage_budget==large and a.current_hp==10000,"int64 scheduled budget not immediate HP loss")
	# Refresh from an actual nonlethal tick is not cleared by the older burn update.
	h.cleanup(a)
	a=h.actor(A,10000)
	a.apply_burn_with_result(3.0,200,r)
	a.damage_callback=func():
		a.damage_callback=Callable()
		a.apply_burn_with_result(5.0,50,r)
	a.burn_runtime.update(a,3.0)
	check(r.applied_damage_budget==50 and a.burn_runtime.total==50 and a.burn_runtime.remaining==5.0,"burn tick revision protects newly refreshed budget")
	h.cleanup(a)
	source.free()
	print("Hero DOT status checks: %d; failures: %d" % [checks,failures])
	quit(1 if failures else 0)
