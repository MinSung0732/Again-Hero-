extends RefCounted
const R := preload("res://rules.gd")
const WORLD := preload("res://world.gd")

static func encode_input(buffer: PackedByteArray, epoch: int, sequence: int, kind: int, point: Vector2) -> void:
	buffer.encode_u32(0,R.MAGIC)
	buffer.encode_u32(4,R.VERSION)
	buffer.encode_u32(8,epoch)
	buffer.encode_u32(12,sequence)
	buffer.encode_u32(16,kind)
	# Quantized signed axes / map points: no Object or Variant decoding.
	buffer.encode_s16(20,int(round(point.x*10)))
	buffer.encode_s16(22,int(round(point.y*10)))

static func input_valid(buffer: PackedByteArray, epoch: int, role: int, last_sequence: int) -> bool:
	if buffer.size() != R.INPUT_BYTES:return false
	if buffer.decode_u32(0) != R.MAGIC or buffer.decode_u32(4) != R.VERSION or buffer.decode_u32(8) != epoch:return false
	var sequence := buffer.decode_u32(12)
	if sequence <= last_sequence or sequence > R.MAX_SEQUENCE:return false
	var kind := buffer.decode_u32(16)
	if role == R.HERO:
		if kind != R.MOVE and kind != R.ATTACK:return false
		if kind == R.MOVE and (absi(buffer.decode_s16(20)) > 10 or absi(buffer.decode_s16(22)) > 10):return false
	elif role == R.DEMON:
		if kind != R.SUMMON:return false
		if buffer.decode_s16(20) < 0 or buffer.decode_s16(20) > int(R.WIDTH*10) or buffer.decode_s16(22) < 0 or buffer.decode_s16(22) > int(R.HEIGHT*10):return false
	else:return false
	return true

static func encode_snapshot(buffer: PackedByteArray, world: WORLD, role: int) -> void:
	buffer.encode_u32(0,R.MAGIC)
	buffer.encode_u32(4,R.VERSION)
	buffer.encode_u32(8,world.epoch)
	buffer.encode_u32(12,world.tick)
	buffer.encode_u32(16,role)
	buffer.encode_u32(20,world.hero_hp)
	buffer.encode_float(24,world.hero_position.x)
	buffer.encode_float(28,world.hero_position.y)
	buffer.encode_float(32,world.mana)
	buffer.encode_u32(36,world.winner)
	buffer.encode_u32(40,world.kills)
	buffer.encode_u32(44,1 if world.started else 0)
	for i in R.CAPACITY:
		var offset := R.HEADER_BYTES + i*16
		buffer.encode_u32(offset,world.generation[i])
		buffer.encode_u32(offset+4,world.hp[i])
		buffer.encode_float(offset+8,world.x[i])
		buffer.encode_float(offset+12,world.y[i])

static func read_snapshot(buffer: PackedByteArray, world: WORLD, expected_epoch: int) -> int:
	# Validate every field before mutating the client view. Stale snapshots rejected.
	if buffer.size() != R.SNAPSHOT_BYTES:return 0
	if buffer.decode_u32(0) != R.MAGIC or buffer.decode_u32(4) != R.VERSION:return 0
	var epoch := buffer.decode_u32(8)
	var tick := buffer.decode_u32(12)
	var role := buffer.decode_u32(16)
	if epoch == 0 or epoch > R.MAX_SEQUENCE or tick > R.MAX_SEQUENCE or (expected_epoch != 0 and (epoch != expected_epoch or tick < world.tick)):return 0
	if role != R.HERO and role != R.DEMON:return 0
	var point := Vector2(buffer.decode_float(24),buffer.decode_float(28))
	var mana := buffer.decode_float(32)
	if not world.point_valid(point) or not is_finite(mana) or mana < 0 or mana > R.MANA_MAX:return 0
	if buffer.decode_u32(20) > R.HERO_HP or buffer.decode_u32(36) > 3 or buffer.decode_u32(40) > R.WIN_KILLS+R.CAPACITY or buffer.decode_u32(44) > 1:return 0
	for i in R.CAPACITY:
		var offset := R.HEADER_BYTES+i*16
		if buffer.decode_u32(offset) > R.MAX_SEQUENCE or buffer.decode_u32(offset+4) > R.MONSTER_HP or not world.point_valid(Vector2(buffer.decode_float(offset+8),buffer.decode_float(offset+12))):return 0
	world.epoch = epoch
	world.tick = tick
	world.hero_hp = buffer.decode_u32(20)
	world.hero_position = point
	world.mana = mana
	world.winner = buffer.decode_u32(36)
	world.kills = buffer.decode_u32(40)
	world.started = buffer.decode_u32(44) == 1
	for i in R.CAPACITY:
		var offset := R.HEADER_BYTES+i*16
		world.generation[i] = buffer.decode_u32(offset)
		world.hp[i] = buffer.decode_u32(offset+4)
		world.x[i] = buffer.decode_float(offset+8)
		world.y[i] = buffer.decode_float(offset+12)
	return role
