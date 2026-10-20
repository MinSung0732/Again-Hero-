extends SceneTree
## Dumps CharacterBody2D member names for tools/extract_hero_archetype.py.
## godot --headless --path . --script res://tools/dump_body_members.gd -- OUT.json


func _initialize() -> void:
	var names := {}
	for item in ClassDB.class_get_method_list("CharacterBody2D", false):
		names[item.name] = true
	for item in ClassDB.class_get_property_list("CharacterBody2D", false):
		names[item.name] = true
	for item in ClassDB.class_get_signal_list("CharacterBody2D", false):
		names[item.name] = true
	for item in ClassDB.class_get_integer_constant_list("CharacterBody2D", false):
		names[item] = true
	var out := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	out.store_string(JSON.stringify(names.keys()))
	out.close()
	quit()
