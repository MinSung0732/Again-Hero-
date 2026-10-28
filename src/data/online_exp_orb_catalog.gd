extends RefCounted
## Display-only limits; never caps authoritative drops or changes EXP rewards.
const SOURCE := preload("res://src/battle/exp_orb.gd")
const MAX_ACTIVE := 128
const MAX_COLLECTED := 32
const MAX_ROWS := MAX_ACTIVE+MAX_COLLECTED
const IDLE := 0
const ATTRACTED := 1
const COLLECTED := 2
const RETAIN_SECONDS := 0.5
const ABSORB_SECONDS := 0.18
const ANIMATION_FPS := 10.0
const EMPTY := []
static func tier_for(value: int) -> int:
	var selected := 0
	for index in SOURCE.TIER_DATA.size():
		if value < int(SOURCE.TIER_DATA[index].min_exp): break
		selected=index
	return selected
static func frame_path(tier: int,frame: int) -> String:
	return "%s/frame_%02d.png" % [SOURCE.TIER_DATA[tier].path,frame+1]
static func valid(rows: Variant) -> bool:
	if not rows is Array or rows.size()>MAX_ROWS: return false
	var ids := {}
	for row in rows:
		if not row is Array or row.size()!=5: return false
		for value in row:
			if not (value is int or value is float) or not is_finite(float(value)): return false
		if row[0]<1 or row[0]>2147483647 or row[0]!=floorf(row[0]) or ids.has(int(row[0])): return false
		ids[int(row[0])]=true
		if absf(row[1])>1000000 or absf(row[2])>1000000: return false
		if row[3]<0 or row[3]>=SOURCE.TIER_DATA.size() or row[3]!=floorf(row[3]): return false
		if row[4] < IDLE or row[4] > COLLECTED or row[4] != floorf(row[4]): return false
	return true
