extends SceneTree

const SCOPE := preload("res://src/systems/account_save_scope.gd")
var failed := false
var events: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("REVEAL_TEST: " + message)

func capture(filename: String) -> void:
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://" + filename)

func run() -> void:
	root.size = Vector2i(540, 960)
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.get_node("LoginGateway").remember_session_enabled = false
	root.get_node("LocalTestMode").active = false
	var folder := "user://reveal_test_" + Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(folder)
	SCOPE.guest_directory = folder
	SCOPE.select_guest()
	var warmup = root.get_node("PresentationWarmup")
	await warmup.prepare_common()
	await warmup.prepare_scene("res://src/main/Main.tscn")
	check(warmup.get_texture("res://assets/art/UI/hero_reveal_v2/reveal_chamber.png") != null, "background warmed before battle")
	check(warmup.get_texture("res://assets/art/UI/talk_light_only_30_frames/effect_01.png") == null, "obsolete 30 PNGs no longer loaded")
	var screen = load("res://src/ui/HeroRevealCutscene.tscn").instantiate()
	root.add_child(screen)
	screen.bgm_start_requested.connect(func(_stage: String) -> void: events.append("bgm"))
	screen.finished.connect(func() -> void: events.append("finished"))
	check(screen.effect_frame is ColorRect, "resolution-independent magic geometry")
	check(screen.title_panel.get_theme_stylebox("panel").get_border_width_min() == 0, "no nested common frame")
	for number in [1, 10]:
		var stage := preload("res://src/data/stage_catalog.gd").get_stage("stage_%d" % number)
		var data := preload("res://src/data/hero_reveal_catalog.gd").get_reveal_data(
			String(stage.get("hero_id")), String(preload("res://src/data/hero_profiles.gd").get_profile(String(stage.get("hero_id"))).get("display_name", "용사")), String(stage.get("portrait_path")))
		data["stage_id"] = "stage_%d" % number
		data["true_name_unlocked"] = number == 10
		await screen.warm_render_resources(String(data["portrait_path"]))
		var loads_before: int = warmup.texture_load_count
		screen.play_reveal(data)
		screen.play_reveal(data) # repeated call must not overlap the sequence
		check(screen._active, "sequence starts")
		check(not screen.loading_progress.visible and screen.loading_progress.value == 0, "loading resets")
		var started := Time.get_ticks_msec()
		var magic_captured := false
		var name_captured := false
		while screen._active and Time.get_ticks_msec() - started < 15000:
			await process_frame
			if not magic_captured and Time.get_ticks_msec() - started >= 650:
				magic_captured = true
				await capture("hero-reveal-stage-%d-magic.png" % number)
			if not name_captured and screen.loading_progress.visible:
				name_captured = true
				await capture("hero-reveal-stage-%d-ready.png" % number)
				check(screen.hero_portrait.material.get_shader_parameter("silhouette_strength") <= 0.01, "portrait fully revealed")
				check(screen.title_label.modulate.a >= 0.99, "name shown before preparation")
		check(not screen._active and not screen.visible, "sequence completes and hides")
		check(magic_captured and name_captured, "both reveal and preparation reached")
		check(warmup.texture_load_count == loads_before, "no destination texture loads during reveal")
		check(screen.true_name_label.text == ("진명 : 아스트라" if number == 10 else "진명 : ???"), "identity rules preserved")
		check(events == ["bgm", "finished"], "BGM starts once before completion")
		events.clear()
	screen.queue_free()
	await process_frame
	print("REVEAL_TEST: " + ("FAILED" if failed else "OK"))
	quit(1 if failed else 0)
