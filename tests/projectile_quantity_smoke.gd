extends SceneTree
const DATA := preload("res://src/data/hero_weapon_catalog.gd")
const RUNTIME := preload("res://src/hero_mode/hero_weapon_runtime.gd")
const BASE := preload("res://tests/hero_weapon_extension_smoke.gd")
const WATCHER := preload("res://src/hero/summoner_watcher.gd")
const GATEKEEPER := preload("res://src/hero/summoner_gatekeeper.gd")
const NATIVE := preload("res://src/hero_mode/hero_weapon_native_runtime.gd")
const SUMMON_BOLT := preload("res://src/hero/summoner_gatekeeper_projectile.gd")
var checks := 0
var failures := 0
class Hero extends BASE.Hero:
	var player_weapons
	var target: Node2D
class NativeSpy extends RefCounted:
	var count := 0
	var last_cast_succeeded := true
	var summon_configs := {}
	func cast(data: Dictionary,_origin,_dir,_target,_damage,_reach,hits:int,_rank,_speed,_awakened) -> bool:
		if String(data.pattern) not in ["piercer","meteor"]: return false
		count = hits
		return true
class NativeArena extends BASE.Arena:
	var projectile_pools := {}
	func recycle_projectile(node: Node,key: String) -> void: projectile_pools[key].append(node)
	func is_combat_simulation_paused() -> bool: return false
class NativeHero extends BASE.Hero:
	func _acquire_projectile(_scene: PackedScene,key: String) -> Node:
		return get_parent().projectile_pools[key].pop_back()
class NativeShot extends Node2D:
	var calls := 0
	func setup(_a,_b,_c,_d,_e=null,_f=null,_g=null,_h=null,_i=null) -> void: calls += 1
class DrawSpy extends Node2D:
	var rect := Rect2()
	func record_draw_texture_rect(_texture: Texture2D,value: Rect2,_tile: bool,_color: Color=Color.WHITE) -> void: rect = value
	func record_draw_set_transform(_a: Vector2,_b: float=0.0) -> void: pass
class Primary extends Node2D:
	var area_attack = preload("res://src/hero/summon_area_attack.gd").new()
	var calls := 0
	func activate(_a,_b,_c,_d,_e) -> void: calls += 1
class Watcher extends WATCHER:
	var primary := Primary.new()
	func _ready() -> void: pass
	func _acquire_projectile() -> Node2D: return primary
class Gatekeeper extends GATEKEEPER:
	var primary := Primary.new()
	func _ready() -> void: pass
	func _acquire_projectile() -> Node2D: return primary
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void: run.call_deferred()
func clear_shots(runtime) -> void:
	for shot in runtime.projectiles: shot.active = false
	for slot in runtime.delivery.slots: slot.left = 0.0
func active_shots(runtime) -> int:
	var result := 0
	for shot in runtime.projectiles:
		if shot.active: result += 1
	return result
func select_weapon(runtime,id: String,extra: int = 2,rank: int = 1) -> void:
	runtime.levels.clear(); runtime.weapon_ids.clear(); runtime.resolved.clear()
	runtime.levels[id] = rank; runtime.weapon_ids.append(id)
	runtime.projectile_bonus = extra
	clear_shots(runtime)
func run() -> void:
	var empty: Array[Texture2D] = []
	for data in DATA.WEAPONS.values(): RUNTIME.ART.cache[String(data.get("effect_dir",""))] = empty
	var arena := BASE.Arena.new(); root.add_child(arena)
	var hero := Hero.new(); arena.add_child(hero)
	var target := BASE.Target.new(); arena.add_child(target); arena.targets.append(target)
	target.position = Vector2(100,0)
	var runtime := RUNTIME.new(); runtime.install(hero); hero.player_weapons = runtime
	var eligible := 0
	for id in DATA.WEAPONS:
		select_weapon(runtime,id)
		var kind := DATA.projectile_quantity_kind(id)
		var stats: Dictionary = runtime.stats_for(id)
		if not kind.is_empty(): eligible += 1
		check(int(stats.extra_projectiles) == (2 if not kind.is_empty() else 0),id+" quantity eligibility")
		check(DATA.passive_allowed("survival_multishot",String(DATA.WEAPONS[id].owner),[id]) == not kind.is_empty(),id+" passive offer eligibility")
		if kind == "orbit":
			var base: Dictionary = DATA.GROWTH.resolve(id,DATA.WEAPONS[id],1,false)
			check(stats.orbit_count == mini(10,int(base.get("orbit_count",4))+2),id+" orbit count")
	check(eligible >= 20 and DATA.projectile_quantity_kind("pistol_hero_suppressor") == "sentry","retained projectile/sentry/orbit weapons eligible")
	for id in ["ranged_rookie_arcane_bolt","swift_hunter_throwing_knife","purifier_hero_holy_bolt","pistol_hero_rifle"]:
		select_weapon(runtime,id,0); runtime._cast(id); var base := active_shots(runtime)
		select_weapon(runtime,id,2); runtime._cast(id)
		check(active_shots(runtime) == base+2,id+" extra shots even with a single target")
	for id in ["pistol_hero_suppressor"]:
		select_weapon(runtime,id,2)
		runtime._cast(id)
		var emitters := 0
		for slot in runtime.delivery.slots:
			if slot.left <= 0: continue
			emitters += 1
			target.global_position = slot.origin+Vector2(40,0)
			slot.tick = 0.0; slot.warning = 0.0
		runtime.delivery.tick(.01)
		check(active_shots(runtime) == emitters*3,id+" each sentry fires three shots")
		target.position = Vector2(100,0)
	var native := NativeSpy.new(); runtime.native_skills = native
	native.summon_configs = {"watcher":{"attack_range":400.0},"gatekeeper":{"attack_range":400.0}}
	for id in ["summoner_hero_watcher","summoner_hero_gatekeeper"]:
		select_weapon(runtime,id)
		var config: Dictionary = runtime.stats_for(id).summon_config
		check(config.survival_weapon_id == id,id+" summon carries explicit weapon identity")
	for id in ["ranged_rookie_magic_lance","sage_astra_comet"]:
		select_weapon(runtime,id,0); runtime._cast(id); var base := native.count
		select_weapon(runtime,id,2); runtime._cast(id)
		check(native.count == base+2,id+" native secondary actor quantity")
	runtime.native_skills = null
	for id in ["ranged_rookie_satellite_orbs","sage_astra_binary_stars"]:
		select_weapon(runtime,id,2,10); runtime.evolved[id] = true
		var stats: Dictionary = runtime.stats_for(id)
		check(stats.orbit_count == 10,id+" MAX orbit reaches ten satellites")
		check(runtime.delivery.cast(id,stats,hero.position,100,250,10),id+" orbit cast")
		for slot in runtime.delivery.slots:
			if slot.left > 0: check(slot.count == int(stats.orbit_count),id+" actual orbit slot")
	for id in ["summoner_hero_watcher","summoner_hero_gatekeeper"]:
		select_weapon(runtime,id,2)
		var actor = Watcher.new() if id.ends_with("watcher") else Gatekeeper.new()
		var visual := AnimatedSprite2D.new(); visual.name = "Visual"; actor.add_child(visual)
		for name in ["AttackAudio","SummonAudio"]:
			var audio := AudioStreamPlayer.new(); audio.name = name; actor.add_child(audio)
		var collision := CollisionShape2D.new(); collision.name = "CollisionShape2D"; actor.add_child(collision)
		arena.add_child(actor)
		actor.owner_hero = hero; actor.survival_weapon_id = id; actor.attack_damage = 20; actor.attack_range = 400
		actor.call("_fire_at_target" if id.ends_with("watcher") else "_fire_at",target)
		check(actor.primary.calls == 1 and active_shots(runtime) == 2,id+" actual ranged summon fires base plus two")
		actor.primary.free(); actor.free()
	select_weapon(runtime,"ranged_rookie_arcane_bolt",2)
	for index in 200: runtime._cast("ranged_rookie_arcane_bolt")
	check(runtime.projectiles.size() == 64 and active_shots(runtime) <= 64,"saturated shots keep fixed pool")
	check(float(runtime.projectiles[0].get("visual_radius",0)) == 28.0,"visible radius cached at emission")
	check(RUNTIME.GEOMETRY.PROJECTILE_RADIUS == 12.0,"collision radius unchanged")
	check(DATA.projectile_visual_radius({"pattern":"bolt"}) == 28.0 and DATA.projectile_visual_radius({"pattern":"burst"}) == 22.0,"visible projectiles enlarged")
	var bullet := SUMMON_BOLT.new()
	bullet.sprite = Sprite2D.new(); bullet.add_child(bullet.sprite)
	bullet.set_meta("survival_presentation",true)
	bullet._fit_survival_sprite(Rect2(-10,-5,20,10),52.0)
	check(is_equal_approx(bullet.sprite.scale.x,2.6) and bullet.sprite.offset == Vector2.ZERO,"native summon visible alpha fit")
	bullet.set_meta("survival_presentation",false); bullet.sprite.scale = Vector2.ONE*.42
	bullet._fit_survival_sprite(Rect2(-10,-5,20,10),52.0)
	check(bullet.sprite.scale == Vector2.ONE*.42 and SUMMON_BOLT.HIT_RADIUS == 30.0,"AI summon size and collision preserved")
	bullet.free()
	var native_arena := NativeArena.new(); root.add_child(native_arena)
	var native_hero := NativeHero.new(); native_arena.add_child(native_hero)
	var actors := NATIVE.new(); actors.hero = native_hero; actors.authority = native_arena
	for pair in [["ranged_rookie_magic_lance",6],["sage_astra_comet",8]]:
		var pattern: String = DATA.WEAPONS[pair[0]].pattern
		var spec: Array = NATIVE.SCENES[pattern]
		native_arena.projectile_pools[spec[1]] = []
		var nodes: Array = []
		for index in int(pair[1]):
			var node := NativeShot.new(); native_arena.add_child(node)
			native_arena.projectile_pools[spec[1]].append(node); nodes.append(node)
		var data: Dictionary = DATA.GROWTH.resolve(pair[0],DATA.WEAPONS[pair[0]],10,true)
		check(actors.cast(data,Vector2.ZERO,Vector2.RIGHT,target,100,400,int(pair[1]),10,1.0,true),pattern+" actual native dispatch")
		var fired := 0
		for node in nodes: fired += node.calls
		check(fired == int(pair[1]),pattern+" startup pool supports augmented maximum")
	native_arena.queue_free()
	var draw_script: Script = load("res://tests/projectile_draw_harness.gd")
	var draw_spy := DrawSpy.new(); arena.add_child(draw_spy)
	var renderer = draw_script.new(); renderer.hero = draw_spy
	var bitmap := Image.create(16,16,false,Image.FORMAT_RGBA8); bitmap.fill(Color.WHITE)
	var texture := ImageTexture.create_from_image(bitmap)
	renderer.projectiles = [{"active":true,"melee":false,"delay":0.0,"position":Vector2.ZERO,"direction":Vector2.RIGHT,"age":0.0,"visual_radius":28.0,"frames":[texture]}]
	renderer.draw()
	check(draw_spy.rect == Rect2(-28,-28,56,56),"actual textured orb draw footprint56")
	renderer.projectiles[0].visual_radius = 22.0
	renderer.draw()
	check(draw_spy.rect == Rect2(-22,-22,44,44),"actual textured bullet draw footprint44")
	hero.player_weapons = null
	arena.queue_free(); await process_frame
	print("PROJECTILE_QUANTITY checks=",checks," failures=",failures)
	quit(1 if failures else 0)
