extends SceneTree
const DATA := preload("res://src/data/hero_weapon_catalog.gd")
const ART := preload("res://src/ui/hero_weapon_art.gd")
const ICONS := preload("res://src/ui/hero_augment_icons.gd")
const RUNTIME := preload("res://src/hero_mode/hero_weapon_runtime.gd")
const BASE := preload("res://tests/hero_weapon_extension_smoke.gd")
var checks := 0
var failures := 0
class Hero extends BASE.Hero:
	var hero_archetype := "ranged_kiter"
	var summon_ok := true
	var summoner_hound_config := {}
	var summoner_hound_cooldown := 0.0
	func _acquire_projectile(_scene, _key) -> Node: return null
	func _get_active_summon_count() -> int: return 0
	func _try_cast_summoner_hound() -> bool: return summon_ok
class Spy extends Node2D:
	var calls: Array = []
	func record_draw_texture_rect(texture: Texture2D, rect: Rect2, _tile: bool, _color: Color = Color.WHITE) -> void: calls.append({"texture":texture,"rect":rect})
	func record_draw_set_transform(_position: Vector2, _rotation: float = 0.0) -> void: pass
	func record_draw_circle(_position: Vector2, _radius: float, _color: Color) -> void: pass
	func record_draw_arc(_position: Vector2, _radius: float, _a: float, _b: float, _steps: int, _color: Color, _width: float = 1.0) -> void: pass
	func record_draw_line(_a: Vector2, _b: Vector2, _color: Color, _width: float = 1.0) -> void: pass
	func record_draw_colored_polygon(_points: PackedVector2Array, _color: Color) -> void: pass
	func record_draw_polyline(_points: PackedVector2Array, _color: Color, _width: float = 1.0) -> void: pass
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("WEAPON_ART: "+label)
func hash_image(texture: Texture2D) -> String:
	var hash := HashingContext.new(); hash.start(HashingContext.HASH_SHA256); hash.update(texture.get_image().get_data()); return hash.finish().hex_encode()
func run() -> void:
	var icon_hashes := {}; var effect_paths := {}; var count := 0; var icon_count := 0
	for id in DATA.WEAPONS:
		var icon := ICONS.texture(id)
		check(icon != null,"icon exists "+id)
		var key := hash_image(icon)
		check(not icon_hashes.has(key),"distinct visible icon "+id); icon_hashes[key] = id
		var data: Dictionary = DATA.WEAPONS[id]
		if data.has("icon_index_v2"): icon_count += 1; check(icon.get_size() == Vector2(64,64),"new icon dimensions "+id)
		if not bool(data.get("visual_effect_unique",false)): continue
		count += 1
		check(not effect_paths.has(data.effect_dir),"one unique effect directory "+id); effect_paths[data.effect_dir] = true
		var frames := ART.sequence(data.effect_dir)
		check(frames.size() == 8,"eight frames "+id)
		var hashes := {}
		for frame in frames:
			check(frame.get_size() == frames[0].get_size() and frame.get_width() <= 128 and frame.get_width() == frame.get_height(),"common centered animation canvas "+id)
			if frame is AtlasTexture:
				check(frame.region.get_center() == Vector2(64,64) and frame.region == (frames[0] as AtlasTexture).region,"fixed original anchor and common crop "+id)
				var raw: Rect2i = frame.atlas.get_image().get_used_rect()
				check(frame.region.encloses(Rect2(raw)),"crop retains entire original effect "+id)
			hashes[hash_image(frame)] = true
		check(hashes.size() >= 4,"animated phases "+id)
		check(ART.sequence(data.effect_dir) == frames,"sequence reuse "+id)
	check(count == 91 and icon_count == 40 and icon_hashes.size() == 100,"complete art scope")
	for directory in ART.LAYOUTS.REGIONS:
		var baked := ART.sequence(directory)
		var raw_frames: Array[Texture2D] = []
		for index in range(1,9): raw_frames.append(load(directory+"/effect_%02d.png" % index) as Texture2D)
		var previous := ART._trim_common_margin(raw_frames)
		for index in range(8):
			check(hash_image(baked[index]) == hash_image(previous[index]),"baked crop pixel parity "+directory)
	var retained_path: String = DATA.WEAPONS.ranged_rookie_arcane_bolt.effect_dir
	var live_frames := ART.sequence(retained_path)
	ART.retain_sequences({retained_path:true})
	check(ART.cache.size() == 1 and ART.sequence(retained_path) == live_frames,"entry cache limited to selected kit")
	ART.retain_sequences({})
	check(ART.cache.is_empty() and live_frames.size() == 8 and hash_image(live_frames[0]) != "","live frame references survive eviction")
	var spy := Spy.new(); root.add_child(spy)
	var harness = load("res://tests/weapon_art_draw_harness.gd").new(); harness.hero = spy
	var frames := ART.sequence(DATA.WEAPONS.ranged_rookie_arcane_bolt.effect_dir)
	check(harness._loop_index(frames,7.0/12.0) == 7 and harness._loop_index(frames,8.0/12.0) == 6 and harness._loop_index(frames,13.0/12.0) == 1 and harness._loop_index(frames,14.0/12.0) == 0,"loop reflects through adjacent frames")
	for pattern in ["chain","orbit","combo","beam","slash","guard","heal","nova"]:
		spy.calls.clear()
		harness.effects = [{"left":0.14,"duration":0.28,"a":Vector2.ZERO,"b":Vector2(200,0),"radius":100.0,"pattern":pattern,"color":Color.WHITE,"frames":frames,"follow":false,"orbit_count":4,"orbit_speed":3.0,"orbit_ratio":0.7,"area_scale":1.0,"shape":PackedVector2Array([Vector2.ZERO,Vector2(100,-20),Vector2(100,20),Vector2.ZERO])}]
		harness.draw()
		check(not spy.calls.is_empty(),"actual texture dispatch "+pattern)
		for call in spy.calls: check(call.texture in frames and call.rect.size.x > 0 and call.rect.size.y > 0,"frame/geometry retained "+pattern)
	harness.effects.clear(); spy.calls.clear()
	harness.projectiles = [{"active":true,"melee":false,"delay":0.0,"position":Vector2(10,0),"frames":frames,"age":0.25,"direction":Vector2.RIGHT,"color":Color.WHITE}]
	harness.draw(); check(spy.calls.size() == 1 and spy.calls[0].texture in frames,"projectile bitmap replaces generic dots")
	var arena := BASE.Arena.new(); root.add_child(arena); var hero := Hero.new(); arena.add_child(hero)
	var runtime := RUNTIME.new(); runtime.install(hero)
	check(runtime.projectiles.size() == 64 and runtime.effects.size() == 48 and runtime.fields.size() == 8 and runtime.pulses.size() == 24,"bounded pools unchanged")
	check(hero.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST,"pixel filter")
	var target := BASE.Target.new(); arena.add_child(target); arena.targets.append(target); target.position = Vector2(100,0)
	runtime._launch_projectile(target,hero.global_position,10,1,Color.WHITE,DATA.WEAPONS.ranged_rookie_arcane_bolt)
	check(runtime.projectiles[0].frames.size() == 8,"pooled projectile snapshots warmed art")
	var native = runtime.native_skills; native.summon_configs = {"hound":{}}
	var data: Dictionary = DATA.WEAPONS.summoner_hero_gate_hound
	native.cast(data,Vector2.ZERO,Vector2.RIGHT,target,20,100,1,1,1.0)
	check(native.last_cast_succeeded,"successful summon visual gate")
	hero.summon_ok = false; native.cast(data,Vector2.ZERO,Vector2.RIGHT,target,20,100,1,1,1.0)
	check(not native.last_cast_succeeded,"failed summon cannot show a false portal")
	ART.cache.clear()
	var generic := BASE.Hero.new(); arena.add_child(generic)
	var generic_runtime := RUNTIME.new(); generic_runtime.install(generic)
	check(generic_runtime.native_skills == null and generic_runtime.art[DATA.STARTERS.ranged_rookie].size() == 8,"generic host warms weapon frames without native pool")
	check(ART.cache.has(DATA.WEAPONS.ranged_rookie_arcane_bolt.effect_dir),"generic launch has prepared frame cache")
	spy.queue_free(); arena.queue_free(); await process_frame
	print("HERO_WEAPON_ART checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
