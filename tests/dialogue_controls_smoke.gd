extends SceneTree

const CATALOG := preload("res://src/data/stage_intro_dialogues.gd")
var failed := false
var completions := 0
var events := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("DIALOGUE_TEST: " + message)

func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	var view = load("res://src/ui/StageIntroCutscene.tscn").instantiate()
	root.add_child(view)
	view.finished.connect(func(_skipped: bool): completions += 1)
	view.dialogue_event.connect(func(_id: String, _payload: Dictionary): events += 1)
	view.auto_enabled = false
	for stage in range(1, 11):
		view.play_dialogue(CATALOG.get_dialogue("stage_%d" % stage))
		view.set_process(false)
		await process_frame
		view.set_process(false)
		check(view.skip_button.visible and not view.skip_button.disabled, "first-time skip stage %d" % stage)
		check(view._typing and view.dialogue_text.visible_characters == 0, "starts typing stage %d" % stage)
		view._on_skip_pressed()
	check(completions == 10 and not view.is_processing(), "skip finishes once and stops typing")
	check(events == 1, "stage 10 skip applies only the marked true-name milestone")
	events = 0
	var dialogue := {"hero_name": "용사", "lines": [
		{"speaker": "hero", "text": "가나다… 기다려!"},
		{"speaker": "demon", "text": "둘째 대사", "event": "test_event"},
	]}
	view.play_dialogue(dialogue)
	view.set_process(false)
	await process_frame
	view.set_process(false)
	view._process(0.04)
	check(view.dialogue_text.visible_characters == 1, "Korean one character at a time")
	check(view._character_delay("…") > view._character_delay("가"), "punctuation pause")
	view._last_advance_msec = -1000000
	view._request_advance()
	check(view._line_index == 0 and not view._typing and view.dialogue_text.visible_characters == -1, "tap completes text without advancing")
	view._process(20.0)
	check(view._line_index == 0 and view._active, "manual mode holds indefinitely")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = root.get_final_transform() * view.auto_button.get_global_rect().get_center()
	click.pressed = true
	Input.parse_input_event(click)
	await process_frame
	var release := click.duplicate() as InputEventMouseButton
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame
	check(view._line_index == 0 and view.auto_enabled, "actual AUTO click toggles without advancing dialogue")
	view._process(0.1)
	check(view._line_index == 0, "auto grants reading hold")
	view._process(2.0)
	check(view._line_index == 1 and view._typing and events == 1, "auto advances once and emits event once")
	view.auto_button.button_pressed = false
	view._process(10.0)
	view._process(20.0)
	check(view._line_index == 1 and not view._typing and view._active, "turning auto off holds completed line")
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		view.auto_button.button_pressed = true
		await create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://dialogue-controls-preview.png")
	view.auto_button.button_pressed = true
	view._process(2.0)
	check(not view._active and completions == 11, "last auto line finishes once")
	view._process(10.0)
	check(completions == 11, "no delayed duplicate finish")
	view.play_dialogue(dialogue)
	await process_frame
	view.set_process(false)
	check(view.auto_button.button_pressed, "auto preference retained across dialogues")
	view._on_skip_pressed()
	view._process(10.0)
	check(completions == 12 and not view._active, "skip cancels auto/typing")
	events = 0
	view.play_dialogue({"lines": [
		{"text": "공개", "event": "test_event", "apply_on_skip": true},
		{"text": "일반 이벤트", "event": "unmarked_event"},
	]})
	await process_frame
	view.set_process(false)
	check(events == 1, "visited milestone fires once")
	view._on_skip_pressed()
	view._on_skip_pressed()
	check(events == 1, "skip does not replay visited milestone or grant unmarked events")
	view.free()
	print("DIALOGUE_CONTROLS_FAILED" if failed else "DIALOGUE_CONTROLS_OK")
	quit(1 if failed else 0)
