extends SceneTree

const SCOPE := preload("res://src/systems/account_save_scope.gd")
var failed := false


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("FORMATION_TOUCH: " + message)


func touch(index: int, position: Vector2, pressed: bool, canceled := false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	event.canceled = canceled
	root.push_input(event, true)


func drag(index: int, position: Vector2, relative: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position
	event.relative = relative
	root.push_input(event, true)


func mouse(position: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	root.push_input(event, true)


func run() -> void:
	root.size = Vector2i(1080, 1920)
	root.get_node("LoginGateway").remember_session_enabled = false
	SCOPE.guest_directory = "user://formation_touch_" + Crypto.new().generate_random_bytes(16).hex_encode()
	SCOPE.select_guest()
	var lobby = load("res://src/lobby/Lobby.tscn").instantiate()
	root.add_child(lobby)
	current_scene = lobby
	lobby._show_formation_mode("team")
	for i in range(8):
		await process_frame
	lobby._open_monster_detail("succubus")
	for i in range(8):
		await process_frame
	var detail: ScrollContainer = lobby.get_node("MonsterDetailOverlay/Panel/Margin/VBox/DetailScroll")
	var list: ScrollContainer = lobby.get_node("SafeArea/Layout/Content/TeamTab/TeamLayout/MonsterScroll")
	var initial_list := list.scroll_vertical
	var point := detail.get_global_rect().position + Vector2(120, 320)
	touch(2, point, true)
	for i in range(4):
		drag(2, point, Vector2(0, -0.25))
	check(detail.scroll_vertical == 0, "sub-deadzone jitter does not begin scrolling")
	drag(2, point - Vector2(0, 16), Vector2(0, -16))
	var after_deadzone := detail.scroll_vertical
	for i in range(4):
		drag(2, point - Vector2(0, 17), Vector2(0, -0.25))
	check(detail.scroll_vertical == after_deadzone + 1, "fractional touch motion is accumulated after swipe begins")
	drag(2, point - Vector2(0, 160), Vector2(0, -160))
	check(detail.scroll_vertical > 0, "raw touch scrolls popup")
	check(list.scroll_vertical == initial_list, "popup touch leaves list stationary")
	var value := detail.scroll_vertical
	drag(3, point, Vector2(0, -100))
	check(detail.scroll_vertical == value, "other finger does not take ownership")
	var motion := InputEventMouseMotion.new()
	motion.device = InputEvent.DEVICE_ID_EMULATION
	motion.position = point
	motion.relative = Vector2(0, -160)
	root.push_input(motion, true)
	check(detail.scroll_vertical == value, "emulated mouse does not scroll twice")
	touch(2, point, false, true)
	check(lobby._detail_scroll_touch_index == -1, "canceled touch releases ownership")
	lobby._close_monster_detail()
	lobby._open_monster_detail("succubus")
	check(detail.scroll_vertical == 0, "reopen starts at top")
	var close: Button = lobby.monster_detail_close_button
	mouse(close.get_global_rect().get_center(), true)
	mouse(close.get_global_rect().get_center(), false)
	check(not lobby.monster_detail_overlay.visible, "close button stays interactive")
	lobby._open_monster_detail("succubus")
	touch(4, Vector2(10, 10), true)
	check(not lobby.monster_detail_overlay.visible, "outside touch closes popup")
	touch(4, Vector2(10, 10), false)
	# Standalone real viewport drag under an overflowing scroll container.
	var container := ScrollContainer.new()
	container.position = Vector2(50, 50)
	container.size = Vector2(400, 400)
	root.add_child(container)
	var column := VBoxContainer.new()
	container.add_child(column)
	var card = load("res://src/ui/formation_drag_card.gd").new()
	card.custom_minimum_size = Vector2(350, 300)
	card.configure_drag("monster", "slime", "Slime")
	column.add_child(card)
	var filler := Control.new()
	filler.custom_minimum_size = Vector2(350, 1000)
	column.add_child(filler)
	lobby.hide()
	for i in range(4):
		await process_frame
	container.scroll_vertical = 50
	var saved_filter := container.mouse_filter
	var press := InputEventMouseButton.new()
	press.position = Vector2(100, 100)
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	card._gui_input(press)
	card._process(0.30)
	check(root.gui_is_dragging(), "long hold starts real formation drag")
	check(container.mouse_filter == Control.MOUSE_FILTER_IGNORE, "drag locks background list")
	container.get_v_scroll_bar().value += 100
	check(container.scroll_vertical == 50, "edge hover/inertia cannot move locked list")
	var move := InputEventMouseMotion.new()
	move.position = container.get_global_rect().get_center()
	move.relative = Vector2(0, -180)
	move.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(move, true)
	await process_frame
	check(container.scroll_vertical == 50, "moving preview does not scroll list")
	mouse(Vector2(800, 1700), false)
	await process_frame
	check(not root.gui_is_dragging(), "release cancels outside drop")
	check(container.mouse_filter == saved_filter, "scroll restored after drag")
	container.scroll_vertical = 100
	check(container.scroll_vertical == 100, "list scrolls again after drag")
	card._gui_input(press)
	card.notification(Control.NOTIFICATION_SCROLL_BEGIN)
	check(not card._hold_active, "ordinary swipe cancels long hold")
	var slot = load("res://src/ui/formation_drop_slot.gd").new()
	slot.position = Vector2(550, 50)
	slot.size = Vector2(300, 300)
	root.add_child(slot)
	var dropped: Array = []
	slot.formation_item_dropped.connect(func(index, kind, id): dropped.append([index, kind, id]))
	card._gui_input(press)
	card._process(0.30)
	move.position = slot.get_global_rect().get_center()
	move.relative = Vector2(500, 0)
	root.push_input(move, true)
	await process_frame
	mouse(slot.get_global_rect().get_center(), false)
	await process_frame
	check(dropped.size() == 1 and dropped[0][1] == "monster" and dropped[0][2] == "slime", "drop still equips correct monster payload")
	check(container.mouse_filter == saved_filter, "successful drop restores scrolling")
	slot.free()
	container.free()
	lobby.free()
	print("FORMATION_TOUCH: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
