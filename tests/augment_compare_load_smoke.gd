extends SceneTree

const SCRIPTS := [
	"res://src/battle/battle.gd",
	"res://src/data/demon_augment_catalog.gd",
	"res://src/data/hero_weapon_catalog.gd",
	"res://src/hero_mode/hero_mode.gd",
	"res://src/hero_mode/hero_weapon_runtime.gd",
	"res://src/main/main.gd",
	"res://src/online/battle_room.gd",
	"res://src/online/match_rules.gd",
	"res://src/online/match_scene.gd",
	"res://src/ui/augment_hold_popup.gd",
	"res://src/ui/augment_compare_view.gd",
]
const SCENES := ["res://src/main/Main.tscn","res://src/hero_mode/HeroMode.tscn","res://src/online/OnlineMatch.tscn"]

func _initialize() -> void:
	for path in SCRIPTS:
		var script: GDScript = load(path)
		if script == null or not script.can_instantiate():
			push_error("Script load failed: "+path); quit(1); return
	for path in SCENES:
		var scene: PackedScene = load(path)
		if scene == null or not scene.can_instantiate():
			push_error("Scene load failed: "+path); quit(1); return
		var instance := scene.instantiate()
		if instance == null:
			push_error("Scene instantiate failed: "+path); quit(1); return
		instance.free()
	print("AUGMENT_COMPARE_LOAD_PASS scripts=",SCRIPTS.size()," scenes=",SCENES.size())
	quit()
