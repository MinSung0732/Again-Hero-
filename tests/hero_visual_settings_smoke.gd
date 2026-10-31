extends SceneTree
## Hero-only preferences: mobile scroll UI, alpha mapping and guide toggle.
const SETTINGS := preload("res://src/ui/BattleSettings.tscn")
const CONTROLS := preload("res://src/ui/hero_combat_visual_settings.gd")
const WEAPON := preload("res://src/hero_mode/hero_weapon_runtime.gd")
const NATIVE := preload("res://src/hero_mode/hero_weapon_native_runtime.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("HERO_VISUAL_SETTINGS: "+label)

func run() -> void:
	var settings := SETTINGS.instantiate()
	root.add_child(settings)
	var tabs: TabContainer = settings.get_node("Panel/Margin/VBox/SettingsTabs")
	var gameplay: VBoxContainer = tabs.get_node("Gameplay")
	var frame_checkbox: CheckBox = gameplay.get_node("BattleFrame")
	var slider_sample: HSlider = tabs.get_node("Sound/BGMRow/Slider")
	var seen_transparency: Array = []
	var seen_range: Array = []
	var controls: Dictionary = CONTROLS.install(gameplay,slider_sample,frame_checkbox,
		func(value: float): seen_transparency.append(value),
		func(value: bool): seen_range.append(value))
	check(gameplay.get_child_count() == 1 and gameplay.get_child(0) is ScrollContainer,"hero gameplay content is scrollable")
	check(controls.battle_frame == frame_checkbox and controls.camera != null,"shared camera/frame settings survive")
	var opacity: HSlider = controls.transparency_slider
	check(opacity.min_value == 0 and opacity.max_value == 100 and opacity.step == 1,"slider covers every 0-100 percent")
	opacity.value = 75
	check(not seen_transparency.is_empty() and is_equal_approx(float(seen_transparency.back()),75),"slider changes notify host")
	var show_range: CheckBox = controls.range_checkbox
	show_range.button_pressed = false
	check(not seen_range.is_empty() and not bool(seen_range.back()),"attack guide checkbox notifies host")

	var weapons := WEAPON.new()
	var hero := Node2D.new()
	root.add_child(hero)
	weapons.hero = hero
	var native := NATIVE.new()
	weapons.native_skills = native
	var actor := Area2D.new()
	hero.add_child(actor)
	native.actors_by_pattern["meteor"] = [actor]
	weapons.set_visual_settings(25.0,false)
	check(is_equal_approx(weapons.effect_opacity,0.75),"25 percent transparency means 75 percent opacity")
	check(not weapons.attack_range_visible,"attack range guides disabled")
	check(is_equal_approx(weapons._fx_color(Color(1,1,1,0.4)).a,0.3),"source color alpha remains proportional")
	check(is_equal_approx(actor.modulate.a,0.75) and not actor.get_meta("hero_attack_range_visible",true),"native effects inherit both preferences")
	weapons.set_visual_settings(100.0,true)
	check(is_zero_approx(actor.modulate.a) and weapons.attack_range_visible,"100 percent hides effects without hiding guides")
	weapons.set_visual_settings(-20.0,true)
	check(is_equal_approx(weapons.effect_opacity,1.0) and is_equal_approx(actor.modulate.a,1.0),"transparency clamps to visible")
	settings.queue_free()
	hero.queue_free()
	await process_frame
	print("HERO_VISUAL_SETTINGS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
