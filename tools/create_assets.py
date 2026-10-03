"""Original pixel icon and chiptune soundtrack. No downloaded art or samples."""
from pathlib import Path
import math, random, struct, wave
from PIL import Image, ImageDraw
ROOT = Path(__file__).resolve().parents[1]
im = Image.new('RGBA', (32, 32), '#15283f')
d = ImageDraw.Draw(im)
d.rectangle((3, 3, 28, 28), fill='#51d6d0')
d.ellipse((5, 4, 27, 27), fill='#132b4b')
d.ellipse((6, 5, 26, 26), fill='#60d9ff')
d.arc((8, 7, 24, 24), 15, 170, fill='#217dc2', width=3)
d.ellipse((10, 8, 15, 13), fill='#dbfffa')
d.rectangle((12, 16, 14, 19), fill='#132b4b')
d.rectangle((20, 16, 22, 19), fill='#132b4b')
d.rectangle((15, 22, 20, 23), fill='#ffffff')
im.resize((256,256),Image.Resampling.NEAREST).save(ROOT/'assets/icon.png')
SR=22050
rng=random.Random(31)
def save(name, data):
    with wave.open(str(ROOT/'assets/audio'/name),'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,x))*28000)) for x in data))
def freq(n): return 440*2**((n-69)/12)
beat=60/132
length=32*beat
samples=[0.0]*int(length*SR)
def note(start,dur,n,amp,kind='square'):
    for j in range(int(dur*SR)):
        k=int(start*SR)+j
        if k>=len(samples): break
        t=j/SR; ph=t*freq(n)
        v=(1 if ph%1<.25 else -1)*.55 if kind=='square' else 1-4*abs(ph%1-.5)
        env=min(1,t/.008)*max(0,1-t/dur)**.6
        samples[k]+=amp*v*env
melody=[76,79,83,79,81,79,76,74,72,76,79,76,74,72,71,74,76,79,84,83,81,79,76,79,77,81,79,77,76,74,72,74]
for i in range(64):
    note(i*beat/2,beat*.42,melody[i%32]+(0 if i<32 else 0),.17)
for b in range(32):
    root=[48,45,53,55][b//8]
    note(b*beat,beat*.8,root+(12 if b%2 else 0),.19,'tri')
    for j in range(int(.1*SR)):
        t=j/SR;k=int(b*beat*SR)+j
        if k<len(samples):
            samples[k]+=.18*math.sin(2*math.pi*(90*t-240*t*t))*math.exp(-t*40)
    if b%2:
        for j in range(int(.08*SR)):
            k=int(b*beat*SR)+j
            if k<len(samples): samples[k]+=.07*rng.uniform(-1,1)*math.exp(-j/SR*35)
save('boardwalk.wav',samples)
for name,dur,f0,f1 in [('place.wav',.15,450,850),('splash.wav',.38,150,40),('pickup.wav',.24,660,1320),('item.wav',.30,330,990),('win.wav',.7,520,1040),('trap.wav',.25,600,200)]:
    data=[]
    for j in range(int(dur*SR)):
        t=j/SR;phase=f0*t+(f1-f0)*t*t/(2*dur)
        tone=(1 if phase%1<.5 else -1)*.2
        if name=='splash.wav': tone=.45*rng.uniform(-1,1)+.15*math.sin(phase*math.tau)
        data.append(tone*(1-t/dur)**1.8*min(1,t/.005))
    save(name,data)
print('Created original icon, 14.5-second looping chiptune, and six sound effects.')
