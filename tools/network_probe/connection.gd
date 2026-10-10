extends RefCounted
const R := preload("res://rules.gd")
const WORLD := preload("res://world.gd")
const WIRE := preload("res://wire.gd")
var peer: ENetMultiplayerPeer
var world = WORLD.new()
var server := false
var role := 0
var epoch := 0
var sequence := 0
var snapshots := 0
var rejected := 0
var last_error := OK
var slots := PackedInt64Array([0,0])
var last_sequences := PackedInt64Array([0,0])
var received := PackedInt32Array([0,0])
var input_buffer := PackedByteArray()
var snapshot_buffer := PackedByteArray()
var send_tick := 0

func _init():
	input_buffer.resize(R.INPUT_BYTES)
	snapshot_buffer.resize(R.SNAPSHOT_BYTES)

func host(port: int = R.PORT) -> int:
	close()
	server = true
	world = WORLD.new(randi_range(1,R.MAX_SEQUENCE))
	epoch = world.epoch
	peer = ENetMultiplayerPeer.new()
	# Unauthenticated development probe must not expose itself to the Internet.
	peer.set_bind_ip("127.0.0.1")
	last_error = peer.create_server(port,2,2)
	if last_error != OK:
		close()
		return last_error
	peer.peer_connected.connect(_connected)
	peer.peer_disconnected.connect(_disconnected)
	return OK

func join(port: int = R.PORT) -> int:
	close()
	peer = ENetMultiplayerPeer.new()
	last_error = peer.create_client("127.0.0.1",port,2)
	if last_error != OK:close()
	return last_error

func close() -> void:
	if peer != null:peer.close()
	peer = null
	server = false
	role = 0
	epoch = 0
	sequence = 0
	snapshots = 0
	rejected = 0
	send_tick = 0
	slots.fill(0)
	last_sequences.fill(0)
	received.fill(0)
	world = WORLD.new()

func _connected(id: int) -> void:
	if world.started or world.winner != 0:
		peer.disconnect_peer(id)
		return
	for i in 2:
		if slots[i] != 0:continue
		slots[i] = id # First connection HERO, second DEMON: never client-selected.
		last_sequences[i] = 0
		if slots[0] != 0 and slots[1] != 0:
			world.started = true
			peer.refuse_new_connections = true
		return
	peer.disconnect_peer(id)

func _disconnected(id: int) -> void:
	for i in 2:
		if slots[i] != id:continue
		slots[i] = 0
		last_sequences[i] = 0
		if world.started and world.winner == 0:world.winner = 3

func send_input(kind: int, point: Vector2 = Vector2.ZERO) -> bool:
	if peer == null or server or epoch == 0 or not world.started or world.winner != 0 or sequence >= R.MAX_SEQUENCE:return false
	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:return false
	if not is_finite(point.x) or not is_finite(point.y) or absf(point.x) > R.WIDTH or absf(point.y) > R.HEIGHT:return false
	sequence += 1
	WIRE.encode_input(input_buffer,epoch,sequence,kind,point)
	peer.set_target_peer(1)
	peer.transfer_channel = 0
	peer.transfer_mode = MultiplayerPeer.TRANSFER_MODE_RELIABLE
	return peer.put_packet(input_buffer) == OK

func step() -> void:
	if peer == null:return
	peer.poll()
	received.fill(0)
	var budget := R.MAX_PACKETS_PER_TICK
	while budget > 0 and peer.get_available_packet_count() > 0:
		budget -= 1
		var sender := peer.get_packet_peer()
		var channel := peer.get_packet_channel()
		var packet := peer.get_packet()
		if server:
			var slot := 0 if sender == slots[0] else (1 if sender == slots[1] else -1)
			if slot < 0 or channel != 0:
				rejected += 1
				continue
			received[slot] += 1
			if received[slot] > R.MAX_INPUTS_PER_ACTOR_TICK or not WIRE.input_valid(packet,epoch,slot+1,last_sequences[slot]):
				rejected += 1
				continue
			# Consume before gameplay: no replay after cooldown/mana recovers.
			last_sequences[slot] = packet.decode_u32(12)
			var point := Vector2(packet.decode_s16(20)/10.0,packet.decode_s16(22)/10.0)
			if not world.apply_input(slot+1,packet.decode_u32(16),point):rejected += 1
		else:
			if sender != 1 or channel != 1:continue
			var assigned := WIRE.read_snapshot(packet,world,epoch)
			if assigned == 0:continue
			role = assigned
			epoch = world.epoch
			snapshots += 1
	if not server:return
	world.step()
	send_tick += 1
	if send_tick % R.SNAPSHOT_INTERVAL != 0:return
	for i in 2:
		if slots[i] == 0:continue
		WIRE.encode_snapshot(snapshot_buffer,world,i+1)
		peer.set_target_peer(slots[i])
		peer.transfer_channel = 1
		peer.transfer_mode = MultiplayerPeer.TRANSFER_MODE_UNRELIABLE_ORDERED
		peer.put_packet(snapshot_buffer)
