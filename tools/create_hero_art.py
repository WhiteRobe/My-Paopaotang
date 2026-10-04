"""Original 48x56 pixel actors: 8 heroes, 4 directions, 24 poses per direction."""
from pathlib import Path
from PIL import Image, ImageDraw
import math
R=Path(__file__).resolve().parents[1]/'assets'
W,H=48,56
INK='#23334d'; CREAM='#fff3d7'
PAL=[('#65c5ed','#2979b8','#d6f1f3'),('#ef9ab9','#b75687','#ffe0e4'),('#8acfa0','#397b67','#e0eac0'),('#ecc16d','#a4704d','#fff0c9'),('#cedee8','#6f9bc0','#f6fcf3'),('#b5a0de','#6d619f','#ecdcff'),('#9ecbd1','#427c94','#e2f1e4'),('#efa37b','#b76166','#ffdc9b')]
def actor(n,direction,pose):
 im=Image.new('RGBA',(W,H));q=ImageDraw.Draw(im);base,dark,light=PAL[n]
 state=pose//4 if pose<4 else (1 if pose<12 else (2 if pose<16 else (3 if pose<20 else 4)))
 frame=pose if pose<4 else pose-(4 if state==1 else 12 if state==2 else 16 if state==3 else 20)
 side=direction in [2,3];back=direction==1
 walk=math.sin(frame*math.tau/8) if state==1 else 0
 hurt=state==2;trapped=state==3;casting=state==4
 bx=round((-3,-2,1,0)[frame]) if hurt else (round(math.sin(frame*math.pi/2)*2) if trapped else 0)
 by=(0 if state!=0 else (0,0,-1,0)[frame])+(-2 if state==1 and frame in [1,2,5,6] else 0)+(1 if casting and frame==0 else 0)
 def box(b,c):q.rectangle(tuple(v+(bx if i%2==0 else by) for i,v in enumerate(b)),fill=c)
 def oval(b,c,outline=None,width=1):q.ellipse(tuple(v+(bx if i%2==0 else by) for i,v in enumerate(b)),fill=c,outline=outline,width=width)
 def poly(points,c,outline=None):q.polygon([(x+bx,y+by) for x,y in points],fill=c,outline=outline)
 def line(points,c,width=1):q.line([(x+bx,y+by) for x,y in points],fill=c,width=width)
 # Boots have separate contact/lift phases and oppositely swinging arms.
 left=round(walk*3);right=-left
 if side:left=round(walk*4);right=-left
 for x,lift in [(16,left),(29,right)]:
  box((x,43-lift,x+6,49-lift),INK);box((x+1,43-lift,x+5,46-lift),dark);box((x-1,48-lift,x+7,51-lift),INK);box((x,48-lift,x+6,49-lift),light);box((x,50-lift,x+6,50-lift),'#677282')
 # Layered outfit, seams, cuffs and personal costume instead of flat color fill.
 poly([(16,31),(31,31),(35,44),(29,46),(16,46),(13,43)],INK)
 poly([(17,32),(30,32),(33,42),(28,44),(17,44),(15,41)],dark)
 box((17,33,28,41),base);box((18,33,21,41),light);box((16,43,31,44),light)
 if n==0:poly([(18,32),(29,32),(25,38),(22,38)],CREAM);poly([(22,35),(26,35),(24,41)],'#ebbe72');box((27,39,30,40),'#e3d5a1')
 if n==1:poly([(17,33),(31,33),(35,43),(13,43)],base);box((15,42,33,44),'#ffccda');oval((23,34,26,37),'#fff2c6');line([(22,38),(27,40)],light)
 if n==2:box((16,33,30,37),'#d7be79');box((18,39,29,44),'#48746f');box((23,37,25,42),'#e6d7a0');box((18,40,20,42),base)
 if n==3:poly([(16,32),(31,32),(28,36),(20,36)],'#ece3c3');line([(25,36),(29,42)],'#d78767',3);box((16,41,32,42),'#6c6860');box((23,40,26,43),'#f4cd7e')
 if n==4:box((16,33,31,36),'#8fbecb');box((18,34,20,36),'#e7f6ed');box((24,34,26,36),'#e7f6ed');box((22,37,25,39),'#d1edf0')
 if n==5:poly([(17,32),(31,32),(35,46),(13,46)],dark);poly([(20,34),(25,34),(28,45),(17,45)],base);line([(27,33),(31,45)],'#d5be80',2);box((22,40,24,42),'#fff1ae')
 if n==6:box((15,32,32,43),dark);box((18,33,29,41),base);box((21,35,27,38),'#b7f4df');box((23,34,25,39),'#eefedb');box((15,43,32,44),'#536479');box((18,40,20,41),'#e8c78b')
 if n==7:poly([(16,33),(30,33),(32,42),(28,46),(17,45),(13,41)],base);poly([(20,34),(25,34),(28,43),(22,46),(17,41)],light);line([(28,36),(30,40)],'#f2c287')
 # Arm poses: swing, protect face on hit, reach toward water when trapped, placement gesture.
 for x,swing in [(11,-left),(33,-right)]:
  arm_y=34+swing
  if hurt:arm_y=28+(2 if x==33 else 0)
  if trapped:arm_y=27+frame%2*3
  if casting and x==33:arm_y=29-frame%2*2
  box((x,arm_y,x+5,arm_y+9),INK);box((x+1,arm_y+1,x+4,arm_y+5),base);box((x+1,arm_y+6,x+4,arm_y+8),'#f0ccae' if n in [0,5] else light);box((x+1,arm_y+3,x+2,arm_y+4),light)
 # Personal head silhouette and direction-specific details.
 if n==1:
  for x in [13,29]:box((x,3,x+6,16),INK);box((x+1,4,x+5,14),base);box((x+2,5,x+4,12),'#ffe4dd')
 elif n==2:
  oval((9,7,22,20),dark);oval((26,7,39,20),dark);oval((12,8,19,15),light);oval((29,8,36,15),light)
 elif n in [3,4]:
  if n==3:
   poly([(10,16),(11,3),(21,11)],INK);poly([(12,13),(13,6),(19,11)],base);poly([(28,11),(36,3),(38,16)],INK);poly([(31,12),(35,7),(36,13)],'#e7a78a')
  else:oval((9,7,20,20),INK);oval((11,9,18,16),dark);oval((28,7,39,20),INK);oval((30,9,37,16),dark)
 elif n==7:poly([(10,21),(13,11),(19,14),(25,2),(28,13),(35,7),(38,22)],INK);poly([(13,20),(16,14),(20,16),(25,6),(28,17),(34,12),(35,21)],'#ed9969');poly([(20,18),(25,9),(28,19)],'#ffe1a2')
 face=(9,13,38,34) if n!=6 else (9,12,38,33)
 oval(face,INK) if n!=6 else box(face,INK)
 if n!=6:oval((11,14,36,32),base if n not in [0,5] else '#e6bc98');oval((12,14,33,30),light if n not in [0,5] else '#f8dfbf')
 else:box((11,14,36,30),base);box((13,16,34,27),'#2f4659');box((12,14,34,15),light);box((36,19,40,25),dark);box((37,20,39,23),light)
 if n==0:
  box((10,7,37,15),INK);box((12,5,35,12),'#f0ead5');box((14,4,33,7),'#fbf7e6');box((9,12,38,15),dark);box((12,12,35,13),base)
  if not back:box((22,7,25,10),'#e8b66b');line([(21,8),(26,8)],'#6a92a4')
 if n==5:
  poly([(8,16),(16,10),(18,4),(31,2),(33,9),(39,16)],INK);poly([(11,14),(19,11),(20,6),(30,4),(30,10),(35,14)],dark);poly([(19,11),(28,10),(30,13),(17,14)],'#eacb89');oval((27,4,30,7),'#f1d5a4');box((15,14,34,16),base)
 if n==3 and not back:oval((12,22,34,32),CREAM)
 if n==1 and not back:oval((13,22,34,31),'#fff1e1')
 if n==4 and not back:oval((17,23,31,32),'#d5e5df')
 # No eyes on the back; rear outfits get actual hats, straps and hair.
 if back:
  if n in [0,5]:poly([(13,18),(34,18),(32,29),(28,31),(15,28)],'#675457' if n==5 else '#966d51');line([(17,20),(17,27)],'#b99570')
  else:line([(13,24),(17,27),(29,27),(34,23)],dark,2);box((22,29,26,31),base)
  box((22,33,25,41),dark);box((21,37,26,39),light)
 else:
  blink=(state==0 and frame==3)
  eyes=[18,29] if not side else [29]
  for x in eyes:
   if hurt:line([(x-2,21),(x+2,25)],INK,2);line([(x-2,25),(x+2,21)],INK,2)
   elif trapped:line([(x-2,22),(x,20),(x+2,22)],INK,2);box((x,24,x+1,25),INK)
   elif blink:line([(x-2,24),(x+1,24)],INK,2)
   else:box((x-2,20,x+2,26),'#fcf7e7');box((x-1+(1 if side else 0),21,x+1+(1 if side else 0),25),INK);box((x,21,x,22),'#a7dce0');box((x-1,21,x-1,21),CREAM)
  if n==6:
   for x in eyes:box((x-1,21,x+1,24),'#a2f5d4');box((x,20,x+1,21),'#efffde')
  if not side:box((13,27,16,28),'#e5a49a');box((31,27,33,28),'#e5a49a')
  if hurt:oval((23,27,27,30),INK)
  elif trapped:line([(22,29),(24,27),(27,29)],INK)
  else:line([(23,28),(25,29),(27,28)],'#856568')
  if n in [3,4]:oval((23 if not side else 32,24,27 if not side else 35,26),INK)
 if n==1:
  poly([(34,15),(37,12),(40,15),(37,18)],'#ffe6a6');box((36,14,37,15),'#fff7dc')
 if n==6:line([(25,12),(25,5),(29,5)],INK,2);oval((27,2,32,7),'#eac588');box((29,3,30,4),CREAM)
 if n==7:box((12,18,14,20),'#ffc28a')
 # Native pixel shade bands add depth without smoothing the contour.
 bounds=im.getbbox()
 if bounds:
  pixels=im.load()
  for y in range(bounds[1],bounds[3]):
   occupied=[x for x in range(W) if pixels[x,y][3]>0]
   if not occupied:continue
   edge=max(occupied)
   for x in occupied:
    red,green,blue,alpha=pixels[x,y]
    if (red,green,blue)==(35,51,77):continue
    if x>=edge-2 and y>14:pixels[x,y]=(max(0,red-22),max(0,green-20),max(0,blue-12),alpha)
    elif y in [17,33,43] and x<24:pixels[x,y]=(min(255,red+8),min(255,green+7),min(255,blue+5),alpha)
 if direction==2:im=im.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
 return im
atlas=Image.new('RGBA',(W*32,H*24))
for n in range(8):
 for direction in range(4):
  for pose in range(24):atlas.alpha_composite(actor(n,direction,pose),((n*4+direction)*W,pose*H))
atlas.save(R/'heroes-detailed.png')
# Separate readable head portraits for menus and status panels.
portraits=Image.new('RGBA',(48*8,40))
for n in range(8):portraits.alpha_composite(actor(n,0,0).crop((0,0,48,40)),(n*48,0))
portraits.save(R/'hero-portraits.png')
print('8 original heroes · 4 directions · idle 4 / walk 8 / hurt 4 / struggle 4 / place 4 = 768 frames')
