extends RefCounted
## Sample existing render nodes at snapshot cadence. No gameplay actors on clients.
const DATA := preload("res://src/data/online_presentation_catalog.gd")
const PNG_SOURCE := preload("res://src/ui/png_texture_source.gd")
const GEOMETRY := preload("res://src/hero_mode/hero_weapon_geometry.gd")
var field_items := {}
var node_cache := {}
var texture_cache := {}
var coordinate_space := Transform2D.IDENTITY
func forget_node(instance: int) -> void:
	node_cache.erase(instance)
# Attached before Battle enters the room tree. Only direct pickup births/exits
# update this room-owned registry; no scene/group scans or gameplay mutations.
func track_field_item(node: Node) -> void:
	if not node is Node2D: return
	var script = node.get_script()
	if script == null or script.resource_path not in DATA.FIELD_ITEM_SCRIPTS: return
	var instance := node.get_instance_id()
	if field_items.has(instance): return
	field_items[instance] = weakref(node)
	node.tree_exited.connect(_forget_field_item.bind(instance),Object.CONNECT_ONE_SHOT)
func _forget_field_item(instance: int) -> void:
	field_items.erase(instance)
	forget_node(instance)
func append_field_items(output: Array) -> void:
	for instance in field_items:
		if output.size() >= DATA.MAX_COMMANDS: return
		var item = field_items[instance].get_ref()
		if not is_instance_valid(item) or item.is_queued_for_deletion(): continue
		append_tree(item,-1,output)
func append_field_item_bars(output: Array) -> void:
	var primitives := preload("res://src/online/primitive_mirror.gd")
	var bar := preload("res://src/ui/treasure_chest_bar_painter.gd")
	for instance in field_items:
		if output.size() >= primitives.DATA.MAX_PRIMITIVES: return
		var item = field_items[instance].get_ref()
		if not is_instance_valid(item) or item.is_queued_for_deletion() or not item.is_visible_in_tree(): continue
		if item.get_script().resource_path != DATA.CHEST_SCRIPT or item.destroyed_flag: continue
		for rect in [bar.BACKGROUND,bar.fill_rect(item.current_hp,item.max_hp)]:
			if not rect.has_area(): continue
			var points := PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
			for index in points.size(): points[index] = item.global_transform*points[index]
			primitives.append(output,"polygon",Vector2.ZERO,0,0,bar.BACKGROUND_COLOR if rect==bar.BACKGROUND else bar.FILL_COLOR,0,points)
func _collect(node: Node,output: Array) -> void:
	if node is AnimatedSprite2D or node is Sprite2D: output.append(weakref(node))
	for child in node.get_children(): _collect(child,output)
func _texture(texture: Texture2D) -> Array:
	if texture == null: return []
	var id := texture.get_instance_id()
	if texture_cache.has(id): return texture_cache[id].descriptor
	if texture_cache.size() >= DATA.MAX_TEXTURES: return []
	var source: Texture2D = texture
	var region := Rect2(Vector2.ZERO,texture.get_size())
	if texture is AtlasTexture:
		region = texture.region; source = texture.atlas
	if source == null or source is AtlasTexture: return []
	var path := PNG_SOURCE.path(source)
	if not DATA.path_allowed(path): return []
	var descriptor := [path,region.position.x,region.position.y,region.size.x,region.size.y]
	texture_cache[id] = {"texture":texture,"descriptor":descriptor}
	return descriptor
func append_tree(root: Node2D,owner: int,output: Array) -> void:
	if not is_instance_valid(root) or not root.is_visible_in_tree(): return
	var id := root.get_instance_id()
	if not node_cache.has(id):
		var nodes: Array = []; _collect(root,nodes); node_cache[id] = nodes
	for reference in node_cache[id]:
		if output.size() >= DATA.MAX_COMMANDS: return
		var sprite = reference.get_ref()
		if not is_instance_valid(sprite) or not sprite.is_visible_in_tree(): continue
		var texture: Texture2D
		if sprite is AnimatedSprite2D:
			if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(sprite.animation) or sprite.sprite_frames.get_frame_count(sprite.animation) <= sprite.frame: continue
			texture = sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
		else: texture = sprite.texture
		if texture == null: continue
		var rect := Rect2(sprite.offset-texture.get_size()*0.5 if sprite.centered else sprite.offset,texture.get_size())
		var transform: Transform2D = coordinate_space*sprite.global_transform
		if sprite.flip_h: transform.x = -transform.x
		if sprite.flip_v: transform.y = -transform.y
		var z: int = sprite.z_index
		var parent = sprite.get_parent()
		var relative: bool = sprite.z_as_relative
		while relative and parent is Node2D:
			z += parent.z_index; relative = parent.z_as_relative; parent = parent.get_parent()
		append_texture(texture,owner,transform,rect,sprite.modulate*sprite.self_modulate,output,z,(coordinate_space*root.global_position).y)
func append_texture(texture: Texture2D,owner: int,transform: Transform2D,rect: Rect2,color: Color,output: Array,z: int = 0,sort_y: float = NAN) -> void:
	if output.size() >= DATA.MAX_COMMANDS: return
	var source := _texture(texture)
	if source.is_empty(): return
	output.append([owner,source[0],source[1],source[2],source[3],source[4],transform.x.x,transform.x.y,transform.y.x,transform.y.y,transform.origin.x,transform.origin.y,rect.position.x,rect.position.y,rect.size.x,rect.size.y,clampf(color.r,0,1),clampf(color.g,0,1),clampf(color.b,0,1),clampf(color.a,0,1),z,transform.origin.y if is_nan(sort_y) else sort_y])
static func visual_order(a: Array,b: Array) -> bool:
	return a[20] < b[20] or (a[20] == b[20] and a[21] < b[21])
func append_weapon_areas(weapons,output: Array) -> void:
	var z: int = weapons.hero.z_index
	for field in weapons.fields:
		var frames: Array = field.get("frames",DATA.EMPTY)
		if field.left <= 0.0 or frames.is_empty(): continue
		var diameter: float = GEOMETRY.area_texture_extent(field.radius)
		var color: Color = field.get("color",Color.WHITE)
		append_texture(weapons._loop_frame(frames,weapons.visual_clock),-1,Transform2D(0.0,field.origin),Rect2(Vector2.ONE*-diameter*0.5,Vector2.ONE*diameter),Color(1,1,1,color.a*GEOMETRY.AREA_TEXTURE_ALPHA),output,z)
	for effect in weapons.effects:
		var frames: Array = effect.get("frames",DATA.EMPTY)
		if effect.left <= 0.0 or frames.is_empty(): continue
		var ratio: float = effect.left/effect.duration
		var a: Vector2 = weapons.hero.global_position if effect.get("follow",false) else effect.a
		var b: Vector2 = effect.b
		var rect: Rect2
		var pose := Transform2D(0.0,a)
		var alpha := ratio
		if effect.pattern == "chain":
			pose = Transform2D((b-a).angle(),a)
			rect = Rect2(0,-GEOMETRY.CHAIN_DRAW_WIDTH*0.5,a.distance_to(b),GEOMETRY.CHAIN_DRAW_WIDTH)
		elif effect.pattern in ["beam","slash","capsule"]:
			pose = Transform2D((b-a).angle(),a)
			rect = GEOMETRY.effect_texture_rect(effect.pattern,a.distance_to(b),effect.radius)
			if not rect.has_area(): continue
			alpha *= GEOMETRY.BEAM_TEXTURE_ALPHA
		elif effect.pattern == "combo":
			pose = Transform2D((b-a).angle(),b)
			rect = Rect2(Vector2.ONE*-float(effect.radius),Vector2.ONE*float(effect.radius)*2)
		elif effect.pattern == "orbit":
			var inner := GEOMETRY.orbit_inner(float(effect.radius),float(effect.orbit_ratio),float(effect.get("area_scale",1.0)))
			var outer := GEOMETRY.orbit_outer(float(effect.radius),float(effect.orbit_ratio),float(effect.get("area_scale",1.0)))
			var extent := GEOMETRY.orbit_texture_extent(inner,outer)
			var count: int = mini(int(effect.orbit_count),DATA.MAX_COMMANDS-output.size())
			for index in count:
				var angle: float = weapons.visual_clock*float(effect.orbit_speed)+index*TAU/float(effect.orbit_count)
				var position := a+Vector2.from_angle(angle)*(inner+outer)*0.5
				append_texture(weapons._loop_frame(frames,weapons.visual_clock),-1,Transform2D(angle+PI*0.5,position),Rect2(Vector2.ONE*-extent,Vector2.ONE*extent*2),Color(1,1,1,alpha),output,z)
			continue
		elif effect.pattern == "bolt": continue # Existing procedural bolt lines need no PNG.
		else:
			var diameter: float = GEOMETRY.area_texture_extent(effect.radius)
			rect = Rect2(Vector2.ONE*-diameter*0.5,Vector2.ONE*diameter); alpha *= GEOMETRY.AREA_TEXTURE_ALPHA
		append_texture(weapons._frame(frames,1.0-ratio),-1,pose,rect,Color(1,1,1,alpha),output,z)

	if weapons.delivery != null: weapons.delivery.visit_visuals(_append_delivery_visual.bind(weapons,output))
	if weapons.evolution != null: weapons.evolution.visit_visuals(_append_evolution_visual.bind(weapons,output))
func _append_delivery_visual(slot: Dictionary,point: Vector2,radius: float,color: Color,warning: bool,weapons,output: Array) -> void:
	var frames: Array = slot.frames
	if warning or frames.is_empty(): return
	var diameter := GEOMETRY.area_texture_extent(radius)
	append_texture(weapons._frame(frames,weapons._loop_progress(frames,weapons.delivery.clock)),-1,Transform2D(0.0,point),Rect2(Vector2.ONE*-diameter*.5,Vector2.ONE*diameter),Color(1,1,1,color.a*GEOMETRY.AREA_TEXTURE_ALPHA),output,weapons.hero.z_index)

func _append_evolution_visual(kind: String,point: Vector2,_edge: Vector2,radius: float,color: Color,frames: Array,progress: float,weapons,output: Array) -> void:
	if kind != "area" or frames.is_empty(): return
	var diameter := GEOMETRY.area_texture_extent(radius)
	append_texture(weapons._frame(frames,progress),-1,Transform2D(0.0,point),Rect2(Vector2.ONE*-diameter*.5,Vector2.ONE*diameter),Color(1,1,1,color.a*GEOMETRY.AREA_TEXTURE_ALPHA),output,weapons.hero.z_index)
