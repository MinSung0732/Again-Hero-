"""Asset-light real save/unlock stores plus extracted UI guards and selector."""
from pathlib import Path
import subprocess
import sys
repo = Path(__file__).resolve().parents[1]
out = Path(sys.argv[1]).resolve()
subprocess.run([sys.executable,str(repo/'tools/build_hero_weapon_extension_fixture.py'),str(out),'--script','tests/mode_progression_smoke.gd'],check=True)
def method(source,name):
 start=source.index('func '+name+'(')
 end=source.find('\nfunc ',start+1)
 return source[start:end if end>=0 else len(source)]+'\n'
source=(repo/'src/ui/lobby_main_modes_view.gd').read_text()
refresh=method(source,'refresh').split('\tif lobby.hero_lobby_view')[0]
base='''extends RefCounted
const UNLOCK_DATA := preload("res://src/data/mode_unlock_catalog.gd")
const UNLOCKS := preload("res://src/systems/mode_unlock_store.gd")
const HERO_STORE := preload("res://src/systems/hero_mode_store.gd")
class Transition extends RefCounted:
	var path := ""
	var options := {}
	func change_scene(destination: String,_message: String,entry: Dictionary) -> bool:
		path = destination; options = entry; return true
class Lobby extends RefCounted:
	var transition := Transition.new()
	func get_node(_path: String) -> RefCounted: return transition
	var _stage_transition_running := false
	var refreshes := 0
	func _refresh_stage_card() -> void: refreshes += 1
var lobby := Lobby.new()
var perspective := "demon"
var difficulty := "easy"
var switching_perspective := false
var ranked := false
var stage := "stage_1"
var notice := AcceptDialog.new()
func current_stage() -> String: return stage
'''
(out/'tests/mode_progression_ui.gd').write_text(base+method(source,'choose_difficulty')+method(source,'blocks_entry')+refresh)
source=(repo/'src/ui/hero_lobby_view.gd').read_text()
start=source.index('\tvar difficulty := OptionButton.new()')
end=source.index('\tbody.add_child(difficulty)',start)+len('\tbody.add_child(difficulty)')
(out/'tests/mode_progression_selector.gd').write_text('''extends RefCounted
const STORE := preload("res://src/systems/hero_mode_store.gd")
class Lobby extends RefCounted:
	var refreshes := 0
	func _refresh_stage_card() -> void: refreshes += 1
var lobby := Lobby.new()
func build(body: VBoxContainer) -> void:
'''+source[start:end]+'\n')

# Autoload is a minimal scoped local-test contract; real save stores are retained.
(out/'tests/local_mode_stub.gd').write_text('extends Node\nconst SCOPE := preload("res://src/systems/account_save_scope.gd")\nvar active := false\nvar test_directory := ""\nfunc has_all_heroes_unlocked() -> bool: return active and SCOPE.guest_directory == test_directory\n')
project=out/'project.godot'
project.write_text(project.read_text()+'\n[autoload]\nLocalTestMode="*res://tests/local_mode_stub.gd"\n')
