extends Control
## Practice-only HUD; no polling or allocations in the frame loop.
var host: Control
var attack_button: Button

func install(main: Control) -> void:
	host = main
	if not host.battle.practice_mode:
		queue_free()
		return
	name = "PracticeControls"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 70
	host.hud_layer.add_child(self)
	attack_button = Button.new()
	attack_button.name = "AttackToggle"
	attack_button.toggle_mode = true
	attack_button.button_pressed = true
	attack_button.text = "공격 ON"
	attack_button.focus_mode = Control.FOCUS_NONE
	attack_button.add_theme_font_size_override("font_size",24)
	add_child(attack_button)
	host._replace_button_frame(attack_button,host.BATTLE_PIXEL_FRAME_MEDIUM_DIR,0.25,host.BATTLE_PIXEL_CENTER_DARK,18)
	attack_button.toggled.connect(_toggle_attack)
	host.battle_viewport_container.resized.connect(_layout)
	host.get_viewport().size_changed.connect(_layout)
	_layout.call_deferred()

func _layout() -> void:
	var panel: Rect2 = host.battle_viewport_container.get_global_rect()
	global_position = panel.position
	size = panel.size
	attack_button.size = Vector2(190,56)
	attack_button.position = Vector2(maxf(size.x-206,0.0),18)

func _toggle_attack(enabled: bool) -> void:
	attack_button.text = "공격 ON" if enabled else "공격 OFF"
	if is_instance_valid(host.battle.hero):
		host.battle.hero.set_practice_attack_enabled(enabled)
