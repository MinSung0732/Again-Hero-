extends Node
## Keep an explicit leave packet alive across the outgoing scene's destruction.
## No waiting/blocking on the UI thread; at most one short-lived drain per leave.
const RULES := preload("res://src/online/match_rules.gd")
var socket: WebSocketPeer
var deadline := 0
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	deadline = Time.get_ticks_msec() + int(RULES.CLOSE_DRAIN_TIMEOUT * 1000.0)
func _process(_delta: float) -> void:
	socket.poll()
	var state := socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN and socket.get_current_outbound_buffered_amount() == 0: socket.close()
	if state == WebSocketPeer.STATE_CLOSED or Time.get_ticks_msec() >= deadline:
		socket.close(); socket = null; queue_free()
