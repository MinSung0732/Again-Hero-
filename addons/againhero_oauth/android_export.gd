@tool
extends EditorExportPlugin

func _get_name() -> String:
	return "AgainHeroOAuth"

# Only the browser-return hint is delivered here. OAuth code and PKCE verifier
# stay on the existing authenticated loopback channel, never in the deep link.
func _get_android_manifest_activity_element_contents(_platform: EditorExportPlatform, _debug: bool) -> String:
	return """
	<intent-filter>
		<action android:name="android.intent.action.VIEW" />
		<category android:name="android.intent.category.DEFAULT" />
		<category android:name="android.intent.category.BROWSABLE" />
		<data android:scheme="againhero" android:host="resume" />
	</intent-filter>
	"""

# Keep authoring originals in Git, but never package unused copies of frame art.
func _export_file(path: String, _type: String, _features: PackedStringArray) -> void:
	if _is_authoring_file(path):
		skip()

static func _is_authoring_file(path: String) -> bool:
	if path.begins_with("res://assets/art/effects/hero_weapon_v2/"):
		return path.get_file() in ["source.png", "sprite_sheet.png", "icon.png", "manifest.json"]
	return path in [
		"res://assets/art/UI/hero_augments/weapons.png",
		"res://assets/art/UI/hero_augments/passives.png",
		"res://assets/art/zeus_reassembled_v2.zip",
	]
