extends CanvasLayer
const CONNECTION_POLICY := preload("res://src/data/cloud_connection_catalog.gd")
## Own only our pause reason; settings/augment pauses survive reconnection.
const VIEW := preload("res://src/ui/startup_loading_view.gd")
const STARTUP := "res://src/startup/Startup.tscn"
const LOBBY := "res://src/lobby/Lobby.tscn"
var _view: Control
var _return: Button
var _delay: Timer
var _paused_tree := false
var _owns_pause := false
var _battle: WeakRef
var _blocked := false
var _reload_pending := false
func _ready() -> void:
	layer = 30000
	process_mode = Node.PROCESS_MODE_ALWAYS
	_view = VIEW.new()
	add_child(_view)
	_return = Button.new()
	_return.text = CONNECTION_POLICY.RETURN_TO_LOGIN
	_return.add_theme_font_size_override("font_size",30)
	_return.add_theme_stylebox_override("normal", VIEW.plate(Color("432354")))
	VIEW.place(_view, _return, Rect2(0.20,0.77,0.60,0.065))
	_return.mouse_filter = Control.MOUSE_FILTER_STOP
	_return.pressed.connect(_return_to_login)
	_delay = Timer.new()
	_delay.one_shot = true
	_delay.timeout.connect(_show_wait)
	add_child(_delay)
	CloudStore.connection_changed.connect(_connection_changed)
	CloudStore.canonical_reloaded.connect(_reload_lobby)
	visible = false
	_view.hide()
func _find_battle(node: Node) -> Node:
	if node == null: return null
	if node.has_method("set_network_pause"): return node
	for child in node.get_children():
		var found := _find_battle(child)
		if found != null: return found
	return null
func _node_added(node: Node) -> void:
	if _blocked and _owns_pause and node.has_method("set_network_pause"):
		# _ready may reset pause domains: reapply after the new scene is ready.
		_hold_battle.call_deferred(node)
func _hold_battle(node: Node) -> void:
	if _blocked and _owns_pause and is_instance_valid(node):
		node.set_network_pause(true)
		_battle = weakref(node)
func _acquire_pause() -> void:
	if _owns_pause: return
	_paused_tree = get_tree().paused
	_owns_pause = true
	get_tree().paused = true
	if not get_tree().node_added.is_connected(_node_added): get_tree().node_added.connect(_node_added)
	_hold_battle(_find_battle(get_tree().current_scene))
func _show_wait() -> void:
	if not _blocked: return
	_acquire_pause()
	_view.modulate.a = 1.0
func _connection_changed(blocked: bool, message: String, terminal: bool) -> void:
	if _reload_pending and not blocked:
		if CloudStore.ready_for_play: return
		_reload_pending = false
	if blocked:
		if not _blocked:
			_blocked = true
			visible = true
			_view.show()
			_view.modulate.a = 0.0
			_delay.start(CONNECTION_POLICY.WAIT_SCREEN_DELAY_SECONDS)
		# Short normal writes block repeat UI actions without freezing combat.
		# Confirmed outages/auth work pause immediately; slow saves pause after the catalog delay.
		if CloudStore.writes_suspended or terminal: _acquire_pause()
		_view.configure_connection(message, terminal)
		_return.visible = terminal
		if terminal: _view.modulate.a = 1.0
	else:
		_blocked = false
		_delay.stop()
		if get_tree().node_added.is_connected(_node_added): get_tree().node_added.disconnect(_node_added)
		if _battle != null and is_instance_valid(_battle.get_ref()): _battle.get_ref().set_network_pause(false)
		_battle = null
		if _owns_pause: get_tree().paused = _paused_tree
		_owns_pause = false
		visible = false
		_view.hide()
func _reload_lobby() -> void:
	var generation: int = CloudStore._generation
	_reload_pending = true
	# Cached in-scene wallets/loadouts must be rebuilt after a canonical swap.
	if SceneTransition.is_transitioning(): await SceneTransition.transition_completed
	if generation != CloudStore._generation: return
	# Release the tree pause for destination setup; the connection modal keeps
	# input blocked and new battles hold their independent network pause reason.
	if _owns_pause: get_tree().paused = _paused_tree
	if SceneTransition.change_scene(LOBBY, CONNECTION_POLICY.RELOADING_LOBBY):
		await SceneTransition.transition_completed
		if generation != CloudStore._generation: return
		var synchronized: bool = await CloudStore.flush()
		if generation != CloudStore._generation: return
		_reload_pending = false
		if synchronized: CloudStore._set_connection(false)
	else:
		_reload_pending = false
		CloudStore._set_connection(true, CONNECTION_POLICY.LOBBY_RELOAD_FAILED, true)
func _return_to_login() -> void:
	_reload_pending = false
	_return.disabled = true
	await LoginGateway.return_to_login()
	_return.disabled = false
