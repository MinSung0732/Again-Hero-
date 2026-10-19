extends RefCounted
const DATA := preload("res://src/data/online_feedback_catalog.gd")
var sequence := 0
var rows: Array = []
var hero_next := 0
var general_next := DATA.HERO_RESERVED
func _init() -> void:
	for _index in DATA.CAPACITY: rows.append([0,0,"",0.0,0.0,0,1.0,1.0,1.0,1.0])
func publish(kind: String,point: Vector2,amount: int,color: Color,tick: int) -> void:
	if kind not in DATA.KINDS or amount<0 or not point.is_finite(): return
	sequence += 1
	var slot := hero_next if kind=="hero_hit" else general_next
	var row: Array = rows[slot]
	row[0]=sequence; row[1]=tick; row[2]=kind; row[3]=snappedf(point.x,0.1); row[4]=snappedf(point.y,0.1); row[5]=mini(amount,1000000)
	row[6]=clampf(color.r,0,1); row[7]=clampf(color.g,0,1); row[8]=clampf(color.b,0,1); row[9]=clampf(color.a,0,1)
	if kind=="hero_hit": hero_next = (hero_next+1)%DATA.HERO_RESERVED
	else: general_next = DATA.HERO_RESERVED+(general_next-DATA.HERO_RESERVED+1)%(DATA.CAPACITY-DATA.HERO_RESERVED)
func snapshot() -> Array:
	var output: Array = []
	for row in rows:
		if row[0]>0: output.append(row.duplicate())
	output.sort_custom(func(a: Array,b: Array): return a[0]<b[0])
	return output
