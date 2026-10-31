extends SceneTree
## Hero-only preferences: mobile scroll UI, alpha mapping and guide toggle.
const SETTINGS := preload("res://src/ui/BattleSettings.tscn")
const CONTROLS := preload("res://src/ui/hero_combat_visual_settings.gd")
const WEAPON := preload("res://src/hero_mode/hero_weapon_runtime.gd")
const NATIVE := preload("res://src/hero_mode/hero_weapon_native_runtime.gd")
const GEOMETRY := preload("res://src/hero_mode/hero_weapon_geometry.gd")
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
	var visual := Sprite2D.new()
	visual.name = "Visual"
	actor.add_child(visual)
	var attraction := Node2D.new()
	attraction.name = "AttractionLayer"
	actor.add_child(attraction)
	native.actors_by_pattern["meteor"] = [actor]
	weapons.set_visual_settings(25.0,false)
	check(is_equal_approx(weapons.effect_opacity,0.75),"25 percent transparency means 75 percent opacity")
	check(not weapons.attack_range_visible,"attack range guides disabled")
	check(is_equal_approx(weapons._fx_color(Color(1,1,1,0.4)).a,0.3),"source color alpha remains proportional")
	check(is_equal_approx(visual.modulate.a,0.75) and is_equal_approx(attraction.modulate.a,0.75),"native art and particles receive the transparency")
	check(is_equal_approx(actor.modulate.a,1.0) and not actor.get_meta("hero_attack_range_visible",true),"native parent stays opaque for independent guides")
	weapons.set_visual_settings(100.0,true)
	check(is_zero_approx(visual.modulate.a) and is_zero_approx(attraction.modulate.a),"100 percent hides only native effect art")
	check(is_equal_approx(actor.modulate.a,1.0) and actor.get_meta("hero_attack_range_visible",false),"native range parent remains visible at 100 percent")
	check(is_equal_approx(weapons._range_guide_color(Color(0.2,0.8,1.0,0.01)).a,GEOMETRY.RANGE_GUIDE_ALPHA),"guides ignore effect opacity and authored alpha")
	check(is_zero_approx(weapons._fx_color(Color(1,1,1,1)).a),"100 percent hides regular weapon effects")
	weapons.set_visual_settings(-20.0,true)
	check(is_equal_approx(weapons.effect_opacity,1.0) and is_equal_approx(visual.modulate.a,1.0),"transparency clamps to original full brightness")
	check(is_equal_approx(GEOMETRY.AREA_TEXTURE_ALPHA,1.0) and is_equal_approx(GEOMETRY.BEAM_TEXTURE_ALPHA,1.0),"zero transparency has no extra texture dimming")
	check(is_equal_approx(weapons._fx_color(Color(1,1,1,1)).a,1.0),"regular visual fully opaque at zero transparency")
	check(is_equal_approx(weapons._range_guide_color(Color.WHITE).a,GEOMETRY.RANGE_GUIDE_ALPHA),"range guides do not depend on effect alpha")
	settings.queue_free()
	hero.queue_free()
	await process_frame
	print("HERO_VISUAL_SETTINGS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
