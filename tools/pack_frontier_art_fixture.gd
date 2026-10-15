extends SceneTree
const D := preload("res://src/data/frontier_monster_catalog.gd")
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		push_error("Run in imported frontier fixture: --script res://tools/pack_frontier_art_fixture.gd -- /absolute/path/frontier-art.pck")
		quit(1)
		return
	var pack := PCKPacker.new()
	assert(pack.pck_start(args[0]) == OK)
	var config := "user://frontier-pack-project.godot"
	var file := FileAccess.open(config,FileAccess.WRITE)
	file.store_string("config_version=5\n[application]\nconfig/name=\"FrontierImportedArt\"\n[rendering]\nrenderer/rendering_method=\"gl_compatibility\"\n")
	file.close()
	assert(pack.add_file("res://project.godot",config) == OK)
	for path in ["src/data/frontier_monster_catalog.gd","src/monsters/monster_visual.gd","tests/frontier_art_export_smoke.gd"]:
		assert(pack.add_file("res://"+path,ProjectSettings.globalize_path("res://"+path)) == OK)
	for data in D.DEFINITIONS.values():
		for key in ["normal_visual","elite_visual"]:
			var pro: Dictionary = data[key]
			for name in pro.animations:
				var cfg: Dictionary = pro.animations[name]
				for index in int(cfg.count):
					var files: Array = cfg.get("files",[])
					var filename: String = files[index] if files.size() > index else "%s_%02d.png" % [name,index+1]
					var path: String = pro.asset_dir+"/"+filename+".import"
					var imported := ConfigFile.new()
					assert(imported.load(path) == OK)
					var ctex: String = imported.get_value("remap","path")
					assert(pack.add_file(path,ProjectSettings.globalize_path(path)) == OK)
					assert(pack.add_file(ctex,ProjectSettings.globalize_path(ctex)) == OK)
	assert(pack.flush() == OK)
	print("PACKED real new monster imports without source PNG")
	quit()
