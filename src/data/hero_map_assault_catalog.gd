extends RefCounted
## Map-space wave locations. The Battle placement gate is the final authority.
const PLAN_SECONDS := 12.0
const PLANS := ["edge","pincer","lanes","scatter"]
const NAMES := {"edge":"외곽 진군","pincer":"양방향 협공","lanes":"진로 차단","scatter":"전장 분산"}
const MIN_DISTANCE := 360.0
static func plan_at(elapsed: float,stage: int) -> String:
	return String(PLANS[(maxi(0,floori(elapsed/PLAN_SECONDS))+clampi(stage,1,10)-1)%PLANS.size()])
static func point(plan: String,sequence: int,origin: Vector2,movement: Vector2,bounds: Vector2) -> Vector2:
	var width := maxf(1.0,bounds.x-160.0)
	var height := maxf(1.0,bounds.y-160.0)
	var fraction := fposmod(sequence*0.61803398875,1.0)
	var side := posmod(sequence/6,4)
	if plan == "edge":
		match side:
			0: return Vector2(80.0+width*fraction,90.0)
			1: return Vector2(bounds.x-80.0,80.0+height*fraction)
			2: return Vector2(80.0+width*fraction,bounds.y-80.0)
			_: return Vector2(80.0,80.0+height*fraction)
	if plan == "pincer":
		return Vector2(80.0 if sequence%2 == 0 else bounds.x-80.0,80.0+height*fraction)
	if plan == "lanes":
		var forward := movement.normalized() if movement.length_squared() > 0.01 else Vector2.DOWN
		return origin+forward*540.0+forward.orthogonal()*(fraction-0.5)*width
	return Vector2(80.0+width*fraction,80.0+height*fposmod(sequence*0.41421356237,1.0))
