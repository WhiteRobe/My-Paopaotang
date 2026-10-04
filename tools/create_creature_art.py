"""Original detailed creature sprites, 64px, 8 motion and 4 impact frames."""
from pathlib import Path
from PIL import Image,ImageDraw
import math,random
R=Path(__file__).resolve().parents[1]/'assets';INK='#263449';WHITE='#fff0cd'
COLORS=['#b59acb','#cb929f','#d0b678','#b29bce','#93bfc3','#9d86b1','#93b87f','#d9ba85','#d39594','#b0cccd','#a08cbd']
def sprite(n,frame):
 im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im);c=COLORS[n];phase=frame*math.tau/8;hurt=frame>=8
 sway=round(math.sin(phase)*2);dy=round(abs(math.sin(phase))*2)
 if hurt:dy=0;sway=(-3,-1,2,0)[frame-8]
 def box(b,fill,outline=None,width=1):d.rectangle(tuple(v+(sway if i%2==0 else dy) for i,v in enumerate(b)),fill=fill,outline=outline,width=width)
 def oval(b,fill,outline=None,width=1):d.ellipse(tuple(v+(sway if i%2==0 else dy) for i,v in enumerate(b)),fill=fill,outline=outline,width=width)
 def poly(p,fill,outline=None):d.polygon([(x+sway,y+dy) for x,y in p],fill=fill,outline=outline)
 def line(p,fill,width=1):d.line([(x+sway,y+dy) for x,y in p],fill=fill,width=width)
 if n==0:
  oval((9,22,55,56),INK);oval((11,23,53,53),c);oval((14,25,46,48),'#cbb8df');oval((15,27,22,32),'#e9d5e8');line([(14,47),(20,50),(44,50),(50,47)],'#9271aa',2)
 elif n==1:
  box((24,30,40,55),'#dccbb3',INK,2);line([(29,34),(29,49)],'#f3e0c0',2);oval((4,8,59,38),INK);oval((6,10,57,35),c);oval((8,12,50,29),'#e0a9af');line([(9,31),(53,31)],'#995b83',2)
  for x,y in [(15,16),(36,13),(48,23)]:oval((x,y,x+7,y+4),'#f6d9bb');box((x+1,y+1,x+3,y+1),WHITE)
 elif n==2:
  for x in [12,51]:
   for y in [28,39,49]:line([(x,y),(x+(-7 if x==12 else 7),y+round(math.sin(phase+y)*3))],'#a38b6a',3)
  oval((13,9,51,56),INK);oval((15,11,49,53),c);oval((18,12,45,48),'#e0c993');line([(31,13),(31,51)],'#94795b',3)
  for y in [22,32,43]:line([(18,y),(27,y+3)],'#b29468',2);line([(35,y+3),(44,y)],'#b29468',2)
 elif n==3:
  for x in [15,25,38,48]:line([(x,35),(x+round(math.sin(phase+x)*4),54),(x+round(math.cos(phase+x)*5),58)],'#9b85ba',3)
  oval((6,11,58,41),INK);oval((8,12,56,38),c);oval((11,14,50,34),'#cab6dc');d.arc((12+sway,15+dy,51+sway,35+dy),190,330,fill='#f3d0e3',width=2);box((24,17,28,18),'#e5e6dc')
 elif n==4:
  spin=round(math.sin(phase*2)*3)
  oval((1,12+spin,25,22+spin),'#dce8df',INK,2);oval((38,12-spin,62,22-spin),'#dce8df',INK,2);line([(6,17),(56,17)],'#748f9e',2)
  box((17,22,47,47),INK);box((20,24,44,43),c);box((22,25,30,40),'#c4ddda');box((20,44,44,47),'#567c92');box((26,16,38,24),'#72889a');box((29,13,35,17),WHITE);line([(21,48),(16,54)],'#8ba49e',2);line([(43,48),(48,54)],'#8ba49e',2)
 elif n==5:
  poly([(15,51),(13,25),(20,12),(45,12),(51,26),(48,53)],INK);box((19,17,45,34),c);box((22,21,42,29),'#3c405e');box((19,38,46,52),'#67618a');box((19,39,44,41),'#b59bae');box((29,38,33,53),'#c5b591');box((26,45,37,48),'#726579');line([(52,17),(52,55)],'#b8af88',3);poly([(52,13),(48,19),(56,19)],WHITE);box((9,37,15,52),c)
 elif n==6:
  for x in [15,47]:line([(x,35),(x-7 if x==15 else x+7,54),(x+3,53)],'#948865',5)
  box((21,22,45,55),'#9b866b',INK,2);line([(26,29),(24,47),(28,54)],'#cab288',2);line([(39,34),(36,49)],'#675c50',2)
  oval((3,5,61,35),'#3b685b',INK,2);oval((8,3,54,28),c);oval((10,6,42,23),'#b0c790');box((21,30,45,41),'#d8ccb1')
  for x,y in [(16,10),(44,8),(51,21)]:oval((x,y,x+4,y+4),'#e5d293');box((x+1,y,x+2,y),WHITE)
 elif n==7:
  box((12,10,51,54),INK);box((15,13,48,51),c);box((9,6,54,13),'#f2d8a5',INK,2);box((9,51,54,58),'#f2d8a5',INK,2);box((18,17,45,47),'#77718b')
  poly([(21,18),(43,18),(32,31),(22,45),(42,45),(32,31)],'#e5c59a');oval((27,26,38,37),'#9cd6ca');box((30,28,34,34),'#d7f2d5');line([(17,16),(17,48)],'#ad956b',2)
 elif n==8:
  for x in [13,50]:
   line([(x,40),(x+(-8 if x==13 else 8),51)],'#b77682',4)
   oval((x-8,15,x+8,34),c,INK,2);poly([(x-6,15),(x,24),(x+6,15)],'#f4d0bd')
  oval((16,24,49,53),INK);oval((18,26,47,50),c);oval((22,26,43,40),'#e5b1a2');line([(22,47),(42,47)],'#a8687d',2)
 elif n==9:
  oval((5,9,59,39),INK);oval((7,11,57,36),c);oval((11,11,50,27),'#dce7dd');line([(20,12),(17,33)],'#8fabad',2);line([(34,12),(33,34)],'#8fabad',2);line([(47,15),(48,30)],'#8fabad',2)
  box((25,34,43,52),'#8e8b92',INK,2);box((27,37,40,47),'#d8b5a4');box((29,39,38,44),'#435c75');line([(4,37),(20,37)],'#c6bb9c',3);line([(46,39),(62,39)],'#c6bb9c',3);poly([(2,30),(9,37),(2,44)],'#e0d2b6');poly([(60,32),(53,39),(60,46)],'#e0d2b6')
 else:
  poly([(7,50),(15,19),(48,19),(58,53),(42,57),(20,57)],INK);poly([(11,49),(19,21),(44,21),(53,51),(39,54),(23,54)],'#75618f');box((20,15,45,38),c);poly([(17,17),(14,4),(25,11),(33,2),(41,11),(51,5),(48,18)],'#e1c899',INK);box((21,18,44,20),'#f6e1b0');oval((19,23,46,41),'#b7a2c7');poly([(25,48),(33,40),(41,48),(33,54)],'#9cdecd');line([(31,45),(34,48),(31,51)],'#e8f8d4',2)
 # Eyes and impact expressions are positioned separately for each body.
 y=[34,39,23,26,32,25,35,32,36,24,30][n]
 if n not in [7,9]:
  for x in [25,39]:
   if hurt:line([(x-2,y-2),(x+2,y+2)],INK,2);line([(x-2,y+2),(x+2,y-2)],INK,2)
   else:box((x-2,y-3,x+2,y+3),WHITE);box((x,y-2,x+2,y+2),INK);box((x,y-2,x,y-2),'#c3e9df')
  line([(29,y+7),(32,y+8),(35,y+7)],INK)
 # Small native-resolution highlights, moss, scratches and rivets.
 rng=random.Random(n*19)
 for j in range(8):
  x=rng.randrange(12,53);y2=rng.randrange(12,51)
  at=(min(63,max(0,x+sway)),min(63,max(0,y2+dy)))
  if im.getpixel(at)[3] and im.getpixel(at)[:3] != (38,52,73):
   pixel=im.getpixel(at);glint=tuple(min(255,v+16) for v in pixel[:3])+(255,);d.point(at,fill=glint)
 return im
atlas=Image.new('RGBA',(64*11,64*12))
for n in range(11):
 for frame in range(12):atlas.alpha_composite(sprite(n,frame),(n*64,frame*64))
atlas.save(R/'creatures-detailed.png')
print('11 original creatures / bosses, 64×64, 8 motion + 4 impact poses')
