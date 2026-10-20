extends RefCounted
const DATA := preload("res://src/data/online_metrics_catalog.gd")
var values := PackedFloat64Array()
var count := 0
var cursor := 0
var total := 0.0
func _init() -> void: values.resize(DATA.SAMPLES)
func reset() -> void:
	values.fill(0.0); count=0; cursor=0; total=0
func push(value: float) -> void:
	if not is_finite(value) or value<0: return
	if count==values.size(): total -= values[cursor]
	else: count += 1
	values[cursor]=value; total += value; cursor=(cursor+1)%values.size()
func mean() -> float: return total/count if count>0 else 0.0
func report() -> Dictionary:
	if count==0: return {"count":0,"mean_ms":null,"p95_ms":null,"max_ms":null}
	# Only requested by the once-per-second panel or explicit copy action.
	var ordered := values.slice(0,count); ordered.sort()
	return {"count":count,"mean_ms":mean(),"p95_ms":ordered[clampi(ceili(count*0.95)-1,0,count-1)],"max_ms":ordered[-1]}
