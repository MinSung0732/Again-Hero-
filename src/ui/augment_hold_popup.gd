extends Control
const RULES := preload("res://src/online/match_rules.gd")
const ICONS := preload("res://src/ui/hero_augment_icons.gd")
const DEMON_AUGMENTS := preload("res://src/data/demon_augment_catalog.gd")
const MONSTERS := preload("res://src/data/monster_catalog.gd")
signal choose(number: int,id: String)
signal reroll(number: int)
signal oldest_auto_chosen

var role := "hero"
var rerolls_left := 0
var reroll_limit := 0
var controls_enabled := true
var holds: Array = []
var dots: Array[Button] = []
var cards: Array[Button] = []
var card_icons: Array[TextureRect] = []
var card_names: Array[Label] = []
var card_descriptions: Array[Label] = []
var dot_row: HBoxContainer
var popup: PanelContainer
var popup_rows: VBoxContainer
var title_label: Label
var reroll_button: Button
var lower_button: Button
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
	popup = PanelContainer.new(); popup.name = "HoldPopup"; popup.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(popup); popup.hide()
	var margin := MarginContainer.new(); popup.add_child(margin)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,20)
	popup_rows = VBoxContainer.new(); popup_rows.add_theme_constant_override("separation",12); margin.add_child(popup_rows)
	title_label = Label.new(); title_label.add_theme_font_size_override("font_size",28)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; popup_rows.add_child(title_label)
	# The solo augment choice card's icon/name/description layout is reused in compact form.
	for index in RULES.MAX_OFFER_CANDIDATES:
		var card := Button.new(); card.name = "Candidate%d" % index
		card.custom_minimum_size.y = 130; popup_rows.add_child(card)
		card.pressed.connect(_choose_card.bind(index)); cards.append(card)
		var row := HBoxContainer.new(); row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); card.add_child(row)
		var icon := TextureRect.new(); icon.name = "AugmentIcon"
		icon.custom_minimum_size = Vector2(110,110); icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon); card_icons.append(icon)
		var labels := VBoxContainer.new(); labels.mouse_filter = Control.MOUSE_FILTER_IGNORE
		labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(labels)
		var name_label := Label.new(); name_label.add_theme_font_size_override("font_size",25)
		labels.add_child(name_label); card_names.append(name_label)
		var description := Label.new(); description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.add_theme_font_size_override("font_size",21); labels.add_child(description)
		card_descriptions.append(description); card.hide()
	reroll_button = Button.new(); reroll_button.name = "Reroll"; reroll_button.custom_minimum_size.y = 64
	popup_rows.add_child(reroll_button); reroll_button.pressed.connect(_reroll_open)
	lower_button = Button.new(); lower_button.name = "Lower"; lower_button.text = "내리기"; lower_button.custom_minimum_size.y = 64
	popup_rows.add_child(lower_button); lower_button.pressed.connect(close_popup)
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
		var dot := dots[holds.size()-1]
		var tween := create_tween(); tween.tween_property(dot,"modulate",Color(1.0,0.8,0.3),0.12)
		tween.tween_property(dot,"modulate",Color.WHITE,0.2)

func open_index(index: int) -> void:
	if index < 0 or index >= holds.size(): return
	opened_number = int(holds[index].number)
	_show_offer(); popup.show(); _layout()

func close_popup() -> void:
	opened_number = -1; popup.hide()

func set_controls(enabled: bool) -> void:
	controls_enabled = enabled
	for card in cards: card.disabled = not enabled
	reroll_button.disabled = not enabled or rerolls_left <= 0

func set_rerolls(left: int,limit: int) -> void:
	if rerolls_left == left and reroll_limit == limit: return
	rerolls_left = left; reroll_limit = limit
	_refresh_reroll()

func set_lower_top(value: float) -> void:
	lower_top = value; _layout()

func _show_offer() -> void:
	for offer in holds:
		if int(offer.number) != opened_number: continue
		title_label.text = "보관 증강 · %d번 선택지" % opened_number
		var options: Array = offer.candidates
		for index in cards.size():
			cards[index].visible = index < options.size()
			if index >= options.size(): continue
			var option: Dictionary = options[index]
			card_names[index].text = String(option.get("name",""))
			card_descriptions[index].text = String(option.get("description",""))
			card_icons[index].texture = _candidate_icon(String(option.get("id","")))
		_refresh_reroll(); _layout(); return

func _refresh_reroll() -> void:
	reroll_button.visible = reroll_limit > 0
	reroll_button.text = "새로고침 · 남은 %d/%d회" % [rerolls_left,reroll_limit]
	reroll_button.disabled = not controls_enabled or rerolls_left <= 0

func _candidate_icon(id: String) -> Texture2D:
	if role == "hero": return ICONS.texture(id)
	var data: Dictionary = DEMON_AUGMENTS.get_augment(id)
	var monster_id := String(data.get("target_monster_id",data.get("monster_id","")))
	if monster_id.is_empty(): return ICONS.texture("survival_power")
	var path := String(MONSTERS.get_monster(monster_id).get("card_icon_path",""))
	if path.is_empty(): return ICONS.texture("survival_power")
	return load(path) as Texture2D

func _choose_card(index: int) -> void:
	if not controls_enabled: return
	for offer in holds:
		if int(offer.number) != opened_number: continue
		if index >= offer.candidates.size(): return
		last_chosen_number = opened_number
		choose.emit(opened_number,String(offer.candidates[index].id)); close_popup(); return

func _reroll_open() -> void:
	if controls_enabled and rerolls_left > 0 and opened_number >= 0:
		reroll.emit(opened_number)

func _layout() -> void:
	if dot_row == null or popup == null: return
	dot_row.position = Vector2(maxf(0.0,(size.x-RULES.AUGMENT_HOLD_LIMIT*76.0)/2.0),maxf(0.0,lower_top-72.0))
	if popup.visible:
		var width := minf(720.0,size.x-48.0)
		var height := minf(popup.get_combined_minimum_size().y,size.y-120.0)
		popup.size = Vector2(width,height)
		popup.position = Vector2((size.x-width)*0.5,(size.y-height)*0.5)
