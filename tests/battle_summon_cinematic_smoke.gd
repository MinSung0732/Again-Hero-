extends SceneTree

class BattleStub extends Node2D:
	signal transcendent_summoned(id: String, actor: Node2D)
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

var failed := false
func check(ok: bool, description: String) -> void:
	if not ok:
		failed = true
		push_error(description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var host := HostStub.new()
	root.add_child(host)
	host.size = Vector2(1080, 1920)
	host.hud_layer = Control.new()
	host.add_child(host.hud_layer)
	host.battle_viewport_container = Control.new()
	host.battle_viewport_container.position = Vector2(0, 270)
	host.battle_viewport_container.size = Vector2(1080, 1174)
	host.add_child(host.battle_viewport_container)
	host.battle_viewport = SubViewport.new()
	host.battle_viewport.size = Vector2i(1080, 1174)
	host.add_child(host.battle_viewport)
	host.battle = BattleStub.new()
	host.battle_viewport.add_child(host.battle)
	var follow_parent := Node2D.new()
	follow_parent.position = Vector2(1200, 1200)
	host.battle.add_child(follow_parent)
	var original := Camera2D.new()
	original.position = Vector2(10, 20)
	original.zoom = Vector2(1.1, 1.1)
	follow_parent.add_child(original)
	original.make_current()
	await process_frame
	var cinematic = preload("res://src/ui/battle_summon_cinematic.gd").new()
	cinematic.install(host)
	var actor := ActorStub.new()
	actor.position = Vector2(1500, 1400)
	host.battle.add_child(actor)
	var original_position := original.position
	var original_zoom := original.zoom
	for locked in [true, false]:
		original.top_level = not locked
		original.make_current()
		await process_frame
		host.battle.transcendent_summoned.emit("zeus", actor)
		cinematic.set_process(false)
		check(cinematic.active, "success signal starts presentation")
		check(cinematic.view.rig.modulate.a == 1.0, "visible full-color pose at time zero")
		cinematic.view.set_time(1.65)
		check(cinematic.view.rig.scale.x > cinematic.view.base_pose_scale*3.0, "illustration face closeup")
		check(float(cinematic.view.rig.eye_material.get_shader_parameter("eye_closed")) > 0.99, "eyes closed before release")
		cinematic.view.set_time(2.35)
		check(float(cinematic.view.rig.eye_material.get_shader_parameter("eye_closed")) < 0.01, "eyes open on release")
		cinematic.view.set_time(4.2)
		check(is_equal_approx(cinematic.view.rig.scale.x,cinematic.view.base_pose_scale), "full body scale restored")
		check(cinematic.view.name_label.modulate.a > 0.99, "name after returning to full body")
		cinematic.view.set_time(0.0)
		check(cinematic.view.background.polygon.size() == 3, "triangle backdrop only")
		check(not cinematic.view.portrait_window.clip_contents, "portrait may extend left of the corner cut-in")
		check(cinematic.clip_contents, "outer battle panel still clips HUD overflow")
		check(cinematic.view.position + cinematic.view.size == cinematic.size, "flush lower right battle corner")
		for frame in range(300):
			cinematic._process(1.0 / 60.0)
			check(actor.position == Vector2(1500,1400), "presentation never moves actor")
			check(original.position == original_position and original.zoom == original_zoom, "original transform untouched")
			check(cinematic.view.rig.meshes.size() == 1, "dedicated battle cast pose")
		cinematic._process(0.02)
		check(not cinematic.active and host.battle_viewport.get_camera_2d() == original, "normal completion restores camera")
		check(original.top_level == not locked, "follow/manual mode preserved")
	check(cinematic.views.size() == 1, "view cached across summons")
	for panel_size in [Vector2(1080,1174), Vector2(720,780), Vector2(1600,900)]:
		host.battle_viewport_container.size = panel_size
		cinematic.play("zeus", actor)
		cinematic.set_process(false)
		check(Rect2(Vector2.ZERO,panel_size).encloses(Rect2(cinematic.view.position,cinematic.view.size)), "cut-in within battle panel")
		cinematic.cancel()
	cinematic.play("zeus", actor)
	cinematic.set_process(false)
	host.battle.external_pause = true
	cinematic._process(0.1)
	check(not cinematic.active, "menu interruption restores")
	host.battle.external_pause = false
	cinematic.play("zeus",actor)
	cinematic.set_process(false)
	host.battle.battle_finished.emit("done",false)
	check(not cinematic.active, "battle completion restores")
	cinematic.play("zeus",actor)
	cinematic.set_process(false)
	actor.current_hp = 0
	cinematic._process(0.1)
	check(not cinematic.active, "target death restores before node removal")
	actor.current_hp = 100
	cinematic.play("zeus",actor)
	cinematic.set_process(false)
	actor.free()
	cinematic._process(0.1)
	check(not cinematic.active, "target removal restores")
	var static_scene: Node2D = load("res://assets/art/effects/battle_summon/zeus/zeus_reassembled.tscn").instantiate()
	check(static_scene.get_child_count() == 7, "corrected supplied scene loads")
	for part in static_scene.get_children():
		check(part.position == Vector2.ZERO and part.scale == Vector2.ONE and not part.centered and part.texture.get_size() == Vector2(768,1280), "static scene exact canvas origin/scale")
	static_scene.free()
	host.queue_free()
	await process_frame
	print("BATTLE_SUMMON_CINEMATIC ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
