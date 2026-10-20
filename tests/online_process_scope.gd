extends RefCounted
## Test-only: simultaneous engine processes must not share a guest journal.
const SCOPE := preload("res://src/systems/account_save_scope.gd")
static func configure(role: String) -> bool:
	if role not in ["server","hero","demon"]: return false
	SCOPE.select_guest()
	SCOPE.guest_directory = "user://online_process_fixture/%s_%d/"%[role,OS.get_process_id()]
	return DirAccess.make_dir_recursive_absolute(SCOPE.guest_directory)==OK
