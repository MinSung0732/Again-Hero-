extends SceneTree
## Real Battle monsters: shields are spent conditional (ranged/melee) first,
## then generic shields expiring-first (Arthur's blessing), then permanent
## generic shields newest first. Amounts per source keep their own add/refresh
## rules; the support_shield_hp total stays authoritative for other readers.
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const COMMON := preload("res://src/monsters/monster_runtime_common.gd")
const HIT := preload("res://src/systems/monster_hit_context.gd")
const BLESSING := preload("res://src/systems/arthur_blessing.gd")
var checks := 0
var failures := 0
var battle


func _initialize() -> void: run.call_deferred()


func expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("SHIELD_ORDER_FAIL " + label)


func spawn(id: String):
	var monster = battle._spawn_monster(id, Vector2(1100, 1000))
	monster.set_physics_process(false)
	monster.max_hp = 100000
	monster.current_hp = 100000
	return monster


func support(actor) -> int:
	return int(actor.get_meta("support_shield_hp", 0))


func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	SCOPE.guest_directory = "user://shield_order_test_" + Crypto.new().generate_random_bytes(16).hex_encode()
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	SCOPE.select_guest()
	battle = load("res://src/battle/Battle.tscn").instantiate()
	root.add_child(battle)
	battle.set_process(false)
	battle.set_physics_process(false)
	await battle.prepare_spawn_resources()
	battle.hero.set_physics_process(false)
	battle.hero.position = Vector2(1000, 1000)

	# 1) Tank spawn shield, then a later support shield: the newer one goes first.
	var tank = spawn("iron_beetle")
	var spawn_shield := int(tank.get_meta("temporary_shield_hp", 0))
	expect(spawn_shield > 0 and String(tank.get_meta("temporary_shield_kind", "")) == "shield", "tank has a generic spawn shield")
	battle.support_buff_runtime.apply_courage(tank, 1, 0.15, 0.10)
	var courage := support(tank)
	expect(courage > 0, "courage grants a support shield")
	var hp: int = tank.current_hp
	tank.take_damage(10)
	expect(tank.current_hp == hp and support(tank) == courage - 10 and int(tank.get_meta("temporary_shield_hp", 0)) == spawn_shield, "newer courage shield spent before the older spawn shield")
	tank.take_damage(courage - 10 + 5)
	expect(support(tank) == 0 and int(tank.get_meta("temporary_shield_hp", 0)) == spawn_shield - 5, "overflow continues into the spawn shield")

	# 2) Spawn shield refreshed after a support grant becomes the newest.
	var tank2 = spawn("iron_beetle")
	COMMON.add_support_shield(tank2, 40, "test_support")
	tank2._set_own_shield(int(tank2.get_meta("temporary_shield_hp", 0)))
	var tank2_spawn := int(tank2.get_meta("temporary_shield_hp", 0))
	tank2.take_damage(10)
	expect(int(tank2.get_meta("temporary_shield_hp", 0)) == tank2_spawn - 10 and support(tank2) == 40, "re-granted spawn shield is newest and goes first")

	# 3) Conditional shields first; a mismatched kind skips them.
	var slime = spawn("slime")
	COMMON.grant_typed_shield(slime, "ranged", 50)
	COMMON.add_support_shield(slime, 50, "test_support")
	HIT.hit(slime, 10, "ranged", battle.hero)
	expect(int(slime.get_meta("ranged_shield_hp", 0)) == 40 and support(slime) == 50, "ranged hit spends the ranged shield before the newer generic one")
	HIT.hit(slime, 10, "melee", battle.hero)
	expect(int(slime.get_meta("ranged_shield_hp", 0)) == 40 and support(slime) == 40, "melee hit skips the ranged shield")
	slime.take_damage(10)
	expect(int(slime.get_meta("ranged_shield_hp", 0)) == 40 and support(slime) == 30, "untyped hit uses only generic shields")

	# 4) Expiring generic shield (Arthur's blessing) before permanent ones.
	var orc = spawn("orc")
	BLESSING.grant(orc, 30, 5.0, battle)
	COMMON.add_support_shield(orc, 50, "test_support")
	orc.take_damage(20)
	expect(int(orc.get_meta("arthur_blessing_hp", 0)) == 10 and support(orc) == 50, "expiring blessing spent before a newer permanent shield")

	# 5) Per-source rules: refresh never stacks with itself; sources stack together.
	var spider = spawn("spider")
	COMMON.grant_generic_shield(spider, "ward", 60, true)
	COMMON.grant_generic_shield(spider, "ward", 40, true)
	expect(support(spider) == 60, "ward refresh keeps the greater value")
	COMMON.grant_generic_shield(spider, "manticore", 30, false, true)
	expect(support(spider) == 90 and int(spider.get_meta("support_shield_capacity", 0)) == 90, "different sources add up; reset capacity mirrors writer")
	spider.take_damage(35)
	expect(support(spider) == 55, "newest source (30) then older ward (5)")
	var entries: Dictionary = spider.get_meta("support_shield_entries")
	expect(not entries.has("manticore") and int(entries.ward.hp) == 55, "spent source removed, older source reduced")

	# 6) Legacy direct writes stay consumable; lowering the total trims entries.
	var goblin = spawn("goblin")
	COMMON.add_support_shield(goblin, 30, "test_support")
	goblin.set_meta("support_shield_hp", 80)
	goblin.take_damage(20)
	expect(support(goblin) == 60 and int(goblin.get_meta("support_shield_entries").test_support.hp) == 30, "direct write is the newest portion")
	goblin.set_meta("support_shield_hp", 10)
	goblin.take_damage(5)
	expect(support(goblin) == 5 and int(goblin.get_meta("support_shield_entries").test_support.hp) == 5, "lowered total trims tracked entries")
	COMMON.GENERIC_SHIELDS.clear(goblin)
	expect(support(goblin) == 0 and not goblin.has_meta("support_shield_entries"), "clear removes total and entries")

	battle.queue_free()
	await process_frame
	if failures == 0:
		print("SHIELD_ORDER_PASS checks=", checks)
		quit(0)
	else:
		print("SHIELD_ORDER_FAIL failures=", failures, " checks=", checks)
		quit(1)
