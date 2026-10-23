extends Control
const RULES := preload("res://src/online/match_rules.gd")
const ICONS := preload("res://src/ui/hero_augment_icons.gd")
const DEMON_AUGMENTS := preload("res://src/data/demon_augment_catalog.gd")
const MONSTERS := preload("res://src/data/monster_catalog.gd")
const AUGMENT_COMPARE := preload("res://src/ui/augment_compare_view.gd")
const DEMON_PANEL := preload("res://src/ui/demon_augment_panel.tscn")
const DEMON_VIEW := preload("res://src/ui/demon_augment_panel_view.gd")
const HERO_CARDS := preload("res://src/ui/hero_augment_cards_view.gd")
const SKIN := preload("res://src/ui/pixel_panel_skin.gd")
# New held offer: the slot glows soft yellow once (fade in, then out).
const NEW_HOLD_GLOW_COLOR := Color(1.0,0.86,0.3,0.55)
const NEW_HOLD_GLOW_IN := 0.18
const NEW_HOLD_GLOW_OUT := 0.5
const NEW_HOLD_GLOW_MARGIN := 10.0
signal choose(number: int,id: String)
signal reroll(number: int)
signal oldest_auto_chosen

var role := "hero"
var rerolls_left := 0
var reroll_limit := 0
var controls_enabled := true
var holds: Array = []
var dots: Array[Button] = []
var dot_glows: Array[Panel] = []
var dot_glow_tweens: Array = []
var cards: Array[Button] = []
var card_icons: Array[TextureRect] = []
var card_names: Array[Label] = []
var card_descriptions: Array[Label] = []
var card_comparisons: Array[RichTextLabel] = []
var dot_row: HBoxContainer
var popup: PanelContainer
var popup_rows: VBoxContainer
var title_label: Label
var reroll_button: Button
var lower_button: Button
var confirm_button: Button
var selected_index := -1
var lower_top := 1700.0
var opened_number := -1
var last_chosen_number := -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dot_row = HBoxContainer.new(); dot_row.name = "HoldDots"
	dot_row.add_theme_constant_override("separation",16); add_child(dot_row)
	for index in RULES.AUGMENT_HOLD_LIMIT:
		var dot := Button.new(); dot.name = "Dot%d" % index; dot.text = "●"
		dot.custom_minimum_size = Vector2(60,60); dot.add_theme_font_size_override("font_size",34)
		dot_row.add_child(dot); dot.pressed.connect(open_index.bind(index)); dot.hide(); dots.append(dot)
		# Glow panels are built once per slot and only tweened when an offer arrives.
		var glow := Panel.new(); glow.name = "NewGlow"; glow.mouse_filter = Control.MOUSE_FILTER_IGNORE; glow.show_behind_parent = true
		var glow_style := StyleBoxFlat.new(); glow_style.bg_color = NEW_HOLD_GLOW_COLOR; glow_style.set_corner_radius_all(int(30.0+NEW_HOLD_GLOW_MARGIN))
		glow.add_theme_stylebox_override("panel",glow_style)
		dot.add_child(glow); glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		glow.offset_left = -NEW_HOLD_GLOW_MARGIN; glow.offset_top = -NEW_HOLD_GLOW_MARGIN; glow.offset_right = NEW_HOLD_GLOW_MARGIN; glow.offset_bottom = NEW_HOLD_GLOW_MARGIN
		glow.modulate.a = 0.0; dot_glows.append(glow); dot_glow_tweens.append(null)
	if role == "demon":
		popup = DEMON_PANEL.instantiate() as PanelContainer
		popup.name = "HoldPopup"
		add_child(popup); popup.hide()
		popup_rows = popup.get_node("Margin/VBox") as VBoxContainer
		title_label = popup_rows.get_node("Trigger") as Label
		reroll_button = popup_rows.get_node("Actions/RerollButton") as Button
		confirm_button = popup_rows.get_node("Actions/ConfirmButton") as Button
		confirm_button.pressed.connect(_confirm_demon)
		for index in 3:
			var card := popup_rows.get_node("Choices/Choice%d" % index) as Button
			card.toggle_mode = true; card.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
			card.pressed.connect(_choose_card.bind(index)); cards.append(card)
			card_icons.append(card.get_node("Icon") as TextureRect)
			card_names.append(card.get_node("Name") as Label)
			card_descriptions.append(card.get_node("Description") as Label)
	else:
		popup = PanelContainer.new(); popup.name = "HoldPopup"; add_child(popup); popup.hide()
		var style := StyleBoxFlat.new(); style.bg_color = Color("122b3a"); style.border_color = Color("d9c77c"); style.set_border_width_all(3); style.set_content_margin_all(28)
		popup.add_theme_stylebox_override("panel",SKIN.skin_style(style))
		popup_rows = VBoxContainer.new(); popup_rows.add_theme_constant_override("separation",22); popup.add_child(popup_rows)
		title_label = Label.new(); title_label.add_theme_font_size_override("font_size",32)
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; popup_rows.add_child(title_label)
		var choices := HBoxContainer.new(); choices.name = "HorizontalAugmentCards"
		choices.add_theme_constant_override("separation",16); choices.alignment = BoxContainer.ALIGNMENT_CENTER
		choices.size_flags_vertical = Control.SIZE_EXPAND_FILL; popup_rows.add_child(choices)
		for index in RULES.MAX_OFFER_CANDIDATES:
			var card: Button = HERO_CARDS.create(choices,{"id":"slot_%d" % index},_choose_card.bind(index))
			card.hide(); cards.append(card)
			card_icons.append(card.get_node("MarginContainer/VBoxContainer/AugmentIcon") as TextureRect)
			card_names.append(card.get_node("MarginContainer/VBoxContainer/Name") as Label)
		reroll_button = Button.new(); reroll_button.name = "AugmentReroll"
		reroll_button.custom_minimum_size.y = 64; reroll_button.add_theme_font_size_override("font_size",26)
		popup_rows.add_child(reroll_button)
	lower_button = Button.new(); lower_button.name = "Lower"; lower_button.text = "내리기"; lower_button.custom_minimum_size.y = 64
	if role == "demon":
		lower_button.custom_minimum_size.y = confirm_button.custom_minimum_size.y
		lower_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		popup_rows.get_node("Actions").add_child(lower_button)
	else:
		popup_rows.add_child(lower_button)
	lower_button.pressed.connect(close_popup)
	reroll_button.pressed.connect(_reroll_open)
	resized.connect(_layout)
	_layout()

func set_holds(next_holds: Array) -> void:
	if holds == next_holds: return
	var old: Array = holds
	holds = next_holds.duplicate(true)
	if old.size() == RULES.AUGMENT_HOLD_LIMIT and holds.size() == RULES.AUGMENT_HOLD_LIMIT and not old.is_empty():
		var oldest_number := int(old[0].get("number",-1))
		var still_present := false
		for offer in holds:
			if int(offer.get("number",-1)) == oldest_number: still_present = true
		if not still_present and oldest_number != last_chosen_number: oldest_auto_chosen.emit()
	last_chosen_number = -1
	for index in dots.size():
		dots[index].visible = index < holds.size()
		if index < holds.size(): dots[index].tooltip_text = "보관 증강 %d" % int(holds[index].get("number",0))
	if opened_number >= 0:
		var found := false
		for offer in holds:
			if int(offer.get("number",-1)) == opened_number: found = true
		if found: _show_offer()
		else: close_popup()
	_layout()
	if holds.size() > old.size() and holds.size() > 0:
		_glow_slot(holds.size()-1)

func _glow_slot(index: int) -> void:
	var previous: Tween = dot_glow_tweens[index]
	if previous != null and previous.is_valid(): previous.kill()
	var glow := dot_glows[index]; glow.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(glow,"modulate:a",1.0,NEW_HOLD_GLOW_IN)
	tween.tween_property(glow,"modulate:a",0.0,NEW_HOLD_GLOW_OUT)
	dot_glow_tweens[index] = tween

func open_index(index: int) -> void:
	if index < 0 or index >= holds.size(): return
	opened_number = int(holds[index].number)
	selected_index = -1
	_show_offer(); popup.show(); _layout()

func close_popup() -> void:
	opened_number = -1; selected_index = -1; popup.hide()

func set_controls(enabled: bool) -> void:
	if enabled == controls_enabled: return
	controls_enabled = enabled
	for card in cards: card.disabled = not enabled
	if confirm_button != null: confirm_button.disabled = not enabled or selected_index < 0
	reroll_button.disabled = not enabled or rerolls_left <= 0
	if enabled and opened_number >= 0: _show_offer() # keeps unavailable cards disabled

func set_rerolls(left: int,limit: int) -> void:
	if rerolls_left == left and reroll_limit == limit: return
	rerolls_left = left; reroll_limit = limit
	_refresh_reroll()

func set_lower_top(value: float) -> void:
	lower_top = value; _layout()

func _show_offer() -> void:
	for offer in holds:
		if int(offer.number) != opened_number: continue
		var options: Array = offer.candidates
		if role == "demon":
			DEMON_VIEW.populate(popup,options,int(offer.get("level",1)),rerolls_left,reroll_limit)
			title_label.text += " · 보관 %d번" % opened_number
			selected_index = -1; confirm_button.disabled = true
			for index in cards.size():
				cards[index].disabled = not controls_enabled or index >= options.size() or bool(options[index].get("unavailable",false))
		else:
			title_label.text = "레벨업 · 증강을 선택하세요 · 보관 %d번" % opened_number
			for index in cards.size():
				cards[index].visible = index < options.size()
				if index >= options.size(): continue
				var old := cards[index]
				var parent := old.get_parent() as HBoxContainer
				var position := old.get_index()
				parent.remove_child(old); old.queue_free()
				var option: Dictionary = options[index]
				var card: Button = HERO_CARDS.create(parent,option,_choose_card.bind(index))
				parent.move_child(card,position); cards[index] = card
				card.custom_minimum_size.x = 200 if options.size() > 3 else 280
				card.disabled = not controls_enabled or bool(option.get("unavailable",false))
				card_names[index] = card.get_node("MarginContainer/VBoxContainer/Name") as Label
		_refresh_reroll(); _layout(); return
func _refresh_reroll() -> void:
	reroll_button.visible = reroll_limit > 0
	reroll_button.text = "↻ 새로고침 · 남은 %d/%d회" % [rerolls_left,reroll_limit]
	reroll_button.disabled = not controls_enabled or rerolls_left <= 0

func _choose_card(index: int) -> void:
	if not controls_enabled: return
	for offer in holds:
		if int(offer.number) != opened_number: continue
		if index >= offer.candidates.size() or bool(offer.candidates[index].get("unavailable",false)): return
		if role == "demon":
			selected_index = index
			for button_index in cards.size(): cards[button_index].set_pressed_no_signal(button_index == index)
			confirm_button.text = "선택한 증강 적용"; confirm_button.disabled = false
			return
		last_chosen_number = opened_number
		choose.emit(opened_number,String(offer.candidates[index].id)); close_popup(); return

func _confirm_demon() -> void:
	if not controls_enabled or selected_index < 0: return
	for offer in holds:
		if int(offer.number) != opened_number: continue
		if selected_index >= offer.candidates.size() or bool(offer.candidates[selected_index].get("unavailable",false)): return
		last_chosen_number = opened_number
		choose.emit(opened_number,String(offer.candidates[selected_index].id)); close_popup(); return

func _reroll_open() -> void:
	if controls_enabled and rerolls_left > 0 and opened_number >= 0:
		reroll.emit(opened_number)

func _layout() -> void:
	if dot_row == null or popup == null: return
	dot_row.position = Vector2(maxf(0.0,(size.x-RULES.AUGMENT_HOLD_LIMIT*76.0)/2.0),maxf(0.0,lower_top-72.0))
	if popup.visible:
		if role == "demon": return
		var width := minf(980.0,size.x-48.0)
		var height := minf(820.0,size.y-120.0)
		popup.size = Vector2(width,height)
		popup.position = Vector2((size.x-width)*0.5,(size.y-height)*0.5)
