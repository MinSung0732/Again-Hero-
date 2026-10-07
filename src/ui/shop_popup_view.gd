extends RefCounted

# Presentation only. All displayed odds and results come from existing stores.
const SHOP := preload("res://src/data/shop_catalog.gd")
const MONSTERS := preload("res://src/data/monster_catalog.gd")
const SKIN := preload("res://src/ui/shop_frame_skin.gd")
var lobby: Control
var rates: VBoxContainer
var history: VBoxContainer
var rates_scroll: ScrollContainer
var history_scroll: ScrollContainer
var icon_cache: Dictionary = {}

func install(host: Control) -> void:
	lobby = host
	for name in ["ShopRatesOverlay", "ShopResultOverlay"]:
		var panel := lobby.get_node(name + "/Panel") as PanelContainer
		panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		panel.anchor_left = 0.06
		panel.anchor_right = 0.94
		panel.anchor_top = 0.18 if name == "ShopRatesOverlay" else 0.26
		panel.anchor_bottom = 0.86
		var margin := panel.get_node("Margin") as MarginContainer
		for side in ["left", "right", "top", "bottom"]:
			margin.add_theme_constant_override("margin_" + side, 24)
		var column := margin.get_node("VBox") as VBoxContainer
		column.add_theme_constant_override("separation", 14)
		var title := column.get_node("Header/Title") as Label
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_stylebox_override("normal", SKIN.style("shop_title_frame", 8))
		title.add_theme_font_size_override("font_size", 34)
		for path in ["Guide", "Footer" if name == "ShopResultOverlay" else "Notice"]:
			var copy := column.get_node(path) as Label
			copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			copy.add_theme_font_size_override("font_size", 21)
		var header := column.get_node("Header") as HBoxContainer
		var close := header.get_node("CloseButton") as Button
		close.custom_minimum_size = Vector2(112, 66)
		if name == "ShopRatesOverlay":
			var container := column.get_node("RatesPanel") as PanelContainer
			container.custom_minimum_size.y = 0
			container.add_theme_stylebox_override("panel", SKIN.plain_content_style(0))
			var inner := container.get_node("Margin") as MarginContainer
			for side in ["left", "right", "top", "bottom"]:
				inner.add_theme_constant_override("margin_" + side, 0)
			rates_scroll = inner.get_node("Scroll") as ScrollContainer
			(inner.get_node("Scroll/Rates") as Control).hide()
			rates = _list(rates_scroll, "RateRows")
		else:
			history_scroll = column.get_node("ResultScroll") as ScrollContainer
			history_scroll.custom_minimum_size.y = 0
			(column.get_node("ResultScroll/Result") as Control).hide()
			history = _list(history_scroll, "HistoryRows")
	for scroll in [rates_scroll, history_scroll]:
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		scroll.scroll_deadzone = 14

func _list(parent: Control, node_name: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.name = node_name
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 12)
	parent.add_child(box)
	return box

func _clear(box: VBoxContainer) -> void:
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()

func _label(parent: Control, text: String, color: Color = Color("e6ddec"), font_size: int = 24, ratio: float = 0.0) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ratio > 0:
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.size_flags_stretch_ratio = ratio
	parent.add_child(label)
	return label

func _row(parent: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "Row"
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	return row

func _panel(parent: Control, color: Color, strong: bool = false) -> VBoxContainer:
	var frame := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("261932") if strong else Color("160f22")
	style.border_color = Color(color, 0.65 if strong else 0.28)
	style.set_border_width_all(2 if strong else 1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(14)
	frame.add_theme_stylebox_override("panel", style)
	parent.add_child(frame)
	return _list(frame, "Rows")

func _icon(parent: Control, id: String, color: Color) -> void:
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(64, 64)
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var style := StyleBoxFlat.new()
	style.bg_color = Color("100b1b")
	style.border_color = Color(color, 0.55)
	style.set_border_width_all(1)
	style.set_content_margin_all(4)
	frame.add_theme_stylebox_override("panel", style)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(frame)
	var rect := TextureRect.new()
	var data := MONSTERS.get_monster(id)
	var path := String(data.get("display_icon_path", ""))
	var texture: Texture2D
	if not path.is_empty():
		if not icon_cache.has(path):
			icon_cache[path] = lobby._load_png_texture_direct(path)
		texture = icon_cache[path]
	if texture == null:
		texture = lobby._team_monster_card_icon(id)
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(rect)

func _shards(data: Dictionary) -> String:
	return "%d ~ %d" % [int(data.get("shard_min", 1)), int(data.get("shard_max", 1))]

func _rate_cells(parent: Control, name_text: String, probability: String, shards: String, color: Color) -> void:
	var row := _row(parent)
	row.custom_minimum_size.y = 56
	_label(row, name_text, color, 26, 0.45)
	_label(row, probability, color, 26, 0.27).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label(row, shards, Color("e6ddec"), 24, 0.28).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func show_rates(pickup_id: String) -> void:
	_clear(rates)
	rates_scroll.scroll_vertical = 0
	var active_pickup := not pickup_id.is_empty()
	lobby.get_node("ShopRatesOverlay/Panel/Margin/VBox/Header/Title").text = "픽업 확률" if active_pickup else "상품 확률"
	lobby.get_node("ShopRatesOverlay/Panel/Margin/VBox/Guide").text = "등급 확률 → 해당 등급 안에서 몬스터 추첨\n표시 확률은 소환 1회 기준입니다."
	_rate_cells(rates, "등급", "등장 확률", "조각 수량", Color("bbabc9"))
	for rarity in SHOP.RARITY_ORDER:
		var data := SHOP.get_rarity(rarity)
		var color: Color = data.color
		var summary := _panel(rates, color, true)
		summary.get_parent().name = "Summary_" + rarity
		_rate_cells(summary, "◆ " + SHOP.get_rarity_label(rarity), "%.3f%%" % SHOP.get_effective_probability(rarity), _shards(data), color)
	if active_pickup:
		var feature := _panel(rates, SHOP.get_rarity(MONSTERS.get_rarity(pickup_id)).color, true)
		feature.get_parent().name = "PickupFeature"
		_label(feature, "픽업 몬스터 · 등급 내 가중치 %s배" % str(SHOP.monster_weight(pickup_id, pickup_id)), Color("ffe6a4"), 25)
		_monster_rate(feature, pickup_id, pickup_id)
	_label(rates, "몬스터별 등장 확률", Color("ffe6a4"), 28)
	for rarity in SHOP.RARITY_ORDER:
		var data := SHOP.get_rarity(rarity)
		var pool := SHOP.get_monster_pool(rarity)
		var group := _panel(rates, data.color)
		group.get_parent().name = "Group_" + rarity
		_rate_cells(group, "◆ " + SHOP.get_rarity_label(rarity), "%.3f%%" % SHOP.get_effective_probability(rarity), _shards(data), data.color)
		if pool.is_empty():
			_label(group, "현재 등장하는 몬스터가 없습니다.", Color("9c8da9"), 22)
		for id in pool:
			_monster_rate(group, String(id), pickup_id)
		if bool(data.get("unlock_on_first_draw", false)):
			_label(group, "첫 획득 즉시 해금 · 이후 조각 지급", data.color, 22)
	lobby.get_node("ShopRatesOverlay/Panel/Margin/VBox/Notice").text = "전체 소환 기준 · 빈 등급 제외 후 보정 · 반올림 표시\n초월 첫 획득 즉시 해금 · 이후 조각 지급"

func _monster_rate(parent: Control, id: String, pickup: String) -> void:
	var rarity := MONSTERS.get_rarity(id)
	var data := SHOP.get_rarity(rarity)
	var row := _row(parent)
	row.name = "Monster_" + id
	row.set_meta("probability", SHOP.get_monster_probability(id, pickup))
	row.custom_minimum_size.y = 70
	_icon(row, id, data.color)
	_label(row, MONSTERS.get_monster_name(id) + (" · 픽업" if id == pickup else ""), data.color if id == pickup else Color("e6ddec"), 24, 1)
	var odds := _label(row, "%.3f%%" % SHOP.get_monster_probability(id, pickup), data.color, 24)
	odds.custom_minimum_size.x = 160
	odds.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var count := _label(row, _shards(data), Color("bfb0c9"), 23)
	count.custom_minimum_size.x = 130
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func show_history(entries: Array) -> void:
	_clear(history)
	history_scroll.scroll_vertical = 0
	var header := _row(history)
	_label(header, "No.", Color("c7b5d7"), 23).custom_minimum_size.x = 60
	_label(header, "몬스터", Color("c7b5d7"), 23, 1)
	_label(header, "획득 결과", Color("c7b5d7"), 23).custom_minimum_size.x = 200
	var number := 0
	for i in range(entries.size() - 1, maxi(entries.size() - 101, -1), -1):
		if not entries[i] is Dictionary:
			continue
		var entry: Dictionary = entries[i]
		var id := String(entry.get("monster_id", ""))
		var rarity := String(entry.get("rarity", MONSTERS.get_rarity(id)))
		var color: Color = SHOP.get_rarity(rarity).get("color", Color.WHITE)
		var box := _panel(history, color)
		box.get_parent().name = "Entry_%d" % number
		box.get_parent().set_meta("monster_id", id)
		box.get_parent().set_meta("entry", entry.duplicate())
		var row := _row(box)
		row.custom_minimum_size.y = 78
		number += 1
		_label(row, "%03d" % number, Color("a995b8"), 22).custom_minimum_size.x = 48
		_icon(row, id, color)
		var info := _list(row, "MonsterInfo")
		_label(info, MONSTERS.get_monster_name(id), color, 25)
		_label(info, SHOP.get_rarity_label(rarity), Color("ac99bb"), 21)
		var result := "첫 획득 · 해금" if bool(entry.get("first_draw_unlock", false)) else "+%d 조각" % int(entry.get("shards", 0))
		if bool(entry.get("unlocked", false)) and not bool(entry.get("first_draw_unlock", false)):
			result += "\n신규 해금"
		if int(entry.get("research_points", 0)) > 0:
			result += "\n연구 +%d" % int(entry.research_points)
		var result_label := _label(row, result, color, 23)
		result_label.custom_minimum_size.x = 200
		result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if number == 0:
		_label(history, "아직 소환 내역이 없습니다.", Color("ac99bb"), 25)
