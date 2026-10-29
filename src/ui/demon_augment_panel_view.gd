extends RefCounted
const AUGMENT_COMPARE := preload("res://src/ui/augment_compare_view.gd")
const MONSTERS := preload("res://src/data/monster_catalog.gd")
# Card rows (button-local y): the level/tag line sits above the details button for both card kinds.
const CARD_HEIGHT := 458.0
const LEVEL_TOP := 346.0
const LEVEL_BOTTOM := 384.0
const DETAILS_TOP := 394.0
const DETAILS_BOTTOM := 442.0

static func populate(panel: PanelContainer,candidates: Array,demon_level: int,rerolls_left: int,reroll_max: int) -> bool:
	var rows := panel.get_node("Margin/VBox") as VBoxContainer
	var is_special := not candidates.is_empty() and String(candidates[0].get("augment_type","normal")) == "special"
	(rows.get_node("Title") as Label).text = "마왕의 특수증강" if is_special else "마왕의 개입"
	(rows.get_node("Trigger") as Label).text = ("마왕 Lv.%d · 편성 몬스터 특수증강 1개 선택" if is_special else "마왕 Lv.%d · 일반증강 1개 선택") % demon_level
	var choices := rows.get_node("Choices") as HBoxContainer
	for index in 3:
		var button := choices.get_node("Choice%d" % index) as Button
		button.set_pressed_no_signal(false)
		button.disabled = true
		button.visible = index < candidates.size()
		if index >= candidates.size(): continue
		var candidate: Dictionary = candidates[index]
		var special := String(candidate.get("augment_type","normal")) == "special"
		button.custom_minimum_size.y = CARD_HEIGHT
		var level := button.get_node("Level") as Label
		level.offset_top = LEVEL_TOP
		level.offset_bottom = LEVEL_BOTTOM
		var monster_id := String(candidate.get("monster_id", "")) if special else String(candidate.get("target_monster_id",""))
		var icon := button.get_node("Icon") as TextureRect
		icon.texture = _monster_icon(monster_id)
		icon.visible = icon.texture != null
		button.text = ""
		var name_label := button.get_node("Name") as Label
		name_label.text = _wrap(String(candidate.get("name","증강")),14)
		name_label.add_theme_font_size_override("font_size",18 if name_label.text.contains("\n") else 22)
		var description := button.get_node("Description") as Label
		description.text = _wrap(String(candidate.get("description","")),16)
		(button.get_node("Level") as Label).text = "특수 · %s" % String(MONSTERS.get_monster(monster_id).get("name",monster_id)) if special else "%d/%d" % [mini(int(candidate.get("current_stack",0))+1,int(candidate.get("max_stack",1))),int(candidate.get("max_stack",1))]
		name_label.offset_top = 122.0 if icon.visible else 64.0
		name_label.offset_bottom = 176.0 if icon.visible else 118.0
		description.offset_top = 180.0 if icon.visible else 126.0
		var comparison_view := button.get_node_or_null("AugmentCompare") as RichTextLabel
		if comparison_view == null:
			comparison_view = AUGMENT_COMPARE.add(button,[],AUGMENT_COMPARE.SOLO_DEMON_FONT,true)
			comparison_view.set_anchors_preset(Control.PRESET_TOP_WIDE)
			comparison_view.offset_left = 18.0
			comparison_view.offset_right = -18.0
			comparison_view.fit_content = false
			comparison_view.scroll_active = false
			comparison_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		comparison_view.offset_top = 228.0
		comparison_view.offset_bottom = 344.0
		var comparison: Array = candidate.get("compare",[])
		AUGMENT_COMPARE.update(comparison_view,comparison)
		description.offset_bottom = 224.0 if comparison_view.visible else 332.0
		description.max_lines_visible = 2 if comparison_view.visible else 6
		description.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		var details := AUGMENT_COMPARE.details(button,candidate)
		details.set_anchors_preset(Control.PRESET_TOP_WIDE)
		details.offset_left = 18.0
		details.offset_right = -18.0
		details.offset_top = DETAILS_TOP
		details.offset_bottom = DETAILS_BOTTOM
	var reroll := rows.get_node("Actions/RerollButton") as Button
	reroll.text = "↻ 새로고침 %d / %d" % [rerolls_left,reroll_max]
	reroll.disabled = true
	var confirm := rows.get_node("Actions/ConfirmButton") as Button
	confirm.disabled = true
	confirm.text = "증강을 먼저 선택하세요"
	var guide := rows.get_node("Guide") as Label
	guide.text = ("특수증강 레벨입니다. 편성 몬스터의 전투 방식을 강화하세요." if is_special else "일반증강 레벨입니다. 마왕 운영 또는 편성 몬스터를 강화하세요.") + "\n카드 선택 후 ‘적용’을 눌러 확정하세요."
	return is_special

static func _monster_icon(monster_id: String) -> Texture2D:
	if monster_id.is_empty(): return null
	var path := String(MONSTERS.get_monster(monster_id).get("card_icon_path",""))
	if path.is_empty(): return null
	var texture: Texture2D = null
	if ResourceLoader.exists(path): texture = load(path) as Texture2D
	if texture == null and FileAccess.file_exists(path):
		var source := Image.new()
		if source.load(path) == OK: texture = ImageTexture.create_from_image(source)
	if texture == null: return null
	var image := texture.get_image()
	if image == null or image.is_empty(): return texture
	var used := image.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0: return texture
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(used.position,used.size)
	return atlas

static func _wrap(value: String,max_chars_per_line: int) -> String:
	var max_chars := maxi(max_chars_per_line,4)
	var lines: PackedStringArray = []
	var current := ""
	for raw_word in value.split(" ",false):
		var word := String(raw_word)
		if word.length() > max_chars:
			if not current.is_empty(): lines.append(current); current = ""
			var start := 0
			while start < word.length():
				lines.append(word.substr(start,mini(max_chars,word.length()-start)))
				start += max_chars
			continue
		var next := word if current.is_empty() else "%s %s" % [current,word]
		if next.length() > max_chars:
			if not current.is_empty(): lines.append(current)
			current = word
		else: current = next
	if not current.is_empty(): lines.append(current)
	return "\n".join(lines)
