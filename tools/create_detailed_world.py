"""Original 48-pixel environmental art and 1280×720 painted pixel landscapes."""
from pathlib import Path
from PIL import Image,ImageDraw
import math,random
R=Path(__file__).resolve().parents[1]/'assets'
NAMES=['harbor','forest','frost','desert','volcano','factory','candy','cosmos','swamp','ruins','reef','sky','citadel','cave']
PAL=[('#466f88','#91b9b0','#c6a57b'),('#284b4d','#86a978','#8c9a6b'),('#506b92','#c1dfec','#8db6d2'),('#695567','#d7b989','#bd956a'),('#492e48','#8a6566','#c78875'),('#394861','#a3afa9','#8a929c'),('#765e8c','#e3c4c4','#dca0b3'),('#282b57','#8289b1','#b1a3c9'),('#294c4b','#8eaa89','#758e73'),('#4d4259','#bcae91','#8a7c8e'),('#225b72','#81bfbd','#dfa6ae'),('#466b8e','#b9d0cf','#c4ad83'),('#332d55','#9288ad','#706785'),('#202d42','#687f87','#536579')]
INK='#25334a'
def mix(a,b,t):
 a=tuple(bytes.fromhex(a[1:])) if isinstance(a,str) else a;b=tuple(bytes.fromhex(b[1:])) if isinstance(b,str) else b;return tuple(round(x*(1-t)+y*t) for x,y in zip(a,b))
def stone(d,box,c,outline=INK):
 d.rectangle(box,fill=c,outline=outline,width=2);x,y,X,Y=box;d.line((x+3,y+3,X-3,y+3),fill=mix(c,'#ffffff',.35),width=2);d.line((x+3,Y-3,X-3,Y-3),fill=mix(c,'#000000',.2),width=2)
tiles=Image.new('RGBA',(288,len(NAMES)*48));decors=Image.new('RGBA',(384,len(NAMES)*48))
for t,(dark,floor,wall) in enumerate(PAL):
 for k in range(6):
  r=random.Random(370*t+k);im=Image.new('RGBA',(48,48));d=ImageDraw.Draw(im)
  if k<2:
   d.rectangle((0,0,47,47),fill=floor)
   for n in range(50):
    x=r.randrange(2,46);y=r.randrange(2,46);d.line((x,y,x+r.randrange(1,4),y),fill=mix(floor,dark,.05+r.random()*.15))
   if t in [0,5,11]:
    for y in [0,16,32]:d.line((0,y,47,y),fill=mix(floor,dark,.32));d.line((0,y+1,47,y+1),fill=mix(floor,'#ffffff',.25))
    for x,y in [(8,8),(40,24),(8,40)]:d.rectangle((x,y,x+1,y+1),fill=dark)
   elif t in [3,9,12]:
    d.rectangle((1,1,46,46),outline=mix(floor,dark,.3),width=2);d.rectangle((4,4,43,43),outline=mix(floor,'#ffffff',.17))
    if k==1:d.line((0,25,13,25,18,30,22,28),fill=mix(floor,dark,.4))
    if t==12:d.polygon([(24,12),(35,24),(24,36),(13,24)],outline='#bfb1cf');d.polygon([(24,17),(30,24),(24,31),(18,24)],outline='#a397ba')
   elif t==2:
    d.polygon([(0,6),(18,2),(46,11),(47,42),(32,46),(8,43)],outline='#e7f3f3',width=2);d.line((5,36,19,25,24,27,40,9),fill='#91b5d0');d.line((24,27,29,40),fill='#91b5d0')
   elif t in [1,8]:
    for x,y in [(8,8),(34,30),(13,37)]:d.ellipse((x,y,x+8,y+4),fill=mix(floor,'#e9efb0',.2));d.line((x+4,y,x+6,y-3),fill=dark)
   elif t in [6,7]:
    d.rectangle((1,1,46,46),outline=mix(floor,'#ffffff',.25),width=2)
    if k==1:d.polygon([(24,12),(27,21),(37,24),(27,27),(24,37),(21,27),(12,24),(21,21)],fill=mix(floor,'#ffffff',.4))
   elif t==10:
    d.arc((-5,8,41,34),8,155,fill='#b7dfcc',width=2);d.arc((14,29,51,50),185,340,fill='#4c969e',width=2)
   elif t==13:
    d.line((0,9,15,7,31,12,48,8),fill='#475a6d',width=2);d.line((10,47,15,33,27,28),fill='#475a6d')
    if k==1:d.polygon([(21,19),(27,22),(25,29),(19,26)],outline='#8faeba')
   else:
    d.line((0,9,15,7,31,12,48,8),fill='#b08075',width=2);d.line((10,47,15,33,27,28),fill='#b08075')
  elif k==2:
   d.rectangle((0,0,47,47),fill=floor);d.ellipse((3,34,44,47),fill=mix(floor,dark,.45))
   if t in [1,8]:
    stone(d,(19,22,28,42),'#8b7364');d.ellipse((3,0,44,30),fill=INK);d.ellipse((5,1,42,27),fill='#5c8d74');d.ellipse((10,3,35,20),fill='#7ead87');d.line((14,9,20,6,28,9),fill='#bdd2a3',width=2)
    for x,y in [(8,22),(35,17),(13,6)]:d.ellipse((x,y,x+5,y+4),fill='#9cc193')
   elif t==10:
    for x,Y in [(10,12),(24,3),(37,16)]:d.line((24,42,x,Y),fill='#a77f9d',width=6);d.line((x,Y,x-4,Y-7),fill='#eabcae',width=5);d.ellipse((x-3,Y-5,x+3,Y+2),fill='#f2cfb6')
   else:
    stone(d,(3,10,44,42),wall);stone(d,(3,1,44,13),mix(wall,'#ffffff',.15));d.line((4,26,43,26),fill=dark,width=2);d.line((24,15,24,25),fill=dark,width=2);d.line((15,28,15,39),fill=dark,width=2)
    if t in [5,7,12]:
     stone(d,(17,15,30,25),dark);d.rectangle((20,18,27,21),fill=['#9ce8dc','#c4b5f8','#edb0d2'][[5,7,12].index(t)])
    if t==2:d.polygon([(4,12),(9,12),(7,24)],fill='#e7f5fa');d.polygon([(34,12),(41,12),(37,27)],fill='#e7f5fa')
   if t==13:
    d.polygon([(4,15),(11,2),(22,6),(31,1),(43,15),(39,39),(24,43),(8,38)],fill='#586f7e',outline='#28374c',width=2)
    d.line((11,7,16,16,12,31),fill='#83949b',width=2);d.line((26,8,31,15,28,27,35,37),fill='#3c5268',width=2)
    for x,y in [(23,16),(28,22),(19,28)]:d.polygon([(x,y-4),(x+3,y),(x,y+4),(x-3,y)],fill='#92c6cf',outline='#507e95')
   elif t==5:
    stone(d,(6,16,41,38),mix(wall,dark,.2));d.line((8,26,39,26),fill='#5e7c88',width=2)
    for x,y in [(9,19),(37,19),(9,35),(37,35)]:d.ellipse((x-2,y-2,x+2,y+2),fill='#d4dfd2',outline='#516575')
    d.rectangle((20,22,28,30),fill='#72a6aa');d.line((20,23,27,23),fill='#b5e6d7')
   elif t==4:
    d.line((10,3,15,16,12,22,20,27,16,39),fill='#de9b76',width=2);d.line((16,12,19,15,16,20),fill='#f3bf89')
   elif t in [3,9]:
    d.polygon([(24,17),(33,23),(24,29),(15,23)],outline='#e1c99d',width=2);d.ellipse((21,21,27,25),fill='#8ca6a1')
   elif t==6:
    for x in range(4,45,8):d.ellipse((x,1,x+8,9),fill='#f5d9d0')
    d.arc((8,15,39,37),190,345,fill='#eac1d3',width=2)
   elif t in [7,12]:
    d.polygon([(24,16),(34,26),(24,36),(14,26)],outline='#bcacd9',width=2);d.polygon([(24,20),(29,26),(24,32),(19,26)],fill='#92bacd' if t==7 else '#b18cbf')
   elif t==11:
    d.arc((13,13,35,40),180,360,fill='#dfded0',width=3);d.line((18,25,30,25),fill='#728e9f',width=2)
  elif k==3:stone(d,(4,4,43,42),wall)
  else:d.rectangle((0,0,47,47),fill=dark)
  tiles.alpha_composite(im,(k*48,t*48))
 for k in range(8):
  r=random.Random(t*100+k);im=Image.new('RGBA',(48,48));d=ImageDraw.Draw(im)
  if k==0:
   d.ellipse((9,30,40,42),fill=(30,40,50,55));d.polygon([(10,31),(15,20),(32,18),(40,31),(33,37),(17,37)],fill=mix(floor,dark,.2),outline=dark);d.line((16,22,30,20,35,29),fill=mix(floor,'#ffffff',.45),width=2)
  elif k==1 and t==13:
   for x,y in [(11,14),(30,27),(19,36)]:
    d.polygon([(x-4,y+8),(x-3,y),(x,y-6),(x+4,y),(x+3,y+8)],fill='#77b6c8',outline='#344b64');d.line((x,y-3,x,y+5),fill='#caedf0');d.line((x-3,y+9,x+4,y+9),fill='#394859',width=2)
  elif k==1:
   for x,y in [(11,14),(30,27),(19,36)]:
    d.line((x,y+4,x-3,y+11),fill='#567665',width=2)
    for a in range(5):
     X=x+int(math.cos(a*math.tau/5)*4);Y=y+int(math.sin(a*math.tau/5)*4);d.ellipse((X-2,Y-2,X+2,Y+2),fill=['#e9cf9c','#dda9c2','#b1dce0'][t%3])
    d.rectangle((x-1,y-1,x+1,y+1),fill='#fff0be')
  elif k==2:
   d.ellipse((5,24,43,39),fill=mix(floor,dark,.25));d.arc((8,26,40,36),10,170,fill='#c5dfd3',width=2);d.arc((15,29,34,38),10,170,fill='#8ebdb8')
  elif k==3:
   stone(d,(14,10,32,31),dark);d.rectangle((17,13,29,28),fill='#ffe6a8');d.line((23,11,23,30),fill=dark,width=2);d.line((14,20,32,20),fill=dark,width=2);d.polygon([(10,11),(23,1),(36,11)],fill=wall,outline=INK);stone(d,(20,31,26,42),wall)
  elif k==4:
   d.ellipse((7,34,41,42),fill=(20,40,60,60));stone(d,(9,10,38,37),wall)
   for x in [14,24,33]:d.line((x,12,x,35),fill=dark,width=2)
   for y in [15,31]:d.rectangle((8,y,39,y+3),fill='#708a99');d.line((10,y,36,y),fill='#bcd3d5')
   d.ellipse((10,6,37,15),fill=wall,outline=dark,width=2);d.ellipse((14,8,34,12),outline='#efd6b2')
  elif k==5 and t==13:
   for x,Y in [(10,27),(24,12),(37,25)]:
    d.rectangle((x-1,Y,x+1,Y+11),fill='#b4a7bc');d.pieslice((x-7,Y-6,x+7,Y+5),180,360,fill='#a687ad',outline='#584c71',width=2);d.rectangle((x-3,Y-3,x-1,Y-2),fill='#e4d2c9')
  elif k==5:
   for x,Y in [(10,27),(24,12),(37,25)]:
    d.line((24,44,x,Y),fill='#60896f',width=3);d.ellipse((x-5,Y-5,x+5,Y+3),fill='#97b987');d.line((x-3,Y+1,x+3,Y-2),fill='#cee0ad')
  elif k==6:
   stone(d,(21,5,26,43),wall);d.polygon([(26,5),(44,8),(41,23),(26,20)],fill=['#db9caf','#9ac7ca','#e2ca94'][t%3],outline=INK);d.line((29,8,41,10),fill='#f5e5c2',width=2);d.polygon([(33,12),(37,15),(33,18),(29,15)],fill='#f4e8c9')
  else:
   stone(d,(5,31,42,43),wall);stone(d,(8,20,39,32),mix(wall,'#ffffff',.1));stone(d,(12,8,35,21),mix(wall,'#ffffff',.2));d.line((16,11,31,11),fill='#e5d8bb',width=2)
  decors.alpha_composite(im,(k*48,t*48))
tiles.save(R/'tiles-detailed.png');decors.save(R/'decorations-detailed.png')
# Landscapes are redrawn at twice the old source resolution, not enlarged copies.
for t,name in enumerate(NAMES):
 r=random.Random(8200+t);dark,floor,wall=PAL[t];im=Image.new('RGB',(1280,720));d=ImageDraw.Draw(im)
 for y in range(720):d.line((0,y,1279,y),fill=mix(dark,floor,.12+.18*y/720))
 if t in [2,3,7,9,11,12]:
  d.ellipse((1040,62,1168,190),fill=mix(floor,'#fff1cc',.25));d.ellipse((1051,67,1090,103),fill=mix(floor,wall,.3));d.ellipse((1130,141,1153,159),fill=mix(floor,wall,.3))
 for layer in range(3):
  ybase=360+layer*110;col=mix(dark,floor,.12+layer*.12)
  points=[(0,720),(0,ybase)]+[(x,ybase-r.randrange(30,130)) for x in range(0,1320,80)]+[(1280,720)]
  d.polygon(points,fill=col)
 for x in range(-40,1320,150):
  height=r.randrange(140,310);Y=720-height
  if t==13:
   Y=r.randrange(0,110);d.polygon([(x-20,0),(x+120,0),(x+83,Y+75),(x+65,Y+13),(x+42,Y+132),(x+18,Y+66)],fill='#4e6374',outline='#203049')
   d.line((x+42,11,x+42,Y+106),fill='#758792',width=3)
   d.polygon([(x,720),(x+120,720),(x+90,615),(x+68,661),(x+39,567),(x+10,630)],fill='#526777',outline='#243a50')
   d.line((x+39,583,x+57,681),fill='#81919b',width=3)
   for X,y in [(x+36,648),(x+62,685)]:d.polygon([(X,y-12),(X+7,y),(X,y+10),(X-7,y)],fill='#80aebb',outline='#b4d5d3')
  elif t in [1,8]:
   stone(d,(x+55,Y+40,x+78,720),'#52665d');d.line((x+63,Y+90,x+23,Y+135),fill='#687e65',width=9)
   for X,y,w in [(x,Y+5,130),(x+12,Y-27,100),(x+37,Y-48,66)]:d.ellipse((X,y,X+w,y+100),fill=mix('#638c71',floor,.3));d.arc((X+8,y+9,X+w-12,y+75),195,330,fill='#a1b690',width=3)
  elif t in [0,5,11]:
   stone(d,(x+12,Y+50,x+123,720),mix(wall,dark,.3));d.polygon([(x+5,Y+50),(x+65,Y),(x+130,Y+50)],fill=mix(wall,'#ddc9b0',.2),outline=dark)
   for X in range(x+23,x+115,27):
    for y in range(Y+75,700,43):stone(d,(X,y,X+13,y+20),dark);d.rectangle((X+3,y+3,X+10,y+15),fill='#e8d6a8')
   d.line((x+65,Y,x+65,Y-90),fill='#bcc7be',width=3);d.polygon([(x+67,Y-90),(x+114,Y-69),(x+67,Y-45)],fill='#caa5ae')
   if t==0:
    for y in [618,651,693]:d.line((x+4,y,x+90,y),fill='#a3c8c3',width=2)
  elif t==10:
   for X,Y2 in [(x+23,530),(x+66,450),(x+106,550)]:
    d.line((x+63,720,X,Y2),fill='#7699a4',width=11);d.line((X,Y2,X-20,Y2-39),fill='#a9a3be',width=9);d.line((X,Y2+20,X+30,Y2-13),fill='#caafb8',width=7)
   for n in range(8):
    X=x+r.randrange(130);y=r.randrange(270,710);d.ellipse((X,y,X+6,y+6),outline='#99c9ce',width=1)
  elif t==6:
   stone(d,(x+20,Y+36,x+119,720),'#af89a7');d.polygon([(x+10,Y+40),(x+65,Y),(x+131,Y+40)],fill='#e9b8ba',outline=dark)
   for X in [x+30,x+96]:d.rectangle((X,Y+49,X+13,720),fill='#ead0b8');d.line((X,Y+52,X+12,Y+80),fill='#cc95b0',width=4)
   d.ellipse((x+45,Y+70,x+86,Y+111),fill='#ffe7c2',outline='#b382a7',width=3)
  else:
   stone(d,(x+20,Y+30,x+120,720),mix(wall,dark,.25));d.polygon([(x+8,Y+32),(x+70,Y-14),(x+132,Y+32)],fill=wall,outline=dark)
   for y in range(Y+60,720,27):d.line((x+22,y,x+116,y),fill=mix(wall,dark,.45),width=2)
   for X in [x+36,x+82]:
    d.rectangle((X,Y+58,X+16,Y+93),fill=dark);d.arc((X,Y+49,X+16,Y+67),180,360,fill='#bda7c7',width=2);d.rectangle((X+5,Y+62,X+11,Y+88),fill='#c4a5bf' if t in [7,12] else '#cbbb9b')
 if t in [4,7,8,12]:
  for n in range(100):
   X=r.randrange(1280);y=r.randrange(720);c=['#f7c39a','#d2c5ed','#d5e9ab','#d2aeea'][[4,7,8,12].index(t)];d.rectangle((X,y,X+1,y+1),fill=c)
 # Foreground rail, hanging lanterns and varied silhouettes give each map a frame.
 for X in [24,1235]:
  stone(d,(X,190,X+16,720),mix(wall,dark,.2));d.line((X+8,190,X+45,205),fill=wall,width=4);stone(d,(X+32,205,X+51,242),dark);d.rectangle((X+36,210,X+47,236),fill='#ead6a6')
 im.save(R/f'background-detailed-{name}.png')
print('Redrew fourteen themes: 48×48 tile and decoration art, 1280×720 landscapes.')
