"""Generate six original gameplay sound effects; leave music and bubble cues intact."""
from pathlib import Path
import math, random, struct, wave
ROOT = Path(__file__).resolve().parents[2]/'assets/audio/sfx'
ROOT.mkdir(parents=True,exist_ok=True)
SR=22050
rng=random.Random(31)
def save(name,data):
    with wave.open(str(ROOT/name),'wb') as w:
        w.setnchannels(1);w.setsampwidth(2);w.setframerate(SR)
        w.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,x))*28000)) for x in data))
for name,dur,f0,f1 in [('place.wav',.15,450,850),('splash.wav',.38,150,40),('pickup.wav',.24,660,1320),('item.wav',.30,330,990),('win.wav',.7,520,1040),('trap.wav',.25,600,200)]:
    data=[]
    for j in range(int(dur*SR)):
        t=j/SR;phase=f0*t+(f1-f0)*t*t/(2*dur)
        tone=(1 if phase%1<.5 else -1)*.2
        if name=='splash.wav': tone=.45*rng.uniform(-1,1)+.15*math.sin(phase*math.tau)
        data.append(tone*(1-t/dur)**1.8*min(1,t/.005))
    save(name,data)
print('Created six gameplay sound effects.')
