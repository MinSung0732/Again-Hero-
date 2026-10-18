extends SceneTree
const SCENE := preload("res://src/ui/DamageNumber.tscn")
const LOGIC := preload("res://src/ui/damage_number.gd")
func _initialize() -> void: run.call_deferred()
func work(popups: Array,hits: int) -> void:
	for frame in 120:
		for popup in popups:
			popup.setup(1)
			for hit in hits: popup.add_damage(1)
			popup._process(1.0/60.0)
func run() -> void:
	var before: Array = []; var after: Array = []
	for index in 48:
		var visible_popup = SCENE.instantiate(); root.add_child(visible_popup); before.append(visible_popup)
		var server_popup := LOGIC.new(); root.add_child(server_popup); after.append(server_popup)
	var rows: Array = []
	for hits in [1,4,12]:
		work(before,hits); work(after,hits); var a: Array = []; var b: Array = []
		for trial in 7:
			for optimized in ([false,true] if trial%2 == 0 else [true,false]):
				var begin := Time.get_ticks_usec(); work(after if optimized else before,hits)
				(b if optimized else a).append((Time.get_ticks_usec()-begin)/1000.0)
		a.sort(); b.sort()
		var row := {"popups":48,"synthetic_frames":120,"merges_after_setup":hits,"runs":7,"before_median_ms":a[3],"after_median_ms":b[3],"before_samples_ms":a,"after_samples_ms":b}
		rows.append(row); print("PHASE3_POPUP_BENCH ",JSON.stringify(row))
	var file := FileAccess.open("user://combat_phase3_popup_benchmark.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"cpu_only":true,"engine":Engine.get_version_info().string,"rows":rows},"\t")); file.close()
	for popup in before+after: popup.free()
	quit()
