extends Control
## Render-only mirror. No HP, collision, projectile or reward simulation.
const MONSTERS := preload("res://src/data/monster_catalog.gd")
const RULES := preload("res://src/online/match_rules.gd")
const ART := preload("res://src/data/online_presentation_catalog.gd")
const HERO_ART := preload("res://src/data/hero_presentation_catalog.gd")
const LOAD_DRAIN := preload("res://src/online/texture_load_drain.gd")
const FIELD := preload("res://src/online/battlefield_presentation.gd")
const SAMPLE := preload("res://src/online/presentation_snapshot.gd")
var battlefield
var render_visuals: Array = []
var art_textures := {}
var pending_textures: Array[String] = []
var painted_owners := {}
var texture_requests := 0
var load_drain
var state := {}
var textures := {}
var hero_texture: Texture2D
var scale_ratio := 1.0
var map_offset := Vector2.ZERO
var bounds := Vector2(3600,3600)
signal placement(point: Vector2)
func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	clip_contents = true
	set_process(false)
	load_drain = LOAD_DRAIN.new(); load_drain.paths = pending_textures; load_drain.view_ref = weakref(self)
	get_tree().root.add_child.call_deferred(load_drain)
	for id in RULES.ROSTER:
		var path := String(MONSTERS.get_monster(id).get("card_icon_path",""))
		if not path.is_empty() and ResourceLoader.exists(path): textures[id] = load(path)
	var profile := HERO_ART.get_visual_profile(RULES.HERO,"")
	var path := String(profile.get("frame_dir",""))+"/idle_01.png"
	if ResourceLoader.exists(path): hero_texture = load(path)
	resized.connect(queue_redraw)
func update_state(value: Dictionary) -> bool:
	if not RULES.point(value.get("bounds",null)) or not value.get("hero",null) is Array: return false
	if value.hero.size() != 5 or not value.get("actors",null) is Array or value.actors.size() > 216: return false
	for number in value.hero:
		if not RULES.number(number): return false
	if float(value.bounds[0]) < 500 or float(value.bounds[1]) < 500: return false
	if float(value.bounds[0]) > ART.MAX_WORLD_EXTENT or float(value.bounds[1]) > ART.MAX_WORLD_EXTENT: return false
	for actor in value.actors:
		if not actor is Array or actor.size() != 6 or not actor[1] is String or actor[1] not in RULES.ROSTER: return false
		for index in [0,2,3,4,5]:
			if not RULES.number(actor[index]): return false
	var commands: Variant = value.get("visuals",ART.EMPTY)
	if not commands is Array or commands.size() > ART.MAX_COMMANDS: return false
	for command in commands:
		if not ART.valid(command): return false
	if value.has("battlefield") and not ART.battlefield_valid(value.battlefield): return false
	if value.has("battlefield") and value.battlefield.bounds != value.bounds: return false
	if value.has("battlefield") and not prepare_battlefield(value.battlefield): return false
	state = value; bounds = Vector2(value.bounds[0],value.bounds[1])
	_merge_visuals()
	_resolve_owners(); queue_redraw(); return true
func prepare_battlefield(value: Dictionary) -> bool:
	if not ART.battlefield_valid(value): return false
	if battlefield != null and battlefield.visible and battlefield.descriptor == value: return true
	if battlefield == null: battlefield = FIELD.new(); add_child(battlefield)
	if not battlefield.prepare(value): return false
	bounds = Vector2(value.bounds[0],value.bounds[1])
	_merge_visuals(); _layout_map(); queue_redraw(); return true
func _merge_visuals() -> void:
	render_visuals.clear()
	if battlefield != null and battlefield.visible: render_visuals.append_array(battlefield.prop_commands)
	render_visuals.append_array(state.get("visuals",ART.EMPTY))
	render_visuals.sort_custom(SAMPLE.visual_order)
	for command in render_visuals: _request_texture(command[1])
func _request_texture(path: String) -> void:
	if art_textures.has(path) or art_textures.size() >= ART.MAX_TEXTURES: return
	art_textures[path] = null
	if not ResourceLoader.exists(path): return
	texture_requests += 1
	if ResourceLoader.has_cached(path):
		art_textures[path] = load(path) as Texture2D
	elif ResourceLoader.load_threaded_request(path,"Texture2D") == OK:
		pending_textures.append(path); set_process(true); load_drain.set_process(true)
func _process(_delta: float) -> void:
	var changed := false
	var index := pending_textures.size()
	while index > 0:
		index -= 1
		var path := pending_textures[index]
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS: continue
		if status == ResourceLoader.THREAD_LOAD_LOADED: art_textures[path] = ResourceLoader.load_threaded_get(path) as Texture2D
		pending_textures[index] = pending_textures[-1]; pending_textures.pop_back(); changed = true
	if changed: _resolve_owners(); queue_redraw()
	if pending_textures.is_empty(): set_process(false)
func _resolve_owners() -> void:
	painted_owners.clear()
	for command in render_visuals:
		var texture: Texture2D = art_textures.get(command[1])
		if texture != null and command[2]+command[4] <= texture.get_width() and command[3]+command[5] <= texture.get_height(): painted_owners[int(command[0])] = true
func clear_state() -> void:
	state = {}; painted_owners.clear(); render_visuals.clear()
	if battlefield != null: battlefield.visible = false
	queue_redraw()
func _exit_tree() -> void:
	if is_instance_valid(load_drain): load_drain.set_process(true)
func _draw_visuals() -> void:
	var map_transform := Transform2D(Vector2(scale_ratio,0),Vector2(0,scale_ratio),map_offset)
	for command in render_visuals:
		var texture: Texture2D = art_textures.get(command[1])
		if texture == null: continue
		var source := Rect2(command[2],command[3],command[4],command[5])
		if source.end.x > texture.get_width() or source.end.y > texture.get_height(): continue
		var pose := Transform2D(Vector2(command[6],command[7]),Vector2(command[8],command[9]),Vector2(command[10],command[11]))
		draw_set_transform_matrix(map_transform*pose)
		draw_texture_rect_region(texture,Rect2(command[12],command[13],command[14],command[15]),source,Color(command[16],command[17],command[18],command[19]))
	draw_set_transform_matrix(Transform2D.IDENTITY)
func _layout_map() -> void:
	scale_ratio = minf(size.x/bounds.x,size.y/bounds.y)
	map_offset = (size-bounds*scale_ratio)*0.5
	if battlefield != null:
		battlefield.position = map_offset; battlefield.scale = Vector2.ONE*scale_ratio
func _draw() -> void:
	_layout_map()
	if battlefield == null or not battlefield.visible:
		draw_rect(Rect2(Vector2.ZERO,size),Color("101b28"))
		draw_rect(Rect2(map_offset,bounds*scale_ratio),Color("283847"))
		for x in range(0,int(bounds.x),300): draw_line(map_offset+Vector2(x,0)*scale_ratio,map_offset+Vector2(x,bounds.y)*scale_ratio,Color("354654"))
		for y in range(0,int(bounds.y),300): draw_line(map_offset+Vector2(0,y)*scale_ratio,map_offset+Vector2(bounds.x,y)*scale_ratio,Color("354654"))
	_draw_visuals()
	if state.is_empty(): return
	var hp: Array = state.hero
	_actor(Vector2(hp[0],hp[1]),hero_texture,Color("73deff"),float(hp[2])/maxf(1,float(hp[3])),true,not painted_owners.has(0))
	for actor in state.actors: _actor(Vector2(actor[2],actor[3]),textures.get(actor[1]),Color("d56d67"),float(actor[4])/maxf(1,float(actor[5])),false,not painted_owners.has(int(actor[0])))
	for point in state.get("shots",ART.EMPTY):
		if RULES.point(point): draw_circle(map_offset+Vector2(point[0],point[1])*scale_ratio,4,Color("d6f5ff"))
func _actor(point: Vector2,texture: Texture2D,color: Color,hp: float,is_hero: bool,draw_body: bool = true) -> void:
	var screen := map_offset+point*scale_ratio
	var extent := Vector2(42,54) if is_hero else Vector2(34,40)
	if draw_body:
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
