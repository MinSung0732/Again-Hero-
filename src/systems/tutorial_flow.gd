extends Node

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const CHECKPOINT := preload("res://src/systems/tutorial_checkpoint.gd")
const SPOTLIGHT := preload("res://src/ui/tutorial_spotlight.gd")
const DATA := preload("res://src/data/tutorial_catalog.gd")
var transport: Node # Isolated tests can inject a fake server.
var account_owner := ""
var status := ""
var pending_exit := false
var modal_visible := false
var busy := false
var host: Node
var coach: RefCounted
var layer: CanvasLayer
var overlay: Control
var title: Label
var copy: Label
var primary: Button
var secondary: Button
var hint: Label
var highlight: Panel
var primary_action := Callable()
var secondary_action := Callable()
var previous_pause := false
var guide_generation := 0
var spotlight: Control
var step := ""

func active() -> bool:
	return account_owner == _owner() and not account_owner.is_empty() and status == "active"

func _owner() -> String:
	var mode := get_node("/root/LocalTestMode")
	return "preview:" + mode.preview_directory if mode.is_tutorial_preview() else SCOPE.user_id

func _rpc(action: String) -> Dictionary:
	var mode := get_node("/root/LocalTestMode")
	if mode.is_tutorial_preview():
		return mode.tutorial_operation(action)
	var cloud: Node = transport if transport != null else get_node("/root/CloudStore")
	return await cloud.tutorial_operation(action)

func bind_host(node: Node) -> void:
	if is_instance_valid(layer):
		layer.queue_free()
	host = node
	modal_visible = false
	coach = null
	spotlight = null
	layer = CanvasLayer.new()
	layer.layer = 150
	node.add_child(layer)
	spotlight = SPOTLIGHT.new()
	layer.add_child(spotlight)
	spotlight.hide()
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.025, 0.012, 0.04, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(800, 0)
	panel.add_theme_stylebox_override("panel", _style(Color("160e24"), Color("eac466"), 4, 30))
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 24)
	panel.add_child(column)
	title = Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("ffdf91"))
	column.add_child(title)
	copy = Label.new()
	copy.custom_minimum_size = Vector2(730, 0)
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_theme_font_size_override("font_size", 27)
	copy.add_theme_color_override("font_color", Color("eee5f5"))
	column.add_child(copy)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 20)
	column.add_child(actions)
	secondary = _button(actions)
	for state in ["normal", "hover", "pressed", "disabled"]:
		secondary.add_theme_stylebox_override(state, _style(Color("44414b") if state == "hover" else Color("34313a"), Color("827e8b"), 2, 16))
	secondary.add_theme_color_override("font_color", Color("c8c4ce"))
	secondary.add_theme_color_override("font_hover_color", Color("e5e1eb"))
	secondary.add_theme_color_override("font_pressed_color", Color("d5d0df"))
	primary = _button(actions)
	primary.pressed.connect(func(): _invoke(primary_action))
	secondary.pressed.connect(func(): _invoke(secondary_action))
	hint = Label.new()
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	hint.offset_left = 80
	hint.offset_right = -80
	hint.offset_top = 410
	hint.offset_bottom = 500
	hint.add_theme_stylebox_override("normal", _style(Color(0.08, 0.035, 0.14, 0.96), Color("d6b258"), 2, 12))
	hint.add_theme_font_size_override("font_size", 25)
	layer.add_child(hint)
	highlight = Panel.new()
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var border := _style(Color.TRANSPARENT, Color("ffe79b"), 4, 0)
	highlight.add_theme_stylebox_override("panel", border)
	layer.add_child(highlight)
	clear_guide()
	node.tree_exiting.connect(func():
		if host == node:
			modal_visible = false
			spotlight = null
			host = null)

func _style(bg: Color, edge: Color, width: int, padding: int) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = bg
	result.border_color = edge
	result.set_border_width_all(width)
	result.set_content_margin_all(padding)
	return result

func _button(parent: Control) -> Button:
	var button := Button.new()
	button.custom_minimum_size.y = 88
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 29)
	button.add_theme_stylebox_override("normal", _style(Color("58247b"), Color("e8bd58"), 3, 16))
	button.add_theme_stylebox_override("hover", _style(Color("77349b"), Color("fff1b2"), 3, 16))
	button.add_theme_stylebox_override("pressed", _style(Color("3d185a"), Color("e8bd58"), 3, 16))
	parent.add_child(button)
	return button

func _invoke(action: Callable) -> void:
	if not busy and action.is_valid():
		action.call()

func show_modal(heading: String, body: String, yes: String, action: Callable, no: String = "", cancel: Callable = Callable()) -> void:
	if not is_instance_valid(host):
		return
	if not modal_visible and host.get("battle") != null:
		previous_pause = host.battle.external_pause
		host.battle.set_external_pause(true)
		host._end_touch_hold()
		host._clear_pending_manual_spawn()
	spotlight.hide()
	modal_visible = true
	guide_generation += 1
	var generation := guide_generation
	title.text = heading
	copy.text = body
	primary.text = yes
	secondary.text = no
	secondary.visible = not no.is_empty()
	primary_action = action
	secondary_action = cancel
	overlay.show()
	hint.hide()
	highlight.hide()
	# Do not accept the release/click that opened a guide.
	primary.disabled = true
	secondary.disabled = true
	await get_tree().create_timer(0.45).timeout
	if generation == guide_generation and is_instance_valid(primary):
		primary.disabled = false
		secondary.disabled = false

func clear_guide() -> void:
	guide_generation += 1
	if is_instance_valid(overlay):
		overlay.hide()
		spotlight.hide()
		hint.hide()
		highlight.hide()
	if modal_visible and is_instance_valid(host) and host.get("battle") != null:
		host.battle.set_external_pause(previous_pause or host.pause_menu.visible or host.result_panel.visible or host._stage_intro_active)
	modal_visible = false
	if is_instance_valid(host) and host.get("main_modes_view") != null:
		host.main_modes_view.schedule_unlock()

func focus_targets(targets: Array, message: String) -> void:
	clear_guide()
	var visible_targets: Array[Control] = []
	for target in targets:
		if is_instance_valid(target) and target.is_visible_in_tree():
			visible_targets.append(target)
	spotlight.configure(visible_targets)
	spotlight.show()
	hint.text = message
	hint.offset_top = 300
	hint.offset_bottom = 400
	hint.show()

func point_to(target: Control, message: String) -> void:
	focus_targets([target], message)

func blocks_input(event: InputEvent) -> bool:
	if not is_instance_valid(host):
		return false
	if modal_visible:
		if event is InputEventKey or event is InputEventJoypadButton:
			get_viewport().set_input_as_handled()
		return true
	if is_instance_valid(spotlight) and spotlight.visible and spotlight.blocks(event):
		get_viewport().set_input_as_handled()
		return true
	return false

func locks_lobby() -> bool:
	return account_owner == _owner() and not account_owner.is_empty() and step not in ["", "done"]

func permits_tab(tab_id: String) -> bool:
	return not locks_lobby() or tab_id == ("shop" if step in ["shop", "draw_done"] else "main")

func guide(id: String, action: Callable) -> void:
	var data: Array = DATA.GUIDES[id]
	show_modal(data[0], data[1], "알겠어요", action)

func advance(next_step: String, praise: String, action: Callable) -> void:
	if not CHECKPOINT.save(next_step):
		show_modal("진행 저장 실패", "저장 공간을 확인해 주세요. 완료한 행동을 다시 요구하지 않도록 진행을 먼저 저장합니다.", "다시 시도", advance.bind(next_step, praise, action))
		return
	step = next_step
	show_modal("잘했어요!", praise, "다음", action)

func install_lobby(lobby: Node) -> void:
	var preview: bool = get_node("/root/LocalTestMode").is_tutorial_preview()
	if not preview and (SCOPE.user_id.is_empty() or get_node("/root/LocalTestMode").active):
		account_owner = ""
		step = ""
		status = ""
		pending_exit = false
		return
	var cloud: Node = transport if transport != null else get_node("/root/CloudStore")
	if not preview and transport == null and not cloud.ready_for_play:
		return
	if account_owner != _owner():
		pending_exit = false
		status = ""
	account_owner = _owner()
	bind_host(lobby)
	step = CHECKPOINT.read()
	busy = true
	var account := account_owner
	show_modal("첫 걸음 확인 중", "계정의 튜토리얼과 보상 기록을 확인하고 있습니다…", "확인 중", Callable())
	var result := await _rpc("read")
	busy = false
	if account != _owner() or not is_instance_valid(lobby):
		return
	if not bool(result.get("ok", false)):
		show_modal("튜토리얼 확인 실패", "네트워크 또는 저장 상태를 확인하고 다시 시도해 주세요.\n지급 여부를 확인하기 전에는 보상을 중복 지급하지 않습니다.", "다시 시도", install_lobby.bind(lobby), "", Callable())
		return
	status = String(result.get("status", ""))
	clear_guide()
	if status == "active":
		if step.is_empty() or step == "done":
			step = "entry"
		resume_lobby()
	elif status == "completed" and step in ["shop", "draw_done"]:
		resume_lobby()
	elif status == "pending":
		step = ""
		show_modal("마왕의 첫 걸음", "던전 입장부터 군단 소환까지 차근차근 배워 볼까요?\n진행 중 앱을 종료해도 완료한 단계 다음부터 이어집니다.\n\n진행하거나 스킵해도 10+1회 소환 비용 %d골드를 계정당 한 번 지급합니다." % DATA.REWARD, "진행", start_lobby, "스킵", finish_lobby)
		if preview:
			copy.text += "\n첫 가입 테스트 · 보상은 로컬 저장에만 지급됩니다."
	else:
		step = ""

func resume_lobby() -> void:
	pending_exit = false
	if step in ["shop", "draw_done"]:
		if status == "active":
			finish_lobby()
		else:
			show_shop()
		return
	host.main_modes_view.ranked = false
	host.main_modes_view.perspective = "demon"
	host.main_modes_view.difficulty = "easy"
	host.selected_stage_index = 0
	host._switch_tab("main")
	host._refresh_stage_card()
	guide("entry", func(): point_to(host.enter_stage_button, "빛나는 ‘던전 입장’ 버튼을 눌러 주세요. 완료한 단계 다음부터 이어집니다."))


func start_lobby() -> void:
	busy = true
	var account := account_owner
	var target := host
	var result := await _rpc("start")
	busy = false
	if account != _owner() or not is_instance_valid(target) or host != target:
		return
	if not bool(result.get("ok", false)):
		show_modal("시작 저장 실패", "튜토리얼 시작을 저장하지 못했습니다.", "다시 시도", start_lobby, "", Callable())
		return
	status = String(result.get("status", ""))
	if not active():
		clear_guide()
		return
	if not CHECKPOINT.save("entry"):
		show_modal("진행 저장 실패", "튜토리얼 진행을 저장하지 못했습니다.", "다시 시도", start_lobby)
		return
	step = "entry"
	resume_lobby()

func finish_lobby() -> void:
	busy = true
	var account := account_owner
	var target := host
	show_modal("보상 저장 중", "튜토리얼 보상을 계정에 안전하게 저장하고 있습니다…", "저장 중", Callable())
	var action := "complete" if step in ["shop", "draw_done"] else "skip"
	var result := await _rpc(action)
	busy = false
	if account != _owner() or not is_instance_valid(target) or host != target:
		return
	if not bool(result.get("ok", false)):
		show_modal("보상 저장 실패", "보상은 아직 확인되지 않았습니다. 재시도해도 중복 지급되지 않습니다.\n저장 충돌이라면 다시 로그인해 주세요.", "다시 시도", finish_lobby, "", Callable())
		return
	status = String(result.get("status", ""))
	pending_exit = false
	if is_instance_valid(host):
		host._refresh_header()
		host._refresh_shop_summon_buttons()
	if action == "skip":
		step = "done"
		if not CHECKPOINT.save("done"):
			show_modal("진행 저장 실패", "보상은 계정에 저장됐습니다. 종료 상태 저장을 재시도하세요.", "다시 시도", finish_lobby)
			return
		show_modal("첫 소환 보상", "%d골드가 지급되었습니다. 상점에서 군단을 소환해 보세요." % DATA.REWARD, "확인", clear_guide)
	else:
		show_shop()

func show_shop() -> void:
	host._switch_tab("shop")
	if step == "draw_done":
		draw_presented()
		return
	guide("shop", focus_shop)

func focus_shop() -> void:
	var lobby := host
	var owner := account_owner
	var target: Control = host.shop_multi_button.get_node("SummonButton")
	# Ensure the actual purchase control is inside the viewport before masking.
	var scroll: ScrollContainer = null
	# Product nesting differs from the legacy scene: locate only its ancestors.
	var ancestor: Node = target.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer:
			scroll = ancestor
			break
		ancestor = ancestor.get_parent()
	if scroll != null:
		scroll.ensure_control_visible(target)
	await get_tree().process_frame
	if is_instance_valid(lobby) and host == lobby and owner == _owner() and step == "shop":
		point_to(target, "빛나는 10+1회 ‘소환하기’를 눌러 첫 군단을 만나세요.")

func tutorial_draw_pending() -> bool:
	return locks_lobby() and step == "shop"

func draw_started() -> void:
	step = CHECKPOINT.read() # Written atomically with cost and shard rewards.
	clear_guide()
	if is_instance_valid(host):
		point_to(host.gacha_reveal_overlay, "소환 연출을 확인한 뒤 결과창의 확인을 눌러 주세요.")

func draw_presented() -> void:
	advance("done", "첫 군단의 조각을 얻었어요! 이제 팀 편성과 연구를 활용해 용사의 빌드를 공략해 보세요.", clear_guide)


var coach_completed := false

func battle_started(main: Node) -> void:
	if not active():
		return
	bind_host(main)
	if step in ["", "entry"]:
		if not CHECKPOINT.save("summon"):
			show_modal("진행 저장 실패", "입장 진행을 저장하지 못했습니다.", "다시 시도", battle_started.bind(main))
			return
		step = "summon"
	coach_completed = false
	coach = load("res://src/ui/tutorial_battle_coach.gd").new()
	coach.install(main, self)

func leave_battle() -> void:
	if not active() or not is_instance_valid(host):
		return
	clear_guide()
	host._on_lobby_pressed()

func returning_to_lobby() -> void:
	if active():
		pending_exit = true
		clear_guide()
