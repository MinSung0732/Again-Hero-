extends SceneTree
const CATALOG := preload("res://src/data/monster_catalog.gd")
const AUGMENTS := preload("res://src/data/demon_augment_catalog.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
var failed := false
var battle
var hero

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("SCORPION_TEST: " + message)

func spawn(position_to_use := Vector2(1100, 1000)):
	var monster = battle._spawn_monster("scorpion", position_to_use)
	monster.set_physics_process(false)
	return monster

func reset_target() -> void:
	hero._clear_medusa_statuses()
	hero.shield_hp = 0
	hero.invulnerability_timer = 0

func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	SCOPE.guest_directory = "user://scorpion_test_" + Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	SCOPE.select_guest()
	battle = load("res://src/battle/Battle.tscn").instantiate()
	root.add_child(battle)
	battle.set_process(false)
	battle.set_physics_process(false)
	await battle.prepare_spawn_resources()
	hero = battle.hero
	hero.set_physics_process(false)
	hero.position = Vector2(1000, 1000)
	hero.max_hp = 100000
	hero.current_hp = 100000
	reset_target()
	check(CATALOG.get_rarity("scorpion") == "common" and CATALOG.get_base_cost("scorpion") == 3, "common cost three")
	check(load("res://src/data/shop_catalog.gd").get_monster_pool("common").has("scorpion"), "real common gacha pool includes scorpion")
	check(load("res://src/systems/monster_collection_store.gd").load_state().has("scorpion"), "collection supports scorpion")
	check(CATALOG.get_species_label(CATALOG.get_species("scorpion")) == "짐승", "beast species")
	for candidate in AUGMENTS.get_monster_normal_augments("scorpion", ""):
		check(AUGMENTS.get_augment(candidate.id) == candidate, "normal augments registered")
	var first = spawn()
	check(first.visual.sprite_frames.get_frame_count("attack") == 5 and first.visual.sprite_frames.get_frame_count("death") == 3, "supplied normal animations")
	var applied: int = first._deal_hit(hero)
	check(applied > 0 and hero.damage_poison_tracker.entries.size() == 1, "real hit records poison")
	var entry: Dictionary = hero.damage_poison_tracker.entries[first.get_instance_id()]
	check(entry.total == applied and entry.duration == 10, "exact recorded damage over ten seconds")
	hero._update_damage_poison(2)
	hero.invulnerability_timer = 0
	first._deal_hit(hero)
	check(entry.elapsed == 2 and entry.total == applied, "same hit channel neither stacks nor refreshes")
	var hp: int = hero.current_hp
	hero.invulnerability_timer = 100
	hero._update_damage_poison(8)
	check(hero.current_hp == hp - (applied - int(round(applied * 0.2))) and hero.damage_poison_tracker.entries.is_empty(), "poison completes exact total despite iframe")
	reset_target()
	hero.invulnerability_timer = 100
	check(first._deal_hit(hero) == 0 and hero.damage_poison_tracker.entries.is_empty(), "blocked first hit no poison")
	reset_target()
	var second = spawn()
	first._deal_hit(hero)
	hero.invulnerability_timer = 0
	second._deal_hit(hero)
	check(hero.damage_poison_tracker.entries.size() == 2, "separate scorpions independent poisons")
	reset_target()
	hero.shield_hp = 100
	check(first._deal_hit(hero) > 0 and hero.damage_poison_tracker.entries[first.get_instance_id()].total == first.attack_damage, "shield absorption included in actual damage budget")
	reset_target()
	battle.demon_special_augments.assign(CATALOG.MONSTERS.scorpion.special_augment_ids)
	var upgraded = spawn(hero.position + Vector2(30, 0))
	check(upgraded.attack_damage == int(round(first.attack_damage * 1.2)), "twinsting damage plus twenty percent once")
	upgraded._attack_target(hero)
	check(hero.damage_poison_tracker.entries.size() == 1 and hero.damage_poison_tracker.entries[upgraded.get_instance_id()].duration == 3, "rapid venom first channel three seconds")
	upgraded._tick_followup(0.06)
	check(hero.damage_poison_tracker.entries.size() == 1, "followup delayed")
	upgraded._tick_followup(0.07)
	check(hero.damage_poison_tracker.entries.size() == 2, "second hit bypasses first-hit iframe and records separate poison")
	hp = hero.current_hp
	hero._update_damage_poison(3)
	check(hero.current_hp == hp - upgraded.attack_damage * 2 and hero.damage_poison_tracker.entries.is_empty(), "both poison budgets complete independently")
	reset_target()
	hero.invulnerability_timer = 100
	upgraded._attack_target(hero)
	upgraded._tick_followup(0.13)
	check(hero.damage_poison_tracker.entries.size() == 1, "second hit bypasses existing iframe even if first blocked")
	reset_target()
	var dying_attack: int = upgraded.attack_damage
	var death_position: Vector2 = upgraded.position
	upgraded.take_damage(100000)
	check(battle.scorpion_swamp_runtime.zones.size() == 1, "one death swamp")
	var zone: Dictionary = battle.scorpion_swamp_runtime.zones[0]
	check(zone.position == death_position and zone.radius_sq == 75 * 75 and zone.total == dying_attack * 2, "diameter one fifty and snapshot total damage")
	var swamp_line = zone.line
	check(swamp_line.visible and swamp_line.points.size() == 40 and swamp_line.closed, "visible pooled range ring")
	upgraded.free()
	hp = hero.current_hp
	hero.invulnerability_timer = 100
	for i in range(6):
		battle.scorpion_swamp_runtime.tick(0.5)
	check(hero.current_hp == hp - dying_attack * 2, "swamp exact three-second total after source freed")
	check(battle.scorpion_swamp_runtime.zones.is_empty() and not swamp_line.visible, "swamp expires and recycles")
	var outside = spawn(hero.position + Vector2(76, 0))
	outside.take_damage(100000)
	hp = hero.current_hp
	battle.scorpion_swamp_runtime.tick(3)
	check(hero.current_hp == hp, "outside radius no damage")
	check(battle.transient_fx_pools["scorpion_venom_swamp"].size() == 1, "range visual reused")
	reset_target()
	# Remove prior distant normal sources from the consumption candidates.
	first.position = Vector2(2000, 2000)
	second.position = Vector2(2000, 2000)
	battle.monster_spatial_grid_physics_frame = -1
	var elite = spawn(Vector2(1500, 1500))
	battle._apply_special_monster_modifiers(elite, "scorpion", {"type":"elite", "name":"엘리트 전갈", "hp_multiplier":2.0, "damage_multiplier":2.0, "attack_speed_multiplier":1.2})
	check(elite.visual.sprite_frames.get_frame_count("attack") == 6, "supplied elite animation")
	var meal = spawn(elite.position + Vector2(40, 0))
	var far_meal = spawn(elite.position + Vector2(80, 0))
	var old_hp: int = elite.max_hp
	var old_damage: int = elite.attack_damage
	var old_speed: float = elite.move_speed
	var old_rate: float = 1.0 / elite.attack_cooldown
	var meal_hp: int = meal.max_hp
	var meal_damage: int = meal.attack_damage
	var meal_speed: float = meal.move_speed
	var meal_rate: float = 1.0 / meal.attack_cooldown
	var alive: int = battle.monsters_alive
	var deaths: int = int(battle.run_metrics.monster_death_counts.get("scorpion", 0))
	var orb_count: int = get_nodes_in_group("exp_orbs").size()
	var kills: int = battle.hero_kills_toward_heal_item
	battle.command_power = 0
	var command: float = battle.command_power
	var meal_id: int = meal.get_instance_id()
	battle.death_refund_ratio = 1.0
	battle.monster_summon_costs[meal_id] = 3.0
	battle.elite_monster_skill_runtime.tick(2.99)
	check(not meal.dying, "three-second initial cooldown")
	battle.elite_monster_skill_runtime.tick(0.02)
	check(meal.dying and not far_meal.dying, "nearest one normal consumed")
	check(elite.max_hp == old_hp + meal_hp and elite.attack_damage == old_damage + meal_damage, "permanent health/damage added")
	check(is_equal_approx(elite.move_speed, old_speed + meal_speed) and is_equal_approx(1.0 / elite.attack_cooldown, old_rate + meal_rate), "movement and attack rate added")
	check(battle.monsters_alive == alive - 1 and not battle.active_monsters.has(meal_id) and not battle.monster_summon_costs.has(meal_id), "consumption unregisters alive/cost registries")
	check(int(battle.run_metrics.monster_death_counts.get("scorpion", 0)) == deaths and get_nodes_in_group("exp_orbs").size() == orb_count and battle.hero_kills_toward_heal_item == kills, "no XP or kill counters")
	check(battle.command_power == command + 3 and battle.scorpion_swamp_runtime.zones.size() == 1, "ordinary death refund and swamp remain during rewardless consumption")
	battle.scorpion_swamp_runtime.tick(3)
	var interval: float = elite.attack_cooldown
	battle._refresh_alive_monsters_for_augments()
	check(elite.max_hp == old_hp + meal_hp and elite.attack_damage == old_damage + meal_damage and is_equal_approx(elite.attack_cooldown, interval), "augment refresh preserves absorption without duplication")
	battle.demon_level += 1
	battle._apply_demon_level_scaling_to_monster(elite, true)
	check(elite.max_hp > old_hp + meal_hp and elite.absorbed_stats.hp == meal_hp and is_equal_approx(elite.attack_cooldown, interval), "level growth preserves absorption")
	battle.elite_monster_skill_runtime.tick(6.99)
	check(not far_meal.dying, "seven-second repeat cooldown")
	battle.elite_monster_skill_runtime.tick(0.02)
	check(far_meal.dying, "second meal after seven seconds")
	battle.scorpion_swamp_runtime.tick(3)
	reset_target()
	elite.position = hero.position + Vector2(30, 0)
	elite.attack_cooldown = 0.08
	elite._attack_target(hero)
	elite._tick_followup(0.04)
	check(hero.damage_poison_tracker.entries.size() == 2 and elite.followup_target == null, "very fast absorbed attack rate still completes both hits")
	reset_target()
	battle.scorpion_swamp_runtime.spawn(hero.position, 10, {"duration":1.0}, first)
	battle.scorpion_swamp_runtime.spawn(hero.position + Vector2(300, 0), 10, {"duration":3.0}, first)
	hp = hero.current_hp
	battle.scorpion_swamp_runtime.tick(1)
	check(hero.current_hp == hp - 20 and battle.scorpion_swamp_runtime.zones.size() == 1, "mixed expiry only active inside zone deals its budget")
	check(battle.scorpion_swamp_runtime.zones[0].elapsed == 1, "swap removal does not double tick surviving zone")
	battle.scorpion_swamp_runtime.tick(2)
	check(battle.scorpion_swamp_runtime.zones.is_empty(), "mixed lifetime zones all recycle")
	battle.free()
	await process_frame
	print("SCORPION_TEST: " + ("FAILED" if failed else "PASS"))
	quit(1 if failed else 0)
