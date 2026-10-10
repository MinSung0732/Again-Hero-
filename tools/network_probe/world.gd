extends RefCounted
const R := preload("res://rules.gd")
# Server-owned fixed pool. No nodes, visuals, peer IDs or per-tick allocations.
var epoch := 1
var tick := 0
var started := false
var winner := 0 # 1 hero, 2 demon, 3 disconnected/aborted.
var kills := 0
var hero_hp := R.HERO_HP
var hero_position := Vector2(600,400)
var hero_axis := Vector2.ZERO
var move_tick := -R.INPUT_TIMEOUT
var next_attack_tick := 0
var mana := R.MANA_MAX
var generation := PackedInt32Array()
var hp := PackedInt32Array()
var x := PackedFloat32Array()
var y := PackedFloat32Array()
var next_hit := PackedInt32Array()

func _init(session: int = 1):
	epoch = session
	generation.resize(R.CAPACITY)
	hp.resize(R.CAPACITY)
	x.resize(R.CAPACITY)
	y.resize(R.CAPACITY)
	next_hit.resize(R.CAPACITY)

func point_valid(point: Vector2) -> bool:
	return is_finite(point.x) and is_finite(point.y) and point.x >= 0 and point.x <= R.WIDTH and point.y >= 0 and point.y <= R.HEIGHT

func apply_input(role: int, kind: int, point: Vector2) -> bool:
	if not started or winner != 0:return false
	if role == R.HERO and kind == R.MOVE:
		if not is_finite(point.x) or not is_finite(point.y) or absf(point.x) > 1 or absf(point.y) > 1:return false
		hero_axis = point.limit_length(1)
		move_tick = tick
		return true
	if role == R.HERO and kind == R.ATTACK:
		if tick < next_attack_tick:return false
		next_attack_tick = tick + R.HERO_COOLDOWN
		# Tiny fixed probe pool only. Production combat will use its existing grid.
		for i in R.CAPACITY:
			if hp[i] <= 0 or hero_position.distance_squared_to(Vector2(x[i],y[i])) > R.ATTACK_RANGE * R.ATTACK_RANGE:continue
			hp[i] = maxi(0,hp[i]-R.HERO_DAMAGE)
			if hp[i] == 0:kills += 1
		if kills >= R.WIN_KILLS:winner = R.HERO
		return true
	if role == R.DEMON and kind == R.SUMMON:
		if not point_valid(point) or mana < R.SUMMON_COST or hero_position.distance_squared_to(point) < R.SUMMON_MIN_DISTANCE * R.SUMMON_MIN_DISTANCE:return false
		for i in R.CAPACITY:
			if hp[i] > 0:continue
			generation[i] += 1
			hp[i] = R.MONSTER_HP
			x[i] = point.x
			y[i] = point.y
			next_hit[i] = tick + R.MONSTER_COOLDOWN
			mana -= R.SUMMON_COST
			return true
	return false

func step() -> void:
	if not started or winner != 0:return
	tick += 1
	if tick - move_tick >= R.INPUT_TIMEOUT:hero_axis = Vector2.ZERO
	hero_position += hero_axis * (R.HERO_SPEED / R.TICK_RATE)
	hero_position.x = clampf(hero_position.x,0,R.WIDTH)
	hero_position.y = clampf(hero_position.y,0,R.HEIGHT)
	mana = minf(R.MANA_MAX,mana + R.MANA_RECOVERY / R.TICK_RATE)
	for i in R.CAPACITY:
		if hp[i] <= 0:continue
		var point := Vector2(x[i],y[i])
		var distance := point.distance_to(hero_position)
		if distance > 30:
			point = point.move_toward(hero_position,R.MONSTER_SPEED / R.TICK_RATE)
			x[i] = point.x
			y[i] = point.y
		elif tick >= next_hit[i]:
			next_hit[i] = tick + R.MONSTER_COOLDOWN
			hero_hp = maxi(0,hero_hp-R.MONSTER_DAMAGE)
			if hero_hp == 0:
				winner = R.DEMON
				return
