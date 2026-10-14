extends SceneTree
const DATA := preload("res://src/data/hero_mode_catalog.gd")
const ENCOUNTERS := preload("res://src/hero_mode/hero_encounter_runtime.gd")
const WEAPONS := preload("res://src/data/hero_weapon_catalog.gd")
const PROFILES := preload("res://src/data/hero_profiles.gd")
const CHARACTERS := preload("res://src/data/hero_character_catalog.gd")
const STORE := preload("res://src/systems/hero_mode_store.gd")
const DIRECTOR := preload("res://src/hero_mode/ai_demon_director.gd")
var checks := 0
var failures := 0
class Metrics extends RefCounted:
	var elapsed_seconds := 0.0
class Actor extends Node2D:
	var current_hp := 100
	var max_hp := 100
	var attack_damage := 30
class Arena extends Node2D:
	var battle_over := false
	var external_pause := false
	var hero: Node2D
	var current_map_size := Vector2(2400,2400)
	var current_stage_data := {"number":1}
	var campaign_difficulty := "easy"
	var run_metrics := Metrics.new()
	var spawned: Array = []
	func _clamp_manual_spawn_position(point: Vector2) -> Vector2: return point.clamp(Vector2(70,240),current_map_size-Vector2(70,70))
	func spawn_hero_encounter(id: String, point: Vector2, data: Dictionary) -> Node2D:
		var actor := Actor.new(); actor.position = point; actor.set_meta("kind",data.type); add_child(actor); spawned.append({"id":id,"kind":data.type}); return actor
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func run() -> void:
	var matrix := "stage\tdifficulty\tmax_rarity\tboss\tboss_hp\tboss_damage\troster\n"
	for difficulty in ["easy","hard"]:
		for stage in range(1,11):
			var roster := DATA.roster_for(stage,difficulty)
			matrix += "%d\t%s\t%s\t%s\t%d\t%d\t%s\n" % [stage,difficulty,DATA.RARITY_ORDER[DATA.rarity_limit(stage,difficulty)],DATA.boss_for(stage,difficulty),DATA.boss_data(stage,difficulty).target_hp,DATA.boss_data(stage,difficulty).target_damage,",".join(roster)]
			check(not roster.is_empty(),"nonempty roster "+str(stage)+difficulty)
			for id in roster: check(DATA.monster_allowed(id,stage,difficulty),"rarity enforced "+id)
			check(DATA.monster_allowed(DATA.boss_for(stage,difficulty),stage,difficulty),"boss rarity enforced")
			check(not DATA.monster_allowed("zeus",stage,difficulty),"transcendent excluded")
	for id in CHARACTERS.ORDER:
		var profile := WEAPONS.profile_for_survival(PROFILES.get_profile(id))
		for key in DATA.BASE_HERO_STATS: check(profile[key] == DATA.BASE_HERO_STATS[key],"equal base "+id+key)
	DirAccess.make_dir_recursive_absolute("res://docs")
	var output := FileAccess.open("res://docs/HERO_ENCOUNTER_MATRIX_20261014.tsv",FileAccess.WRITE); output.store_string(matrix); output.close()
	var config := ConfigFile.new(); config.set_value("hero_growth","stage_5_vitality",7)
	check(STORE._shared_growth(config,"vitality") == 7,"legacy investments preserved as common maximum")
	config.set_value("hero_growth","shared_vitality",8)
	check(STORE._shared_growth(config,"vitality") == 8,"common growth advances all heroes")
	for center in [Vector2(80,80),Vector2(2320,2320)]:
		check(DATA.boss_position(center,Vector2(2400,2400)).distance_squared_to(center) >= 180*180,"boss position safe at edge")
	for kind in DATA.EVENT_KINDS:
		for center in [Vector2(1200,1200),Vector2(80,80),Vector2(2320,2320)]:
			var points := DATA.encounter_points(kind,center,Vector2(2400,2400))
			check(not points.is_empty() and points.size() <= 16,"bounded event geometry")
			for point in points: check(point.distance_squared_to(center) >= 180*180 and Rect2(70,70,2261,2261).has_point(point),"safe bounded point")
	var arena := Arena.new(); root.add_child(arena); arena.hero = Actor.new(); arena.hero.position = Vector2(1200,1200); arena.add_child(arena.hero)
	var encounter := ENCOUNTERS.new(); arena.add_child(encounter); encounter.install(arena)
	check(encounter.walls.size() == 8,"eight pooled colliders")
	for index in 4:
		arena.run_metrics.elapsed_seconds = encounter.next_event
		var before := arena.spawned.size(); encounter.tick(0.01)
		check(encounter.warning > 0 and arena.spawned.size() == before,"telegraph before spawn")
		encounter.tick(2.0)
		check(arena.spawned.size()-before <= 4,"bounded burst four per tick")
		for step in 5: encounter.tick(0.1)
		if index == 3:
			check(encounter.wall_time > 0 and encounter.walls[0].visible,"physical barricade activated")
			var probe := CharacterBody2D.new(); probe.collision_layer = 1; probe.collision_mask = 2
			var collider := CollisionShape2D.new(); var circle := CircleShape2D.new(); circle.radius = 16; collider.shape = circle; probe.add_child(collider)
			probe.position = encounter.walls[0].position-Vector2(100,0); arena.add_child(probe)
			await physics_frame; await physics_frame
			check(probe.test_move(probe.global_transform,Vector2(200,0)),"real physics blocks hero movement")
			encounter.tick(16); await process_frame
			check(not encounter.walls[0].visible,"barricade expires and pool hides")
			await physics_frame; await physics_frame
			check(not probe.test_move(probe.global_transform,Vector2(200,0)),"expired barricade releases physical path")
			probe.queue_free()
	arena.run_metrics.elapsed_seconds = 900
	encounter.tick(0.1)
	check(encounter.finale and is_instance_valid(encounter.boss) and not arena.battle_over,"900 starts boss, not victory")
	var count := arena.spawned.size()
	for index in 10: encounter.tick(1.0)
	check(arena.spawned.size() == count,"only one boss and no more waves")
	arena.external_pause = true; encounter.tick(100)
	check(arena.spawned.size() == count,"pause respected")
	var finale = load("res://tests/hero_finale_harness.gd").new(); root.add_child(finale)
	finale.hero = Actor.new(); finale.hero.position = Vector2(1200,1200); finale.add_child(finale.hero)
	finale.run_metrics.elapsed_seconds = 900; finale._on_run_time_up()
	check(not finale.battle_over,"actual Battle timeout no longer wins")
	check(finale._spawn_monster("slime",Vector2(600,600)) == null,"actual factory stops ordinary spawns after 900")
	check(finale.spawn_hero_encounter("zeus",Vector2(600,600),{}) == null,"actual spawn rejects disallowed grade")
	for index in 72: finale.active_monsters[index] = true
	check(finale.spawn_hero_encounter("orc",Vector2(600,600),{}) == null,"actual spawn respects entity cap")
	finale.current_stage_data.number = 10
	check(finale.get_population_limit() == 108,"hero population bypasses demon command cap100")
	finale.run_metrics.elapsed_seconds = 800
	var above72 = finale._spawn_monster("orc",Vector2(600,600))
	check(is_instance_valid(above72),"stage10 ordinary factory accepts above72")
	var event_above72 = finale.spawn_hero_encounter("orc",Vector2(600,600),{})
	check(is_instance_valid(event_above72),"stage10 event accepts above72")
	for index in 108: finale.active_monsters[index] = true
	check(finale._spawn_monster("orc",Vector2(600,600)) == null and finale.spawn_hero_encounter("orc",Vector2(600,600),{}) == null,"stage10 all factory paths stop at108")
	finale.hero_player_mode = false
	check(finale.get_population_limit() == 100,"demon command population unchanged")
	finale.hero_player_mode = true; finale.current_stage_data.number = 1; finale.run_metrics.elapsed_seconds = 900
	finale.active_monsters.clear()
	check(finale.spawn_hero_encounter("orc",finale.hero.position,{}) == null,"actual spawn forbids overlap")
	var final_actor = finale.spawn_hero_encounter("orc",Vector2(600,600),{"type":"boss","target_hp":11800,"target_damage":32})
	check(final_actor.max_hp == 11800 and final_actor.current_hp == 11800 and final_actor.attack_damage == 32,"actual boss uses stage stat budget")
	check(is_instance_valid(final_actor) and final_actor.get_meta("hero_final_boss",false),"actual spawn marks final boss")
	finale.hero.current_hp = 0; finale._finish_hero_boss_victory()
	check(not finale.battle_over,"dead hero cannot win simultaneous defeat")
	finale.hero.current_hp = 100; finale.run_metrics.elapsed_seconds = 899; finale._finish_hero_boss_victory()
	check(not finale.battle_over,"premature boss completion rejected")
	finale.run_metrics.elapsed_seconds = 901; finale._finish_hero_boss_victory(); finale._finish_hero_boss_victory()
	check(finale.won and finale.finish_count == 1,"actual boss victory finalizes once")
	finale.battle_over = false; finale.hero_player_mode = false; finale._on_run_time_up()
	check(finale.battle_over and not finale.won,"demon mode timeout preserved")
	finale.queue_free()
	var selector_harness = load("res://tests/hero_difficulty_harness.gd").new()
	var body := VBoxContainer.new(); root.add_child(body); selector_harness.build(body)
	var selector: OptionButton = body.get_node("HeroDifficulty")
	check(selector.get_item_count() == 2 and selector.selected == 0,"difficulty control offers easy/hard")
	selector.select(1); selector.item_selected.emit(1)
	check(selector_harness.STORE.difficulty() == "hard","actual binding selects hard")
	selector_harness.STORE.fail = true; selector.select(0); selector.item_selected.emit(0)
	check(selector.selected == 1,"failed save restores previous difficulty")
	body.queue_free()
	print("HERO_ENCOUNTERS checks=%d failures=%d" % [checks,failures])
	arena.queue_free(); await process_frame; quit(1 if failures else 0)
