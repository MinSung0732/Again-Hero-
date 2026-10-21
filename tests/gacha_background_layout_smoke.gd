extends SceneTree
## Executes the five actual layout functions, with texture/rig adapters; no full cutscene playback.
const BG := preload("res://src/ui/cutscene_background_layout.gd")
const VIEWS := ["arthur","bulgasal","izanami","manticore","shuten_doji"]
const SIZES := [Vector2(1080,1920),Vector2(1080,2400),Vector2(720,1600),Vector2(1080,2520),Vector2(800,1280),Vector2(500,500),Vector2(1920,1080),Vector2(240,1080)]
var checks := 0
var failures := 0
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func make_view(id: String):
	# Windows checkouts use CRLF; extracted bodies must not keep stray CRs.
	var source := FileAccess.get_file_as_string("res://src/ui/"+id+"_gacha_view.gd").replace("\r","")
	var start := source.find("func _layout(")
	var end := source.find("\nfunc ",start+1)
	var method := source.substr(start,end-start if end>=0 else source.length()-start)
	var script := GDScript.new()
	script.source_code = 'extends Control\nconst BACKGROUND_LAYOUT=preload("res://src/ui/cutscene_background_layout.gd")\nvar stage: Node2D\nvar background: Sprite2D\nvar background_art: Sprite2D\nvar background_overlay: ColorRect\n'+method
	check(script.reload() == OK,"real layout compiles:"+id)
	check("resized.connect(_layout)" in source,"resize remains connected:"+id)
	return script.new()
func covers(outer: Rect2,inner: Rect2) -> bool:
	return outer.grow(0.1).encloses(inner)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var parent := Control.new()
	parent.position = Vector2(33,71)
	parent.scale = Vector2(0.65,0.65)
	root.add_child(parent)
	var image := Image.create(512,960,false,Image.FORMAT_RGBA8)
	image.fill(Color("372b58"))
	var texture := ImageTexture.create_from_image(image)
	for id in VIEWS:
		var view = make_view(id)
		parent.add_child(view)
		view.position = Vector2(23,17)
		view.stage = Node2D.new(); view.add_child(view.stage)
		var sprite := Sprite2D.new(); sprite.texture = texture
		view.stage.add_child(sprite)
		view.background = sprite; view.background_art = sprite
		view.background_overlay = ColorRect.new(); view.stage.add_child(view.background_overlay)
		for dimensions in SIZES:
			view.size = dimensions
			view._layout()
			var bounds := sprite.get_global_transform()*Rect2(-texture.get_size()*0.5,texture.get_size())
			check(covers(bounds,view.get_global_rect()),id+" environment covers:"+str(dimensions))
			check(is_equal_approx(sprite.scale.x,sprite.scale.y),id+" uniform art scale:"+str(dimensions))
			var factor := minf(dimensions.x/540.0,dimensions.y/960.0)
			check(view.stage.scale.is_equal_approx(Vector2.ONE*factor) and view.stage.position.is_equal_approx((dimensions-Vector2(540,960)*factor)*0.5),id+" character contain unchanged")
			if id == "arthur": check(covers(view.background_overlay.get_global_rect(),view.get_global_rect()),"Arthur shader covers view")
		view.size = Vector2.ZERO; view._layout()
		check(sprite.position.is_finite() and sprite.scale.is_finite(),id+" zero-size safe")
		view.size = Vector2(1080,2400); view._layout()
		check(covers(sprite.get_global_transform()*Rect2(-texture.get_size()*0.5,texture.get_size()),view.get_global_rect()),id+" reuse after zero-size")
		view.free()
	var empty := Sprite2D.new()
	BG.cover_sprite(empty,Vector2(1080,2400),Vector2.ZERO,1.0)
	check(empty.scale.is_finite(),"missing texture safe"); empty.free()
	parent.free()
	print("GACHA_BACKGROUND_LAYOUT_SMOKE checks=",checks," failures=",failures)
	quit(1 if failures else 0)
