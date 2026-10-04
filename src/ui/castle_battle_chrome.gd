extends Control

# Static presentation shell using the shipped castle artwork. No collision,
# camera tracking, per-frame animation, or gameplay input nodes.
var wall: Texture2D
var pillar: Texture2D
var flag: Texture2D
var brazier: Texture2D

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
	main.battle_viewport_container.offset_top = 350
	# Reserve side ornament space instead of painting over moving actors.
	main.battle_viewport_container.offset_left = 64
	main.battle_viewport_container.offset_right = -64
	place(main.get_node("HUD/HeroSkillCooldownBar"), Rect2(72, 360, 470, 68))
	for index in range(2):
		var button: Button = main.monster_info_bookmark if index == 0 else main.hero_info_bookmark
		button.offset_left = -166
		button.offset_right = -22
		button.offset_top = 382 + index * 162
		button.offset_bottom = button.offset_top + 142
		place(button.get_node("Icon"), Rect2(46, 24, 52, 52))
		place(button.get_node("Label"), Rect2(10, 87, 124, 38), 24)
	var chrome = load("res://src/ui/castle_battle_chrome.gd").new()
	chrome.name = "CastleBattleChrome"
	chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chrome.z_index = -10
	main.hud_layer.add_child(chrome)
	chrome.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chrome.wall = load("res://assets/art/UI/tiles/again_hero_B_walls/wall_top_001.png")
	chrome.pillar = load("res://assets/art/UI/tiles/again_hero_C_objects/pillar_001.png")
	chrome.flag = load("res://assets/art/UI/tiles/again_hero_C_objects/flag_002.png")
	chrome.brazier = load("res://assets/art/UI/tiles/again_hero_C_objects/brazier_001.png")
	chrome.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	chrome.resized.connect(chrome.queue_redraw)
	chrome.queue_redraw()

static func place(control: Control, rect: Rect2, font_size: int = 0) -> void:
	control.position = rect.position
	control.size = rect.size
	if font_size > 0:
		control.add_theme_font_size_override("font_size", font_size)

func _draw() -> void:
	var width := size.x
	var bottom := size.y - 465.0
	# Header architecture is behind all labels; only the narrow edge strip
	# overlays the scrolling world. Center remains open and unobscured.
	draw_rect(Rect2(0, 0, width, 350), Color("141020"))
	if wall != null:
		for column in range(4):
			draw_texture_rect(wall, Rect2(column * width / 4.0, 0, width / 4.0, 350), false, Color(0.48, 0.40, 0.58, 1))
	draw_rect(Rect2(0, 344, width, 6), Color("9c7340"))
	for right in [false, true]:
		var x := width - 64.0 if right else 0.0
		draw_rect(Rect2(x, 350, 64, maxf(bottom - 350, 0)), Color("191326"))
		if pillar != null:
			var y := 350.0
			while y < bottom:
				draw_texture_rect(pillar, Rect2(x, y, 64, minf(270, bottom - y)), false, Color(0.7, 0.62, 0.85, 1))
				y += 270
		if flag != null:
			draw_texture_rect(flag, Rect2(x, 362, 64, 176), false, Color(0.7, 0.54, 0.85, 1))
		if brazier != null:
			for y in [650.0, bottom - 160.0]:
				if y > 512 and y + 145 < bottom:
					draw_texture_rect(brazier, Rect2(x, y, 64, 145), false, Color(0.85, 0.72, 0.92, 1))
