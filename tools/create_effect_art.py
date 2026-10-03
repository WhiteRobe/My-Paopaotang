"""Hand-drawn environment accents and animated pixel impact effects."""
from pathlib import Path
from PIL import Image,ImageDraw
import math,random
ROOT=Path(__file__).resolve().parents[1]/'assets'
INK='#182840'
colors=['#8bcbb8','#a3ca85','#d5eafa','#f0cfa0','#dd9e7b','#a1c9ca','#f4bbd6','#bca9e4','#a2c991','#d6c9a3','#a9ded4','#d7e5d9','#bea7d9']
atlas=Image.new('RGBA',(160,260))
for theme,color in enumerate(colors):
 for variant in range(8):
  im=Image.new('RGBA',(20,20));d=ImageDraw.Draw(im);r=random.Random(theme*113+variant)
  if variant==0:
   d.polygon([(4,14),(6,10),(12,9),(16,13),(14,16),(5,16)],fill='#455c68');d.line((6,12,12,11,15,13),fill=color);d.line((7,14,13,14),fill='#8eaaa8')
  elif variant==1:
   for x,y in [(5,14),(10,12),(15,15)]:
    d.line((x,y,x,y-5),fill='#648d71');d.line((x,y-2,x-2,y-3),fill='#8ab386');d.rectangle((x-1,y-7,x+1,y-5),fill=color);d.point((x,y-6),fill='#fff0b5')
  elif variant==2:
   d.ellipse((3,10,17,16),fill='#4e8192');d.line((5,12,10,12),fill=color);d.line((12,14,15,14),fill='#b3dedb');d.point((15,10),fill='#e0f9eb')
  elif variant==3:
   d.rectangle((8,7,11,18),fill='#7b6f7a');d.rectangle((5,3,14,8),fill=INK);d.rectangle((6,4,13,7),fill=color);d.rectangle((7,5,12,6),fill='#fff3bb');d.rectangle((6,18,13,19),fill='#b2a594')
  elif variant==4:
   d.rectangle((8,11,11,17),fill='#d4c4a2');d.polygon([(9,4),(12,9),(10,11),(7,9)],fill=color);d.rectangle((9,7,10,9),fill='#fff6ca');d.rectangle((6,17,13,18),fill='#96847a')
  elif variant==5:
   d.line((9,1,8,8,12,15,10,19),fill='#739480',width=2)
   for x,y in [(8,5),(11,11),(11,16)]:d.polygon([(x,y),(x-4,y-3),(x-3,y+1)],fill=color);d.polygon([(x,y),(x+4,y-2),(x+3,y+2)],fill='#8ab995')
  elif variant==6:
   d.rectangle((3,1,4,19),fill='#c2b59b');d.polygon([(5,3),(16,3),(14,8),(16,13),(5,13)],fill=color);d.rectangle((7,5,10,7),fill='#fff2bf');d.line((5,12,15,12),fill='#687e91')
  else:
   for y in [5,10,15]:d.polygon([(3,y),(14,y),(17,y+3),(6,y+3)],fill=color);d.line((6,y+3,17,y+3),fill='#637081')
  atlas.alpha_composite(im,(variant*20,theme*20))
atlas.save(ROOT/'decorations.png')
# Each effect has four deliberately drawn phases, rather than a scaled rectangle.
fx=Image.new('RGBA',(192,128));palettes=[('#68dfff','#bffaff'),('#96c7ff','#f0feff'),('#ff9166','#fff0a2'),('#bda0ff','#fffac2'),('#91e9a5','#e8ffc0'),('#ffa2c4','#fff2df')]
for kind,(color,light) in enumerate(palettes):
 for frame in range(4):
  im=Image.new('RGBA',(32,32));d=ImageDraw.Draw(im);radius=5+frame*3
  if kind in [0,1,5]:
   d.ellipse((16-radius,16-radius,16+radius,16+radius),outline=color,width=2 if frame<3 else 1)
   for n in range(8):
    a=n*math.pi/4; x=round(16+math.cos(a)*(radius+2));y=round(16+math.sin(a)*(radius+2));d.rectangle((x,y,x+1,y+1),fill=light)
   if kind==1:
    for n in range(6):
     a=n*math.pi/3;d.line((16,16,round(16+math.cos(a)*radius),round(16+math.sin(a)*radius)),fill=light)
   elif kind==5:d.polygon([(14,9),(18,9),(18,14),(23,14),(23,18),(18,18),(18,23),(14,23),(14,18),(9,18),(9,14),(14,14)],fill=light)
  elif kind==2:
   for n in range(5):
    x=7+n*4;h=5+(n*3+frame*2)%10;d.polygon([(x-3,24),(x,24-h),(x+3,24)],fill=color);d.line((x,22,x,24-h//2),fill=light,width=2)
   d.rectangle((8,25,23,26),fill=light)
  elif kind==3:
   for n in range(4):
    a=n*math.pi/2; x=round(16+math.cos(a)*radius);y=round(16+math.sin(a)*radius)
    d.line((16,16,(16+x)//2+2,(16+y)//2-2,x,y),fill=color,width=3);d.line((16,16,x,y),fill=light,width=1)
  else:
   for n in range(6):
    a=n*math.pi/3+frame*.3;x=round(16+math.cos(a)*radius);y=round(16+math.sin(a)*radius)
    d.polygon([(x-3,y),(x,y-4),(x+3,y),(x,y+3)],fill=color);d.line((x-1,y+1,x+1,y-1),fill=light)
  fx.alpha_composite(im,(kind*32,frame*32))
fx.save(ROOT/'impact-effects.png')
print('Created 104 pixel environment accents and six animated impact families.')

items=Image.new('RGBA',(200,60));items.alpha_composite(Image.open(ROOT/'items.png').convert('RGBA').crop((0,0,200,40)))
for i,(color,light) in enumerate(palettes[1:]+[('#ffe3a0','#fff5d4')]):
 im=Image.new('RGBA',(20,20));d=ImageDraw.Draw(im)
 d.polygon([(10,1),(17,5),(17,14),(10,18),(3,14),(3,5)],fill=INK);d.polygon([(10,2),(16,6),(16,13),(10,17),(4,13),(4,6)],fill=color)
 if i==0:
  for dx,dy in [(5,0),(-5,0),(0,5),(0,-5),(3,3),(-3,-3)]:d.line((10,10,10+dx,10+dy),fill=light)
 elif i==1:d.polygon([(7,13),(6,9),(9,5),(11,9),(13,6),(14,12),(11,15)],fill=light)
 elif i==2:d.polygon([(11,4),(6,11),(10,11),(8,16),(14,8),(10,8)],fill=light)
 elif i==3:d.line((10,5,9,10,11,15),fill=light,width=2);d.polygon([(9,9),(5,6),(5,10)],fill=light);d.polygon([(10,12),(15,9),(14,13)],fill=light)
 elif i==4:d.rectangle((8,5,11,14),fill=light);d.rectangle((5,8,14,11),fill=light)
 else:d.line((5,13,14,5),fill=light,width=2);d.polygon([(10,5),(15,4),(14,9)],fill=light);d.line((3,15,6,12),fill=light)
 d.point((5,5),fill='#ffffff');items.alpha_composite(im,(i*20,40))
items.save(ROOT/'items.png')
