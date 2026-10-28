extends RefCounted
## Bounded generic draw commands sampled from the authoritative weapon effects.
const DATA := preload("res://src/data/online_feedback_catalog.gd")
const GEO := preload("res://src/hero_mode/hero_weapon_geometry.gd")
const KINDS := ["circle","ring","line","polyline","polygon"]
var parsed: Array = []
static func valid(commands: Variant) -> bool:
	if not commands is Array or commands.size()>DATA.MAX_PRIMITIVES: return false
	for row in commands:
		if not row is Array or row.size()!=11 or row[0] not in KINDS or not row[10] is Array or row[10].size()>DATA.MAX_POINTS or row[10].size()%2!=0: return false
		for index in range(1,10):
			if not (row[index] is float or row[index] is int) or not is_finite(float(row[index])) or absf(float(row[index]))>1000000: return false
		for index in range(5,9):
			if row[index]<0 or row[index]>1: return false
		if row[4]<0 or row[9]<0 or row[9]>1000000: return false
		if row[0] in ["line","polyline"] and row[10].size()<4: return false
		if row[0]=="polygon" and row[10].size()<6: return false
		for value in row[10]:
			if not (value is float or value is int) or not is_finite(float(value)) or absf(float(value))>1000000: return false
	return true
func replace(commands: Array) -> void:
	parsed.clear()
	for row in commands:
		var points := PackedVector2Array()
		for index in range(0,row[10].size(),2): points.append(Vector2(row[10][index],row[10][index+1]))
		parsed.append({"kind":row[0],"pose":Transform2D(row[3],Vector2(row[1],row[2])),"radius":row[4],"color":Color(row[5],row[6],row[7],row[8]),"width":row[9],"points":points})
func draw(view: Control) -> void:
	var map := Transform2D(Vector2(view.map_scale.x,0),Vector2(0,view.map_scale.y),view.map_offset)
	for cmd in parsed:
		view.draw_set_transform_matrix(map*cmd.pose)
		match cmd.kind:
			"circle": view.draw_circle(Vector2.ZERO,cmd.radius,cmd.color)
			"ring": view.draw_arc(Vector2.ZERO,cmd.radius,0,TAU,48,cmd.color,maxf(0.1,cmd.width))
			"line","polyline": view.draw_polyline(cmd.points,cmd.color,maxf(0.1,cmd.width))
			"polygon": view.draw_colored_polygon(cmd.points,cmd.color)
	view.draw_set_transform_matrix(Transform2D.IDENTITY)
static func append(output: Array,kind: String,origin: Vector2,angle: float,radius: float,color: Color,width: float = 0,points: PackedVector2Array = PackedVector2Array()) -> void:
	if output.size()>=DATA.MAX_PRIMITIVES: return
	var wire: Array = []
	for point in points:
		if wire.size()+2>DATA.MAX_POINTS: break
		wire.append(point.x); wire.append(point.y)
	output.append([kind,origin.x,origin.y,angle,radius,clampf(color.r,0,1),clampf(color.g,0,1),clampf(color.b,0,1),clampf(color.a,0,1),width,wire])
static func line(output: Array,a: Vector2,b: Vector2,color: Color,width: float) -> void:
	append(output,"line",Vector2.ZERO,0,0,color,width,PackedVector2Array([a,b]))
static func area(output: Array,origin: Vector2,radius: float,color: Color) -> void:
	append(output,"circle",origin,0,radius,Color(color,color.a*GEO.AREA_FILL_ALPHA))
	append(output,"ring",origin,0,radius,color,GEO.OUTLINE_WIDTH)
static func capture(weapons) -> Array:
	var output: Array = []
	# A delivery slot emits at most one danger outline. Reserve these before
	# decorative fills/trails so the bounded wire never hides an active warning.
	if weapons.delivery != null: weapons.delivery.visit_visuals(_delivery_warning.bind(output))
	for field in weapons.fields:
		if field.left>0: area(output,field.origin,field.radius,field.get("color",Color.WHITE))
	for effect in weapons.effects:
		if effect.left<=0 or output.size()>=DATA.MAX_PRIMITIVES: continue
		var ratio: float = effect.left/effect.duration
		var a: Vector2 = weapons.hero.global_position if effect.get("follow",false) else effect.a
		var b: Vector2 = effect.b
		var color: Color = effect.color; color.a = ratio*GEO.EFFECT_ALPHA
		var frames: Array = effect.get("frames",DATA.EMPTY)
		match String(effect.pattern):
			"beam","slash","capsule":
				append(output,"polygon",a,(b-a).angle(),0,Color(color,ratio*GEO.SHAPE_FILL_ALPHA),0,effect.shape)
				append(output,"polyline",a,(b-a).angle(),0,color,GEO.OUTLINE_WIDTH,effect.shape)
			"combo":
				if frames.is_empty(): line(output,a,b,color,GEO.OUTLINE_WIDTH)
			"chain":
				line(output,a,b,Color(color,ratio*GEO.CHAIN_LINE_ALPHA),GEO.OUTLINE_WIDTH)
				if frames.is_empty(): line(output,a,b,color,GEO.CHAIN_FALLBACK_WIDTH)
			"bolt":
				line(output,a,b,Color(color,ratio*GEO.BOLT_LINE_ALPHA),GEO.OUTLINE_WIDTH)
				append(output,"circle",a.lerp(b,1.0-ratio),0,GEO.BOLT_RADIUS,color)
			"orbit":
				var inner := GEO.orbit_inner(effect.radius,effect.orbit_ratio,effect.get("area_scale",1.0))
				var outer := GEO.orbit_outer(effect.radius,effect.orbit_ratio,effect.get("area_scale",1.0))
				append(output,"ring",a,0,(inner+outer)*0.5,Color(color,ratio*GEO.ORBIT_FILL_ALPHA),outer-inner)
				append(output,"ring",a,0,inner,color,GEO.OUTLINE_WIDTH); append(output,"ring",a,0,outer,color,GEO.OUTLINE_WIDTH)
				if frames.is_empty():
					for index in mini(int(effect.orbit_count),DATA.MAX_PRIMITIVES-output.size()):
						var angle: float = weapons.visual_clock*effect.orbit_speed+index*TAU/effect.orbit_count
						append(output,"circle",a+Vector2.from_angle(angle)*(inner+outer)*0.5,0,GEO.orbit_texture_extent(inner,outer),color)
			_: area(output,a,effect.radius,Color(color,ratio))
	if weapons.delivery != null: weapons.delivery.visit_visuals(_delivery_visual.bind(output))
	if weapons.evolution != null: weapons.evolution.visit_visuals(_evolution_visual.bind(output))
	return output

static func _delivery_warning(_slot: Dictionary,point: Vector2,radius: float,color: Color,warning: bool,output: Array) -> void:
	if warning: append(output,"ring",point,0,radius,color,2.0)

static func _delivery_visual(_slot: Dictionary,point: Vector2,radius: float,color: Color,warning: bool,output: Array) -> void:
	if not warning: area(output,point,radius,color)

static func _evolution_visual(kind: String,point: Vector2,edge: Vector2,radius: float,color: Color,_frames: Array,progress: float,output: Array) -> void:
	match kind:
		"area": area(output,point,radius,color)
		"ring": append(output,"ring",point,0,radius,color,3.0)
		"line": line(output,point,edge,color,2.0)
		"arc":
			var points := PackedVector2Array()
			for index in 16: points.append(Vector2.from_angle(progress*index/15.0)*radius)
			append(output,"polyline",point,0,0,color,3.0,points)
