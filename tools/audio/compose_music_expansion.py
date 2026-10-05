"""Compose 21 original scores for v4.7.6; leaves the original theme scores intact.
Requires numpy and ffmpeg. Notes, instruments and percussion contain no samples.
"""
from pathlib import Path
import argparse, json, math, subprocess, tempfile, wave
import numpy as np

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'assets/audio/music'
SR=32000
SCALES={'major':[0,2,4,5,7,9,11],'minor':[0,2,3,5,7,8,10],
        'dorian':[0,2,3,5,7,9,10],'harmonic':[0,1,4,5,7,8,11],
        'pentatonic':[0,2,4,7,9,12,14]}
# id, title, tempo, tonic, mode, lead, motif, metre, bars, scene
SCORES=[
 ('harbor-alt','海港：白帆与晚潮',108,60,'major','reed',[0,2,4,5,4,2,1,0,2,4,6,5,3,2,1,4],4,80,'harbor'),
 ('forest-alt','森林：枝间圆舞',102,62,'dorian','flute',[0,3,4,2,1,2,5,4,3,1,0,2,4,6,5,2],3,104,'forest'),
 ('frost-alt','冰雪：雪花玻璃钟',96,65,'major','glass',[4,2,0,1,2,5,4,2,6,5,3,2,1,0,4,2],3,96,'frost'),
 ('desert-alt','沙漠：月下商队',106,57,'harmonic','oud',[0,1,4,5,4,3,1,0,4,6,5,3,4,1,0,1],4,80,'desert'),
 ('volcano-alt','火山：赤岩行进曲',126,48,'minor','brass',[0,0,4,3,2,0,5,4,6,5,4,2,3,1,0,4],4,88,'volcano'),
 ('factory-alt','工厂：铜管发条',124,55,'dorian','pulse',[0,4,1,3,0,5,2,4,6,4,2,0,1,3,5,4],4,88,'factory'),
 ('candy-alt','糖果：跳跳汽水节',118,67,'major','marimba',[0,4,6,5,2,4,1,0,5,3,6,4,2,1,0,2],4,80,'candy'),
 ('cosmos-alt','星空：银轨远航',94,59,'minor','glass',[0,4,5,2,6,4,3,1,2,5,6,4,1,3,2,0],4,80,'cosmos'),
 ('swamp-alt','沼泽：苇笛与萤光',98,57,'dorian','reed',[0,2,3,5,3,1,2,0,4,5,6,3,2,4,1,0],4,80,'swamp'),
 ('ruins-alt','遗迹：石碑的记忆',92,53,'harmonic','harp',[0,4,1,3,5,4,6,1,3,4,1,0,6,5,4,1],4,80,'ruins'),
 ('reef-alt','深海：珍珠摇篮',88,64,'major','glass',[2,5,4,1,0,2,4,6,5,3,2,4,1,0,2,5],4,80,'reef'),
 ('sky-alt','空港：云端邮差',116,62,'major','harp',[0,2,4,6,5,2,3,4,6,5,4,2,1,3,2,0],4,80,'sky'),
 ('citadel-alt','王城：黎明钟声',120,50,'minor','brass',[0,2,3,4,6,5,3,2,4,5,6,4,2,1,0,4],4,88,'citadel'),
 ('cave-alt','洞窟：深岩星火',86,48,'minor','glass',[0,4,1,0,5,3,2,6,4,2,1,5,3,0,4,1],4,80,'cave'),
 ('menu','群岛：潮汐序曲',96,60,'major','harp',[0,2,4,5,6,4,2,0,3,5,4,2,1,0,2,4],4,80,'menu'),
 ('lobby','伙伴：出航前夜',112,62,'major','marimba',[0,4,2,5,4,1,2,0,4,6,5,3,2,4,1,0],4,80,'lobby'),
 ('boss-swamp','苔冠树王：根脉苏醒',128,45,'dorian','reed',[0,3,2,0,5,4,3,1,6,4,5,3,2,0,1,4],4,96,'boss:0'),
 ('boss-ruins','砂钟守卫：逆转刻度',132,50,'harmonic','pulse',[0,1,4,1,5,4,6,3,4,1,0,3,6,4,1,0],4,96,'boss:1'),
 ('boss-reef','铁钳蟹将：深庭激流',124,52,'minor','glass',[0,4,3,5,6,4,2,3,5,6,4,2,1,3,2,0],4,96,'boss:2'),
 ('boss-sky','雷翼飞艇：穿越风暴',140,50,'minor','brass',[0,4,2,5,6,4,3,2,5,6,4,3,2,1,0,4],4,96,'boss:3'),
 ('boss-citadel','墨潮大王：夺回晨光',144,43,'minor','brass',[0,2,4,6,5,3,2,0,6,5,4,2,1,3,2,0],4,96,'boss:4'),
]

def compose(spec):
    ident,title,bpm,tonic,mode,lead,motif,metre,bars,scene=spec
    beat=60/bpm;duration=bars*metre*beat
    mix=np.zeros((round(duration*SR),2),np.float32)
    rng=np.random.default_rng(476+sum(map(ord,ident)))
    scale=SCALES[mode];boss=scene.startswith('boss:')
    def pitch(degree,octave=0):return tonic+scale[degree%7]+12*(degree//7+octave)
    def place(start,signal,pan=0):
        at=round(start*SR)%len(mix)
        stereo=np.asarray(signal[:,None]*[math.sqrt((1-pan)/2),math.sqrt((1+pan)/2)],np.float32)
        count=min(len(stereo),len(mix)-at);mix[at:at+count]+=stereo[:count]
        if count<len(stereo):mix[:len(stereo)-count]+=stereo[count:]
    def note(start,length,midi,volume,voice='tri',pan=0):
        t=np.arange(round(length*SR),dtype=np.float32)/SR
        f=440*2**((midi-69)/12);ph=t*f;v=np.zeros_like(t)
        if voice in ['pulse','brass']:
            # Truncated harmonics avoid the harsh aliasing of naive square waves.
            for h in range(1,min(18,int(11000/f)),2):v+=np.sin(math.tau*ph*h)/h
            v*=.65
            if voice=='brass':v*=1+.12*np.sin(t*math.tau*4.8)
        elif voice in ['glass','harp']:
            for h,gain in [(1,.7),(2,.18),(3.98,.07)]:v+=np.sin(math.tau*ph*h)*gain
        elif voice=='marimba':v=np.sin(math.tau*ph)*.75+np.sin(math.tau*ph*3)*.16
        elif voice=='oud':v=np.sin(math.tau*ph)*.55+np.sin(math.tau*ph*2)*.24+np.sin(math.tau*ph*3)*.12
        elif voice in ['reed','flute']:
            ph=ph+.006*np.sin(t*math.tau*5)
            v=np.sin(math.tau*ph)*.8+np.sin(math.tau*ph*(3 if voice=='reed' else 2))*.18
        elif voice=='pad':v=np.sin(math.tau*ph)*.55+np.sin(math.tau*ph*.999)*.25
        else:v=(1-4*np.abs(ph%1-.5))*.75
        attack=.10 if voice=='pad' else .009
        release=.18 if voice=='pad' else min(.08,length*.30)
        envelope=np.minimum(t/attack,1)*np.clip((length-t)/release,0,1)
        if voice in ['glass','harp','oud','marimba']:envelope*=np.exp(-t/(length*.45))
        place(start,v*envelope*volume,pan)
    def drum(start,kind,volume):
        length=.25 if kind=='kick' else .17
        t=np.arange(round(length*SR),dtype=np.float32)/SR
        noise=rng.uniform(-1,1,len(t)).astype(np.float32)
        if kind=='kick':v=np.sin(math.tau*(52*t+1.9*(1-np.exp(-t*35))))*np.exp(-t*22)
        elif kind=='snare':v=(noise*.65+np.sin(math.tau*t*180)*.25)*np.exp(-t*27)
        elif kind=='wood':v=np.sin(math.tau*t*730)*np.exp(-t*75)+noise*.08*np.exp(-t*100)
        else:v=(noise-np.roll(noise,1))*.4*np.exp(-t*95)
        place(start,v*volume,0)
    progression=[0,3,5,4,2,5,1,4] if mode in ['major','pentatonic'] else [0,3,5,4,0,6,3,4]
    for bar in range(bars):
        section=min(9,bar*10//bars);start=bar*metre*beat
        chord=progression[(bar//2)%8]
        if section==5:chord=[5,3,1,4][(bar//2)%4]
        melody_shift=2 if section in [3,4,7] else 0
        lead_gain=.17 if boss else .14
        if section in [0,5,8]:lead_gain*=.64
        rhythm=[0,.5,1.25,2,2.5,3.25] if metre==4 else [0,.5,1,1.75,2,2.5]
        if boss and section in [2,4,6,9]:rhythm=[0,.5,.75,1.5,2,2.5,3,3.5]
        for tick,position in enumerate(rhythm):
            if position>=metre or (section==5 and tick%2):continue
            degree=motif[(bar%4*4+tick)%16]+melody_shift
            if section==8:degree=motif[(15-tick-bar)%16]
            if bar%8==7 and tick==len(rhythm)-1:degree=0
            length=beat*(.72 if section in [0,5,8] else .38)
            note(start+position*beat,length,pitch(degree,1),lead_gain,lead,.22)
        for d in [chord,chord+2,chord+4]:note(start,metre*beat*.94,pitch(d),.045,'pad',-.18)
        for tick in range(metre):
            note(start+tick*beat,beat*.73,pitch(chord,-1)+(12 if tick%2 else 0),.155,'tri')
            if section not in [0,5,8] or tick%2==0:drum(start+tick*beat,'kick',.17 if boss else .125)
            percussion='snare' if boss or scene in ['factory','volcano','citadel','candy','lobby'] else 'wood'
            if tick%2:drum(start+tick*beat,percussion,.075 if boss else .035)
            if section not in [0,5,8] and scene not in ['reef','cosmos','cave']:
                drum(start+(tick+.5)*beat,'hat',.033)
            if section in [1,2,4,6,7,9]:
                note(start+(tick+.25)*beat,beat*.28,pitch(chord+[0,2,4,2][tick%4],1),.06,'harp',-.55)
        # Countermelody and sparse octave accents appear only in the later reprise.
        if section in [4,6,9] and bar%2==1:
            for tick in range(0,metre,2):note(start+(tick+.6)*beat,beat*.85,pitch(motif[(bar+tick+8)%16]),.072,'flute',-.42)
        if bar%8==7 and section not in [0,5,8]:
            for tick in range(4):drum(start+(metre-1+tick/4)*beat,'snare' if boss else 'wood',.04)
    # Circular tails preserve the actual loop boundary instead of inserting silence.
    for seconds,gain in [(.18,.09),(.36,.06),(.57,.045 if scene=='cave' else .025)]:
        mix+=np.roll(mix[:,::-1].copy(),round(seconds*SR),axis=0)*gain
    mix-=np.mean(mix,axis=0)
    mix=np.tanh(mix*1.35)
    rms=float(np.sqrt(np.mean(mix**2)))
    mix*=min(.145/max(rms,.001),.78/max(float(np.max(np.abs(mix))),.001))
    if ident=='forest-alt':
        # Native Vorbis pre-roll can expose this reed phrase's circular tail.
        # A 40 ms cadence at either edge keeps its decoded boundary quiet.
        n=round(.04*SR);ramp=np.sin(np.linspace(0,math.pi/2,n))**2
        mix[:n]*=ramp[:,None];mix[-n:]*=ramp[::-1,None]
    peak=float(np.max(np.abs(mix)));rms=float(np.sqrt(np.mean(mix**2)))
    seam=float(np.max(np.abs(mix[0]-mix[-1])))
    category='variations' if ident.endswith('-alt') else 'boss' if ident.startswith('boss-') else 'frontend'
    relative=category+'/'+ident+'.ogg'
    (OUT/category).mkdir(parents=True,exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='paopaotang-score-v476-') as tmp:
        wav=Path(tmp)/'score.wav'
        with wave.open(str(wav),'wb') as f:
            f.setnchannels(2);f.setsampwidth(2);f.setframerate(SR)
            f.writeframes(np.asarray(np.clip(mix,-1,1)*32767,dtype='<i2').tobytes())
        subprocess.run(['ffmpeg','-y','-loglevel','error','-i',str(wav),'-c:a','vorbis','-strict','-2','-b:a','128k',str(OUT/relative)],check=True)
    entry={'id':ident,'title':title,'scene':scene,'bpm':bpm,'metre':metre,'bars':bars,'seconds':round(duration,2),'file':relative,'peak':round(peak,4),'rms':round(rms,4),'loop_seam':round(seam,4),'sample_rate':SR}
    print(f'{title}: {duration:.1f}s peak={peak:.3f} rms={rms:.3f} seam={seam:.4f}',flush=True)
    return entry

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--only',nargs='+',help='Recompose selected ids and preserve other catalog entries.')
    args=parser.parse_args()
    if args.only and set(args.only)-{s[0] for s in SCORES}:parser.error('Unknown score id')
    old={e['id']:e for e in json.loads((OUT/'catalog.json').read_text())} if (OUT/'catalog.json').exists() else {}
    for spec in SCORES:
        if not args.only or spec[0] in args.only:old[spec[0]]=compose(spec)
    (OUT/'catalog.json').write_text(json.dumps([old[s[0]] for s in SCORES if s[0] in old],ensure_ascii=False,indent=2)+'\n')
