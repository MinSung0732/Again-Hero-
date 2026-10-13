extends SceneTree

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const STAMINA := preload("res://src/systems/stamina_store.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("HERO_STARTUP: " + message)

func run() -> void:
	root.get_node("CloudStore").stop()
	root.get_node("LoginGateway").remember_session_enabled = false
	SCOPE.select_guest()
	SCOPE.guest_directory = "user://hero_startup_smoke_" + str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	var progress := ConfigFile.new()
	progress.set_value("progress", "highest_unlocked_stage", 10)
	progress.set_value("cleared", "stage_10", true)
	check(SCOPE.save_config(progress, "user://stage_progress.cfg") == OK, "isolated fixture")
	var pad_script: Script = load("res://src/hero_mode/hero_move_pad.gd")
	check(pad_script != null and pad_script.can_instantiate(), "pad compiles without native method collision")
	if pad_script == null or not pad_script.can_instantiate():
		quit(1)
		return
	var ticket := STAMINA.try_enter("stage_1", true)
	check(bool(ticket.get("success", false)), "entry receipt created")
	root.get_node("SceneTransition").set("_entry_options", {"stage_id":"stage_1", "hero_entry":ticket})
	var scene = load("res://src/hero_mode/HeroMode.tscn").instantiate()
	root.add_child(scene)
	check(is_instance_valid(scene.pad) and is_instance_valid(scene.build) and is_instance_valid(scene.overlay), "all UI creation completes")
	check(is_instance_valid(scene.battle) and scene.director != null, "battle and director initialize")
	if not is_instance_valid(scene.battle) or scene.director == null:
		quit(1)
		return
	check(scene.battle.run_time_limit_seconds == 900.0 and scene.battle.hero.player_weapons != null, "15 minute weapon survival configured")
	check(scene.get_node("HeroHUD") != null and scene.weapon_buttons.size() == 3, "top HUD weapon slots")
	check(scene.is_processing() and scene.battle.hero.player_controlled, "player simulation starts after setup")
	var background := scene.get_node("HeroBackground") as ColorRect
	var view := scene.get_node("BattleView") as SubViewportContainer
	check(background.get_index() < view.get_index(), "opaque background behind battle viewport")
	check(view.get_index() < scene.pad.get_index(), "pad above battle viewport")
	await process_frame
	check(view.size.x > 0 and view.size.y > 0 and scene.pad.is_visible_in_tree(), "viewport and pad have usable layout")
	var pad_position: Vector2 = scene.pad.position
	scene.pad.set_position(pad_position + Vector2(10, 0))
	check(scene.pad.position == pad_position + Vector2(10, 0), "native Control position setter still works")
	scene.pad._update_direction(scene.pad.size * 0.5 + Vector2(105, 0))
	check(scene.pad.direction.x > 0.9 and scene.battle.hero.player_move_input.x > 0.9, "pad emits hero movement")
	scene.pad.reset()
	check(scene.battle.hero.player_move_input == Vector2.ZERO, "release stops movement")
	var elapsed: float = scene.battle.run_metrics.elapsed_seconds
	await create_timer(1.5).timeout
	check(scene.battle.run_metrics.elapsed_seconds > elapsed, "battle clock advances")
	check(scene.battle.get_population_count() > 0, "AI demon sends first monsters")
	check(not scene.hp.max_value <= 0 and not scene.status.text.is_empty(), "HUD updated")
	scene._queue_chest()
	scene._begin_roulette()
	check(scene.rolling and scene.battle.external_pause, "chest pauses combat for roulette")
	await create_timer(2.7).timeout
	check(bool(scene.roulette_receipt.get("applied",false)), "roulette applies one weapon reward")
	scene._close_roulette()
	check(not scene.rolling and not scene.battle.external_pause, "roulette resumes combat")
	scene._pause()
	check(scene.paused and scene.battle.external_pause, "pause works")
	scene._resume()
	check(not scene.paused and not scene.battle.external_pause, "resume works")
	check(not scene.battle.hero.follow_camera.top_level, "hero camera stays fixed")
	var refunded := STAMINA.refund_early_exit(scene.entry, 2000)
	check(bool(refunded.get("success", false)), "early exit refund uses claimed entry")
	scene.queue_free()
	await process_frame
	print("HERO_MODE_STARTUP_SMOKE checks=", checks, " failures=", failures)
	quit(1 if failures else 0)
