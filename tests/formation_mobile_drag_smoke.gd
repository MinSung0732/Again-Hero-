extends SceneTree

const ROUTER := preload("res://src/ui/mobile_scroll_router.gd")
const CARD := preload("res://src/ui/formation_drag_card.gd")
const SLOT := preload("res://src/ui/formation_drop_slot.gd")
var failed := false

class TouchRoot extends Control:
	var router := ROUTER.new()
	func _input(event: InputEvent) -> void:
		if router.handle_input(event,self): get_viewport().set_input_as_handled()

func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	if not ok:
		failed = true
		push_error("FORMATION_MOBILE_DRAG: "+label)
func touch(index: int, point: Vector2, pressed: bool) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = point
	event.pressed = pressed
	return event
func motion(point: Vector2) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.device = InputEvent.DEVICE_ID_EMULATION
	event.position = point
	event.relative = Vector2(0,-140)
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	return event
func release(point: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.device = InputEvent.DEVICE_ID_EMULATION
	event.position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = false
	root.push_input(event,true)
func run() -> void:
	root.get_node("CloudStore").stop()
	root.size = Vector2i(1080,1920)
	var harness := TouchRoot.new()
	harness.size = Vector2(1080,1920)
	root.add_child(harness)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(30,420)
	scroll.size = Vector2(420,500)
	harness.add_child(scroll)
	var column := VBoxContainer.new()
	scroll.add_child(column)
	var card := CARD.new()
	card.custom_minimum_size = Vector2(390,300)
	card.configure_drag("monster","slime","Slime")
	column.add_child(card)
	var filler := Control.new()
	filler.custom_minimum_size = Vector2(390,1500)
	column.add_child(filler)
	var slot := SLOT.new()
	slot.position = Vector2(550,100)
	slot.size = Vector2(300,240)
	harness.add_child(slot)
	var drops: Array = []
	slot.formation_item_dropped.connect(func(index,kind,id): drops.append([index,kind,id]))
	for i in range(4): await process_frame
	scroll.scroll_vertical = 80
	var original_filter := scroll.mouse_filter
	var point := card.get_global_rect().get_center()
	# Acquire the actual scroll router before the card's hold finishes.
	root.push_input(touch(0,point,true),true)
	check(harness.router._touch_index==0,"router initially owns the finger")
	card._gui_input(touch(0,card.size/2,true))
	card._process(0.30)
	check(root.gui_is_dragging(),"real long hold starts native GUI drag")
	check(scroll.mouse_filter==Control.MOUSE_FILTER_IGNORE,"source scroll locked")
	var swipe := InputEventScreenDrag.new()
	swipe.index = 0
	swipe.position = point-Vector2(0,180)
	swipe.relative = Vector2(0,-180)
	root.push_input(swipe,true)
	check(harness.router._touch_index==-1 and not harness.router._dragging,"GUI drag releases cached scroll gesture")
	var move := motion(slot.get_global_rect().get_center())
	check(not harness.router.handle_input(move,harness),"emulated pointer is passed to GUI drag")
	root.push_input(move,true)
	await process_frame
	check(scroll.scroll_vertical==80,"dragging upward preserves list position")
	root.push_input(touch(0,move.position,false),true)
	release(move.position)
	await process_frame
	check(drops.size()==1 and drops[0][1]=="monster" and drops[0][2]=="slime","touch companion drops correct payload into slot")
	check(not root.gui_is_dragging() and scroll.mouse_filter==original_filter,"drop restores native drag and scrolling")
	# The next gesture is a normal scroll, with no stale long-press ownership.
	point = scroll.get_global_rect().get_center()
	root.push_input(touch(1,point,true),true)
	swipe.index = 1
	swipe.position = point-Vector2(0,60)
	swipe.relative = Vector2(0,-60)
	root.push_input(swipe,true)
	check(scroll.scroll_vertical>80 and harness.router._dragging,"next swipe scrolls normally")
	harness.router.reset()
	# A failed drop restores the same scroll lock, without retaining input.
	root.push_input(touch(2,point,true),true)
	card._gui_input(touch(2,card.size/2,true))
	card._process(0.30)
	harness.router.step(1.0/60.0)
	check(harness.router._touch_index==-1,"frame-driven scroll tracking also yields to drag")
	root.push_input(motion(Vector2(950,1700)),true)
	release(Vector2(950,1700))
	await process_frame
	check(drops.size()==1 and scroll.mouse_filter==original_filter,"outside drop cancels and restores scroll")
	# Demon skill cards share the same drag ownership and payload path.
	card.configure_drag("skill","line_assault","Line Assault")
	root.push_input(touch(3,point,true),true)
	card._gui_input(touch(3,card.size/2,true))
	card._process(0.30)
	root.push_input(motion(slot.get_global_rect().get_center()),true)
	release(slot.get_global_rect().get_center())
	await process_frame
	check(drops.size()==2 and drops[1][1]=="skill" and drops[1][2]=="line_assault","demon skill touch drag uses same fix")
	check(scroll.mouse_filter==original_filter,"skill drop restores scrolling")
	harness.free()
	print("FORMATION_MOBILE_DRAG: "+("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
