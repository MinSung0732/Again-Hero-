extends Node

const ANDROID_VAULT := preload("res://src/network/android_session_vault.gd")
var _android: RefCounted

func _android_store() -> RefCounted:
	if _android == null:
		_android = ANDROID_VAULT.new()
	return _android


# Windows DPAPI CurrentUser: no plaintext token file, hard-coded key, or token
# in command-line arguments. The static helper exchanges JSON over pipes only.
var PATH := "user://windows_session.dpapi"
const SCRIPT := """
$ErrorActionPreference='Stop'
try {
  [Console]::InputEncoding=[Text.UTF8Encoding]::new($false)
  [Console]::OutputEncoding=[Text.UTF8Encoding]::new($false)
  Add-Type -AssemblyName System.Security
  $inputData=[Console]::In.ReadLine() | ConvertFrom-Json
  $scope=[System.Security.Cryptography.DataProtectionScope]::CurrentUser
  if($inputData.action -eq 'save') {
    $bytes=[Text.Encoding]::UTF8.GetBytes($inputData.data)
    $encrypted=[Security.Cryptography.ProtectedData]::Protect($bytes,$null,$scope)
    $temp=$inputData.path+'.tmp'
    [IO.File]::WriteAllBytes($temp,$encrypted)
    if([IO.File]::Exists($inputData.path)) { [IO.File]::Replace($temp,$inputData.path,[NullString]::Value) }
    else { [IO.File]::Move($temp,$inputData.path) }
    [Console]::Out.WriteLine('{"ok":true}')
  } elseif($inputData.action -eq 'read') {
    $bytes=[Security.Cryptography.ProtectedData]::Unprotect([IO.File]::ReadAllBytes($inputData.path),$null,$scope)
    @{ok=$true;data=[Text.Encoding]::UTF8.GetString($bytes)} | ConvertTo-Json -Compress | ForEach-Object { [Console]::Out.WriteLine($_) }
  } else { [Console]::Out.WriteLine('{"ok":false}') }
} catch { @{ok=$false;error=$_.Exception.GetType().FullName;line=$_.InvocationInfo.ScriptLineNumber} | ConvertTo-Json -Compress | ForEach-Object { [Console]::Out.WriteLine($_) } }
"""
var _busy := false
var diagnostic := ""

func read_session() -> Dictionary:
	if OS.get_name() == "Android":
		return _android_store().read_session()
	if not FileAccess.file_exists(PATH):
		return {}
	var result := await _run("read", "")
	var data: Variant = JSON.parse_string(String(result.get("data", "")))
	return data if data is Dictionary else {}

func save_session(id: String, refresh_token: String) -> bool:
	if OS.get_name() == "Android":
		return _android_store().save_session(id, refresh_token)
	var result := await _run("save", JSON.stringify({"user_id": id, "refresh_token": refresh_token}))
	return bool(result.get("ok", false))

func clear_session() -> void:
	if OS.get_name() == "Android":
		_android_store().clear_session()
		return
	while _busy:
		await get_tree().process_frame
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(PATH)

func _run(action: String, data: String) -> Dictionary:
	if OS.get_name() != "Windows":
		return {}
	while _busy:
		await get_tree().process_frame
	_busy = true
	var utf16 := PackedByteArray()
	for code in SCRIPT.to_utf8_buffer():
		utf16.append(code)
		utf16.append(0)
	var process := OS.execute_with_pipe("powershell.exe", PackedStringArray(["-NoProfile", "-NonInteractive", "-WindowStyle", "Hidden", "-EncodedCommand", Marshalls.raw_to_base64(utf16)]), false)
	if process.is_empty():
		_busy = false
		return {}
	var pipe: FileAccess = process.stdio
	pipe.store_line(JSON.stringify({"action": action, "path": ProjectSettings.globalize_path(PATH), "data": data}))
	pipe.flush()
	var output := ""
	var deadline := Time.get_ticks_msec() + 15000
	while Time.get_ticks_msec() < deadline:
		output += pipe.get_buffer(4096).get_string_from_utf8()
		if output.contains("\n"):
			break
		if not OS.is_process_running(int(process.pid)):
			output += pipe.get_buffer(4096).get_string_from_utf8()
			break
		await get_tree().process_frame
	if OS.is_process_running(int(process.pid)) and Time.get_ticks_msec() >= deadline:
		OS.kill(int(process.pid))
	pipe.close()
	(process.stderr as FileAccess).close()
	_busy = false
	var result: Variant = JSON.parse_string(output.strip_edges())
	diagnostic = str(result.get("error", "no error")) + " line " + str(result.get("line", 0)) if result is Dictionary else "no valid helper response"
	return result if result is Dictionary else {}
