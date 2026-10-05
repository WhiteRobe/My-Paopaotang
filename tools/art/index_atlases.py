"""Index HD generated sprite sheets without editing or resampling their pixels."""
from pathlib import Path
from PIL import Image
import numpy as np,json
R=Path(__file__).resolve().parents[2]/'assets/art'
specs={'habitat-flight-v478.png':(8,4),'site-details-v478.png':(4,4),'bat-flight-v478.png':(8,2),'monster-skills-v474.png':(8,4),'water-vines-v473.png':(4,4),'mechanisms-v472.png':(4,4),'pressure-core-v464.png':(1,1),'blocks-depth-v463.png':(4,2),'hero-trapped-v5.png':(8,4),'hero-death-v5.png':(8,3),'bubble-break-v5.png':(6,2),'remote-hd.png':(1,1),'hero-actions-hd.png':(8,7),'items-hd.png':(7,4),'creatures-hd.png':(4,3),'missions-hd.png':(4,2),'bubbles-hd.png':(4,2),'mounts-hd.png':(3,4),'impacts-hd.png':(6,4),'fauna-hd.png':(4,3)}
for p in R.rglob('monster-*-anim.png'):specs[p.name]=(6,6)
for p in R.rglob('theme-*.png'):specs[p.name]=(4,4)
for p in R.rglob('playfield-*.png'):specs[p.name]=(4,2)
for p in R.rglob('heroes-*.png'):specs[p.name]=(8,1)
specs['heroes-front-hd.png']=(4,2)
for p in R.rglob('walk-*.png'):specs[p.name]=(12,4)
regions={};report={}
for name,(cols,rows) in specs.items():
 p=next(R.rglob(name),None)
 if p is None:raise FileNotFoundError(f'Missing atlas: {name}')
 im=Image.open(p).convert('RGBA');mask=np.asarray(im.getchannel('A'))>24
 cuts=[0]
 counts=mask.sum(axis=1)
 for row in range(1,rows):
  ideal=round(row*im.height/rows);pad=round(im.height/rows*.12)
  low=max(0,ideal-pad);high=min(im.height,ideal+pad+1)
  scores=counts[low:high];best=np.where(scores==scores.min())[0]
  cuts.append(low+int(min(best,key=lambda k:abs(low+k-ideal))))
 cuts.append(im.height)
 if name=="hero-death-v5.png":cuts=[0,295,544,im.height]
 raw=[]
 for row in range(rows):
  xcuts=[round(i*im.width/cols) for i in range(cols+1)]
  if not name.startswith(('theme-','playfield-','walk-')) and name!='blocks-depth-v463.png':
   density=mask[cuts[row]:cuts[row+1]].sum(axis=0)
   for col in range(1,cols):
    ideal=xcuts[col];pad=round(im.width/cols*.18);lo=max(xcuts[col-1]+1,ideal-pad);hi=min(im.width,ideal+pad+1)
    score=density[lo:hi];best=np.where(score==score.min())[0];xcuts[col]=lo+int(min(best,key=lambda k:abs(lo+k-ideal)))
  for col in range(cols):
   x0=xcuts[col];x1=xcuts[col+1];y0=cuts[row];y1=cuts[row+1]
   if name.startswith(('hero-','monster-')) or name=='mounts-hd.png':
    local_counts=mask[:,x0:x1].sum(axis=1)
    for edge in [0,1]:
     boundary=y0 if edge==0 else y1
     if boundary in [0,im.height]:continue
     pad=max(2,round(im.height/rows*.10));low=max(0,boundary-pad);high=min(im.height,boundary+pad+1)
     candidates=local_counts[low:high];best=np.where(candidates==candidates.min())[0]
     boundary=low+int(min(best,key=lambda k:abs(low+k-boundary)))
     if edge==0:y0=boundary
     else:y1=boundary
   cell_mask=mask[y0:y1,x0:x1]
   omissions=[]
   if name in ['items-hd.png','missions-hd.png','mounts-hd.png','creatures-hd.png','fauna-hd.png'] or name.startswith(('heroes-','hero-','monster-')):
    # Ignore disconnected fragments belonging to a neighbouring atlas cell.
    step=2 if name=='hero-actions-hd.png' else 4 if name=='mounts-hd.png' else 8;small=np.zeros(((cell_mask.shape[0]+step-1)//step,(cell_mask.shape[1]+step-1)//step),bool)
    for yy in range(small.shape[0]):
     for xx in range(small.shape[1]):small[yy,xx]=cell_mask[yy*step:(yy+1)*step,xx*step:(xx+1)*step].any()
    seen=set();components=[]
    for yy,xx in np.argwhere(small):
     start=(int(yy),int(xx))
     if start in seen:continue
     todo=[start];seen.add(start);component=[]
     while todo:
      v=todo.pop();component.append(v)
      for dy,dx in [(1,0),(-1,0),(0,1),(0,-1)]:
       nxt=(v[0]+dy,v[1]+dx)
       if 0<=nxt[0]<small.shape[0] and 0<=nxt[1]<small.shape[1] and small[nxt] and nxt not in seen:seen.add(nxt);todo.append(nxt)
     components.append(component)
    if components:
     main_component=max(components,key=len)
     main=np.array(main_component);lo=main.min(axis=0)*step;hi=(main.max(axis=0)+1)*step
     if name in ['mounts-hd.png','items-hd.png','missions-hd.png','creatures-hd.png','fauna-hd.png','hero-actions-hd.png']:
      for component in components:
       if component is main_component or len(component)>len(main_component)*.12:continue
       other=np.array(component);a0,b0=other.min(axis=0)*step;a1,b1=(other.max(axis=0)+1)*step
       near_edge=min(b0,a0,cell_mask.shape[1]-b1,cell_mask.shape[0]-a1)<=max(3,step*3)
       if near_edge and not (name=='hero-actions-hd.png' and col==7):omissions.append([int(x0+b0),int(y0+a0),int(b1-b0),int(a1-a0)])
     retained=np.zeros_like(cell_mask);retained[lo[0]:hi[0],lo[1]:hi[1]]=cell_mask[lo[0]:hi[0],lo[1]:hi[1]];cell_mask=retained
   points=np.argwhere(cell_mask)
   if points.size:
    a,b=points.min(axis=0);c,d=points.max(axis=0)+1
    rectangle=[int(x0+b),int(y0+a),int(d-b),int(c-a)]
    overlaps=[o for o in omissions if o[0]<rectangle[0]+rectangle[2] and o[0]+o[2]>rectangle[0] and o[1]<rectangle[1]+rectangle[3] and o[1]+o[3]>rectangle[1]]
    if overlaps:rectangle.append(overlaps)
    raw.append(rectangle)
   else:raw.append([x0,y0,x1-x0,y1-y0])
 # Detect the generated walk columns rather than assuming an exact layout.
 if name.startswith('walk-'):
  frames=[];row_counts=[]
  for row in range(rows):
   slab=mask[cuts[row]:cuts[row+1]]
   ids=np.flatnonzero(slab.sum(axis=0)>2)
   blocks=[v for v in np.split(ids,np.where(np.diff(ids)>10)[0]+1) if len(v)>25]
   row_counts.append(len(blocks))
   for block in blocks:
    x0=int(block[0]);x1=int(block[-1])+1
    points=np.argwhere(slab[:,x0:x1]);a,b=points.min(axis=0);c,d=points.max(axis=0)+1
    frames.append([x0,int(cuts[row]+a),x1-x0,int(c-a)])
  if len(set(row_counts))!=1 or row_counts[0]<12:raise ValueError(f'{name}: unexpected animation layout {row_counts}')
  cols=row_counts[0];raw=frames
  # Keep tight row-local source rectangles. Expanding to a shared height
  # sampled feet from the preceding row; shared scale belongs in the renderer.
 if name=='items-hd.png':
  order=[9,1,2,4,5,6,3,7,8,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,0]
  out=[None]*28
  for slot,kind in enumerate(order):out[kind]=raw[slot]
  raw=out
 if name=="monster-02-anim.png":raw[6:12],raw[12:18]=raw[12:18],raw[6:12]
 regions[p.relative_to(R).as_posix()]=raw
 report[name]={'size':list(im.size),'cells':len(raw),'minimum_cell':min(min(r[2:4]) for r in raw),'row_cuts':cuts,'alpha_fraction':round(float((np.asarray(im.getchannel('A'))==0).mean()),4)}
(R/'atlas-regions.json').write_text(json.dumps(regions,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(report,ensure_ascii=False,indent=2))
