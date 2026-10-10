extends SceneTree
const R := preload("res://rules.gd")
const CONNECTION := preload("res://connection.gd")
const WIRE := preload("res://wire.gd")
var c = CONNECTION.new()
var mode := "server"
var frame := 0
var terminal_frames := 0
var moved := false
var poisoned := false
var announced := false
func _initialize():
	Engine.physics_ticks_per_second = R.TICK_RATE
	var args := OS.get_cmdline_user_args()
	mode = args[0]
	var port := int(args[1])
	var error: int = c.host(port) if mode == "server" else c.join(port)
	print("READY ",mode," ",error)
	if error != OK:quit(1)
func _physics_process(_delta):
	c.step()
	frame += 1
	if c.role != 0 and not announced:
		announced = true
		print("ROLE ",c.role)
	if frame > 1200:
		push_error("probe timeout")
		c.close()
		quit(1)
		return false
	if mode != "server" and c.world.started and c.world.winner == 0:
		if c.role == R.HERO:
			if not poisoned:
				# Real remote wrong-role and oversized-axis commands, not mock ingress.
				c.send_input(R.SUMMON,Vector2(100,100))
				c.send_input(R.MOVE,Vector2(2,0))
				poisoned = true
			if frame % 3 == 0:c.send_input(R.MOVE,Vector2.RIGHT if c.world.tick < 12 else Vector2.ZERO)
			if frame % 6 == 0:c.send_input(R.ATTACK)
		else:
			if frame % 15 == 0:c.send_input(R.SUMMON,c.world.hero_position+Vector2(130,0))
	if c.world.hero_position.x > 600:moved = true
	if c.world.winner != 0:
		terminal_frames += 1
		if terminal_frames >= (90 if mode == "server" else 20):
			var state := PackedByteArray()
			state.resize(R.SNAPSHOT_BYTES)
			WIRE.encode_snapshot(state,c.world,0) # Strip only recipient role for comparison.
			print("RESULT ",JSON.stringify({"mode":mode,"role":c.role,"epoch":c.world.epoch,"tick":c.world.tick,"winner":c.world.winner,"kills":c.world.kills,"moved":moved,"snapshots":c.snapshots,"rejected":c.rejected,"state":state.hex_encode()}))
			c.close()
			quit(0)
	return false
