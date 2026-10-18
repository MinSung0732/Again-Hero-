extends "res://src/hero_mode/hero_mode.gd"
## Real modal handlers, with startup/network/navigation intentionally omitted.
func _ready() -> void:
	entry_ready = true
	pad = MOVE_PAD.new(); add_child(pad)
	inventory_dim = ColorRect.new(); add_child(inventory_dim); inventory_dim.hide()
	overlay = PanelContainer.new(); add_child(overlay)
	overlay_rows = VBoxContainer.new(); overlay.add_child(overlay_rows)
	settings_panel = Control.new(); add_child(settings_panel); settings_panel.hide()
func _process(_delta: float) -> void: pass
func _sync_settings() -> void: pass
