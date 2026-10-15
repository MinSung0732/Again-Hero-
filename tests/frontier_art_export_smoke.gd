extends SceneTree
## PCK test: run after packing .png.import/.ctex WITHOUT any source PNGs.
const D := preload("res://src/data/frontier_monster_catalog.gd")
const VISUAL := preload("res://src/monsters/monster_visual.gd")
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var count := 0
	for id in D.DEFINITIONS:
		for key in ["normal_visual","elite_visual"]:
			var profile: Dictionary = D.DEFINITIONS[id][key]
			var sprite := VISUAL.new()
			root.add_child(sprite)
			assert(sprite.apply_visual_profile(profile))
			for name in profile.animations:
				var config: Dictionary = profile.animations[name]
				assert(sprite.sprite_frames.get_frame_count(name) == config.count)
				for index in int(config.count):
					var files: Array = config.get("files",[])
					var filename: String = files[index] if files.size() > index else "%s_%02d.png" % [name,index+1]
					var path: String = profile.asset_dir+"/"+filename
					assert(not FileAccess.file_exists(path),"source PNG must be absent")
					assert(ResourceLoader.exists(path),"import-only texture must resolve")
					var texture := sprite.sprite_frames.get_frame_texture(name,index)
					assert(texture != null and texture.get_width() > 0)
					count += 1
			sprite.queue_free()
	print("FRONTIER_ART_EXPORT real imported frames=",count," profiles=16")
	quit()
