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
	progress.set_value("progress", "highest_unlocked_stage", 1)
	progress.set_value("progress", "current_stage_id", "stage_1")
	# Hero mode opens after demon easy stage 3 (2026-10-14 unlock rules).
	for stage_id in ["stage_1","stage_2","stage_3"]: progress.set_value("cleared", stage_id, true)
	check(SCOPE.save_config(progress, "user://stage_progress.cfg") == OK, "isolated fixture")
	var hero_progress := ConfigFile.new()
	# Battlefields unlock through contiguous hero easy wins (2026-10-15).
	for number in range(1,10): hero_progress.set_value("hero_progress","stage_%d_easy_wins" % number,1)
	check(SCOPE.save_config(hero_progress,"user://team_loadout.cfg") == OK,"prior hero stage clears, independent of campaign")
	var pad_script: Script = load("res://src/hero_mode/hero_move_pad.gd")
	check(pad_script != null and pad_script.can_instantiate(), "pad compiles without native method collision")
	if pad_script == null or not pad_script.can_instantiate():
		quit(1)
		return
	var ticket := STAMINA.try_enter("stage_10", true,-1,false)
	check(bool(ticket.get("success", false)), "entry receipt created")
	root.get_node("SceneTransition").set("_entry_options", {"stage_id":"stage_10","hero_id":"ranged_rookie", "hero_entry":ticket})
	var scene = load("res://src/hero_mode/HeroMode.tscn").instantiate()
	root.add_child(scene)
	# The build Label became the collapsible stats panel (2026-10-14).
	check(is_instance_valid(scene.pad) and is_instance_valid(scene.stats_panel) and is_instance_valid(scene.overlay), "all UI creation completes")
	check(not scene.entry_ready and not scene.is_processing() and not scene.pad.enabled, "loading gates simulation and input")
	var deadline := Time.get_ticks_msec()+45000
	while not scene.entry_ready and Time.get_ticks_msec() < deadline:
		await process_frame
	check(scene.presentation_ready and scene.entry_ready, "warmup completes before entry")
	check(is_instance_valid(scene.battle) and scene.director != null, "battle and director initialize")
	if not is_instance_valid(scene.battle) or scene.director == null:
		quit(1)
		return
	check(scene.battle.run_time_limit_seconds == 900.0 and scene.battle.hero.player_weapons != null, "15 minute weapon survival configured")
	var equipped = scene.battle.hero.player_weapons
	check(equipped != null and equipped.weapon_ids.size() >= 1, "starter equipped before gameplay opens")
	if equipped != null and not equipped.weapon_ids.is_empty():
		check(String(equipped.weapon_ids[0]) == "ranged_rookie_arcane_bolt" and int(equipped.levels.get("ranged_rookie_arcane_bolt",0)) == 1, "apprentice starter receives level one")
		check(equipped.ensure_starting_weapon() and equipped.weapon_ids.size() == 1, "rechecking starter does not duplicate inventory")
	check(scene.get_node("HeroHUD") != null and scene.weapon_buttons.size() == 6, "top HUD weapon slots")
	check(scene.battle.current_stage_id == "stage_10" and String(scene.battle.current_hero_profile.id) == "ranged_rookie", "apprentice plays high-stage map without changing character")
	var saved := ConfigFile.new(); SCOPE.load_config(saved,"user://stage_progress.cfg")
	check(saved.get_value("progress","current_stage_id","") == "stage_1", "hero entry does not change demon campaign selection")
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
	scene.battle.hero.gain_exp(scene.battle.hero.exp_to_next_level*4)
	await create_timer(0.3).timeout
	var cards := scene.overlay_rows.get_node("HorizontalAugmentCards") as HBoxContainer
	check(scene.choosing and scene.battle.external_pause and cards.get_child_count() == 3,"three horizontal choices pause combat")
	check(scene.overlay.anchor_left == 0.5 and scene.overlay.anchor_top == 0.5,"choice overlay centered")
	check(scene.get_global_rect().encloses(scene.overlay.get_global_rect()),"choice overlay stays inside the viewport")
	var last_x := -INF
	for card in cards.get_children():
		check(card.position.x > last_x,"choice cards arranged left to right"); last_x = card.position.x
		check(scene.overlay.get_global_rect().encloses(card.get_global_rect()),"each card stays inside the choice overlay")
		var icon := card.find_child("AugmentIcon",true,false) as TextureRect
		check(icon != null and icon.texture != null and icon.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST,"each choice has a pixel icon")
	scene._choose(String(scene.battle.hero.player_augment_candidates[0].id),scene.choice_generation)
	check(not scene.choosing and not scene.battle.external_pause,"choice resumes combat")
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
