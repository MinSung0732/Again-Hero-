extends SceneTree
const S := preload("res://src/systems/account_save_scope.gd")
const P := preload("res://src/systems/stage_progress.gd")
const C := preload("res://src/data/campaign_experience_catalog.gd")
var failures := 0
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("CAMPAIGN_HUD: "+label)
func fits(label: Label) -> bool:
	return label.get_theme_font("font").get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,label.get_theme_font_size("font_size")).x <= label.size.x
func capture(name: String) -> void:
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://campaign-"+name+".png")
func run() -> void:
	root.get_node("CloudStore").stop(); root.get_node("LoginGateway").remember_session_enabled = false
	S.select_guest(); S.guest_directory = "user://campaign_hud_"+str(Time.get_ticks_usec()); DirAccess.make_dir_recursive_absolute(S.guest_directory)
	var mode := root.get_node("LocalTestMode"); mode.active = false; mode.tutorial_preview = false
	await root.get_node("PresentationWarmup").prepare_scene("res://src/main/Main.tscn")
	var main = load("res://src/main/Main.tscn").instantiate(); main.gameplay_settings_path = S.guest_directory.path_join("options.cfg"); root.add_child(main); current_scene = main
	var deadline := Time.get_ticks_msec()+20000
	while not main._presentation_ready and Time.get_ticks_msec() < deadline: await process_frame
	main.stage_intro_cutscene._finish(true); await process_frame; await process_frame
	main.hero_reveal_cutscene._active = false; main.hero_reveal_cutscene.hide(); main.hud_layer.show(); main.battle.set_external_pause(true)
	check(main.battle_loadout_ids == ["slime","spider","orc"],"actual Main starter trio")
	check(is_instance_valid(main._insight_view) and main._insight_view.visible,"real Main installs insight")
	check(main._insight_view.get_rect().position.y >= 337 and main._insight_view.get_rect().end.y <= 420,"insight uses gap above battlefield")
	for hint in C.COUNTERS.values():
		main._insight_view.update_copy("용사 선택 · 민첩한 발놀림  › 상세",hint); await process_frame
		check(fits(main._insight_view.title) and fits(main._insight_view.advice),"real font copy fits:"+hint)
	main._on_hero_augment_selected(2,[],"민첩한 발놀림","","")
	check(main._insight_view.title.text.contains("민첩한 발놀림") and main._insight_view.advice.text.contains("자동 배치"),"choice is visible in actual Main")
	main.settings_battle_frame.button_pressed = false; await process_frame
	check(not main._insight_view.get_global_rect().intersects(main.hero_skill_cooldown_bar.get_global_rect()),"frame-off cooldown/insight separated")
	check(main.battle_viewport_container.offset_top >= main._insight_view.get_rect().end.y,"frame-off board below insight")
	main.settings_battle_frame.button_pressed = true; await process_frame
	await capture("insight")
	main.battle.battle_over = true
	main._on_battle_finished("Stage 1 클리어!\n군단 해금 · 폭탄쥐\n팀편성에서 바로 사용할 수 있습니다.\n최초 클리어 골드 +1000",true); await process_frame; await process_frame
	check(main.result_reward.text.contains("군단 해금") and main.stage_select_result_button.text == "새 군단 편성","reward+formationCTA")
	check(main.result_analysis.text.contains("폭탄쥐") and not main._insight_view.visible,"next experiment in result and coach hidden")
	await capture("result")
	main.free(); current_scene = null
	P.complete_stage("stage_1",1,"stage_2",2,300)
	set_meta("campaign_team_return","stage_2")
	await root.get_node("PresentationWarmup").prepare_scene("res://src/lobby/Lobby.tscn")
	var lobby = load("res://src/lobby/Lobby.tscn").instantiate(); root.add_child(lobby); current_scene = lobby; await lobby.prepare_presentation(); await process_frame; await process_frame
	check(not has_meta("campaign_team_return") and lobby.selected_stage_index == 1,"formation navigation consumed once and selects unlocked next stage")
	check(lobby.team_tab.visible and "bomb_rat" in lobby.team_available_ids,"new monster visible in actual formation")
	check(lobby.team_selected_ids.size() == 3,"existing loadout preserved")
	await capture("formation")
	lobby.queue_free(); await process_frame; await process_frame
	print("CAMPAIGN_HUD_SMOKE checks=",checks," failures=",failures)
	quit(1 if failures else 0)
