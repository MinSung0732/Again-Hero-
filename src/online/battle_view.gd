extends Control
## Render-only mirror. No HP, collision, projectile or reward simulation.
const MONSTERS := preload("res://src/data/monster_catalog.gd")
const RULES := preload("res://src/online/match_rules.gd")
const ART := preload("res://src/data/online_presentation_catalog.gd")
const HERO_ART := preload("res://src/data/hero_presentation_catalog.gd")
const LOAD_DRAIN := preload("res://src/online/texture_load_drain.gd")
const FIELD := preload("res://src/online/battlefield_presentation.gd")
const SAMPLE := preload("res://src/online/presentation_snapshot.gd")
const FEEDBACK_DATA := preload("res://src/data/online_feedback_catalog.gd")
const PRIMITIVES := preload("res://src/online/primitive_mirror.gd")
const CAMERA_VIEW := preload("res://src/ui/battle_camera_view.gd")
const BARS := preload("res://src/ui/battle_bar_painter.gd")
var motion = preload("res://src/online/actor_motion.gd").new()
var visual_order: Array[int] = []
var visual_slots := PackedInt32Array()
var visual_depths := PackedFloat64Array()
var display_sort := Callable(self,"_display_before")
var actor_ids := {}
var motion_paused := false
var motion_received_us := 0
var primitives = PRIMITIVES.new()
var feedback
var battlefield
var render_visuals: Array = []
var art_textures := {}
var pending_textures: Array[String] = []
var painted_owners := {}
var texture_requests := 0
var load_drain
var state := {}
var textures := {}
var allowed_actor_ids: Array = RULES.ROSTER.duplicate()
var reveal_on_sight := false
var hero_texture: Texture2D
var scale_ratio := 1.0
var map_scale := Vector2.ONE
var map_offset := Vector2.ZERO
var bounds := Vector2(3600,3600)
var hero_role := true
var camera_view_locked := true
var manual_center := Vector2.ZERO
var drag_pointer := -1
var drag_distance := 0.0
const DRAG_THRESHOLD := 12.0
signal placement(point: Vector2)
func set_match_roster(roster: Array,transcendence_id: String = "") -> void:
	allowed_actor_ids = roster.duplicate()
	if not transcendence_id.is_empty(): allowed_actor_ids.append(transcendence_id)
	# The hero never receives the demon roster; monsters are admitted as they appear on the field.
	reveal_on_sight = allowed_actor_ids.is_empty()
	for id in allowed_actor_ids: _load_actor_texture(String(id))
func _load_actor_texture(id: String) -> void:
	if textures.has(id): return
	var path := String(MONSTERS.get_monster(id).get("card_icon_path",""))
	if not path.is_empty() and ResourceLoader.exists(path): textures[id] = load(path)
func _admit_sighted_actor(id: String) -> bool:
	if not reveal_on_sight or MONSTERS.get_monster(id).is_empty(): return false
	allowed_actor_ids.append(id); _load_actor_texture(id)
	return true
func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	clip_contents = true
	set_process(false)
	feedback = preload("res://src/online/combat_feedback.gd").new(); add_child(feedback)
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
	if not PRIMITIVES.valid(value.get("primitives",ART.EMPTY)): return false
	if value.has("feedback") and not FEEDBACK_DATA.valid_events(value.feedback,value.get("feedback_cursor",null),value.get("tick",null)): return false
	if not RULES.point(value.get("bounds",null)) or not value.get("hero",null) is Array: return false
	if value.hero.size() != 6 or not value.get("actors",null) is Array or value.actors.size() > ART.MAX_ACTORS: return false
	for index in 5:
		if not RULES.number(value.hero[index]): return false
	if not BARS.valid_hero_bars(value.hero[5]) or not value.get("hero_archetype",null) is String: return false
	if float(value.bounds[0]) < 500 or float(value.bounds[1]) < 500: return false
	if float(value.bounds[0]) > ART.MAX_WORLD_EXTENT or float(value.bounds[1]) > ART.MAX_WORLD_EXTENT: return false
	actor_ids.clear()
	for actor in value.actors:
		if not actor is Array or actor.size() != 7 or not actor[1] is String or not BARS.valid_monster_bars(actor[6]): return false
		if actor[1] not in allowed_actor_ids and not _admit_sighted_actor(actor[1]): return false
		for index in [0,2,3,4,5]:
			if not RULES.number(actor[index]): return false
		var id := int(actor[0])
		if id <= 0 or float(id) != float(actor[0]) or actor_ids.has(id): return false
		actor_ids[id] = true
	var commands: Variant = value.get("visuals",ART.EMPTY)
	if not value.get("shots",ART.EMPTY) is Array: return false
	for shot in value.get("shots",ART.EMPTY):
		if not shot is Array or shot.size()!=7 or not RULES.number(shot[0]) or not RULES.number(shot[1]) or not RULES.number(shot[2]) or shot[2]<=0 or shot[2]>256: return false
		for channel in range(3,7):
			if not RULES.number(shot[channel]) or shot[channel]<0 or shot[channel]>1: return false
	if not commands is Array or commands.size() > ART.MAX_COMMANDS: return false
	for command in commands:
		if not ART.valid(command): return false
	if value.has("battlefield") and not ART.battlefield_valid(value.battlefield): return false
	if value.has("battlefield") and value.battlefield.bounds != value.bounds: return false
	if value.has("battlefield") and not prepare_battlefield(value.battlefield): return false
	primitives.replace(value.get("primitives",ART.EMPTY))
	if not motion_paused:
		var now := Time.get_ticks_usec()
		if motion_received_us > 0 and now-motion_received_us >= int(ART.MOTION_RESET_SECONDS*1000000.0): motion.clear()
		motion.replace(value.hero,value.actors); motion_received_us = now
		if motion.active: set_process(true)
	if state.is_empty() and not hero_role and not camera_view_locked:
		manual_center = Vector2(value.hero[0],value.hero[1])
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
func prepare_battlefield_async(value: Dictionary,current: Callable,progress: Callable) -> bool:
	if not ART.battlefield_valid(value): return false
	if battlefield == null: battlefield = FIELD.new(); add_child(battlefield)
	if not await battlefield.prepare_async(value,current,progress): return false
	if not current.is_valid() or not current.call(): return false
	bounds = Vector2(value.bounds[0],value.bounds[1])
	_merge_visuals(); _layout_map(); queue_redraw(); return true
func _merge_visuals() -> void:
	render_visuals.clear()
	if battlefield != null and battlefield.visible: render_visuals.append_array(battlefield.prop_commands)
	render_visuals.append_array(state.get("visuals",ART.EMPTY))
	render_visuals.sort_custom(SAMPLE.visual_order)
	visual_order.resize(render_visuals.size()); visual_slots.resize(render_visuals.size()); visual_depths.resize(render_visuals.size())
	for index in render_visuals.size():
		visual_order[index] = index
		visual_slots[index] = motion.slots.get(int(render_visuals[index][0]),-1)
	_sort_display_depth(true)
	for command in render_visuals: _request_texture(command[1])
func _sort_display_depth(force_sort: bool = false) -> void:
	var changed := force_sort
	for index in render_visuals.size():
		var slot := visual_slots[index]
		var depth: float = float(render_visuals[index][21])+(motion.offsets[slot].y if slot >= 0 else 0.0)
		if visual_depths[index] != depth: changed = true; visual_depths[index] = depth
	if changed: visual_order.sort_custom(display_sort)
func _display_before(a: int,b: int) -> bool:
	var az: float = render_visuals[a][20]; var bz: float = render_visuals[b][20]
	if az != bz: return az < bz
	if visual_depths[a] != visual_depths[b]: return visual_depths[a] < visual_depths[b]
	return a < b
func pause_motion() -> void:
	motion_paused = true
	set_process(not pending_textures.is_empty())
	# Freeze the displayed point; the first resumed state establishes a new baseline.
func resume_motion() -> void:
	motion.clear(); motion_paused = false; motion_received_us = 0
	visual_slots.fill(-1)
func _request_texture(path: String) -> void:
	if art_textures.has(path) or art_textures.size() >= ART.MAX_TEXTURES: return
	art_textures[path] = null
	if not ResourceLoader.exists(path): return
	texture_requests += 1
	if ResourceLoader.has_cached(path):
		art_textures[path] = load(path) as Texture2D
	elif ResourceLoader.load_threaded_request(path,"Texture2D") == OK:
		pending_textures.append(path); set_process(true); load_drain.set_process(true)
func _process(delta: float) -> void:
	advance_motion(delta)
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
	if pending_textures.is_empty() and (motion_paused or not motion.active): set_process(false)
func advance_motion(delta: float) -> void:
	if motion_paused or not motion.advance(delta): return
	_sort_display_depth(); queue_redraw()
func _resolve_owners() -> void:
	painted_owners.clear()
	for command in render_visuals:
		var texture: Texture2D = art_textures.get(command[1])
		if texture != null and command[2]+command[4] <= texture.get_width() and command[3]+command[5] <= texture.get_height(): painted_owners[int(command[0])] = true
func clear_state() -> void:
	state = {}; painted_owners.clear(); render_visuals.clear()
	manual_center = bounds*0.5; drag_pointer = -1
	visual_order.clear(); visual_slots.clear(); visual_depths.clear(); actor_ids.clear(); resume_motion()
	if feedback != null: feedback.reset()
	primitives.parsed.clear()
	if battlefield != null: battlefield.visible = false
	queue_redraw()
func _exit_tree() -> void:
	if is_instance_valid(load_drain): load_drain.set_process(true)
func _draw_visuals() -> void:
	var map_transform := Transform2D(Vector2(map_scale.x,0),Vector2(0,map_scale.y),map_offset)
	for index in visual_order:
		var command: Array = render_visuals[index]
		var texture: Texture2D = art_textures.get(command[1])
		if texture == null: continue
		var source := Rect2(command[2],command[3],command[4],command[5])
		if source.end.x > texture.get_width() or source.end.y > texture.get_height(): continue
		var pose := Transform2D(Vector2(command[6],command[7]),Vector2(command[8],command[9]),Vector2(command[10],command[11]))
		var slot := visual_slots[index]
		if slot >= 0: pose.origin += motion.offsets[slot]
		draw_set_transform_matrix(map_transform*pose)
		draw_texture_rect_region(texture,Rect2(command[12],command[13],command[14],command[15]),source,Color(command[16],command[17],command[18],command[19]))
	draw_set_transform_matrix(Transform2D.IDENTITY)
func _layout_map() -> void:
	var solo_size: Vector2 = CAMERA_VIEW.viewport_size(hero_role)
	map_scale = Vector2(size.x/solo_size.x,size.y/solo_size.y)
	scale_ratio = map_scale.x
	var hero_point := Vector2(bounds.x*0.5,bounds.y*0.5)
	if state.get("hero",null) is Array and state.hero.size() >= 2:
		hero_point = motion.position(0,Vector2(state.hero[0],state.hero[1]))
	if not hero_role and not camera_view_locked:
		hero_point = manual_center
	else:
		manual_center = hero_point
	var half_view := solo_size*0.5
	hero_point.x = clampf(hero_point.x,half_view.x,bounds.x-half_view.x) if bounds.x >= solo_size.x else bounds.x*0.5
	hero_point.y = clampf(hero_point.y,half_view.y,bounds.y-half_view.y) if bounds.y >= solo_size.y else bounds.y*0.5
	if not hero_role and not camera_view_locked: manual_center = hero_point
	map_offset = size*0.5-hero_point*map_scale
	if battlefield != null:
		battlefield.position = map_offset; battlefield.scale = map_scale

func set_camera_view_locked(locked: bool) -> void:
	_layout_map()
	camera_view_locked = locked or hero_role
	manual_center = (size*0.5-map_offset)/map_scale
	queue_redraw()

func pan_camera_by_screen_delta(screen_delta: Vector2) -> void:
	if hero_role or camera_view_locked or screen_delta.length_squared() <= 0.001: return
	manual_center -= screen_delta/map_scale
	_layout_map(); queue_redraw()
func _draw() -> void:
	_layout_map()
	if battlefield == null or not battlefield.visible:
		draw_rect(Rect2(map_offset,bounds*map_scale),Color("283847"))
		for x in range(0,int(bounds.x),300): draw_line(map_offset+Vector2(x,0)*map_scale,map_offset+Vector2(x,bounds.y)*map_scale,Color("354654"))
		for y in range(0,int(bounds.y),300): draw_line(map_offset+Vector2(0,y)*map_scale,map_offset+Vector2(bounds.x,y)*map_scale,Color("354654"))
	primitives.draw(self)
	_draw_visuals()
	if state.is_empty(): return
	var hp: Array = state.hero
	var hero_point: Vector2 = motion.position(0,Vector2(hp[0],hp[1]))
	_actor(hero_point,hero_texture,Color("73deff"),true,not painted_owners.has(0))
	_draw_hero_bars(hero_point,hp[5],String(state.hero_archetype))
	for actor in state.actors:
		var point: Vector2 = motion.position(int(actor[0]),Vector2(actor[2],actor[3]))
		_actor(point,textures.get(actor[1]),Color("d56d67"),false,not painted_owners.has(int(actor[0])))
		_draw_monster_bars(point,actor[6])
	for shot in state.get("shots",ART.EMPTY):
		var center := map_offset+Vector2(shot[0],shot[1])*map_scale
		draw_circle(center,float(shot[2])*scale_ratio,Color(shot[3],shot[4],shot[5],shot[6]))
		draw_circle(center,7.0*scale_ratio,Color.WHITE)
func _actor(point: Vector2,texture: Texture2D,color: Color,is_hero: bool,draw_body: bool = true) -> void:
	var screen := map_offset+point*map_scale
	var extent := Vector2(42,54) if is_hero else Vector2(34,40)
	if draw_body:
		if texture != null: draw_texture_rect(texture,Rect2(screen-extent*0.5,extent),false)
		else: draw_circle(screen,12,color)
func _bar_transform(point: Vector2) -> void:
	draw_set_transform_matrix(Transform2D(Vector2(map_scale.x,0),Vector2(0,map_scale.y),map_offset+point*map_scale))
func _draw_hero_bars(point: Vector2,bars: Array,archetype: String) -> void:
	_bar_transform(point)
	var layout: Vector4 = HERO_ART.get_status_layout(archetype)
	var left := -HERO_ART.STATUS_BAR_WIDTH*0.5+layout.x
	var rule: Dictionary = HERO_ART.get_status_resource(archetype)
	if int(bars[2]) == 1:
		if int(bars[4]) > 0: BARS.draw_hero_cells(self,float(bars[5]),int(bars[4]),int(bars[3]),rule["color"])
	else:
		BARS.draw_hero_resource(self,left if bool(rule["use_x_offset"]) else -HERO_ART.STATUS_BAR_WIDTH*0.5,float(bars[5]),float(bars[3])/255.0,rule["color"])
	BARS.draw_hero_hp(self,left,float(bars[6]),float(bars[0])/255.0)
	if int(bars[1]) > 0: BARS.draw_hero_shield(self,left,float(bars[7]),float(bars[1])/255.0)
	draw_set_transform_matrix(Transform2D.IDENTITY)
func _draw_monster_bars(point: Vector2,bars: Array) -> void:
	_bar_transform(point)
	var y := float(bars[2])
	var scale_x := float(bars[3])/100.0
	var scale_y := float(bars[4])/100.0
	BARS.draw_monster_bar(self,y,float(bars[0])/255.0,BARS.MONSTER_HP,scale_x,scale_y)
	if int(bars[1]) >= 0: BARS.draw_monster_bar(self,y+BARS.MONSTER_STEP/scale_y,float(bars[1])/255.0,BARS.MONSTER_YELLOW,scale_x,scale_y,true)
	for index in range(5,bars.size(),2):
		BARS.draw_monster_bar(self,y-BARS.MONSTER_STEP/scale_y*float((index-5)/2+1),float(bars[index+1])/255.0,BARS.SHIELD_COLORS[BARS.SHIELD_KINDS[int(bars[index])]],scale_x,scale_y)
	draw_set_transform_matrix(Transform2D.IDENTITY)
func _gui_input(event: InputEvent) -> void:
	var point: Vector2
	var pointer := -2
	if event is InputEventScreenTouch: pointer = event.index
	if event is InputEventScreenDrag and pointer == drag_pointer:
		drag_distance += event.relative.length()
		pan_camera_by_screen_delta(event.relative); accept_event(); return
	if event is InputEventMouseMotion and drag_pointer == -2 and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		drag_distance += event.relative.length()
		pan_camera_by_screen_delta(event.relative); accept_event(); return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT: point = event.position
	elif event is InputEventScreenTouch: point = event.position
	else: return
	if not hero_role and not camera_view_locked:
		if event.pressed:
			drag_pointer = pointer; drag_distance = 0.0; accept_event(); return
		if pointer != drag_pointer: return
		drag_pointer = -1
		if drag_distance >= DRAG_THRESHOLD: accept_event(); return
	elif not event.pressed: return
	_layout_map(); point = (point-map_offset)/map_scale
	if point.x >= 0 and point.y >= 0 and point.x <= bounds.x and point.y <= bounds.y: placement.emit(point)
	accept_event()
