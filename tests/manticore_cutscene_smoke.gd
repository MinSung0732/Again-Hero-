extends SceneTree
const PLAYER = preload("res://src/ui/transcendent_cutscene_player.gd")
const OVERLAY = preload("res://src/ui/gacha_reveal_overlay.gd")
const PREVIEW = preload("res://src/dev/manticore_cutscene_preview.gd")
var completed := 0
func _initialize(): run.call_deferred()
func run():
	if AudioServer.get_bus_index(&"SFX")<0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count-1,&"SFX")
	var player=PLAYER.new()
	player.theme=Theme.new()
	player.theme.default_font=load("res://assets/fonts/Galmuri11.ttf")
	root.add_child(player)
	player.finished.connect(func():completed+=1)
	player.play("manticore")
	player.set_process(false)
	assert(player._running)
	var view=player._active_view
	var node_count=view.get_child_count()
	assert(view.rig.mesh.texture.get_size()==Vector2(768,1280))
	assert(view.rig.bones.size()==8 and view.rig.bones[0].position==Vector2.ZERO)
	assert(player._impact_sound.stream is AudioStreamWAV and player._charge_sound.stream is AudioStreamWAV)
	assert(player._charge_sound.bus==&"SFX")
	var initial_vertices=view.rig.mesh.polygon
	var bone_count=view.rig.bones.size()
	for t in [0.0,0.7,1.8,3.2,4.8]:
		view.set_time(t)
		assert(view.rig.mesh.polygon==initial_vertices and view.rig.bones.size()==bone_count)
		assert(view.rig.bones[0].rotation==0.0)
	view.set_time(0.0)
	for bone in view.rig.bones:assert(is_zero_approx(bone.rotation))
	view.set_time(1.8)
	assert(absf(view.rig.bones[1].rotation)>0.001)
	assert(absf(view.rig.bones[2].rotation)>0.001)
	assert(absf(view.rig.bones[4].rotation)>0.001)
	assert(absf(view.rig.bones[6].rotation)>0.001)
	var total=view.rig.mesh.polygon.size()
	for vertex in range(total):
		var sum=0.0
		for bone in range(bone_count):sum+=view.rig.mesh.get_bone_weights(bone)[vertex]
		assert(absf(sum-1.0)<0.0001)
	player.advance(1.0)
	assert(not player._impact_played)
	assert(float(view.reveal_material.get_shader_parameter("reveal_edge"))<0)
	player.advance(0.5)
	assert(player._charge_played and not player._impact_played)
	player.advance(2.9)
	assert(player._impact_played and not player._charge_sound.playing)
	assert(view.name_label.text=="만티코어" and view.name_label.modulate.a==1)
	assert(float(view.reveal_material.get_shader_parameter("reveal_edge"))>1)
	for dimensions in [Vector2(360,800),Vector2(540,960),Vector2(1080,2400),Vector2(1280,720)]:
		view.size=dimensions
		view._layout()
		var extent=Vector2(540,960)*view.stage.scale
		assert(Rect2(Vector2.ZERO,dimensions).encloses(Rect2(view.stage.position,extent)))
		assert(view.rig.position.y+1223*view.rig.scale.y<view.name_label.position.y)
	player.advance(0.6)
	assert(completed==1 and not player.visible)
	player.play("manticore")
	player.set_process(false)
	assert(player._active_view==view and view.elapsed==0)
	player.skip()
	player.advance(5)
	assert(completed==2 and not player._impact_sound.playing and not player._charge_sound.playing)
	player.play("manticore")
	player.cancel()
	await process_frame
	assert(completed==2 and not player.visible and view.get_child_count()==node_count)
	var overlay=OVERLAY.new()
	root.add_child(overlay)
	var outcomes=PREVIEW.sample_results(true)
	var snapshot=outcomes.duplicate(true)
	for source in ["summon","pickup"]:
		for entry in outcomes:entry.source=source
		overlay.present(outcomes)
		overlay._sequence_token+=1
		overlay._show_reveal(0)
		var seen=[]
		for i in range(11):
			assert(overlay._reveal_index==i)
			if i in [1,5,9]:
				seen.append(i)
				assert(overlay._phase=="cutscene")
				overlay._cutscene.set_process(false)
				if i==5:overlay._cutscene.skip()
				else:overlay._cutscene.advance(5)
				assert(overlay._phase=="reveal")
			overlay._advance_reveal()
		assert(seen==[1,5,9] and overlay._phase=="result")
		assert(overlay._results==outcomes)
		overlay.present(outcomes)
		overlay._sequence_token+=1
		overlay._show_reveal(1)
		overlay.skip_to_results()
		assert(overlay._phase=="result" and not overlay._cutscene.visible)
	assert(snapshot.size()==outcomes.size())
	if DisplayServer.get_name()!="headless":
		overlay.hide()
		player.size=Vector2(540,960)
		player.play("manticore")
		player.set_process(false)
		for t in [0.8,2.1,2.8,4.5]:
			view.set_time(t)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("/tmp/manticore_"+str(t)+".png")
	player.cancel()
	overlay.queue_free()
	player.queue_free()
	await process_frame
	print("MANTICORE_CUTSCENE PASS: normal/skip/cancel/reuse, both result sources, three transcendent order, four aspect ratios")
	quit()
