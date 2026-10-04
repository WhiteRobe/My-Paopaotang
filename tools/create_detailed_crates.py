"""Original theme-specific wooden, movable, reinforced and 2x2 vault crate sprites."""
from pathlib import Path
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1]/'assets'
import random,math
class DetailedDraw:
 def __init__(self,im,factor):self.canvas=ImageDraw.Draw(im);self.factor=factor
 def __getattr__(self,name):
  def draw(coords,*args,**kwargs):
   def scale(v):return tuple(scale(x) for x in v) if isinstance(v,(tuple,list)) else round(v*self.factor)
   if 'width' in kwargs:kwargs['width']=max(1,round(kwargs['width']*self.factor))
   return getattr(self.canvas,name)(scale(coords),*args,**kwargs)
  return draw
INK='#182840';WHITE='#fff2d4'
colors=['#d8ad76','#b29168','#b7d9e8','#d1a773','#b47b68','#b79261','#e9b4c4','#a399cd','#b2a27b','#c3b188','#cdaca9','#cbb78d','#aa8ead','#84969b']
singles=Image.new('RGBA',(144,len(colors)*144));vaults=Image.new('RGBA',(288,len(colors)*96))
for theme,c in enumerate(colors):
 for state in range(3):
  for kind in range(3):
   im=Image.new('RGBA',(48,48));d=DetailedDraw(im,2.4)
   d.rectangle((1,3,18,19),fill=INK);d.rectangle((2,1,17,16),fill=c);d.rectangle((3,2,16,15),outline='#f1d3a4')
   if kind==0:
    for y in [6,11]:d.line((3,y,16,y),fill='#806856')
    d.line((4,3,14,14),fill='#a18465',width=2);d.line((5,3,15,13),fill='#dfc195')
   elif kind==1:
    d.rectangle((2,3,17,6),fill='#78959c');d.rectangle((2,12,17,15),fill='#78959c');d.rectangle((3,4,16,5),fill='#c2d9d4')
    d.polygon([(4,9),(7,7),(7,11)],fill=WHITE);d.polygon([(15,9),(12,7),(12,11)],fill=WHITE)
    for x in [5,14]:d.ellipse((x-2,16,x+2,19),fill='#3c586c')
   else:
    d.rectangle((2,2,17,16),fill='#75828f');d.rectangle((5,3,14,15),fill=c)
    d.rectangle((2,2,17,4),fill='#b9c3c7');d.rectangle((2,13,17,15),fill='#b9c3c7')
    d.rectangle((8,7,11,10),fill='#5d667c');d.point((9,8),fill='#fff0b9')
    for x,y in [(3,6),(16,6),(3,12),(16,12)]:d.point((x,y),fill='#e6e4d4')
   if state>0:
    d.line((8,2,10,6,7,9,10,12,8,16),fill=INK,width=1);d.line((10,6,14,7),fill=INK)
    if state==2:d.line((2,10,6,11,8,9),fill=INK);d.rectangle((11,12,14,14),fill='#78635d')
   detail=ImageDraw.Draw(im);r=random.Random(theme*50+kind*7+state)
   if kind==0:
    for n in range(14):
     x=r.randrange(10,37);y=r.randrange(8,34);detail.line((x,y,x+r.randrange(2,6),y),fill='#b59a76')
   else:
    for x,y in [(8,14),(38,14),(8,30),(38,30)]:detail.ellipse((x-2,y-2,x+2,y+2),fill='#dee0d9',outline='#4f6074');detail.point((x-1,y-1),fill='#fff5d7')
    detail.line((13,7,34,7),fill='#e6e9db')
   if theme in [2,7,10,12]:
    detail.polygon([(24,17),(29,23),(24,29),(19,23)],outline=['#d9eef7','#cdbbff','#f4c5d1','#d3b1df'][[2,7,10,12].index(theme)])
   singles.alpha_composite(im,(kind*48,(theme*3+state)*48))
  im=Image.new('RGBA',(96,96));d=DetailedDraw(im,2.4)
  d.rectangle((1,5,38,39),fill=INK);d.rectangle((2,2,37,34),fill='#625a79');d.rectangle((4,4,35,32),fill=c)
  for x in [3,32]:d.rectangle((x,3,x+4,33),fill='#e0bf7e');d.line((x+1,5,x+1,31),fill='#fff0b7')
  for y in [3,28]:d.rectangle((3,y,36,y+4),fill='#e0bf7e');d.line((5,y+1,34,y+1),fill='#fff0b7')
  d.rectangle((15,13,25,24),fill='#6b5a73');d.rectangle((16,11,24,16),outline='#ffe3a0',width=2)
  d.polygon([(20,15),(24,19),(20,23),(16,19)],fill='#c8b6ff');d.rectangle((19,17,20,20),fill='#fff5d1')
  for x,y in [(7,8),(30,8),(7,27),(30,27)]:d.rectangle((x,y,x+2,y+2),fill='#fff0b7')
  if state>0:
   d.line((10,5,12,12,9,17,12,24,10,31),fill=INK,width=2);d.line((28,7,26,13,29,19,26,25),fill=INK,width=2)
   if state==2:d.line((5,24,11,23,17,28,25,27,34,30),fill=INK,width=2);d.rectangle((5,15,8,20),fill='#736079')
  detail=ImageDraw.Draw(im)
  for x in [17,78]:
   for y in [23,63]:detail.ellipse((x-3,y-3,x+3,y+3),fill='#fff0b7',outline='#9b795a');detail.point((x-1,y-1),fill='#ffffff')
  for x in [29,65]:detail.line((x,24,x+3,27,x,30,x-3,27,x,24),fill='#e5cc99',width=1)
  detail.arc((38,38,57,55),190,300,fill='#fff5e8',width=2);detail.line((45,48,50,48),fill='#c7a4e5')
  vaults.alpha_composite(im,(state*96,theme*96))
singles.save(ROOT/'crates-detailed.png');vaults.save(ROOT/'vault-crates-detailed.png')
print('Created unique skins and three damage states for all fourteen map themes.')
