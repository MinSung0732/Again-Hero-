extends RefCounted
## Reflow only on viewport/slot resize, never from the combat update loop.
const BASE_WIDTH := 1080.0
var host
var viewport: Viewport
var controls: Array[Control] = []
var base_rects: Array[Rect2] = []

static func horizontal_rect(rect: Rect2, width: float) -> Rect2:
	var ratio := maxf(width,1.0)/BASE_WIDTH
	return Rect2(rect.position.x*ratio,rect.position.y,rect.size.x*ratio,rect.size.y)

func install(main: Control) -> void:
	host = main
	viewport = main.get_viewport()
	for path in ["HUD/TopBar","HUD/DemonUltimatePanel","HUD/BottomBar"]:
		for child in main.get_node(path).get_children():
			if child is Control and is_zero_approx(child.anchor_left) and is_zero_approx(child.anchor_right):
				controls.append(child)
				base_rects.append(child.get_rect())
	for slot in [main.summon_slot_1,main.summon_slot_2,main.summon_slot_3]:
		slot.custom_minimum_size.x = 0
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var children: Array[Control] = []
		var rects: Array[Rect2] = []
		for name in ["Icon","Name","Cost"]:
			var child := slot.get_node(name) as Control
			children.append(child); rects.append(child.get_rect())
		slot.resized.connect(_resize_slot.bind(slot,children,rects))
		_resize_slot(slot,children,rects)
	var backdrop := main.get_node("ScreenBackground/TopHUDBackdrop") as Control
	backdrop.anchor_right = 1.0
	backdrop.offset_right = 0.0
	viewport.size_changed.connect(refresh)
	main.tree_exiting.connect(detach,CONNECT_ONE_SHOT)
	refresh()

func _resize_slot(slot: Control, children: Array[Control], rects: Array[Rect2]) -> void:
	# Design cards are 332px wide; keep icon aspect and touch height unchanged.
	var ratio := maxf(slot.size.x,1.0)/332.0
	for index in children.size():
		var rect := rects[index]
		children[index].position = Vector2(rect.position.x*ratio,rect.position.y)
		children[index].size = Vector2(rect.size.x*ratio,rect.size.y)

func refresh() -> void:
	if not is_instance_valid(host) or not host.is_inside_tree(): return
	var width := viewport.get_visible_rect().size.x
	for index in controls.size():
		var rect := horizontal_rect(base_rects[index],width)
		controls[index].position = rect.position
		controls[index].size = rect.size
	var cooldown := host.get_node("HUD/HeroSkillCooldownBar") as Control
	cooldown.position.x = (130.0 if host.battle_frame_enabled else 30.0)*width/BASE_WIDTH
	cooldown.size.x = 470.0*width/BASE_WIDTH
	host._sync_skill_unlock_cutscene_frame()

func detach() -> void:
	if is_instance_valid(viewport) and viewport.size_changed.is_connected(refresh):
		viewport.size_changed.disconnect(refresh)
	host = null
