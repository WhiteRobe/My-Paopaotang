"""Compose only the two original result-page scores; preserve other resources."""
import json
from compose_music_expansion import compose, OUT
SCORES=[
 ('result-victory','胜利：伙伴们的欢呼',112,60,'major','marimba',[0,2,4,6,5,4,2,0,4,6,5,3,4,2,1,0],4,32,'result'),
 ('result-defeat','失利：下一次出航',84,57,'minor','harp',[0,2,3,5,4,3,2,0,3,4,5,3,2,1,2,0],4,24,'result')]
if __name__=='__main__':
 old={entry['id']:entry for entry in json.loads((OUT/'catalog.json').read_text())}
 for score in SCORES:old[score[0]]=compose(score)
 (OUT/'catalog.json').write_text(json.dumps(list(old.values()),ensure_ascii=False,indent=2)+'\n')
