"""Index the original racing terrain and checkpoint atlases without changing pixels."""
from pathlib import Path
from PIL import Image
import json
ROOT=Path(__file__).resolve().parents[2]/'assets/art'
def index(regions):
 # Preserve the curated vehicle and airship cells during a full atlas rebuild.
 regions['maps/racing/race-v490.png']=[[46,58,274,269],[411,51,270,268],[1104,138,326,183],[739,138,325,183],[22,383,468,318],[517,374,248,331],[778,489,274,208],[1093,387,329,311],[40,738,287,276],[429,750,251,248],[779,737,262,274],[1108,734,320,281]]
 for filename,cols,rows in [('terrain-v493.png',3,3),('checkpoints-v493.png',2,2)]:
  image=Image.open(ROOT/'maps/racing'/filename).convert('RGBA');cells=[]
  for row in range(rows):
   for col in range(cols):
    x0=round(col*image.width/cols);y0=([0,400,1024][row] if filename.startswith("checkpoints") else round(row*image.height/rows))
    x1=round((col+1)*image.width/cols);y1=([0,400,1024][row+1] if filename.startswith("checkpoints") else round((row+1)*image.height/rows))
    if filename.startswith('checkpoints'):
     bounds=image.getchannel('A').crop((x0,y0,x1,y1)).point(lambda a:255 if a>48 else 0).getbbox()
     if bounds is None:raise ValueError('Empty checkpoint cell')
     a,b,c,d=bounds;x0,y0,x1,y1=x0+a,y0+b,x0+c,y0+d
    cells.append([x0,y0,x1-x0,y1-y0])
  regions['maps/racing/'+filename]=cells
 return regions
if __name__=='__main__':
 path=ROOT/'atlas-regions.json';path.write_text(json.dumps(index(json.loads(path.read_text())),ensure_ascii=False,indent=2)+'\n')
