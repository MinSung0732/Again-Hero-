extends SceneTree
const PROLOGUE := preload("res://src/ui/player_prologue.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
var failed := false

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failed = true
		push_error("PROLOGUE_KEYBOARD: " + message)

func settle() -> void:
	await process_frame
	await process_frame
	await process_frame

func run() -> void:
	root.size = Vector2i(540, 960)
	root.content_scale_size = Vector2i(1080, 1920)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.get_node("CloudStore").stop()
	root.get_node("LoginGateway").remember_session_enabled = false
	root.get_node("LocalTestMode").active = false
	var hex := Crypto.new().generate_random_bytes(16).hex_encode()
	var id := "%s-%s-%s-%s-%s" % [hex.substr(0,8),hex.substr(8,4),hex.substr(12,4),hex.substr(16,4),hex.substr(20,12)]
	check(SCOPE.select_account(id), "isolated fixture")
	var view := PROLOGUE.new()
	root.add_child(view)
	await settle()
	view.index = 28
	view._show_line()
	view.set_process(false)
	view.name_input.text = "달빛마왕7"
	view._validate_name(view.name_input.text)
	var input := view.name_input
	var button := view.confirm
	# Equal device proportions with different physical pixel densities.
	for scale_y in [0.5, 1.0, 1.5]:
		for keyboard_fraction in [0.30, 0.50, 0.65]:
			var available := PROLOGUE.keyboard_available_height(1920, 0, scale_y, 1920 * scale_y, 1920 * scale_y * keyboard_fraction)
			check(is_equal_approx(available, 1920 * (1.0 - keyboard_fraction)), "physical pixels converted to canvas")
			view._apply_name_layout(available, true)
			await settle()
			check(view.choice.get_rect().end.y <= available + 1, "modal above keyboard")
			check(view._name_scroll.get_global_rect().encloses(input.get_global_rect()), "input fully visible")
			check(view._name_scroll.get_global_rect().encloses(button.get_global_rect()), "confirm fully visible")
	# OS already resized the canvas: the same inset is applied only once.
	check(is_equal_approx(PROLOGUE.keyboard_available_height(960, 0, 0.5, 960, 480), 960), "no double subtraction after OS resize")
	check(is_equal_approx(PROLOGUE.keyboard_available_height(1920, 40, 0.5, 1000, 480), 960), "screen top inset")
	# An unusually tall keyboard leaves a scrollable form instead of tiny text.
	view._apply_name_layout(260, true)
	await settle()
	check(view.choice.get_rect().end.y <= 261, "short visible area bounds")
	view._name_scroll.ensure_control_visible(button)
	await settle()
	check(view._name_scroll.scroll_vertical > 0, "short viewport can scroll")
	check(view._name_scroll.get_global_rect().grow(1).encloses(button.get_global_rect()), "confirm reachable by scrolling")
	check(input == view.name_input and button == view.confirm and input.text == "달빛마왕7" and not button.disabled, "layout preserves input and validation")
	view._apply_name_layout(1920, false)
	await settle()
	check(view.choice.get_rect().is_equal_approx(Rect2(108, 825.6, 864, 537.6)), "keyboard close restores original modal")
	check(view._name_scroll.get_global_rect().grow(1).encloses(button.get_global_rect()), "confirm remains visible after keyboard closes")
	view._close_choice()
	check(view._name_scroll == null, "closed form stops keyboard polling")
	view.queue_free()
	await settle()
	SCOPE.select_guest()
	print("PLAYER_PROLOGUE_KEYBOARD_SMOKE_" + ("FAILED" if failed else "OK"))
	quit(1 if failed else 0)
