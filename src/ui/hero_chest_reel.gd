extends Control
## One receipt determines the landing item. All three rows/side FX are reused.
const DATA := preload("res://src/data/hero_weapon_catalog.gd")
const ICONS := preload("res://src/ui/hero_augment_icons.gd")
const ROW_HEIGHT := 86.0
var pool: Array = []
var receipt: Dictionary = {}
var final_turns := 0
var turns := 0.0
var progress := 0.0
var displayed_id := ""
var labels: Array[Label] = []
var icons: Array[TextureRect] = []
var last_index := -1
var center_label: Label
func configure(owned: Array, reward: Dictionary) -> void:
	pool = owned.duplicate(); receipt = reward
	var winner := String(receipt.get("id","survival_restore"))
	if winner not in pool: pool.append(winner)
	final_turns = pool.size()*12+pool.find(winner)
	custom_minimum_size = Vector2(0,ROW_HEIGHT*3)
	clip_contents = true; mouse_filter = Control.MOUSE_FILTER_IGNORE
	for index in 3:
		var icon := TextureRect.new(); icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(icon); icons.append(icon)
		var label := Label.new(); label.add_theme_font_size_override("font_size",28)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(label); labels.append(label)
	center_label = labels[1]
	resized.connect(_layout)
	advance(0.0)
func advance(value: float) -> void:
	progress = clampf(value,0,1); turns = progress*final_turns
	var index := floori(turns)
	if index != last_index:
		last_index = index
		for slot in 3:
			var id := String(pool[posmod(index+slot-1,pool.size())])
			icons[slot].texture = ICONS.texture(id)
			labels[slot].text = String(DATA.WEAPONS[id].name) if DATA.WEAPONS.has(id) else "생명의 축복"
		displayed_id = String(pool[index%pool.size()])
	if progress >= 1.0: center_label.text = String(receipt.name)
	_layout(); queue_redraw()
func _layout() -> void:
	var offset := (turns-floorf(turns))*ROW_HEIGHT
	for index in labels.size():
		var top := index*ROW_HEIGHT-offset
		icons[index].position = Vector2(90,top+11); icons[index].size = Vector2(64,64)
		labels[index].position = Vector2(170,top); labels[index].size = Vector2(maxf(1,size.x-260),ROW_HEIGHT)
		labels[index].modulate = Color("ffe09a") if index == 1 else Color(0.65,0.73,0.8,0.6)
		icons[index].modulate.a = 1.0 if index == 1 else 0.45
func _draw() -> void:
	draw_style_box(_background(),Rect2(Vector2(74,ROW_HEIGHT),Vector2(maxf(1,size.x-148),ROW_HEIGHT)))
	var clock := progress*TAU*18.0
	for side in 2:
		var x := 34.0 if side == 0 else size.x-34.0
		var sign_x := 1.0 if side == 0 else -1.0
		var pulse := (0.5+0.5*sin(clock))*float(progress < 1.0)
		var color := Color("f4ca73"); color.a = 0.65+pulse*0.35
		var center := Vector2(x+sign_x*pulse*12,ROW_HEIGHT*1.5)
		draw_line(center+Vector2(-sign_x*12,-18),center+Vector2(sign_x*10,0),color,5)
		draw_line(center+Vector2(sign_x*10,0),center+Vector2(-sign_x*12,18),color,5)
		for spark in 4:
			var point := Vector2(x,ROW_HEIGHT*1.5)+Vector2.from_angle(clock*sign_x+spark*TAU/4)*Vector2(18,80)
			draw_circle(point,3.0+pulse*2.0,Color(color,0.65 if progress < 1 else 0))
var background: StyleBoxFlat
func _background() -> StyleBoxFlat:
	if background == null:
		background = StyleBoxFlat.new(); background.bg_color = Color("244254")
		background.border_color = Color("d5b86f"); background.set_border_width_all(2); background.set_corner_radius_all(8)
	return background
