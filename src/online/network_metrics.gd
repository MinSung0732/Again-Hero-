extends RefCounted
## Local monotonic clocks only; never subtract a server timestamp from a client clock.
const DATA := preload("res://src/data/online_metrics_catalog.gd")
const WINDOW := preload("res://src/online/metric_window.gd")
const RULES := preload("res://src/online/match_rules.gd")
var enabled := false
var samples := {}
var sent_sequences := PackedInt64Array()
var sent_at := PackedInt64Array()
var nonce := 0
var ping_id := 0
var ping_at := 0
var last_ack := 0
var state_tick := -1
var state_at := 0
var rx_bytes := 0
var tx_bytes := 0
var rx_packets := 0
var tx_packets := 0
var rate_at := 0
var rate_rx := 0
var rate_tx := 0
var rx_kib_s := 0.0
var tx_kib_s := 0.0
var server := {}
var snapshot_bytes := 0
func _init() -> void:
	for key in DATA.SAMPLE_KEYS: samples[key] = WINDOW.new()
	sent_sequences.resize(DATA.INPUT_SLOTS); sent_at.resize(DATA.INPUT_SLOTS)
	reset()
func reset() -> void:
	for key in samples: samples[key].reset()
	rx_bytes=0; tx_bytes=0; rx_packets=0; tx_packets=0; rate_rx=0; rate_tx=0; rx_kib_s=0; tx_kib_s=0
	rate_at=Time.get_ticks_usec(); server={}; snapshot_bytes=0; transport_reset()
func transport_reset() -> void:
	ping_id=0; ping_at=0; last_ack=0; state_at=0; state_tick=-1
	sent_sequences.fill(0); sent_at.fill(0)
func receive_bytes(size: int) -> void:
	if enabled: rx_bytes+=size; rx_packets+=1
func send_bytes(size: int) -> void:
	if enabled: tx_bytes+=size; tx_packets+=1
func tick_rates(now: int = -1) -> void:
	if not enabled: return
	if now<0: now=Time.get_ticks_usec()
	if now-rate_at<DATA.REFRESH_US: return
	var seconds := float(now-rate_at)/1000000.0
	rx_kib_s=float(rx_bytes-rate_rx)/1024.0/seconds; tx_kib_s=float(tx_bytes-rate_tx)/1024.0/seconds
	rate_rx=rx_bytes; rate_tx=tx_bytes; rate_at=now
func heartbeat() -> Dictionary:
	if not enabled: return {"op":"ping"}
	var now := Time.get_ticks_usec()
	if ping_id>0 and now-ping_at<int(RULES.RESPONSE_TIMEOUT*1000000): return {"op":"ping"}
	nonce=(nonce%DATA.MAX_SEQUENCE)+1; ping_id=nonce; ping_at=now
	return {"op":"ping","probe":ping_id}
func pong(event: Dictionary) -> void:
	if not enabled or not DATA.sequence(event.get("probe",null)) or event.probe!=ping_id or ping_id==0: return
	samples.rtt.push(float(Time.get_ticks_usec()-ping_at)/1000.0); ping_id=0; ping_at=0
	if DATA.server_valid(event.get("metrics",null)): server=event.metrics.duplicate()
func input_sent(sequence: int) -> void:
	if not enabled: return
	var slot := sequence%DATA.INPUT_SLOTS; sent_sequences[slot]=sequence; sent_at[slot]=Time.get_ticks_usec()
func state(event: Dictionary,role: String) -> void:
	if not enabled or not DATA.sequence(event.get("tick",null)) or event.tick<=state_tick: return
	var now := Time.get_ticks_usec()
	if state_at>0: samples.gap.push(float(now-state_at)/1000.0)
	state_at=now; state_tick=int(event.tick)
	var ack: Variant = event.get("ack",null)
	if not ack is Dictionary or not DATA.sequence(ack.get(role,null)): return
	var sequence := int(ack[role])
	if sequence<=last_ack: return
	last_ack=sequence
	var slot := sequence%DATA.INPUT_SLOTS
	if sent_sequences[slot]==sequence and sent_at[slot]>0:
		samples.input.push(float(now-sent_at[slot])/1000.0); sent_at[slot]=0
func report(role: String) -> Dictionary:
	return {"protocol":RULES.VERSION,"byte_scope":"websocket_payload","role":role,"os":OS.get_name(),"rtt":samples.rtt.report(),"state_gap":samples.gap.report(),"input_confirmation":samples.input.report(),"rx_bytes":rx_bytes,"tx_bytes":tx_bytes,"rx_packets":rx_packets,"tx_packets":tx_packets,"rx_kib_s":rx_kib_s,"tx_kib_s":tx_kib_s,"server":server.duplicate()}
func server_report(rooms: int,peers: int,actors: int,projectiles: int) -> Dictionary:
	return {"physics_ms":maxf(0,Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0),"process_ms":maxf(0,Performance.get_monitor(Performance.TIME_PROCESS)*1000.0),"snapshot_ms":samples.snapshot.mean(),"encode_ms":samples.encode.mean(),"snapshot_samples":samples.snapshot.count,"encode_samples":samples.encode.count,"rooms":rooms,"peers":peers,"actors":actors,"projectiles":projectiles,"snapshot_bytes":snapshot_bytes,"tx_kib_s":tx_kib_s,"rx_kib_s":rx_kib_s}
