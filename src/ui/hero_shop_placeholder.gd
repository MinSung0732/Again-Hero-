extends RefCounted
## Presentation only. No purchase callbacks or store writes.
const ART := preload("res://src/ui/hero_shop_art.gd")
static func panel(parent: Node,name: String) -> VBoxContainer:
	var frame := PanelContainer.new(); frame.name = name
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL; parent.add_child(frame)
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.add_theme_stylebox_override("panel",ART.panel_style())
	var rows := VBoxContainer.new(); rows.add_theme_constant_override("separation",14)
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL; frame.add_child(rows); return rows
static func text(parent: Node,value: String,font: int,color: Color = Color("e8e0cd")) -> Label:
	var label := Label.new(); label.text = value
	label.add_theme_font_size_override("font_size",font); label.add_theme_color_override("font_color",color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label); return label
static func coming_button(parent: Node,value: String) -> Button:
	var button := Button.new(); button.text = value; button.disabled = true
	button.custom_minimum_size.y = 76; button.add_theme_font_size_override("font_size",26)
	button.add_theme_color_override("font_disabled_color",Color("d2c4dd"))
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.add_theme_stylebox_override("disabled",ART.panel_style(true)); parent.add_child(button); return button
static func build(body: VBoxContainer,_view) -> void:
	text(body,"◆  용사 상점  ◆",40,Color("f0d18e"))
	preload("res://src/ui/shop_token_chip.gd").build(body, "hero_token")
	text(body,"새로운 용사와의 만남을 준비하고 있습니다.",23,Color("b9abc5"))
	var banner := panel(body,"HeroShopBanner")
	text(banner,"COMING SOON",22,Color("c6a96a"))
	text(banner,"용사 뽑기 준비 중",36,Color("ffe1a0"))
	text(banner,"용사 소환과 픽업은 추후 공개됩니다.",24)
	var summon := panel(body,"HeroSummonSection")
	text(summon,"◇  용사 소환  ◇",32,Color("f0d18e"))
	text(summon,"함께할 용사들을 만나보세요.",23,Color("b9abc5"))
	var cards := HBoxContainer.new(); cards.name = "HeroSummonCards"
	cards.add_theme_constant_override("separation",18); summon.add_child(cards)
	for index in 2:
		var card := panel(cards,"HeroSummonSingle" if index == 0 else "HeroSummonMulti")
		card.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text(card,"기본 소환" if index == 0 else "10+1회 소환",26,Color("e8ca84"))
		ART.illustration(card,index == 1)
		text(card,"용사 뽑기\n준비 중",28)
		coming_button(card,"준비 중")
	var info := HBoxContainer.new(); info.add_theme_constant_override("separation",18); summon.add_child(info)
	for caption in ["소환 내역","소환 확률"]:
		coming_button(info,caption+" · 준비 중").size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pickup := panel(body,"HeroPickupSection")
	text(pickup,"◇  픽업 용사 소환  ◇",32,Color("f0d18e"))
	text(pickup,"픽업 준비 중",36,Color("ffe1a0"))
	text(pickup,"새로운 픽업 소식을 기다려 주세요.",24,Color("b9abc5"))
	coming_button(pickup,"픽업 준비 중")
