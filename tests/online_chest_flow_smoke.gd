extends SceneTree
const ROOM := preload("res://src/online/battle_room.gd")
const PICKUPS := preload("res://src/data/ranked_pickup_catalog.gd")
const HERO := preload("res://src/data/hero_mode_catalog.gd")
const CODEC := preload("res://src/online/snapshot_codec.gd")
var checks := 0
var failures := 0
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: run.call_deferred()
func break_chest(chest) -> void:
	chest.take_damage(chest.max_hp)
	chest.visual.animation = &"death"
	chest._on_visual_animation_finished()
func run() -> void:
	root.get_node("CloudStore").stop()
	var room := ROOM.new(); root.add_child(room); room.prepare(); room.start()
	var battle = room.battle; battle.process_mode = Node.PROCESS_MODE_DISABLED
	var runtime = battle.hero.player_weapons
	check(PICKUPS.CHEST_KILLS==HERO.CHEST_KILLS and PICKUPS.CHEST_ELITE_KILLS==HERO.CHEST_ELITE_KILLS,"ranked supply reuses solo thresholds")
	check(not battle._hero_chest_eligible("kills"),"no unearned opening chest")
	battle.hero_kills_toward_chest = PICKUPS.CHEST_KILLS-1
	var monster = battle._spawn_monster("slime",battle.hero.position+Vector2(300,0))
	monster.take_damage(monster.max_hp*10)
	await process_frame
	check(battle.active_treasure_chests.size()==1 and battle.hero_chests_spawned==1,"real final qualifying kill spawns first ranked chest")
	check(battle.hero_kills_toward_chest==0,"successful spawn consumes only earned kill progress")
	var chest = battle.active_treasure_chests.values()[0]
	var original_hp: int = chest.current_hp
	chest.take_damage(10)
	check(chest.current_hp==original_hp-10,"chest retains authoritative durability")
	var snapshot: Dictionary = room.snapshot()
	check(snapshot.primitives.size()>=2,"existing generic wire includes shared solo chest bar")
	var codec := CODEC.new(); var decoded: Dictionary = JSON.parse_string(codec.encode(snapshot))
	check(CODEC.expand(decoded) and preload("res://src/online/primitive_mirror.gd").valid(decoded.primitives),"JSON chest durability presentation validates")
	var gold: float = runtime.gold_bonus
	break_chest(chest)
	check(room.chest_receipts.size()==1 and runtime.last_applied_chest==1,"physical chest break applies one server reward")
	chest._on_visual_animation_finished()
	check(room.chest_receipts.size()==1 and runtime.last_applied_chest==1,"repeated animation callback cannot duplicate reward")
	check(runtime.gold_bonus==gold and not battle.external_pause,"ranked chest grants no account gold and never pauses combat")
	check(room.snapshot("hero").chest_receipts.size()==1 and not room.snapshot("demon").has("chest_receipts"),"reward receipt stays private to hero")
	await process_frame
	check(battle.active_treasure_chests.is_empty(),"broken chest retires its field slot")
	# First-elite path and later progress use the existing solo thresholds.
	battle.hero_chests_spawned = 0; battle.hero_elite_kills_toward_chest = 1
	check(battle._hero_chest_eligible("elite"),"opening elite can still grant first chest")
	battle.hero_chests_spawned = 1
	check(not battle._hero_chest_eligible("elite"),"later elite progress is not an unearned reward")
	battle.hero_elite_kills_toward_chest = PICKUPS.CHEST_ELITE_KILLS
	check(battle._hero_chest_eligible("elite"),"later elite threshold unlocks its independent reward")
	# Capacity/session failures preserve progress for a later attempt.
	for index in battle.MAX_ACTIVE_CHESTS: battle._spawn_random_treasure_chest()
	battle.hero_kills_toward_chest = PICKUPS.CHEST_KILLS
	var spawned: int = battle.hero_chests_spawned
	battle._try_spawn_chest_from_kills(); await process_frame
	check(battle.hero_kills_toward_chest==PICKUPS.CHEST_KILLS and battle.hero_chests_spawned==spawned,"full field preserves earned progress")
	battle._spawn_chest_for_session(battle.battle_command_router.get_session_id()+1)
	check(battle.hero_kills_toward_chest==PICKUPS.CHEST_KILLS,"stale session cannot consume progress")
	var to_free: Array = battle.active_treasure_chests.values()
	for item in to_free: item.free()
	battle._try_spawn_chest_from_kills(); await process_frame
	check(battle.active_treasure_chests.size()==1 and battle.hero_kills_toward_chest==0,"freed capacity delivers the waiting earned chest")
	# Evolve through the same physical chest path, never a client command.
	for id in runtime.weapon_ids: runtime.levels[id]=preload("res://src/data/hero_weapon_catalog.gd").MAX_LEVEL
	chest = battle.active_treasure_chests.values()[0]
	break_chest(chest)
	check(room.chest_receipts[-1].evolution and not runtime.evolved.is_empty(),"physical chest applies MAX evolution and its receipt")
	await process_frame
	battle._spawn_random_treasure_chest(); chest = battle.active_treasure_chests.values()[0]
	room.finish("hero","test_complete")
	var serial: int = runtime.last_applied_chest
	break_chest(chest)
	check(runtime.last_applied_chest==serial and room.chest_receipts.is_empty(),"terminal match cannot grant a late chest reward")
	# Solo opening policy remains unchanged by the online-only branch.
	battle.online_match_mode = false; battle.hero_chests_spawned = 0; battle.hero_kills_toward_chest = HERO.CHEST_KILLS
	check(not battle._hero_chest_eligible("kills") and battle._hero_chest_eligible("elite"),"solo keeps its opening elite gate")
	for kind in ["AudioStreamPlayer","AudioStreamPlayer2D"]:
		for player in room.find_children("*",kind,true,false): player.stop(); player.stream=null
	room.free()
	print("ONLINE_CHEST_FLOW checks=",checks," failures=",failures)
	quit(1 if failures else 0)
