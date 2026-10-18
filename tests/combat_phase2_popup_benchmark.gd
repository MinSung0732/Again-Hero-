extends SceneTree
const SCENE := preload("res://src/ui/DamageNumber.tscn")
const FRAMES := 120
func _initialize() -> void: run.call_deferred()
func work(popups: Array,hits: int) -> void:
	for frame in FRAMES:
		for popup in popups:
			for hit in hits: popup.add_damage(1,Color.WHITE)
			popup._process(1.0/60.0)
func run() -> void:
	var script := GDScript.new(); script.source_code = FileAccess.get_file_as_string("res://tests/fixtures/combat_phase2/damage_number_before.gd.txt")
	if script.reload() != OK: quit(1); return
	var before: Array = []; var after: Array = []
	for index in 48:
		var old = SCENE.instantiate(); old.set_script(script); root.add_child(old); old.set_process(false); old.setup(1); before.append(old)
		var current = SCENE.instantiate(); root.add_child(current); current.set_process(false); current.setup(1); after.append(current)
	var rows: Array = []
	for hits in [1,4,12]:
		var before_ms: Array = []; var after_ms: Array = []
		work(before,hits); work(after,hits)
		for trial in 7:
			for optimized in ([false,true] if trial%2 == 0 else [true,false]):
				var begin := Time.get_ticks_usec(); work(after if optimized else before,hits)
				(after_ms if optimized else before_ms).append((Time.get_ticks_usec()-begin)/1000.0)
		before_ms.sort(); after_ms.sort()
		var row := {"popups":48,"synthetic_render_frames":FRAMES,"hits_per_popup_frame":hits,"runs":7,"before_median_ms":before_ms[3],"after_median_ms":after_ms[3],"before_samples_ms":before_ms,"after_samples_ms":after_ms}
		rows.append(row); print("PHASE2_POPUP_BENCH ",JSON.stringify(row))
	var file := FileAccess.open("user://combat_phase2_popup_benchmark.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"cpu_only":true,"rows":rows},"\t")); file.close()
	for popup in before+after: popup.free()
	quit()
