extends SceneTree

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const STORE := preload("res://src/systems/monster_collection_store.gd")
const CATALOG := preload("res://src/data/monster_catalog.gd")
var failed := false

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("FIRST_UNLOCK_TEST: " + message)

func exercise() -> void:
	var state := STORE.load_state()
	check(STORE.get_unlocked_ids(state) == ["slime", "spider", "orc"], "only three starter monsters")
	for id in CATALOG.ORDER:
		if CATALOG.is_default_unlocked(id):
			continue
		var required := CATALOG.get_shards_required(id)
		check(required == 30, "current common monster unlock cost")
		var award := STORE.award_shards(id, required-1)
		check(award.success and not STORE.is_unlocked(id), "locked below threshold " + id)
		check(STORE.try_upgrade(id).reason == "locked", "locked cannot upgrade " + id)
		award = STORE.award_shards(id, 1)
		check(award.success and award.awards[0].unlocked and STORE.is_unlocked(id), "threshold unlock " + id)
		check(STORE.get_shards(id) == required, "unlock preserves existing non-consuming semantics")
		award = STORE.award_shards(id, 1)
		check(award.success and not award.awards[0].unlocked, "new-unlock flag not repeated")
		check(STORE.try_upgrade(id).success and STORE.get_shards(id) == 1, "unlocked monster can upgrade")
	# Previously owned monsters remain owned even after their shards are spent.
	state = STORE.load_state()
	state.ghost = {"unlocked": true, "level": 0, "shards": 0}
	check(STORE.save_state(state) and STORE.is_unlocked("ghost"), "preserve prior unlock")
	var expected := {"common":30, "advanced":30, "uncommon":30, "rare":30, "legendary":25, "transcendent":15}
	for rarity in expected:
		check(CATALOG.RARITY_UPGRADE_PROFILES[rarity].shards_required == expected[rarity], "shared rarity threshold " + rarity)

func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	var folder := "user://first_unlock_" + Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(folder)
	SCOPE.guest_directory = folder
	SCOPE.select_guest()
	exercise()
	for file in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(file))
	DirAccess.remove_absolute(folder)
	SCOPE.guest_directory = "user://"
	var hex := Crypto.new().generate_random_bytes(16).hex_encode()
	var id := "%s-%s-%s-%s-%s" % [hex.substr(0,8),hex.substr(8,4),hex.substr(12,4),hex.substr(16,4),hex.substr(20,12)]
	check(SCOPE.select_account(id), "isolated account")
	folder = SCOPE.resolve("user://save_bundle.json").get_base_dir()
	exercise()
	for file in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(file))
	DirAccess.remove_absolute(folder)
	SCOPE.select_guest()
	print("MONSTER_FIRST_UNLOCK_FAILED" if failed else "MONSTER_FIRST_UNLOCK_OK")
	quit(1 if failed else 0)
