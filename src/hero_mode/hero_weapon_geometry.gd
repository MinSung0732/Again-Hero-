extends RefCounted
## Shared by detection, hit filtering and render outlines. Radii are world units.
const SLASH_DOT := 0.35
const ORBIT_HALF_WIDTH := 100.0
const PROJECTILE_RADIUS := 12.0
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
