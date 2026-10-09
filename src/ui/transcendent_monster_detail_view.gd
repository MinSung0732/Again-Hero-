extends RefCounted
const SKILL_ICONS := preload("res://src/data/skill_icon_catalog.gd")
const DATA := preload("res://src/data/transcendent_detail_catalog.gd")
const COLLECTION := preload("res://src/systems/monster_collection_store.gd")
const RULES := preload("res://src/data/transcendence_catalog.gd")
var root: VBoxContainer
var unlock: Label
var notes: Label
var upgrades: Label
var upgrade_panels: Array[PanelContainer] = []
var upgrade_titles: Array[Label] = []
var upgrade_descriptions: Array[Label] = []
var active_style: StyleBoxFlat
var locked_style: StyleBoxFlat
var rows: Array[HBoxContainer] = []
var titles: Array[Label] = []
var descriptions: Array[Label] = []
var icons: Array[TextureRect] = []
var placeholders: Array[Label] = []
func _label(parent: Node, text: String, font_size: int = 26) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color("ddd1e6"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label
func install(parent: Control) -> void:
	root = VBoxContainer.new()
	root.name = "TranscendentDetails"
	root.add_theme_constant_override("separation",20)
	parent.add_child(root)
	notes = _label(root,"")
	_label(root,"잠금 해제조건",30).add_theme_color_override("font_color",Color("f0cb68"))
	unlock = _label(root,"")
	_label(root,"기술 · 패시브",30).add_theme_color_override("font_color",Color("f0cb68"))
	for i in range(5):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation",16)
		root.add_child(row)
		rows.append(row)
		var badge := PanelContainer.new()
		badge.custom_minimum_size = Vector2(80,80)
		badge.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		badge.tooltip_text = "임시 기술 아이콘 · 추후 교체 예정"
		row.add_child(badge)
		var icon := TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		badge.add_child(icon)
		icons.append(icon)
		var placeholder := _label(icon,str(i+1),24)
		placeholder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		placeholders.append(placeholder)
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(column)
		titles.append(_label(column,"",28))
		descriptions.append(_label(column,"",24))
	_label(root,"초월시 추가효과",30).add_theme_color_override("font_color",Color("f0cb68"))
	upgrades = _label(root,"")
	active_style = _upgrade_style(Color("30263d"),Color("cfaa5b"))
	locked_style = _upgrade_style(Color("1a1723"),Color("494151"))
	for i in range(5):
		var panel := PanelContainer.new()
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(panel)
		upgrade_panels.append(panel)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation",8)
		panel.add_child(column)
		upgrade_titles.append(_label(column,"",26))
		upgrade_descriptions.append(_label(column,"",24))
func _upgrade_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style
func present(id: String) -> void:
	var entry: Dictionary = DATA.ENTRIES.get(id,{})
	root.show()
	notes.text = String(entry.get("notes","전투 능력 준비 중입니다."))
	unlock.text = RULES.describe(id).replace(" 및 ","\n그리고 ").replace(" 또는 ","\n또는 ")+"\n\n전투당 한 번 소환할 수 있습니다."
	var skills: Array = entry.get("skills",[])
	for i in range(rows.size()):
		rows[i].visible = i < skills.size()
		if i >= skills.size(): continue
		var skill: Dictionary = skills[i]
		titles[i].text = String(skill.name)+"\n"+String(skill.kind)
		descriptions[i].text = String(skill.text)
		var skill_id := String(skill.get("id",skill.name))
		icons[i].texture = SKILL_ICONS.texture("transcendent",id,skill_id)
		icons[i].get_parent().set_meta("icon_key",SKILL_ICONS.key("transcendent",id,skill_id))
		icons[i].get_parent().tooltip_text = String(skill.name)+(" · 스킬 아이콘 자리" if icons[i].texture == null else "")
		placeholders[i].visible = icons[i].texture == null
		placeholders[i].text = "P" if String(skill.kind)=="패시브" else str(i+1)
	# Read the current account once when opening, including after an upgrade.
	var state := COLLECTION.load_state()
	var owned := COLLECTION.is_unlocked(id,state)
	var level := clampi(COLLECTION.get_upgrade_level(id,state),0,5) if owned else 0
	var effects: Array = entry.get("upgrades",[])
	upgrades.text = "현재 %d초월 · 5초월까지 강화할 수 있습니다." % level if owned else "미획득 · 획득 후 초월 효과를 해금할 수 있습니다."
	if effects.is_empty(): upgrades.text = "초월 효과 준비 중입니다."
	for i in range(upgrade_panels.size()):
		upgrade_panels[i].visible = i < effects.size()
		if i >= effects.size(): continue
		var enabled := owned and level >= i+1
		upgrade_panels[i].set_meta("active",enabled)
		upgrade_panels[i].add_theme_stylebox_override("panel",active_style if enabled else locked_style)
		upgrade_titles[i].text = "%d초월 · %s" % [i+1,"활성" if enabled else "잠김"]
		upgrade_titles[i].add_theme_color_override("font_color",Color("f0cb68") if enabled else Color("938b9f"))
		upgrade_descriptions[i].text = String(effects[i])
		upgrade_descriptions[i].add_theme_color_override("font_color",Color("eee3ef") if enabled else Color("938b9f"))
