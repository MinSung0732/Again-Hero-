extends SceneTree
const H = preload("res://tests/zeus_receipt_helper.gd")
const A = preload("res://src/monsters/zeus.gd")
const B = preload("res://tests/zeus_before.gd")
const R = preload("res://src/systems/battle_damage_receipt.gd")
var checks := 0
var failures := 0
func check(v: bool,msg: String):
	checks += 1
	if not v:
		failures += 1
		push_error(msg)
func _initialize():call_deferred("run")
func run():
	var h = H.new()
	h.root = root
	var r = R.new()
	for shield in [0,100]:
		for amount in [-1,0,1,60,1000]:
			var a = h.actor(A,60,shield)
			a.take_damage_with_result(amount,r)
			var hit = amount>shield and a.current_hp>0
			check(a.events.has(["cue","hit"])==hit,"hit cue only actual surviving HP loss")
			check(a.events.has("stop_audio")==a.dying,"death stops actor audio")
			check(not a.events.has(["cue","death"]),"cinematic owns death cue")
			h.cleanup(a)
	# Same buffer at post-damage hit sound: latest nested result wins.
	var a = h.actor(A,60,0)
	var nested := [false]
	a.combat_sfx.callback = func(cue):
		if cue=="hit":
			a.combat_sfx.callback = Callable()
			nested[0] = a.take_damage_with_result(7,r)
	check(not a.take_damage_with_result(10,r),"old hit-sound receipt invalidated")
	check(nested[0] and r.complete and r.requested_damage==7 and r.hp_damage==7 and a.current_hp==43,"nested hit sound actual result preserved")
	h.cleanup(a)
	# Separate buffers preserve both actual losses before callbacks.
	a = h.actor(A,60,0)
	var inner = R.new()
	a.combat_sfx.callback = func(cue):
		if cue=="hit":
			a.combat_sfx.callback = Callable()
			a.take_damage_with_result(7,inner)
	check(a.take_damage_with_result(10,r) and r.hp_damage==10 and inner.hp_damage==7,"separate hit buffers preserve outer actual loss")
	h.cleanup(a)
	# Death audio callback precedes common guard, including nested lethal damage.
	for script in [B,A]:
		a = h.actor(script,60,0)
		var deaths := [0]
		a.died.connect(func():deaths[0] += 1)
		a.combat_sfx.callback = func(cue):
			if cue=="stop_all":
				a.combat_sfx.callback = Callable()
				if script==A:a.take_damage_with_result(1,inner)
				else:a.take_damage(1)
		if script==A:a.take_damage_with_result(100,r)
		else:a.take_damage(100)
		check(deaths[0]==1 and a.dying,"death sound reentry retains one actual death")
		if script==A:check(r.death_started and not inner.death_started and inner.hp_damage==0,"HP0 nested hit cannot invent death")
		h.cleanup(a)
	a = h.actor(A,60,0)
	a.combat_sfx.callback = func(cue):
		if cue=="stop_all":a.dying = true
	check(a.take_damage_with_result(100,r) and r.hp_damage==60 and not r.death_started,"closed guard callback not confirmed death")
	h.cleanup(a)
	print("Zeus audio receipt checks: %d; failures: %d" % [checks,failures])
	quit(1 if failures else 0)
