extends RefCounted
## Sample existing render nodes at snapshot cadence. No gameplay actors on clients.
const DATA := preload("res://src/data/online_presentation_catalog.gd")
const PNG_SOURCE := preload("res://src/ui/png_texture_source.gd")
const GEOMETRY := preload("res://src/hero_mode/hero_weapon_geometry.gd")
var node_cache := {}
var texture_cache := {}
func forget_node(instance: int) -> void:
	node_cache.erase(instance)
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
		var transform: Transform2D = sprite.global_transform
		if sprite.flip_h: transform.x = -transform.x
		if sprite.flip_v: transform.y = -transform.y
		var z: int = sprite.z_index
		var parent = sprite.get_parent()
		var relative: bool = sprite.z_as_relative
		while relative and parent is Node2D:
			z += parent.z_index; relative = parent.z_as_relative; parent = parent.get_parent()
		append_texture(texture,owner,transform,rect,sprite.modulate*sprite.self_modulate,output,z)
func append_texture(texture: Texture2D,owner: int,transform: Transform2D,rect: Rect2,color: Color,output: Array,z: int = 0) -> void:
	if output.size() >= DATA.MAX_COMMANDS: return
	var source := _texture(texture)
	if source.is_empty(): return
	output.append([owner,source[0],source[1],source[2],source[3],source[4],transform.x.x,transform.x.y,transform.y.x,transform.y.y,transform.origin.x,transform.origin.y,rect.position.x,rect.position.y,rect.size.x,rect.size.y,clampf(color.r,0,1),clampf(color.g,0,1),clampf(color.b,0,1),clampf(color.a,0,1),z])
func append_weapon_areas(weapons,output: Array) -> void:
	var z: int = weapons.hero.z_index
	for field in weapons.fields:
		var frames: Array = field.get("frames",DATA.EMPTY)
		if field.left <= 0.0 or frames.is_empty(): continue
		var diameter: float = field.radius*sqrt(2.0)
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
		elif effect.pattern in ["beam","slash","capsule","combo","bolt","orbit"]:
			continue # Their procedural/geometry presentation is a separate adapter.
		else:
			var diameter: float = effect.radius*sqrt(2.0)
			rect = Rect2(Vector2.ONE*-diameter*0.5,Vector2.ONE*diameter); alpha *= GEOMETRY.AREA_TEXTURE_ALPHA
		append_texture(weapons._frame(frames,1.0-ratio),-1,pose,rect,Color(1,1,1,alpha),output,z)
