extends SceneTree
const H = preload("res://tests/hero_status_receipt_helper.gd")
const HERO = preload("res://src/hero/hero.gd")
const LEGACY = preload("res://tests/hero_status_legacy_only.gd")
const DERIVED = preload("res://tests/hero_status_derived.gd")
const A = preload("res://tests/izanami_status_after.gd")
const B = preload("res://tests/izanami_status_before.gd")
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
func actor(script,hero):
	var a=script.new()
	root.add_child(a)
	a.hero=hero
	return a
func state(a):
	return [h.state(a.hero),a.hero.damage_taken_increase_ratio,a.hero.damage_taken_increase_timer,a.status_depth,a.passive_statuses]
func prepare_status(hero,timer):
	hero.slow_timer=timer
	hero.stun_timer=timer
	hero.silence_timer=timer
	hero.damage_taken_increase_timer=timer
	hero.damage_taken_increase_ratio=0.2
func run():
	h=H.new()
	h.root=root
	for kind in ["slow","stun","silence","vulnerability"]:
		for hp in [0,1,100]:
			for dying in [false,true]:
				for duration in [-1.0,0.0,0.05,3.0]:
					for strength in [-1.0,0.0,0.5,2.0]:
						for resist in [0.0,0.5,1.0]:
							for timer in [0.0,1.0,5.0]:
								for count_passive in [false,true]:
									var old=actor(B,h.actor(HERO,hp,dying,resist))
									var a=actor(A,h.actor(HERO,hp,dying,resist))
									prepare_status(old.hero,timer)
									prepare_status(a.hero,timer)
									var before=old._status(kind,strength,duration,count_passive,ACTION.Token.new())
									check(a._status(kind,strength,duration,count_passive,ACTION.Token.new())==before,"caller legacy return preserved")
									check(state(old)==state(a),"caller passive/raw/AI/mutation state preserved")
									check(a.status_result_complete==(hp>0 and not dying),"caller result availability separate from acceptance")
									if a.status_result_complete:
										var r=a.status_receipt
										check(r.complete and r.accepted==before and r.identity_verified,"actual Hero result accepted and identity")
										check(r.status_id==StringName("damage_taken_increase" if kind=="vulnerability" else kind) and r.requested_duration==duration,"actual request routed by caller")
									check(ACTION.current(a.hero)==null and not a.hero.status_applied.is_connected(a._count_own_status),"scope and temporary observer restored")
									h.cleanup(old.hero)
									h.cleanup(a.hero)
									old.free()
									a.free()
	# Genuine missing capability and derived overrides both run their legacy call once.
	for script in [LEGACY,DERIVED]:
		for kind in ["slow","stun","silence","vulnerability"]:
			var old=actor(B,h.actor(script))
			var a=actor(A,h.actor(script))
			var before=old._status(kind,0.5,3.0)
			check(a._status(kind,0.5,3.0)==before and state(old)==state(a),"unsupported caller legacy behavior identical")
			check(not a.status_result_complete,"unsupported result is unavailable")
			if script==DERIVED:check(a.hero.legacy_calls==1,"derived status called exactly once")
			h.cleanup(old.hero)
			h.cleanup(a.hero)
			old.free()
			a.free()
	var a=actor(A,h.actor(HERO))
	var buffer_id=a.status_receipt.get_instance_id()
	var token=ACTION.Token.new()
	for i in range(30):
		for kind in ["slow","stun","silence","vulnerability"]:a._status(kind,0.5,1.0,true,token)
	check(a.hero.get_meta("raw")==120 and a.hero.get_meta("credits")==1 and a.passive_statuses==120,"repeated zone applications preserve raw passive and one action credit")
	check(a.status_receipt.get_instance_id()==buffer_id and a.status_receipt.revision==120,"one retained buffer reused across caller applications")
	a._status("slow",0.5,1.0,true,ACTION.Token.new())
	check(a.hero.get_meta("credits")==2,"new cast credited independently")
	var ambient=ACTION.Token.new()
	var previous=ACTION.begin(a.hero,ambient)
	a._status("silence",0,1.0,false,token)
	check(ACTION.current(a.hero)==ambient,"outer action restored rather than cleared")
	ACTION.finish(a.hero,previous)
	var passive=a.passive_statuses
	check(not a._status("unknown",0,1) and not a.status_result_complete and a.passive_statuses==passive,"unknown status invalidates availability without effects")
	a.hero.current_hp=0
	check(not a._status("stun",0,1) and not a.status_result_complete,"early rejection invalidates previous result availability")
	h.cleanup(a.hero)
	a.free()
	a=actor(A,null)
	check(not a._status("slow",0.5,1) and not a.status_result_complete,"missing Hero rejected before API")
	a.free()
	# Nested Hero callbacks may overwrite this buffer but must never cause a retry.
	for kind in ["slow","stun","silence","vulnerability"]:
		var old=actor(B,h.actor(HERO))
		a=actor(A,h.actor(HERO))
		var old_gate := [false]
		old.hero.status_applied.connect(func(_kind):
			if old_gate[0]:return
			old_gate[0]=true
			old.hero.apply_silence(2.0)
		)
		var gate := [false]
		a.hero.status_applied.connect(func(_kind):
			if gate[0]:return
			gate[0]=true
			a.hero.apply_silence_with_result(2.0,a.status_receipt)
		)
		var before=old._status(kind,0.5,1.0)
		check(a._status(kind,0.5,1.0)==before and state(old)==state(a),"nested raw callback preserves existing passive behavior")
		check(not a.status_result_complete and a.status_receipt.status_id==&"silence" and a.status_receipt.complete,"outer availability false despite nested complete buffer")
		check(a.hero.get_meta("raw")==2 and a.passive_statuses==2,"nested event not reapplied on incomplete result")
		h.cleanup(old.hero)
		h.cleanup(a.hero)
		old.free()
		a.free()
	print("Izanami status caller checks: ",checks," failures: ",failures)
	quit(1 if failures else 0)
