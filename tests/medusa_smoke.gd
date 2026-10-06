extends SceneTree
const CATALOG := preload("res://src/data/monster_catalog.gd")
const AUGMENTS := preload("res://src/data/demon_augment_catalog.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const COMMON := preload("res://src/monsters/monster_runtime_common.gd")
const FX := preload("res://src/ui/combat_status_effect_visual.gd")
var failed := false
var battle
var hero
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool,message: String) -> void:
	if not ok:
		failed = true
		push_error("MEDUSA_TEST: " + message)
func spawn(position_to_use := Vector2(1100,1000)):
	var monster = battle._spawn_monster("medusa",position_to_use)
	monster.set_physics_process(false)
	return monster
func hit(monster) -> int:
	hero.invulnerability_timer = 0
	return monster._deal_hit(hero)
func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	SCOPE.guest_directory = "user://medusa_test_" + Crypto.new().generate_random_bytes(16).hex_encode()
	SCOPE.select_guest()
	battle = load("res://src/battle/Battle.tscn").instantiate()
	root.add_child(battle)
	battle.set_process(false)
	battle.set_physics_process(false)
	await battle.prepare_spawn_resources()
	hero = battle.hero
	hero.set_physics_process(false)
	hero.max_hp = 100000
	hero.current_hp = 100000
	hero.shield_hp = 0
	hero.status_resistances.clear()
	hero.position = Vector2(1000,1000)
	check(CATALOG.get_rarity("medusa") == "rare" and CATALOG.get_species_label(CATALOG.get_species("medusa")) == "인간형" and CATALOG.get_base_cost("medusa") == 7, "identity")
	check(CATALOG.get_grade_label("rare") == "희귀", "grade label")
	for candidate in AUGMENTS.get_monster_normal_augments("medusa",""):
		check(AUGMENTS.get_augment(candidate.id) == candidate,"normal augment lookup")
	var first = spawn()
	var second = spawn()
	check(first.visual.sprite_frames.get_frame_count("attack") == 6, "normal frames")
	check(first.collision_mask & 2 == 0 and COMMON.compute_soft_separation_bias(first,battle) == Vector2.ZERO,"no monster collision or separation")
	first._physics_process(1.0)
	check(is_equal_approx(first.pursuit_multiplier,1.1) and second.pursuit_multiplier == 1, "per-unit pursuit growth")
	first._physics_process(100.0)
	check(first.pursuit_multiplier == 2, "growth cap")
	hero.invulnerability_timer = 10
	check(first._deal_hit(hero) == 0 and first.pursuit_multiplier == 2 and hero.medusa_hit_stacks == 0,"blocked hit gives no stacks or reset")
	for i in range(9):
		hit(first if i % 2 == 0 else second)
	check(hero.medusa_hit_stacks == 9 and hero.petrify_timer == 0,"nine shared hits")
	hit(second)
	check(is_equal_approx(hero.petrify_timer,2.5) and hero.medusa_stone_threshold == 11 and hero.medusa_hit_stacks == 0,"tenth hit petrifies and raises threshold")
	check(hero.hero_sprite.self_modulate.r < 0.9 and hero.hero_sprite.speed_scale > 0,"dark tint but animation not frozen")
	check(not hero.apply_petrify(10),"active stone not refreshed")
	var anchor: Vector2 = hero.position
	first.position = hero.position + Vector2(200,0)
	second.position = hero.position + Vector2(250,0)
	hero.target = first
	hero.retarget_timer = 10
	hero.attack_timer = 0
	hero._physics_process(0.1)
	check(hero.position == anchor and hero.velocity == Vector2.ZERO,"root holds position")
	check(hero.attack_timer > 0,"basic attack continues during stone")
	hero.global_position += Vector2(400,0)
	hero._clamp_to_battlefield()
	check(hero.position == anchor,"blink or lunge cannot displace stone")
	hero._tick_petrify(3)
	check(not hero.get_meta("petrify_active") and hero.hero_sprite.self_modulate == Color.WHITE,"stone expires and restores tint")
	for i in range(10):
		hit(first)
	check(hero.petrify_timer == 0 and hero.medusa_hit_stacks == 10,"next threshold is eleven")
	hit(first)
	check(hero.petrify_timer > 0 and hero.medusa_stone_threshold == 12,"eleventh hit triggers next stone")
	hero._clear_medusa_statuses()
	battle.demon_special_augments.assign(CATALOG.MONSTERS.medusa.special_augment_ids)
	var augmented = spawn()
	augmented.pursuit_multiplier = 2
	var expected: int = augmented.attack_damage + int(round(augmented.get_actual_move_speed() * 0.05))
	check(hit(augmented) == expected and augmented.pursuit_multiplier == 1,"speed damage samples before reset")
	hero.apply_petrify(1)
	expected = int(round((augmented.attack_damage + int(round(augmented.get_actual_move_speed()*0.05))) * 1.5))
	check(hit(augmented) == expected,"stone target damage bonus")
	hero._clear_medusa_statuses()
	for i in range(10):
		hit(augmented)
	hero._tick_petrify(3)
	check(hero.slow_timer == 3 and is_equal_approx(hero.move_multiplier,0.7),"release slow three seconds thirty percent")
	hero._clear_medusa_statuses()
	var elite = spawn(Vector2(1000,1000))
	battle._apply_special_monster_modifiers(elite,"medusa",{"type":"elite"})
	check(not elite.elite_aura.is_empty() and elite.visual.sprite_frames.get_frame_count("move") == 6,"elite passive activated, elite frames")
	first.position = elite.position + Vector2(249,0)
	second.position = elite.position + Vector2(251,0)
	battle.monster_spatial_grid_physics_frame = -1
	elite._tick_aura(0.2)
	check(first.poison_aura_remaining > 0 and second.poison_aura_remaining == 0 and elite.poison_aura_remaining > 0,"radius 250 including self, outside excluded")
	var applied := hit(first)
	check(hero.damage_poison_tracker.entries.size() == 1 and hero.get_meta("poison_active"),"aura hit creates source-specific poison")
	var before := int(hero.damage_poison_tracker.entries[first.get_instance_id()].total)
	hit(first)
	check(hero.damage_poison_tracker.entries.size() == 1 and hero.damage_poison_tracker.entries[first.get_instance_id()].total == before,"same source no refresh or stack")
	second.poison_aura_remaining = 1
	var second_applied := hit(second)
	check(hero.damage_poison_tracker.entries.size() == 2,"different source independent poison")
	var hp: int = hero.current_hp
	hero.invulnerability_timer = 100
	hero._update_damage_poison(5)
	check(hero.current_hp == hp - applied - second_applied and hero.damage_poison_tracker.entries.is_empty(),"exact damage budgets, invulnerability ignored, expiry")
	check(hero.apply_damage_poison(5,20,first),"source can reapply after expiration")
	first.free()
	hp = hero.current_hp
	hero._update_damage_poison(5)
	check(hero.current_hp == hp - 20,"poison survives source death")
	var effect := FX.new()
	hero.add_child(effect)
	effect.setup(hero,"poison")
	check(effect.sprite_frames.get_frame_count("fx") == 4,"existing poison pixel effect")
	hero.apply_damage_poison(5,50,second)
	effect._process(0.2)
	check(effect.visible,"poison visual active")
	hero._clear_medusa_statuses()
	# A recorded hit has already gone through guard mitigation; do not reduce it twice.
	var saved_archetype: String = hero.hero_archetype
	hero.hero_archetype = "sword_shield"
	hero.fighter_guard_active = true
	hp = hero.current_hp
	check(hero.apply_damage_poison(5,100,second),"guard poison accepted")
	hero._update_damage_poison(5)
	check(hero.current_hp == hp - 100,"guard does not mitigate recorded damage twice")
	hero.fighter_guard_active = false
	hero.hero_archetype = saved_archetype
	hero.apply_damage_poison(5,100,second)
	hero.apply_poison(0.5,0.001,0.5,second)
	hero._update_poison(0.5)
	hero._update_damage_poison(0.5)
	check(hero.poison_timer == 0 and hero.get_meta("poison_active"),"legacy poison expiry preserves Medusa visual")
	hero._clear_medusa_statuses()
	hero.current_hp = 1
	hero.apply_damage_poison(5,50,second)
	hero._update_damage_poison(5)
	check(hero.damage_poison_tracker.entries.is_empty() and hero.petrify_timer == 0,"lethal poison safely clears statuses mid tick")
	print("MEDUSA_TEST: " + ("FAILED" if failed else "PASS"))
	quit(1 if failed else 0)
