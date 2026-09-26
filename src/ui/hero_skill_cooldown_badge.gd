extends Control
class_name HeroSkillCooldownBadge

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
var detail_label: Label


func _ready() -> void:
	custom_minimum_size = BADGE_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	_ensure_detail_popup()
	queue_redraw()


func configure(data: Dictionary) -> void:
	skill_id = String(data.get("id", ""))
	skill_name = String(data.get("name", skill_id))
	var new_icon_path := String(data.get("icon_path", ""))
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
	tooltip_text = _build_detail_text()
	if is_instance_valid(detail_popup) and detail_popup.visible:
		detail_label.text = tooltip_text
	queue_redraw()


func _build_detail_text() -> String:
	var lines: PackedStringArray = []
	lines.append(skill_name)
	if not description.strip_edges().is_empty():
		lines.append(description.strip_edges())
	if cooldown_total > 0.001:
		if cooldown_remaining > 0.01:
			lines.append(
				"남은 쿨타임 %.1f초 / %.1f초"
				% [cooldown_remaining, cooldown_total]
			)
		else:
			lines.append("쿨타임 준비됨 / %.1f초" % cooldown_total)
	if not resource_text.is_empty():
		lines.append("소모/조건 · %s" % resource_text)
	if not progress_text.is_empty():
		lines.append(progress_text)
	if not status_text.is_empty():
		lines.append("상태 · %s" % status_text)
	return "\n".join(lines)


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

	detail_label = Label.new()
	detail_label.custom_minimum_size = Vector2(500.0, 0.0)
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.add_theme_font_size_override("font_size", 24)
	margin.add_child(detail_label)


func _gui_input(event: InputEvent) -> void:
	var pressed := false
	if event is InputEventScreenTouch:
		pressed = (event as InputEventScreenTouch).pressed
	elif event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		pressed = (
			mouse_event.pressed
			and mouse_event.button_index == MOUSE_BUTTON_LEFT
		)
	if not pressed:
		return

	_ensure_detail_popup()
	detail_label.text = _build_detail_text()
	detail_popup.popup_centered(Vector2i(560, 300))
	accept_event()


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

	draw_arc(
		center,
		radius,
		0.0,
		TAU,
		48,
		Color(0.72, 0.76, 0.84, 0.86)
			if dimmed
			else Color(1.0, 0.82, 0.34, 0.95),
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

	draw_colored_polygon(points, Color(0.025, 0.03, 0.045, 0.70))
