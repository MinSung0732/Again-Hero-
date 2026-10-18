extends RefCounted
## Fixed slots; sample accepted timers before ticking, draw current remaining time.
const NAMES := ["공포","기절","속박","석화","매혹"]
var totals := PackedFloat32Array([0,0,0,0,0])
var previous := PackedFloat32Array([0,0,0,0,0])
func remaining(hero, index: int) -> float:
	match index:
		0: return maxf(0,hero.fear_timer)
		1: return maxf(0,hero.stun_timer)
		2: return maxf(0,hero.player_root_timer) if hero.player_root_timer > 0.0 else maxf(0,hero.slow_timer)
		3: return maxf(0,hero.petrify_timer)
		4: return maxf(0,hero.charm_timer)
	return 0.0
func sample(hero) -> void:
	for index in 5:
		var left := remaining(hero,index)
		if left <= 0: totals[index] = 0
		elif previous[index] <= 0 or left > previous[index]+0.0001: totals[index] = left
func commit(hero) -> void:
	for index in 5: previous[index] = remaining(hero,index)
func draw_on(canvas: CanvasItem, hero, y: float, width: float) -> void:
	for index in 5:
		var left := remaining(hero,index)
		if left <= 0: continue
		var ratio := clampf(left/maxf(totals[index],left),0,1)
		canvas.draw_rect(Rect2(-width*0.5,y,width,6),Color(0.08,0.08,0.10,0.9))
		canvas.draw_rect(Rect2(-width*0.5,y,width*ratio,6),Color.WHITE)
		var label := "둔화" if index == 2 and hero.player_root_timer <= 0.0 else String(NAMES[index])
		canvas.draw_string(ThemeDB.fallback_font,Vector2(-width*0.5,y-3),"%s %.1f초" % [label,left],HORIZONTAL_ALIGNMENT_LEFT,width,14,Color.WHITE)
		y -= 24.0
