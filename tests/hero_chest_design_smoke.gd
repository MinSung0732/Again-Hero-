extends SceneTree
const DATA := preload("res://src/data/hero_weapon_catalog.gd")
class Rewards extends RefCounted:
	var levels := {}
	var passives := {}
	var evolved := {}
	var count := 0
	var receipt := {}
	func _init():
		var ids: Array = DATA.weapon_pool("ranged_rookie").slice(0,3)
		for id in ids: levels[id] = 5
		receipt = {"pool":ids,"id":ids[1],"kind":"weapon","evolution":false,"name":String(DATA.WEAPONS[ids[1]].name)+" Lv.6","description":"기본 피해·사거리 증가 · 재사용 대기시간 감소\n추가 공격 강화","applied":false}
	func roll_chest(): return receipt
	func apply_chest(value):
		if value.applied: return false
		count += 1; levels[value.id] += 1; value.applied = true; return true
class Hero extends RefCounted:
	var player_weapons := Rewards.new()
class Battle extends Node:
	var hero := Hero.new()
	var battle_over := false
	var external_pause := false
	func set_external_pause(value): external_pause = value
var checks := 0
var failures := 0
func _initialize(): call_deferred("run")
func check(ok,message):
	checks += 1
	if not ok: failures += 1; push_error(message)
func run():
	for viewport in [Vector2i(1080,1920),Vector2i(540,960),Vector2i(1920,1080),Vector2i(960,540)]:
		root.size = viewport
		var host = load("res://tests/hero_chest_binding_harness.gd").new(); root.add_child(host)
		host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		host.battle = Battle.new(); host.add_child(host.battle)
		await process_frame
		host._begin_roulette(); host.roulette_tween.kill()
		await process_frame; await process_frame; await process_frame
		check(host.rolling and host.battle.external_pause and not host.pad.enabled and host.inventory_dim.visible,"roll captures battle input")
		host._close_roulette()
		check(host.rolling and host.roulette_continue.disabled,"reward cannot dismiss early")
		var rect: Rect2 = host.overlay.get_global_rect()
		check(rect.position.x >= 0 and rect.end.x <= viewport.x and rect.position.y >= 0 and rect.end.y <= viewport.y,"popup stays in viewport")
		var reel = host.roulette_reel
		check(reel.cards[0].position.x < reel.cards[1].position.x and reel.cards[1].position.x < reel.cards[2].position.x,"three horizontal cards")
		check(reel.cards[1].size.y > reel.cards[0].size.y,"center reward emphasized")
		for card in reel.cards:
			check(card.position.x >= 0 and card.position.x+card.size.x <= reel.size.x,"card inside reel")
		host._finish_roulette(); host._finish_roulette()
		await process_frame; await process_frame
		check(host.battle.hero.player_weapons.count == 1 and host.refresh_count == 1,"reward applies and refreshes exactly once")
		check(reel.displayed_id == String(host.roulette_receipt.id) and reel.center_label.text == String(host.roulette_receipt.name),"center matches actual reward")
		check(not host.roulette_continue.disabled and host.roulette_continue.text == "계속 플레이","continue unlocks after reward")
		check(host.roulette_continue.get_global_rect().end.y <= viewport.y,"fixed continue stays visible")
		var point: Vector2 = host.roulette_continue.get_global_rect().get_center()
		if viewport.x < viewport.y:
			var touch := InputEventScreenTouch.new(); touch.index = 3; touch.position = point; touch.pressed = true
			Input.parse_input_event(touch); Input.flush_buffered_events(); await process_frame
			touch = touch.duplicate(); touch.pressed = false; Input.parse_input_event(touch); Input.flush_buffered_events()
		else:
			var mouse := InputEventMouseButton.new(); mouse.position = point; mouse.global_position = point; mouse.button_index = MOUSE_BUTTON_LEFT; mouse.pressed = true
			Input.parse_input_event(mouse); Input.flush_buffered_events(); await process_frame
			mouse = mouse.duplicate(); mouse.pressed = false; Input.parse_input_event(mouse); Input.flush_buffered_events()
		await process_frame
		check(not host.rolling and not host.battle.external_pause and host.pad.enabled and not host.inventory_dim.visible,"continue resumes and clears backdrop")
		host.queue_free(); await process_frame
	print("HERO_CHEST_DESIGN checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
