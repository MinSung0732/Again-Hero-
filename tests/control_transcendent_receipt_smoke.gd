extends SceneTree
const IH = preload("res://tests/izanami_receipt_helper.gd")
const SH = preload("res://tests/shuten_doji_receipt_helper.gd")
const SW = preload("res://tests/shuten_doji_wave_receipt_helper.gd")
const RESULT = preload("res://src/systems/battle_damage_receipt.gd")
const IA = preload("res://src/monsters/izanami.gd")
const SB = preload("res://tests/shuten_doji_before.gd")
const SA = preload("res://src/monsters/shuten_doji.gd")
var checks := 0
var failures := 0
var h
func check(value: bool,message: String):
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func _initialize():call_deferred("run")
func actor(script,hp,shield,fog,level,released,used):
	var a = h.actor(script,hp,shield)
	a.max_hp = 2500
	a.self_fog_power = fog
	a.transcend_level = level
	a.released = released
	a.revival_used = used
	return a
func state(a):
	return [a.current_hp,a.dying,a.events,a.revival_used,a.revival_remaining,a.revival_heal_fraction,
		a.released,a.attack_remaining,a.basic_hits,a.velocity,a.visual.visible,a.visual.animation,a.visual.frame,
		a.get_meta("support_shield_hp"),a.get_meta("support_shield_capacity",0),
		a.fog_age,a.blast_age,a.chain_state,a.effect_layer.visible,a.status_layer.visible]
func run():
	var ih = IH.new()
	ih.root = root
	var r = RESULT.new()
	var a = ih.actor(IA,60,10)
	var hero = a.hero
	hero.accepted_damage_hit.emit(a)
	check(a.incoming_signal_hits==1 and hero.accepted_damage_hit.is_connected(a._on_accepted_hit),"Izanami live signal connected")
	var snapshots: Array = []
	a.died.connect(func():
		snapshots.append([a.ghost_remaining,a.fan_remaining,a.fire_age.duplicate(),
			a.spirit_state.duplicate(),a.torii_age.duplicate(),a.crossing_records.size(),
			hero.accepted_damage_hit.is_connected(a._on_accepted_hit),a.get_meta("support_shield_hp")])
		hero.accepted_damage_hit.emit(a)
	)
	check(a.take_damage_with_result(100,r) and r.hp_damage==60 and r.shield_absorbed==10 and r.death_started,"Izanami inherits real parent result")
	check(snapshots==[[0.0,0.0,PackedFloat32Array([-1,-1,-1,-1]),PackedInt32Array([0,0,0,0,0,0,0,0]),PackedFloat32Array([-1,-1,-1,-1]),0,false,0]],"Izanami cleanup before actual death callback")
	check(a.incoming_signal_hits==1,"Izanami signal disconnected before death event")
	ih.cleanup(a)
	h = SH.new()
	h.root = root
	for hp in [0,1,600,2500]:
		for shield in [0,100,3000]:
			for fog in [0.0,0.5,1.0]:
				for level in [0,3,4,5]:
					for released in [false,true]:
						for used in [false,true]:
							for amount in [-1,0,1,100,5000]:
								var old = actor(SB,hp,shield,fog,level,released,used)
								var fresh = actor(SA,hp,shield,fog,level,released,used)
								old.take_damage(amount)
								check(fresh.take_damage_with_result(amount,r),"Shuten damage result completes")
								check(state(old)==state(fresh),"original fog/released reduction/shield/revival/death parity")
								check(r.hp_damage==maxi(hp-fresh.current_hp,0) and r.shield_absorbed==shield-int(fresh.get_meta("support_shield_hp")),"actual pre-revival HP/shield")
								check(r.accepted==(r.hp_damage+r.shield_absorbed>0) and r.death_started==fresh.dying,"revival not death")
								check(r.requested_damage==amount and r.identity_verified,"original request before reductions")
								if fresh.revival_remaining>0:
									var before_state = state(fresh)
									check(fresh.take_damage_with_result(9999,r) and not r.accepted and not r.death_started and state(fresh)==before_state,"revival invulnerability ignores next hit")
									for step in [0.2,0.4,2.4]:
										old._tick_revival(step)
										fresh._tick_revival(step)
										check(state(old)==state(fresh),"original reverse frames/heal fraction/overflow timing")
									check(fresh.released and fresh.revival_remaining==0.0 and fresh.current_hp==2500 and fresh.basic_hits==0,"revival completes full healing/release once")
								h.cleanup(old)
								h.cleanup(fresh)
	# 5th transcend threshold uses post-shield/reduction HP, including equality.
	for start in [1250,1251,1252]:
		a = actor(SA,start,0,0.0,5,false,false)
		a.take_damage_with_result(1,r)
		check(a.revival_used==(start<=1251) and not r.death_started,"5th transcend threshold equality")
		h.cleanup(a)
	a = actor(SA,1250,100,0.0,5,false,false)
	a.take_damage_with_result(1,r)
	check(not a.revival_used and r.shield_absorbed==1 and r.hp_damage==0,"full shield absorption does not trigger threshold revival")
	h.cleanup(a)
	# Reverse death frames and overflow conversion are actual original methods.
	a = actor(SA,2500,0,0.0,5,false,false)
	a.take_damage_with_result(2000,r)
	check(a.current_hp==500 and r.hp_damage==2000 and not r.death_started and a.visual.animation==&"death" and a.visual.frame==2,"threshold revival actual pre-heal loss")
	a._tick_revival(0.16)
	check(a.visual.frame==1 and a.visual.visible,"reverse frame advances")
	a._tick_revival(0.3)
	check(not a.visual.visible,"release effect phase hides body")
	a._tick_revival(2.60)
	check(a.current_hp==2500 and a.released and a.visual.visible and a.get_meta("support_shield_hp")==500,"5th transcend heal excess becomes shield")
	a.take_damage_with_result(5000,r)
	check(r.death_started and a.dying and r.shield_absorbed==500 and r.hp_damage==2500,"later reduced lethal starts actual death")
	check(not a.effect_layer.visible and not a.status_layer.visible and a.fog_age.count(-1.0)==64 and a.blast_age.count(-1.0)==64 and a.chain_state==PackedByteArray([0,0,0,0]),"real death clears fog/blast/chains and hides layers")
	h.cleanup(a)
	# First lethal at HP1 consumes revival with zero HP loss; never phantom damage.
	a = actor(SA,1,0,0.0,0,false,false)
	check(a.take_damage_with_result(100,r) and a.revival_used and not r.accepted and r.hp_damage==0 and not r.death_started,"HP1 first revival zero actual damage")
	h.cleanup(a)
	# Nested release cue occurs after HP recording, invalidating older buffer.
	a = actor(SA,60,0,0.0,0,false,false)
	var nested_ok := [false]
	a.audio_bank.callback = func(cue):
		if cue=="release":
			a.audio_bank.callback = Callable()
			nested_ok[0] = a.take_damage_with_result(7,r)
	check(not a.take_damage_with_result(100,r),"release callback invalidates outer result")
	check(nested_ok[0] and r.complete and r.requested_damage==7 and r.hp_damage==0 and not r.death_started and a.revival_remaining==3.0,"nested HP1 revival result preserved")
	h.cleanup(a)
	a = actor(SA,60,0,0.0,0,false,false)
	var inner = RESULT.new()
	a.audio_bank.callback = func(cue):
		if cue=="release":
			a.audio_bank.callback = Callable()
			a.take_damage_with_result(7,inner)
	check(a.take_damage_with_result(100,r) and r.hp_damage==59 and not r.death_started and inner.complete and inner.hp_damage==0,"independent nested revival results")
	h.cleanup(a)
	# Audio callback closes actual common guard; cleanup still follows old order.
	a = actor(SA,60,0,0.0,0,true,true)
	a.audio_bank.callback = func(cue):
		if cue=="stop_all":a.dying = true
	check(a.take_damage_with_result(100,r) and r.hp_damage==60 and not r.death_started and a.events.count("death")==0,"Shuten actual death guard respected")
	h.cleanup(a)
	# Real wave transitions from first revival to later actual kill.
	var w = SW.new()
	w.root = root
	var shot = load("res://tests/wave_projectile_after.gd")
	var world = w.world(shot,60,0,100)
	world.a.max_hp = 2500
	world.a.revival_used = false
	w.sweep(world)
	check(world.hero.kills==0 and world.hero.hits==2 and world.a.current_hp==1 and world.a.revival_remaining==3.0,"wave first revival not kill")
	world.a._tick_revival(3.0)
	world.hero.monsters = [world.a]
	world.p.setup("berserker_wave",Vector2.RIGHT,5000,700.0,700.0,{},world.hero)
	world.p.set_physics_process(false)
	w.sweep(world)
	check(world.hero.kills==1 and world.a.dying,"later wave actual kill once")
	w.cleanup(world)
	world = w.world(shot,60,0,100)
	world.a.revival_used = false
	world.a.audio_bank.callback = func(cue):
		if cue=="release":
			world.a.audio_bank.callback = Callable()
			world.a.take_damage_with_result(7,world.p._wave_damage_receipt)
	w.sweep(world)
	check(world.hero.kills==0 and world.hero.hits==2 and world.a.revival_remaining==3.0,"wave overwrite no death inference/retry")
	w.cleanup(world)
	print("Control transcend special checks: ",checks,"; failures: ",failures)
	quit(1 if failures else 0)
