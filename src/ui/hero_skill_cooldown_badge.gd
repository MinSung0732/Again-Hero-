extends Control
class_name HeroSkillCooldownBadge

const SKILL_ART := preload("res://src/data/skill_icon_catalog.gd")
const BADGE_SIZE := Vector2(62.0, 62.0)
const ICON_MARGIN := 7.0

var skill_id: String = ""
var skill_name: String = ""
var description: String = ""
var icon_path: String = ""
var icon_texture: Texture2D
var cooldown_total: float = 0.0
var cooldown_remaining: float = 0.0
var resource_text: String = ""
var progress_text: String = ""
var status_text: String = ""
var available: bool = true

var detail_popup: PopupPanel
var detail_label: RichTextLabel


func _ready() -> void:
	custom_minimum_size = BADGE_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	tooltip_text = ""
	_ensure_detail_popup()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	set_process(false)
	queue_redraw()


func _process(delta: float) -> void:
	if cooldown_remaining <= 0.0 or cooldown_total <= 0.001:
		set_process(false)
		return
	cooldown_remaining = maxf(cooldown_remaining - delta, 0.0)
	queue_redraw()
	if cooldown_remaining <= 0.0:
		set_process(false)


func configure(data: Dictionary) -> void:
	skill_id = String(data.get("id", ""))
	skill_name = String(data.get("name", skill_id))
	var new_icon_path := SKILL_ART.hero_hud_path(skill_id)
	if new_icon_path.is_empty(): new_icon_path = String(data.get("icon_path", ""))
	if new_icon_path != icon_path:
		icon_path = new_icon_path
		icon_texture = _load_icon_texture(icon_path)
	update_state(data)


func _load_icon_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		var loaded = load(path)
		if loaded is Texture2D:
			return loaded
	if FileAccess.file_exists(path):
		var image := Image.new()
		if image.load(path) == OK:
			return ImageTexture.create_from_image(image)
	return null


func update_state(data: Dictionary) -> void:
	skill_name = String(data.get("name", skill_name))
	description = String(
		data.get(
			"description",
			"용사가 전투 상황과 사용 조건에 맞춰 자동으로 사용하는 기술입니다."
		)
	)
	resource_text = String(data.get("resource_text", ""))
	progress_text = String(data.get("progress_text", ""))
	status_text = String(data.get("status_text", ""))
	available = bool(data.get("available", true))
	cooldown_total = maxf(float(data.get("cooldown_total", 0.0)), 0.0)
	cooldown_remaining = maxf(float(data.get("cooldown_remaining", 0.0)), 0.0)
	set_process(cooldown_remaining > 0.01 and cooldown_total > 0.001)
	tooltip_text = ""
	if is_instance_valid(detail_popup) and detail_popup.visible:
		detail_label.text = _build_detail_bbcode()
	queue_redraw()


func _build_detail_text() -> String:
	var lines: PackedStringArray = []
	lines.append(skill_name)
	if not description.strip_edges().is_empty():
		lines.append(description.strip_edges())
	lines.append("")
	lines.append("[분류 / 카테고리]")
	lines.append(_get_category_text())
	lines.append("")
	lines.append("[사용 효과]")
	lines.append_array(_get_usage_lines())
	return "\n".join(lines)


func _build_detail_bbcode() -> String:
	var usage_text := "\n".join(_get_usage_lines())
	return (
		"[font_size=30][b]%s[/b][/font_size]\n"
		+ "[color=#AEB6C8]%s[/color]\n\n"
		+ "[font_size=20][color=#F2C85B][b]분류 / 카테고리[/b][/color][/font_size]\n"
		+ "%s\n\n"
		+ "[font_size=20][color=#7FD9FF][b]사용 효과[/b][/color][/font_size]\n"
		+ "%s"
	) % [
		_escape_bbcode(skill_name),
		_escape_bbcode(description.strip_edges()),
		_escape_bbcode(_get_category_text()),
		_escape_bbcode(usage_text),
	]


func _get_category_text() -> String:
	if skill_id == "alchemist_philosopher_stone":
		return "조건부 변신 · 전투당 1회"
	if cooldown_total > 0.001:
		return "자동 발동 · 재사용 대기형"
	return "자동 발동 · 조건 충족형"


func _get_usage_lines() -> PackedStringArray:
	var lines: PackedStringArray = []
	if cooldown_total > 0.001:
		if cooldown_remaining > 0.01:
			lines.append(
				"쿨타임  %.1f초 남음 / %.1f초"
				% [cooldown_remaining, cooldown_total]
			)
		else:
			lines.append("쿨타임  준비됨 / %.1f초" % cooldown_total)
	else:
		lines.append("쿨타임  없음")
	if not resource_text.is_empty():
		lines.append("소모 / 조건  %s" % resource_text)
	if not progress_text.is_empty():
		lines.append("진행  %s" % progress_text)
	if not status_text.is_empty():
		lines.append("상태  %s" % status_text)
	return lines


func _escape_bbcode(value: String) -> String:
	return value.replace("[", "\\[").replace("]", "\\]")

func _ensure_detail_popup() -> void:
	if is_instance_valid(detail_popup):
		return
	detail_popup = PopupPanel.new()
	detail_popup.name = "SkillDetailPopup"
	add_child(detail_popup)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 18)
	detail_popup.add_child(margin)

	detail_label = RichTextLabel.new()
	detail_label.custom_minimum_size = Vector2(500.0, 250.0)
	detail_label.bbcode_enabled = true
	detail_label.fit_content = true
	detail_label.scroll_active = false
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.add_theme_font_size_override("normal_font_size", 22)
	detail_label.add_theme_constant_override("line_separation", 6)
	margin.add_child(detail_label)


func _gui_input(event: InputEvent) -> void:
	if not event is InputEventScreenTouch:
		return
	var touch := event as InputEventScreenTouch
	if not touch.pressed:
		return
	_show_detail_popup()
	accept_event()


func _on_mouse_entered() -> void:
	if DisplayServer.is_touchscreen_available():
		return
	_show_detail_popup()


func _on_mouse_exited() -> void:
	if DisplayServer.is_touchscreen_available():
		return
	if is_instance_valid(detail_popup):
		detail_popup.hide()


func _show_detail_popup() -> void:
	_ensure_detail_popup()
	detail_label.text = _build_detail_bbcode()

	var viewport_size := get_viewport_rect().size
	var popup_width := mini(560, maxi(420, int(viewport_size.x) - 16))
	var popup_height := mini(360, maxi(280, int(viewport_size.y) - 16))
	var popup_size := Vector2i(popup_width, popup_height)
	var desired_x := int(global_position.x)
	var desired_y := int(global_position.y + size.y + 10.0)
	desired_x = clampi(
		desired_x,
		8,
		maxi(8, int(viewport_size.x) - popup_size.x - 8)
	)
	desired_y = clampi(
		desired_y,
		8,
		maxi(8, int(viewport_size.y) - popup_size.y - 8)
	)
	detail_popup.popup(
		Rect2i(
			Vector2i(desired_x, desired_y),
			popup_size
		)
	)

func _draw() -> void:
	var center := size * 0.5
	var radius := maxf(minf(size.x, size.y) * 0.5 - 2.0, 1.0)
	var on_cooldown := cooldown_remaining > 0.01
	var dimmed := on_cooldown or not available
	var icon_modulate := (
		Color(0.62, 0.64, 0.68, 0.72)
		if dimmed
		else Color(1.0, 1.0, 1.0, 1.0)
	)

	draw_circle(center, radius, Color(0.045, 0.05, 0.065, 0.90))

	var icon_rect := Rect2(
		Vector2(ICON_MARGIN, ICON_MARGIN),
		Vector2(
			maxf(size.x - ICON_MARGIN * 2.0, 1.0),
			maxf(size.y - ICON_MARGIN * 2.0, 1.0)
		)
	)
	if icon_texture != null:
		draw_texture_rect(icon_texture, icon_rect, false, icon_modulate)
	else:
		draw_circle(center, radius * 0.52, Color(0.72, 0.76, 0.84, 0.82))

	if on_cooldown and cooldown_total > 0.001:
		var ratio := clampf(cooldown_remaining / cooldown_total, 0.0, 1.0)
		_draw_cooldown_sector(center, radius - 1.0, ratio)
		_draw_cooldown_rim(center, radius - 1.5, ratio)
		_draw_center_text(
			center,
			str(maxi(int(ceil(cooldown_remaining)), 1)),
			20,
			Color(1.0, 1.0, 1.0, 0.98)
		)
	elif cooldown_total > 0.001 and available:
		_draw_center_text(
			center,
			"READY",
			13,
			Color(1.0, 0.90, 0.36, 1.0)
		)

	draw_arc(
		center,
		radius,
		0.0,
		TAU,
		48,
		Color(0.80, 0.84, 0.92, 0.96)
			if dimmed
			else Color(1.0, 0.82, 0.34, 1.0),
		2.0,
		true
	)


func _draw_cooldown_sector(center: Vector2, radius: float, ratio: float) -> void:
	if ratio <= 0.001:
		return

	var points := PackedVector2Array()
	points.append(center)
	var segments := maxi(int(ceil(48.0 * ratio)), 2)
	var start_angle := -PI * 0.5
	var sweep := TAU * ratio
	for index in range(segments + 1):
		var t := float(index) / float(segments)
		var angle := start_angle + sweep * t
		points.append(center + Vector2.from_angle(angle) * radius)

	draw_colored_polygon(points, Color(0.015, 0.02, 0.035, 0.82))


func _draw_cooldown_rim(center: Vector2, radius: float, ratio: float) -> void:
	if ratio <= 0.001:
		return
	var start_angle := -PI * 0.5
	var end_angle := start_angle + TAU * ratio
	draw_arc(
		center,
		radius,
		start_angle,
		end_angle,
		maxi(int(ceil(48.0 * ratio)), 2),
		Color(0.62, 0.86, 1.0, 1.0),
		4.0,
		true
	)


func _draw_center_text(
	center: Vector2,
	text_value: String,
	font_size: int,
	color: Color
) -> void:
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(
		text_value,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size
	)
	var baseline := Vector2(
		center.x - text_size.x * 0.5,
		center.y + text_size.y * 0.34
	)
	draw_string(
		font,
		baseline,
		text_value,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size,
		Color(0.0, 0.0, 0.0, 0.95)
	)
	draw_string(
		font,
		baseline + Vector2(0.0, -1.0),
		text_value,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size,
		color
	)
