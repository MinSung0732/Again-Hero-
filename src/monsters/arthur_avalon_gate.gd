extends Node2D
# No collision body or registry entry: invulnerable, untargetable support structure.
const DATA := preload("res://src/data/arthur_behavior_catalog.gd")
const FX := preload("res://src/ui/arthur_combat_effects.gd")
var authority: Node
var source: WeakRef
var duration := 30.0
var age := 0.0
var query_timer := 0.0
var neighbors: Array = []
var records: Dictionary = {}
var stale: Array[int] = []
var buffed_count := 0
func setup(battle: Node, caster: Node, seconds: float) -> void:
	authority = battle
	source = weakref(caster)
	duration = seconds
func _ready() -> void:
	# Match CastleDepthProp roots: same-Z direct children are ordered by feet Y.
	z_index = 0
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	FX.prepare(1)
func _physics_process(delta: float) -> void:
	if not is_instance_valid(authority) or authority.battle_over:
		_clear_buffs()
		queue_free()
		return
	if authority.external_pause or authority.demon_augment_selection_active: return
	age += delta
	if age>=duration and not records.is_empty(): _clear_buffs()
	query_timer -= delta
	if query_timer <= 0:
		query_timer = 0.2
		_refresh_members()
	for id in records:
		var entry: Dictionary = records[id]
		var actor: Node = entry.target.get_ref()
		if not _inside(actor): continue
		# Snapshot each five-second cycle; distribute it only while inside.
		if float(entry.cycle) <= 0:
			entry.cycle = DATA.GATE_CYCLE
			entry.shield = actor.current_hp >= actor.max_hp
			entry.budget = actor.current_hp*DATA.GATE_RECOVERY if entry.shield else (actor.max_hp-actor.current_hp)*DATA.GATE_RECOVERY
			entry.fraction = 0.0
		var step := minf(delta,float(entry.cycle))
		entry.cycle = maxf(float(entry.cycle)-step,0)
		entry.fraction = float(entry.fraction)+float(entry.budget)*step/DATA.GATE_CYCLE
		var paid := int(entry.fraction)
		entry.fraction = float(entry.fraction)-paid
		if paid > 0:
			if entry.shield:
				preload("res://src/monsters/monster_runtime_common.gd").add_support_shield(actor,paid)
			else:
				actor.current_hp = mini(actor.max_hp,actor.current_hp+paid)
				actor.queue_redraw()
	var caster: Node = source.get_ref()
	if is_instance_valid(caster): caster.gate_boost_count = buffed_count
	queue_redraw()
	if age >= duration+0.3: queue_free()
func _inside(actor: Node) -> bool:
	return age < duration and is_instance_valid(actor) and not actor.is_queued_for_deletion() and actor.current_hp > 0 and not actor.get("dying") and global_position.distance_squared_to(actor.global_position) <= DATA.GATE_RADIUS*DATA.GATE_RADIUS
func _refresh_members() -> void:
	neighbors.clear()
	if age < duration: authority.fill_monsters_near(global_position,DATA.GATE_RADIUS,neighbors)
	stale.clear()
	for id in records:
		var actor: Node = records[id].target.get_ref()
		if not _inside(actor):
			_restore(records[id])
			stale.append(id)
	for id in stale: records.erase(id)
	for actor in neighbors:
		if not _inside(actor): continue
		var id: int = actor.get_instance_id()
		if not records.has(id):
			var interval := float(actor.get("attack_cooldown")) if actor.get("attack_cooldown") != null else 0.0
			records[id] = {"target":weakref(actor),"base_interval":interval,"applied_interval":interval/DATA.GATE_HASTE,"cycle":0.0,"fraction":0.0,"budget":0.0,"shield":false}
			if interval > 0: actor.set("attack_cooldown",interval/DATA.GATE_HASTE)
			actor.set_meta("arthur_gate_active",true)
			actor.set_meta("arthur_gate_speed",DATA.GATE_SPEED)
		else:
			var entry: Dictionary = records[id]
			var interval = actor.get("attack_cooldown")
			# An augment may replace a stat while the gate is active: rebase once.
			if interval != null and not is_equal_approx(float(interval),float(entry.applied_interval)):
				entry.base_interval = float(interval)
				entry.applied_interval = float(interval)/DATA.GATE_HASTE
				actor.set("attack_cooldown",entry.applied_interval)
	buffed_count = records.size()
func _restore(entry: Dictionary) -> void:
	var actor: Node = entry.target.get_ref()
	if not is_instance_valid(actor): return
	if actor.get("attack_cooldown") != null and is_equal_approx(float(actor.get("attack_cooldown")),float(entry.applied_interval)):
		actor.set("attack_cooldown",entry.base_interval)
	actor.set_meta("arthur_gate_active",false)
	actor.set_meta("arthur_gate_speed",1.0)
func _clear_buffs() -> void:
	for id in records: _restore(records[id])
	records.clear()
	buffed_count = 0
	var caster: Node = source.get_ref() if source != null else null
	if is_instance_valid(caster): caster.gate_boost_count = 0
func _exit_tree() -> void: _clear_buffs()
func _draw() -> void:
	var frame := mini(4,int(age*8)) if age < 0.625 else 4+int(age*5)%2
	if age >= duration: frame = 6+mini(1,int((age-duration)*8))
	FX.draw_frame(self,1,frame,Vector2.ZERO)
	if age < duration:
		draw_arc(Vector2.ZERO,DATA.GATE_RADIUS,0,TAU,96,Color(0.9,0.8,0.4,0.65),1.2)
		draw_rect(Rect2(-50,-270,100,5),Color(0.08,0.08,0.12))
		draw_rect(Rect2(-50,-270,100*maxf(1-age/duration,0),5),Color(0.9,0.8,0.35))
