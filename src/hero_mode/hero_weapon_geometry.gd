extends RefCounted
# Default 0% transparency means full-strength art, not an additional .75/.85 tint.
const AREA_FILL_ALPHA := 0.26
const EFFECT_ALPHA := 1.0
const SHAPE_FILL_ALPHA := 0.34
const ORBIT_FILL_ALPHA := 0.30
const OUTLINE_WIDTH := 3.0
const CHAIN_LINE_ALPHA := 0.62
const CHAIN_FALLBACK_WIDTH := 5.0
const BOLT_LINE_ALPHA := 0.70
const BOLT_RADIUS := 12.0
const CHAIN_DRAW_WIDTH := 32.0
const AREA_TEXTURE_ALPHA := 1.0
const BEAM_TEXTURE_ALPHA := 1.0
const RANGE_GUIDE_ALPHA := 0.96
const RANGE_GUIDE_WIDTH := 3.0
const ORBIT_TEXTURE_MAX_EXTENT := 18.0
## Authored art stays opaque; the optional hit-area outline is independent of it.
## Effect frames use about this share of their square, so the art is scaled until its
## visible content matches the real hit circle instead of the old inscribed sqrt(2) square.
const AREA_ART_COVERAGE := 0.68
const ART_GUIDE_ALPHA := 0.22
const ART_GUIDE_WIDTH := 1.5
## Telegraphs (lob landing, delayed bursts) share one danger colour across all weapons.
const WARNING_COLOR := Color("ffd27a")
const WARNING_WIDTH := 2.0
static func area_texture_extent(radius: float) -> float:
	return radius*2.0/AREA_ART_COVERAGE
static func effect_texture_rect(pattern: String,length: float,radius: float) -> Rect2:
	if pattern == "slash": return Rect2(Vector2(length*0.2,-length*0.3),Vector2.ONE*length*0.6)
	return Rect2(Vector2(0,-radius),Vector2(sqrt(maxf(0,length*length-radius*radius)),radius*2))
static func orbit_texture_extent(inner: float,outer: float) -> float:
	return minf(ORBIT_TEXTURE_MAX_EXTENT,(outer-inner)*0.5/sqrt(2.0))
## Shared by detection, hit filtering and render outlines. Radii are world units.
const SLASH_DOT := 0.35
const ORBIT_HALF_WIDTH := 100.0
const PROJECTILE_RADIUS := 12.0
## Multishot fallback when fewer enemies than shots: side offset (px) and angle (rad) per pair.
const EXTRA_SHOT_OFFSET := 22.0
const EXTRA_SHOT_SPREAD := 0.22
static func reach(data: Dictionary, rank: int, awakened: bool) -> float:
	if data.has("reach_scale"): return float(data.range)*float(data.reach_scale)
	return float(data.range)*(1.0+0.035*(rank-1))*(1.25 if awakened else 1.0)
static func beam_half_width(rank: int) -> float:
	return 40.0+rank*5.0
static func orbit_inner(radius: float, ratio: float, scale: float = 1.0) -> float:
	return maxf(0,radius*ratio-ORBIT_HALF_WIDTH*scale)
static func orbit_outer(radius: float, ratio: float, scale: float = 1.0) -> float:
	return minf(radius,radius*ratio+ORBIT_HALF_WIDTH*scale)
static func contains(pattern: String, offset: Vector2, direction: Vector2, radius: float, rank: int, data: Dictionary) -> bool:
	if offset.length_squared() > radius*radius: return false
	match pattern:
		"slash": return offset.is_zero_approx() or offset.normalized().dot(direction) >= SLASH_DOT
		"beam": return offset.dot(direction) >= 0 and absf(offset.cross(direction)) <= beam_half_width(rank)*float(data.get("area_scale",1.0))
		"orbit": return absf(offset.length()-radius*float(data.get("orbit_ratio",0.7))) <= ORBIT_HALF_WIDTH*float(data.get("area_scale",1.0))
	return true
static func sector(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array(); points.resize(27); points[0] = Vector2.ZERO
	var angle := acos(SLASH_DOT)
	for index in 25: points[index+1] = Vector2.from_angle(lerpf(-angle,angle,index/24.0))*radius
	points[26] = Vector2.ZERO
	return points
static func beam(radius: float, half_width: float) -> PackedVector2Array:
	var points := PackedVector2Array(); points.resize(28)
	var width := minf(radius,half_width); var angle := asin(width/radius)
	points[0] = Vector2(0,-width)
	for index in 25: points[index+1] = Vector2.from_angle(lerpf(-angle,angle,index/24.0))*radius
	points[26] = Vector2(0,width)
	points[27] = points[0]
	return points
static func capsule(length: float, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array(); points.resize(35)
	for index in 17:
		points[index] = Vector2(length,0)+Vector2.from_angle(lerpf(-PI*0.5,PI*0.5,index/16.0))*radius
		points[index+17] = Vector2.from_angle(lerpf(PI*0.5,PI*1.5,index/16.0))*radius
	points[34] = points[0]
	return points
