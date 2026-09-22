extends Control
class_name HeroSkillCooldownBadge

const BADGE_SIZE := Vector2(62.0, 62.0)
const ICON_MARGIN := 7.0

var skill_id: String = ""
var skill_name: String = ""
var icon_path: String = ""
var icon_texture: Texture2D
var cooldown_total: float = 0.0
var cooldown_remaining: float = 0.0

func _ready() -> void:
	custom_minimum_size = BADGE_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func configure(data: Dictionary) -> void:
	skill_id = String(data.get("id", ""))
	skill_name = String(data.get("name", skill_id))
	icon_path = String(data.get("icon_path", ""))
	tooltip_text = skill_name
	icon_texture = null
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		var loaded = load(icon_path)
		if loaded is Texture2D:
			icon_texture = loaded
	update_state(data)

func update_state(data: Dictionary) -> void:
	cooldown_total = maxf(float(data.get("cooldown_total", 0.0)), 0.0)
	cooldown_remaining = maxf(float(data.get("cooldown_remaining", 0.0)), 0.0)
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var radius := maxf(minf(size.x, size.y) * 0.5 - 2.0, 1.0)
	var on_cooldown := cooldown_remaining > 0.01
	var icon_modulate := (
		Color(0.62, 0.64, 0.68, 0.78)
		if on_cooldown
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
		Color(0.72, 0.76, 0.84, 0.86) if on_cooldown else Color(1.0, 0.82, 0.34, 0.95),
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
