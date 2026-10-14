extends Node
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const STORE := preload("res://src/systems/profile_cosmetic_store.gd")
const CATALOG := preload("res://src/data/profile_cosmetic_catalog.gd")
const PICKUP := preload("res://tests/pickup_texture_harness.gd")
const PROFILE_VIEW := preload("res://tests/profile_texture_harness.gd")
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func _ready() -> void:
	var directory := "user://profile_export_"+str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(directory); SCOPE.guest_directory = directory; SCOPE.select_guest()
	var host := Control.new(); add_child(host)
	var profile = PROFILE_VIEW.new(); profile.lobby = host
	var pickup = PICKUP.new(); pickup.lobby = host
	for gender in ["male","female"]:
		var config := ConfigFile.new(); config.set_value("player_profile","value",{"gender":gender,"nickname":"test"})
		SCOPE.save_config(config,"user://stage_progress.cfg")
		var id: String = "original_"+gender
		for slot in ["avatar","banner"]:
			var path := CATALOG.path(id,slot)
			check(not FileAccess.file_exists(path) and ResourceLoader.exists(path),"exported imported-only resource")
			check(id in STORE.choices(slot) and STORE.selected_id(slot) == id,"guest default cosmetic survives export")
			check(STORE.select(slot,id),"imported cosmetic selection saves")
			var texture = profile._texture(path)
			check(texture != null,"profile and account preview texture exists")
			check(profile._texture(path) == texture,"profile texture cache reused")
		check("zeus" not in STORE.choices("avatar"),"unowned monster avatar remains locked")
	var monsters := ConfigFile.new(); monsters.set_value("monsters","zeus_unlocked",true)
	SCOPE.save_config(monsters,"user://monster_collection.cfg")
	for slot in ["avatar","banner"]:
		check("zeus" in STORE.choices(slot),"owned transcendent cosmetic survives export")
		check(STORE.select(slot,"zeus") and STORE.selected_id(slot) == "zeus","owned cosmetic selection retained")
		check(profile._texture(CATALOG.path("zeus",slot)) != null,"owned profile texture exists")
	var path := "res://assets/art/Transcendent_monster/zeus/zeus_pickup_banner.png"
	check(not FileAccess.file_exists(path) and ResourceLoader.exists(path),"pickup imported-only asset")
	var texture = pickup._texture(path)
	check(texture != null and texture.get_width() > 0,"pickup banner loaded from exported texture")
	check(pickup._texture(path) == texture,"pickup texture cache reused")
	check(pickup._texture("") == null and profile._texture("") == null,"empty path handled")
	print("PROFILE_EXPORT checks=",checks," failures=",failures)
	get_tree().quit(1 if failures else 0)
