"""Compose short original bubble capture/pop sounds without external samples."""
from pathlib import Path
import math, random, struct, wave
ROOT=Path(__file__).resolve().parents[2]/'assets/audio/sfx'
rate=44100
for name,duration,start,end in [('bubble-trap',.23,640,145),('bubble-pop',.16,860,105)]:
    rng=random.Random(71 if name=='bubble-pop' else 43)
    phase=0.;samples=[]
    for n in range(round(duration*rate)):
        t=n/rate;progress=t/duration
        frequency=end+(start-end)*math.exp(-progress*8)
        phase+=2*math.pi*frequency/rate
        attack=min(1,t/.003)
        envelope=attack*math.exp(-progress*6)*(1-progress)
        liquid=math.sin(phase)+.22*math.sin(phase*1.98)
        transient=rng.uniform(-1,1)*math.exp(-t*310)*(.4 if name=='bubble-pop' else .12)
        samples.append(max(-1,min(1,.7*envelope*liquid+transient)))
    with wave.open(str(ROOT/(name+'.wav')),'wb') as out:
        out.setnchannels(1);out.setsampwidth(2);out.setframerate(rate)
        out.writeframes(b''.join(struct.pack('<h',round(x*26000)) for x in samples))
print('Created original bubble capture and rupture audio.')
