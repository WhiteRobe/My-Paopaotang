"""Draw original flare and carried-torch icons into the item atlas."""
from pathlib import Path
from PIL import Image,ImageDraw
p=Path(__file__).resolve().parents[1]/'assets/items.png';im=Image.open(p).convert('RGBA')
for kind in [26,27]:
 icon=Image.new('RGBA',(20,20));d=ImageDraw.Draw(icon)
 if kind==26:
  d.polygon([(4,9),(9,4),(16,11),(11,17)],fill='#263a50');d.polygon([(5,9),(9,5),(15,11),(11,16)],fill='#d49790');d.line((7,8,13,14),fill='#f8d4aa',width=2)
  d.line((14,7,17,4,16,2),fill='#f6d19f');d.rectangle((16,1,18,3),fill='#fff2bb');d.line((11,2,13,4),fill='#ffcba1');d.line((18,7,19,7),fill='#ffeab0')
 else:
  d.line((6,17,12,7),fill='#22334b',width=4);d.line((6,16,11,8),fill='#a58862',width=2);d.line((6,15,10,8),fill='#e1c99a')
  d.polygon([(8,8),(7,4),(10,5),(11,0),(15,3),(16,6),(13,10)],fill='#ee9d65');d.polygon([(10,7),(10,4),(12,5),(13,2),(14,6),(13,8)],fill='#ffe7a2');d.point((12,6),fill='#fff5d0')
 im.paste(icon,((kind%10)*20,(kind//10)*20))
im.save(p)
