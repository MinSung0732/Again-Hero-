extends RefCounted
const DETAIL := preload("res://src/ui/hero_inventory_detail.gd")
const ICONS := preload("res://src/ui/hero_augment_icons.gd")
const RESULT_SECTION_MARGIN := 24
static func build(parent: VBoxContainer, model: Dictionary, actions: Dictionary) -> void:
	parent.add_theme_constant_override("separation",16)
	var accent := Color("f8cf7c") if bool(model.won) else Color("ee929b")
	var title := DETAIL.label(parent,"용사 승리!" if bool(model.won) else "용사 패배",48,accent)
	title.name = "ResultTitle"; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var subtitle := DETAIL.label(parent,String(model.message),24,Color("d0c6df")); subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var scroll := ScrollContainer.new(); scroll.name = "ResultScroll"; scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; parent.add_child(scroll)
	var body := VBoxContainer.new(); body.size_flags_horizontal = Control.SIZE_EXPAND_FILL; body.add_theme_constant_override("separation",12); scroll.add_child(body)
	if not parent.resized.is_connected(fit.bind(parent)):
		parent.resized.connect(fit.bind(parent),CONNECT_DEFERRED)
	body.minimum_size_changed.connect(fit.bind(parent),CONNECT_DEFERRED)
	fit.call_deferred(parent)
	var stats := DETAIL.section(body,"전투 기록",accent)
	stats.get_parent().add_theme_stylebox_override("panel",DETAIL.style(Color("141624"),accent,RESULT_SECTION_MARGIN))
	var seconds := maxi(0,floori(float(model.seconds)))
	for pair in [["생존 시간","%02d분 %02d초" % [seconds/60,seconds%60]],["처치 수",str(model.kills)],["용사 Lv.","Lv.%d" % int(model.level)]]:
		var row := HBoxContainer.new(); row.custom_minimum_size.y = 48; stats.add_child(row)
		var key := DETAIL.label(row,String(pair[0]),25,Color("a8c7df")); key.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var value := DETAIL.label(row,String(pair[1]),28); value.autowrap_mode = TextServer.AUTOWRAP_OFF; value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	DETAIL.label(stats,"장착한 핵심 무기",25,Color("a8c7df"))
	var gear := HFlowContainer.new(); gear.name = "ResultWeapons"; gear.add_theme_constant_override("h_separation",10); gear.add_theme_constant_override("v_separation",10); stats.add_child(gear)
	for weapon in model.weapons:
		var frame := PanelContainer.new(); frame.add_theme_stylebox_override("panel",DETAIL.style(Color("111322"),Color("cba763"),RESULT_SECTION_MARGIN)); gear.add_child(frame)
		var slot := VBoxContainer.new(); frame.add_child(slot)
		var icon := TextureRect.new(); icon.texture = ICONS.texture(String(weapon.id)); icon.custom_minimum_size = Vector2(72,72)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; icon.mouse_filter = Control.MOUSE_FILTER_IGNORE; slot.add_child(icon)
		var rank := DETAIL.label(slot,String(weapon.rank),22,Color("ffda86")); rank.autowrap_mode = TextServer.AUTOWRAP_OFF; rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if model.weapons.is_empty(): DETAIL.label(stats,"장착 무기 없음",23)
	var rewards := DETAIL.section(body,"획득 보상",Color("dfb7ef")); rewards.name = "ResultRewards"
	rewards.get_parent().add_theme_stylebox_override("panel",DETAIL.style(Color("141624"),Color("dfb7ef"),RESULT_SECTION_MARGIN))
	if not bool(model.settled):
		DETAIL.label(rewards,"보상 저장에 실패했습니다. 재시도 후 이동하세요.",24,Color("ee929b"))
		var retry := DETAIL.button(parent,"보상 저장 재시도",actions.settle); retry.name = "ResultSettle"; retry.grab_focus(); return
	if model.has("research_base"):
		DETAIL.label(rewards,"연구 기본 %d + 성과 %d" % [int(model.research_base),int(model.research_performance)],22,Color("dc9af6"))
		DETAIL.label(rewards,"골드 기본 %d + 성과 %d + 성장 %d" % [int(model.gold_base),int(model.gold_performance),int(model.gold_growth)],22,Color("ffcf77"))
	if int(model.get("chest_earned",0)) > 0:
		DETAIL.label(rewards,"상자 누적 %d → 지급 %d골드 (%d%%)" % [int(model.chest_earned),int(model.chest_paid),roundi(float(model.chest_rate)*100)],22,Color("ffcf77")).name = "ResultChestGold"
	if int(model.get("first_clear_token",0)) > 0:
		DETAIL.label(rewards,"스테이지 첫 클리어 · 용사토큰 +%d" % int(model.first_clear_token),22,Color("dc9af6"))
	if int(model.get("all_clear_token",0)) > 0:
		DETAIL.label(rewards,"쉬움 전체 클리어 · 용사토큰 +%d" % int(model.all_clear_token),22,Color("dc9af6"))
	var reward_grid := GridContainer.new(); reward_grid.columns = 2; reward_grid.add_theme_constant_override("h_separation",20); rewards.add_child(reward_grid)
	for pair in [["연구 포인트",int(model.research),Color("dc9af6")],["골드",int(model.gold),Color("ffcf77")]]:
		var cell := VBoxContainer.new(); cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL; reward_grid.add_child(cell)
		DETAIL.label(cell,String(pair[0]),24)
		var amount := DETAIL.label(cell,"+%d" % int(pair[1]),34,pair[2]); amount.name = "RewardAmount"; amount.autowrap_mode = TextServer.AUTOWRAP_OFF
	if bool(model.won) and bool(model.next_available):
		var next := DETAIL.button(parent,"다음 스테이지 도전",actions.next); next.name = "ResultNext"; next.grab_focus()
	var footer := BoxContainer.new(); footer.name = "ResultActions"; footer.vertical = parent.get_viewport_rect().size.y >= 700 or parent.get_viewport_rect().size.x < 700; footer.add_theme_constant_override("separation",12); parent.add_child(footer)
	var retry := DETAIL.button(footer,"같은 용사로 다시 도전",actions.retry); retry.size_flags_horizontal = Control.SIZE_EXPAND_FILL; retry.name = "ResultRetry"
	if not bool(model.next_available): retry.grab_focus()
	var lobby := DETAIL.button(footer,"로비로",actions.leave); lobby.size_flags_horizontal = Control.SIZE_EXPAND_FILL; lobby.name = "ResultLobby"
	lobby.add_theme_stylebox_override("normal",DETAIL.style(Color("1d283b"),Color("d9b363"),16))

static func fit(parent: VBoxContainer) -> void:
	if not is_instance_valid(parent) or not parent.is_inside_tree(): return
	var panel := parent.get_parent() as PanelContainer
	var root := panel.get_parent() as Control if panel != null else null
	var scroll := parent.get_node_or_null("ResultScroll") as ScrollContainer
	if root == null or scroll == null or scroll.get_child_count() == 0: return
	var body := scroll.get_child(0) as Control
	# Scroll's minimum excludes its scrolling child. Add its actual content once;
	# retain fixed buttons and only scroll when the screen cannot fit the content.
	var needed: float = parent.get_combined_minimum_size().y+body.get_combined_minimum_size().y+48
	var height := minf(ceilf(needed),maxf(180,root.size.y-48))
	panel.anchor_top = 0.5; panel.anchor_bottom = 0.5
	if not is_equal_approx(panel.offset_top,-height*0.5): panel.offset_top = -height*0.5
	if not is_equal_approx(panel.offset_bottom,height*0.5): panel.offset_bottom = height*0.5
