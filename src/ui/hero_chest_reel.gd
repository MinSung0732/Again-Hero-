extends Control
## Five reusable cards scroll as complete slots beneath a fixed center marker.
## Repeated IDs still move; the receipt remains authoritative.
const DATA := preload("res://src/data/hero_weapon_catalog.gd")
const ICONS := preload("res://src/ui/hero_augment_icons.gd")
const DETAIL := preload("res://src/ui/hero_inventory_detail.gd")
const CENTER_SLOT := 2
const CARD_COUNT := 5
var pool: Array = []
var receipt: Dictionary = {}
var ranks: Dictionary = {}
var final_turns := 0
var turns := 0.0
var progress := 0.0
var displayed_id := ""
var labels: Array[Label] = []
var icons: Array[TextureRect] = []
var rank_labels: Array[Label] = []
var cards: Array[Panel] = []
var last_index := -1
var center_label: Label
func configure(owned: Array, reward: Dictionary, equipped_ranks: Dictionary = {}) -> void:
	pool = owned.duplicate(); receipt = reward; ranks = equipped_ranks.duplicate()
	var winner := String(receipt.get("id","survival_restore"))
	if winner not in pool: pool.append(winner)
	final_turns = pool.size()*12+pool.find(winner)
	custom_minimum_size = Vector2(0,280)
	clip_contents = true; mouse_filter = Control.MOUSE_FILTER_IGNORE
	for index in CARD_COUNT:
		var card := Panel.new(); card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_theme_stylebox_override("panel",DETAIL.style(Color("171625"),Color("bd9d61"),12))
		add_child(card); cards.append(card)
		var icon := TextureRect.new(); icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE; card.add_child(icon); icons.append(icon)
		var rank := Label.new(); rank.add_theme_font_size_override("font_size",24)
		rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; rank.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(rank); rank_labels.append(rank)
		var label := Label.new(); label.add_theme_font_size_override("font_size",24)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(label); labels.append(label)
	center_label = labels[CENTER_SLOT]
	resized.connect(_layout)
	advance(0.0)
func advance(value: float) -> void:
	progress = clampf(value,0,1); turns = progress*final_turns
	var index := floori(turns)
	if index != last_index:
		last_index = index
		for slot in CARD_COUNT:
			var id := String(pool[posmod(index+slot-CENTER_SLOT,pool.size())])
			icons[slot].texture = ICONS.texture(id)
			labels[slot].text = String(DATA.WEAPONS[id].name) if DATA.WEAPONS.has(id) else String(DATA.PASSIVES[id].name) if DATA.PASSIVES.has(id) else "생명의 축복"
			rank_labels[slot].text = String(ranks.get(id,""))
		displayed_id = String(pool[index%pool.size()])
	if progress >= 1.0:
		center_label.text = String(receipt.name)
		rank_labels[CENTER_SLOT].text = "MAX" if bool(receipt.get("evolution",false)) else "강화 완료" if bool(receipt.get("applied",false)) else ""
	_layout(); queue_redraw()
func _card_width() -> float:
	return maxf(1,(size.x-64)/3)
func _selection_rect() -> Rect2:
	var width := _card_width()
	return Rect2(Vector2(24+width+8,14),Vector2(width,244))
func _layout() -> void:
	var width := _card_width()
	var fraction := turns-floorf(turns)
	for index in labels.size():
		var distance := float(index-CENTER_SLOT)-fraction
		var emphasis := clampf(1.0-absf(distance),0.0,1.0)
		var x := 24+(distance+1)*(width+8)
		var top := lerpf(36.0,14.0,emphasis)
		var height := lerpf(200.0,244.0,emphasis)
		# Icon, rank and name inherit the moving card's transform.
		cards[index].position = Vector2(x,top); cards[index].size = Vector2(width,height)
		icons[index].position = Vector2(16,16); icons[index].size = Vector2(maxf(1,width-32),height-80)
		rank_labels[index].position = Vector2(12,height-100); rank_labels[index].size = Vector2(maxf(1,width-24),32)
		labels[index].position = Vector2(12,height-68); labels[index].size = Vector2(maxf(1,width-24),56)
		labels[index].modulate = Color("b1aac3").lerp(Color("ffda86"),emphasis)
		cards[index].modulate.a = lerpf(0.55,1.0,emphasis)
func _draw() -> void:
	if cards.size() < CARD_COUNT: return
	var rect := _selection_rect()
	var pulse := 0.5+0.5*sin(progress*TAU*18.0) if progress < 1.0 else 1.0
	var gold := Color("ffd776"); gold.a = 0.6+0.4*pulse
	for x in [rect.position.x-10,rect.end.x+10]:
		var center := Vector2(x,rect.get_center().y)
		draw_colored_polygon(PackedVector2Array([center+Vector2(0,-12),center+Vector2(8,0),center+Vector2(0,12),center+Vector2(-8,0)]),gold)
	for y in [rect.position.y-7,rect.end.y+7]:
		var center := Vector2(rect.get_center().x,y)
		draw_colored_polygon(PackedVector2Array([center+Vector2(0,-7),center+Vector2(5,0),center+Vector2(0,7),center+Vector2(-5,0)]),gold)
