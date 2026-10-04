"""Original round cues and layered liquid rupture, generated without samples."""
from pathlib import Path
import math,random,struct,wave
R=Path(__file__).resolve().parents[1]/'assets/audio';RATE=44100

def write(name,values):
 peak=max(max(abs(v) for v in values),1)
 with wave.open(str(R/(name+'.wav')),'wb') as f:
  f.setnchannels(1);f.setsampwidth(2);f.setframerate(RATE)
  f.writeframes(b''.join(struct.pack('<h',round(v/peak*30000)) for v in values))

def tone(t,f):return math.sin(math.tau*f*t)+.16*math.sin(math.tau*f*2*t)

rng=random.Random(472);samples=[]
for n in range(round(.38*RATE)):
 t=n/RATE
 # Membrane snap, deep descending plop, then three sparkling droplets.
 phase=math.tau*(110*t+(980-110)*(.014)*(1-math.exp(-t/.014)))
 v=.85*math.sin(phase)*math.exp(-t*23)*(1-math.exp(-t*900))
 v+=rng.uniform(-1,1)*.30*math.exp(-t*160)
 for delay,freq in [(.055,1050),(.095,1480),(.15,1900)]:
  u=t-delay
  if u>=0:v+=.12*tone(u,freq)*math.exp(-u*42)*(1-math.exp(-u*650))
 samples.append(v)
write('bubble-pop',samples)

for name,duration in [('round-ready',2.5),('round-urgent',32.)]:
 samples=[]
 for n in range(round(duration*RATE)):
  t=n/RATE;v=0.
  if name=='round-ready':
   for start,freq in [(0,523.25),(.7,659.25),(1.4,783.99),(2.1,1046.5)]:
    u=t-start
    if 0<=u<.4:v+=.35*tone(u,freq)*math.exp(-u*11)*(1-math.exp(-u*500))
  else:
   beat=.25;idx=int(t/beat);u=t%beat
   notes=[130.81,155.56,196.,174.61,130.81,155.56,233.08,196.]
   v+=.24*tone(u,notes[(idx//2)%8])*math.exp(-u*14)*(1-math.exp(-u*450))
   v+=.085*tone(u,notes[idx%8]*4)*math.exp(-u*24)
   if idx%2==0:v+=.22*math.sin(math.tau*(52*u+9*(1-math.exp(-u*30))))*math.exp(-u*28)
   v+=rng.uniform(-1,1)*.035*math.exp(-u*70)
  samples.append(v)
 write(name,samples)
print('Created stronger bubble pop, ready cue and 32-second urgent loop.')
