"""Compose only the four original racing scores, using synthesized instruments."""
import json
from compose_music_expansion import compose, OUT
SCORES=[
 ('race-harbor','赛车：白帆冲刺',136,60,'major','marimba',[0,2,4,2,5,4,2,0,2,4,6,5,4,2,1,0],4,64,'race:harbor'),
 ('race-forest','赛车：林间追风',142,62,'dorian','flute',[0,2,3,4,2,5,4,2,6,5,3,4,2,1,2,0],4,64,'race:forest'),
 ('race-factory','赛车：齿轮疾驰',148,55,'minor','pulse',[0,0,4,2,3,4,6,4,2,3,5,4,2,1,4,0],4,64,'race:factory'),
 ('race-sprint','赛车：最后冲线',164,57,'minor','brass',[0,2,4,6,4,5,6,4,6,5,4,3,2,4,1,0],4,24,'race:sprint'),
]
if __name__=='__main__':
 catalog=OUT/'catalog.json';old={entry['id']:entry for entry in json.loads(catalog.read_text())}
 for score in SCORES:old[score[0]]=compose(score)
 catalog.write_text(json.dumps(list(old.values()),ensure_ascii=False,indent=2)+'\n')
