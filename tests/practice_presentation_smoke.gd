extends SceneTree
const CATALOG := preload("res://src/data/monster_catalog.gd")
const OVERLAY := preload("res://src/ui/gacha_reveal_overlay.gd")
const CONTROLS := preload("res://src/ui/practice_battle_controls.gd")
var failures := 0
class Host extends Control:
	var battle: Node
	var hud_layer: CanvasLayer
	var battle_viewport_container: SubViewportContainer
	const BATTLE_PIXEL_FRAME_MEDIUM_DIR := ""
	const BATTLE_PIXEL_CENTER_DARK := ""
	func _replace_button_frame(_button, _dir, _scale, _center, _margin): pass
func _initialize(): run.call_deferred()
func check(ok: bool, message: String):
	if not ok:
		failures += 1
		push_error("PRESENTATION: "+message)
func run():
	root.get_node("CloudStore").stop()
	for id in ["zeus","bulgasal"]:
		check(CATALOG.get_ui_icon_path(id)==String(CATALOG.get_monster(id).card_icon_path),"pixel UI icon "+id)
	var overlay = OVERLAY.new()
	root.add_child(overlay)
	overlay.show()
	var icon = load(CATALOG.get_ui_icon_path("bulgasal"))
	overlay._results=[{"monster_id":"bulgasal","rarity":"transcendent","name":"불가살","icon":icon}]
	overlay._show_reveal(0)
	overlay._cutscene.set_process(false)
	await process_frame
	var view = overlay._cutscene._active_view
	check(view!=null and view.background.texture!=null,"production cutscene background connected")
	overlay._cutscene.advance(4.6)
	check(view.label.text=="불가살" and view.label.modulate.a>0.99,"bottom name visible")
	check(overlay._cutscene.z_index>overlay._flash.z_index and not overlay._door_flash.visible,"cutscene above production flash")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/practice_gacha_layering.png")
	overlay._cutscene.skip()
	check(overlay._phase=="reveal" and overlay._reveal_icon.texture==icon,"skip returns to actual pixel reveal")
	overlay.skip_to_results()
	check(overlay._phase=="result","final result connected")
	var mode = root.get_node("LocalTestMode")
	mode.active=true
	mode.tutorial_preview=false
	mode.request_practice_battle()
	var host := Host.new()
	host.battle=load("res://src/battle/Battle.tscn").instantiate()
	host.add_child(host.battle)
	host.hud_layer=CanvasLayer.new()
	host.add_child(host.hud_layer)
	host.battle_viewport_container=SubViewportContainer.new()
	host.battle_viewport_container.size=Vector2(540,400)
	host.add_child(host.battle_viewport_container)
	root.add_child(host)
	host.battle.set_process(false)
	host.battle.set_physics_process(false)
	var controls := CONTROLS.new()
	controls.install(host)
	await process_frame
	check(controls.attack_button.text=="공격 ON" and controls.attack_button.position.x>=0,"practice HUD default ON and inside panel")
	controls.attack_button.button_pressed=false
	check(not host.battle.hero.practice_attack_enabled and controls.attack_button.text=="공격 OFF","HUD toggles real dummy OFF")
	controls.attack_button.button_pressed=true
	check(host.battle.hero.practice_attack_enabled,"HUD toggles real dummy ON")
	overlay.queue_free()
	host.queue_free()
	await process_frame
	await process_frame
	print("PRACTICE_PRESENTATION: ","PASS" if failures==0 else "FAIL"," failures=",failures)
	quit(0 if failures==0 else 1)
