extends Node
const ART := preload("res://src/ui/hero_weapon_art.gd")
const ICONS := preload("res://src/ui/hero_augment_icons.gd")
var checks := 0
var failures := 0
func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(text)
func _ready() -> void:
	for directory in ART.LAYOUTS.REGIONS:
		var frames := ART.sequence(directory)
		check(frames.size() == 8,"exported frames present: "+directory)
		var parent: String = directory.get_base_dir()
		for name in ["sprite_sheet.png","source.png","icon.png","manifest.json"]:
			check(not ResourceLoader.exists(parent+"/"+name) and not FileAccess.file_exists(parent+"/"+name),"authoring source excluded")
	for id in ICONS.DATA.WEAPONS: check(ICONS.texture(id) != null,"weapon icon retained")
	for id in ICONS.DATA.PASSIVES: check(ICONS.texture(id) != null,"passive icon retained")
	check(not ResourceLoader.exists("res://assets/art/UI/hero_augments/weapons.png"),"unused icon source excluded")
	print("OPTIMIZED_PCK checks=",checks," failures=",failures)
	get_tree().quit(1 if failures else 0)
