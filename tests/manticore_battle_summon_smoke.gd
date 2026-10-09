extends SceneTree
const PREVIEW := preload("res://src/dev/manticore_battle_summon_preview.gd")
func _initialize(): run.call_deferred()
func run():
	root.get_node("CloudStore").stop()
	root.get_node("LoginGateway").remember_session_enabled=false
	if AudioServer.get_bus_index(&"SFX")<0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count-1,&"SFX")
	var host=PREVIEW.new()
	host.size=Vector2(540,960)
	root.add_child(host)
	await process_frame
	var c=host.cinematic
	c.cancel()
	var baseline:=0.75
	Engine.time_scale=baseline
	var camera_transform=host.original.transform
	var camera_zoom=host.original.zoom
	var actor_position=host.actor.position
	for panel in [Vector2(540,650),Vector2(360,520),Vector2(900,560)]:
		host.battle_viewport_container.size=panel
		await process_frame
		host.replay()
		c.set_process(false)
		assert(c.active and c.view.corner_triangle and c.view.backdrop.polygon.size()==3)
		assert(c.view.position+c.view.size==panel)
		assert(c.view.rig.mesh.material.shader==c.view.FOCUS,"full color focus shader")
		c.advance(1.0)
		assert(is_equal_approx(Engine.time_scale,baseline*0.18))
		assert(c.camera.global_position.is_equal_approx(actor_position))
		assert(c.sound_bank.played_count>0)
		c.advance(1.3)
		assert(c.world_effect.elapsed==c.elapsed and float(c.view.eyes.get_shader_parameter("closed"))<1)
		c.advance(2.71)
		assert(not c.active and host.battle_viewport.get_camera_2d()==host.original)
		assert(Engine.time_scale==baseline and host.original.transform==camera_transform and host.original.zoom==camera_zoom)
		assert(host.actor.position==actor_position)
	assert(c.views.size()==1 and c.world_effects.size()==1 and c.sound_banks.size()==1)
	for reason in ["menu","augment","target","hide","cancel"]:
		host.replay()
		c.set_process(false)
		c.advance(1)
		var bank=c.sound_bank
		if reason=="menu":host.battle.external_pause=true
		elif reason=="augment":host.battle.demon_augment_selection_active=true
		elif reason=="target":host.actor.current_hp=0
		elif reason=="hide":host.battle_viewport_container.hide()
		else:c.cancel()
		c.advance(0.1)
		assert(not c.active and Engine.time_scale==baseline)
		for player in bank.players.values():assert(not player.playing)
		host.battle.external_pause=false
		host.battle.demon_augment_selection_active=false
		host.actor.current_hp=100
		host.battle_viewport_container.show()
	if DisplayServer.get_name()!="headless":
		host._layout()
		host.replay()
		c.set_process(false)
		for target_time in [0.8,1.8,2.5,4.25]:
			c.advance(target_time-c.elapsed)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("/tmp/manticore_summon_"+str(target_time)+".png")
	c.cancel()
	Engine.time_scale=1
	c.host = null
	host.free()
	await process_frame
	print("MANTICORE_BATTLE_SUMMON PASS: signal/camera/slow/FX/audio/cancel/reuse/aspects, no actor mutation")
	quit()
