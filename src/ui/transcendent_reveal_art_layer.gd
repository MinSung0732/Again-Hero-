extends Node2D
## One retained layer per cached gacha view. No timers, particles or frame allocations.
const CATALOG := preload("res://src/data/transcendent_reveal_art_catalog.gd")
var texture: Texture2D
var tint := Color.WHITE
var release := 2.0
var elapsed := 0.0
var viewport_host: Control

func configure(monster_id: String) -> void:
	var entry: Dictionary = CATALOG.ENTRIES.get(monster_id, {})
	if entry.is_empty(): return
	tint = entry.color
	release = entry.release
	var path: String = entry.path
	# The existing player retains this layer with its view. No global strong cache
	# prolongs the image lifetime after the owning gacha player leaves the tree.
	texture = load(path) as Texture2D if ResourceLoader.exists(path) else null
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var cutout := ShaderMaterial.new()
	cutout.shader = preload("res://src/ui/transcendent_reveal_art_cutout.gdshader")
	material = cutout
	set_process(false)

func install(view: Control) -> void:
	# Stage views already have a 540x960 contain transform; Zeus draws its background
	# on the parent Control, so its layer needs that same transform explicitly.
	if "stage" in view and view.get("stage") is Node2D:
		var stage: Node2D = view.get("stage")
		stage.add_child(self)
		stage.move_child(self, 1) # Above background, below original portrait/foreground.
	else:
		viewport_host = view
		view.add_child(self)
		view.move_child(self, 0)
	refresh_layout()

func refresh_layout() -> void:
	if viewport_host != null:
		var factor := minf(viewport_host.size.x/540.0, viewport_host.size.y/960.0)
		scale = Vector2.ONE*factor
		position = (viewport_host.size-Vector2(540,960)*factor)*0.5

func set_time(seconds: float) -> void:
	elapsed = maxf(0.0, seconds)
	queue_redraw()

func _draw() -> void:
	var fade := 1.0-smoothstep(4.4,5.0,elapsed)
	if fade <= 0.0: return
	var charge := smoothstep(0.5,release,elapsed)
	var wake := smoothstep(release,release+0.25,elapsed)
	var center := Vector2(270,455)
	if texture != null:
		var side := lerpf(490.0,650.0,wake)+sin(elapsed*1.6)*5.0
		draw_set_transform(center, sin(elapsed*0.35)*0.025)
		draw_texture_rect(texture,Rect2(-Vector2.ONE*side*0.5,Vector2.ONE*side),false,
			Color(1,1,1,(charge*0.22+wake*0.62)*fade))
		draw_set_transform(Vector2.ZERO)
	# Three consecutive expanding waves, not a static badge. Theme colors preserve identity.
	for wave in range(3):
		var age := elapsed-release-float(wave)*0.18
		if age < 0.0 or age > 1.25: continue
		var alpha := (1.0-age/1.25)*fade*(0.7-float(wave)*0.12)
		var color := Color(tint,alpha)
		draw_arc(center,100.0+age*320.0,0,TAU,64,color,3.0-float(wave)*0.5,false)
		for ray in range(12):
			var direction := Vector2.UP.rotated(float(ray)*TAU/12.0)
			draw_line(center+direction*(115+age*300),center+direction*(135+age*360),color,2,false)
	for mote in range(24):
		var angle := float(mote)*TAU/24.0+elapsed*0.12
		var radius := 210.0+float(mote%4)*18.0
		var point := center+Vector2.RIGHT.rotated(angle)*radius
		var alpha := charge*fade*(0.3+0.4*maxf(0,sin(elapsed*2.0+mote)))
		draw_rect(Rect2(point,Vector2.ONE*(2.0+float(mote%2))),Color(tint,alpha))
