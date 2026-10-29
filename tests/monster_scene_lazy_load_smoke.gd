extends SceneTree

const CATALOG = preload("res://src/data/monster_catalog.gd")

func _initialize() -> void:
	assert(CATALOG.scene_cache.is_empty())
	var ids: Array = CATALOG.MONSTERS.keys()
	for id in ids:
		assert(CATALOG.has_scene(String(id)))
	assert(not CATALOG.has_scene("missing_monster"))
	assert(CATALOG.scene_cache.is_empty())
	var first := String(ids[0])
	var scene: PackedScene = CATALOG.get_scene(first)
	assert(scene != null and scene.resource_path == CATALOG.MONSTERS[first].scene_path)
	var instance := scene.instantiate()
	assert(instance != null)
	instance.free()
	CATALOG.warm_scenes([first], 1)
	CATALOG.warm_scenes([first], 2)
	for id in ids:
		CATALOG.get_scene(String(id))
	assert(CATALOG.scene_cache.size() <= CATALOG.SCENE_CACHE_LIMIT)
	assert(CATALOG.scene_cache.has(first))
	CATALOG.release_warm(1)
	for id in ids:
		CATALOG.get_scene(String(id))
	assert(CATALOG.scene_cache.has(first))
	CATALOG.release_warm(2)
	for id in ids:
		CATALOG.get_scene(String(id))
	assert(not CATALOG.scene_cache.has(first))
	print("monster_scene_lazy_load_smoke: PASS")
	quit()
