extends SceneTree
const S := preload("res://src/monsters/DarkElfRogue.tscn")
const C := preload("res://src/data/monster_catalog.gd")
const A := preload("res://src/data/demon_augment_catalog.gd")
const D := preload("res://src/data/dark_elf_rogue_behavior_catalog.gd")
const P := preload("res://src/systems/hero_target_policy.gd")
const HIT := preload("res://src/systems/monster_hit_context.gd")
const SHOP := preload("res://src/data/shop_catalog.gd")
const ELITE := preload("res://src/systems/elite_monster_skill_runtime.gd")
const DAMAGE := preload("res://src/ui/damage_number_spawner.gd")
var checks := 0
var failures := 0
class Hero extends Node2D:
	var hero_sprite := Sprite2D.new()
	var current_hp := 100000
	var shield_hp := 0
	var immune := false
	var hits: Array[int] = []
	var colors: Array[Color] = []
	func take_damage(amount: int,_source: Node = null) -> bool:
		if immune: return false
		immune = true
		return _receive(amount)
	func take_followup_damage(amount: int,_source: Node = null) -> bool: return _receive(amount)
	func _receive(amount: int) -> bool:
		hits.append(amount)
		colors.append(get_meta("damage_number_color_once",Color.WHITE))
		DAMAGE.show(self,amount)
		var absorbed := mini(shield_hp,amount)
		shield_hp -= absorbed; current_hp -= amount-absorbed
		return true
class Audio extends Node:
	func play_battle(_key: String,_battle: Node) -> void: pass
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func function_source(source: String,name: String) -> String:
	var start := source.find("func "+name+"(")
	var end := source.find("\nfunc ",start+1)
	return source.substr(start,end-start if end>=0 else source.length()-start)
func make_battle():
	var script := GDScript.new()
	script.source_code = '''extends Node2D
const MONSTER_SUPPORT_COMMON = preload("res://src/monsters/monster_runtime_common.gd")
var hero: Node2D
var configs: Dictionary = {}
func _get_special_augment_config(_id: String) -> Dictionary: return configs
func _get_demon_level_monster_hp_multiplier(_spawn_seconds: float = -1.0) -> float: return 1.0
func _get_demon_level_monster_damage_multiplier(_spawn_seconds: float = -1.0) -> float: return 1.0
func _get_demon_level_monster_speed_multiplier(_spawn_seconds: float = -1.0) -> float: return 1.0
func _clamp_manual_spawn_position(point: Vector2) -> Vector2: return point
func invalidate_monster_spatial_snapshot() -> void: pass
'''
	var source := FileAccess.get_file_as_string("res://src/battle/battle.gd")
	for name in ["_apply_demon_level_scaling_to_monster","refresh_monster_runtime_stats","_get_special_stat_multiplier"]:
		script.source_code += "\n"+function_source(source,name)+"\n"
	check(script.reload() == OK,"actual Battle stat functions compile")
	return script.new()
func actor(battle):
	var unit = S.instantiate()
	C.apply_runtime_base_stats(unit,"dark_elf_rogue")
	for pair in [["max_hp","demon_level_base_max_hp"],["attack_damage","demon_level_base_attack_damage"],["move_speed","demon_level_base_move_speed"]]: unit.set_meta(pair[1],unit.get(pair[0]))
	unit.configure_combat_context(battle.hero,battle)
	battle.add_child(unit); unit.set_physics_process(false)
	unit.attack_timer = 1000
	return unit
func reset_hit(hero) -> void:
	hero.immune = false; hero.hits.clear(); hero.colors.clear()
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var battle = make_battle(); root.add_child(battle)
	battle.hero = Hero.new(); battle.hero.add_to_group("hero"); battle.add_child(battle.hero)
	battle.hero.add_child(battle.hero.hero_sprite)
	battle.hero.position = Vector2(30,0)
	var unit = actor(battle)
	var hero = battle.hero
	check(C.get_rarity("dark_elf_rogue") == "uncommon" and C.get_role("dark_elf_rogue") == "exploder" and C.get_species("dark_elf_rogue") == "humanoid","advanced humanoid burst")
	check(unit.max_hp == 142 and unit.attack_damage == 13 and C.get_base_cost("dark_elf_rogue") == 9,"balanced142/13/cost9")
	check(C.get_summon_exp("dark_elf_rogue") == 9,"summonEXP included")
	var pool := SHOP.get_monster_pool("uncommon")
	check("dark_elf_rogue" in pool and SHOP.roll_monster("uncommon",(pool.find("dark_elf_rogue")+0.5)/pool.size()) == "dark_elf_rogue","actual seeded gacha")
	check(unit.visual.sprite_frames.get_frame_count("attack") == 6 and unit.visual.sprite_frames.get_frame_count("hit") == 4,"normal realframes")
	unit.apply_visual_profile(D.ELITE_VISUAL)
	check(unit.visual.sprite_frames.get_frame_count("hit") == 3,"elite realframes")
	unit._attack_target(hero); unit._tick_followup(0.13)
	check(hero.hits == [13],"followup not early")
	unit._tick_followup(0.02)
	check(hero.hits == [13,13],"two full strikes, own immunity does not cancel second")
	var start: Vector2 = unit.position
	unit._physics_process(0.1)
	check(unit.position != start and unit.reposition_goal.distance_to(hero.position) <= unit.attack_range+0.01,"physical reposition inside melee range")
	unit.position = Vector2.ZERO; unit.reposition_active = false
	unit.quiet_time = 0; unit._physics_process(2.9)
	check(not unit.stealth_active,"no early stealth")
	unit._physics_process(0.11)
	check(unit.stealth_active and is_equal_approx(unit.visual.self_modulate.a,0.4),"three second stealth visual")
	var hp: int = unit.current_hp
	HIT.hit(unit,20,"melee")
	check(unit.current_hp == hp-10 and unit.quiet_time == 0,"stealth half damage/preparation reset")
	reset_hit(hero); unit._attack_target(hero); unit._tick_followup(0.14)
	check(hero.hits == [20,13] and not unit.stealth_active and unit.quiet_time == 0,"stealth150 first strike only")
	unit.configure_special_augments({"dark_elf_rogue_assassinate":{},"dark_elf_rogue_backstab":{}})
	unit._enter_stealth(); reset_hit(hero); hero.hero_sprite.flip_h = false
	unit.position = Vector2.ZERO; unit._attack_target(hero); unit._tick_followup(0.14)
	check(hero.hits == [52,17] and hero.colors == [D.BACKSTAB_COLOR,D.BACKSTAB_COLOR],"300percent ambush and133percent rear red both hits")
	# Hits merged into a live popup apply their colour in the popup's next _process (process_frame fires first).
	await process_frame
	await process_frame
	check(hero.get_meta("damage_number_popup").get_node("Value").get_theme_color("font_color") == D.BACKSTAB_COLOR,"actual damage popup red color")
	check(not hero.has_meta("damage_number_color_once"),"red metadata does not leak")
	reset_hit(hero); hero.hero_sprite.flip_h = true; unit._attack_target(hero); unit._tick_followup(0.14)
	check(hero.hits == [13,13] and hero.colors == [Color.WHITE,Color.WHITE],"front no bonus/color")
	reset_hit(hero); hero.hero_sprite.flip_h = false; hero.set_meta("damage_number_color_once",Color.BLUE)
	unit._attack_target(hero)
	check(hero.get_meta("damage_number_color_once") == Color.BLUE,"preserve preexisting scoped color")
	hero.remove_meta("damage_number_color_once"); unit.followup_target = null
	battle.configs = {"dark_elf_rogue_blades":A.get_augment("dark_elf_rogue_blades").effect_values}
	battle.refresh_monster_runtime_stats(unit)
	check(unit.attack_damage == 17,"attack30percent both hit basis")
	battle.configs = {}; battle.refresh_monster_runtime_stats(unit)
	unit.configure_special_augments({"dark_elf_rogue_assassinate":{},"dark_elf_rogue_backstab":{}})
	unit._enter_stealth()
	var revision := P.revision
	check(unit.try_cast_elite_skill({}),"darkness starts")
	check(unit.dark_remaining == 5 and not unit.stealth_active and unit.modulate.a == 0 and not P.is_detectable(unit) and P.revision == revision+1,"fully invisible/untargetable/cache invalidation")
	check(is_equal_approx(unit._get_combat_bonuses().move_speed_multiplier,1.3),"movement30percent")
	var targets: Array = [unit,hero]; P.filter_detectable(targets)
	check(targets == [hero],"actual target policy filters rogue")
	hp = unit.current_hp; HIT.hit(unit,10,"ranged")
	check(unit.current_hp == hp-17,"hidden receives170percent, no normal stealth reduction")
	unit._enter_stealth(); check(not unit.stealth_active,"normal stealth blocked during darkness")
	reset_hit(hero); hero.immune = true
	unit._attack_target(hero)
	check(unit.dark_remaining > 0 and not P.is_detectable(unit) and unit.followup_target == null,"immune miss does not consume elite reveal strike")
	reset_hit(hero); unit._attack_target(hero); unit._tick_followup(0.14)
	check(hero.hits == [39,17],"225percent elite times133rear, no300ambush multiplier")
	check(unit.dark_remaining == 0 and unit.modulate.a == 1 and P.is_detectable(unit),"successful hit reveals and restores targeting")
	unit.followup_target = null; unit.reposition_active = false; unit.attack_timer = 1000
	unit.try_cast_elite_skill({}); unit._physics_process(4.99)
	check(unit.dark_remaining > 0 and not unit.stealth_active,"five seconds not early expiry")
	unit._physics_process(0.02)
	check(unit.dark_remaining == 0 and P.is_detectable(unit) and unit.quiet_time == 0,"timeout restores targeting and restarts preparation")
	for status in ["stun_active","silence_active"]:
		unit.set_meta(status,true); check(not unit.try_cast_elite_skill({}),"elite blocked:"+status); unit.remove_meta(status)
	reset_hit(hero); unit._attack_target(hero); hero.position = Vector2(1000,0); unit._tick_followup(0.14)
	check(hero.hits.size() == 1,"second hit cancels when target leaves range")
	var audio := Audio.new(); audio.name = "GameAudio"; root.add_child(audio)
	var manager = ELITE.new(); manager.setup(battle)
	manager.register_elite(unit,"dark_elf_rogue",C.get_elite_skills("dark_elf_rogue"))
	manager.tick(2.99); check(unit.dark_remaining == 0,"actual elite initial wait")
	manager.tick(0.02)
	check(unit.dark_remaining == 5 and manager._skill_states[unit.get_instance_id()].skills[0]._timer == 20,"actual initial3 and cooldown20")
	HIT.hit(unit,10000,"ranged")
	check(unit.dying and unit.dark_remaining == 0 and P.is_detectable(unit) and unit.modulate.a == 1,"death clears hide and restores death visual")
	manager.reset()
	var removed = actor(battle); removed.try_cast_elite_skill({}); var previous := P.revision; removed.free()
	check(P.revision == previous+1,"tree exit clears hidden cache state")
	battle.free(); audio.free()
	print("DARK_ELF_ROGUE_SMOKE checks=",checks," failures=",failures)
	quit(1 if failures else 0)
