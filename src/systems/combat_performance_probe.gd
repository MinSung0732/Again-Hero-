extends RefCounted
## Opt-in CPU scopes, bounded sample storage. Reports allocate only on request.
## Nested scopes overlap; their totals must never be added to claim total frame CPU.
enum Scope { BATTLE, HERO, WEAPONS, GRID, QUERY, NETWORK_SNAPSHOT, MONSTER_PHYSICS, MONSTER_MOVE, SEPARATION }
const NAMES := ["battle_process","hero_physics","weapon_tick","grid_rebuild","spatial_query","network_snapshot","monster_base_physics","monster_move_and_slide","monster_separation"]
const SAMPLE_LIMIT := 512
var enabled := false
var calls := PackedInt64Array()
var totals := PackedInt64Array()
var maxima := PackedInt64Array()
var samples := PackedInt64Array()
var frame_intervals := PackedFloat64Array()
# Aggregate inclusive scope time across calls within each rendered frame.
# All arrays are retained; only the opt-in profiling path updates them.
var scope_frame_current := PackedInt64Array()
var scope_frame_samples := PackedInt64Array()
var scope_frame_totals := PackedInt64Array()
var scope_frame_maxima := PackedInt64Array()
var frame_count := 0
func _init() -> void:
	calls.resize(NAMES.size()); totals.resize(NAMES.size()); maxima.resize(NAMES.size())
	samples.resize(NAMES.size()*SAMPLE_LIMIT); frame_intervals.resize(SAMPLE_LIMIT)
	scope_frame_current.resize(NAMES.size())
	scope_frame_samples.resize(NAMES.size()*SAMPLE_LIMIT)
	scope_frame_totals.resize(NAMES.size())
	scope_frame_maxima.resize(NAMES.size())
func start() -> void:
	calls.fill(0); totals.fill(0); maxima.fill(0); samples.fill(0); frame_intervals.fill(0)
	scope_frame_current.fill(0); scope_frame_samples.fill(0)
	scope_frame_totals.fill(0); scope_frame_maxima.fill(0)
	frame_count = 0; enabled = true
func stop() -> void: enabled = false
func record(scope: int, started_usec: int) -> void:
	if enabled: record_elapsed(scope,Time.get_ticks_usec()-started_usec)
func record_elapsed(scope: int, elapsed_usec: int) -> void:
	if not enabled: return
	samples[scope*SAMPLE_LIMIT+calls[scope]%SAMPLE_LIMIT] = elapsed_usec
	calls[scope] += 1; totals[scope] += elapsed_usec
	maxima[scope] = maxi(maxima[scope],elapsed_usec)
	scope_frame_current[scope] += elapsed_usec
func frame(delta: float) -> void:
	if not enabled: return
	var slot := frame_count%SAMPLE_LIMIT
	for scope in NAMES.size():
		var elapsed_us := scope_frame_current[scope]
		scope_frame_samples[scope*SAMPLE_LIMIT+slot] = elapsed_us
		scope_frame_totals[scope] += elapsed_us
		scope_frame_maxima[scope] = maxi(scope_frame_maxima[scope],elapsed_us)
		scope_frame_current[scope] = 0
	frame_intervals[slot] = delta*1000.0
	frame_count += 1
func report() -> Dictionary:
	var scopes := {}
	for scope in NAMES.size():
		var count := mini(calls[scope],SAMPLE_LIMIT)
		var ordered := samples.slice(scope*SAMPLE_LIMIT,scope*SAMPLE_LIMIT+count)
		ordered.sort()
		var frame_samples_count := mini(frame_count,SAMPLE_LIMIT)
		var ordered_frames := scope_frame_samples.slice(scope*SAMPLE_LIMIT,scope*SAMPLE_LIMIT+frame_samples_count)
		ordered_frames.sort()
		scopes[NAMES[scope]] = {
			"calls":calls[scope],"total_us":totals[scope],
			"mean_us":float(totals[scope])/maxi(1,calls[scope]),
			"p95_us":ordered[clampi(ceili(count*.95)-1,0,count-1)] if count else 0,
			"max_us":maxima[scope],"retained_samples":count,
			"frame_mean_us":float(scope_frame_totals[scope])/maxi(1,frame_count),
			"frame_p95_us":ordered_frames[clampi(ceili(frame_samples_count*.95)-1,0,frame_samples_count-1)] if frame_samples_count else 0,
			"frame_max_us":scope_frame_maxima[scope]
		}
	var intervals := frame_intervals.slice(0,mini(frame_count,SAMPLE_LIMIT)); intervals.sort()
	return {"scopes":scopes,"frame_intervals_ms":{"samples":frame_count,"p95":intervals[clampi(ceili(intervals.size()*.95)-1,0,intervals.size()-1)] if not intervals.is_empty() else 0.0},"nested_scopes_overlap":true,"engine":Engine.get_version_info().string,"display":DisplayServer.get_name()}
