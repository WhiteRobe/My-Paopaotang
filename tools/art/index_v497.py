"""Index v4.9.7 art without changing source pixels."""
from pathlib import Path
from PIL import Image
import numpy as np
import json
ROOT=Path(__file__).resolve().parents[2]/'assets/art'
def index(regions):
 name='characters/walk/side-walk-v497.png'
 dst=ROOT/name
 im=Image.open(dst);a=np.asarray(im.getchannel('A'))>32
 ys=[0,155,338,498,660,815,989,1121,1254];xs=[0,154,287,417,548,677,807,942,1073,1254];out=[]
 for row in range(8):
  entries=[]
  for col in range(9):
   x0,x1=xs[col:col+2];y0,y1=ys[row:row+2]
   mask=a[y0:y1,x0:x1];small=np.zeros(((mask.shape[0]+3)//4,(mask.shape[1]+3)//4),bool)
   for yy in range(small.shape[0]):
    for xx in range(small.shape[1]):small[yy,xx]=mask[yy*4:(yy+1)*4,xx*4:(xx+1)*4].any()
   seen=set();components=[]
   for yy,xx in np.argwhere(small):
    start=(int(yy),int(xx))
    if start in seen:continue
    todo=[start];seen.add(start);component=[]
    while todo:
     v=todo.pop();component.append(v)
     for dy,dx in [(1,0),(-1,0),(0,1),(0,-1),(1,1),(1,-1),(-1,1),(-1,-1)]:
      nxt=(v[0]+dy,v[1]+dx)
      if 0<=nxt[0]<small.shape[0] and 0<=nxt[1]<small.shape[1] and small[nxt] and nxt not in seen:seen.add(nxt);todo.append(nxt)
    components.append(component)
   main=max(components,key=len);main_points=np.array(main);lo=main_points.min(axis=0)*4;hi=np.minimum((main_points.max(axis=0)+1)*4,mask.shape)
   omissions=[]
   for part in components:
    if part is main:continue
    points=np.array(part);begin=points.min(axis=0)*4;end=np.minimum((points.max(axis=0)+1)*4,mask.shape)
    omissions.append([x0+int(begin[1]),y0+int(begin[0]),int(end[1]-begin[1]),int(end[0]-begin[0])])
   x=x0+int(lo[1]);y=y0+int(lo[0]);w=int(hi[1]-lo[1]);h=int(hi[0]-lo[0]);head=np.argwhere(a[y:y+int(h*.38),x:x+w]);pivot=float(head[:,1].mean());entries.append([x,y,w,h,omissions[:8],pivot])
  baseline=[max(v[2] for v in entries),max(v[3] for v in entries)]
  for v in entries:v.append(baseline)
  out+=entries
 regions[name]=out
 for filename,cols,rows in [('maps/decorations/shelters-front-v497.png',3,1),('maps/blocks/blocks-depth-v463.png',4,2)]:
  image=Image.open(ROOT/filename);cells=[]
  for row in range(rows):
   for col in range(cols):
    x0=col*image.width//cols;y0=row*image.height//rows;x1=(col+1)*image.width//cols;y1=(row+1)*image.height//rows
    l,t,r,b=image.getchannel('A').crop((x0,y0,x1,y1)).point(lambda a:255 if a>32 else 0).getbbox()
    cells.append([x0+l,y0+t,r-l,b-t])
  regions[filename]=cells
 return regions
if __name__=='__main__':
 path=ROOT/'atlas-regions.json';path.write_text(json.dumps(index(json.loads(path.read_text())),ensure_ascii=False,indent=2)+'\n')
