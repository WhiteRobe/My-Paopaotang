"""Measure cutout regions without modifying generated source pixels."""
from pathlib import Path
import json
from PIL import Image
import numpy as np
ROOT=Path(__file__).resolve().parents[2]/'assets/art'
def bounds(mask,x0,y0,x1,y1):
    slab=mask[y0:y1,x0:x1];step=4
    small=np.zeros(((slab.shape[0]+3)//4,(slab.shape[1]+3)//4),bool)
    for y in range(small.shape[0]):
        for x in range(small.shape[1]):small[y,x]=slab[y*4:(y+1)*4,x*4:(x+1)*4].any()
    seen=set();components=[]
    for y,x in np.argwhere(small):
        start=(int(y),int(x))
        if start in seen:continue
        todo=[start];seen.add(start);component=[]
        while todo:
            v=todo.pop();component.append(v)
            for dy,dx in [(1,0),(-1,0),(0,1),(0,-1)]:
                nxt=(v[0]+dy,v[1]+dx)
                if 0<=nxt[0]<small.shape[0] and 0<=nxt[1]<small.shape[1] and small[nxt] and nxt not in seen:seen.add(nxt);todo.append(nxt)
        components.append(np.array(component))
    main=max(components,key=len)
    lo=main.min(axis=0)*4;hi=np.minimum((main.max(axis=0)+1)*4,slab.shape)
    pts=np.argwhere(slab[lo[0]:hi[0],lo[1]:hi[1]]);a=pts.min(axis=0)+lo;b=pts.max(axis=0)+lo+1
    box=[x0+int(a[1]),y0+int(a[0]),int(b[1]-a[1]),int(b[0]-a[0])]
    omissions=[]
    for c in components:
        if c is main:continue
        low=c.min(axis=0)*4;high=(c.max(axis=0)+1)*4
        if (low<b).all() and (high>a).all():omissions.append([x0+int(low[1]),y0+int(low[0]),int(high[1]-low[1]),int(high[0]-low[0])])
    return box,omissions
def index(regions):
    for path in (ROOT/'characters/rigs').glob('*-v501.png'):
        alpha=np.asarray(Image.open(path).getchannel('A'))>32
        h,w=alpha.shape
        if path.name.startswith('torsos-'):
            cells=[]
            density=alpha.sum(axis=0)
            cuts=[0]
            for i in range(1,4):
                a=int(w*(i-.3)/4);b=int(w*(i+.3)/4)
                best=np.flatnonzero(density[a:b]==density[a:b].min())
                cuts.append(a+int(min(best,key=lambda k:abs(a+k-w*i/4))))
            cuts.append(w)
            for a,b in zip(cuts,cuts[1:]):
                box,omissions=bounds(alpha,a,0,b,h)
                x,y,bw,bh=box
                head=np.argwhere(alpha[y:y+int(bh*.4),x:x+bw])
                cells.append(box+[float(head[:,1].mean()),omissions])
        else:
            # Adaptive empty seams prevent braids/capes crossing nominal cell edges.
            cells=[]
            for row in range(2):
                y0=0 if row==0 else int(h*.55);y1=int(h*.55) if row==0 else h
                density=alpha[y0:y1].sum(axis=0);cuts=[0]
                for i in (1,2):
                    a=int(w*(i-.25)/3);b=int(w*(i+.25)/3)
                    best=np.flatnonzero(density[a:b]==density[a:b].min())
                    cuts.append(a+int(min(best,key=lambda k:abs(a+k-w*i/3))))
                cuts.append(w)
                for col in range(3):
                    top=y0
                    if path.name=='robot-v501.png' and row==1 and col<2:top=int(h*.69)
                    box,omissions=bounds(alpha,cuts[col],top,cuts[col+1],y1)
                    cells.append(box+[omissions])
        regions[path.relative_to(ROOT).as_posix()]=cells
    return regions
if __name__=='__main__':
    p=ROOT/'atlas-regions.json'
    p.write_text(json.dumps(index(json.loads(p.read_text())),ensure_ascii=False,indent=2)+'\n')
