extends SceneTree

var failed := false
func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("FAIL: " + message)

func run() -> void:
	var main = load("res://src/main/Main.tscn").instantiate()
	root.add_child(main)
	var presenter = main.result_presenter
	for won in [true, false]:
		presenter.show_result(won, "결과", "", "전투 연구 +187\n최초 클리어 골드 +1000\n군단 보상 · 조각 +10", "전투 시간: 00:00 / 목표 03:00\n처치: 12\n도움말")
		await process_frame
		check(presenter.banner.texture != null and presenter.PNG_SOURCE.path(presenter.banner.texture).ends_with("victory_banner.png" if won else "defeat_banner.png"), "banner")
		check(presenter.cards.size() == 3 and presenter.cards[1].find_child("First", true, false).visible, "reward cards and first")
		check(presenter.rows.size() == 4 and presenter.tip.text == "도움말", "analysis rows")
		check(presenter.rows[1].text == "00:00 / 목표 03:00", "time value keeps colons")
		var formatted := preload("res://src/ui/battle_result_copy.gd").format_analysis("Run 00:00 / 목표 03:00", "")
		presenter.set_analysis(formatted, "팁: 다음 전투")
		check(presenter.rows[0].text == "전투 시간" and presenter.rows[1].text == "00:00 / 목표 03:00" and presenter.tip.text == "팁: 다음 전투", "formatted time and separate tip")
		var tap := InputEventMouseButton.new()
		tap.pressed = true
		presenter._on_panel_input(tap)
		check(presenter.banner.modulate.a == 1.0 and presenter.cards[2].modulate.a == 1.0, "skip animation")
	check(main.restart_button.pressed.is_connected(main._on_restart_pressed) and main.stage_select_result_button.pressed.is_connected(main._on_result_formation_pressed) and main.next_stage_button.pressed.is_connected(main._on_next_stage_pressed), "button signals")
	for dimensions in [Vector2i(1080, 1920), Vector2i(1080, 2400)]:
		root.size = dimensions
		main.result_panel.show()
		await process_frame
		check(main.result_panel.get_global_rect().end.y <= dimensions.y, "panel bounds")
	main.queue_free()
	print("FAIL" if failed else "PASS: demon result screen")
	quit(1 if failed else 0)
