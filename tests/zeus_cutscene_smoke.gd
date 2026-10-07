extends SceneTree

const OVERLAY := preload("res://src/ui/gacha_reveal_overlay.gd")
const PLAYER := preload("res://src/ui/transcendent_cutscene_player.gd")
const EFFECT_LAYER := preload("res://src/ui/transcendent_cutscene_effect_layer.gd")
const CATALOG := preload("res://src/data/transcendent_cutscene_catalog.gd")
const PREVIEW := preload("res://src/dev/zeus_cutscene_preview.gd")
const COLLECTION := preload("res://src/systems/monster_collection_store.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
var _completed := 0

func _initialize() -> void:
	_run.call_deferred()

func _wait_ready(player: Control) -> void:
	for tick in range(600):
		if player._running:
			return
		await process_frame
	assert(false, "cutscene loading timeout")

func _run() -> void:
	var player = PLAYER.new()
	root.add_child(player)
	player.finished.connect(func(): _completed += 1)
	player.play("zeus")
	await _wait_ready(player)
	assert(player._impact_sound.stream is AudioStreamWAV and player._impact_sound.bus == &"SFX", "Zeus reveal uses imported lightning on SFX")
	player.set_process(false)
	player.advance(4.15)
	var active: Control = player._active_view
	assert(active != null and not active.is_processing() and not active.is_processing_input())
	assert(not player._name_label.visible and not player._effects.visible)
	assert(active.name_label.text == "제우스" and active.name_label.modulate.a == 1.0)
	assert(active.name_label.get_theme_font_size("font_size") >= 18)
	assert(active.reveal_material.get_shader_parameter("reveal_edge") > 1.0)
	assert(player._impact_played)
	for dimensions in [Vector2(32, 256), Vector2(400, 60), Vector2(128, 128)]:
		var box := Rect2(20, 30, 300, 900)
		var fitted := EFFECT_LAYER.fitted_rect(dimensions, box)
		assert(box.encloses(fitted))
		assert(is_equal_approx(fitted.size.x / fitted.size.y, dimensions.x / dimensions.y))
	player.advance(0.85)
	assert(_completed == 1 and not player.visible)
	player.play("zeus")
	await _wait_ready(player)
	assert(player._active_view == active and player._views.size() == 1)
	assert(active.elapsed == 0.0 and active.rig.modulate.a == 0.0)
	player.advance(1.0)
	assert(is_equal_approx(float(active.reveal_material.get_shader_parameter("reveal_edge")), -0.08))
	assert(not player._impact_played)
	player.advance(1.5)
	assert(player._impact_played)
	player.skip()
	assert(not player._impact_sound.playing and not active.visible)
	player.advance(5.0)
	assert(_completed == 2 and not player.visible)
	# Cancellation during asynchronous loading must not resurrect the player.
	player.play("zeus")
	player.cancel()
	await process_frame
	assert(not player.visible and not player._running)
	# Exercise the production _process clock for a real five-second completion too.
	player.play("zeus")
	await _wait_ready(player)
	var started := Time.get_ticks_msec()
	await player.finished
	assert(Time.get_ticks_msec() - started >= 4900)
	assert(_completed == 3 and not player.visible)
	var data := CATALOG.get_entry("zeus")
	assert(data.character_count == 1 and data.character_region.size == Vector2(768, 1280))
	assert(data.feet_y == [1200.0])
	player.play("zeus")
	await _wait_ready(player)
	player.set_process(false)
	for viewport_size in [Vector2(1280,720), Vector2(2340,1080), Vector2(1024,768), Vector2(1080,1920), Vector2(1080,2400), Vector2(720,1280)]:
		player.size = viewport_size
		await process_frame
		assert(active.size == viewport_size)
		assert(Rect2(Vector2.ZERO, viewport_size).encloses(Rect2(active.name_label.position, active.name_label.size)), str(viewport_size, " name:", active.name_label.position, " size:",active.name_label.size))
		assert((active.rig.global_transform * Vector2(384,1200)).y < active.name_label.global_position.y)
		assert(player._skip.get_index() > active.get_index())
	player.cancel()
	player.play("unregistered_monster")
	assert(not player._running and not player.visible)
	player.queue_free()
	var overlay = OVERLAY.new()
	root.add_child(overlay)
	# Actual atomic reward transaction in a fresh isolated guest namespace.
	assert(SCOPE.user_id.is_empty(), "run this fixture without a signed-in account")
	var rewards: Array = []
	for source in ["summon", "pickup"]:
		SCOPE.guest_directory = "user://zeus_fixture_%s_%s" % [source, Time.get_ticks_usec()]
		DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
		var progress := ConfigFile.new()
		progress.set_value("meta", "gold", 1000)
		assert(SCOPE.save_config(progress, COLLECTION.PROGRESS_PATH) == OK)
		var rolls := PREVIEW.sample_results(true)
		for entry in rolls:
			entry.source = source
		var batch := COLLECTION.award_shard_batch(rolls, 1000)
		assert(batch.success and batch.awards.size() == 11)
		assert(batch.state.zeus.unlocked and batch.state.zeus.shards == 2)
		assert(SCOPE.load_config(progress, COLLECTION.PROGRESS_PATH) == OK)
		assert(int(progress.get_value("meta", "gold")) == 0)
		rewards = rolls
	var gold_bytes := FileAccess.get_file_as_string(SCOPE.guest_directory.path_join("stage_progress.cfg"))
	var collection_bytes := FileAccess.get_file_as_string(SCOPE.guest_directory.path_join("monster_collection.cfg"))
	var snapshot := rewards.duplicate(true)
	# Skip the unrelated door animation while retaining the normal reveal dispatch.
	overlay.present(rewards)
	overlay._sequence_token += 1
	var seen: Array[int] = []
	overlay._show_reveal(0)
	for index in range(rewards.size()):
		assert(overlay._reveal_index == index)
		if rewards[index].monster_id == "zeus":
			assert(overlay._phase == "cutscene")
			seen.append(index)
			await _wait_ready(overlay._cutscene)
			assert(overlay._cutscene._active_view != null)
			assert(overlay._cutscene._active_view.elapsed == 0.0)
			if index == 5:
				overlay._cutscene.skip()
			else:
				overlay._cutscene.advance(5.0)
			assert(overlay._phase == "reveal" and overlay._reveal_index == index)
		overlay._advance_reveal()
	assert(seen == [1,5,9] and overlay._phase == "result")
	assert(overlay._results == snapshot and rewards == snapshot)
	assert(overlay._cutscene_seen.size() == 3)
	# Global skip aborts a cutscene/loading coroutine, yields the whole batch once.
	overlay.present(rewards)
	overlay._sequence_token += 1
	overlay._show_reveal(1)
	overlay.skip_to_results()
	await process_frame
	assert(overlay._phase == "result" and not overlay._cutscene.visible)
	assert(overlay._results == snapshot)
	overlay._confirm()
	assert(not overlay.is_presenting())
	assert(FileAccess.get_file_as_string(SCOPE.guest_directory.path_join("stage_progress.cfg")) == gold_bytes)
	assert(FileAccess.get_file_as_string(SCOPE.guest_directory.path_join("monster_collection.cfg")) == collection_bytes)
	overlay.queue_free()
	await process_frame
	await process_frame
	print("Zeus atomic ordinary/pickup rewards / normal/skip/cancel/multi order/immutable results/aspect geometry PASS")
	quit()
