extends SceneTree
const H = preload("res://tests/bulgasal_receipt_helper.gd")
const W = preload("res://tests/bulgasal_wave_receipt_helper.gd")
const RESULT = preload("res://src/systems/battle_damage_receipt.gd")
const BEFORE = preload("res://tests/bulgasal_before.gd")
const AFTER = preload("res://src/monsters/bulgasal.gd")
const POLICY = preload("res://src/systems/hero_target_policy.gd")
var checks := 0
var failures := 0
var h
func check(value: bool,message: String):
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func _initialize():call_deferred("run")
func actor(script,phase,level,hp,shield,hits,aura := 1.0):
	var a = h.actor(script,hp,shield,aura)
	a.phase = phase
	a.transcend_level = level
	a.received_hits = hits
	a.retreat_pending = 2
	a.channel.begin(2.0)
	a.visual.visible = false
	a.visual.position = Vector2(12,-130)
	a.special_augment_configs = {"orc_rage_stacks":{"max_stacks":5},
		"orc_last_charge":{"hp_ratio":0.3,"duration":0.75}}
	return a
func state(a):
	return [a.current_hp,a.dying,a.events,a.received_hits,a.retreat_pending,
		a.get_meta("support_shield_hp"),a.rage_stacks,a.last_charge_triggered,a.last_charge_timer,
		a.fragment_states,a.fragment_hit,a.channel.active,a.channel.completed,a.channel.interrupted,
		a.rock_active,a.wave_active,a.wave_visual_distance,a.visual.visible,a.visual.position,
		a.pillars.retiring,a.pillars.get_parent()==a,a.pillars.shatter_calls]
func run():
	h = H.new()
	h.root = root
	var r = RESULT.new()
	# Real child guard/counter, parent shield/HP/augments/death, before and after.
	for phase in ["idle","burrow","air"]:
		for level in [0,3,4,5]:
			for hp in [0,1,60]:
				for shield in [0,10,100]:
					for amount in [-1,0,1,3,100]:
						for hits in [0,9,19]:
							var old = actor(BEFORE,phase,level,hp,shield,hits)
							var fresh = actor(AFTER,phase,level,hp,shield,hits)
							old.take_damage(amount)
							check(fresh.take_damage_with_result(amount,r),"result completes even when immune")
							check(state(old)==state(fresh),"legacy damage/counter/shield/death cleanup parity")
							check(r.hp_damage==hp-fresh.current_hp and r.shield_absorbed==shield-int(fresh.get_meta("support_shield_hp")),"actual reduced HP/shield")
							check(r.accepted==(r.hp_damage+r.shield_absorbed>0) and r.death_started==fresh.dying,"accepted and actual death")
							check(r.requested_damage==amount and r.identity_verified,"original unreduced request and life")
							h.cleanup(old)
							h.cleanup(fresh)
	# Burrow reduction precedes parent's aura; the tenth incoming hit counts even at zero.
	for aura in [0.5,1.0,1.5]:
		for amount in [1,3,25,100]:
			var old = actor(BEFORE,"burrow",3,60,10,9,aura)
			var a = actor(AFTER,"burrow",3,60,10,9,aura)
			old.take_damage(amount)
			check(a.take_damage_with_result(amount,r) and state(old)==state(a),"burrow/aura/shield order")
			check(a.received_hits==0 and a.retreat_pending==3,"one incoming hit queues retreat")
			check(r.hp_damage==60-a.current_hp and r.shield_absorbed==10-int(a.get_meta("support_shield_hp")),"aura counts final shield and HP")
			h.cleanup(old)
			h.cleanup(a)
	var a = actor(AFTER,"burrow",3,60,100,9)
	a.take_damage_with_result(1,r)
	check(not r.accepted and a.received_hits==0 and a.retreat_pending==3 and a.current_hp==60,"rounded-zero hit retains old retreat trigger")
	h.cleanup(a)
	a = actor(AFTER,"idle",0,60,100,9)
	a.take_damage_with_result(25,r)
	check(r.accepted and r.hp_damage==0 and r.shield_absorbed==25 and a.received_hits==0 and a.retreat_pending==3,"fully shielded hit counts toward retreat")
	h.cleanup(a)
	# Real legacy zero-argument child death retains all cleanup and pillar reparent.
	for api in ["legacy","result"]:
		a = actor(AFTER,"idle",4,60,0,9)
		a.burrow_phased = true
		a.burrow_saved_layer = 2
		a.burrow_saved_mask = 13
		a.collision_layer = 0
		a.collision_mask = 12
		POLICY.set_hidden(a,true)
		var revision = POLICY.revision
		var snapshots: Array = []
		a.pillars.callback = func():
			snapshots.append([a.current_hp,a.dying,POLICY.is_detectable(a),a.channel.active,
				a.fragment_states.duplicate(),a.visual.position,a.visual.visible])
		if api=="legacy":a.take_damage(100)
		else:check(a.take_damage_with_result(100,r) and r.death_started and r.hp_damage==60,"result actual common death guard")
		check(snapshots==[[0,false,true,false,PackedInt32Array([0,0,0,0,0,0,0,0]),a.visual_rest,true]],"cleanup before common guard retains order")
		check(a.collision_layer==2 and a.collision_mask==13 and not a.burrow_phased and POLICY.revision==revision+1,"death restores burrow collision/detection")
		check(a.events==[60,"hit","stop_audio","pillars","death"],"HP/hit/audio/pillars/death order")
		check(a.channel.interrupted and not a.channel.active and not a.rock_active and not a.wave_active and a.wave_visual_distance==-1.0,"active skill state canceled")
		check(a.pillars.retiring and a.pillars.get_parent()==a.get_parent() and a.pillars.shatter_calls==[false],"actual pillar retirement reparent; no death damage")
		h.cleanup(a)
	# Callback marks dying before common guard: cleanup runs, no confirmed new death.
	a = actor(AFTER,"idle",0,60,0,0)
	a.pillars.callback = func():a.dying = true
	check(a.take_damage_with_result(100,r) and r.hp_damage==60 and not r.death_started,"pillar callback closes actual death guard")
	check(a.pillars.retiring and a.events.count("death")==0,"existing cleanup still runs without second death")
	h.cleanup(a)
	# Same-buffer reentry in audio/pillars cleanup preserves newer rejected hit.
	for callback in ["audio","pillars"]:
		a = actor(AFTER,"idle",0,60,0,0)
		var nested_ok := [false]
		if callback=="audio":
			a.audio_bank.callback = func():nested_ok[0] = a.take_damage_with_result(7,r)
		else:
			a.pillars.callback = func():nested_ok[0] = a.take_damage_with_result(7,r)
		check(not a.take_damage_with_result(100,r),"cleanup callback invalidates old buffer "+callback)
		check(nested_ok[0] and r.complete and r.requested_damage==7 and not r.accepted and not r.death_started and a.dying,"new HP0 immune receipt survives old writer")
		check(a.events.count("death")==1 and a.received_hits==1,"damage/death cleanup never replayed")
		h.cleanup(a)
	# Separate buffers retain original death even if a nested HP0 hit is rejected.
	a = actor(AFTER,"idle",0,60,0,0)
	var inner = RESULT.new()
	a.pillars.callback = func():a.take_damage_with_result(7,inner)
	check(a.take_damage_with_result(100,r) and r.hp_damage==60 and r.death_started and inner.complete and not inner.accepted,"independent cleanup results")
	h.cleanup(a)
	# Actual wave integration: immune, reduced/shielded, callback-invalidated results.
	var w = W.new()
	w.root = root
	var shot = load("res://tests/wave_projectile_after.gd")
	for phase in ["idle","burrow","air"]:
		for level in [3,4]:
			var world = w.world(shot,60,10,100)
			world.a.phase = phase
			world.a.transcend_level = level
			w.sweep(world)
			var immune = phase=="air" or (phase=="burrow" and level>=4)
			check(world.hero.kills==(1 if phase=="idle" else 0),"wave kill only actual death")
			check(world.a.received_hits==(0 if immune else 1),"wave immune guard versus incoming hit counter")
			check(world.hero.hits==2,"existing wave notification policy including immune")
			check(world.a.current_hp==(60 if immune else 30 if phase=="burrow" else 0),"wave uses reduced child damage once")
			w.cleanup(world)
	var world = w.world(shot,60,0,100)
	world.a.pillars.callback = func():world.a.take_damage_with_result(7,world.p._wave_damage_receipt)
	w.sweep(world)
	check(world.hero.kills==0 and world.hero.hits==2 and world.a.dying and world.a.received_hits==1,"wave overwrite no inferred kill or damage replay")
	check(world.a.pillars.shatter_calls==[false] and world.a.events.count("death")==1,"wave death cleanup once")
	w.cleanup(world)
	print("Bulgasal special checks: ",checks,"; failures: ",failures)
	quit(1 if failures else 0)
