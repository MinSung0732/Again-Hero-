extends Control
## One retained background + bounded procedural animation; no particle nodes.
signal cancelled
signal rules_requested
const DATA := preload("res://src/data/online_loading_catalog.gd")
const ROW_SKIN := preload("res://src/ui/mission_row_skin.gd")
var role_theme := {}
var clock := 0.0
var title: Label
var subtitle: Label
var elapsed: Label
var last_second := -1
var hint: Label
var meter: ProgressBar
var cancel: Button
var backdrop: TextureRect
var phase := ""
var map_summary := ""
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP; z_index = 50
	backdrop = TextureRect.new(); add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shade := ColorRect.new(); add_child(shade); shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.01,0.01,0.04,0.32); shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var margin := MarginContainer.new(); add_child(margin); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right"]: margin.add_theme_constant_override("margin_"+side,DATA.MARGIN_X)
	for side in ["top","bottom"]: margin.add_theme_constant_override("margin_"+side,DATA.MARGIN_Y)
	var rows := VBoxContainer.new(); margin.add_child(rows); rows.add_theme_constant_override("separation",DATA.ROW_GAP)
	title = label(rows,46); elapsed = label(rows,30); subtitle = label(rows,25)
	var space := Control.new(); space.size_flags_vertical = Control.SIZE_EXPAND_FILL; rows.add_child(space)
	meter = ProgressBar.new(); meter.custom_minimum_size.y = 12; meter.show_percentage = false; rows.add_child(meter)
	var tip_box := PanelContainer.new(); rows.add_child(tip_box)
	var tip_style := StyleBoxFlat.new(); tip_style.bg_color = DATA.TIP_BACKGROUND
	tip_style.set_content_margin_all(DATA.TIP_PADDING); tip_box.add_theme_stylebox_override("panel",tip_style)
	hint = label(tip_box,23)
	var rules := Button.new(); rules.text = DATA.RULES_TEXT; rows.add_child(rules)
	ROW_SKIN.apply_button(rules); rules.custom_minimum_size.y = DATA.BUTTON_HEIGHT
	rules.add_theme_font_size_override("font_size",DATA.BUTTON_FONT)
	rules.pressed.connect(func(): rules_requested.emit())
	cancel = Button.new(); cancel.text = DATA.CANCEL_TEXT; rows.add_child(cancel)
	ROW_SKIN.apply_button(cancel); cancel.custom_minimum_size.y = DATA.BUTTON_HEIGHT
	cancel.add_theme_font_size_override("font_size",DATA.BUTTON_FONT)
	cancel.pressed.connect(func(): cancelled.emit())
	visible = false; set_process(false)
func label(parent: Node,font: int) -> Label:
	var value := Label.new(); value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value.add_theme_font_size_override("font_size",font)
	value.add_theme_color_override("font_shadow_color",Color.BLACK); value.add_theme_constant_override("shadow_offset_y",3)
	parent.add_child(value); return value
func begin(role: String) -> void:
	map_summary = ""
	role_theme = DATA.theme(role); backdrop.texture = load(role_theme.art) as Texture2D
	title.modulate = role_theme.accent; meter.modulate = role_theme.accent
	clock = 0; last_second = -1; show_phase("queue"); visible = true; set_process(true)
func show_phase(value: String,progress: float = 0.0) -> void:
	phase = value
	_update_elapsed()
	title.text = role_theme.name+" · "+("상대를 찾는 중" if value == "queue" else "전투 준비")
	subtitle.text = role_theme.tag if value == "queue" else map_summary + "\n" + ("전장과 군단을 준비하는 중…" if value == "loading" else "준비 완료 · 상대방을 기다리는 중…")
	hint.text = role_theme.hint
	meter.visible = value != "queue"; meter.value = clampf(progress,0,1)*100
func set_map(map_data: Dictionary) -> void:
	map_summary = "%s · %s · %d분" % [map_data.name,preload("res://src/data/ranked_map_catalog.gd").favor_label(String(map_data.favor)),int(map_data.duration_seconds)/60]
	if phase != "queue": show_phase(phase,meter.value/100.0)
func finish() -> void:
	visible = false; set_process(false); backdrop.texture = null
func _process(delta: float) -> void:
	clock += delta
	if int(clock) != last_second: _update_elapsed()
	queue_redraw()
func _update_elapsed() -> void:
	last_second = int(clock)
	elapsed.visible = phase == "queue"
	if elapsed.visible: elapsed.text = DATA.QUEUE_TIME % [last_second / 60,last_second % 60]
func _draw() -> void:
	if role_theme.is_empty(): return
	var accent: Color = role_theme.accent
	var center := Vector2(size.x*0.5,size.y*0.78)
	var radius := minf(size.x*0.12,size.y*0.055)
	draw_arc(center,radius,clock*DATA.SPIN_SPEED,clock*DATA.SPIN_SPEED+TAU*0.7,36,accent,3,false)
	for index in DATA.PARTICLES:
		var seed_x := float(posmod(index*37,101))/101.0
		var y := 1.0-fposmod(float(index)/DATA.PARTICLES+clock*DATA.PARTICLE_SPEED,1.0)
		var alpha := sin(y*PI)*0.65
		draw_rect(Rect2(Vector2(size.x*seed_x,size.y*y),Vector2.ONE*(2+index%3)),Color(accent,alpha))
