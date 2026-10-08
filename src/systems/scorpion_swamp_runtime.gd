extends RefCounted

const BEHAVIOR := preload("res://src/data/scorpion_behavior_catalog.gd")
const VISUAL_POOL_KEY := "scorpion_venom_swamp_sprite"
static var textures: Array[Texture2D] = []

const POOL_KEY := "scorpion_venom_swamp"
var battle: Node
var zones: Array = []
static var circle_points := PackedVector2Array()

func setup(authority: Node) -> void:
	battle = authority
	warm_resources()
	if circle_points.is_empty():
		for i in range(40):
			circle_points.append(Vector2.RIGHT.rotated(TAU * float(i) / 40.0))

static func warm_resources() -> void:
	if not textures.is_empty():
		return
	var spec: Dictionary = BEHAVIOR.SWAMP_VISUAL
	for index in range(1, int(spec.frame_count) + 1):
		var path := "%s/effect_%02d.png" % [spec.directory, index]
		var texture: Texture2D
		if ResourceLoader.exists(path):
			texture = load(path) as Texture2D
		if texture == null:
			var image := Image.new()
			if image.load(path) == OK:
				texture = ImageTexture.create_from_image(image)
		textures.append(texture)


func _update_visual(zone: Dictionary) -> void:
	var sprite := zone.get("sprite") as Sprite2D
	if not is_instance_valid(sprite):
		return
	var spec: Dictionary = BEHAVIOR.SWAMP_VISUAL
	var seconds := float(spec.frame_seconds)
	var elapsed := float(zone.elapsed)
	var remaining := float(zone.duration) - elapsed
	var index: int
	if remaining <= seconds * int(spec.outro_count):
		index = int(spec.outro_first) + clampi(int((seconds * int(spec.outro_count) - remaining) / seconds), 0, int(spec.outro_count) - 1)
	elif elapsed < seconds * int(spec.intro_count):
		index = mini(int(elapsed / seconds), int(spec.intro_count) - 1)
	else:
		index = int(spec.loop_first) + int((elapsed - seconds * int(spec.intro_count)) / seconds) % int(spec.loop_count)
	sprite.texture = textures[clampi(index, 0, textures.size() - 1)]


func spawn(location: Vector2, attack: int, config: Dictionary, source: Node) -> void:
	if not is_instance_valid(battle):
		return
	var radius := float(config.get("radius", 75.0))
	var line := battle.acquire_transient_fx(POOL_KEY, "line") as Line2D
	if line != null:
		line.points = circle_points
		line.closed = true
		line.width = 1.5 / maxf(radius, 1.0)
		line.scale = Vector2.ONE * radius
		line.global_position = location
		line.default_color = Color(0.43, 0.88, 0.25, 0.8)
		line.z_index = 1
	var sprite := battle.acquire_transient_fx(VISUAL_POOL_KEY, "sprite") as Sprite2D
	if sprite != null:
		sprite.centered = false
		sprite.offset = -BEHAVIOR.SWAMP_VISUAL.anchor
		sprite.scale = Vector2.ONE * (radius * 2.0 / float(BEHAVIOR.SWAMP_VISUAL.reference_width))
		sprite.global_position = location
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		# Floor effect remains beneath the standing actors and their status bars.
		sprite.z_as_relative = false
		sprite.z_index = -1 if battle.y_sort_enabled else 0
	var duration := maxf(float(config.get("duration", 3.0)), 0.1)
	zones.append({"position":location, "radius_sq":radius * radius, "duration":duration, "elapsed":0.0, "tick":0.5, "total":maxi(int(round(attack * float(config.get("damage_multiplier", 2.0)))), 0), "apportioned":0, "source":weakref(source), "line":line, "sprite":sprite})
	_update_visual(zones.back())

func tick(delta: float) -> void:
	for i in range(zones.size() - 1, -1, -1):
		var zone: Dictionary = zones[i]
		zone.elapsed = minf(float(zone.elapsed) + delta, float(zone.duration))
		_update_visual(zone)
		zone.tick = float(zone.tick) - delta
		if float(zone.tick) <= 0.0 or float(zone.elapsed) >= float(zone.duration):
			var cumulative := int(round(float(zone.total) * float(zone.elapsed) / float(zone.duration)))
			var damage := maxi(cumulative - int(zone.apportioned), 0)
			zone.apportioned = cumulative
			zone.tick = 0.5
			var target := battle.get("hero") as Node2D
			if damage > 0 and is_instance_valid(target) and target.global_position.distance_squared_to(zone.position) <= float(zone.radius_sq):
				target.call("take_status_damage", damage, zone.source.get_ref())
		if float(zone.elapsed) >= float(zone.duration):
			if is_instance_valid(zone.line):
				battle.recycle_transient_fx(zone.line, POOL_KEY)
			if is_instance_valid(zone.sprite):
				battle.recycle_transient_fx(zone.sprite, VISUAL_POOL_KEY)
			zones[i] = zones.back()
			zones.pop_back()
