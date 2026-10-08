"""Index original integrated riding sheets; never rewrite image pixels."""
from pathlib import Path
from PIL import Image
import numpy as np
import json
ROOT=Path(__file__).resolve().parents[2]/'assets/art'
def index(regions):
 for path in sorted((ROOT/'riding').glob('*.png')):
  image=Image.open(path).convert('RGBA');mask=np.asarray(image.getchannel('A'))>48
  density=mask.sum(axis=1);cuts=[0]
  for row in range(1,4):
   ideal=round(row*image.height/4);pad=round(image.height/4*.16)
   lo=ideal-pad;hi=ideal+pad+1;values=density[lo:hi]
   candidates=np.where(values==values.min())[0]
   cuts.append(lo+int(min(candidates,key=lambda k:abs(lo+k-ideal))))
  cuts.append(image.height);cells=[]
  for row in range(4):
   top,bottom=cuts[row:row+2];ys=np.where(mask[top:bottom].sum(axis=1)>max(4,image.width*.005))[0]
   if len(ys)==0:raise ValueError(f'Empty riding row: {path} {row}')
   top=max(top,top+int(ys.min())-2);bottom=min(bottom,cuts[row]+int(ys.max())+3)
   xcuts=[0];density=mask[top:bottom].sum(axis=0)
   for col in range(1,4):
    ideal=round(col*image.width/4);pad=round(image.width/4*.16);lo=ideal-pad;hi=ideal+pad+1
    values=density[lo:hi];candidates=np.where(values==values.min())[0]
    xcuts.append(lo+int(min(candidates,key=lambda k:abs(lo+k-ideal))))
   xcuts.append(image.width)
   for col in range(4):
    left,right=xcuts[col:col+2]
    if mask[top:bottom,left:right].sum()<500:raise ValueError(f'Empty riding frame: {path} {row} {col}')
    cells.append([left,top,right-left,bottom-top])
  regions[path.relative_to(ROOT).as_posix()]=cells
 return regions
if __name__=='__main__':
 path=ROOT/'atlas-regions.json';path.write_text(json.dumps(index(json.loads(path.read_text())),ensure_ascii=False,indent=2)+'\n')
