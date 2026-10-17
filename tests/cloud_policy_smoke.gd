extends SceneTree
const CLOUD := preload("res://src/network/cloud_store.gd")
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const POLICY := preload("res://src/data/cloud_connection_catalog.gd")
const CONTRACT := preload("res://src/data/rpc_contract_catalog.gd")
const CODEC := preload("res://src/network/rpc_request_codec.gd")
var checks := 0
var failed := false

class Gateway extends Node:
	var user_id := ""
	var access_token := "fixture"
	var refreshes := 0
	var refresh_ok := false
	func refresh_session() -> bool:
		refreshes += 1
		await get_tree().process_frame
		return refresh_ok

class Transport extends "res://src/network/cloud_store.gd":
	var responses: Array = []
	var calls: Array = []
	func _request_with_token(method: String, data: Dictionary, _token: String) -> Dictionary:
		calls.append({"method":method,"data":data.duplicate(true)})
		await get_tree().process_frame
		var response: Dictionary = responses.pop_front() if not responses.is_empty() else {"status":200,"body":{"ok":true}}
		_last_http_status = int(response.status)
		return response.get("body",{})

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failed = true; push_error(message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	# Frozen pre-refactor boundaries, including the special 401 refresh path.
	var equivalent := true
	for status in range(-1,601):
		var old_retry := not (status > 0 and status < 500 and status not in [408,429])
		var old_permanent := status >= 400 and status <= 499 and status not in [401,408,429]
		if CONTRACT.retry_empty_response(status) != old_retry or CODEC.is_permanent_http_error(status) != old_permanent: equivalent = false
	check(equivalent,"all HTTP decision boundaries retain prior behavior")
	var delay := POLICY.RETRY_INITIAL_SECONDS
	for expected in [1.0,2.0,4.0,8.0,15.0,15.0]:
		check(delay == expected,"retry schedule unchanged")
		delay = POLICY.next_retry_delay(delay)
	var root_cloud := root.get_node("CloudStore")
	var overlay := root.get_node("CloudConnectionOverlay")
	root_cloud.stop()
	root_cloud._set_connection(true,POLICY.CONNECTING,false,false)
	check(overlay.visible and not paused and overlay._view.heading.text==POLICY.CONNECTING,"short save still blocks input without pausing combat")
	check(overlay._delay.wait_time==POLICY.WAIT_SCREEN_DELAY_SECONDS and overlay._view.detail.text==POLICY.CONNECTION_WAIT_DETAIL,"view delay/detail use common policy")
	root_cloud._set_connection(false)
	check(not overlay.visible and not paused,"fast completion releases overlay")
	root_cloud._set_connection(true,POLICY.CONNECTING,false,false)
	await create_timer(POLICY.WAIT_SCREEN_DELAY_SECONDS + 0.05).timeout
	check(paused and overlay._view.modulate.a==1.0,"long save pauses only after the existing grace period")
	root_cloud._set_connection(false)
	check(not paused,"long save recovery releases only its own tree pause")
	paused=true
	root_cloud._set_connection(true)
	root_cloud._set_connection(false)
	check(paused,"pre-existing tree pause survives reconnect")
	paused=false
	for entry in [{"result":{"session_replaced":true},"message":POLICY.SESSION_REPLACED},{"result":{"reauthenticate":true},"message":POLICY.SESSION_EXPIRED}]:
		root_cloud._handle_terminal(entry.result)
		check(root_cloud.connection_message==entry.message and root_cloud.terminal,"session terminal reason preserved")
		root_cloud.stop()
	root_cloud._handle_terminal({"request_rejected":true})
	check(root_cloud.connection_message==POLICY.REQUEST_REJECTED and overlay._return.text==POLICY.RETURN_TO_LOGIN and overlay._return.visible,"rejected request offers login action")
	check(overlay._view.heading.text==POLICY.CONNECTION_CHECK_TITLE and overlay._view.detail.text==POLICY.REQUEST_REJECTED,"terminal view preserves specific reason")
	root_cloud.stop()
	var original := root.get_node("LoginGateway")
	root.remove_child(original); original.free()
	var gateway := Gateway.new(); gateway.name="LoginGateway"; root.add_child(gateway)
	var id := CLOUD.new_operation_id()
	check(SCOPE.select_account(id),"isolated account")
	gateway.user_id = id
	var cloud := Transport.new(); root.add_child(cloud)
	cloud.ready_for_play=true; cloud._initialized=true
	check(cloud._heartbeat.wait_time==15.0,"heartbeat unchanged")
	var expected_methods := ["read_player_profile","register_player_profile","complete_player_prologue","check_player_nickname","rename_player_nickname","change_player_gender"]
	check(CONTRACT.SERIAL_RETRY_METHODS.size()==expected_methods.size(),"no newly retryable mutations")
	var params := {"operation_id":CLOUD.new_operation_id(),"chosen_name":"마왕","chosen_gender":"female"}
	for method in expected_methods:
		cloud.responses=[{"status":0},{"status":200,"body":{"ok":true}}]; cloud.calls.clear()
		var result := await cloud.request_rpc(method,params)
		check(result.get("ok")==true and cloud.calls.size()==2 and cloud.calls[0].data==cloud.calls[1].data,"same operation retried: "+method)
		check(not cloud.busy and cloud._rpc_waiters==0 and not cloud.connection_blocked,"serial loop releases ownership: "+method)
	for method in ["cloud_sync","request_account_withdrawal","future_mutation"]:
		cloud.responses=[{"status":0}]; cloud.calls.clear()
		check((await cloud.request_rpc(method,params)).is_empty() and cloud.calls.size()==1,"unlisted mutation is not retried: "+method)
	for status in [408,429,503]:
		cloud.responses=[{"status":status},{"status":200,"body":{"ok":true}}]; cloud.calls.clear()
		check((await cloud.request_rpc("read_player_profile",params)).get("ok")==true and cloud.calls.size()==2,"transient status recovers: "+str(status))
	cloud.responses=[{"status":401}]; cloud.calls.clear(); gateway.refresh_ok=false; gateway.refreshes=0
	check((await cloud.request_rpc("read_player_profile",params)).is_empty() and gateway.refreshes==1 and cloud.calls.size()==1,"failed 401 refresh does not become infinite delay retry")
	cloud.responses=[{"status":401},{"status":200,"body":{"ok":true}}]; cloud.calls.clear(); gateway.refresh_ok=true; gateway.refreshes=0
	check((await cloud.request_rpc("read_player_profile",params)).get("ok")==true and gateway.refreshes==1 and cloud.calls.size()==2,"401 refresh retries once with same request")
	cloud.responses=[{"status":200,"body":{"ok":false,"error":"duplicate"}}]; cloud.calls.clear()
	check((await cloud.request_rpc("rename_player_nickname",params)).get("error")=="duplicate" and cloud.calls.size()==1,"business rejection never replays mutation")
	cloud.calls.clear(); cloud.responses=[{"status":400,"body":{"request_rejected":true}}]
	check((await cloud.request_rpc("read_player_profile",params)).is_empty() and cloud.terminal and cloud.calls.size()==1 and cloud._timer.is_stopped(),"permanent failure remains terminal")
	cloud.stop()
	for expected in [1.0,2.0,4.0,8.0,15.0,15.0]:
		cloud._retry_later()
		check(cloud._timer.wait_time==expected,"connection timer uses unchanged backoff")
	cloud.stop(); cloud.ready_for_play=true
	cloud._queue_save()
	check(cloud._timer.wait_time==0.15 and not cloud.writes_suspended,"save coalescing remains non-suspending")
	cloud.stop(); cloud.queue_free(); await process_frame
	SCOPE.select_guest()
	print("CLOUD_POLICY checks=",checks," ","FAIL" if failed else "PASS")
	quit(1 if failed else 0)
