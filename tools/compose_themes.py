"""Thirteen original, loopable pixel-game scores. Requires numpy and ffmpeg.
All oscillators, melodies, chord voicings and percussion are generated here.
"""
from pathlib import Path
import json, math, subprocess, tempfile, wave
import numpy as np
ROOT = Path(__file__).resolve().parents[1]
SR = 22050
THEMES = [
    ('harbor','海港：晴日航线',112,60,'major','pulse',[0,2,4,2,5,4,2,1]),
    ('forest','森林：萤火小径',100,62,'dorian','flute',[0,2,1,4,3,2,5,4]),
    ('frost','冰雪：雪晶舞曲',88,65,'major','bell',[4,6,5,2,4,2,1,0]),
    ('desert','沙漠：沙海旅人',110,57,'harmonic','pluck',[0,1,4,3,1,0,6,4]),
    ('volcano','火山：熔岩脉动',124,48,'minor','pulse',[0,0,2,3,4,3,2,6]),
    ('factory','工厂：齿轮节拍',128,55,'dorian','pulse',[0,2,0,4,3,0,5,4]),
    ('candy','糖果：汽水派对',120,67,'major','pluck',[0,4,2,5,4,6,5,2]),
    ('cosmos','星空：轨道漫游',92,59,'minor','bell',[0,4,6,5,2,4,3,1]),
    ('swamp','沼泽：萤灯夜行',96,57,'dorian','flute',[0,3,2,5,4,2,1,6]),
    ('ruins','遗迹：砂钟回声',90,53,'harmonic','bell',[0,1,4,6,3,4,1,0]),
    ('reef','深海：珊瑚梦境',84,64,'major','bell',[2,4,6,4,5,3,2,0]),
    ('sky','空港：风帆航线',118,62,'major','pluck',[0,2,5,4,6,5,3,1]),
    ('citadel','王城：归航之光',122,50,'minor','pulse',[0,2,4,6,5,3,2,0]),
    ('cave','洞窟：火炬回声',86,48,'minor','bell',[0,4,2,6,3,1,5,0]),
]
SCALES = {'major':[0,2,4,5,7,9,11], 'minor':[0,2,3,5,7,8,10], 'dorian':[0,2,3,5,7,9,10], 'harmonic':[0,1,4,5,7,8,11]}
def hz(n): return 440 * 2 ** ((n-69)/12)
def render(spec):
    key,title,bpm,root,mode,instrument,motif = spec
    beat = 60/bpm
    duration = 256*beat
    mix = np.zeros((round(duration*SR),2),dtype=np.float32)
    scale=SCALES[mode]
    rng=np.random.default_rng(173+root)
    def pitch(degree,octave=0):
        return root + scale[degree%7] + (degree//7+octave)*12
    def add(start,dur,n,amp,voice='tri',pan=0):
        a=round(start*SR); count=min(round(dur*SR),len(mix)-a)
        if count<=0: return
        t=np.arange(count,dtype=np.float32)/SR
        phase=t*hz(n)
        if voice=='pulse':
            v=np.where(phase%1<(.25 if key!='volcano' else .125),.55,-.55)
        elif voice=='bell':
            v=np.sin(phase*math.tau)*.7+np.sin(phase*math.tau*2.01)*.22+np.sin(phase*math.tau*3.98)*.08
        elif voice=='flute':
            v=np.sin((phase+.005*np.sin(t*math.tau*5))*math.tau)*.8+np.sin(phase*math.tau*2)*.15
        elif voice=='pluck':
            v=(1-4*np.abs(phase%1-.5))*.7+np.sin(phase*math.tau*2)*.22
        elif voice=='pad':
            v=np.sin(phase*math.tau)*.7+np.sin(phase*math.tau*.998)*.2
        else: v=1-4*np.abs(phase%1-.5)
        env=np.minimum(1,t/(.05 if voice=='pad' else .006))*np.maximum(0,1-t/dur)**(1.8 if voice in ['bell','pluck'] else .65)
        v=np.asarray(v*env*amp,dtype=np.float32)
        mix[a:a+count,0]+=v*math.sqrt((1-pan)/2)
        mix[a:a+count,1]+=v*math.sqrt((1+pan)/2)
    def drum(start,kind,amp):
        a=round(start*SR); count=min(round(.16*SR),len(mix)-a)
        if count<=0:return
        t=np.arange(count,dtype=np.float32)/SR
        if kind=='kick':v=np.sin(math.tau*(110*t-220*t*t))*np.exp(-t*35)
        elif kind=='snare':v=(rng.uniform(-1,1,count)*.8+np.sin(math.tau*t*170)*.2)*np.exp(-t*24)
        else:v=rng.uniform(-1,1,count)*np.exp(-t*100)
        v=np.asarray(v*amp,dtype=np.float32)
        mix[a:a+count,:]+=v[:,None]*.707
    progression=[0,5,3,4] if mode=='major' else [0,5,6,4]
    for bar in range(64):
        section=bar//8
        start=bar*4*beat
        chord=progression[(bar//2)%4]
        # Four arrangements, then a varied reprise, with a quiet bridge.
        lead_amp=.16 if section not in [0,4] else .12
        for tick in range(8):
            degree=motif[(tick+(bar%2)*2)%8]
            if section in [2,6]:degree=(degree+2)%7
            if section in [3,7] and tick>=4:degree=motif[7-tick]
            degree=(degree+chord)%7
            if bar%8==7 and tick>=6:degree=0 if tick==7 else 1
            if section==4 and tick%2:continue
            note_dur=beat*(.88 if section==4 else .43)
            add(start+tick*beat/2,note_dur,pitch(degree,1),lead_amp,instrument,.18)
        for degree in [chord,chord+2,chord+4]:
            add(start,beat*3.85,pitch(degree),.045,'pad',-.25)
        for tick in range(4):
            add(start+tick*beat,beat*.7,pitch(chord,-1)+(12 if tick%2 else 0),.17,'tri',0)
            if section!=4 or tick%2==0:drum(start+tick*beat,'kick',.17)
            if tick%2 and key not in ['forest','frost','cosmos','cave']:drum(start+tick*beat,'snare',.085)
            if key not in ['frost','cosmos','cave']:drum(start+(tick+.5)*beat,'hat',.042)
        if section in [1,3,5,7]:
            for tick in range(4):
                add(start+(tick+.25)*beat,beat*.2,pitch(chord+[0,2,4,2][tick],1),.055,'bell',-.65)
        if bar%8==7 and key in ['volcano','factory','candy']:
            for tick in range(4):drum(start+(3+tick*.25)*beat,'snare',.045)
    if key=='cave':
        for delay,gain in [(.18,.16),(.37,.10),(.61,.05)]:
            count=round(delay*SR);mix[count:]+=mix[:-count,::-1]*gain
    # Gentle saturation and normalization leave headroom for gameplay effects.
    mix=np.tanh(mix*1.2)
    mix*=.8/max(.8,float(np.max(np.abs(mix))))
    with tempfile.TemporaryDirectory(prefix='paopaotang-score-') as temp:
        wav=Path(temp)/'score.wav'
        with wave.open(str(wav),'wb') as f:
            f.setnchannels(2);f.setsampwidth(2);f.setframerate(SR)
            f.writeframes(np.asarray(mix*32767,dtype='<i2').tobytes())
        out=ROOT/'assets/audio/themes'/f'{key}.ogg'
        subprocess.run(['ffmpeg','-y','-loglevel','error','-i',str(wav),'-c:a','vorbis','-strict','-2','-b:a','96k',str(out)],check=True)
    print(f'{title}: {duration:.1f}s',flush=True)
    return {'theme':key,'title':title,'bpm':bpm,'seconds':round(duration,2),'file':f'{key}.ogg'}
if __name__=='__main__':
    metadata=[render(spec) for spec in THEMES]
    (ROOT/'assets/audio/themes/catalog.json').write_text(json.dumps(metadata,ensure_ascii=False,indent=2)+'\n')
