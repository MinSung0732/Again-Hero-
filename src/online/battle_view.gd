extends Control
## Render-only mirror. No HP, collision, projectile or reward simulation.
const MONSTERS := preload("res://src/data/monster_catalog.gd")
const RULES := preload("res://src/online/match_rules.gd")
var state := {}
var textures := {}
var hero_texture: Texture2D
var scale_ratio := 1.0
var map_offset := Vector2.ZERO
var bounds := Vector2(3600,3600)
signal placement(point: Vector2)
func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for id in RULES.ROSTER:
		var path := String(MONSTERS.get_monster(id).get("card_icon_path",""))
		if not path.is_empty() and ResourceLoader.exists(path): textures[id] = load(path)
	var path := "res://assets/art/heroes/stage1_mage/frames/idle_01.png"
	if ResourceLoader.exists(path): hero_texture = load(path)
	resized.connect(queue_redraw)
func update_state(value: Dictionary) -> bool:
	if not RULES.point(value.get("bounds",null)) or not value.get("hero",null) is Array: return false
	if value.hero.size() != 5 or not value.get("actors",null) is Array or value.actors.size() > 216: return false
	for number in value.hero:
		if not RULES.number(number): return false
	if float(value.bounds[0]) < 500 or float(value.bounds[1]) < 500: return false
	for actor in value.actors:
		if not actor is Array or actor.size() != 6 or not actor[1] is String or actor[1] not in RULES.ROSTER: return false
		for index in [0,2,3,4,5]:
			if not RULES.number(actor[index]): return false
	state = value; bounds = Vector2(value.bounds[0],value.bounds[1]); queue_redraw(); return true
func _layout_map() -> void:
	scale_ratio = minf(size.x/bounds.x,size.y/bounds.y)
	map_offset = (size-bounds*scale_ratio)*0.5
func _draw() -> void:
	_layout_map()
	draw_rect(Rect2(Vector2.ZERO,size),Color("101b28"))
	draw_rect(Rect2(map_offset,bounds*scale_ratio),Color("283847"))
	for x in range(0,int(bounds.x),300): draw_line(map_offset+Vector2(x,0)*scale_ratio,map_offset+Vector2(x,bounds.y)*scale_ratio,Color("354654"))
	for y in range(0,int(bounds.y),300): draw_line(map_offset+Vector2(0,y)*scale_ratio,map_offset+Vector2(bounds.x,y)*scale_ratio,Color("354654"))
	if state.is_empty(): return
	var hp: Array = state.hero
	_actor(Vector2(hp[0],hp[1]),hero_texture,Color("73deff"),float(hp[2])/maxf(1,float(hp[3])),true)
	for actor in state.actors: _actor(Vector2(actor[2],actor[3]),textures.get(actor[1]),Color("d56d67"),float(actor[4])/maxf(1,float(actor[5])),false)
	for point in state.get("shots",[]):
		if RULES.point(point): draw_circle(map_offset+Vector2(point[0],point[1])*scale_ratio,4,Color("d6f5ff"))
func _actor(point: Vector2,texture: Texture2D,color: Color,hp: float,is_hero: bool) -> void:
	var screen := map_offset+point*scale_ratio
	var extent := Vector2(42,54) if is_hero else Vector2(34,40)
	if texture != null: draw_texture_rect(texture,Rect2(screen-extent*0.5,extent),false)
	else: draw_circle(screen,12,color)
	draw_line(screen+Vector2(-18,-32),screen+Vector2(18,-32),Color("27212c"),5)
	draw_line(screen+Vector2(-18,-32),screen+Vector2(-18+36*clampf(hp,0,1),-32),color,4)
func _gui_input(event: InputEvent) -> void:
	var point: Vector2
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: point = event.position
	elif event is InputEventScreenTouch and event.pressed: point = event.position
	else: return
	_layout_map(); point = (point-map_offset)/maxf(0.001,scale_ratio)
	if point.x >= 0 and point.y >= 0 and point.x <= bounds.x and point.y <= bounds.y: placement.emit(point)
	accept_event()
