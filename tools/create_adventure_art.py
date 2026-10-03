"""Original pixel art for five story regions, creatures, bosses and mission objects."""
from pathlib import Path
from PIL import Image,ImageDraw
import random
ROOT=Path(__file__).resolve().parents[1]/'assets'
INK='#182840';WHITE='#fff5d5'
palettes=[('#637b68','#344951','#a99567'),('#bba681','#74687c','#c09162'),('#68a9bb','#386878','#dc9d99'),('#a8bfcb','#75899f','#c9a66e'),('#6a668e','#373653','#957b9b')]
base=Image.open(ROOT/'tiles.png').convert('RGBA');atlas=Image.new('RGBA',(120,260));atlas.alpha_composite(base.crop((0,0,120,160)))
for t,(floor,wall,crate) in enumerate(palettes):
 for k in range(6):
  im=Image.new('RGBA',(20,20),floor);d=ImageDraw.Draw(im)
  d.line((0,19,19,19),fill=wall);d.line((19,0,19,19),fill=wall)
  if k<2:
   if t==0:
    d.ellipse((2,4,8,8),fill='#80a97f');d.line((12,14,15,11),fill='#b5c697');d.point((15,6),fill='#d5e9a8')
   elif t==1:
    d.rectangle((1,1,18,18),outline='#d5c69d');d.line((4,10,9,8,13,13),fill=wall)
   elif t==2:
    d.arc((2,3,13,10),0,170,fill='#98d6d4');d.point((15,15),fill='#e9d4a5');d.point((16,14),fill='#d6b3c2')
   elif t==3:
    d.line((2,6,17,6),fill='#dbe5df');d.line((2,14,17,14),fill='#8da7b9');d.rectangle((3,3,4,4),fill='#e4d9a5')
   else:
    d.rectangle((1,1,18,18),outline='#8f8bb0');d.polygon([(10,4),(14,10),(10,16),(6,10)],outline='#a9a2c4')
  elif k==2:
   d.rectangle((1,3,18,19),fill=INK)
   if t==0:
    d.rectangle((6,7,13,18),fill='#635343');d.ellipse((1,0,18,12),fill='#436554');d.line((5,4,8,11,13,14),fill='#86b37c',width=2)
   elif t==1:
    d.rectangle((4,1,15,17),fill='#827886');d.rectangle((6,1,13,3),fill='#d4bc9a');d.polygon([(10,5),(13,9),(10,13),(7,9)],fill='#91d8c0')
   elif t==2:
    d.line((10,18,10,4),fill='#e1adad',width=4);d.line((10,12,4,7,4,3),fill='#e1adad',width=3);d.line((10,10,16,6,16,1),fill='#f0c3b7',width=3)
   elif t==3:
    d.rectangle((5,4,14,17),fill='#667f9c');d.polygon([(3,5),(10,0),(17,5)],fill='#d6cfac');d.rectangle((8,7,11,11),fill='#a7dce0')
   else:
    d.rectangle((2,1,17,17),fill='#514e70');d.rectangle((2,1,17,3),fill='#b5a2c8');d.line((3,9,16,9),fill='#9382a7');d.line((10,4,10,8),fill='#9382a7')
  elif k==3:
   d.rectangle((2,4,17,18),fill=INK);d.rectangle((2,2,17,15),fill=crate);d.rectangle((4,3,15,14),outline='#edd2a5');d.line((3,8,16,8),fill=wall)
   if t==2:d.ellipse((7,5,12,11),fill='#f0dfc2')
   elif t==4:d.polygon([(10,4),(13,8),(10,12),(7,8)],fill='#d4a6db')
  elif k==4:d.rectangle((0,0,19,19),fill='#111727')
  else:d.ellipse((4,3,15,14),fill='#b7e2c2');d.rectangle((8,12,11,18),fill=crate)
  atlas.alpha_composite(im,(k*20,(t+8)*20))
atlas.save(ROOT/'tiles.png')
for t,name in enumerate(['swamp','ruins','reef','sky','citadel']):
 r=random.Random(903+t);im=Image.new('RGB',(640,360),['#253c3b','#403649','#193d57','#324660','#24213d'][t]);d=ImageDraw.Draw(im)
 if t==0:
  for x in range(-10,640,65):
   d.rectangle((x+19,160,x+27,360),fill='#405d4e');d.ellipse((x-5,120,x+52,196),fill='#3d6453');d.line((x+22,220,x+3,270),fill='#577456',width=3)
  for n in range(75):
   x=r.randrange(640);y=r.randrange(360);d.rectangle((x,y,x+1,y+1),fill=r.choice(['#b8d995','#91b49f']))
 elif t==1:
  for x in range(0,640,75):
   h=r.randrange(70,180);d.rectangle((x+8,360-h,x+46,360),fill='#726271');d.rectangle((x+3,350-h,x+51,362-h),fill='#a19086')
   for y in range(380-h,350,19):d.line((x+10,y,x+43,y),fill='#8c7a83')
  d.ellipse((528,46,594,112),fill='#958d99')
 elif t==2:
  for x in range(-10,640,55):
   d.line((x+18,360,x+22,265,x+12,238),fill='#52938c',width=7);d.line((x+20,308,x+39,283,x+41,261),fill='#887291',width=4)
  for n in range(40):
   x=r.randrange(640);y=r.randrange(280);d.ellipse((x,y,x+4,y+4),outline='#5d95a9')
  d.polygon([(552,85),(585,70),(607,85),(585,93)],fill='#b4cbbf');d.line((585,73,585,110),fill='#708c94')
 elif t==3:
  for n in range(15):
   x=r.randrange(640);y=r.randrange(360);d.ellipse((x,y,x+85,y+25),fill='#687d98');d.ellipse((x+14,y-8,x+52,y+16),fill='#687d98')
  for x in [30,565]:d.rectangle((x,150,x+25,240),fill='#7b8294');d.line((x+12,155,x+12,105),fill='#d5cdb6',width=2);d.polygon([(x+12,105),(x+45,138),(x+12,138)],fill='#b0aaa8')
 else:
  for x in range(-20,640,70):
   h=r.randrange(90,230);d.rectangle((x,360-h,x+52,360),fill='#423a60');d.polygon([(x,360-h),(x+26,335-h),(x+52,360-h)],fill='#6a5078')
   for y in range(380-h,340,24):d.rectangle((x+16,y,x+22,y+8),fill='#aa87ae')
  d.ellipse((525,42,601,118),fill='#696085');d.polygon([(540,105),(581,53),(605,65)],fill='#403654')
 im.save(ROOT/f'background-{name}.png')
# Six common enemies and five chapter bosses; every silhouette is separately drawn.
enemies=Image.new('RGBA',(352,96))
for n in range(11):
 for pose in range(3):
  im=Image.new('RGBA',(32,32));d=ImageDraw.Draw(im);dy=pose%2
  if n==0:
   d.ellipse((4,11+dy,27,28),fill=INK);d.ellipse((5,12+dy,26,26),fill='#ad81cd');d.rectangle((7,22,24,26),fill='#785ca7')
  elif n==1:
   d.rectangle((11,15,21,28),fill='#d7c2a5');d.ellipse((2,6+dy,29,21+dy),fill=INK);d.ellipse((3,7+dy,28,19+dy),fill='#c47c8e');d.rectangle((7,9,11,11),fill='#f9d9b3');d.rectangle((22,12,25,14),fill='#f9d9b3')
  elif n==2:
   for x in [5,25]:
    for y in [13,19,25]:d.line((x,y,x+(-3 if x==5 else 3),y+pose-1),fill='#c8ac78',width=2)
   d.ellipse((6,6,25,28),fill=INK);d.ellipse((7,7,24,27),fill='#d2b36f');d.line((16,8,16,26),fill='#8f754f',width=2)
  elif n==3:
   for x in [7,12,19,24]:d.line((x,19,x+pose-1,28),fill='#a88ed6',width=2)
   d.ellipse((3,6+dy,28,22+dy),fill='#63598c');d.ellipse((4,7+dy,27,20+dy),fill='#bc91d6');d.arc((7,8,24,19),180,345,fill='#edc9e0',width=2)
  elif n==4:
   d.ellipse((7,10,24,24),fill=INK);d.rectangle((9,11,22,22),fill='#87b5bf');d.line((3,9,28,9),fill='#d1d7b5',width=2);d.rectangle((1,7+dy,8,10+dy),fill='#c1caca');d.rectangle((23,7-dy,30,10-dy),fill='#c1caca')
  elif n==5:
   d.polygon([(7,25),(6,12),(9,5),(23,5),(26,12),(25,25)],fill=INK);d.rectangle((9,6,22,15),fill='#8c718f');d.rectangle((10,10,21,12),fill='#e2b49b');d.rectangle((8,17,24,26),fill='#66547e');d.rectangle((3,16,6,26),fill='#c1a7bb');d.line((28,9,28,25),fill='#d9c38c',width=2)
  elif n==6:
   d.line((6,18,2,28,10,25),fill='#aa9c70',width=3);d.line((25,18,30,28,22,25),fill='#aa9c70',width=3)
   d.rectangle((10,10,23,28),fill='#83755f');d.ellipse((2,1,30,18),fill='#497961');d.ellipse((5,0,27,13),fill='#73a16e');d.rectangle((12,16,22,21),fill='#d2c5a3');d.rectangle((6,4,8,7),fill='#e7d69d');d.rectangle((23,3,25,6),fill='#d1cf91')
  elif n==7:
   d.rectangle((6,6,25,27),fill=INK);d.rectangle((7,7,24,26),fill='#c9aa78');d.rectangle((4,3,27,7),fill='#e7d0a5');d.rectangle((4,26,27,29),fill='#e7d0a5');d.polygon([(10,10),(21,10),(16,17),(10,23),(21,23),(16,17)],fill='#8a738c');d.rectangle((14,13,18,18),fill='#8fe1ce')
  elif n==8:
   d.ellipse((8,11,24,26),fill='#aa686f');d.ellipse((9,12,23,24),fill='#e3937d');d.ellipse((0,7+dy,10,18+dy),fill='#dba78d');d.ellipse((22,7-dy,31,18-dy),fill='#dba78d')
   for x in [8,24]:
    for y in [22,26]:d.line((x,y,x+(-5 if x==8 else 5),y+2),fill='#ebba98',width=2)
  elif n==9:
   d.ellipse((1,3,30,20),fill=INK);d.ellipse((2,4,29,18),fill='#9ba2c5');d.line((6,6,24,6),fill='#dfd7bd');d.rectangle((10,20,22,28),fill='#526f96');d.rectangle((12,22,20,25),fill='#b3e0dd');d.line((3,23,28,23),fill='#ceccae',width=2)
  else:
   for x in [3,10,20,27]:d.line((16,15,x,29),( '#b090c9'),width=3)
   d.ellipse((4,4,28,23),fill=INK);d.ellipse((5,5,27,22),fill='#85669f');d.polygon([(7,6),(9,0),(14,4),(18,0),(23,6)],fill='#efd393');d.rectangle((7,6,24,8),fill='#d5b87d')
  if n!=7:
   for x in [11,20]:d.rectangle((x,15+dy,x+2,17+dy),fill='#fff0b0');d.point((x+1,16+dy),fill=INK)
  enemies.alpha_composite(im,(n*32,pose*32))
enemies.save(ROOT/'enemies.png')
objects=Image.new('RGBA',(160,20))
for n in range(8):
 im=Image.new('RGBA',(20,20));d=ImageDraw.Draw(im)
 if n==0:
  d.ellipse((5,8,14,17),fill='#e4d19b');d.line((10,10,10,3),fill='#84cb8b',width=2);d.polygon([(10,6),(4,2),(4,6)],fill='#b5ed95');d.polygon([(10,4),(16,1),(15,6)],fill='#8bdfa5')
 elif n==1:
  d.ellipse((1,1,18,18),fill='#826bb1');d.ellipse((2,2,17,17),outline='#d7d2ff',width=2);d.rectangle((7,7,12,13),fill='#ffd9b1');d.rectangle((6,4,13,7),fill='#d79eac')
 elif n==2:
  d.rectangle((6,6,13,18),fill='#aa947a');d.rectangle((3,3,16,9),fill='#4e6378');d.polygon([(10,0),(14,5),(10,10),(6,5)],fill='#fff0a6');d.rectangle((5,17,14,19),fill='#d8c39b')
 elif n==3:
  d.rectangle((2,6,17,14),fill='#bd9972');d.rectangle((4,7,15,12),fill='#e1c895');d.polygon([(10,3),(13,7),(10,11),(7,7)],fill='#a2eadc');d.ellipse((3,14,7,18),fill=INK);d.ellipse((13,14,17,18),fill=INK)
 elif n==4:
  d.ellipse((1,3,18,16),fill='#577f94');d.ellipse((3,5,16,14),outline='#d4ffbc',width=2);d.polygon([(8,6),(13,10),(8,13)],fill='#fff3b4')
 elif n==5:
  d.polygon([(10,1),(17,6),(14,16),(6,16),(3,6)],fill='#efe8b2');d.polygon([(10,3),(14,7),(10,13),(6,7)],fill='#8fdce1')
 elif n==6:
  d.rectangle((6,5,13,12),fill='#ffe6bf');d.polygon([(4,5),(10,0),(16,5)],fill='#99d9c1');d.rectangle((4,12,15,17),fill='#6a9f92');d.rectangle((5,17,7,19),fill=INK);d.rectangle((12,17,14,19),fill=INK)
 else:d.polygon([(3,4),(7,3),(10,6),(13,3),(17,4),(17,9),(10,17),(3,9)],fill='#ff96aa')
 objects.alpha_composite(im,(n*20,0))
objects.save(ROOT/'mission-objects.png')
print('Created five regions, eleven enemies/bosses, and eight mission objects.')
