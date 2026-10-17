"""Production profile/name/prologue code; isolate OS/auth and absent artwork."""
from pathlib import Path
import argparse,re,shutil
from PIL import Image
p=argparse.ArgumentParser();p.add_argument('destination',type=Path);a=p.parse_args()
repo=Path(__file__).resolve().parents[1];out=a.destination.resolve()
if out==repo or repo in out.parents: raise SystemExit('Use a directory outside the repository')
out.mkdir(parents=True,exist_ok=True)
queue=['src/ui/lobby_settings_view.gd','tests/profile_defaults_smoke.gd','tests/profile_gender_smoke.gd','tests/nickname_input_smoke.gd','tests/nickname_rpc_retry_smoke.gd','tests/player_prologue_keyboard_smoke.gd'];seen=set()
while queue:
 path=queue.pop()
 if path in seen: continue
 seen.add(path);source=repo/path;dest=out/path;dest.parent.mkdir(parents=True,exist_ok=True)
 if source.exists(): shutil.copy2(source,dest)
 elif dest.suffix=='.png': Image.new('RGBA',(512,512),(60,40,80,255)).save(dest)
 elif dest.suffix=='.tres': dest.write_text('[gd_resource type="StyleBoxFlat" format=3]\n[resource]\n')
 else: raise SystemExit('Missing dependency: '+path)
 if path=='src/data/monster_catalog.gd':
  dest.write_text(re.sub(r'preload\("res://src/monsters/[^"\n]+\.tscn"\)','null',dest.read_text()))
 if path=='src/data/demon_appearance_catalog.gd':
  queue.extend(re.findall(r'"res://([^"\n]+\.png)"',dest.read_text()))
 if dest.suffix in ['.gd','.tres']:
  queue.extend(re.findall(r'preload\("res://([^"\n]+)"\)',dest.read_text()))
# Dynamic frame load used by real pixel-panel skin.
path=out/'assets/art/UI/newUI_frame/frame_06.png';path.parent.mkdir(parents=True,exist_ok=True)
Image.new('RGBA',(512,512),(80,50,100,255)).save(path)
def write(path,text):
 dest=out/path;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_text(text)
write('fixture_mode.gd','''extends Node
var active := false
var tutorial_preview := false
var test_directory := "user://localtest"
func is_tutorial_preview() -> bool: return tutorial_preview
func has_all_monsters_unlocked() -> bool: return false
func is_practice_allowed() -> bool: return false
''')
write('fixture_cloud.gd','extends Node\nvar busy := false\nvar conflict := false\nfunc stop(): pass\n')
write('fixture_gateway.gd','extends Node\nvar remember_session_enabled := false\nvar user_id := ""\nvar access_token := "fixture"\n')
write('warmup.gd','extends Node\nfunc get_texture(_path: String) -> Texture2D: return null\n')
write('project.godot','''config_version=5
[application]
config/name="Nickname isolated fixture"
config/use_custom_user_dir=true
config/custom_user_dir_name="AgainHeroNicknameFixture"
[autoload]
LocalTestMode="*res://fixture_mode.gd"
CloudStore="*res://fixture_cloud.gd"
LoginGateway="*res://fixture_gateway.gd"
PresentationWarmup="*res://warmup.gd"
[display]
window/size/viewport_width=1080
window/size/viewport_height=1920
[rendering]
renderer/rendering_method="gl_compatibility"
''')
print('Actual profile/save/prologue/entry/skin logic; auth and missing art fixtures:',len(seen))
