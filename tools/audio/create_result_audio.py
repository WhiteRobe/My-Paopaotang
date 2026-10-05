"""Compose original victory and defeat stingers without replacing existing music."""
from pathlib import Path
import math, struct, wave
RATE=44100
ROOT=Path(__file__).resolve().parents[2]/'assets/audio/cues'
for name,notes in [('victory',[60,64,67,72,76,79,76,72]),('defeat',[64,62,59,57,55,52,50,48])]:
 duration=5.5
 values=[]
 for n in range(int(duration*RATE)):
  t=n/RATE;v=0.0
  for i,note in enumerate(notes):
   u=t-i*.38
   if u<0:continue
   frequency=440*2**((note-69)/12)
   envelope=(1-math.exp(-u*100))*math.exp(-u*(3.8 if name=='victory' else 2.8))
   v+=envelope*(math.sin(math.tau*frequency*u)+.18*math.sin(math.tau*frequency*2*u))*.17
  if t>3:
   for note in ([60,64,67] if name=='victory' else [48,51,55]):
    u=t-3;f=440*2**((note-69)/12)
    v+=math.sin(math.tau*f*u)*(1-math.exp(-u*20))*math.exp(-u*2)*.12
  values.append(v)
 peak=max(abs(v) for v in values)
 with wave.open(str(ROOT/('round-'+name+'.wav')),'wb') as output:
  output.setnchannels(1);output.setsampwidth(2);output.setframerate(RATE)
  output.writeframes(b''.join(struct.pack('<h',int(v/peak*26000)) for v in values))
 print(name,duration,'seconds')
