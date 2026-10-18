extends SceneTree
const BASE := preload("res://tests/hero_weapon_extension_smoke.gd")
const RUNTIME := preload("res://src/hero_mode/hero_weapon_runtime.gd")
const GAUGE := preload("res://src/hero_mode/hero_control_gauge.gd")
var checks := 0
var failures := 0
class Hero extends BASE.Hero:
	var fear_timer := 0.0
	var stun_timer := 0.0
	var charm_timer := 0.0
class Canvas extends RefCounted:
	var rects: Array = []
	var labels: Array = []
	func record_draw_rect(rect: Rect2, color: Color) -> void: rects.append({"rect":rect,"color":color})
	func record_draw_string(_font, position: Vector2, text: String, _alignment, _width, _size, color: Color) -> void: labels.append({"position":position,"text":text,"color":color})
func _initialize() -> void: call_deferred("run")
func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(text)
func run() -> void:
	var arena := BASE.Arena.new(); root.add_child(arena)
	var hero := Hero.new(); arena.add_child(hero)
	var runtime := RUNTIME.new(); runtime.install(hero)
	var target := BASE.Target.new(); arena.add_child(target); target.position = Vector2(600,0); arena.targets.append(target)
	var data: Dictionary = runtime.DATA.WEAPONS.ranged_rookie_arcane_bolt
	runtime._effect(Vector2(100,100),Vector2(200,100),30,"nova",Color.WHITE,data)
	runtime._launch_projectile(target,Vector2.ZERO,10,1,Color.WHITE,data)
	var initial: Vector2 = runtime.effects[0].a
	var cooldown: float = runtime.cooldowns[runtime.weapon_ids[0]]
	hero.position = Vector2(200,0); runtime.tick(0.1,false)
	check(runtime.effects[0].a == initial,"fixed effect retains world origin after forced movement")
	check(is_equal_approx(runtime.effects[0].left,0.18),"effect ages during control lock")
	check(runtime.projectiles[0].position != Vector2.ZERO,"already launched projectile progresses during control")
	check(runtime.cooldowns[runtime.weapon_ids[0]] == cooldown,"control lock cannot cast or consume new weapon cooldown")
	runtime.tick(0.2,false); check(runtime.effects[0].left == 0,"effect expires instead of sticking to hero")
	var gauge := GAUGE.new()
	hero.fear_timer = 2; hero.stun_timer = 3; hero.slow_timer = 4; hero.move_multiplier = 0.01; hero.petrify_timer = 5; hero.charm_timer = 6
	gauge.sample(hero)
	for i in 5: check(gauge.totals[i] == i+2,"accepted timer captured for control slot")
	hero.fear_timer = 1; gauge.commit(hero); gauge.sample(hero)
	check(gauge.totals[0] == 2 and gauge.remaining(hero,0)/gauge.totals[0] == 0.5,"white duration gauge drains")
	hero.fear_timer = 2; gauge.sample(hero)
	check(gauge.totals[0] == 2,"equal duration refresh resets from decremented timer")
	hero.fear_timer = 4; gauge.sample(hero); check(gauge.totals[0] == 4,"longer reapplication restarts gauge")
	hero.fear_timer = 0; gauge.sample(hero); check(gauge.totals[0] == 0,"cleanse or expiry hides duration gauge")
	var painter = load("res://tests/hero_control_gauge_draw_harness.gd").new()
	var canvas := Canvas.new(); hero.set_meta("root_like_slow",true)
	hero.fear_timer = 2; painter.sample(hero); hero.fear_timer = 1
	painter.draw_on(canvas,hero,-120,92)
	check(canvas.rects.size() == 10 and canvas.labels.size() == 5,"simultaneous statuses have separate rows")
	check(is_equal_approx(canvas.rects[1].rect.size.x,46),"rendered bar width equals remaining fraction")
	for i in 5:
		check(canvas.rects[i*2+1].color == Color.WHITE,"duration fill is white")
		check(canvas.labels[i].position.y == -123-i*24,"control rows do not overlap")
	check(canvas.labels[2].text.begins_with("속박"),"binding label survives slow resistance representation")
	# Test the production physics wrapper with forced movement and early returns.
	var physics = load("res://tests/hero_control_physics_harness.gd").new(); root.add_child(physics)
	physics._physics_process(0.1)
	check(physics.player_weapons.blocked_ticks == 1 and physics.player_weapons.normal_ticks == 0,"real wrapper updates presentation on control early return")
	physics.controlled = false; physics._physics_process(0.1)
	check(physics.player_weapons.blocked_ticks == 1 and physics.player_weapons.normal_ticks == 1,"ordinary update not duplicated")
	physics.channel_after_tick = true; physics._physics_process(0.1)
	check(physics.player_weapons.blocked_ticks == 1 and physics.player_weapons.normal_ticks == 2,"channel entered after cast cannot double tick")
	physics.player_controlled = false; physics.controlled = true; physics._physics_process(0.1)
	check(physics.player_weapons.blocked_ticks == 1,"demon AI path unchanged")
	physics.queue_free(); arena.queue_free(); await process_frame
	print("HERO_CONTROL_STATUS checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
