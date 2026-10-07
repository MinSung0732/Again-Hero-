extends "res://src/ui/zeus_rig_cutscene_view.gd"

# Only this development wrapper loops and accepts Space; production uses the outer player.
var paused := false
var _last_tick := 0

func _ready() -> void:
	super._ready()
	_last_tick = Time.get_ticks_usec()

func _process(_delta: float) -> void:
	var tick := Time.get_ticks_usec()
	if not paused:
		set_time(fmod(elapsed+float(tick-_last_tick)/1000000.0,5.7))
	_last_tick = tick

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		paused = not paused
