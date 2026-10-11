extends SceneTree
const PLAYER := preload("res://src/ui/transcendent_cutscene_player.gd")
const ART := preload("res://src/data/transcendent_reveal_art_catalog.gd")
var checks := 0
var failures := 0
var completed := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("REVEAL_ART: "+message)
func run() -> void:
	root.get_node("CloudStore").stop()
	var player := PLAYER.new()
	root.add_child(player)
	player.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	player.size = Vector2(540,960)
	player.finished.connect(func(): completed += 1)
	for id in ART.ENTRIES:
		player.play(id)
		player.set_process(false)
		check(player._running, id+" dispatch")
		var view: Control = player._active_view
		var layer: Node2D = player._active_reveal_layer
		check(layer != null and layer.texture != null, id+" generated texture")
		check(layer.texture.resource_path == ART.ENTRIES[id].path, id+" own theme")
		var image: Image = layer.texture.get_image()
		check(image.get_pixel(0,0).a < 0.5, id+" transparent corner")
		check(image.get_pixel(image.get_width()/2,image.get_height()/2).a < 0.5,id+" clear center after cutout")
		var parent := layer.get_parent()
		var node_count := parent.get_child_count()
		for dimensions in [Vector2(360,800),Vector2(1080,2400),Vector2(1280,720)]:
			player.size = dimensions
			player._layout()
			player.advance(0.4)
			check(layer.scale.x > 0 and layer.scale.x == layer.scale.y,id+" uniform scale")
		player.advance(3.0)
		check(layer.elapsed > ART.ENTRIES[id].release,id+" release clock")
		player.cancel()
		check(not player.visible and player._active_reveal_layer == null,id+" cancel")
		player.play(id)
		player.set_process(false)
		check(player._active_view == view and player._active_reveal_layer == layer,id+" cached reuse")
		check(layer.elapsed == 0 and parent.get_child_count() == node_count,id+" reset/no new nodes")
		player.skip()
		check(not player.visible,id+" skip")
		player.play(id)
		player.set_process(false)
		player.advance(5)
		check(not player.visible,id+" duration ends")
	check(completed == ART.ENTRIES.size()*2,"finished once per skip/completion")
	player.play("unknown")
	check(not player._running and completed == ART.ENTRIES.size()*2+1,"unknown ID safe")
	player.free()
	var view = load("res://src/ui/arthur_battle_summon_view.gd").new()
	root.add_child(view)
	view.size = Vector2(540,960)
	view.set_time(1.5)
	check(float(view.reveal.get_shader_parameter("closed")) == 1.0,"Arthur closed phase")
	var eyes: Texture2D = view.reveal.get_shader_parameter("closed_eyes_art")
	check(eyes != null and eyes.resource_path == ART.ROOT+"arthur_closed_eyes_source.png","generated eyelid binding")
	check(not view.stage.get_child(0).visible,"battle hides rectangular cathedral")
	view.set_time(2.3)
	check(float(view.reveal.get_shader_parameter("closed")) == 0.0,"Arthur original eyes restored")
	view.free()
	await process_frame
	print("REVEAL_ART: %s (%d checks)" % ["PASS" if failures==0 else "FAIL",checks])
	quit(0 if failures==0 else 1)
