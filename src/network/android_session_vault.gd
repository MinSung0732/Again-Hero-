extends RefCounted

# AndroidKeyStore-backed AES-GCM storage. No plaintext refresh token on disk.
const PATH := "user://android_session.keystore"
const ALIAS := "again_hero_refresh_v1"

func _key(create: bool) -> Variant:
	var store = JavaClassWrapper.wrap("java.security.KeyStore").getInstance("AndroidKeyStore")
	store.load(null, null)
	if JavaClassWrapper.get_exception() != null:
		return null
	if not store.containsAlias(ALIAS):
		if not create:
			return null
		var props = JavaClassWrapper.wrap("android.security.keystore.KeyProperties")
		var spec_class = JavaClassWrapper.wrap("android.security.keystore.KeyGenParameterSpec$Builder")
		var builder = spec_class.Builder(ALIAS, props.PURPOSE_ENCRYPT | props.PURPOSE_DECRYPT)
		builder.setBlockModes(PackedStringArray(["GCM"]))
		builder.setEncryptionPaddings(PackedStringArray(["NoPadding"]))
		var generator = JavaClassWrapper.wrap("javax.crypto.KeyGenerator").getInstance("AES", "AndroidKeyStore")
		generator.init(builder.build())
		generator.generateKey()
		if JavaClassWrapper.get_exception() != null:
			return null
	var key = store.getKey(ALIAS, null)
	if JavaClassWrapper.get_exception() != null:
		return null
	return key


func save_session(id: String, refresh_token: String) -> bool:
	if id.is_empty() or refresh_token.is_empty():
		return false
	var key = _key(true)
	if key == null:
		return false
	var cipher = JavaClassWrapper.wrap("javax.crypto.Cipher").getInstance("AES/GCM/NoPadding")
	cipher.init(1, key)
	var encrypted: PackedByteArray = cipher.doFinal(JSON.stringify({"user_id": id, "refresh_token": refresh_token}).to_utf8_buffer())
	var iv: PackedByteArray = cipher.getIV()
	if JavaClassWrapper.get_exception() != null or iv.size() != 12 or encrypted.is_empty():
		return false
	var file := FileAccess.open(PATH + ".tmp", FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"version": 1, "iv": Marshalls.raw_to_base64(iv), "ciphertext": Marshalls.raw_to_base64(encrypted)}))
	file.flush()
	var result := file.get_error() == OK
	file.close()
	return result and DirAccess.rename_absolute(ProjectSettings.globalize_path(PATH + ".tmp"), ProjectSettings.globalize_path(PATH)) == OK


func read_session() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {}
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null or file.get_length() > 8192:
		return {}
	var record: Variant = JSON.parse_string(file.get_as_text())
	if not record is Dictionary or int(record.get("version", 0)) != 1:
		return {}
	var iv := Marshalls.base64_to_raw(String(record.get("iv", "")))
	var encrypted := Marshalls.base64_to_raw(String(record.get("ciphertext", "")))
	if iv.size() != 12 or encrypted.is_empty():
		return {}
	var key = _key(false)
	if key == null:
		return {}
	var cipher = JavaClassWrapper.wrap("javax.crypto.Cipher").getInstance("AES/GCM/NoPadding")
	var spec = JavaClassWrapper.wrap("javax.crypto.spec.GCMParameterSpec").GCMParameterSpec(128, iv)
	cipher.init(2, key, spec)
	var plaintext: PackedByteArray = cipher.doFinal(encrypted)
	if JavaClassWrapper.get_exception() != null:
		return {}
	var data: Variant = JSON.parse_string(plaintext.get_string_from_utf8())
	return data if data is Dictionary and not String(data.get("user_id", "")).is_empty() and not String(data.get("refresh_token", "")).is_empty() else {}


func clear_session() -> void:
	for path in [PATH, PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
