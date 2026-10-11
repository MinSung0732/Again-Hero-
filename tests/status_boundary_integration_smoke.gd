extends SceneTree
# Actual Battle/Hero/component scripts and scene resources, not fixture doubles.
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const AFF := preload("res://src/systems/received_afflictions.gd")
const RECEIPT := preload("res://src/systems/battle_status_receipt.gd")
const ELEMENT := preload("res://src/hero/archmage_element_status.gd")
const YUKI := preload("res://src/systems/yuki_onna_runtime.gd")
var failures := 0
var checks := 0
var nested := false
class Victim extends Node2D:
	var current_hp := 10000
	var max_hp := 10000
	var velocity := Vector2.ONE
	var paid := 0
	func take_damage(amount: int) -> void:
		paid += amount
		current_hp -= amount
func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("STATUS_BOUNDARY: "+label)
func stop(actor: Node) -> void:
	actor.set_process(false)
	actor.set_physics_process(false)
func run() -> void:
	root.get_node("CloudStore").stop()
	root.get_node("LoginGateway").remember_session_enabled = false
	root.get_node("LocalTestMode").active = false
	SCOPE.guest_directory = "user://status-boundary-"+str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	SCOPE.select_guest()
	var battle = load("res://src/battle/Battle.tscn").instantiate()
	root.add_child(battle)
	stop(battle)
	await battle.prepare_spawn_resources()
	var hero = battle.hero
	stop(hero)
	hero.max_hp = 1000000
	hero.current_hp = 1000000
	var source := Node2D.new()
	root.add_child(source)
	var buffer_id: int = hero.legacy_status_receipt.get_instance_id()
	var calls := [
		[&"slow",&"apply_slow",[0.5,1.0]],
		[&"stun",&"apply_stun",[1.0]],
		[&"silence",&"apply_silence",[1.0]],
		[&"fear",&"apply_fear",[source,1.0]],
		[&"paralysis",&"apply_paralysis",[0.3,1.0]],
		[&"petrify",&"apply_petrify",[1.0]],
		[&"poison",&"apply_poison",[1.0,0.1]],
		[&"poison",&"apply_damage_poison",[1.0,100,source,700]],
		[&"bleed",&"apply_bleed",[1.0,source,0.03,false]],
		[&"burn",&"apply_burn",[1.0,100,source]],
		[&"charm",&"apply_charm",[source,1.0]],
		[&"healing_reduction",&"apply_healing_reduction",[1.0,0.5]],
		[&"damage_taken_increase",&"apply_damage_taken_increase",[1.0,0.1]],
	]
	for row in calls:
		hero.callv(row[1],row[2])
		check(hero.legacy_status_result_complete and hero.legacy_status_receipt.complete,"legacy complete "+str(row[1]))
		check(hero.legacy_status_receipt.status_id == row[0],"legacy kind "+str(row[1]))
		check(hero.legacy_status_receipt.get_instance_id()==buffer_id,"reused legacy buffer")
	# A callback overwrites this receiver's buffer: outer availability must be false.
	hero.status_applied.connect(func(kind):
		if kind=="slow" and not nested:
			nested = true
			hero.apply_silence(2.0))
	hero.apply_slow(0.5,1.0)
	check(nested and not hero.legacy_status_result_complete,"nested outer unavailable")
	check(hero.legacy_status_receipt.status_id==&"silence","nested payload preserved")
	hero.current_hp = 0
	hero.apply_stun(1)
	check(hero.legacy_status_result_complete and not hero.legacy_status_receipt.accepted,"dead Hero rejection recorded")
	hero.current_hp = hero.max_hp
	var victim := Victim.new()
	root.add_child(victim)
	victim.set_physics_process(true)
	var receipt = RECEIPT.new()
	check(AFF.apply_burn_with_result(victim,2,120,source,receipt) and receipt.accepted and receipt.applied_damage_budget==120,"generic burn budget")
	var component = victim.get_node("ReceivedAfflictions")
	var component_id: int = component.status_receipt.get_instance_id()
	check(AFF.apply_poison_with_result(victim,2,90,source,5,receipt) and receipt.accepted,"generic poison")
	check(AFF.apply_poison_with_result(victim,2,90,source,5,receipt) and not receipt.accepted,"generic poison dedupe rejection")
	check(AFF.apply_slow_with_result(victim,0.5,2,receipt) and receipt.accepted and is_equal_approx(receipt.applied_strength,0.5),"generic slow snapshot")
	check(AFF.apply_stun_with_result(victim,2,receipt) and receipt.accepted and not victim.is_physics_processing(),"generic stun physics")
	check(AFF.apply_silence_with_result(victim,2,receipt) and receipt.accepted,"generic silence")
	check(AFF.apply_bleed_current_with_result(victim,2,0.06,source,receipt) and receipt.accepted and receipt.applied_damage_budget==600,"generic current HP bleed budget")
	check(not AFF.apply_bleed_current(victim,2,0.06,source) and not component.status_result_complete,"guard invalidates old component result")
	check(component.status_receipt.get_instance_id()==component_id,"reused component buffer")
	component.clear()
	check(not component.status_result_complete and receipt.complete and receipt.accepted,"clear invalidates component only")
	check(victim.is_physics_processing(),"clear restores physics")
	check(AFF.apply_bleed_current_with_result(victim,0,0.0,source,receipt) and receipt.accepted and receipt.applied_damage_budget==1,"preserve generic zero duration minimum budget")
	component.clear()
	var element = ELEMENT.new()
	element.setup(victim)
	victim.add_child(element)
	stop(element)
	element.apply_burn(12,2,0.5)
	check(element.status_result_complete and element.status_receipt.accepted and element.status_receipt.applied_strength==12 and element.status_receipt.applied_damage_budget==0,"element burn per-tick units")
	element.apply_freeze(1)
	check(element.status_result_complete and element.status_receipt.accepted and victim.velocity==Vector2.ZERO,"element freeze")
	element._process(1.1)
	check(victim.is_physics_processing(),"element thaw physics")
	var yuki = YUKI.new()
	yuki.apply_hit(hero,0.1,3,source)
	check(yuki.status_result_complete and yuki.status_receipt.accepted and is_equal_approx(yuki.status_receipt.applied_strength,1.0-float(hero.get_meta("yuki_slow_multiplier"))),"Yuki independent slow metadata")
	yuki.reset()
	check(not yuki.status_result_complete,"Yuki reset invalidates cache")
	var bulgasal = load("res://src/monsters/Bulgasal.tscn").instantiate()
	bulgasal.configure_combat_context(hero,battle)
	battle.add_child(bulgasal)
	stop(bulgasal)
	bulgasal.phase = "idle"
	check(AFF.apply_stun_with_result(bulgasal,2,receipt) and receipt.accepted,"Bulgasal native opt-in")
	bulgasal.apply_silence(2)
	check(bulgasal.legacy_status_result_complete and bulgasal.legacy_status_receipt.accepted,"Bulgasal legacy")
	bulgasal.transcend_level = 5
	bulgasal.phase = "channel"
	bulgasal.channel.begin(2)
	check(AFF.apply_stun_with_result(bulgasal,2,receipt) and not receipt.accepted,"Bulgasal five-level channel immunity")
	yuki = null
	victim.free()
	source.free()
	battle.free()
	await process_frame
	print("STATUS_BOUNDARY_INTEGRATION checks="+str(checks)+" failures="+str(failures))
	quit(0 if failures==0 else 1)
