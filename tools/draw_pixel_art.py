"""Hand-authored pixel illustrations: item atlas, characters, mounts, tiles and scenery."""
from pathlib import Path
from PIL import Image, ImageDraw
import random, math
ROOT=Path(__file__).resolve().parents[1]/'assets'
INK='#182840'; WHITE='#fff8dc'
def new(w,h):
    im=Image.new('RGBA',(w,h),(0,0,0,0));return im,ImageDraw.Draw(im)
def star(d,x,y,c=WHITE):
    d.polygon([(x,y-4),(x+1,y-1),(x+4,y-1),(x+2,y+1),(x+3,y+4),(x,y+2),(x-3,y+4),(x-2,y+1),(x-4,y-1),(x-1,y-1)],fill=c)
def bubble(d,box,c='#65d7ff'):
    d.ellipse(box,fill=INK);x,y,r,b=box;d.ellipse((x+1,y+1,r-1,b-1),fill=c);d.rectangle((x+3,y+2,x+5,y+3),fill='#eeffff')
def icon(kind):
    im,d=new(20,20)
    if kind==1:
        d.polygon([(3,3),(9,1),(16,3),(15,11),(9,18),(4,13)],fill=INK)
        d.polygon([(5,4),(9,3),(14,4),(13,10),(9,15),(6,11)],fill='#79dfb7')
        d.line((9,5,9,12),fill='#e9ffe1',width=2);d.line((6,8,12,8),fill='#e9ffe1',width=2)
    elif kind in [2,6,7]:
        c={2:'#ffe17b',6:'#a8ef78',7:'#ffc58a'}[kind]
        d.polygon([(6,2),(13,2),(13,10),(17,12),(18,16),(4,16),(3,12),(6,10)],fill=INK)
        d.polygon([(7,3),(12,3),(12,11),(16,13),(16,14),(5,14),(5,12),(7,11)],fill=c)
        d.rectangle((5,15,17,17),fill='#f8f2d2');d.line((8,5,11,5),fill=WHITE);d.line((8,8,11,8),fill=WHITE)
        if kind==2:
            for y in [5,8,11]:d.line((0,y,4,y),fill='#e4fcff')
        if kind==6:
            d.rectangle((14,3,18,5),fill=WHITE);d.rectangle((16,1,17,7),fill=WHITE)
        if kind==7:d.polygon([(1,2),(5,4),(4,8),(2,9),(2,5)],fill=WHITE)
    elif kind==3:
        d.line((10,5,14,1),fill=INK,width=2);d.ellipse((13,0,16,3),fill='#cfacff')
        d.rounded_rectangle((4,4,15,18),radius=2,fill=INK);d.rectangle((5,5,14,16),fill='#9b7dd4')
        d.rectangle((7,7,12,9),fill='#baffca');d.ellipse((8,11,11,14),fill='#ff879a');d.rectangle((7,16,12,17),fill='#e7ceff')
    elif kind==4:
        bubble(d,(0,5,11,16));bubble(d,(8,1,19,12));bubble(d,(8,10,18,19));d.rectangle((12,13,15,16),fill=WHITE)
    elif kind==5:
        d.polygon([(10,1),(5,8),(3,12),(3,16),(7,19),(12,19),(16,16),(16,12),(14,8)],fill=INK)
        d.polygon([(10,3),(6,9),(5,12),(5,15),(8,17),(12,17),(14,15),(14,12)],fill='#78dfff')
        d.line((8,8,6,12),fill=WHITE,width=2);d.line((1,5,4,7),fill='#ffc285');d.line((16,6,19,3),fill='#ffc285')
    elif kind==8:
        bubble(d,(1,1,18,18),'#95b6ff');star(d,10,10,'#ffe888');d.point((17,0),fill=WHITE);d.point((0,15),fill=WHITE)
    elif kind==9:
        d.line((3,17,14,6),fill=INK,width=3);d.line((4,16,14,6),fill='#d9f6ff',width=2)
        d.ellipse((11,0,18,7),fill=INK);d.ellipse((12,1,17,6),fill='#eea9d5');d.ellipse((14,2,16,4),fill=INK)
    elif kind==10:
        d.polygon([(7,2),(12,2),(16,8),(18,17),(12,18),(9,16),(5,18),(1,16),(4,8)],fill=INK)
        d.polygon([(8,3),(11,3),(14,8),(16,15),(12,16),(9,13),(6,16),(3,15),(6,8)],fill='#9779cd')
        d.line((8,7,5,14),fill='#ceb2ff',width=2);d.ellipse((8,2,11,5),fill='#fff2b2')
    elif kind==11:
        d.ellipse((3,3,16,16),fill=INK);d.ellipse((4,4,15,15),fill='#69e9e4')
        d.polygon([(11,2),(6,10),(10,10),(7,18),(15,8),(11,8)],fill=WHITE)
        d.line((0,10,2,10),fill='#f5ffcd');d.line((17,6,19,6),fill='#f5ffcd')
    elif kind==12:
        d.ellipse((2,2,17,17),fill=INK);d.ellipse((3,3,16,16),fill='#78bfea')
        for a,b in [((9,4),(9,15)),((4,7),(15,12)),((4,12),(15,7))]:d.line((*a,*b),fill='#eeffff',width=2)
        for x,y in [(9,4),(9,15),(4,7),(15,12),(4,12),(15,7)]:d.point((x,y),fill=WHITE)
    elif kind==13:
        d.rectangle((4,7,15,15),fill=INK);d.rectangle((5,8,14,14),fill='#ffe7bf')
        d.rectangle((3,3,16,8),fill='#ff9abd');d.rectangle((6,1,13,4),fill='#ff9abd')
        d.rectangle((6,9,7,11),fill=INK);d.rectangle((12,9,13,11),fill=INK)
        d.rectangle((6,15,13,18),fill='#ac7db9');d.rectangle((4,17,6,19),fill=INK);d.rectangle((13,17,15,19),fill=INK)
    elif kind==14:
        d.arc((2,2,17,18),0,180,fill=INK,width=6);d.arc((3,3,16,17),0,180,fill='#f27482',width=4)
        d.rectangle((2,2,7,9),fill=INK);d.rectangle((3,3,6,9),fill='#ff8592');d.rectangle((12,2,17,9),fill=INK);d.rectangle((13,3,16,9),fill='#ff8592')
        d.rectangle((3,2,6,5),fill=WHITE);d.rectangle((13,2,16,5),fill=WHITE)
        d.line((8,1,9,4),fill='#ffe595');d.line((10,3,12,0),fill='#ffe595')
    elif kind==15:
        d.ellipse((3,2,16,18),fill=INK);d.ellipse((4,3,15,17),fill='#ecffd4')
        for box in [(6,5,8,7),(11,8,14,11),(6,12,9,15)]:d.ellipse(box,fill='#91dcad')
        d.line((5,5,6,4),fill=WHITE)
    elif kind==16:
        d.polygon([(2,7),(6,4),(14,4),(18,7),(16,15),(12,18),(8,18),(3,15)],fill=INK)
        d.polygon([(4,8),(7,6),(13,6),(16,8),(14,13),(10,15),(6,13)],fill='#cf9862')
        d.rectangle((5,6,14,8),fill='#ffe1a7');d.line((5,11,3,16),fill='#ffe1a7',width=2);d.line((14,11,16,16),fill='#ffe1a7',width=2)
        star(d,10,5,'#fff49e')
    elif kind==17:
        star(d,5,6,'#e0b4ff');star(d,14,13,'#91e7ff')
        d.line((10,3,16,3),fill=WHITE);d.line((16,3,16,7),fill=WHITE);d.line((16,7,18,5),fill=WHITE)
        d.line((9,17,3,17),fill=WHITE);d.line((3,17,3,12),fill=WHITE);d.line((3,12,1,14),fill=WHITE)
    elif kind==18:
        d.rectangle((5,2,14,5),fill=INK);d.rectangle((7,3,12,4),fill='#efc196')
        d.rounded_rectangle((2,5,17,18),radius=2,fill=INK);d.rectangle((3,6,16,16),fill='#fff2da');d.rectangle((3,15,16,17),fill='#ddc7af')
        d.rectangle((8,8,11,14),fill='#ee7587');d.rectangle((6,10,13,12),fill='#ee7587')
    elif kind==19:
        d.ellipse((2,1,17,18),fill='#7e582f');d.ellipse((3,2,16,17),fill='#ffc958');d.ellipse((5,4,14,15),fill='#ffe89b');star(d,10,10,'#dc9d37')
    return im
atlas,_=new(200,40)
for kind in range(1,20):atlas.alpha_composite(icon(kind),((kind%10)*20,(kind//10)*20))
atlas.save(ROOT/'items.png')

PALETTES=[('#64baa9','#4d97a1','#d7ae79'),('#76a56e','#47724e','#bb8955'),('#b4d8e2','#72a5c5','#b6caed'),('#dfba79','#bd945e','#cf9563'),('#745563','#40394d','#a06556'),('#608c9b','#425e79','#c68d58'),('#e7aac1','#c786b4','#e6ba83'),('#655b99','#464b7d','#8e8ac5')]
tiles,_=new(120,160)
for theme,(floor,wall,crate) in enumerate(PALETTES):
    r=random.Random(401+theme)
    for kind in range(6):
        im,d=new(20,20);d.rectangle((0,0,19,19),fill=floor)
        d.line((0,19,19,19),fill=wall);d.line((19,0,19,19),fill=wall)
        if kind in [0,1]:
            if theme in [0,5,7]:
                d.line((1,1,18,1),fill='#97c6c1' if theme==0 else '#8797b3')
                if kind==1:d.rectangle((3,13,4,14),fill=wall);d.rectangle((14,5,15,6),fill=wall)
                if theme==5:d.line((2,6,17,6),fill='#6e9eac');d.rectangle((3,3,4,4),fill='#b1cbd0')
                if theme==7:d.point((5,6),fill='#b3b0ed');d.line((11,14,15,14),fill='#8883bc')
            elif theme==1:
                for x,y in [(3,6),(12,15),(16,4)]:d.line((x,y,x+1,y-3),fill='#5a895b');d.point((x-1,y-2),fill='#a2c785')
                if kind==1:d.rectangle((7,5,8,6),fill='#f4cbb5')
            elif theme==2:
                d.line((3,6,7,5),fill='#eff9ff');d.line((12,14,17,13),fill='#eff9ff');d.point((8,17),fill='#799ec7')
            elif theme==3:
                d.line((2,5,6,5),fill='#f0d59c');d.line((10,14,16,14),fill='#caa263')
                for n in range(4):d.point((r.randrange(2,18),r.randrange(2,18)),fill='#ac8953')
            elif theme==4:
                d.line((4,0,7,7,4,12),fill='#ad6a66');d.line((10,14,15,10,19,12),fill='#574657')
                if kind==1:d.point((7,6),fill='#ffc074')
            elif theme==6:
                d.rectangle((1,1,18,18),outline='#f4c9d7');d.point((5,7),fill='#fff2cb');d.point((13,13),fill='#fff2cb')
        elif kind==2:
            d.rectangle((1,3,18,19),fill=INK)
            if theme==1:
                d.rectangle((7,9,12,18),fill='#936744');d.ellipse((1,0,18,14),fill='#345c48');d.ellipse((3,0,16,11),fill='#5b975f');d.rectangle((5,3,9,4),fill='#9dc480')
            elif theme==3:
                d.rectangle((7,3,12,18),fill='#61895b');d.rectangle((3,8,7,11),fill='#61895b');d.rectangle((3,4,5,10),fill='#7eab69');d.rectangle((12,10,16,13),fill='#61895b');d.rectangle((14,6,16,12),fill='#7eab69');d.line((9,4,9,15),fill='#a2bd7b')
            elif theme==6:
                d.rectangle((2,2,17,17),fill=wall);d.rectangle((3,3,16,15),fill='#f3c3dc')
                for x in [5,10,15]:d.line((x,4,x,14),fill='#ca86ad')
                d.line((4,8,15,8),fill='#ca86ad');d.line((4,12,15,12),fill='#ca86ad')
            else:
                d.rectangle((2,1,17,16),fill=wall);d.line((3,2,16,2),fill='#b5c7d3' if theme!=4 else '#8b7081')
                if theme==2:d.rectangle((2,0,17,4),fill='#eefaff');d.rectangle((4,4,5,7),fill='#c8eeff')
                elif theme==5:
                    for x,y in [(4,4),(14,4),(4,13),(14,13)]:d.rectangle((x,y,x+1,y+1),fill='#b4c9c5')
                    d.line((4,8,15,8),fill='#273f5d')
                elif theme==7:d.rectangle((5,4,14,12),outline='#8b8cc7');d.rectangle((8,6,11,9),fill='#c3b7fa')
                elif theme==4:d.line((6,2,9,7,7,12),fill='#c9836e');d.point((8,9),fill='#ffc992')
                else:d.line((2,8,17,8),fill='#38697d');d.line((10,2,10,7),fill='#38697d')
        elif kind==3:
            d.rectangle((2,4,17,18),fill=INK);d.rectangle((2,2,17,15),fill=crate)
            if theme in [0,1]:
                for y in [6,10,14]:d.line((3,y,16,y),fill='#9d7350')
                d.rectangle((4,3,6,14),fill='#f3cd91');d.rectangle((13,3,15,14),fill='#f3cd91')
            elif theme==2:d.rectangle((3,2,16,5),fill='#f3fcff');d.rectangle((5,7,14,12),outline='#dce9ff')
            elif theme==3:d.ellipse((3,2,16,17),fill=crate);d.rectangle((5,2,14,4),fill='#efd4a1');d.line((4,9,15,9),fill='#a86c4e')
            elif theme==4:d.rectangle((4,4,15,13),outline='#dfac83');d.line((4,9,14,7),fill='#744750')
            elif theme==5:
                d.rectangle((4,3,15,15),fill='#b48764');d.rectangle((4,4,15,6),fill='#eac17d');d.rectangle((4,12,15,14),fill='#eac17d');d.rectangle((8,8,11,10),fill='#5d6275')
            elif theme==6:
                d.rectangle((3,3,16,14),fill='#f0c5a4')
                for x,y in [(5,6),(13,5),(9,10),(14,12)]:d.rectangle((x,y,x+1,y+1),fill='#956e65')
            else:d.rectangle((4,4,15,13),fill='#b0a2df');d.line((5,6,14,11),fill='#e2ceff');d.rectangle((8,7,10,9),fill='#7d66b0')
        elif kind==4:
            d.rectangle((0,0,19,19),fill='#3c70a7' if theme!=4 else '#d56356')
            for y in [5,13]:d.line((2,y,8,y,10,y-1,16,y-1),fill='#88d7e9' if theme!=4 else '#ffc88b')
        else:
            if theme==1:d.rectangle((7,9,11,17),fill='#eee0bc');d.ellipse((2,3,17,12),fill='#ef8995');d.rectangle((5,6,7,7),fill=WHITE);d.rectangle((12,5,14,6),fill=WHITE)
            elif theme==6:d.rectangle((9,9,10,19),fill='#ead0a8');d.ellipse((3,1,17,14),fill='#f589b5');d.arc((5,3,15,12),0,280,fill='#ffe4c6',width=2)
            else:d.ellipse((5,5,15,15),fill=crate);d.rectangle((8,2,11,5),fill=WHITE)
        tiles.alpha_composite(im,(kind*20,theme*20))
tiles.save(ROOT/'tiles.png')

colors=['#62ceff','#ff8bad','#8bf2be','#ffcf6c','#d3e9ff','#baa2ff','#88d6d8','#ff9570']
chars,_=new(160,288)
for n,c in enumerate(colors):
 for direction in range(4):
  for step in range(3):
    im,d=new(20,24)
    foot=1 if step==1 else (-1 if step==2 else 0)
    # Distinct silhouettes: sailor, rabbit, frog, fox, polar bear, wizard, robot, fire spirit.
    if n==0:
        d.rectangle((4,12,15,19),fill=INK);d.rectangle((5,13,14,18),fill='#286ab1')
        d.ellipse((3,3,16,15),fill=INK);d.ellipse((4,4,15,14),fill='#ffe2bf')
        d.rectangle((3,2,16,6),fill=c);d.rectangle((5,0,14,3),fill=WHITE);d.rectangle((3,5,16,6),fill='#244e83')
        d.rectangle((7,13,12,14),fill=WHITE);d.polygon([(8,14),(11,14),(10,17)],fill='#f3ad67')
    elif n==1:
        d.rectangle((3,0,6,7),fill=INK);d.rectangle((12,0,15,7),fill=INK)
        d.rectangle((4,0,5,7),fill='#ffb8d1');d.rectangle((13,1,14,7),fill='#ffb8d1')
        d.ellipse((2,5,17,17),fill=INK);d.ellipse((3,6,16,16),fill=c)
        d.ellipse((5,9,14,16),fill='#fff2dd');d.polygon([(5,15),(14,15),(17,21),(3,21)],fill='#e55e94')
        d.rectangle((5,19,14,20),fill='#ffd9e8');star(d,16,7,'#fff19c')
    elif n==2:
        d.ellipse((2,2,8,9),fill='#45a979');d.ellipse((11,2,17,9),fill='#45a979')
        d.rectangle((4,3,6,5),fill=WHITE);d.rectangle((13,3,15,5),fill=WHITE)
        d.ellipse((2,5,17,16),fill=INK);d.ellipse((3,6,16,15),fill=c)
        d.ellipse((5,9,14,15),fill='#e9ffd3');d.ellipse((4,14,15,21),fill='#438f77')
        d.rectangle((8,16,11,19),fill='#d3ef9a');d.line((5,8,8,8),fill='#3a8466')
    elif n==3:
        d.polygon([(2,8),(2,1),(8,5),(12,5),(17,1),(17,9)],fill=INK)
        d.polygon([(3,8),(3,2),(8,6),(12,6),(16,2),(16,10)],fill=c)
        d.ellipse((3,5,16,15),fill=c);d.polygon([(4,10),(9,8),(15,10),(12,15),(7,15)],fill=WHITE)
        d.ellipse((5,14,14,21),fill='#cb8541');d.polygon([(14,18),(19,14),(18,21),(13,21)],fill=c)
        d.rectangle((17,16,18,18),fill=WHITE);d.rectangle((6,14,13,16),fill='#ef6c6a')
    elif n==4:
        d.ellipse((1,3,7,9),fill=INK);d.ellipse((12,3,18,9),fill=INK)
        d.ellipse((2,4,6,8),fill='#accce3');d.ellipse((13,4,17,8),fill='#accce3')
        d.ellipse((2,5,17,17),fill=INK);d.ellipse((3,6,16,16),fill='#effbff')
        d.ellipse((6,10,13,16),fill='#b9dbea');d.ellipse((3,15,16,22),fill='#d3e9ff')
        d.rectangle((3,15,16,17),fill='#708ac7');d.rectangle((12,17,14,20),fill='#9eade7')
    elif n==5:
        d.polygon([(2,10),(9,0),(12,1),(17,10)],fill=INK)
        d.polygon([(3,9),(9,1),(11,2),(16,9)],fill=c);star(d,10,5,'#fff09b')
        d.rectangle((2,9,17,11),fill='#715498');d.rectangle((5,11,14,16),fill='#ffdfbf')
        d.polygon([(5,15),(14,15),(18,22),(2,22)],fill='#7860b1');d.rectangle((8,16,11,20),fill='#cbb0f2')
        d.line((17,12,17,21),fill='#e9c581');d.rectangle((16,12,18,14),fill='#bbf6ee')
    elif n==6:
        d.rectangle((9,0,10,4),fill='#a6c1c5');d.rectangle((8,0,11,1),fill='#ffc07b')
        d.rectangle((2,4,17,14),fill=INK);d.rectangle((3,5,16,13),fill=c)
        d.rectangle((4,7,15,11),fill='#26445c');d.rectangle((5,8,7,9),fill='#e2ffa4');d.rectangle((12,8,14,9),fill='#e2ffa4')
        d.rectangle((1,7,2,11),fill='#e6d7a5');d.rectangle((17,7,18,11),fill='#e6d7a5')
        d.rectangle((4,15,15,20),fill=INK);d.rectangle((5,16,14,19),fill='#589baa');d.rectangle((8,16,11,18),fill='#fbb589')
    else:
        d.polygon([(2,15),(4,8),(7,1),(10,7),(13,0),(16,8),(18,14),(15,21),(5,21)],fill=INK)
        d.polygon([(3,14),(5,9),(7,3),(10,9),(13,2),(15,9),(17,14),(14,20),(6,20)],fill='#f28367')
        d.polygon([(5,15),(8,8),(11,13),(13,10),(15,16),(12,21),(8,21)],fill='#ffd684')
    if n!=6:
        if direction==1:
            # Rear view retains headgear and silhouette, with no face floating on the back.
            d.rectangle((6,9,13,12),fill=c if n!=0 else '#cc9c7d')
        else:
            eye_x=[6,12] if direction==0 else ([5,10] if direction==2 else [9,14])
            for x in eye_x:d.rectangle((x,10,x+1,11),fill=INK)
            mouth=9 if direction==0 else (7 if direction==2 else 11)
            d.point((mouth,13),fill='#9a5365')
    elif direction==1:d.rectangle((4,7,15,11),fill='#589baa');d.line((6,8,13,8),fill='#b3e5e6')
    # Alternating legs and arms supply a three-pose cycle for every direction.
    if n!=7:
        d.rectangle((4,20+max(0,foot),7,22+min(0,foot)),fill=INK)
        d.rectangle((12,20+max(0,-foot),15,22+min(0,-foot)),fill=INK)
        d.rectangle((2,15+foot,3,17+foot),fill=c);d.rectangle((16,15-foot,17,17-foot),fill=c)
    else:
        d.point((2,5+step),fill='#ffc784');d.point((17,3+step),fill='#ffdba0')
    chars.alpha_composite(im,(n*20,(direction*3+step)*24))
chars.save(ROOT/'characters.png')
mounts,_=new(96,28)
for n in range(1,4):
    im,d=new(32,28)
    d.ellipse((3,20,28,26),fill='#24495b')
    if n==1:
        d.ellipse((4,12,27,24),fill=INK);d.ellipse((5,12,26,22),fill='#ffe18a');d.rectangle((9,23,13,25),fill='#edaa62');d.rectangle((21,23,25,25),fill='#edaa62')
        d.ellipse((19,6,30,18),fill='#ffe18a');d.rectangle((25,11,26,12),fill=INK);d.rectangle((28,13,31,15),fill='#efad69');d.arc((8,14,21,21),0,180,fill='#e8b971',width=2)
    elif n==2:
        d.ellipse((4,10,26,23),fill=INK);d.ellipse((5,10,25,21),fill='#7cc592');d.ellipse((9,11,22,20),fill='#507c67');d.polygon([(15,11),(20,14),(18,19),(12,19),(10,14)],outline='#a6e2ab')
        d.ellipse((24,13,31,21),fill='#b7e3a1');d.point((28,16),fill=INK);d.rectangle((7,22,11,25),fill='#b7e3a1');d.rectangle((19,22,23,25),fill='#b7e3a1')
    else:
        d.ellipse((4,13,25,24),fill=INK);d.ellipse((5,13,24,22),fill='#f5c9df');d.ellipse((19,8,30,20),fill='#f5c9df');d.rectangle((21,0,24,10),fill='#f5c9df');d.rectangle((27,2,30,11),fill='#f5c9df');d.rectangle((22,2,23,7),fill='#dfa4c5');d.rectangle((28,4,29,9),fill='#dfa4c5')
        d.rectangle((25,12,26,13),fill=INK);d.rectangle((29,15,31,16),fill='#c784a8');d.ellipse((4,10,9,16),fill=WHITE);d.rectangle((8,23,13,25),fill='#dfacc9');d.rectangle((20,22,25,24),fill='#dfacc9')
    mounts.alpha_composite(im,((n-1)*32,0))
mounts.save(ROOT/'mounts.png')

for theme,name in enumerate(['harbor','forest','frost','desert','volcano','factory','candy','cosmos']):
    r=random.Random(751+theme);im=Image.new('RGB',(640,360),['#173948','#233e3d','#263e57','#473b43','#412d43','#243846','#493347','#27243e'][theme]);d=ImageDraw.Draw(im)
    if theme in [0,2,3,4]:
        for n in range(6):
            x=n*130-60;peak=35+r.randrange(35)
            d.polygon([(x,185),(x+65,peak),(x+140,185)],fill=['#245768','#3c657d','#79534c','#663c4b'][[0,2,3,4].index(theme)])
            if theme==2:d.polygon([(x+36,peak+55),(x+65,peak),(x+90,peak+55),(x+67,peak+43)],fill='#8aacbd')
            if theme==4:d.polygon([(x+50,peak+25),(x+65,peak),(x+80,peak+25)],fill='#d08866')
    if theme==0:
        for y in range(194,360,12):
            for x in range(0,640,50):d.line((x+(y%24),y,x+25+(y%24),y),fill='#285b6b')
        d.rectangle((20,120,38,198),fill='#67969c');d.rectangle((18,114,40,123),fill='#c3a288');d.polygon([(18,113),(29,104),(40,113)],fill='#c3a288')
        d.polygon([(590,180),(635,180),(624,193),(600,193)],fill='#4b7480');d.line((610,132,610,179),fill='#b3ab93');d.polygon([(613,132),(631,166),(613,166)],fill='#7e9ba3')
    elif theme==1:
        for x in range(0,640,52):
            d.rectangle((x+17,220,x+27,360),fill='#3c5345');d.ellipse((x-8,160,x+52,238),fill='#375d47');d.ellipse((x,155,x+42,213),fill='#497653')
        for n in range(80):
            x=r.randrange(640);y=r.randrange(330,359);d.point((x,y),fill=r.choice(['#c8b788','#71977a','#9e7991']))
    elif theme==2:
        for x in range(0,640,65):d.polygon([(x,315),(x+20,242),(x+40,315)],fill='#3c6a78');d.polygon([(x+10,279),(x+20,242),(x+30,279)],fill='#afc8d5')
        for n in range(85):
            x=r.randrange(640);y=r.randrange(360);d.rectangle((x,y,x+1,y+1),fill='#7998b6')
    elif theme==3:
        for y in [230,280,335]:
            d.polygon([(0,y),(150,y-25),(320,y+4),(490,y-24),(640,y),(640,360),(0,360)],fill=['#5b4245','#6b4a48','#785249'][[230,280,335].index(y)])
        d.ellipse((560,44,602,86),fill='#b88868')
    elif theme==4:
        for n in range(22):
            x=r.randrange(640);y=r.randrange(260,360);d.line((x,y,x+10,y-6,x+15,y+5),fill='#a45c58',width=2)
        for n in range(55):d.point((r.randrange(640),r.randrange(360)),fill='#a67a60')
    elif theme==5:
        for x in range(0,640,60):
            h=r.randrange(35,85);d.rectangle((x,245-h,x+45,360),fill='#354956');d.rectangle((x+10,210-h,x+18,245-h),fill='#526573')
            for y in range(250-h,320,20):d.rectangle((x+8,y,x+13,y+4),fill='#808d79')
        for x in range(0,640,40):d.polygon([(x,350),(x+18,330),(x+30,330),(x+12,350)],fill='#8d8463')
    elif theme==6:
        for x in range(-30,640,105):
            d.ellipse((x,220,x+130,405),fill=r.choice(['#785a73','#8b647b','#77657c']));d.rectangle((x+48,170,x+54,250),fill='#a8828a');d.ellipse((x+28,137,x+75,185),fill='#aa718b');d.arc((x+35,145,x+68,175),0,300,fill='#d1a191',width=3)
        for n in range(50):d.rectangle((r.randrange(640),r.randrange(360),r.randrange(640),r.randrange(360)),fill=None) if False else None
    else:
        for n in range(140):
            x=r.randrange(640);y=r.randrange(360);d.rectangle((x,y,x+(n%2),y+(n%2)),fill=r.choice(['#746e9c','#9695b7','#c2b7cb']))
        d.ellipse((525,50,600,125),fill='#615b85');d.ellipse((540,58,558,76),fill='#7f78a1');d.ellipse((560,85,580,105),fill='#494569');d.arc((500,72,625,105),0,360,fill='#a2a0bd',width=2)
    im.save(ROOT/f'background-{name}.png')
print('Created 19 illustrated items, 8 characters, 3 mounts, 48 tiles and 8 themed landscapes.')
