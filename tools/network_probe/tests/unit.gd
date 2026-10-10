extends SceneTree
const R := preload("res://rules.gd")
const WORLD := preload("res://world.gd")
const WIRE := preload("res://wire.gd")
const CONNECTION := preload("res://connection.gd")
var checks := 0
var failures := 0
func check(value: bool, message: String):
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func _initialize():
	var input := PackedByteArray()
	input.resize(R.INPUT_BYTES)
	for role in [R.HERO,R.DEMON,0,3]:
		for kind in [R.MOVE,R.ATTACK,R.SUMMON,0,99]:
			WIRE.encode_input(input,12,1,kind,Vector2.ZERO)
			var expected: bool = (role == R.HERO and kind in [R.MOVE,R.ATTACK]) or (role == R.DEMON and kind == R.SUMMON)
			check(WIRE.input_valid(input,12,role,0) == expected,"role/kind permission")
			check(not WIRE.input_valid(input,13,role,0),"wrong session")
			check(not WIRE.input_valid(input,12,role,1),"duplicate sequence")
	for size in [0,1,23,25,1000]:
		var bad := PackedByteArray()
		bad.resize(size)
		check(not WIRE.input_valid(bad,12,R.HERO,0),"exact packet length")
	WIRE.encode_input(input,12,1,R.MOVE,Vector2(2,0))
	check(not WIRE.input_valid(input,12,R.HERO,0),"movement bounds")
	WIRE.encode_input(input,12,1,R.SUMMON,Vector2(-1,0))
	check(not WIRE.input_valid(input,12,R.DEMON,0),"map bounds")
	WIRE.encode_input(input,12,R.MAX_SEQUENCE+1,R.ATTACK,Vector2.ZERO)
	check(not WIRE.input_valid(input,12,R.HERO,0),"sequence upper bound")
	var w = WORLD.new(12)
	check(not w.apply_input(R.HERO,R.MOVE,Vector2.RIGHT),"waiting gate")
	w.started = true
	check(not w.apply_input(R.HERO,R.SUMMON,Vector2.ZERO),"world role guard")
	check(not w.apply_input(R.DEMON,R.SUMMON,w.hero_position),"summon exclusion")
	check(not w.apply_input(R.HERO,R.MOVE,Vector2(NAN,0)),"finite movement")
	check(w.apply_input(R.HERO,R.MOVE,Vector2(1,1)),"valid move")
	var origin: Vector2 = w.hero_position
	w.step()
	check(is_equal_approx(w.hero_position.distance_to(origin),R.HERO_SPEED/R.TICK_RATE),"diagonal speed clamped")
	for i in R.INPUT_TIMEOUT:w.step()
	origin = w.hero_position
	w.step()
	check(w.hero_position == origin,"input expires instead of endless motion")
	var spawn: Vector2 = w.hero_position + Vector2(130,0)
	check(w.apply_input(R.DEMON,R.SUMMON,spawn),"summon")
	check(w.mana < R.MANA_MAX and w.generation[0] == 1,"server cost/generation")
	check(w.apply_input(R.HERO,R.ATTACK,Vector2.ZERO),"attack")
	check(w.hp[0] == R.MONSTER_HP-R.HERO_DAMAGE,"server damage")
	check(not w.apply_input(R.HERO,R.ATTACK,Vector2.ZERO),"cooldown guard")
	for i in R.HERO_COOLDOWN:w.step()
	w.apply_input(R.HERO,R.ATTACK,Vector2.ZERO)
	check(w.hp[0] == 0 and w.kills == 1,"kill once")
	check(w.apply_input(R.DEMON,R.SUMMON,w.hero_position+Vector2(130,0)) and w.generation[0] == 2,"slot reuse changes generation")
	var snapshot := PackedByteArray()
	snapshot.resize(R.SNAPSHOT_BYTES)
	WIRE.encode_snapshot(snapshot,w,R.HERO)
	var view = WORLD.new()
	check(WIRE.read_snapshot(snapshot,view,0) == R.HERO and view.hero_position == w.hero_position and view.hp == w.hp,"snapshot roundtrip")
	var frozen: Vector2 = view.hero_position
	for offset in range(0,R.SNAPSHOT_BYTES,4):
		var bad: PackedByteArray = snapshot.duplicate()
		bad.encode_u32(offset,0xffffffff)
		check(WIRE.read_snapshot(bad,view,12) == 0 and view.hero_position == frozen,"bad snapshot rejected atomically")
	# Older tick or different epoch cannot overwrite a newer view.
	view.tick = w.tick+1
	check(WIRE.read_snapshot(snapshot,view,12) == 0,"stale tick")
	check(WIRE.read_snapshot(snapshot,view,13) == 0,"stale epoch")
	w.winner = R.DEMON
	origin = w.hero_position
	var tick: int = w.tick
	w.step()
	check(w.tick == tick and w.hero_position == origin and not w.apply_input(R.HERO,R.ATTACK,Vector2.ZERO),"terminal state")
	var full = WORLD.new(99)
	full.started = true
	for i in R.CAPACITY:
		check(full.apply_input(R.DEMON,R.SUMMON,Vector2(0,0)),"fixed pool slot available")
	var mana: float = full.mana
	check(not full.apply_input(R.DEMON,R.SUMMON,Vector2(0,0)) and full.mana == mana,"full pool does not charge mana")
	full.mana = 0
	full.hp[0] = 0
	check(not full.apply_input(R.DEMON,R.SUMMON,Vector2(0,0)),"mana gate")
	var lethal = WORLD.new(100)
	lethal.started = true
	lethal.hero_hp = R.MONSTER_DAMAGE
	lethal.hp[0] = R.MONSTER_HP
	lethal.x[0] = lethal.hero_position.x
	lethal.y[0] = lethal.hero_position.y
	lethal.step()
	check(lethal.hero_hp == 0 and lethal.winner == R.DEMON,"demon victory server decision")
	var link = CONNECTION.new()
	link.slots[0] = 99
	link.world.started = true
	link._disconnected(99)
	check(link.world.winner == 3 and link.slots[0] == 0,"disconnect abort")
	link.slots[0] = 100
	link.world.winner = R.HERO
	link._disconnected(100)
	check(link.world.winner == R.HERO,"disconnect cannot overwrite finalized result")
	link.close()
	check(link.epoch == 0 and link.sequence == 0 and not link.world.started,"close invalidates session")
	print("UNIT ",checks," failures ",failures)
	quit(1 if failures else 0)
