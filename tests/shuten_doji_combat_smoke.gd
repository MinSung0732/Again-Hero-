extends SceneTree
const SCENE := preload("res://src/monsters/ShutenDoji.tscn")
const DATA := preload("res://src/data/shuten_doji_behavior_catalog.gd")
const AFF := preload("res://src/systems/received_afflictions.gd")
const RUNTIME := preload("res://src/systems/transcendence_runtime.gd")
const FIXTURE := preload("res://tests/manticore_combat_smoke.gd")
var failures := 0
class Target extends Node2D:
	var current_hp := 100000
	var max_hp := 100000
	var damage := 0
	var slow := 1.0
	var stun := 0.0
	var silence := 0.0
	var bleed_ratio := 0.0
	func take_damage(amount: int, _source: Node = null) -> bool:
		damage += amount
		current_hp -= amount
		return true
	func take_followup_damage(amount: int, source: Node) -> bool: return take_damage(amount,source)
	func take_status_damage(amount: int, source: Node) -> bool: return take_damage(amount,source)
	func apply_slow(multiplier: float, _seconds: float) -> void: slow = multiplier
	func apply_stun(seconds: float) -> void: stun = seconds
	func apply_silence(seconds: float) -> bool:
		silence = seconds
		return true
	func apply_bleed(_seconds: float, _source: Node, ratio: float, _refresh: bool) -> bool:
		if get_meta("bleed_active",false): return false
		bleed_ratio = ratio
		set_meta("bleed_active",true)
		return true
class Ally extends Node2D:
	var monster_type := "slime"
	var current_hp := 10000
	func take_damage(amount: int) -> void: current_hp -= amount
func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error("SHUTEN: "+label)
func run() -> void:
	root.get_node("CloudStore").stop()
	root.get_node("LoginGateway").remember_session_enabled = false
	var runtime = RUNTIME.new()
	runtime.configure("shuten_doji",DATA.RULES)
	for i in range(39): runtime.record_summon("control")
	for i in range(3): runtime.record_status()
	check(not runtime.ready,"39 controls + three statuses locked")
	check(runtime.record_summon("control"),"AND unlock at forty")
	runtime.consume()
	check(not runtime.record_status(),"once per battle")
	var authority = FIXTURE.Authority.new()
	root.add_child(authority)
	var target := Target.new()
	authority.add_child(target)
	authority.hero = target
	var actor = SCENE.instantiate()
	actor.configure_combat_context(target,authority)
	actor.configure_transcendence(10,0)
	check(actor.attack_damage==230 and actor.max_hp==2510 and actor.summon_snapshot==10,"pre-summon status snapshot")
	actor.configure_transcendence(0,0)
	authority.add_child(actor)
	actor.set_physics_process(false)
	actor.visual.set_physics_process(false)
	check(actor.attack_damage==220 and actor.max_hp==2500 and actor.get_gauge_regen()==15,"base stats, snapshot and regen cap")
	actor.gauge = 100
	actor._cast_fog()
	for i in range(20): actor._tick_fogs(0.1)
	var active := 0
	for i in range(DATA.FOG_CAPACITY):
		if actor.fog_age[i]>=0:
			active += 1
			check(actor.fog_points[i].length()<=200 and actor.fog_life[i]>=5 and actor.fog_life[i]<=10,"radial fog and lifetime")
	check(active==12 and actor.gauge==70 and actor.attack_damage==220,"twelve mists, cost and once-per-skill growth")
	actor.fog_age.fill(-1)
	actor.records.clear()
	target.damage = 0
	actor.attack_damage = 220
	var action: int = actor._next_action()
	actor._spawn_fog(Vector2.ZERO,5,1,action)
	var ally := Ally.new()
	authority.add_child(ally)
	actor.nearby_allies = [ally,actor]
	actor.transcend_level = 1
	var own_hp: int = actor.current_hp
	for i in range(50): actor._tick_fogs(0.1)
	check(abs(target.damage-220)<=1 and ally.current_hp>=9779 and ally.current_hp<=9781,"total fog damage, allied friendly fire")
	check(actor.current_hp==own_hp and actor.attack_damage==220,"no self damage or repeated tick growth")
	check(int(actor.get_meta("support_shield_hp",0))>=249,"two percent shield per second")
	check(is_equal_approx(float(ally.get_meta("received_slow_multiplier",1)),0.5),"allied slow applies")
	actor.fog_age.fill(-1)
	actor.transcend_level = 2
	actor.gauge = 100
	actor._cast_fog()
	actor._tick_fogs(2)
	active = 0
	for age in actor.fog_age:
		if age>=0: active+=1
	check(active==19,"tier two nineteen mists")
	actor.fog_age.fill(-1)
	actor.cooldowns[0] = 20
	target.set_meta("bleed_active",false)
	actor._spawn_fog(Vector2.ZERO,5,1,actor._next_action())
	actor._spawn_fog(Vector2.ZERO,5,1,actor._next_action())
	actor._ignite()
	check(actor.cooldowns[0]==16 and bool(target.get_meta("bleed_active")) and target.stun==2,"per-mist refund, bleed then refreshed stun")
	var captured_hp: float = target.bleed_ratio*target.max_hp
	check(captured_hp>0 and captured_hp<6000,"six percent CURRENT health snapshot after explosion")
	actor.chain_immunity.clear()
	actor.gauge = 100
	actor.transcend_level = 0
	actor._cast_chain(target)
	actor.chain_age[0] = 10
	check(actor._bind_chain(0,target) and actor.cooldowns[2]==48,"ten seconds twenty percent refund")
	check(target.slow==0.01 and target.silence==3,"chain binds slow99 and silence")
	var damage_before: int = target.damage
	var chain_total: int = int(round(actor.chain_damage[0]))
	actor._tick_chains(3)
	check(target.damage-damage_before==chain_total and actor.chain_state[0]==0,"exact total250 percent over three seconds")
	actor._cast_chain(target)
	check(not actor._bind_chain(0,target),"chain immunity blocks early rebind")
	actor.clock = 13
	actor.transcend_level = 3
	actor._cast_chain(target)
	check(actor._bind_chain(0,target) and actor.cooldowns[2]==30,"tier three unconditional fifty percent refund after expiry")
	actor.chain_state.fill(0)
	actor.transcend_level = 0
	actor.self_fog_power = 0
	actor.set_meta("support_shield_hp",0)
	actor.current_hp = 100
	actor.take_damage(99999)
	check(actor.revival_used and actor.revival_remaining==3 and not actor.dying,"first lethal starts revival")
	actor.take_damage(99999)
	check(actor.current_hp==1,"three-second invulnerability")
	actor._tick_revival(3)
	check(actor.current_hp==actor.max_hp and actor.released,"complete full recovery")
	actor.transcend_level = 4
	actor.basic_hits = 19
	actor.cooldowns.fill(10)
	actor._on_basic_hit()
	check(actor.cooldowns[0]==9 and target.stun==2.5 and int(actor.get_meta("support_shield_hp",0))==int(round(actor.max_hp*.05)),"release cooldown refund twenty-hit shield stun")
	actor.set_meta("support_shield_hp",0)
	actor.current_hp = actor.max_hp
	actor.take_damage(100)
	check(actor.current_hp==actor.max_hp-70,"tier four damage reduction")
	actor.released = false
	actor.revival_used = false
	actor.transcend_level = 5
	actor.current_hp = actor.max_hp
	actor.take_damage(int(actor.max_hp*.5)+1)
	check(actor.revival_remaining==3,"tier five half-health trigger")
	var hp_before: int = actor.current_hp
	actor._tick_revival(3)
	check(int(actor.get_meta("support_shield_hp",0))==hp_before,"tier five overheal shield")
	# Generic friendly status component: exact budget, non-refresh, pool cleanup.
	ally.current_hp = 10000
	AFF.reset_on(ally)
	check(AFF.apply_bleed_current(ally,7,0.06,actor),"generic bleed accepted")
	check(not AFF.apply_bleed_current(ally,7,0.06,actor),"generic bleed does not refresh")
	var component = AFF.component(ally)
	component.set_physics_process(false)
	component._tick_extra(7)
	check(ally.current_hp==9400 and not ally.get_meta("bleed_active"),"generic exact six percent total")
	ally.set_physics_process(true)
	AFF.apply_stun(ally,2)
	check(not ally.is_physics_processing(),"generic stun pauses actor")
	component._tick_extra(2)
	check(ally.is_physics_processing(),"generic stun restores actor")
	AFF.reset_on(ally)
	authority.queue_free()
	await process_frame
	print("SHUTEN_COMBAT "+("PASS" if failures==0 else "FAIL"))
	quit(0 if failures==0 else 1)
