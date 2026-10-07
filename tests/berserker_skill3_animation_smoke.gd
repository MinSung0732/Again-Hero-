extends SceneTree

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const PROGRESS := preload("res://src/systems/stage_progress.gd")
var failed := false


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("BERSERKER_SKILL3: " + message)


func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	SCOPE.guest_directory = "user://skill3_test_" + Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	SCOPE.select_guest()
	PROGRESS.set_current_stage("stage_6")
	var battle = load("res://src/battle/Battle.tscn").instantiate()
	root.add_child(battle)
	battle.set_process(false)
	battle.set_physics_process(false)
	await battle.prepare_spawn_resources()
	var hero = battle.hero
	hero.set_physics_process(false)
	check(hero.hero_archetype == "berserker_madness", "actual stage six profile")
	var target := Node2D.new()
	battle.add_child(target)
	for iteration in range(3):
		hero.position = Vector2(700, 1000)
		target.position = Vector2(1200, 1000)
		hero.max_hp = 10000
		hero.current_hp = 10000
		hero.hit_pose_timer = 0.0
		var layer: int = hero.collision_layer
		var mask: int = hero.collision_mask
		var monster = null
		if iteration == 1:
			monster = battle._spawn_monster("slime", target.position)
			monster.set_physics_process(false)
		hero._start_berserker_skill3(target)
		check(hero.berserker_skill3_active and hero.hero_sprite.animation == &"dash_start", "cast starts with dash pose")
		check(hero.current_hp == 9500, "existing five percent HP cost")
		check(hero.collision_layer == 0 and hero.collision_mask == 0, "dash collision disabled")
		hero._play_stage1_animation("move")
		check(hero.hero_sprite.animation == &"dash_start", "active dash cannot be interrupted by movement")
		await create_timer(0.26).timeout
		check(hero.hero_sprite.animation == &"dash_finish" and hero.berserker_skill3_active, "finish pose retained during recovery")
		check(hero.collision_layer == layer and hero.collision_mask == mask, "collision restored after dash")
		if iteration == 2:
			hero.hit_pose_timer = 2.0
			hero._restart_stage1_animation("hit")
		else:
			hero._play_stage1_animation("idle")
			check(hero.hero_sprite.animation == &"dash_finish", "active recovery retains finish pose")
		for tick in range(100):
			if not hero.berserker_skill3_active:
				break
			await create_timer(0.02).timeout
		check(not hero.berserker_skill3_active and hero.attack_pose_timer == 0.0, "cast completes")
		if iteration == 2:
			check(hero.hero_sprite.animation == &"hit", "completion preserves higher priority hit")
			hero.hit_pose_timer = 0.0
			await create_timer(0.3).timeout
			hero._play_stage1_animation("idle")
		check(hero.hero_sprite.animation == &"idle", "completed skill returns to idle")
		hero.velocity = Vector2(100, 0)
		hero._update_berserker_pose_visual(0.016)
		check(hero.hero_sprite.animation == &"move", "movement resumes")
		hero.attack_pose_timer = 0.3
		hero._restart_stage1_animation("attack")
		check(hero.hero_sprite.animation == &"attack", "subsequent attack animation resumes")
		hero.attack_pose_timer = 0.0
		await create_timer(0.5).timeout
		if is_instance_valid(monster):
			monster.free()
	# Shared guard still protects another active dash owner and non-looping clips.
	hero._restart_stage1_animation("dash_finish")
	hero.fighter_charge_active = true
	hero._play_stage1_animation("idle")
	check(hero.hero_sprite.animation == &"dash_finish", "fighter charge ownership retained")
	hero.fighter_charge_active = false
	hero.hero_sprite.sprite_frames.set_animation_loop("dash_finish", false)
	hero._restart_stage1_animation("dash_finish")
	hero._play_stage1_animation("idle")
	check(hero.hero_sprite.animation == &"dash_finish", "non-looping dash protected until clip completes")
	await create_timer(1.1).timeout
	hero._play_stage1_animation("idle")
	check(hero.hero_sprite.animation == &"idle", "finished non-looping dash releases")
	hero.is_dying = true
	hero._restart_stage1_animation("death")
	hero._play_stage1_animation("idle")
	check(hero.hero_sprite.animation == &"death", "death protection retained")
	battle.free()
	await create_timer(0.2).timeout
	print("BERSERKER_SKILL3: " + ("FAILED" if failed else "PASS"))
	quit(1 if failed else 0)
