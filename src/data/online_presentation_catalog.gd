extends RefCounted
## Wire-only presentation policy; combat sizes/anchors come from live visuals.
const MAX_COMMANDS := 128
const MAX_ACTORS := 216
# Display policy only; no movement speed or combat rule is inferred here.
const MOTION_SECONDS := preload("res://src/online/match_rules.gd").SNAPSHOT_INTERVAL
const MOTION_RESET_SECONDS := MOTION_SECONDS * 3.0
const MOTION_SNAP_DISTANCE := 256.0
const MAX_TEXTURES := 512
const COMMAND_SIZE := 22
const BACKGROUND_Z := -100
const MAX_WORLD_EXTENT := 8192.0
const EMPTY := []
const ART_ROOT := "res://assets/art/"
const MAX_PATH_LENGTH := 256
const MAX_TEXTURE_EXTENT := 8192.0
static func path_allowed(path: Variant) -> bool:
	return path is String and path.length() <= MAX_PATH_LENGTH and path.begins_with(ART_ROOT) and path.ends_with(".png") and not path.contains("..") and not path.contains("\\")
static func valid(command: Variant) -> bool:
	if not command is Array or command.size() != COMMAND_SIZE or not path_allowed(command[1]): return false
	for index in COMMAND_SIZE:
		if index == 1: continue
		var value: Variant = command[index]
		if not (value is float or value is int) or not is_finite(float(value)) or absf(float(value)) > 1000000.0: return false
	for index in [2,3,4,5]:
		if command[index] < 0 or command[index] > MAX_TEXTURE_EXTENT: return false
	if command[4] <= 0 or command[5] <= 0 or command[14] <= 0 or command[15] <= 0: return false
	for index in range(16,20):
		if command[index] < 0 or command[index] > 1: return false
	return true
static func battlefield_valid(value: Variant) -> bool:
	if not value is Dictionary or value.size() != 2 or not value.get("stage",null) is String or not value.get("bounds",null) is Array or value.bounds.size() != 2: return false
	var stages := preload("res://src/data/stage_catalog.gd")
	if not stages.STAGES.has(value.stage): return false
	for size in value.bounds:
		if not (size is float or size is int) or not is_finite(float(size)) or size < 500 or size > MAX_WORLD_EXTENT: return false
	return true
