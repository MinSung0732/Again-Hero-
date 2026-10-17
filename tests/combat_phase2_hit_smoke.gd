extends SceneTree
## Differential oracle is the frozen pre-phase2 hit helper, not a rewritten model.
const HIT := preload("res://src/systems/monster_hit_context.gd")
const WEAPONS := preload("res://src/hero_mode/hero_weapon_runtime.gd")
var checks := 0
var failures := 0
class Runtime extends RefCounted:
	var hero: Node
	var passive_siphon := 0.0
	var absorbed := 0
	func absorb_damage(amount: int) -> void: absorbed += amount
class Source extends Node:
	var player_weapons
class Arena extends Node:
	var hero: Node
class Target extends Node2D:
	var current_hp := 1000
	var shield := 0
	var calls := 0
	var nested
	var source: Node
	var trace: Array = []
	var dies := false
	func take_damage(amount: int) -> bool:
		calls += 1
		trace.append([get_meta("incoming_attack_kind"),get_meta("_status_damage_source") == source,amount,current_hp])
		if nested != null and calls == 1:
			nested.hit(self,3,"melee",source)
			trace.append([get_meta("incoming_attack_kind"),get_meta("_status_damage_source") == source,"after_nested"])
		var blocked := mini(shield,amount); shield -= blocked
		current_hp -= maxi(0,amount-blocked)
		if dies: queue_free()
		return amount > blocked
	func take_damage_with_result(amount: int,receipt) -> bool:
		receipt.append(amount)
		return take_damage(amount)
class NoHP extends Node:
	func take_damage(_amount: int): return null
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: run.call_deferred()
func before_script():
	var script := GDScript.new()
	script.source_code = FileAccess.get_file_as_string("res://tests/fixtures/combat_phase2/monster_hit_context_before.gd.txt")
	check(script.reload() == OK,"load frozen helper")
	return script
func replay(helper,kind: String,siphon: float,nested: bool,receipt_enabled: bool,restore: bool,shield: int) -> Array:
	var arena := Arena.new(); root.add_child(arena)
	var source := Source.new(); arena.add_child(source); arena.hero = source
	var runtime := Runtime.new(); runtime.hero = source; runtime.passive_siphon = siphon; source.player_weapons = runtime
	var projectile := Node.new(); arena.add_child(projectile)
	if kind != "hero": projectile.add_to_group(kind)
	if kind == "geometry": projectile.set_meta("survival_geometry",true)
	var target := Target.new(); arena.add_child(target); target.source = source if kind == "hero" else projectile
	target.shield = shield; target.nested = helper if nested else null
	if restore:
		target.set_meta("incoming_attack_kind","outer"); target.set_meta("_status_damage_source",source)
	var receipt: Array = []; var hits: Array = []
	for index in 8:
		hits.append(helper.hit(target,100+index,"ranged",target.source,receipt if receipt_enabled else null))
	var result := [hits,target.current_hp,target.shield,target.trace.duplicate(true),receipt.duplicate(),runtime.absorbed,target.get_meta("incoming_attack_kind","") if target.has_meta("incoming_attack_kind") else "ABSENT",target.has_meta("_status_damage_source")]
	arena.free(); runtime.hero = null
	return result
func edge_cases(helper) -> Array:
	var source := Source.new(); var runtime := Runtime.new(); runtime.hero = source; runtime.passive_siphon = .1; source.player_weapons = runtime
	var target := Target.new(); target.source = source; target.dies = true
	var result := [helper.hit(target,1200,"ranged",source),runtime.absorbed,target.is_queued_for_deletion()]
	target.free()
	var no_hp := NoHP.new(); result.append(helper.hit(no_hp,10,"ranged",source)); result.append(runtime.absorbed); no_hp.free()
	result.append(helper.hit(source,10)); result.append(helper.hit(null,10))
	var self_target := Target.new(); self_target.source = source; runtime.hero = self_target
	helper.hit(self_target,10,"ranged",source); result.append(runtime.absorbed); self_target.free()
	# Moving pooled projectile to another authority must resolve the new room immediately.
	var a := Arena.new(); var b := Arena.new(); root.add_child(a); root.add_child(b)
	var projectile := Node.new(); a.add_child(projectile); projectile.add_to_group("hero_projectiles")
	a.hero = source; b.hero = null
	var t := Target.new(); t.source = projectile
	helper.hit(t,10,"ranged",projectile); projectile.reparent(b); helper.hit(t,10,"ranged",projectile)
	runtime.passive_siphon = 0; projectile.reparent(a); helper.hit(t,10,"ranged",projectile)
	runtime.passive_siphon = .2; helper.hit(t,10,"ranged",projectile)
	result.append(runtime.absorbed); t.free(); a.free(); b.free(); source.free(); runtime.hero = null
	return result
func run() -> void:
	var old = before_script()
	for kind in ["hero","hero_projectiles","hero_summons","hero_summon_projectiles","geometry","unrelated"]:
		for siphon in [0.0,.1]:
			for nested in [false,true]:
				for receipt in [false,true]:
					for restore in [false,true]:
						for shield in [0,1500]:
							check(replay(old,kind,siphon,nested,receipt,restore,shield) == replay(HIT,kind,siphon,nested,receipt,restore,shield),"ordered hit/metadata/receipt/absorption parity "+kind)
	check(edge_cases(old) == edge_cases(HIT),"free/no HP/self/invalid/room/upgrade parity")
	# Real Hero script has many exported/runtime properties; exercise its actual lookup.
	var hero = load("res://src/hero/hero.gd").new(); var runtime = WEAPONS.new(); hero.player_weapons = runtime; runtime.hero = hero
	for value in [0.0,.1,0.0,.3]:
		runtime.passive_siphon = value
		check(old._siphon_runtime(hero) == HIT._siphon_runtime(hero),"actual Hero runtime upgrade resolution")
	hero.player_weapons = null; runtime.hero = null; hero.free()
	print("COMBAT_PHASE2_HIT checks=",checks," failures=",failures); quit(1 if failures else 0)
