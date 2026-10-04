extends RefCounted

# Select namespace before progression reads; never migrate guest data silently.
static var user_id := ""

static func select_account(id: String) -> bool:
	var pattern := RegEx.new()
	pattern.compile("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$")
	if pattern.search(id) == null:
		return false
	if DirAccess.make_dir_recursive_absolute("user://accounts/" + id.to_lower()) != OK:
		return false
	user_id = id.to_lower()
	return true

static func select_guest() -> void:
	user_id = ""

static func resolve(legacy_path: String) -> String:
	return legacy_path if user_id.is_empty() else "user://accounts/%s/%s" % [user_id, legacy_path.get_file()]
