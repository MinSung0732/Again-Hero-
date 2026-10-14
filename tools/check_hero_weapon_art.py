"""Art integrity + gameplay invariance audit; not a full game/GPU test."""
from pathlib import Path
from PIL import Image
import collections,hashlib,json,re,subprocess
repo=Path(__file__).resolve().parents[1]
def catalog(text): return json.JSONDecoder().raw_decode(re.sub(r',\s*([}\]])',r'\1',text.split('const WEAPONS := ',1)[1]))[0]
current=catalog((repo/'src/data/hero_weapon_catalog.gd').read_text())
before=catalog(subprocess.check_output(['git','show','ba50ad858511f08b79f058a80bb8ff8b288f151d:src/data/hero_weapon_catalog.gd'],cwd=repo,text=True))
visual={'effect_dir','icon_source','icon_index_v2','visual_effect_unique','color'}
assert set(current)==set(before)
for id in current:
 assert {k:v for k,v in current[id].items() if k not in visual}=={k:v for k,v in before[id].items() if k not in visual},'Gameplay changed: '+id
root=repo/'assets/art/effects/hero_weapon_v2'; count=0; sequences={}; warnings=[]; black_pixels=0
for id,data in current.items():
 if not data.get('visual_effect_unique'): continue
 count+=1; folder=root/id; manifest=json.loads((folder/'manifest.json').read_text())
 assert manifest['weapon_id']==id and manifest['anchor']==[64,64] and len(manifest['animation']['frames'])==8
 sheet=Image.open(folder/'sprite_sheet.png').convert('RGBA'); assert sheet.size==(384,384)
 hashes=[]
 for index,path in enumerate(manifest['animation']['frames'],1):
  im=Image.open(folder/path); assert im.mode=='RGBA' and im.size==(128,128),(id,path)
  alpha=im.getchannel('A'); assert set(alpha.get_flattened_data()) <= {0,255}
  box=alpha.getbbox(); assert box and min(box[0],box[1])>=8 and max(box[2],box[3])<=120
  assert sheet.crop((index%3*128,index//3*128,index%3*128+128,index//3*128+128)).tobytes()==im.tobytes()
  hashes.append(hashlib.sha256(im.tobytes()).hexdigest())
  black_pixels+=sum(1 for px in im.get_flattened_data() if px==(0,0,0,255))
 assert len(set(hashes))>=4,'Insufficient animation: '+id
 sequence_hash=hashlib.sha256(''.join(hashes).encode()).hexdigest()
 assert sequence_hash not in sequences,'Reused effect: '+id
 sequences[sequence_hash]=id
 if manifest['animation']['loop']:
  a=Image.open(folder/manifest['animation']['frames'][0]).getchannel('A'); b=Image.open(folder/manifest['animation']['frames'][-1]).getchannel('A')
  aa=set(i for i,v in enumerate(a.get_flattened_data()) if v); bb=set(i for i,v in enumerate(b.get_flattened_data()) if v)
  overlap=len(aa&bb)/max(1,len(aa|bb))
  assert manifest['animation']['loop_playback']=='ping_pong'
  if overlap<0.25: warnings.append({'id':id,'raw_endpoint_iou':round(overlap,3),'resolved_by':'adjacent-frame ping-pong cycle; no last-to-first cut'})
assert count==91
atlas=Image.open(repo/'assets/art/ui/hero_augments/weapons_unique_v2.png'); assert atlas.size==(512,320)
icons={}
for id,data in current.items():
 if 'icon_index_v2' not in data: continue
 index=data['icon_index_v2']; tile=atlas.crop((index%8*64,index//8*64,index%8*64+64,index//8*64+64))
 assert tile.tobytes()==Image.open(root/id/'icon.png').tobytes()
 key=hashlib.sha256(tile.tobytes()).hexdigest(); assert key not in icons,'Duplicate new icon: '+id; icons[key]=id
assert len(icons)==40
print(json.dumps({'effects':count,'frames':count*8,'unique_icons':len(icons),'all_gameplay_fields_preserved':True,'opaque_black_pixels_retained':black_pixels,'loop_review':warnings},ensure_ascii=False))
