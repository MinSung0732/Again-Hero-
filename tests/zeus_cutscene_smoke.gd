extends SceneTree

const OVERLAY := preload("res://src/ui/gacha_reveal_overlay.gd")
const PLAYER := preload("res://src/ui/transcendent_cutscene_player.gd")
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
	player.advance(5.0)
	assert(_completed == 1 and not player.visible)
	player.play("zeus")
	await _wait_ready(player)
	player.advance(2.5)
	player.skip()
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
	for viewport_size in [Vector2(1280,720), Vector2(2340,1080), Vector2(1024,768), Vector2(1080,1920)]:
		var stage: Rect2 = PLAYER.stage_rect(viewport_size)
		var factor := stage.size.x / 1280.0
		for feet in data.feet_y:
			var region: Rect2 = data.character_region
			var anchor: Vector2 = data.anchor
			var extent := region.size * float(data.character_scale)
			var origin := anchor - Vector2(region.size.x * 0.5, feet - region.position.y) * float(data.character_scale)
			var body := Rect2(stage.position + origin * factor, extent * factor)
			assert(Rect2(Vector2.ZERO, viewport_size).encloses(body))
			assert(body.end.y < stage.position.y + 630 * factor, "name overlaps feet")
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
