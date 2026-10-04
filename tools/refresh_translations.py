"""Refresh editable offline locale catalogs; the shipped game never calls a translator."""
from pathlib import Path
import re,json,time,urllib.request,urllib.parse,concurrent.futures
ROOT=Path(__file__).resolve().parents[1]
def sources():
 values=set()
 for path in ROOT.rglob('*.gd'):
  if '.godot' in path.parts or 'dist' in path.parts:continue
  for raw in re.findall(r'"((?:[^"\\]|\\.)*)"',path.read_text()):
   try:s=json.loads('"'+raw+'"')
   except ValueError:continue
   if re.search('[\u3400-\u9fff]',s):values.add(s)
 return sorted(values)
def translate(lang,items):
 target=ROOT/'locales'/f'{lang}.json'
 result=json.loads(target.read_text()) if target.exists() else {}
 pending=[s for s in items if s not in result]
 groups=[];batch=[];size=0
 for s in pending:
  if size+len(s)>1000 and batch:groups.append(batch);batch=[];size=0
  batch.append(s);size+=len(s)+18
 if batch:groups.append(batch)
 for index,batch in enumerate(groups):
  query='\n'.join(f'[[N{i:03}]] '+s for i,s in enumerate(batch))
  url='https://translate.googleapis.com/translate_a/single?'+urllib.parse.urlencode({'client':'gtx','sl':'zh-CN','tl':lang,'dt':'t','q':query})
  for retry in range(5):
   try:
    req=urllib.request.Request(url,headers={'User-Agent':'Mozilla/5.0'})
    data=json.loads(urllib.request.urlopen(req,timeout=35).read())
    output=''.join(x[0] for x in data[0]);markers=list(re.finditer(r'(?:\[|【|［){1,3}\s*N\s*(\d+)\s*(?:\]|】|］){1,3}',output,re.I))
    if not markers:raise ValueError('No alignment markers')
    for j,mark in enumerate(markers):
     k=int(mark.group(1));end=markers[j+1].start() if j+1<len(markers) else len(output);text=output[mark.end():end].strip();result[batch[k]]=text
    for missing in [s for s in batch if s not in result]:
     single='https://translate.googleapis.com/translate_a/single?'+urllib.parse.urlencode({'client':'gtx','sl':'zh-CN','tl':lang,'dt':'t','q':missing})
     data2=json.loads(urllib.request.urlopen(single,timeout=35).read());result[missing]=''.join(x[0] for x in data2[0])
    target.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n');print(lang,index+1,'/',len(groups),len(result),flush=True);break
   except Exception as e:
    print(lang,'retry',retry,type(e).__name__,str(e),flush=True)
    if retry==4:raise
    time.sleep(2+retry*2)
  time.sleep(.15)
 return lang,len(result)
if __name__=='__main__':
 items=sources();(ROOT/'locales/zh.json').write_text(json.dumps({s:s for s in items},ensure_ascii=False,indent=2)+'\n')
 print('Source strings:',len(items),flush=True)
 with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
  for result in pool.map(lambda lang:translate(lang,items),['en','ja','fr','de']):print('DONE',result,flush=True)
