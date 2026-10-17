extends "res://src/ui/lobby_settings_view.gd"
var account_syncs := 0
func _sync_account() -> void: account_syncs += 1
func _sync_notice() -> void: pass
