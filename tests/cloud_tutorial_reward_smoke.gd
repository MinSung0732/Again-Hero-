extends SceneTree
const SCOPE := preload("res://src/systems/account_save_scope.gd")
const FIXTURE := preload("res://tests/tutorial_smoke.gd")
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func run() -> void:
	root.get_node("LoginGateway").remember_session_enabled = false
	root.get_node("LocalTestMode").active = false
	root.get_node("LocalTestMode").tutorial_preview = false
	var id: String = root.get_node("CloudStore").new_operation_id()
	check(SCOPE.select_account(id), "isolated account")
	SCOPE.install({"stage_progress.cfg":{"meta":{"gold":23}}},1)
	root.get_node("LoginGateway").user_id = id
	var cloud := FIXTURE.FakeCloud.new()
	root.add_child(cloud)
	cloud.snapshot = SCOPE.files.duplicate(true)
	cloud.ready_for_play = true
	cloud._initialized = true
	# The production overlay rebuilds scene caches before releasing this fence.
	cloud.canonical_reloaded.connect(func(): cloud._set_connection(false))
	cloud.offline = true
	check((await cloud.tutorial_operation("skip")).is_empty(), "offline reward fails closed")
	check(SCOPE.files["stage_progress.cfg"].meta.gold == 23 and cloud.grants == 0, "offline never fabricates reward")
	cloud.offline = false
	check((await cloud.tutorial_operation("start")).get("ok") == true, "tutorial start can retry")
	cloud.drop_tutorial_ack = true
	check((await cloud.tutorial_operation("complete")).is_empty() and cloud.grants == 1, "server commits reward before lost response")
	check(SCOPE.files["stage_progress.cfg"].meta.gold == 23, "unconfirmed reward not installed")
	check(await cloud.initialize(), "canonical recovery installs committed reward")
	check(SCOPE.files["stage_progress.cfg"].meta.gold == 1023 and not cloud.connection_blocked, "recovered wallet released after scene refresh")
	var result: Dictionary = await cloud.tutorial_operation("complete")
	check(result.get("granted") == 0 and cloud.grants == 1 and SCOPE.files["stage_progress.cfg"].meta.gold == 1023, "repeated claim cannot duplicate currency")
	cloud.stop()
	cloud.queue_free()
	var folder := SCOPE.resolve("user://save_bundle.json").get_base_dir()
	SCOPE.select_guest()
	root.get_node("LoginGateway").user_id = ""
	for file in DirAccess.get_files_at(folder): DirAccess.remove_absolute(folder.path_join(file))
	DirAccess.remove_absolute(folder)
	await process_frame
	print("CLOUD_TUTORIAL_REWARD checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
