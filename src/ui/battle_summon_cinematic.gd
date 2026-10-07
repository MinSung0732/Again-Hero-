extends Control

const CATALOG := preload("res://src/data/battle_summon_cinematic_catalog.gd")
var host: Control
var active := false
var actor: Node2D
var original: Camera2D
var camera: Camera2D
var spotlight: ColorRect
var shade: ShaderMaterial
var view: Control
var views: Dictionary = {}
var elapsed := 0.0
var duration := 5.0
var zoom_factor := 1.3
var start_center := Vector2.ZERO
var start_zoom := Vector2.ONE
var return_center := Vector2.ZERO
var return_zoom := Vector2.ONE
var returning := false

func install(main: Control) -> void:
	host = main
	name = "BattleSummonCinematic"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	z_index = 70
	host.hud_layer.add_child(self)
	camera = Camera2D.new()
	camera.enabled = false
	host.battle.add_child(camera)
	spotlight = ColorRect.new()
	spotlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade = ShaderMaterial.new()
	shade.shader = preload("res://src/ui/battle_summon_spotlight.gdshader")
	spotlight.material = shade
	add_child(spotlight)
	host.battle.transcendent_summoned.connect(play)
	host.battle.battle_finished.connect(_finished)
	hide()
	set_process(false)
	# Prewarm once during installation; successful summon never allocates a new view.
	for entry in CATALOG.ENTRIES.values():
		_cached_view(String(entry.view))

func play(monster_id: String, summoned: Node2D) -> void:
	cancel()
	if not CATALOG.ENTRIES.has(monster_id) or not is_instance_valid(summoned):
		return
	original = host.battle_viewport.get_camera_2d()
	if not is_instance_valid(original):
		return
	var entry: Dictionary = CATALOG.ENTRIES[monster_id]
	var path: String = entry.view
	view = _cached_view(path)
	if view == null:
		return
	actor = summoned
	duration = float(entry.duration)
	zoom_factor = float(entry.zoom)
	elapsed = 0.0
	returning = false
	start_center = original.get_screen_center_position()
	start_zoom = original.zoom
	camera.global_position = start_center
	camera.offset = Vector2.ZERO
	camera.zoom = start_zoom
	camera.limit_left = original.limit_left
	camera.limit_top = original.limit_top
	camera.limit_right = original.limit_right
	camera.limit_bottom = original.limit_bottom
	camera.enabled = true
	camera.make_current()
	active = true
	host._end_camera_drag()
	_layout()
	view.show()
	view.set_time(0.0)
	show()
	set_process(true)

func _layout() -> void:
	var panel: Rect2 = host.battle_viewport_container.get_global_rect()
	global_position = panel.position
	size = panel.size
	spotlight.size = size
	# Keep the entire portrait inside the battle area, above the lower battle HUD.
	var h := minf(size.y * 0.68, size.x * 0.78)
	view.size = Vector2(h * 540.0 / 960.0, h)
	view.position = size - view.size - Vector2(16, 24)
	shade.set_shader_parameter("panel_size", size)

func _process(delta: float) -> void:
	if not active:
		return
	if not is_instance_valid(actor) or not actor.is_inside_tree() or host.battle.battle_over or not host.battle_viewport_container.is_visible_in_tree():
		cancel()
		return
	if actor.get("current_hp") != null and int(actor.get("current_hp")) <= 0:
		cancel()
		return
	# Menus/augment selection interrupt cleanly without changing battle pause state.
	if host.battle.external_pause or host.battle.demon_augment_selection_active:
		cancel()
		return
	elapsed = minf(elapsed + delta, duration)
	_layout()
	if elapsed < 4.0:
		var approach := 1.0 - pow(1.0 - clampf(elapsed / 0.95, 0.0, 1.0), 3.0)
		camera.global_position = start_center.lerp(actor.global_position, approach)
		var zoom_in := smoothstep(0.75, 2.1, elapsed)
		var zoom_out := smoothstep(3.1, 4.0, elapsed)
		camera.zoom = start_zoom * (1.0 + (zoom_factor - 1.0) * zoom_in * (1.0 - zoom_out * 0.45))
	else:
		if not returning:
			returning = true
			return_center = camera.global_position
			return_zoom = camera.zoom
		if is_instance_valid(original):
			var back := smoothstep(4.0, duration, elapsed)
			# Original camera keeps its follow/manual transform untouched throughout.
			camera.global_position = return_center.lerp(original.global_position + original.offset, back)
			camera.zoom = return_zoom.lerp(original.zoom, back)
	camera.force_update_scroll()
	var projected: Vector2 = host.battle_viewport.get_canvas_transform() * actor.global_position
	var normalized: Vector2 = projected / Vector2(host.battle_viewport.size)
	shade.set_shader_parameter("focus", normalized)
	shade.set_shader_parameter("strength", smoothstep(0.1, 0.85, elapsed) * (1.0 - smoothstep(3.8, duration, elapsed)))
	view.set_time(elapsed)
	view.modulate.a = 1.0 - smoothstep(4.3, duration, elapsed)
	if elapsed >= duration:
		cancel()

func cancel() -> void:
	active = false
	set_process(false)
	if is_instance_valid(camera):
		camera.enabled = false
	if is_instance_valid(original) and original.is_inside_tree():
		original.make_current()
		original.force_update_scroll()
	if is_instance_valid(view):
		view.hide()
		view.modulate.a = 1.0
	shade.set_shader_parameter("strength", 0.0)
	actor = null
	original = null
	hide()

func _finished(_message: String, _won: bool) -> void:
	cancel()

func _exit_tree() -> void:
	cancel()

func _cached_view(path: String) -> Control:
	if views.has(path):
		return views[path]
	var script = load(path)
	if script == null or not script.can_instantiate():
		return null
	var created: Control = script.new()
	add_child(created)
	created.hide()
	views[path] = created
	return created
