extends SceneTree
const OBS := preload("res://src/systems/battle_damage_observation.gd")
const AUTH := preload("res://tests/authority.gd")
class Victim extends Node:
	var current_hp := 100
class Legacy extends Node:pass
class OldAuthority extends Node:
	var registry
	func get_battle_entity_handle(n):return registry.get_handle(n)
var checks := 0
var failures := 0
func check(value: bool,msg: String):
	checks += 1
	if not value:
		failures += 1
		push_error(msg)
func _initialize():call_deferred("run")
func run():
	var scope = AUTH.new()
	root.add_child(scope)
	var registry = scope.battle_entity_registry
	registry.begin_session(1)
	var v = Victim.new()
	scope.add_child(v)
	var life = registry.activate(v)
	check(scope.get_last_battle_entity_handle(v) == life,"battle adapter last life")
	check(scope.resolve_battle_entity(life) == v,"active handle still authorizes resolve")
	v.current_hp = 80
	check(OBS.observe_legacy_hit(v,scope,life,100) == 0,"nonlethal result")
	v.current_hp = 0
	check(OBS.observe_legacy_hit(v,scope,life,100) == OBS.HP_DEPLETED,"depleted result")
	check(OBS.is_legacy_kill_candidate(OBS.HP_DEPLETED),"legacy depletion classification")
	check(not OBS.is_legacy_kill_candidate(OBS.HP_DEPLETED | OBS.LIFE_CHANGED),"changed life cannot credit kill")
	registry.retire(life)
	check(scope.get_last_battle_entity_handle(v) == life and scope.get_battle_entity_handle(v) == Vector3i.ZERO,"retire keeps observation only")
	check(scope.resolve_battle_entity(life) == null,"last handle grants no authority")
	check(OBS.observe_legacy_hit(v,scope,life,100) == OBS.HP_DEPLETED,"normal retired death observed")
	var another = Victim.new()
	scope.add_child(another)
	var other_life = registry.activate(another)
	check(other_life.y == life.y and other_life.z > life.z,"other node reuses slot")
	check(OBS.observe_legacy_hit(v,scope,life,100) == OBS.HP_DEPLETED,"other node slot reuse preserves actual victim history")
	registry.retire(other_life)
	var newer = registry.activate(v)
	registry.retire(newer)
	check(OBS.observe_legacy_hit(v,scope,life,100) == OBS.LIFE_CHANGED,"reuse then retire detected")
	# Metadata and registry capacity stay bounded over repeated activations.
	for i in range(1000):
		v.current_hp = 100
		var current = registry.activate(v)
		check(scope.get_last_battle_entity_handle(v) == current,"latest activation identity")
		v.current_hp = 0
		registry.retire(current)
		check(OBS.observe_legacy_hit(v,scope,current,100) == OBS.HP_DEPLETED,"retired current result")
		check(OBS.observe_legacy_hit(v,scope,life,100) == OBS.LIFE_CHANGED,"old result remains invalid")
	check(registry.snapshot().slot_count == 1 and v.get_meta_list().size() == 1,"1000 lives bounded registry and one metadata entry")
	check(OBS.observe_legacy_hit(v,scope,newer,-1) == OBS.HP_UNKNOWN,"missing pre-hit HP is unknown")
	check(OBS.observe_legacy_hit(null,scope,life,100) == OBS.TARGET_GONE,"freed/null original target observed as gone")
	check(OBS.observe_legacy_hit(null,scope,life,0) == 0,"already dead target no new kill")
	registry.begin_session(2)
	check(scope.get_last_battle_entity_handle(v) == Vector3i.ZERO,"epoch rejects historical value")
	check(OBS.observe_legacy_hit(v,scope,newer,100) == OBS.LIFE_CHANGED,"epoch invalidates result")
	var current = registry.activate(v)
	v.current_hp = 100
	check(OBS.observe_legacy_hit(v,scope,current,100) == 0,"revive/nondepleted is not kill")
	check(OBS.observe_legacy_hit(v,scope,Vector3i.ZERO,100) == (OBS.LIFE_CHANGED | OBS.IDENTITY_UNVERIFIED),"unregistered initial identity rejected")
	v.set_meta(registry.LAST_LIFE_META,"bad")
	check(registry.get_last_handle(v) == Vector3i.ZERO,"malformed metadata fails closed")
	v.set_meta(registry.LAST_LIFE_META,current)
	v.current_hp = 0
	v.queue_free()
	check(OBS.observe_legacy_hit(v,scope,current,100) == OBS.HP_DEPLETED,"queued lethal node readable observation")
	check(registry.resolve(current) == null and registry.get_last_handle(v) == current,"queued has observation but no authority")
	var legacy = Legacy.new()
	root.add_child(legacy)
	var legacy_v = Victim.new()
	legacy.add_child(legacy_v)
	legacy_v.current_hp = 0
	check(OBS.observe_legacy_hit(legacy_v,legacy,Vector3i.ZERO,100) == (OBS.LEGACY_UNTRACKED | OBS.IDENTITY_UNVERIFIED | OBS.HP_DEPLETED),"legacy identity confidence explicit")
	var old = OldAuthority.new()
	old.registry = registry
	root.add_child(old)
	var old_v = Victim.new()
	old.add_child(old_v)
	var old_life = registry.activate(old_v)
	old_v.current_hp = 0
	registry.retire(old_life)
	check(OBS.observe_legacy_hit(old_v,old,old_life,100) == (OBS.IDENTITY_UNVERIFIED | OBS.HP_DEPLETED),"old adapter retire fallback confidence explicit")
	legacy.free()
	old.free()
	scope.free()
	print("Damage observation checks: ",checks,"; failures: ",failures)
	quit(1 if failures else 0)
