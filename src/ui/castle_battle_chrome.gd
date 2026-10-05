extends Control

# Static presentation shell using the shipped castle artwork. No collision,
# camera tracking, per-frame animation, or gameplay input nodes.
const ROOT := "res://assets/art/UI/battle_castle_v3/"
const PLAY_TOP := 420.0
const SIDE_INSET := 120.0
var surround: Texture2D
var floor_backing: Texture2D

static func texture(main: Node, path: String) -> Texture2D:
	var warmup := main.get_node_or_null("/root/PresentationWarmup")
	if warmup != null:
		var cached: Texture2D = warmup.get_texture(path)
		if cached != null:
			return cached
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	var image := Image.load_from_file(path)
	return ImageTexture.create_from_image(image) if image != null and not image.is_empty() else null

static func rebuild(main: Node) -> void:
	var top := main.get_node("HUD/TopBar")
	place(top.get_node("LogoPlate"), Rect2(14, 4, 350, 156))
	place(top.get_node("StageFrame"), Rect2(378, 12, 354, 148))
	place(top.get_node("StageNumber"), Rect2(412, 25, 286, 32), 24)
	top.get_node("StageNumber").horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place(top.get_node("Subtitle"), Rect2(402, 59, 306, 44), 30)
	place(top.get_node("StageHeroName"), Rect2(402, 105, 306, 32), 23)
	place(top.get_node("TimerFrame"), Rect2(750, 30, 306, 90))
	place(top.get_node("RunTimer"), Rect2(766, 48, 274, 54), 28)
	place(top.get_node("HeroStatusFrame"), Rect2(20, 165, 714, 172))
	place(top.get_node("HeroPortrait"), Rect2(38, 182, 142, 138))
	place(top.get_node("HeroLevel"), Rect2(200, 180, 500, 42), 30)
	place(top.get_node("HeroHPBar"), Rect2(200, 232, 498, 36))
	place(top.get_node("HeroHP"), Rect2(200, 232, 498, 36), 28)
	place(top.get_node("ExpBar"), Rect2(200, 280, 498, 27))
	place(top.get_node("ExpLabel"), Rect2(200, 276, 498, 35), 23)
	place(top.get_node("StageMenuButton"), Rect2(810, 130, 246, 82))
	place(top.get_node("MonsterFrame"), Rect2(750, 226, 306, 110))
	place(top.get_node("MonsterIcon"), Rect2(772, 256, 46, 46))
	place(top.get_node("Monsters"), Rect2(824, 244, 218, 68), 34)
	top.offset_bottom = 350
	place(main.get_node("HUD/HeroSkillCooldownBar"), Rect2(130, PLAY_TOP+10, 470, 68))
	for index in range(2):
		var button: Button = main.monster_info_bookmark if index == 0 else main.hero_info_bookmark
		button.offset_left = -166
		button.offset_right = -22
		button.offset_top = 366 + index * 162
		button.offset_bottom = button.offset_top + 142
		place(button.get_node("Icon"), Rect2(46, 24, 52, 52))
		place(button.get_node("Label"), Rect2(10, 87, 124, 38), 24)
	var chrome = load("res://src/ui/castle_battle_chrome.gd").new()
	chrome.name = "CastleBattleChrome"
	chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chrome.z_index = -10
	main.hud_layer.add_child(chrome)
	chrome.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chrome.surround = texture(main, ROOT + "castle_surround.png")
	chrome.floor_backing = texture(main, ROOT + "flagstone_floor.png")
	chrome.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	chrome.resized.connect(chrome.queue_redraw)
	chrome.queue_redraw()
	var panel_art := texture(main, ROOT + "gold_panel.png")
	var panel_builder = load("res://src/ui/illustrated_battle_panel.gd")
	for target in [top.get_node("StageFrame"), top.get_node("TimerFrame"),
		top.get_node("HeroStatusFrame"), top.get_node("MonsterFrame"),
		main.stage_menu_button, main.monster_info_bookmark, main.hero_info_bookmark,
		main.get_node("HUD/DemonUltimatePanel/Frame"), main.get_node("HUD/BottomBar/AutoFrame"),
		main.summon_slot_1, main.summon_slot_2, main.summon_slot_3]:
		panel_builder.install(target, panel_art)
	for button in [main.demon_ultimate_1, main.demon_ultimate_2, main.demon_ultimate_3]:
		panel_builder.install(button, panel_art)
		button.add_theme_font_size_override("font_size", 24)
		button.add_theme_color_override("font_disabled_color", Color("a497bc"))
	for button in [main.summon_slot_1, main.summon_slot_2, main.summon_slot_3]:
		place(button.get_node("Icon"), Rect2(26, 27, 110, 108))
		place(button.get_node("Name"), Rect2(138, 36, 176, 42), 24)
		place(button.get_node("Cost"), Rect2(138, 86, 176, 40), 24)
	for label in [main.get_node("HUD/DemonUltimatePanel/DemonLevelLabel"),
		main.get_node("HUD/DemonUltimatePanel/UltimateLabel"), main.get_node("HUD/BottomBar/CommandLabel")]:
		label.add_theme_font_size_override("font_size", 24)
	apply_visibility(main, main.battle_frame_enabled)

static func apply_visibility(main: Node, enabled: bool) -> void:
	var chrome: Control = main.hud_layer.get_node_or_null("CastleBattleChrome")
	if chrome != null:
		chrome.visible = enabled
	main.battle_viewport_container.offset_top = PLAY_TOP if enabled else 350.0
	main.battle_viewport_container.offset_left = SIDE_INSET if enabled else 0.0
	main.battle_viewport_container.offset_right = -SIDE_INSET if enabled else 0.0
	place(main.get_node("HUD/HeroSkillCooldownBar"), Rect2(130 if enabled else 30, PLAY_TOP+10 if enabled else 360, 470, 68))
	main._sync_skill_unlock_cutscene_frame()

static func place(control: Control, rect: Rect2, font_size: int = 0) -> void:
	control.position = rect.position
	control.size = rect.size
	if font_size > 0:
		control.add_theme_font_size_override("font_size", font_size)

func _draw() -> void:
	var width := size.x
	var bottom := size.y - 465.0
	draw_rect(Rect2(0, 0, width, PLAY_TOP), Color("141020"))
	if surround == null:
		return
	# Transparent gaps beside the pillars reveal stone, not the empty window.
	if floor_backing != null:
		for x in [0.0, width-SIDE_INSET]:
			draw_texture_rect_region(floor_backing, Rect2(x, PLAY_TOP, SIDE_INSET, bottom-PLAY_TOP), Rect2(0,0,180,1254), Color(0.60,0.54,0.72,1))
	# Split architectural bands, never squash a full pillar into a thin repeat.
	# Fill alpha gaps behind the battlements/HUD with the same opaque masonry.
	draw_texture_rect_region(surround, Rect2(0, 0, width, PLAY_TOP), Rect2(215, 505, 130, 30))
	# Crop away the transparent skyline, moving the castle upward rather than
	# leaving empty sky above the live header or squeezing its full elevation.
	draw_texture_rect_region(surround, Rect2(0, 0, width, PLAY_TOP), Rect2(0, 190, 1024, 360))
	var rail_height := maxf(bottom - PLAY_TOP, 1.0)
	draw_texture_rect_region(surround, Rect2(0, PLAY_TOP, SIDE_INSET, rail_height), Rect2(0, 550, 196, 920))
	draw_texture_rect_region(surround, Rect2(width-SIDE_INSET, PLAY_TOP, SIDE_INSET, rail_height), Rect2(828, 550, 196, 920))
	draw_rect(Rect2(SIDE_INSET, PLAY_TOP, width-SIDE_INSET*2, 8), Color(0.03,0.02,0.05,0.8))
