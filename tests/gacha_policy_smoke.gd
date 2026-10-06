extends SceneTree
const SHOP := preload("res://src/data/shop_catalog.gd")
const STORE := preload("res://src/systems/monster_collection_store.gd")
const HISTORY := preload("res://src/systems/shop_summon_history_store.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
var failed := false
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error("GACHA_POLICY_TEST: " + message)
func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	SCOPE.guest_directory = "user://gacha_policy_" + Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	SCOPE.select_guest()
	var expected := {"common":[30,5,8], "uncommon":[30,3,5], "rare":[30,1,5], "legendary":[9,2,4], "transcendent":[1,1,2]}
	var sum := 0.0
	for id in expected:
		var data := SHOP.get_rarity(id)
		check(data.weight == expected[id][0] and data.shard_min == expected[id][1] and data.shard_max == expected[id][2], "rarity policy " + id)
		sum += data.weight
	check(sum == 100, "weights total one hundred")
	check(is_equal_approx(SHOP.get_effective_probability("common"), 3000.0/69.0) and is_equal_approx(SHOP.get_effective_probability("legendary"), 900.0/69.0), "three available pools normalized")
	check(SHOP.get_effective_probability("rare") == 0 and SHOP.get_effective_probability("transcendent") == 0, "empty pool cannot win")
	# Only in-memory pool sentinels: no pretend monsters in content or saves.
	var real_pools: Dictionary = SHOP._rarity_pools
	SHOP._rarity_pools = {"common":["fixture"],"uncommon":["fixture"],"rare":["fixture"],"legendary":["fixture"],"transcendent":["fixture"]}
	var boundaries := {0.0:"common",0.29999:"common",0.3:"uncommon",0.59999:"uncommon",0.6:"rare",0.89999:"rare",0.9:"legendary",0.98999:"legendary",0.99:"transcendent",1.0:"transcendent"}
	for value in boundaries:
		check(SHOP.roll_rarity(value) == boundaries[value], "exact weighted boundary " + str(value))
	SHOP._rarity_pools = real_pools
	var entry := {"unlocked":false,"shards":0,"level":0}
	var roll := {"monster_id":"fixture","rarity":"transcendent","shards":2,"source":"summon"}
	var first := STORE._apply_draw_reward(entry,roll,SHOP.get_rarity("transcendent"),15,false)
	check(entry.unlocked and entry.shards == 0 and first.shards == 0 and first.first_draw_unlock and first.unlocked, "first draw grants character only")
	var duplicate := STORE._apply_draw_reward(entry,roll,SHOP.get_rarity("transcendent"),15,false)
	check(entry.shards == 2 and duplicate.shards == 2 and not duplicate.unlocked and not duplicate.get("first_draw_unlock",false), "next draw grants shards without repeat unlock")
	var maxed := STORE._apply_draw_reward(entry,roll,SHOP.get_rarity("transcendent"),15,true)
	check(maxed.research_points == 2 and entry.shards == 2, "maxed duplicate conversion unchanged")
	var legendary := {"unlocked":false,"shards":23,"level":0}
	STORE._apply_draw_reward(legendary,{"shards":1,"source":"summon"},SHOP.get_rarity("legendary"),25,false)
	check(not legendary.unlocked,"legendary stays locked below threshold")
	var unlocked := STORE._apply_draw_reward(legendary,{"shards":2,"source":"summon"},SHOP.get_rarity("legendary"),25,false)
	check(legendary.unlocked and legendary.shards == 26 and unlocked.unlocked,"legendary threshold preserves shards")
	check(not HISTORY._normalize_entry(first).is_empty() and HISTORY._normalize_entry(first).first_draw_unlock,"zero shard first character retained in history")
	var saved_history := HISTORY.append_entries([first,duplicate])
	check(saved_history.size() == 2 and HISTORY.load_entries()[0].first_draw_unlock and HISTORY.load_entries()[0].shards == 0, "first character history survives reload")
	check(HISTORY._normalize_entry({"monster_id":"fixture","rarity":"common","shards":0}).is_empty(),"zero invalid reward still rejected")
	var lobby = load("res://src/lobby/Lobby.tscn").instantiate()
	for i in range(500):
		var drawn: Dictionary = lobby._roll_monster_shard()
		check(not drawn.is_empty() and drawn.source == "summon", "no empty actual reward")
		var policy := SHOP.get_rarity(drawn.rarity)
		check(drawn.shards >= policy.shard_min and drawn.shards <= policy.shard_max,"actual reward range")
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		root.add_child(lobby)
		current_scene = lobby
		lobby._rebuild_shop_list()
		lobby.shop_rates_overlay.show()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[-1])
	lobby.free()
	var overlay = load("res://src/ui/gacha_reveal_overlay.gd").new()
	root.add_child(overlay)
	first["name"] = "테스트"
	var card: Control = overlay._create_result_card(first)
	var found := false
	for label in card.find_children("*","Label",true,false):
		found = found or label.text == "첫 획득 · 즉시 해금"
	check(found,"first character reward UI")
	card.free()
	var render_entries: Array = []
	for id in SHOP.RARITY_ORDER:
		var result := {"monster_id":"fixture", "name":SHOP.get_rarity_label(id), "rarity":id, "shards":2}
		var glow_card: Control = overlay._create_result_card(result)
		var frame := glow_card.find_child("RarityGlowFrame",true,false) as TextureRect
		check(frame != null and frame.material is ShaderMaterial, "rarity card glow shader " + id)
		if frame != null:
			check(frame.material.get_shader_parameter("rarity_color") == SHOP.get_rarity(id).color,"correct glow color " + id)
		var second_card: Control = overlay._create_result_card(result)
		var second_frame := second_card.find_child("RarityGlowFrame",true,false) as TextureRect
		check(second_frame.material == frame.material,"shared rarity glow material")
		second_card.free()
		glow_card.free()
		render_entries.append(result)
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		overlay._results = render_entries
		overlay.show()
		overlay._show_final_results()
		await process_frame
		await RenderingServer.frame_post_draw
		var path := OS.get_cmdline_user_args()[-1].replace("gacha-rates.png","gacha-card-glow.png")
		root.get_texture().get_image().save_png(path)
	overlay.free()
	var result := STORE.award_shard_batch([{"monster_id":"banshee","shards":29,"source":"summon"}])
	check(result.success and not STORE.is_unlocked("banshee"),"advanced unchanged threshold")
	result = STORE.award_shard_batch([{"monster_id":"banshee","shards":1,"source":"summon"}])
	check(result.success and STORE.is_unlocked("banshee") and STORE.get_shards("banshee") == 30,"advanced threshold unlock")
	await process_frame
	print("GACHA_POLICY_SMOKE_OK" if not failed else "GACHA_POLICY_SMOKE_FAILED")
	quit(1 if failed else 0)
