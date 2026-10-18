extends RefCounted
## Public address only; no credential in the setting or URL.
static func endpoint() -> String:
	return String(ProjectSettings.get_setting("online/match_endpoint","")).strip_edges()
