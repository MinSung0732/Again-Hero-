extends SceneTree
const DATA := preload("res://src/data/online_feedback_catalog.gd")
const BUFFER := preload("res://src/online/feedback_buffer.gd")
const POPUPS := preload("res://src/ui/damage_number_spawner.gd")
const ROOM := preload("res://src/online/battle_room.gd")
const RULES := preload("res://src/online/match_rules.gd")
var checks := 0
var failures := 0
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.get_node("CloudStore").stop()
	for path in ["res://src/ui/damage_number_spawner.gd","res://src/data/online_feedback_catalog.gd","res://src/online/feedback_buffer.gd","res://src/online/combat_feedback.gd","res://src/online/battle_room.gd","res://src/online/battle_view.gd","res://src/online/match_rules.gd","res://src/online/match_server.gd","res://src/battle/battle.gd","res://src/monsters/dark_elf_rogue.gd"]:
		check(load(path) != null,"script loads: "+path)
	for path in ["res://src/main/Main.tscn","res://src/hero_mode/HeroMode.tscn","res://src/online/OnlineMatch.tscn"]:
		var scene := load(path) as PackedScene
		check(scene != null and scene.can_instantiate(),"scene can instantiate: "+path)
		if scene != null and scene.can_instantiate():
			var instance := scene.instantiate()
			check(instance != null,"scene instantiates: "+path)
			instance.free()
	var host := Node2D.new(); root.add_child(host)
	var color := Color(0.8,0.3,0.2)
	var target := Node2D.new(); host.add_child(target); target.position = Vector2(80,90)
	POPUPS.show(target,12,color)
	var solo_scene = target.get_meta("damage_number_popup")
	var solo = POPUPS.show_feedback(host,42,Vector2(80,90),12,color,false)
	var same = POPUPS.show_feedback(host,42,Vector2(80,90),5,color,false)
	check(solo == same and solo.numeric_amount == 17,"shared popup merges same owner")
	check(solo.value_label.text == solo_scene.value_label.text and solo.value_label.get_theme_color("font_color") == solo_scene.value_label.get_theme_color("font_color") and solo.value_label.get_theme_font_size("font_size") == solo_scene.value_label.get_theme_font_size("font_size"),"solo and online popup text color and size")
	solo._process(0.01)
	check(solo.value_label.text == "17","merged popup displays sum")
	var heal = POPUPS.show_feedback(host,42,Vector2(80,90),4,Color.GREEN,true)
	check(heal != solo and heal.value_label.text == "+4" and heal.value_label.get_theme_font_size("font_size") == 32,"heal uses shared scene and prefix")
	var count: int = host.get_meta(POPUPS.POOL_META,[]).size()
	for index in 120:
		POPUPS.show_feedback(host,100+index,Vector2.ZERO,1,color,false)
	check(host.get_meta(POPUPS.POOL_META,[]).size() <= POPUPS.MAX_ACTIVE_POPUPS and host.get_meta(POPUPS.POOL_META,[]).size() >= count,"popup pool bounded")
	for popup in host.get_meta(POPUPS.POOL_META,[]): popup._deactivate_for_pool()
	var reused = POPUPS.show_feedback(host,700,Vector2.ZERO,8,color,false)
	check(reused != null and host.get_meta(POPUPS.POOL_META,[]).size() <= POPUPS.MAX_ACTIVE_POPUPS,"inactive popup reused")
	var buffer := BUFFER.new()
	buffer.publish("monster_hit",Vector2(2,3),17,color,5,42,true)
	var rows := buffer.snapshot()
	check(rows.size()==1 and rows[0].size()==DATA.EVENT_SIZE and rows[0][10]==42 and rows[0][11]==1 and DATA.valid_events(rows,buffer.sequence,5),"critical and owner wire round trip")
	check(buffer.snapshot(buffer.sequence).is_empty(),"ordered events send once")
	var bad: Array = rows[0].duplicate(); bad[11]=2
	check(not DATA.valid_events([bad],buffer.sequence,5),"invalid critical bit rejected")
	bad = rows[0].duplicate(); bad[10]=-1
	check(not DATA.valid_events([bad],buffer.sequence,5),"invalid owner rejected")
	bad = rows[0].duplicate(); bad[2]="unknown"
	check(not DATA.valid_events([bad],buffer.sequence,5),"invalid kind rejected")
	check(RULES.VERSION==22,"protocol 22")
	var room := ROOM.new(); root.add_child(room); room.prepare()
	room.battle.hero_player_mode = false
	for index in RULES.POPULATION:
		room.battle._spawn_monster("orc",room.battle.hero.position+Vector2(90+index*3,50))
	room.battle.hero_player_mode = true
	for index in DATA.CAPACITY:
		room.feedback.publish("monster_hit",room.battle.hero.position+Vector2(index,0),100,color,room.tick,1000+index,index==0)
	var state := room.snapshot()
	var encoded := JSON.stringify(state)
	check(encoded.to_utf8_buffer().size() <= RULES.MAX_SNAPSHOT,"population cap snapshot fits")
	for kind in DATA.KINDS: check(DATA.KINDS.find(kind) >= 0,"effect kind in catalog")
	for player in room.find_children("*","AudioStreamPlayer",true,false): player.stop(); player.stream = null
	room.free(); host.free()
	print("ONLINE_COMBAT_FEEDBACK checks=",checks," failures=",failures," snapshot_bytes=",encoded.to_utf8_buffer().size())
	quit(1 if failures else 0)
