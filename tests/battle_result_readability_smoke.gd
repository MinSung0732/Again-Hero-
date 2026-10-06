extends SceneTree

const COPY := preload("res://src/ui/battle_result_copy.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const PROGRESS := preload("res://src/systems/stage_progress.gd")
var failed := false

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("RESULT_TEST: " + message)

func capture(name: String) -> void:
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[-1].replace("{result}", name))

func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	var folder := "user://result_test_" + Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(folder)
	SCOPE.guest_directory = folder
	SCOPE.select_guest()
	var main = load("res://src/main/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	var deadline := Time.get_ticks_msec() + 20000
	while not main._presentation_ready and Time.get_ticks_msec() < deadline:
		await process_frame
	main.stage_intro_cutscene._finish(true)
	await process_frame
	main.hero_reveal_cutscene._active = false
	main.hero_reveal_cutscene.hide()
	main.hud_layer.show()
	main.battle.set_external_pause(true)
	main.battle.run_metrics.elapsed_seconds = 173.0
	main.battle.run_metrics.lowest_hero_hp = 65
	main.battle.run_metrics.lowest_hero_hp_ratio = 0.13
	main.battle.run_metrics.total_damage_dealt = 1240
	main.battle.run_metrics.summon_demon_exp = {"slime": 45.0, "spider": 60.0, "banshee": 130.0}
	PROGRESS.complete_stage("stage_1", 1, "stage_2", 2, 0)
	var victory := "Stage 1 클리어!\n첫 번째 침입자 · 견습 마법용사 처치 성공.\n최초 클리어 보상 · 연구 포인트 +100\nRun 연구 +141 · 산정 141 × Stage 1.00\n기본 +50 · 피해 +30 · 마왕Lv +15 · 용사Lv +6 · 소환 +10 · 신속 +24 · 관찰/전환 +6"
	for won in [true, false]:
		var message := victory if won else "시간 초과!\n견습 마법용사가 제한시간을 버텨냈습니다.\nRun 연구 +41\n기본 +10 · 피해 +20 · 마왕Lv +3 · 용사Lv +2 · 소환 +3 · 신속 +0 · 관찰/전환 +3"
		main._on_battle_finished(message, won)
		await process_frame
		await process_frame
		check(main.result_title.text.begins_with("승리" if won else "패배"), "localized result title")
		check(main.result_reward.text.contains("+141" if won else "+41"), "actual granted reward shown")
		check(not main.result_message.text.contains("산정"), "calculation separated from headline")
		check(main.result_analysis.text.contains("◆ 전투 기록") and not main.result_analysis.text.contains("◆ 보상 상세"), "compact battle record")
		for hidden in ["용사 증강", "전략 전환", "마왕 최종", "일반증강", "특수증강", "직접 소환"]:
			check(not main.result_analysis.text.contains(hidden), "hidden result metric " + hidden)
		check(main.result_analysis.get_global_rect().end.y <= main.next_stage_button.get_global_rect().position.y if won else main.result_analysis.get_global_rect().end.y <= main.restart_button.get_global_rect().position.y, "record fits above buttons without scroll")
		check(main.result_panel.get_global_rect().end.y <= 1920 and main.restart_button.get_global_rect().end.y <= main.result_panel.get_global_rect().end.y, "panel/actions stay in screen")
		check(main.restart_button.pressed.is_connected(main._on_restart_pressed) and main.stage_select_result_button.pressed.is_connected(main._on_lobby_pressed), "existing actions connected")
		check(won or not main.next_stage_button.visible, "no next-stage action on defeat")
		check(not won or main.next_stage_button.visible, "unlocked next stage shown on victory")
		await capture("victory" if won else "defeat")
	var failed_reward := COPY.format_message("시간 초과!\nRun 연구 보상 저장 실패")
	check(failed_reward.reward.is_empty() and failed_reward.details.contains("저장 실패"), "failed award never shown as granted")
	var full_summary := "Run 02:53 / 목표 05:00\nHero 최저 HP: 65 (13%)\nHero 누적 HP 피해: 1240\n마왕 EXP 기여: 밴시 130\n" + "직접 소환: 밴시 100\n전략 전환: 밴시→박쥐\nHero 증강 30회\n마왕 최종 Lv.30\n일반증강: 공격력 증가\n특수증강: 은신\n첫 특수증강: 01:30\n".repeat(60)
	var compact := COPY.format_analysis(full_summary, "보상 산정 내역")
	check(compact.split("\n").size() == 6 and compact.contains("누적 HP 피해"), "large builds cannot grow result content")
	check(main.get_node("HUD/ResultPanel/Margin/VBox/ResultAnalysisArea") is MarginContainer, "result contains no scrolling area")
	main.free()
	for file in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(file))
	DirAccess.remove_absolute(folder)
	SCOPE.guest_directory = "user://"
	print("BATTLE_RESULT_READABILITY_FAILED" if failed else "BATTLE_RESULT_READABILITY_OK")
	quit(1 if failed else 0)
