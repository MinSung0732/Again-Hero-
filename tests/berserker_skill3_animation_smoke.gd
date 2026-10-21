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


# hero.gd forwards these coroutines to the berserker archetype runtime. Awaiting
# the hero method must resume only after the whole skill finished (2026-10-20:
# forwarders without `await` returned immediately). Wall-clock vs game-time
# frame jitter gets a 10% margin.
func check_coroutine_forwarders(battle: Node, hero: Node) -> void:
	var layer: int = hero.collision_layer
	var mask: int = hero.collision_mask
	var skill3: Dictionary = hero.berserker_config["skill_3"]
	hero.position = Vector2(700, 1000)
	var destination: Vector2 = hero.global_position + Vector2.RIGHT * float(skill3["dash_distance"])
	var monster = battle._spawn_monster("slime", destination + Vector2(0, 80))
	monster.set_physics_process(false)
	hero.velocity = Vector2.ZERO
	hero.hit_pose_timer = 0.0
	hero.berserker_skill3_active = true
	hero.attack_pose_timer = 1.55
	var started := Time.get_ticks_msec()
	await hero._execute_berserker_skill3(Vector2.RIGHT, skill3)
	var elapsed := float(Time.get_ticks_msec() - started) / 1000.0
	check(not hero.berserker_skill3_active and hero.attack_pose_timer == 0.0, "awaited skill3 forwarder resumes after recovery")
	check(elapsed >= 0.9 * (float(skill3["dash_duration"]) + float(skill3["orb_pickup_duration"])), "awaited skill3 covers dash and orb pickup (%.2fs)" % elapsed)
	check(hero.global_position.is_equal_approx(destination), "skill3 dash reaches destination")
	check(hero.collision_layer == layer and hero.collision_mask == mask, "skill3 forwarder restores collision")
	check(hero.hero_sprite.animation == &"idle", "skill3 forwarder ends in idle")
	if is_instance_valid(monster):
		monster.free()

	var skill2: Dictionary = hero.berserker_config["skill_2"]
	started = Time.get_ticks_msec()
	await hero._run_berserker_skill2_wave(hero.global_position, Vector2.UP, skill2)
	elapsed = float(Time.get_ticks_msec() - started) / 1000.0
	check(elapsed >= 0.9 * float(skill2["blood_duration"]), "awaited skill2 wave covers blood duration (%.2fs)" % elapsed)

	hero.berserker_revive_used = false
	hero.berserker_reviving = false
	hero.current_hp = 1
	started = Time.get_ticks_msec()
	await hero._begin_berserker_revive()
	elapsed = float(Time.get_ticks_msec() - started) / 1000.0
	check(elapsed >= 0.9 * float(hero.berserker_config["revive_delay"]), "awaited revive covers revive delay (%.2fs)" % elapsed)
	check(not hero.berserker_reviving and hero.berserker_revive_used, "revive forwarder resumes after revive")
	check(hero.current_hp == maxi(int(round(float(hero.max_hp) * float(hero.berserker_config["revive_hp_ratio"]))), 1), "revive restores HP ratio")
	check(hero.collision_layer == layer and hero.collision_mask == mask, "revive restores collision")
	check(hero.hero_sprite.animation == &"idle", "revive ends in idle")
	hero.current_hp = hero.max_hp


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
		# Wait for the dash tween itself, not wall-clock time: the first cast loads
		# audio/trail resources and that hitch frame can outrun a fixed timer.
		for frame in range(120):
			if hero.collision_layer == layer:
				break
			await process_frame
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
	await check_coroutine_forwarders(battle, hero)
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
