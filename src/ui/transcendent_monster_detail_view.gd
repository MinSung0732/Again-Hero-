extends RefCounted
const DATA := preload("res://src/data/transcendent_detail_catalog.gd")
const RULES := preload("res://src/data/transcendence_catalog.gd")
var root: VBoxContainer
var unlock: Label
var notes: Label
var upgrades: Label
var rows: Array[HBoxContainer] = []
var titles: Array[Label] = []
var descriptions: Array[Label] = []
var icons: Array[TextureRect] = []
var placeholders: Array[Label] = []
var textures: Dictionary = {}
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
		badge.custom_minimum_size = Vector2(64,64)
		badge.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		badge.tooltip_text = "임시 기술 아이콘 · 추후 교체 예정"
		row.add_child(badge)
		var icon := TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
func present(id: String) -> void:
	var entry: Dictionary = DATA.ENTRIES.get(id,{})
	root.show()
	notes.text = String(entry.get("notes","전투 능력 준비 중입니다."))
	unlock.text = RULES.describe(id)+"\n전투당 한 번 소환할 수 있습니다."
	var skills: Array = entry.get("skills",[])
	for i in range(rows.size()):
		rows[i].visible = i < skills.size()
		if i >= skills.size(): continue
		var skill: Dictionary = skills[i]
		titles[i].text = String(skill.name)+"\n"+String(skill.kind)
		descriptions[i].text = String(skill.text)
		var path := String(skill.get("icon",DATA.PLACEHOLDER_ICON))
		if not textures.has(path):
			textures[path] = load(path) as Texture2D if ResourceLoader.exists(path) else null
		icons[i].texture = textures[path]
		placeholders[i].visible = icons[i].texture == null
		placeholders[i].text = "P" if String(skill.kind)=="패시브" else str(i+1)
	var lines := PackedStringArray()
	var effects: Array = entry.get("upgrades",[])
	for i in range(effects.size()):
		lines.append("%d초월 · %s"%[i+1,String(effects[i])])
	upgrades.text = "\n\n".join(lines) if not lines.is_empty() else "초월 효과 준비 중입니다."
