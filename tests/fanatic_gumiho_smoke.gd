extends SceneTree
const C := preload("res://src/data/monster_catalog.gd")
const A := preload("res://src/data/demon_augment_catalog.gd")
const F := preload("res://src/monsters/Fanatic.tscn")
const G := preload("res://src/monsters/Gumiho.tscn")
const GDAT := preload("res://src/data/gumiho_behavior_catalog.gd")
const HIT := preload("res://src/systems/monster_hit_context.gd")
const SHOP := preload("res://src/data/shop_catalog.gd")
var checks := 0
var failures := 0
class Hero extends Node2D:
	var current_hp := 100000
	var max_hp := 100000
	var charm_immunity_timer := 0.0
	var fear_immunity_timer := 0.0
	var hits: Array[int] = []
	var charms := 0
	var burns := 0
	var burn_budget := 0
	var fear_speed := 0.0
	func take_damage(amount: int,_source: Node = null) -> bool: hits.append(amount); current_hp -= amount; return true
	func take_followup_damage(amount: int,source: Node = null) -> bool: return take_damage(amount,source)
	func take_status_damage(amount: int,source: Node = null) -> bool: return take_damage(amount,source)
	func apply_charm(_source: Node,duration: float) -> bool:
		charms += 1; set_meta("charm_active",true); set_meta("charm_duration",duration); set_meta("captured_immunity",get_meta("incoming_charm_immunity",7.0)); return true
	func apply_fear(_source: Node,duration: float,speed: float) -> void: fear_speed = speed; set_meta("fear_active",true); set_meta("fear_duration",duration); set_meta("fear_recovery",get_meta("incoming_fear_immunity",0.0))
	func apply_burn(_duration: float,total: int,_source: Node = null) -> bool: burns += 1; burn_budget = total; set_meta("burn_active",true); return true
class Battle extends Node2D:
	var hero: Node2D
	var gumiho_shared_runtime = preload("res://src/systems/gumiho_shared_runtime.gd").new()
	var summoned: Array = []
	func _spawn_monster(id: String,point: Vector2,_cost: float,_split: bool,mods: Dictionary):
		summoned.append({"id":id,"point":point,"mods":mods}); return null
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func function_source(source: String,name: String) -> String:
	var start := source.find("func "+name+"(")
	var end := source.find("\nfunc ",start+1)
	return source.substr(start,end-start if end>=0 else source.length()-start)
func make_stat_battle():
	var script := GDScript.new()
	script.source_code = '''extends Node2D
const MONSTER_SUPPORT_COMMON = preload("res://src/monsters/monster_runtime_common.gd")
var hero: Node2D
var gumiho_shared_runtime = preload("res://src/systems/gumiho_shared_runtime.gd").new()
var configs: Dictionary = {}
func _get_special_augment_config(_id: String) -> Dictionary: return configs
func _get_demon_level_monster_hp_multiplier() -> float: return 1.0
func _get_demon_level_monster_damage_multiplier() -> float: return 1.0
func _get_demon_level_monster_speed_multiplier() -> float: return 1.0
func _clamp_manual_spawn_position(point: Vector2) -> Vector2: return point
func invalidate_monster_spatial_snapshot() -> void: pass
'''
	var source := FileAccess.get_file_as_string("res://src/battle/battle.gd")
	for name in ["_apply_demon_level_scaling_to_monster","refresh_monster_runtime_stats","_get_special_stat_multiplier"]:
		script.source_code += "\n"+function_source(source,name)+"\n"
	check(script.reload() == OK,"actual Battle stat functions compile")
	return script.new()
func actor(battle,scene,id: String):
	var unit = scene.instantiate(); C.apply_runtime_base_stats(unit,id)
	for pair in [["max_hp","demon_level_base_max_hp"],["attack_damage","demon_level_base_attack_damage"],["move_speed","demon_level_base_move_speed"]]: unit.set_meta(pair[1],unit.get(pair[0]))
	unit.configure_combat_context(battle.hero,battle); battle.add_child(unit); unit.set_physics_process(false); unit.attack_timer = 1000
	return unit
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var b := Battle.new(); root.add_child(b); b.hero = Hero.new(); b.add_child(b.hero); b.hero.position = Vector2(30,0)
	for id in ["fanatic","gumiho"]:
		check(id in C.ORDER and id in SHOP.get_monster_pool(C.get_rarity(id)),id+" gacha pool")
		check(C.get_summon_exp(id) == C.get_base_cost(id),id+" demon EXP")
		check(C.MONSTERS[id].special_augment_ids.size() == 3,id+" three augment entries")
	var f = actor(b,F,"fanatic")
	check(f.max_hp == 158 and f.attack_damage == 9 and f.explosion_damage == 126,"fanatic budget")
	check(f.visual.sprite_frames.get_frame_count("attack") == 6 and f.blast.sprite_frames.get_frame_count("idle") == 8,"actual fanatic/explosion assets")
	f._attack_target(b.hero); f._tick_followup(0.13); check(b.hero.hits == [9],"first hit")
	f._tick_followup(0.02); check(b.hero.hits == [9,9] and f.orb.visible,"orb second hit")
	f.set_meta("visual_variant","elite"); b.hero.hits.clear(); f._attack_target(b.hero); f._tick_followup(1)
	check(b.hero.hits == [9],"elite single hit")
	f.configure_special_augments({"fanatic_dagger":{}}); b.hero.hits.clear(); f._attack_target(b.hero)
	check(b.hero.hits == [12],"dagger30percent")
	check(f.try_cast_elite_skill({}),"ritual begins")
	f._tick_ritual(0.14); check(b.summoned.is_empty(),"ritual not early")
	for i in range(10): f._tick_ritual(0.15)
	check(b.summoned.size() == 10 and not f.ritual_active,"ten sequential summons")
	check(b.summoned[0].mods.exclude_all_augments and b.summoned[0].mods.fixed_base_stats and not b.summoned[0].mods.counts_population,"ritual explicit augment exclusion")
	b.hero.hits.clear(); var point: Vector2 = f.position
	f.take_damage(9999); f._physics_process(1.49)
	check(f.dying and f.fusing and not f.exploded and f.position == point and b.hero.hits.is_empty(),"delayed stationary fuse")
	f._physics_process(0.02); check(f.exploded and b.hero.hits == [126],"delayed explosion126")
	f._explode(); check(b.hero.hits.size() == 1,"explosion once")
	var suicide = actor(b,F,"fanatic"); suicide.configure_special_augments({"fanatic_suicide":{}}); b.hero.hits.clear()
	check(suicide._get_combat_bonuses().move_speed_multiplier == 1.5,"suicide speed50percent")
	suicide._attack_target(b.hero); check(suicide.exploded and b.hero.hits == [126],"immediate suicide no basic")
	var g = actor(b,G,"gumiho"); var g2 = actor(b,G,"gumiho")
	check(g.max_hp == 354 and g.attack_damage == 61,"gumiho authored budget")
	var shield: int = g.get_meta("temporary_shield_hp"); var hp: int = g.current_hp
	check(shield == roundi(g.max_hp*0.55),"spawn shield55percent")
	HIT.hit(g,10,"melee"); check(g.current_hp == hp-10 and g.get_meta("temporary_shield_hp") == shield,"melee bypasses ranged shield")
	HIT.hit(g,20,"ranged"); check(g.get_meta("temporary_shield_hp") == shield-20,"ranged absorbs")
	g.set_meta("ranged_shield_hp",40); g._physics_process(5.01)
	check(g.get_meta("temporary_shield_hp") == 0 and g.get_meta("ranged_shield_hp") == 40,"expiry preserves other shield")
	g2.configure_special_augments({"gumiho_universal":{}}); hp = g2.current_hp; shield = g2.get_meta("temporary_shield_hp"); HIT.hit(g2,20,"melee")
	check(g2.current_hp == hp and g2.get_meta("temporary_shield_hp") == shield-20,"universal shield absorbs melee")
	for i in range(19): (g if i%2 == 0 else g2)._attack_target(b.hero)
	check(b.gumiho_shared_runtime.get_stacks(b.hero) == 19 and b.hero.charms == 0,"shared19")
	g2._attack_target(b.hero)
	check(b.hero.charms == 1 and b.gumiho_shared_runtime.get_stacks(b.hero) == 0 and b.hero.get_meta("captured_immunity") == 5,"twentieth charm scoped5")
	check(not b.hero.has_meta("incoming_charm_immunity"),"charm metadata restored")
	g.configure_special_augments({"gumiho_fascination":{},"gumiho_last_shadow":{}})
	check(g._get_combat_bonuses().attack_speed_multiplier == 1.7,"charmed AS70percent")
	g.current_hp = 100; g.set_meta("ranged_shield_hp",0); HIT.hit(g,10,"melee")
	check(g.emergency_used and g.stealth_remaining == 5,"lowHP stealth")
	hp = g.current_hp; HIT.hit(g,10,"melee"); check(g.current_hp == hp-5,"stealth halves damage")
	g._physics_process(5.01); check(g.stealth_remaining == 0,"stealth expires")
	check(g.try_cast_elite_skill({"id":"elite_gumiho_fear"}),"fear accepted")
	check(b.hero.fear_speed == 1.7 and b.hero.get_meta("fear_recovery") == 5,"fear target speed and immunity")
	check(not g.try_cast_elite_skill({"id":"elite_gumiho_fear"}),"active fear not refreshed")
	g.current_hp = g.max_hp; var original_hp: int = g.max_hp; var original_atk: int = g.attack_damage
	check(not g.try_cast_elite_skill({"id":"elite_gumiho_foxfire"}),"human cannot breathe")
	check(g.try_cast_elite_skill({"id":"elite_gumiho_transform"}),"fox transform")
	check(g.max_hp == roundi(original_hp*1.5) and g.attack_damage == roundi(original_atk*1.5) and g.visual.sprite_frames.get_frame_count("skill") == 4,"fox stats and real skill4")
	g._physics_process(1.01); check(g._stealthed(),"fox quiet1sec stealth")
	g.stealth_remaining = 0; HIT.hit(g,10,"melee"); check(not g._stealthed(),"hit restarts fox quiet")
	b.hero.hits.clear(); check(g.try_cast_elite_skill({"id":"elite_gumiho_foxfire"}),"fox breath begins")
	g._tick_breath(0.49); check(b.hero.hits.is_empty(),"breath no early tick")
	g._tick_breath(1.51); var total := 0
	for amount in b.hero.hits: total += amount
	check(total == roundi(g.attack_damage*1.5) and b.hero.burns == 1 and b.hero.burn_budget == 5000,"breath150percent/one5percent burn")
	g.try_cast_elite_skill({"id":"elite_gumiho_foxfire"}); g._tick_breath(2)
	check(b.hero.burns == 1,"existing burn no refresh")
	g._physics_process(20); check(g.fox_remaining == 0 and g.max_hp == original_hp and g.attack_damage == original_atk,"fox expires restoring stats")
	var projectile := Node2D.new(); b.add_child(projectile); projectile.position = g.position
	seed(1984)
	var reflected := false
	for i in range(100):
		if HIT.reflect_projectile(g,23,b.hero,projectile): reflected = true; break
	check(reflected,"projectile reflection reachable")
	var hp_before: int = b.hero.current_hp
	for child in b.get_children():
		if child.get_script() == preload("res://src/monsters/gumiho_reflected_projectile.gd"): child.set_physics_process(false); child._physics_process(1)
	check(b.hero.current_hp == hp_before-23,"returned projectile damage on arrival")
	var stats_battle = make_stat_battle(); root.add_child(stats_battle); stats_battle.hero = Hero.new(); stats_battle.add_child(stats_battle.hero)
	var real_g = actor(stats_battle,G,"gumiho"); var base_cd: float = real_g.attack_cooldown; var base_speed: float = real_g.move_speed
	real_g.current_hp = roundi(real_g.max_hp*0.5)
	real_g.try_cast_elite_skill({"id":"elite_gumiho_transform"})
	check(real_g.max_hp == 531 and real_g.attack_damage == 92 and is_equal_approx(real_g.attack_cooldown,base_cd/1.5) and is_equal_approx(real_g.move_speed,base_speed*1.5),"actual Battle all4 stats transform")
	check(absf(float(real_g.current_hp)/real_g.max_hp-0.5) < 0.002,"actual Battle preserves HP ratio")
	real_g._physics_process(20)
	check(real_g.max_hp == 354 and real_g.attack_damage == 61 and is_equal_approx(real_g.attack_cooldown,base_cd),"actual Battle reverts transform")
	stats_battle.free()
	b.free()
	print("FANATIC_GUMIHO_SMOKE checks=",checks," failures=",failures)
	quit(1 if failures else 0)
