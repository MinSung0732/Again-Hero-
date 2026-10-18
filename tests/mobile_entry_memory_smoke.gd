extends SceneTree
# Run with tools/build_mobile_entry_fixture.py: real entry controller, simulated
# destination scenes (no GPU claim); all scope/cache/import functions are real.
class Cinematic extends "res://src/ui/battle_summon_cinematic.gd":
	var prepared: Array = []
	func _cached_view(path: String): prepared.append(path); return null
	func _cached_world_effect(_path: String): return null
	func _cached_sound_bank(_id: String): return null
class Host extends Control:
	var hud_layer: CanvasLayer
	var battle
class FakeBattle extends Node2D:
	signal transcendent_summoned(id,actor)
	signal transcendent_died(id,actor)
	signal battle_finished(won,message)
	var hero = null
	var transcendence := {"monster_id":""}
var checks := 0
var failures := 0
func _initialize(): call_deferred("run")
func check(ok: bool,message: String):
	checks += 1
	if not ok: failures += 1; push_error(message)
func run():
	var BATTLE := load("res://src/battle/battle.gd")
	var DATA := load("res://src/data/hero_mode_catalog.gd")
	var VISUAL := load("res://src/monsters/monster_visual.gd")
	var ART := load("res://src/ui/hero_weapon_art.gd")
	var WARM := load("res://src/systems/presentation_warmup.gd")
	var HERO := load("res://src/hero/hero.gd")
	root.get_node("CloudStore").stop()
	root.get_node("LoginGateway").remember_session_enabled = false
	var a = BATTLE.new(); var b = BATTLE.new()
	a._monster_spawn_resources_warmed = true
	check(not b._monster_spawn_resources_warmed,"a previous battle cannot suppress the next warmup")
	a.allowed_monster_ids = ["slime","imp","harpy"]
	check(a.spawn_warmup_ids() == ["slime","imp","harpy"],"warm exactly the current formation")
	a.transcendence.monster_id = "zeus"
	check(a.spawn_warmup_ids() == ["slime","imp","harpy","zeus"],"include equipped transcendent only")
	a.online_match_mode = true
	check(a.spawn_warmup_ids().is_empty(),"dedicated room has no solo warmup")
	a.online_match_mode = false; a.hero_player_mode = true
	for difficulty in ["easy","hard"]:
		for stage in range(1,11):
			a.current_stage_data = {"number":stage}; a.campaign_difficulty = difficulty
			var ids: Array = a.spawn_warmup_ids()
			check(ids == DATA.entry_monster_ids(stage,difficulty),"stage-aware warmup")
			for id in DATA.roster_for(stage,difficulty): check(id in ids,"all initial roster prepared")
			check(DATA.boss_for(stage,difficulty) in ids,"final boss prepared")
			for id in ids:
				check(DATA.monster_allowed(id,stage,difficulty),"rarity scope retained")
				check(not DATA.MONSTERS.MONSTERS[id].has("hero_survival_after"),"late recruits are not forced into first entry")
	a.free(); b.free()
	# Execute the actual async warmup twice with different formations. Scene
	# textures are fixture art, while actor _ready()/elite application are real.
	for selection in [["slime"],["spider","orc"]]:
		var battle = BATTLE.new()
		battle.allowed_monster_ids = selection
		battle.process_mode = Node.PROCESS_MODE_DISABLED
		root.add_child(battle)
		await battle.prepare_spawn_resources()
		check(battle._monster_spawn_resources_warmed and not battle._monster_spawn_warmup_running,"each battle finishes its own async preparation")
		check(battle.spawn_warmup_ids() == selection,"no full-catalog prewarm")
		check(battle.active_monsters.is_empty(),"temporary warmup actors never become live summons")
		battle.queue_free(); await process_frame
	var cache = WARM.new()
	var texture := ImageTexture.create_from_image(Image.create(8,8,false,Image.FORMAT_RGBA8))
	cache._common["common"] = texture; cache._destination["old"] = texture; cache._cropped["old"] = texture
	cache.release_destination()
	check(cache._destination.is_empty() and cache._cropped.is_empty(),"old destination strong refs released")
	check(cache.get_texture("common") == texture,"shared loading art preserved")
	cache.free()
	var frames := SpriteFrames.new(); VISUAL._frames_cache["old"] = frames
	var live := AnimatedSprite2D.new(); live.sprite_frames = frames
	VISUAL.clear_cached_frames()
	check(VISUAL._frames_cache.is_empty() and live.sprite_frames == frames,"cache eviction preserves live actor refs")
	live.free()
	var host := Host.new(); host.hud_layer = CanvasLayer.new(); host.add_child(host.hud_layer)
	host.battle = FakeBattle.new(); host.add_child(host.battle); root.add_child(host)
	var cinematic := Cinematic.new(); cinematic.install(host)
	check(cinematic.prepared.is_empty(),"no equipped transcendence means no cinematic warmup")
	cinematic.free()
	host.battle.transcendence.monster_id = "zeus"
	cinematic = Cinematic.new(); cinematic.install(host)
	check(cinematic.prepared.size() == 1,"only equipped cinematic loaded")
	cinematic.free()
	cinematic = Cinematic.new(); cinematic.install(host,["zeus","bulgasal"])
	check(cinematic.prepared.size() == 2,"explicit multi-preview retained")
	host.free()
	var hero = HERO.new()
	var first: Texture2D = hero._load_stage1_texture("res://tests/mobile_probe.png")
	var second: Texture2D = hero._load_stage1_texture("res://tests/mobile_probe.png")
	check(first != null and first == second,"raw PNG plus import reuses one GPU resource")
	hero.free()
	var transition = root.get_node("SceneTransition")
	var warm = root.get_node("PresentationWarmup")
	for path in ["res://src/main/Main.tscn","res://src/hero_mode/HeroMode.tscn","res://src/main/Main.tscn"]:
		var previous := Node.new(); root.add_child(previous); current_scene = previous
		warm.previous = weakref(previous)
		check(transition.change_scene(path,"mobile regression",{"difficulty":"easy","probe":checks}),"entry accepted")
		check(not transition.change_scene(path),"duplicate during release phase rejected")
		var deadline := Time.get_ticks_msec()+10000
		while transition.is_transitioning() and Time.get_ticks_msec()<deadline: await process_frame
		check(not transition.is_transitioning(),"entry completed")
		check(warm.saw_released,"previous scene freed before destination texture loading")
		check(warm.release_count > 0,"destination cache release called")
		check(current_scene != null and current_scene.prepared,"scene preparation finishes below overlay")
		check(current_scene.options.get("difficulty","") == "easy" and current_scene.options.has("probe"),"entry ticket/options survive previous-scene cleanup")
		check(not transition.visible,"overlay closes only after preparation")
		check(transition.consume_entry_options().is_empty(),"destination consumes the exact entry options once")
		current_scene.free(); current_scene = null
	print("MOBILE_ENTRY_MEMORY checks=",checks," failures=",failures)
	quit(1 if failures else 0)
