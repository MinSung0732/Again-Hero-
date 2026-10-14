extends PanelContainer
## Fixed controls refreshed only while expanded; values are actual runtime bonuses.
const ART := preload("res://src/ui/hero_hud_art.gd")
var expanded := false
var toggle: Button
var rows: VBoxContainer
var values: Array[Label] = []
const KEYS := ["damage","armor","speed","haste","hp","siphon","area","xp"]
const TITLES := ["기본 공격","피해 감소","기본 이속","공속 보너스","최대 체력","피흡","범위 보너스","경험치 보너스"]
func _ready() -> void:
	name = "HeroStats"
	mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new(); style.bg_color = Color("151322eb"); style.border_color = Color("ae8650")
	style.set_border_width_all(2); style.set_content_margin_all(8); add_theme_stylebox_override("panel",style)
	var box := VBoxContainer.new(); box.add_theme_constant_override("separation",4); add_child(box)
	toggle = Button.new(); toggle.name = "Toggle"; toggle.custom_minimum_size.y = 44
	toggle.add_theme_font_size_override("font_size",21); toggle.pressed.connect(_toggle); box.add_child(toggle)
	rows = VBoxContainer.new(); rows.name = "Rows"; box.add_child(rows)
	for index in KEYS.size():
		var line := HBoxContainer.new(); line.custom_minimum_size.y = 34; line.add_theme_constant_override("separation",6); rows.add_child(line)
		var icon := TextureRect.new(); icon.texture = ART.icon(KEYS[index]); icon.custom_minimum_size = Vector2(28,28)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; icon.mouse_filter = Control.MOUSE_FILTER_IGNORE; line.add_child(icon)
		var title := Label.new(); title.text = TITLES[index]; title.add_theme_font_size_override("font_size",20); line.add_child(title)
		var value := Label.new(); value.size_flags_horizontal = Control.SIZE_EXPAND_FILL; value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value.add_theme_font_size_override("font_size",22); value.add_theme_color_override("font_color",Color("ffe2a4")); line.add_child(value); values.append(value)
	_apply()
func _toggle() -> void:
	expanded = not expanded; _apply()
func _apply() -> void:
	rows.visible = expanded; toggle.text = "능력치 ‹" if expanded else "능력치 ›"
	custom_minimum_size.x = 280 if expanded else 108
	size = Vector2(custom_minimum_size.x,0)
func refresh(hero, runtime) -> void:
	if not expanded or runtime == null: return
	var base_damage: float = runtime.identity.attack_damage() if runtime.identity != null else float(hero.attack_damage)
	values[0].text = str(roundi(base_damage*runtime.power))
	values[1].text = "%.0f%%" % ((1.0-runtime.damage_multiplier)*100.0)
	values[2].text = "%.0f" % hero.move_speed
	values[3].text = "+%.0f%%" % ((1.0/runtime.haste-1.0)*100.0)
	values[4].text = str(hero.max_hp)
	values[5].text = "%.1f%%" % (runtime.passive_siphon*100.0)
	values[6].text = "+%.0f%%" % ((runtime.area_bonus-1.0)*100.0)
	values[7].text = "+%.0f%%" % ((hero.exp_gain_multiplier-1.0)*100.0)
