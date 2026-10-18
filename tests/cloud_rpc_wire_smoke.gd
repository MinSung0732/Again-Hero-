extends SceneTree
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const CODEC := preload("res://src/network/rpc_request_codec.gd")
const CLOUD := preload("res://src/network/cloud_store.gd")
var checks := 0
var failed := false

class Endpoint extends Node:
	var server := TCPServer.new()
	var peers: Array = []
	var bodies: Array[String] = []
	var save_status := 200
	func _ready() -> void: server.listen(0,"127.0.0.1")
	func url() -> String: return "http://127.0.0.1:%d" % server.get_local_port()
	func _process(_delta: float) -> void:
		if server.is_connection_available(): peers.append({"socket":server.take_connection(),"bytes":PackedByteArray()})
		for i in range(peers.size()-1,-1,-1):
			var item: Dictionary = peers[i]; var socket: StreamPeerTCP=item.socket
			socket.poll()
			if socket.get_available_bytes()>0: item.bytes.append_array(socket.get_data(socket.get_available_bytes())[1])
			var text: String=item.bytes.get_string_from_utf8(); var split:=text.find("\r\n\r\n")
			if split<0: continue
			var length:=0
			for line in text.substr(0,split).split("\r\n"):
				if line.to_lower().begins_with("content-length:"): length=int(line.get_slice(":",1))
			if item.bytes.size()<split+4+length: continue
			var body: String=item.bytes.slice(split+4,split+4+length).get_string_from_utf8()
			bodies.append(body)
			var request: Dictionary=JSON.parse_string(body)
			var status:=200; var result: Dictionary={"ok":true}
			if body.contains('"expected_revision":1.0'): status=400
			elif request.get("action")=="read": result={"found":true,"revision":1,"payload":{"stage_progress.cfg":{"meta":{"gold":7}}}}
			elif request.get("action")=="save": status=save_status; result={"ok":true,"revision":2}
			if status!=200: result={"code":"22P02" if status==400 else "unavailable"}
			var bytes:=JSON.stringify(result).to_utf8_buffer()
			var header:="HTTP/1.1 %d Test\r\nContent-Type: application/json\r\nContent-Length: %d\r\nConnection: close\r\n\r\n" % [status,bytes.size()]
			socket.put_data(header.to_utf8_buffer()); socket.put_data(bytes)
			socket.disconnect_from_host(); peers.remove_at(i)
	func _exit_tree() -> void:
		server.stop()
		for item in peers: item.socket.disconnect_from_host()

class Cloud extends "res://src/network/cloud_store.gd":
	var url := ""
	func _rpc_endpoint(method: String) -> String: return url+"/"+method

func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failed=true; push_error(message)

func _initialize() -> void: run.call_deferred()

func run() -> void:
	var restored: Dictionary=JSON.parse_string('{"expected_revision":1,"new_payload":{"ratio":2.5}}')
	check(JSON.stringify(restored).contains('"expected_revision":1.0'),"reproduce restored JSON decimal wire token")
	var encoded:=CODEC.encode("cloud_sync",restored)
	check(encoded.ok and String(encoded.body).contains('"expected_revision":1,') and String(encoded.body).contains('"ratio":2.5'),"normalize only contract integer without rounding gameplay fractions")
	check(typeof(restored.expected_revision)==TYPE_FLOAT,"encoding does not mutate caller/pending state")
	for value in [-1,1.5,"1",true,null,INF,NAN,9007199254740992.0]:
		check(not CODEC.encode("cloud_sync",{"expected_revision":value}).ok,"reject invalid integer argument")
	check(CODEC.encode("cloud_sync",{"action":"read"}).ok,"optional argument stays omitted")
	for status in [400,403,404,422]: check(CODEC.is_permanent_http_error(status),"permanent client status")
	for status in [0,200,401,408,429,500,503]: check(not CODEC.is_permanent_http_error(status),"transient/auth status")
	var endpoint:=Endpoint.new(); root.add_child(endpoint)
	# Actual HTTP negative control: demonstrates the old decimal request gets 400.
	var http:=HTTPRequest.new(); root.add_child(http)
	http.request(endpoint.url()+"/cloud_sync",PackedStringArray(["Content-Type: application/json"]),HTTPClient.METHOD_POST,JSON.stringify(restored))
	var raw: Array=await http.request_completed
	check(raw[1]==400,"old restored decimal rejected over real HTTP")
	http.queue_free()
	var id:=CLOUD.new_operation_id()
	check(SCOPE.select_account(id),"isolated account")
	SCOPE.write_allowed=Callable(); SCOPE.saved_callback=Callable()
	SCOPE.install({"stage_progress.cfg":{"meta":{"gold":7}}},1)
	var config:=ConfigFile.new(); SCOPE.load_config(config,"user://stage_progress.cfg"); config.set_value("meta","gold",17)
	check(SCOPE.save_config(config,"user://stage_progress.cfg")==OK,"seed durable unsent save")
	var operation: String=SCOPE.pending_cloud.operation_id
	SCOPE.pending_cloud.sent=true; SCOPE.persist()
	check(SCOPE.select_account(id) and SCOPE.pending_cloud.operation_id==operation and typeof(SCOPE.pending_cloud.expected_revision)==TYPE_INT,"restore request ID and integer revision from cache")
	root.get_node("LoginGateway").user_id=id
	var cloud:=Cloud.new(); cloud.url=endpoint.url(); root.add_child(cloud)
	check(await cloud.initialize(),"login claim/read/cache replay completes over real HTTP")
	check(SCOPE.revision==2 and not SCOPE.dirty and not cloud.connection_blocked and cloud.ready_for_play,"login leaves waiting screen after save acknowledgement")
	check(endpoint.bodies.any(func(body):return body.contains('"expected_revision":1,') and body.contains(operation)),"saved operation identity is unchanged on integer wire")
	config.set_value("meta","gold",18); SCOPE.save_config(config,"user://stage_progress.cfg")
	endpoint.save_status=503
	check(not await cloud.flush() and not cloud.terminal and not cloud._timer.is_stopped(),"503 remains recoverable")
	cloud._timer.stop(); endpoint.save_status=400
	check(not await cloud.flush() and cloud.terminal and cloud._timer.is_stopped(),"400 cannot enter infinite reconnect loop")
	check(SCOPE.dirty and not SCOPE.pending_cloud.is_empty() and cloud.writes_suspended,"rejected save is retained and further writes blocked")
	check(cloud.connection_message==CODEC.CONTRACT.REJECTED_MESSAGE,"terminal state offers return to login")
	cloud.stop(); cloud.queue_free(); endpoint.queue_free(); await process_frame
	SCOPE.select_guest()
	print("CLOUD_RPC_WIRE checks=",checks," ","FAIL" if failed else "PASS")
	quit(1 if failed else 0)
