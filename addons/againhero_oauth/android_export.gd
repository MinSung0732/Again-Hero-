@tool
extends EditorExportPlugin

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
