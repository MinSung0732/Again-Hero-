"""Deterministically split generated sheets; retain black pixels and one scale.
Never key out a colour. Only existing alpha is binarized. One common centered
crop/scale is used across all eight frames; transparent frame canvases stay equal.
"""
from pathlib import Path
from PIL import Image
import argparse,hashlib,json,re
p=argparse.ArgumentParser(); p.add_argument('raw',type=Path); p.add_argument('--finalize',action='store_true'); args=p.parse_args()
repo=Path(__file__).resolve().parents[1]
source=(repo/'src/data/hero_weapon_catalog.gd').read_text()
data=json.JSONDecoder().raw_decode(re.sub(r',\s*([}\]])',r'\1',source.split('const WEAPONS := ',1)[1]))[0]
root=repo/'assets/art/effects/hero_weapon_v2'; report=[]
for path in sorted(args.raw.glob('*.png')):
 id=path.stem
 if id not in data: continue
 output=root/id; output.mkdir(parents=True,exist_ok=True)
 # Reviewed component-separated sources cannot safely use nominal grid crops.
 existing=output/'manifest.json'
 if existing.exists() and json.loads(existing.read_text()).get('source_file'):
  continue
 src=Image.open(path).convert('RGBA'); width,height=src.size
 alpha=src.getchannel('A')
 if alpha.getextrema()[0] != 0: raise SystemExit('Not transparent: '+id)
 cells=[]
 for index in range(9):
  x=index%3; y=index//3
  cell=src.crop((round(width*x/3),round(height*y/3),round(width*(x+1)/3),round(height*(y+1)/3)))
  source_box=cell.getchannel('A').point(lambda n:255 if n>=128 else 0).getbbox()
  if not source_box or min(source_box[:2])<=0 or source_box[2]>=cell.width or source_box[3]>=cell.height:
   raise SystemExit('Source touches cell boundary; review whole components before splitting: '+id+':'+str(index))
  # Project source explicitly requires nearest-only pixel normalization.
  cell=cell.resize((128,128),Image.Resampling.NEAREST)
  a=cell.getchannel('A').point(lambda n: 255 if n>=128 else 0)
  cell.putalpha(a)
  cell.paste((0,0,0,0),(0,0,cell.width,cell.height),a.point(lambda n: 255-n))
  if a.getbbox() is None: raise SystemExit('Empty generated cell: '+id+':'+str(index))
  cells.append(cell)
 # Same union crop for every effect, centered on the original cell anchor.
 # This removes authoring gutters without stretching individual frames.
 frames=cells[1:]
 boxes=[f.getchannel('A').getbbox() for f in frames]
 extent=max(max(abs(v-64) for v in b) for b in boxes)
 extent=min(64,max(1,extent+2))
 crop=(64-extent,64-extent,64+extent,64+extent)
 normalized=[]
 for frame in frames:
  logical=frame.crop(crop).resize((56,56),Image.Resampling.NEAREST)
  final=Image.new('RGBA',(128,128)); final.paste(logical.resize((112,112),Image.Resampling.NEAREST),(8,8)); normalized.append(final)
 iconbox=cells[0].getchannel('A').getbbox(); icon=cells[0].crop(iconbox)
 scale=min(56/icon.width,56/icon.height); icon=icon.resize((max(1,round(icon.width*scale)),max(1,round(icon.height*scale))),Image.Resampling.NEAREST)
 icon_canvas=Image.new('RGBA',(64,64)); icon_canvas.paste(icon,((64-icon.width)//2,(64-icon.height)//2))
 icon_canvas.save(output/'icon.png')
 sheet=Image.new('RGBA',(384,384)); sheet.paste(icon_canvas.resize((128,128),Image.Resampling.NEAREST),(0,0))
 frame_dir=output/'frames'; frame_dir.mkdir(exist_ok=True)
 hashes=[]
 for index,frame in enumerate(normalized,1):
  frame.save(frame_dir/f'effect_{index:02d}.png'); sheet.paste(frame,(index%3*128,index//3*128))
  hashes.append(hashlib.sha256(frame.tobytes()).hexdigest())
 sheet.save(output/'sprite_sheet.png')
 manifest={'weapon_id':id,'name':data[id]['name'],'source_size':[width,height],'source_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'sheet':'sprite_sheet.png','sheet_size':[384,384],'cell_size':[128,128],'anchor':[64,64],'alpha':'binary; existing transparency only; black foreground retained','common_source_crop':list(crop),'normalization':'one common crop and nearest scale; identical frame canvases','animation':{'fps':12,'loop_playback':'ping_pong','transient_window_seconds':0.28,'transient_playback':'normalized to visual window; no gameplay timing change','loop':data[id]['pattern'] in ['bolt','burst','orbit','poison'],'frames':[f'frames/effect_{i:02d}.png' for i in range(1,9)]},'unique_frames':len(set(hashes))}
 (output/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
 report.append({'id':id,'icon_hash':hashlib.sha256(icon_canvas.tobytes()).hexdigest(),'unique_frames':len(set(hashes)),'edge_clear':all(f.getchannel('A').getbbox()[0]>=8 and f.getchannel('A').getbbox()[1]>=8 and f.getchannel('A').getbbox()[2]<=120 and f.getchannel('A').getbbox()[3]<=120 for f in normalized)})
if args.finalize:
 extras=[k for k,v in sorted(data.items(),key=lambda pair: int(pair[1].get('icon_index_v2',999))) if 'icon_index_v2' in v]
 missing=[k for k in extras if not (root/k/'icon.png').is_file()]
 if missing: raise SystemExit('Missing extra icons '+str(missing))
 atlas=Image.new('RGBA',(512,320))
 for index,id in enumerate(extras): atlas.paste(Image.open(root/id/'icon.png'),(index%8*64,index//8*64))
 atlas_path=repo/'assets/art/UI/hero_augments/weapons_unique_v2.png'; atlas.save(atlas_path)
print(json.dumps({'processed':len(report),'entries':report},ensure_ascii=False))
