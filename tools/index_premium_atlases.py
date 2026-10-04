"""Read generated transparent atlases; index regions without altering their pixels."""
from pathlib import Path
from PIL import Image
import numpy as np,json
R=Path(__file__).resolve().parents[1]/'assets/premium'
result={}
for name,cols,rows in [('heroes-v1.png',8,4),('missions-v1.png',4,2)]:
 im=Image.open(R/name);alpha=np.array(im.getchannel('A'))>32;counts=alpha.sum(axis=1);cuts=[0]
 for row in range(1,rows):
  lo=int((row/rows-.08)*im.height);hi=int((row/rows+.08)*im.height);cuts.append(lo+int(np.argmin(counts[lo:hi])))
 cuts.append(im.height);regions=[]
 for row in range(rows):
  for col in range(cols):
   l=round(col*im.width/cols);r=round((col+1)*im.width/cols);t=cuts[row];b=cuts[row+1]
   sub=alpha[t:b,l:r];projection=sub.sum(axis=0);runs=[];start=None
   for x,count in enumerate(projection):
    if count>1 and start is None:start=x
    if (count<=1 or x==len(projection)-1) and start is not None:runs.append((start,x+1));start=None
   a,z=max(runs,key=lambda run:projection[run[0]:run[1]].sum());a=max(0,a-1);z=min(r-l,z+1)
   positions=np.argwhere(sub[:,a:z]);y0,x0=positions.min(axis=0);y1,x1=positions.max(axis=0)+1
   regions.append([int(l+a+x0),int(t+y0),int(x1-x0),int(y1-y0)])
 result[name]=regions;print(name,'row divisions',cuts)
(R/'atlas-regions.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
