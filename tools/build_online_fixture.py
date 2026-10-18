"""Isolate original battle/network sources; only absent presentation is replaced."""
from pathlib import Path
import re,shutil,subprocess,argparse
from PIL import Image
p=argparse.ArgumentParser();p.add_argument('destination',type=Path);a=p.parse_args()
r=Path(__file__).resolve().parents[1];out=a.destination.resolve()
if out==r or r in out.parents:raise SystemExit('Use a directory outside the repository')
out.mkdir(parents=True,exist_ok=True)
for folder in ['src','tests']:shutil.copytree(r/folder,out/folder,dirs_exist_ok=True)
project=(r/'project.godot').read_text().replace('config/features=PackedStringArray("4.7")','config/features=PackedStringArray("4.5")')
project=re.sub(r'config/icon=.*','',project);project=re.sub(r'\[editor_plugins\].*?\[rendering\]','[rendering]',project,flags=re.S)
project=project.replace('config/name="용사, 또 너야?"','config/name="AgainHero online isolated fixture"\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="AgainHeroOnlineFixture"')
(out/'project.godot').write_text(project)
m=out/'src/data/monster_catalog.gd';s=m.read_text();keep={'Slime','Spider','Orc','BombRat','SkeletonArcher'}
s=re.sub(r'preload\("res://src/monsters/([^"/]+)\.tscn"\)',lambda x:x[0] if x[1] in keep else 'null',s);m.write_text(s)
queue=[str(x.relative_to(out)) for x in (out/'src').rglob('*.gd')]+[str(x.relative_to(out)) for x in (out/'src').rglob('*.tscn')]
seen=set();placeholders=[]
for folder,prefixes in {
 'assets/art/heroes/stage1_mage/frames':['idle','walk','atk','hit','dead'],
 'assets/art/monsters/slime/frames':['idle','move','attack','hit','death'],
 'assets/art/monsters/spider/frames':['idle','move','attack','hit','death'],
 'assets/art/monsters/orc/frames':['idle','move','attack','hit','death'],
 'assets/art/monsters/skelletonarcher/frames':['idle','walk','atk','hit','dead'],
 'assets/art/monsters/bombrat/frames':['frame'],
 'assets/art/monsters/bombrat/frames/effect':['frame'],
}.items():
 for prefix in prefixes:queue += [folder+'/'+prefix+'_%02d.png'%i for i in range(1,25)]
for relative in ['src/data/contextual_audio_catalog.gd','src/data/game_audio_catalog.gd']:
 text=(r/relative).read_text();root=re.search(r'const ROOT := "res://([^" ]+)"',text)[1]
 queue += [root+x for x in re.findall(r'"([^"/]+\.wav)"',text)]
queue+=['assets/art/UI/newUI_frame/frame_06.png']
queue+=['assets/art/monsters/Scorpion/frames/effect1/effect_%02d.png'%i for i in range(1,9)]
queue+=['assets/art/heroes/stage1_mage/frames/effect_01/frame_%02d.png'%i for i in range(1,7)]
while queue:
 path=queue.pop()
 if path in seen:continue
 seen.add(path);dest=out/path;source=r/path;dest.parent.mkdir(parents=True,exist_ok=True)
 if not dest.exists():
  if source.exists():shutil.copyfile(source,dest)
  elif dest.suffix.lower() in ['.png','.webp','.jpg']:
   Image.new('RGBA',(64,64),(0,0,0,0)).save(dest);placeholders.append(path)
  elif dest.suffix.lower()=='.tres' and '/clean_frames/' in path:
   dest.write_text('[gd_resource type="StyleBoxTexture" format=3]\n[resource]\n');placeholders.append(path)
  elif dest.suffix.lower() in ['.ttf','.otf']:
   shutil.copyfile(next(Path('/usr/share/fonts').rglob('*.ttf')),dest);placeholders.append(path)
  elif dest.suffix.lower()=='.svg':
   dest.write_text('<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64"/>');placeholders.append(path)
  elif dest.suffix.lower() in ['.wav','.ogg','.mp3']:
   subprocess.run(['ffmpeg','-loglevel','error','-y','-f','lavfi','-i','anullsrc=r=44100:cl=mono','-t','0.1',str(dest)],check=True);placeholders.append(path)
  else:raise SystemExit('Missing nonvisual dependency: '+path)
 if dest.suffix in ['.gd','.tscn','.tres']:
  content=dest.read_text();queue+=re.findall(r'path="res://([^"]+)"',content)+re.findall(r'preload\("res://([^\"]+)"\)',content)
previous=(out/'omitted_art.txt').read_text().splitlines() if (out/'omitted_art.txt').exists() else []
(out/'omitted_art.txt').write_text('\n'.join(sorted(set(previous+placeholders))))
print('Resource closure:',len(seen),'placeholder presentation:',len(placeholders))
