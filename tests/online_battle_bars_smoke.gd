extends SceneTree
const BARS := preload("res://src/ui/battle_bar_painter.gd")
const RULES := preload("res://src/online/match_rules.gd")
const ROOM := preload("res://src/online/battle_room.gd")
const VIEW := preload("res://src/online/battle_view.gd")
const COMMON := preload("res://src/monsters/monster_runtime_common.gd")
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: push_error(message); quit(1); assert(ok,message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	for path in ["res://src/ui/battle_bar_painter.gd","res://src/data/monster_bar_layout_catalog.gd","res://src/hero/hero.gd","res://src/monsters/monster_runtime_common.gd","res://src/online/battle_room.gd","res://src/online/battle_view.gd","res://src/online/match_rules.gd","res://tests/online_battle_bars_smoke.gd","res://tests/online_augment_hold_smoke.gd","res://tests/online_demon_abilities_smoke.gd","res://tests/online_hero_abilities_smoke.gd","res://tests/online_motion_smoke.gd"]:
		var script: Resource = load(path)
		check(script != null and script.can_instantiate(),"script load: "+path)
	for path in ["res://src/main/Main.tscn","res://src/hero_mode/HeroMode.tscn","res://src/online/OnlineMatch.tscn"]:
		var scene: PackedScene = load(path)
		check(scene != null and scene.can_instantiate(),"scene load: "+path)
		var instance: Node = scene.instantiate()
		check(instance != null,"scene instantiate: "+path)
		instance.free()
	check(RULES.VERSION == 20,"protocol 20")
	check(is_equal_approx(RULES.SNAPSHOT_INTERVAL,0.1),"10 Hz snapshots")
	var rect := BARS.bar_rect(-35.0,-44.0,70.0,6.0,0.6)
	check(rect == Rect2(-35.0,-44.0,42.0,6.0),"shared bar matches solo rectangle")
	var solo_commands := [[Rect2(-35.0,-44.0,70.0,6.0),Color("202024")],[Rect2(-35.0,-44.0,42.0,6.0),Color("4cd965")]]
	var shared_commands := [[Rect2(-35.0,-44.0,BARS.MONSTER_WIDTH,BARS.MONSTER_HEIGHT),BARS.MONSTER_BACKGROUND],[rect,BARS.MONSTER_HP]]
	check(shared_commands == solo_commands,"solo and online rect/color command order")
	var hero_commands := [[Rect2(-46.0,-64.0,92.0,10.0),Color(0.12,0.12,0.14)],[BARS.bar_rect(-46.0,-64.0,92.0,10.0,0.5),Color(0.95,0.38,0.32)]]
	check(hero_commands == [[Rect2(-46.0,-64.0,92.0,10.0),BARS.HERO.STATUS_BACKGROUND_COLOR],[Rect2(-46.0,-64.0,46.0,10.0),BARS.HERO.STATUS_HP_COLOR]],"hero rect/color command order")
	check(BARS.MONSTER_HP == Color("4cd965") and BARS.MONSTER_BACKGROUND == Color("202024"),"shared monster colors")
	check(BARS.SHIELD_COLORS == COMMON.BAR_COLORS,"shield colors and order")
	var room = ROOM.new(); root.add_child(room); room.prepare(); room.start()
	var hero = room.battle.hero
	hero.current_hp = maxi(hero.max_hp/2,1)
	hero.shield_max_hp = 100.0; hero.shield_hp = 25.0
	var hero_bars: Array = room._hero_bars()
	check(hero_bars[0] == BARS.quantize(float(hero.current_hp)/float(hero.max_hp)),"hero HP ratio")
	check(hero_bars[1] == BARS.quantize(0.25),"hero shield ratio")
	check(BARS.valid_hero_bars(hero_bars),"hero bars valid")
	var original_archetype: String = hero.hero_archetype
	hero.hero_archetype = "pistol_gunner"
	hero.gunner_magazine_size = 12; hero.gunner_ammo = 5; hero.gunner_reloading = false
	hero_bars = room._hero_bars()
	check(hero_bars[2] == 1 and hero_bars[3] == 5 and hero_bars[4] == 12,"visible magazine cells")
	hero.gunner_reloading = true; hero.gunner_reload_timer = float(hero.gunner_config.get("reload_seconds",2.4))*0.5
	check(room._hero_bars()[3] == 6,"reload progress cells")
	hero.hero_archetype = original_archetype
	var monster = preload("res://src/monsters/Slime.tscn").instantiate()
	room.battle.add_child(monster)
	monster.current_hp = maxi(monster.max_hp/2,1)
	COMMON.grant_typed_shield(monster,"ranged",40)
	var monster_bars: Array = room._monster_bars(monster)
	check(monster_bars[0] == BARS.quantize(float(monster.current_hp)/float(monster.max_hp)),"monster HP ratio")
	check(monster_bars[5] == 1 and monster_bars[6] == 255,"monster ranged shield")
	check(BARS.valid_monster_bars(monster_bars),"monster bars valid")
	COMMON.grant_typed_shield(monster,"melee",20)
	COMMON.grant_generic_shield(monster,"bar_test",30)
	monster_bars = room._monster_bars(monster)
	check(monster_bars.size() == 11 and monster_bars[5] == 1 and monster_bars[7] == 2 and monster_bars[9] == 0,"ranged, melee, generic shield order")
	var arthur = preload("res://src/monsters/Arthur.tscn").instantiate()
	arthur.gauge = 75.0
	var arthur_bars: Array = room._monster_bars(arthur)
	check(arthur_bars[1] == BARS.quantize(0.5),"boss yellow gauge uses solo capacity")
	arthur.free()
	var snapshot: Dictionary = room.snapshot()
	var hero_state: Dictionary = room.snapshot_for_role("hero",snapshot)
	var demon_state: Dictionary = room.snapshot_for_role("demon",snapshot)
	check(not hero_state.has("demon_charge") and not hero_state.has("summon_costs"),"hero role private data hidden")
	check(not demon_state.has("hero_inventory") and not demon_state.has("chest_receipts"),"demon role private data hidden")
	check(hero_state.hero[5] == demon_state.hero[5],"public bars same for both roles")
	var view = VIEW.new(); root.add_child(view)
	check(view.update_state(snapshot),"live room snapshot accepted")
	var wire: Variant = JSON.parse_string(JSON.stringify(snapshot))
	check(view.update_state(wire),"JSON-decoded snapshot accepted")
	var bad := snapshot.duplicate(true)
	bad.hero[5] = [1,2]
	check(not view.update_state(bad),"truncated hero bars rejected")
	bad = snapshot.duplicate(true); bad.hero[5][0] = 256
	check(not view.update_state(bad),"out of range hero bars rejected")
	bad = snapshot.duplicate(true); bad.hero[5][0] = 12.5
	check(not view.update_state(bad),"fractional hero bars rejected")
	bad = snapshot.duplicate(true); bad.actors = [[1,"slime",0,0,10,10,[255,-1,-44,100,100,4,255]]]
	check(not view.update_state(bad),"invalid monster shield kind rejected")
	var actor_row := [1,"slime",100,100,50,100,monster_bars]
	var full := snapshot.duplicate(true)
	full.actors.clear()
	for index in RULES.POPULATION:
		var row := actor_row.duplicate(true)
		row[0] = index+1
		full.actors.append(row)
		var visual_rows: Array = []
		room.presentation.append_tree(monster,index+1,visual_rows)
		full.visuals.append_array(visual_rows)
	var bytes := JSON.stringify(full).to_utf8_buffer().size()
	check(bytes <= RULES.MAX_SNAPSHOT,"population cap snapshot size")
	print("ONLINE_BATTLE_BARS_PASS checks=",checks," bytes=",bytes)
	view.queue_free(); room.queue_free(); await process_frame; quit()
