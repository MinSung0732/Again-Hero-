extends RefCounted
## Room-owned visual registry. Pool reuse gets a fresh ID, never a phantom pickup.
const DATA := preload("res://src/data/online_exp_orb_catalog.gd")
var active := {}
var collected: Array = []
var next_id := 0
func activate(orb: Node2D) -> void:
	var instance := orb.get_instance_id()
	next_id+=1
	active[instance]={"node":orb,"id":next_id,"tier":DATA.tier_for(int(orb.exp_value))}
	var on_exit := _tree_exited.bind(instance)
	if not orb.tree_exited.is_connected(on_exit): orb.tree_exited.connect(on_exit)
func retire(orb: Node2D) -> void:
	var instance := orb.get_instance_id()
	if not active.has(instance): return
	var entry: Dictionary=active[instance]
	if collected.size()>=DATA.MAX_COLLECTED: collected.pop_front()
	collected.append({"row":[entry.id,snappedf(orb.position.x,.1),snappedf(orb.position.y,.1),entry.tier,DATA.COLLECTED],"until":Time.get_ticks_usec()+int(DATA.RETAIN_SECONDS*1000000)})
	active.erase(instance)
func _tree_exited(instance: int) -> void:
	active.erase(instance)
func snapshot() -> Array:
	var output: Array=[]
	var now:=Time.get_ticks_usec()
	while not collected.is_empty() and int(collected[0].until)<=now: collected.pop_front()
	for entry in collected: output.append(entry.row)
	var count:=0
	for instance in active:
		if count>=DATA.MAX_ACTIVE: break
		var entry: Dictionary=active[instance]
		var orb: Node2D=entry.node
		if not is_instance_valid(orb) or orb.is_queued_for_deletion() or not orb.visible: continue
		output.append([entry.id,snappedf(orb.position.x,.1),snappedf(orb.position.y,.1),entry.tier,DATA.ATTRACTED if orb.magnetized or orb.global_magnet_time_left>0 else DATA.IDLE])
		count+=1
	return output
