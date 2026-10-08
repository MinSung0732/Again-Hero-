extends SceneTree

class BattleStub extends Node2D:
	signal transcendent_summoned(id: String, actor: Node2D)
	signal transcendent_died(id: String, actor: Node2D)
	signal battle_finished(message: String, won: bool)
	var battle_over := false
	var external_pause := false
	var demon_augment_selection_active := false

class ActorStub extends Node2D:
	var current_hp := 100

class HostStub extends Control:
	var hud_layer: Control
	var battle: BattleStub
	var battle_viewport: SubViewport
	var battle_viewport_container: Control
	func _end_camera_drag() -> void:
		pass

var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures+=1
		push_error("BULGASAL_PRESENTATION: "+message)
func run() -> void:
	root.size=Vector2i(540,960)
	var host := HostStub.new()
	root.add_child(host)
	host.size=Vector2(540,960)
	host.hud_layer=Control.new()
	host.add_child(host.hud_layer)
	host.battle_viewport_container=Control.new()
	host.battle_viewport_container.position=Vector2(0,110)
	host.battle_viewport_container.size=Vector2(540,650)
	host.add_child(host.battle_viewport_container)
	host.battle_viewport=SubViewport.new()
	host.battle_viewport.size=Vector2i(540,650)
	host.add_child(host.battle_viewport)
	host.battle=BattleStub.new()
	host.battle_viewport.add_child(host.battle)
	var original := Camera2D.new()
	original.position=Vector2(100,100)
	original.zoom=Vector2(0.7,0.7)
	host.battle.add_child(original)
	original.make_current()
	var actor := ActorStub.new()
	actor.position=Vector2(350,400)
	host.battle.add_child(actor)
	await process_frame
	var cinematic = preload("res://src/ui/battle_summon_cinematic.gd").new()
	cinematic.install(host)
	var original_transform := original.transform
	var original_zoom := original.zoom
	Engine.time_scale=0.75
	for panel_size in [Vector2(540,650),Vector2(360,520),Vector2(900,560)]:
		host.battle_viewport_container.size=panel_size
		cinematic.play("bulgasal",actor)
		cinematic.set_process(false)
		check(cinematic.active and cinematic.view.corner_triangle,"registered corner cut-in")
		check(cinematic.view.backdrop.polygon.size()==3,"triangular backdrop")
		check(cinematic.view.position+cinematic.view.size==panel_size,"flush lower right")
		cinematic.view.set_time(1.5)
		check(float(cinematic.view.expression.get_shader_parameter("eye_closed"))==1.0,"closed eye after silhouette revealed")
		check(float(cinematic.view.expression.get_shader_parameter("reveal_edge"))>1.0,"black silhouette fully reveals")
		cinematic.view.set_time(2.0)
		check(float(cinematic.view.expression.get_shader_parameter("eye_closed"))==0.0,"eyes snap open")
		cinematic.view.set_time(3)
		check(cinematic.view.name_label.modulate.a==1.0 and cinematic.view.name_label.text=="불가살","name only")
		cinematic.advance(1)
		check(is_equal_approx(Engine.time_scale,0.75*0.18),"slow motion independent of clock")
		cinematic.advance(4.01)
		check(not cinematic.active and host.battle_viewport.get_camera_2d()==original,"normal return restores camera")
		check(is_equal_approx(Engine.time_scale,0.75) and original.transform==original_transform and original.zoom==original_zoom,"speed and camera exact restoration")
		check(actor.position==Vector2(350,400),"actor never moved by cinematic")
	for reason in ["menu","augment","death","cancel"]:
		cinematic.play("bulgasal",actor)
		cinematic.set_process(false)
		cinematic.advance(1)
		if reason=="menu":host.battle.external_pause=true
		elif reason=="augment":host.battle.demon_augment_selection_active=true
		elif reason=="death":actor.current_hp=0
		else:cinematic.cancel()
		cinematic.advance(0.1)
		check(not cinematic.active and is_equal_approx(Engine.time_scale,0.75),"interruption restores speed: "+reason)
		host.battle.external_pause=false
		host.battle.demon_augment_selection_active=false
		actor.current_hp=100
	check(cinematic.views.size()==2,"one cached view per transcendent")
	Engine.time_scale=1.0
	host.battle_viewport_container.size=Vector2(540,650)
	cinematic.play("bulgasal",actor)
	cinematic.set_process(false)
	if DisplayServer.get_name()!="headless":
		for seconds in [0.8,1.5,2.0,3.5]:
			cinematic.view.set_time(seconds)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("/tmp/bulgasal_battle_"+str(seconds)+".png")
	cinematic.cancel()
	host.queue_free()
	await process_frame
	await process_frame
	print("BULGASAL_PRESENTATION: ","PASS" if failures==0 else "FAIL"," failures=",failures)
	quit(0 if failures==0 else 1)
