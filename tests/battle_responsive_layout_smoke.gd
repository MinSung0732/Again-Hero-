extends SceneTree
const LAYOUT := preload("res://src/ui/battle_responsive_layout.gd")
class Host extends Control:
	var summon_slot_1: Button
	var summon_slot_2: Button
	var summon_slot_3: Button
	var battle_frame_enabled := true
	var sync_count := 0
	func _sync_skill_unlock_cutscene_frame() -> void: sync_count += 1
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	root.size = Vector2i(1080,1920)
	var host := Host.new()
	root.add_child(host)
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var hud := Control.new(); hud.name = "HUD"; host.add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for name in ["TopBar","DemonUltimatePanel","BottomBar"]:
		var group := Control.new(); group.name = name; hud.add_child(group)
		group.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		var panel := Control.new(); panel.name = "Panel"; panel.position = Vector2(20,4); panel.size = Vector2(1040,100); group.add_child(panel)
	var cooldown := Control.new(); cooldown.name = "HeroSkillCooldownBar"; hud.add_child(cooldown)
	var slots := HBoxContainer.new(); slots.name = "SummonButtons"; slots.position = Vector2(20,96); slots.size = Vector2(1040,158)
	slots.add_theme_constant_override("separation",10); hud.get_node("BottomBar").add_child(slots)
	var buttons: Array[Button] = []
	for index in 3:
		var button := Button.new(); button.custom_minimum_size = Vector2(332,158); slots.add_child(button); buttons.append(button)
		for name in ["Icon","Name","Cost"]:
			var child := Control.new(); child.name = name; child.position = Vector2(138,36); child.size = Vector2(176,42); button.add_child(child)
	host.summon_slot_1 = buttons[0]; host.summon_slot_2 = buttons[1]; host.summon_slot_3 = buttons[2]
	var background := Control.new(); background.name = "ScreenBackground"; host.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := Control.new(); backdrop.name = "TopHUDBackdrop"; background.add_child(backdrop)
	backdrop.size = Vector2(1080,300)
	var reflow := LAYOUT.new(); reflow.install(host)
	for width in [1080,1440,1536,2560,1080]:
		root.size = Vector2i(width,1920)
		for tick in 4: await process_frame
		reflow.refresh()
		for tick in 2: await process_frame
		assert(is_equal_approx(backdrop.size.x,width))
		assert(is_equal_approx(slots.size.x,1040.0*width/1080))
		assert(slots.get_child(2).get_rect().end.x >= slots.size.x-1)
		for button in buttons:
			assert(button.size_flags_horizontal == Control.SIZE_EXPAND_FILL)
			assert(button.size.y >= 158)
			assert(button.get_node("Name").get_rect().end.x <= button.size.x+1)
		var panel := hud.get_node("TopBar/Panel") as Control
		assert(is_equal_approx(panel.size.x,1040.0*width/1080))
		assert(panel.size.y == 100)
		assert(is_equal_approx(cooldown.size.x,470.0*width/1080))
	var old_sync := host.sync_count
	host.queue_free()
	await process_frame
	assert(not root.size_changed.is_connected(reflow.refresh))
	print("PASS responsive battle widths, slot fill and phone restoration; syncs=",old_sync)
	quit()
