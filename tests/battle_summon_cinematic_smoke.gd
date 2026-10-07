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

class SimulationProbe extends Node:
	var seconds := 0.0
	func _physics_process(delta: float) -> void:
		seconds += delta

var failed := false
func check(ok: bool, description: String) -> void:
	if not ok:
		failed = true
		push_error(description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var saved_scale := Engine.time_scale
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
		var baseline := 1.0 if locked else 0.75
		Engine.time_scale = baseline
		original.top_level = not locked
		original.make_current()
		await process_frame
		host.battle.transcendent_summoned.emit("zeus", actor)
		cinematic.set_process(false)
		check(cinematic.active, "success signal starts presentation")
		var audio = cinematic.sound_bank
		var audio_start: int = audio.played_count
		check(cinematic.next_audio_cue == 1 and audio.players.charge.playing, "summon starts real-time charge cue")
		cinematic.elapsed = 1.9
		cinematic._advance_audio()
		check(audio.played_count == audio_start+1 and not audio.players.charge.playing, "first radial lightning releases sound and stops charge")
		cinematic.elapsed = 2.26
		cinematic._advance_audio()
		check(audio.played_count == audio_start+3, "all three radial bursts have cues")
		cinematic._advance_audio()
		check(audio.played_count == audio_start+3, "timeline cues never repeat on redraw")
		cinematic.elapsed = 0.0
		check(cinematic.world_effect.frames.size() == 4, "PNG lightning frames cached once")
		check(int(cinematic.world_effect.CONFIG.rays) == 8 and cinematic.world_effect.CONFIG.bursts.size() == 3, "eight directions with three bursts")
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
			cinematic.advance(1.0 / 60.0)
			if frame == 59:
				check(is_equal_approx(Engine.time_scale, baseline * 0.18), "camera approach reaches slow motion")
			if frame == 140:
				check(cinematic.world_effect.burst_strength(0.08) > 0.99, "burst peaks before recovery")
				var projected := host.battle_viewport.get_canvas_transform() * actor.global_position
				var expected: Vector2 = projected / Vector2(host.battle_viewport.size) * cinematic.size
				check(cinematic.world_effect.position.is_equal_approx(expected), "radial lightning follows the real actor")
			if frame == 209:
				check(is_equal_approx(Engine.time_scale, baseline), "speed recovered after lightning")
			check(actor.position == Vector2(1500,1400), "presentation never moves actor")
			check(original.position == original_position and original.zoom == original_zoom, "original transform untouched")
			check(cinematic.view.rig.meshes.size() == 1, "dedicated battle cast pose")
		cinematic.advance(0.02)
		check(not cinematic.active and host.battle_viewport.get_camera_2d() == original, "normal completion restores camera")
		check(original.top_level == not locked, "follow/manual mode preserved")
		check(is_equal_approx(Engine.time_scale, baseline), "normal end restores prior speed")
	check(cinematic.views.size() == 1, "view cached across summons")
	check(cinematic.world_effects.size() == 1, "radial effect reused across summons")
	Engine.time_scale = saved_scale
	for panel_size in [Vector2(1080,1174), Vector2(720,780), Vector2(1600,900)]:
		host.battle_viewport_container.size = panel_size
		cinematic.play("zeus", actor)
		cinematic.set_process(false)
		check(Rect2(Vector2.ZERO,panel_size).encloses(Rect2(cinematic.view.position,cinematic.view.size)), "cut-in within battle panel")
		cinematic.advance(1.0)
		cinematic.cancel()
		check(is_equal_approx(Engine.time_scale, saved_scale), "cancel restores speed across panel ratios")
	cinematic.play("zeus", actor)
	cinematic.set_process(false)
	cinematic.advance(1.0)
	check(Engine.time_scale < saved_scale, "interruption begins while slowed")
	host.battle.external_pause = true
	cinematic.advance(0.1)
	check(not cinematic.active, "menu interruption restores")
	check(is_equal_approx(Engine.time_scale, saved_scale), "interruption restores speed")
	host.battle.external_pause = false
	cinematic.play("zeus",actor)
	cinematic.set_process(false)
	cinematic.advance(1.0)
	check(Engine.time_scale < saved_scale, "interruption begins while slowed")
	host.battle.battle_finished.emit("done",false)
	check(not cinematic.active, "battle completion restores")
	check(is_equal_approx(Engine.time_scale, saved_scale), "interruption restores speed")
	cinematic.play("zeus",actor)
	cinematic.set_process(false)
	cinematic.advance(1.0)
	check(Engine.time_scale < saved_scale, "interruption begins while slowed")
	actor.current_hp = 0
	cinematic.advance(0.1)
	check(not cinematic.active, "target death restores before node removal")
	check(is_equal_approx(Engine.time_scale, saved_scale), "interruption restores speed")
	actor.current_hp = 100
	cinematic.play("zeus",actor)
	cinematic.set_process(false)
	cinematic.advance(1.0)
	check(Engine.time_scale < saved_scale, "interruption begins while slowed")
	# Restore target first and verify the actual monotonic process clock with scaled physics.
	cinematic.cancel()
	Engine.time_scale = 1.0
	var saved_fps := Engine.max_fps
	Engine.max_fps = 60
	var probe := SimulationProbe.new()
	host.battle.add_child(probe)
	cinematic.play("zeus", actor)
	var begin := Time.get_ticks_usec()
	while cinematic.active and Time.get_ticks_usec() - begin < 6500000:
		await process_frame
	var real_seconds := float(Time.get_ticks_usec() - begin) / 1000000.0
	check(not cinematic.active and real_seconds >= 4.8 and real_seconds < 6.0, "five real seconds independent of slow physics")
	check(probe.seconds > 1.0 and probe.seconds < 4.3, "physics simulation actually advances more slowly")
	check(is_equal_approx(Engine.time_scale, 1.0), "real-clock completion restores speed")
	Engine.max_fps = saved_fps
	Engine.time_scale = saved_scale
	cinematic.play("zeus", actor)
	cinematic.set_process(false)
	cinematic.advance(1.0)
	get_tree_pause_check(cinematic, saved_scale)
	cinematic.play("zeus", actor)
	cinematic.set_process(false)
	cinematic.advance(1.0)
	cinematic._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(not cinematic.active and is_equal_approx(Engine.time_scale, saved_scale), "mobile suspension restores speed")
	cinematic.play("zeus", actor)
	cinematic.set_process(false)
	cinematic.advance(1.0)
	actor.free()
	cinematic.advance(0.1)
	check(not cinematic.active, "target removal restores")
	check(is_equal_approx(Engine.time_scale, saved_scale), "interruption restores speed")
	var static_scene: Node2D = load("res://assets/art/effects/battle_summon/zeus/zeus_reassembled.tscn").instantiate()
	check(static_scene.get_child_count() == 7, "corrected supplied scene loads")
	for part in static_scene.get_children():
		check(part.position == Vector2.ZERO and part.scale == Vector2.ONE and not part.centered and part.texture.get_size() == Vector2(768,1280), "static scene exact canvas origin/scale")
	static_scene.free()
	var exit_actor := ActorStub.new()
	host.battle.add_child(exit_actor)
	cinematic.play("zeus", exit_actor)
	cinematic.set_process(false)
	cinematic.advance(1.0)
	host.queue_free()
	await process_frame
	check(is_equal_approx(Engine.time_scale, saved_scale), "scene exit restores speed")
	print("BATTLE_SUMMON_CINEMATIC ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)

func get_tree_pause_check(cinematic: Control, expected_scale: float) -> void:
	paused = true
	cinematic.advance(0.01)
	check(not cinematic.active and is_equal_approx(Engine.time_scale, expected_scale), "tree pause restores speed")
	paused = false
