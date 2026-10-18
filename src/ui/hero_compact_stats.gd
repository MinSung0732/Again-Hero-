extends PanelContainer
## Grouped overview. Fixed controls; no combat scans or nodes created on refresh.
const ART := preload("res://src/ui/hero_hud_art.gd")
const GROUPS := [{"title":"공격","indices":[0,3,6],"color":Color("f4d18d")},{"title":"생존","indices":[4,1,5],"color":Color("8cddba")},{"title":"이동 · 성장","indices":[2,7],"color":Color("a4c6ff")}]
const KEYS := ["damage","armor","speed","haste","hp","siphon","area","xp"]
const TITLES := ["공격력","피해 감소","이동속도","공격속도","최대 체력","피해 흡수","공격 범위","획득 경험치"]
var expanded := false
var toggle: Button
var rows: VBoxContainer
var values: Array[Label] = []
func _ready() -> void:
	name = "HeroStats"; mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new(); style.bg_color = Color("151924f5"); style.border_color = Color("a88b57")
	style.set_border_width_all(2); style.set_content_margin_all(12); add_theme_stylebox_override("panel",style)
	var box := VBoxContainer.new(); box.add_theme_constant_override("separation",8); add_child(box)
	toggle = Button.new(); toggle.name = "Toggle"; toggle.custom_minimum_size.y = 64
	toggle.add_theme_font_size_override("font_size",26); toggle.pressed.connect(_toggle); box.add_child(toggle)
	rows = VBoxContainer.new(); rows.name = "Rows"; rows.add_theme_constant_override("separation",6); box.add_child(rows)
	values.resize(KEYS.size())
	for group in GROUPS:
		var caption := Label.new(); caption.text = group.title; caption.add_theme_font_size_override("font_size",22)
		caption.add_theme_color_override("font_color",group.color); rows.add_child(caption)
		for index in group.indices:
			var line := HBoxContainer.new(); line.custom_minimum_size.y = 48; line.add_theme_constant_override("separation",8); rows.add_child(line)
			var icon := TextureRect.new(); icon.texture = ART.icon(KEYS[index]); icon.custom_minimum_size = Vector2(36,36)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; icon.mouse_filter = Control.MOUSE_FILTER_IGNORE; line.add_child(icon)
			var title := Label.new(); title.text = TITLES[index]; title.add_theme_font_size_override("font_size",26); line.add_child(title)
			var value := Label.new(); value.size_flags_horizontal = Control.SIZE_EXPAND_FILL; value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			value.add_theme_font_size_override("font_size",30); value.add_theme_color_override("font_color",group.color); line.add_child(value); values[index] = value
	var note := Label.new(); note.text = "강화 수치는 기본 대비 증가량입니다.\n피해흡수는 준 피해의 일부를 회복합니다."
	note.add_theme_font_size_override("font_size",20); note.add_theme_color_override("font_color",Color("a5aebf")); rows.add_child(note)
	_apply()
func _toggle() -> void:
	expanded = not expanded; _apply()
func _apply() -> void:
	rows.visible = expanded; toggle.text = "내 능력치  ‹" if expanded else "능력치  ›"
	custom_minimum_size.x = 370 if expanded else 152
	size = Vector2(custom_minimum_size.x,0)
func refresh(hero, runtime) -> void:
	if not expanded or runtime == null: return
	var base_damage: float = runtime.identity.attack_damage() if runtime.identity != null else float(hero.attack_damage)
	values[0].text = str(roundi(base_damage*runtime.power))
	values[1].text = "%.0f%%" % ((1.0-runtime.damage_multiplier)*100.0)
	values[2].text = "+%.0f%%" % ((hero.move_speed/maxf(1.0,runtime.base_move_speed)-1.0)*100.0)
	values[3].text = "+%.0f%%" % ((1.0/runtime.haste-1.0)*100.0)
	values[4].text = str(hero.max_hp)
	values[5].text = "%.1f%%" % (runtime.passive_siphon*100.0)
	values[6].text = "+%.0f%%" % ((runtime.area_bonus-1.0)*100.0)
	values[7].text = "+%.0f%%" % ((hero.exp_gain_multiplier/maxf(0.01,runtime.base_exp_multiplier)-1.0)*100.0)
