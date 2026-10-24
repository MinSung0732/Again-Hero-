extends RefCounted
## Shared solo/online combat bar geometry. Call only from a CanvasItem draw callback.
const HERO := preload("res://src/data/hero_presentation_catalog.gd")
const MONSTER_WIDTH := 70.0
const MONSTER_HEIGHT := 6.0
const MONSTER_YELLOW_HEIGHT := 4.0
const MONSTER_STEP := 9.0
const MONSTER_BACKGROUND := Color("202024")
const MONSTER_HP := Color("4cd965")
const MONSTER_YELLOW := Color("ffdb3b")
const SHIELD_COLORS := {"shield":Color("61ddff"),"ranged":Color("b490ff"),"melee":Color("ff9566")}
const SHIELD_KINDS := ["shield", "ranged", "melee"]
const MAX_HERO_CELLS := 64

static func bar_rect(x: float, y: float, width: float, height: float, ratio: float) -> Rect2:
	return Rect2(x, y, width * clampf(ratio, 0.0, 1.0), height)

static func draw_bar(canvas: CanvasItem, x: float, y: float, width: float, height: float, ratio: float, background: Color, color: Color) -> void:
	canvas.draw_rect(Rect2(x, y, width, height), background, true)
	canvas.draw_rect(bar_rect(x, y, width, height, ratio), color, true)

static func draw_hero_hp(canvas: CanvasItem, x: float, y: float, ratio: float) -> void:
	draw_bar(canvas, x, y, HERO.STATUS_BAR_WIDTH, HERO.STATUS_HP_HEIGHT, ratio, HERO.STATUS_BACKGROUND_COLOR, HERO.STATUS_HP_COLOR)

static func draw_hero_shield(canvas: CanvasItem, x: float, y: float, ratio: float) -> void:
	draw_bar(canvas, x, y, HERO.STATUS_BAR_WIDTH, HERO.STATUS_SHIELD_HEIGHT, ratio, HERO.STATUS_SHIELD_BACKGROUND_COLOR, HERO.STATUS_SHIELD_COLOR)

static func draw_hero_resource(canvas: CanvasItem, x: float, y: float, ratio: float, color: Color) -> void:
	draw_bar(canvas, x, y, HERO.STATUS_BAR_WIDTH, HERO.STATUS_RESOURCE_HEIGHT, ratio, HERO.STATUS_BACKGROUND_COLOR, color)

static func draw_hero_cells(canvas: CanvasItem, y: float, capacity: int, filled: int, color: Color) -> void:
	var gap := HERO.STATUS_CELL_GAP
	var width := (HERO.STATUS_BAR_WIDTH - gap * float(capacity - 1)) / float(capacity)
	for index in range(capacity):
		var x := -HERO.STATUS_BAR_WIDTH * 0.5 + float(index) * (width + gap)
		canvas.draw_rect(Rect2(x, y, width, HERO.STATUS_RESOURCE_HEIGHT), HERO.STATUS_BACKGROUND_COLOR, true)
		if index < filled:
			canvas.draw_rect(Rect2(x, y, width, HERO.STATUS_RESOURCE_HEIGHT), color, true)

static func draw_monster_bar(canvas: CanvasItem, y: float, ratio: float, color: Color, scale_x: float = 1.0, scale_y: float = 1.0, yellow: bool = false) -> void:
	var width := MONSTER_WIDTH / maxf(absf(scale_x), 0.01)
	var height := (MONSTER_YELLOW_HEIGHT if yellow else MONSTER_HEIGHT) / maxf(absf(scale_y), 0.01)
	draw_bar(canvas, -width * 0.5, y, width, height, ratio, MONSTER_BACKGROUND, color)

static func valid_monster_bars(bars: Variant) -> bool:
	if not bars is Array or bars.size() < 5 or bars.size() > 11: return false
	if not _byte(bars[0]) or not _byte(bars[1], true): return false
	if not _integer(bars[2],-512,512): return false
	if not _integer(bars[3],1,1024) or not _integer(bars[4],1,1024): return false
	if (bars.size() - 5) % 2 != 0: return false
	var seen := 0
	for index in range(5, bars.size(), 2):
		if not _byte(bars[index]) or int(bars[index]) >= SHIELD_KINDS.size() or (seen & (1 << int(bars[index]))) != 0: return false
		if not _byte(bars[index + 1]): return false
		seen |= 1 << int(bars[index])
	return true

static func valid_hero_bars(bars: Variant) -> bool:
	if not bars is Array or bars.size() != 8: return false
	for index in 5:
		if not _byte(bars[index]): return false
	for index in range(5,8):
		if not _integer(bars[index],-512,512): return false
	return int(bars[2]) <= 1 and int(bars[4]) <= MAX_HERO_CELLS and (int(bars[2]) == 0 or (int(bars[4]) > 0 and int(bars[3]) <= int(bars[4])))

static func _byte(value: Variant, allow_absent: bool = false) -> bool:
	return _integer(value,-1 if allow_absent else 0,255)

static func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value)) and float(value) >= minimum and float(value) <= maximum

static func quantize(ratio: float) -> int:
	return clampi(int(round(clampf(ratio, 0.0, 1.0) * 255.0)), 0, 255)
