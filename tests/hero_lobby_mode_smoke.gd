extends SceneTree
const VIEW := preload("res://src/ui/hero_lobby_view.gd")
const MODES := preload("res://src/ui/lobby_main_modes_view.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const STORE := preload("res://src/systems/hero_mode_store.gd")
class Host extends Control:
	const STAGE_PROGRESS := preload("res://src/systems/stage_progress.gd")
	var hero_lobby_view
	var main_modes_view
	var shop_button := Button.new()
	var team_button := Button.new()
	var research_button := Button.new()
	var main_button := Button.new()
	var other_button := Button.new()
	var title_label := Label.new()
	var shop_tab := Control.new()
	var team_tab := Control.new()
	var research_tab := Control.new()
	var current_tab := "main"
	var stage_ids := ["stage_1"]
	var selected_stage_index := 0
	var _portrait_texture_cache := {}
	func _refresh_nav_button(_button: Button,_selected: bool) -> void: pass
	func _apply_lobby_button_skin(_button: Button,_selected: bool,_size: int) -> void: pass
	func _format_shop_number(value: int) -> String: return str(value)
	func _refresh_header() -> void: pass
	func _refresh_stage_card() -> void: hero_lobby_view.set_active(main_modes_view.perspective == "hero")
	func _load_png_texture_direct(_path: String) -> Texture2D: return PlaceholderTexture2D.new()
	func _load_texture(_path: String) -> Texture2D: return PlaceholderTexture2D.new()
	func _normalize_hero_portrait_texture(texture: Texture2D) -> Texture2D: return texture
func _initialize() -> void: call_deferred("run")
func run() -> void:
	SCOPE.select_guest(); SCOPE.guest_directory = "user://lobby_mode_"+str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)
	# LocalTestMode/PresentationWarmup are real autoloads (a same-named fake node would be
	# renamed and ignored), so unlock hero mode the real way: demon easy stage 3 cleared.
	var unlocks := ConfigFile.new()
	for stage_id in ["stage_1","stage_2","stage_3"]: unlocks.set_value("cleared",stage_id,true)
	assert(SCOPE.save_config(unlocks,"user://stage_progress.cfg") == OK)
	var host := Host.new(); root.add_child(host)
	var backdrop := TextureRect.new(); backdrop.name = "LobbyBackground"; backdrop.texture = PlaceholderTexture2D.new(); host.add_child(backdrop)
	var original := backdrop.texture
	var dim := ColorRect.new(); dim.name = "Background"; host.add_child(dim)
	for tab in [host.shop_tab,host.team_tab,host.research_tab]:
		host.add_child(tab); var label := Label.new(); label.text = "Demon original"; tab.add_child(label)
	for button in [host.shop_button,host.team_button,host.research_button,host.main_button,host.other_button]: host.add_child(button)
	host.add_child(host.title_label)
	var view := VIEW.new(); var modes := MODES.new()
	host.hero_lobby_view = view; host.main_modes_view = modes; modes.lobby = host; view.install(host)
	assert(await modes._prepare_perspective("hero",STORE.owner()))
	assert(view.active and modes.perspective == "hero" and backdrop.texture != original)
	assert(host.shop_button.text == "용사상점" and host.team_button.text == "캐릭터 편성")
	assert(not host.team_tab.get_child(0).visible and view.panels.team.visible)
	host.current_tab = "shop"; view.rebuild("shop")
	assert(view.bodies.shop.get_child(0).text.contains("용사 상점"))
	assert(view.bodies.shop.find_child("HeroSummonSection",true,false) != null)
	assert(view.bodies.shop.find_child("HeroPickupSection",true,false) != null)
	var shop_buttons: Array[Node] = view.bodies.shop.find_children("*","Button",true,false)
	assert(shop_buttons.size() == 5)
	# GameAudio (autoload) attaches its global click sound to every Button; nothing else may.
	var game_audio := root.get_node("GameAudio")
	for button in shop_buttons: assert(button.disabled and button.pressed.get_connections().all(func(link): return link.callable.get_object() == game_audio))
	var single := view.bodies.shop.find_child("SingleSummonArt",true,false) as TextureRect
	var multi := view.bodies.shop.find_child("MultiSummonArt",true,false) as TextureRect
	assert(single.texture != null and multi.texture != null and single.texture != multi.texture)
	assert(single.texture.resource_path.contains("hero_shop_v2") and multi.texture.resource_path.contains("hero_shop_v2"))
	assert(view.panels.shop.get_theme_stylebox("panel") is StyleBoxTexture)
	for width in [1080,1536]:
		host.shop_tab.size = Vector2(width,1700); await process_frame; await process_frame
		assert(single.size.x > 0 and multi.size.x > 0)
		assert(view.bodies.shop.find_child("HeroSummonCards",true,false).size.x < width)
	host.current_tab = "research"; view.rebuild("research")
	assert(view.growth_cards.size() == 12 and view.growth_labels.balance.text.ends_with(" P"))
	assert(view.bodies.research.find_child("HeroResearchGrid",true,false).columns == 4)
	view._select_growth("power"); assert(view.selected_growth == "power")
	assert(await modes._prepare_perspective("demon",STORE.owner()))
	assert(not view.active and backdrop.texture == original and host.team_tab.get_child(0).visible)
	host.hero_lobby_view = null
	assert(not await modes._prepare_perspective("hero",STORE.owner()) and modes.perspective == "demon")
	host.queue_free(); await process_frame
	print("HERO_LOBBY_MODE_SMOKE PASS: actual mode preparation, theme/nav/panels/research and missing-extension gate")
	quit()
