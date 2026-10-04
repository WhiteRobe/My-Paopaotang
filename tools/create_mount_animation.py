"""Original four-direction pixel mounts, with planted feet and seated saddles."""
from pathlib import Path
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[1]/'assets'
INK='#182840'
atlas=Image.new('RGBA',(144,672))
for kind in range(3):
 for direction in range(4):
  for frame in range(4):
   im=Image.new('RGBA',(48,42));d=ImageDraw.Draw(im)
   gait=[0,-2,0,2][frame];side=direction>=2
   cream=['#ffe39a','#a4dba5','#f7d7ec'][kind];shade=['#dda95c','#579680','#bb8eaf'][kind]
   d.ellipse((8,33,40,39),fill='#223f50')
   feet=[(12,31+gait,18,35+gait),(31,31-gait,37,35-gait)]
   for box in feet:d.rectangle(box,fill=INK);d.rectangle((box[0]+1,box[1],box[2]-1,box[3]-1),fill=shade)
   d.ellipse((7,16,40,34),fill=INK);d.ellipse((9,17,38,32),fill=cream)
   d.arc((11,18,37,31),5,170,fill=shade,width=2)
   hx=34 if side else 24
   if kind==1:
    d.ellipse((10,12,37,31),fill=INK);d.ellipse((12,13,35,28),fill='#6bba94')
    d.polygon([(24,14),(30,18),(30,25),(24,28),(18,25),(18,18)],fill='#a0d9a0',outline='#417e72')
    for a,b in [((18,18),(13,16)),((30,18),(35,16)),((18,25),(13,28)),((30,25),(35,28))]:d.line((*a,*b),fill='#417e72',width=2)
    hy=22 if side else (31 if direction==0 else 10)
    d.ellipse((hx-7,hy-6,hx+8,hy+7),fill=INK);d.ellipse((hx-6,hy-5,hx+7,hy+6),fill=cream)
   else:
    hy=17 if side else (24 if direction==0 else 11)
    d.ellipse((hx-8,hy-9,hx+9,hy+8),fill=INK);d.ellipse((hx-7,hy-8,hx+8,hy+6),fill=cream)
    if kind==0:
     if side:d.rectangle((hx+5,hy,hx+12,hy+4),fill='#df9b58');d.rectangle((hx+6,hy,hx+11,hy+1),fill='#ffd78b')
     elif direction==0:d.rectangle((hx-5,hy+3,hx+5,hy+7),fill='#df9b58');d.line((hx-4,hy+3,hx+4,hy+3),fill='#ffdc97')
     d.ellipse((12,20,24,28),fill='#efd081');d.arc((12,20,24,28),10,155,fill='#b98a50',width=1)
    else:
     for ex in [hx-5,hx+4]:
      d.rectangle((ex-2,hy-20,ex+2,hy-6),fill=INK);d.rectangle((ex-1,hy-19,ex+1,hy-7),fill=cream);d.line((ex,hy-17,ex,hy-10),fill='#e6a9ca',width=2)
     d.ellipse((7,18,15,26),fill='#fff2ef')
     if side:d.rectangle((hx+6,hy+2,hx+8,hy+3),fill='#d58dac')
   if direction!=1:
    for ex in ([hx+3] if side else [hx-4,hx+4]):
     d.rectangle((ex,hy-3,ex+2,hy-1),fill=INK);d.point((ex,hy-3),fill='#fff5d5')
   else:d.arc((hx-5,hy-5,hx+5,hy+5),190,345,fill=shade,width=2)
   # A visible saddle gives the rider a stable seated anchor.
   d.rectangle((18,15,29,19),fill=INK);d.rectangle((19,15,28,17),fill='#bd7798');d.line((20,15,27,15),fill='#f5c3d2')
   if direction==2:im=im.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
   atlas.alpha_composite(im,(kind*48,(direction*4+frame)*42))
atlas.save(ROOT/'mount-animation.png')
print('Created three mounts × four directions × four frames at 48×42.')
