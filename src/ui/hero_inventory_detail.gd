extends RefCounted
const DATA := preload("res://src/data/hero_weapon_catalog.gd")
const ICONS := preload("res://src/ui/hero_augment_icons.gd")
const SKIN := preload("res://src/ui/pixel_panel_skin.gd")
const GEOMETRY := preload("res://src/hero_mode/hero_weapon_geometry.gd")
const ROW_ICONS := {"기본 타격 피해":"survival_power","피해 계수":"survival_projectile_power","기본 재사용":"survival_haste","공격 범위":"survival_reach","발동 수":"survival_multishot","무기 흡혈":"survival_siphon"}
static func weapon_model(runtime, hero, id: String) -> Dictionary:
	var rank := int(runtime.levels[id]); var evolved: bool = runtime.evolved.has(id)
	var data: Dictionary = runtime.stats_for(id)
	var base: float = runtime.identity.attack_damage() if runtime.identity != null else float(hero.attack_damage)
	var damage := maxi(1,roundi(base*float(data.power)*runtime.power*float(data.damage_scale)))
	var rows: Array = [["기본 타격 피해",str(damage)],["피해 계수","%.0f%%" % (float(data.power)*100)],["기본 재사용","%.2f초" % (float(data.cooldown)*runtime.haste*float(data.cooldown_scale))],["공격 범위","%.0f" % GEOMETRY.reach(data,rank,evolved)]]
	var delivery := DATA.DELIVERY.spec(id,data)
	if not delivery.is_empty(): rows[0][0] = "시전 피해 기준"
	var hits := int(data.get("base_hits",1))+int(data.get("bonus_hits",0))
	if hits > 1 and String(data.pattern) in ["bolt","burst","combo","chain","meteor","piercer","ice_pillar"]: rows.append(["발동 수",str(hits)+"회"])
	if String(data.pattern) == "orbit": rows.append(["발동 수",str(data.get("orbit_count",4))+"개 접촉 궤도"])
	if not delivery.is_empty(): rows.append(["전달 방식",String(delivery.label)])
	if float(data.get("lifesteal",0)) > 0: rows.append(["무기 흡혈","%.1f%%" % (float(data.lifesteal)*100)])
	return {"id":id,"name":DATA.GROWTH.evolution_name(id) if evolved else String(data.name),"kind":"무기","rank":"Lv.11 MAX" if evolved else "Lv.%d" % rank,"evolved":evolved,"maxed":evolved,"description":DATA.card_tags(id,data),"rows":rows,"effects":DATA.inventory_description(id,data),"flow":"","note":""}
static func passive_model(runtime, id: String) -> Dictionary:
	var rank := int(runtime.passives[id]); var limit := DATA.passive_limit(id)
	var passive: Dictionary = DATA.PASSIVES[id]
	var total := float(passive.value)*rank*100.0
	if String(passive.stat) == "armor": total = minf(30,total)
	if String(passive.stat) == "slow_resist": total = (minf(0.85,runtime.base_slow_resistance+total/100)-runtime.base_slow_resistance)*100
	var bonus := "+%d개" % mini(rank,2) if String(passive.stat) == "multishot" else "+%.1f%%" % total
	var effects := DATA.inventory_description(id,{})
	return {"id":id,"name":String(passive.name),"kind":"보조 증강","rank":"MAX" if rank >= limit else "Lv.%d" % rank,"evolved":false,"maxed":rank >= limit,"description":"#보조","rows":[["현재 레벨","%d / %d" % [rank,limit]],["누적 효과",bonus]],"effects":effects,"flow":"","note":""}
static func label(parent: Node, text: String, font_size: int, color: Color = Color.WHITE) -> Label:
	var node := Label.new(); node.text = text; node.add_theme_font_size_override("font_size",font_size); node.add_theme_color_override("font_color",color)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; node.mouse_filter = Control.MOUSE_FILTER_IGNORE; parent.add_child(node); return node
static func style(fill: Color, border: Color, margin: int = 16) -> StyleBox:
	var box := StyleBoxFlat.new(); box.bg_color = fill; box.border_color = border; box.set_border_width_all(2); box.set_content_margin_all(margin)
	return SKIN.skin_style(box)
static func section(parent: Node, title: String, color: Color) -> VBoxContainer:
	label(parent,title,28,color)
	var panel := PanelContainer.new(); panel.add_theme_stylebox_override("panel",style(Color("141624"),color)); parent.add_child(panel)
	var rows := VBoxContainer.new(); rows.add_theme_constant_override("separation",12); panel.add_child(rows); return rows
static func button(parent: Node, text: String, action: Callable) -> Button:
	var node := Button.new(); node.text = text; node.custom_minimum_size.y = 76; node.add_theme_font_size_override("font_size",28)
	for state in ["normal","hover","pressed","focus"]:
		node.add_theme_stylebox_override(state,style(Color("45235f") if state == "normal" else Color("643681"),Color("e4b95e"),16))
	parent.add_child(node); node.pressed.connect(action); return node
static func build(parent: VBoxContainer, model: Dictionary, close: Callable) -> void:
	parent.add_theme_constant_override("separation",16)
	var bar := HBoxContainer.new(); bar.name = "DetailHeader"; parent.add_child(bar)
	var caption := label(bar,"장착 증강 상세",23,Color("d8b970")); caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var x := button(bar,"×",close); x.name = "DetailClose"; x.custom_minimum_size = Vector2(76,76)
	var scroll := ScrollContainer.new(); scroll.name = "DetailScroll"; scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; parent.add_child(scroll)
	var body := VBoxContainer.new(); body.size_flags_horizontal = Control.SIZE_EXPAND_FILL; body.add_theme_constant_override("separation",18); scroll.add_child(body)
	var head := VBoxContainer.new(); head.name = "DetailIdentity"; head.add_theme_constant_override("separation",12); body.add_child(head)
	var frame := PanelContainer.new(); frame.add_theme_stylebox_override("panel",style(Color("0e101a"),Color("e2b958"),10)); frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER; head.add_child(frame)
	var icon := TextureRect.new(); icon.name = "DetailIcon"; icon.texture = ICONS.texture(model.id); icon.custom_minimum_size = Vector2(160,160)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; icon.mouse_filter = Control.MOUSE_FILTER_IGNORE; frame.add_child(icon)
	var title := VBoxContainer.new(); title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; title.add_theme_constant_override("separation",12); head.add_child(title)
	var name_label := label(title,String(model.name),34); name_label.name = "DetailTitle"; name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var badges := HBoxContainer.new(); badges.name = "DetailBadges"; badges.alignment = BoxContainer.ALIGNMENT_CENTER; badges.add_theme_constant_override("separation",8); title.add_child(badges)
	for text in [String(model.kind),"진화" if model.evolved else "",String(model.rank)]:
		if text.is_empty(): continue
		var badge := PanelContainer.new(); badge.add_theme_stylebox_override("panel",style(Color("292237"),Color("dabd73"),8)); badges.add_child(badge); var badge_text := label(badge,text,22,Color("ffe190")); badge_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	label(body,String(model.description),24,Color("acb4c9"))
	var stats := section(body,"기본 능력치",Color("f1ca67")); stats.name = "DetailStats"
	for row in model.rows:
		var line := HBoxContainer.new(); line.name = "StatRow"; line.custom_minimum_size.y = 48; stats.add_child(line)
		line.add_theme_constant_override("separation",14)
		var glyph := TextureRect.new(); glyph.texture = ICONS.texture(String(ROW_ICONS.get(String(row[0]),model.id))); glyph.custom_minimum_size = Vector2(32,32)
		glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; glyph.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE; line.add_child(glyph)
		var key := label(line,String(row[0]),24); key.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var value := label(line,String(row[1]),26,Color("aee3fa")); value.name = "StatValue"; value.autowrap_mode = TextServer.AUTOWRAP_OFF; value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if not String(model.note).is_empty(): label(body,String(model.note),20,Color("8994ac"))
	var effects := section(body,"무기 설명" if model.kind == "무기" else "증강 설명",Color("ce92ea")); effects.name = "DetailDescription"; label(effects,String(model.effects),24)
	if not String(model.flow).is_empty():
		label(body,"연관 콘텐츠",27,Color("ce92ea")); label(body,String(model.flow),23,Color("c2c6da"))
	var resume := button(parent,"계속 플레이",close); resume.name = "DetailResume"; resume.grab_focus()
