extends RefCounted
## Built only when paused; reuse authored pixel skins and owned weapon icons.
const DETAIL := preload("res://src/ui/hero_inventory_detail.gd")
const ICONS := preload("res://src/ui/hero_augment_icons.gd")
static func build(parent: VBoxContainer, model: Dictionary, actions: Dictionary) -> void:
	parent.add_theme_constant_override("separation",20)
	var header := HBoxContainer.new(); header.name = "PauseHeader"; parent.add_child(header)
	var title := DETAIL.label(header,"일시정지 · 용사 모드",36,Color("ffcf79")); title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var x := DETAIL.button(header,"×",actions.resume); x.name = "PauseClose"; x.custom_minimum_size = Vector2(76,76)
	var scroll := ScrollContainer.new(); scroll.name = "PauseScroll"; scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; parent.add_child(scroll)
	var body := VBoxContainer.new(); body.size_flags_horizontal = Control.SIZE_EXPAND_FILL; body.add_theme_constant_override("separation",20); scroll.add_child(body)
	var summary := PanelContainer.new(); summary.name = "PauseSummary"; summary.add_theme_stylebox_override("panel",DETAIL.style(Color("161425"),Color("d2ac62"),20)); body.add_child(summary)
	var grid := GridContainer.new(); grid.name = "SummaryGrid"; grid.columns = 2; grid.add_theme_constant_override("h_separation",20); grid.add_theme_constant_override("v_separation",20); summary.add_child(grid)
	grid.resized.connect(func(): grid.columns = 4 if grid.size.x >= 760 else 2)
	var elapsed := maxi(0,floori(float(model.seconds)))
	for pair in [["생존 시간","%02d:%02d" % [elapsed/60,elapsed%60]],["처치 수",str(model.kills)],["현재 레벨","Lv.%d" % int(model.level)]]:
		var cell := VBoxContainer.new(); cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL; grid.add_child(cell)
		DETAIL.label(cell,String(pair[0]),22,Color("ada7c9"))
		var value := DETAIL.label(cell,String(pair[1]),30); value.autowrap_mode = TextServer.AUTOWRAP_OFF
	var gear := VBoxContainer.new(); gear.size_flags_horizontal = Control.SIZE_EXPAND_FILL; grid.add_child(gear)
	DETAIL.label(gear,"주요 장비 / 스킬",22,Color("ada7c9"))
	var slots := HFlowContainer.new(); gear.add_child(slots)
	for id in model.weapons:
		var icon := TextureRect.new(); icon.texture = ICONS.texture(String(id)); icon.custom_minimum_size = Vector2(48,48)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; icon.mouse_filter = Control.MOUSE_FILTER_IGNORE; slots.add_child(icon)
	if model.weapons.is_empty(): DETAIL.label(gear,"장비 없음",22)
	if int(model.get("chest_gold",0)) > 0: DETAIL.label(body,"상자 골드 누적 %d · 종료 시 정산" % int(model.chest_gold),23,Color("ffcf77"))
	for entry in [["계속 플레이","resume"],["다시 시작","restart"],["설정","settings"],["로비로 돌아가기","leave"]]:
		var button := DETAIL.button(body,String(entry[0]),actions[String(entry[1])]); button.name = "Pause_"+String(entry[1]); button.custom_minimum_size.y = 96
		if entry[1] == "resume": button.grab_focus()
		else: button.add_theme_stylebox_override("normal",DETAIL.style(Color("1a1729"),Color("d9b363"),16))
	if not parent.resized.is_connected(fit.bind(parent)):
		parent.resized.connect(fit.bind(parent),CONNECT_DEFERRED)
	body.minimum_size_changed.connect(fit.bind(parent),CONNECT_DEFERRED)
	fit.call_deferred(parent)

static func fit(parent: VBoxContainer) -> void:
	if not is_instance_valid(parent) or not parent.is_inside_tree(): return
	var panel := parent.get_parent() as PanelContainer
	var root := panel.get_parent() as Control if panel != null else null
	var scroll := parent.get_node_or_null("PauseScroll") as ScrollContainer
	if root == null or scroll == null or scroll.get_child_count() == 0: return
	var content := scroll.get_child(0) as Control
	var needed: float = parent.get_node("PauseHeader").get_combined_minimum_size().y+content.get_combined_minimum_size().y+20+48
	var available := maxf(180,root.size.y-panel.offset_top-24)
	var height := minf(needed,available)
	panel.anchor_bottom = 0.0
	if not is_equal_approx(panel.offset_bottom,panel.offset_top+height): panel.offset_bottom = panel.offset_top+height
