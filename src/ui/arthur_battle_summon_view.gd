extends "res://src/ui/arthur_gacha_view.gd"
var corner_triangle := true
var backdrop: Polygon2D
func _ready() -> void:
	super._ready()
	stage.get_child(0).visible = false
	backdrop = Polygon2D.new()
	backdrop.z_index = -3
	backdrop.texture = background_art.texture
	backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(backdrop)
	_layout()
func _layout() -> void:
	super._layout()
	if backdrop==null or size.x<=0 or size.y<=0: return
	backdrop.polygon = PackedVector2Array([Vector2(size.x,0),size,Vector2(0,size.y)])
	# Polygon2D uses pixel UVs: cover the panel without stretching the cathedral.
	var texture_size := backdrop.texture.get_size()
	var cover := maxf(size.x/texture_size.x,size.y/texture_size.y)
	var extent := size/cover
	var origin := (texture_size-extent)*0.5
	backdrop.uv = PackedVector2Array([origin+Vector2(extent.x,0),origin+extent,origin+Vector2(0,extent.y)])
func set_time(seconds: float) -> void:
	super.set_time(seconds)
	if backdrop != null: backdrop.modulate = background_art.modulate
	var focus := smoothstep(0.65,1.5,seconds)*(1-smoothstep(2.55,3.7,seconds))
	var factor := 0.88*(1+1.65*focus)
	var full := Vector2(300,850)-Vector2(380,1192)*factor
	var face := Vector2(320,400)-Vector2(358,350)*factor
	rig.scale = Vector2.ONE*factor
	rig.position = full.lerp(face,focus)
	reveal.set_shader_parameter("revealed",1.0)
	reveal.set_shader_parameter("closed",smoothstep(0.25,0.5,seconds)*(1-smoothstep(1.95,2.2,seconds)))
