extends RefCounted

const POOL_KEY := "scorpion_venom_swamp"
var battle: Node
var zones: Array = []
static var circle_points := PackedVector2Array()

func setup(authority: Node) -> void:
	battle = authority
	if circle_points.is_empty():
		for i in range(40):
			circle_points.append(Vector2.RIGHT.rotated(TAU * float(i) / 40.0))

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
	var duration := maxf(float(config.get("duration", 3.0)), 0.1)
	zones.append({"position":location, "radius_sq":radius * radius, "duration":duration, "elapsed":0.0, "tick":0.5, "total":maxi(int(round(attack * float(config.get("damage_multiplier", 2.0)))), 0), "apportioned":0, "source":weakref(source), "line":line})

func tick(delta: float) -> void:
	for i in range(zones.size() - 1, -1, -1):
		var zone: Dictionary = zones[i]
		zone.elapsed = minf(float(zone.elapsed) + delta, float(zone.duration))
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
			zones[i] = zones.back()
			zones.pop_back()
