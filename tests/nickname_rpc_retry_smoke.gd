extends SceneTree
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const CLOUD := preload("res://src/network/cloud_store.gd")
var checks := 0
var failed := false

class Transport extends "res://src/network/cloud_store.gd":
	var calls: Array = []
	var dropped := {}
	func _request_with_token(method: String, data: Dictionary, _token: String) -> Dictionary:
		calls.append({"method":method,"data":data.duplicate(true)})
		await get_tree().process_frame
		if not dropped.has(method):
			dropped[method] = true
			_last_http_status = 0
			return {}
		_last_http_status = 200
		return {"ok":true,"available":true}

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failed=true; push_error(message)

func _initialize() -> void: run.call_deferred()

func run() -> void:
	var id := CLOUD.new_operation_id()
	check(SCOPE.select_account(id),"isolated account")
	var gateway := root.get_node("LoginGateway")
	gateway.user_id = id
	gateway.access_token = "fixture"
	var cloud := Transport.new(); root.add_child(cloud)
	cloud.ready_for_play = true; cloud._initialized=true
	var operation := CLOUD.new_operation_id()
	for method in ["check_player_nickname","rename_player_nickname"]:
		var params := {"chosen_name":"별빛마왕"}
		if method == "rename_player_nickname": params["operation_id"] = operation
		var result := await cloud.request_rpc(method,params)
		check(result.get("ok")==true,"transient "+method+" recovery")
		var entries := cloud.calls.filter(func(c):return c.method==method)
		check(entries.size()==2 and entries[0].data==entries[1].data,"retry preserves name/operation UUID")
		check(not cloud.busy and cloud._rpc_waiters==0 and not cloud.connection_blocked,"RPC serial owner/modal released")
	cloud.stop(); cloud.queue_free(); await process_frame
	SCOPE.select_guest()
	print("NICKNAME_RPC_RETRY checks=",checks," ","FAIL" if failed else "PASS")
	quit(1 if failed else 0)
