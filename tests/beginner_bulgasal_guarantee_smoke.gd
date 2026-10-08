extends SceneTree
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const STORE := preload("res://src/systems/monster_collection_store.gd")
const SHOP := preload("res://src/data/shop_catalog.gd")
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, note: String) -> void:
	if not ok:
		failures += 1
		push_error("BEGINNER: "+note)
func rolls(count: int) -> Array:
	var result: Array = []
	for i in range(count): result.append({"monster_id":"slime","rarity":"common","shards":1,"source":"summon"})
	return result
func progress() -> ConfigFile:
	var config := ConfigFile.new()
	SCOPE.load_config(config,STORE.PROGRESS_PATH)
	return config
func run() -> void:
	root.get_node("CloudStore").stop()
	root.get_node("LoginGateway").remember_session_enabled = false
	root.get_node("LocalTestMode").active = false
	var hex := Crypto.new().generate_random_bytes(16).hex_encode()
	var id := "%s-%s-%s-%s-%s" % [hex.substr(0,8),hex.substr(8,4),hex.substr(12,4),hex.substr(16,4),hex.substr(20,12)]
	check(SCOPE.select_account(id),"isolated account")
	var folder := SCOPE.resolve("user://save_bundle.json").get_base_dir()
	var config := progress()
	config.set_value("meta","gold",1000)
	SCOPE.save_config(config,STORE.PROGRESS_PATH)
	var failed := STORE.award_shard_batch(rolls(11),1001,true)
	check(not failed.success and int(progress().get_value("monster_gacha","total_draws",0))==0 and not STORE.load_state().bulgasal.unlocked,"insufficient funds cannot commit reward or counters")
	var batch := STORE.award_shard_batch(rolls(SHOP.MULTI_DRAW_COUNT),1000,true)
	check(batch.success and batch.awards.size()==11,"actual tutorial10+1 batch")
	check(batch.awards[9].monster_id=="bulgasal" and batch.awards[9].first_draw_unlock and batch.awards[9].beginner_guarantee,"exact tenth replacement uses first unlock")
	check(batch.awards[8].monster_id=="slime" and batch.awards[10].monster_id=="slime","other outcomes preserved")
	check(batch.state.bulgasal.unlocked and batch.state.bulgasal.shards==0 and int(progress().get_value("meta","gold"))==0,"ownership and spending atomically saved")
	check(SCOPE.select_account(id) and bool(progress().get_value("monster_gacha","beginner_bulgasal_claimed",false)),"reconnect persists claim")
	batch = STORE.award_shard_batch(rolls(11),0,true)
	for award in batch.awards: check(award.monster_id=="slime","no second guarantee even with tutorial flag replay")
	check(int(progress().get_value("monster_gacha","total_draws"))==22,"cumulative rolls persisted")
	SCOPE.select_guest()
	SCOPE.guest_directory="user://beginner_fixture_"+str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	batch=STORE.award_shard_batch(rolls(9),0,true)
	check(not batch.state.bulgasal.unlocked,"nine draws below threshold")
	batch=STORE.award_shard_batch(rolls(2))
	check(batch.awards[0].monster_id=="bulgasal" and batch.awards[1].monster_id=="slime","threshold spanning batches uses persisted eligibility")
	for file in DirAccess.get_files_at(SCOPE.guest_directory): DirAccess.remove_absolute(SCOPE.guest_directory.path_join(file))
	batch=STORE.award_shard_batch(rolls(11))
	check(not batch.state.bulgasal.unlocked,"ordinary or old account never enrolled by draws alone")
	for file in DirAccess.get_files_at(SCOPE.guest_directory): DirAccess.remove_absolute(SCOPE.guest_directory.path_join(file))
	DirAccess.remove_absolute(SCOPE.guest_directory)
	SCOPE.guest_directory="user://"
	for file in DirAccess.get_files_at(folder): DirAccess.remove_absolute(folder.path_join(file))
	DirAccess.remove_absolute(folder)
	print("BEGINNER_BULGASAL: PASS" if failures==0 else "BEGINNER_BULGASAL: FAIL")
	quit(0 if failures==0 else 1)
