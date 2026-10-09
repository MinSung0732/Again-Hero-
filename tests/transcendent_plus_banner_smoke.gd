extends SceneTree
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const COLLECTION := preload("res://src/systems/monster_collection_store.gd")
const COSMETICS := preload("res://src/systems/profile_cosmetic_store.gd")
const CATALOG := preload("res://src/data/profile_cosmetic_catalog.gd")
const MONSTERS := preload("res://src/data/monster_catalog.gd")
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("PLUS_BANNER: "+message)
func run() -> void:
	root.get_node("CloudStore").stop()
	root.get_node("LoginGateway").remember_session_enabled = false
	SCOPE.guest_directory = "user://plus_banner_"+str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	SCOPE.select_guest()
	var state := COLLECTION.load_state()
	state.zeus = {"unlocked":false,"level":0,"shards":0}
	COLLECTION.save_state(state)
	check("zeus_plus_banner" not in COSMETICS.choices("banner"),"locked monster has no plus banner")
	state.zeus = {"unlocked":true,"level":0,"shards":0}
	COLLECTION.save_state(state)
	check("zeus" in COSMETICS.choices("banner") and "zeus" in COSMETICS.choices("avatar"),"first unlock keeps original cosmetics")
	check("zeus_plus_banner" not in COSMETICS.choices("banner"),"first unlock excludes five-transcendence reward")
	state.zeus = {"unlocked":true,"level":4,"shards":MONSTERS.get_shards_required("zeus")}
	COLLECTION.save_state(state)
	check(not COSMETICS.select("banner","zeus_plus_banner"),"four transcends cannot equip")
	var upgrade := COLLECTION.try_upgrade("zeus")
	check(upgrade.success and upgrade.level == 5,"actual fifth upgrade succeeds")
	check("zeus_plus_banner" in COSMETICS.choices("banner") and "zeus" in COSMETICS.choices("banner"),"fifth upgrade adds separate banner")
	check("zeus_plus_banner" not in COSMETICS.choices("avatar") and not COSMETICS.select("representative","zeus_plus_banner"),"banner-only reward")
	check(COSMETICS.select("banner","zeus_plus_banner") and COSMETICS.selected_id("banner") == "zeus_plus_banner","equip persists through reload")
	var image := Image.load_from_file(CATALOG.path("zeus_plus_banner","banner"))
	check(image != null and not image.is_empty(),"uploaded PNG decodes")
	check(COSMETICS.choices("banner").count("zeus_plus_banner") == 1,"no duplicate grant")
	# Existing five-transcendence saves require no second grant transaction.
	var saved := COLLECTION.load_state()
	COLLECTION.save_state(saved)
	check(COSMETICS.selected_id("banner") == "zeus_plus_banner","restored collection preserves eligibility")
	SCOPE.guest_directory += "_other"
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	SCOPE.select_guest()
	check("zeus_plus_banner" not in COSMETICS.choices("banner"),"account isolation")
	print("TRANSCENDENT_PLUS_BANNER: "+("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
