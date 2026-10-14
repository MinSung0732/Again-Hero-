extends SceneTree
const DETAIL := preload("res://src/ui/hero_inventory_detail.gd")
var checks := 0
var failures := 0
func _initialize(): call_deferred("run")
func check(ok,message):
	checks += 1
	if not ok: failures += 1; push_error(message)
func run():
	root.size = Vector2i(1080,1920)
	var host = load("res://tests/hero_dropdown_harness.gd").new(); root.add_child(host)
	var tabs := TabContainer.new(); tabs.size = Vector2(850,600); host.add_child(tabs)
	var gameplay := VBoxContainer.new(); gameplay.name = "Gameplay"; tabs.add_child(gameplay)
	host.build(tabs); await process_frame; await process_frame
	var option: OptionButton = host.pad_mode_selector; var popup := option.get_popup()
	check(option.size.y >= 88 and option.get_theme_font_size("font_size") == 30,"selector mobile size")
	check(popup.get_theme_font_size("font_size") == 32 and popup.get_theme_constant("v_separation") == 64,"dropdown text and row spacing")
	check(popup.item_count == 2 and popup.get_item_text(0) == "고정형 패드" and popup.get_item_text(1) == "자유형 패드","real pad choices")
	option.show_popup(); await process_frame; await process_frame
	check(popup.size.y >= 192,"actual popup rows large enough for touch")
	popup.hide(); option.item_selected.emit(1)
	check(host.selected == 1,"selection keeps existing callback")
	host.queue_free(); await process_frame
	print("HERO_DROPDOWN checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
