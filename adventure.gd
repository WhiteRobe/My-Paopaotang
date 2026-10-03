extends RefCounted
const Story=preload("res://data/story.gd")
var g
var stage:Dictionary={}
var enemies:Array=[]
var objects:Array=[]
var enemy_art=preload("res://assets/enemies.png")
var object_art=preload("res://assets/mission-objects.png")
var dialogue=0
var progress=0
var wave=0
var wave_wait=0.0
var objective_done=false
var boss_dead=false
var escort_cell=Vector2i(3,7)
var escort_visual=Vector2(3,7)
var escort_hp=8
var escort_timer=0.0
var escort_hit=0.0
var revives=2
var spawn_serial=0
var checkpoint=Vector2i(10,7)
func _init(game):g=game
func setup():
	stage=Story.STAGES[g.adventure_stage-1]
	enemies.clear();objects.clear();dialogue=0;progress=0;wave=0;wave_wait=0;objective_done=false;boss_dead=false
	escort_cell=Vector2i(3,7);escort_visual=Vector2(escort_cell);escort_hp=8;escort_timer=0;escort_hit=0;revives=2;spawn_serial=0
	checkpoint=Vector2i(10,7);g.clear_patch(checkpoint)
	for p in g.players:
		p.team=0;p.grace=3;p.revive_wait=-1.0;p.pve_revives=1
		# Adventurers begin ready for crowds, while pickups still provide growth.
		p.capacity=maxi(p.capacity,3);p.range=maxi(p.range,3);p.power=maxi(p.power,1)
	var points=[Vector2i(5,3),Vector2i(15,11),Vector2i(15,3),Vector2i(5,11)]
	for c in points:clear_route(c)
	match stage.mission:
		"collect","rescue","beacons":
			for i in range(stage.target):objects.append({"cell":points[i],"type":stage.mission,"active":false})
			spawn_group(3+stage.chapter)
		"escort":
			for x in range(2,19):g.grid[7][x]=0
			spawn_group(4+stage.chapter)
		"survive":spawn_group(4);wave_wait=9
		"waves":spawn_wave()
		"boss":
			for y in range(3,12):
				for x in range(6,15):g.grid[y][x]=0
			spawn_enemy(Vector2i(10,5),6+stage.chapter,true)
			spawn_group(2+int(stage.chapter/2))
	g.state="story"
	g.profile.adventure_stage=g.adventure_stage;g.save_profile()
func clear_route(c):
	g.clear_patch(c)
	for x in range(1,c.x+1):g.grid[7][x]=0
	for y in range(mini(7,c.y),maxi(7,c.y)+1):g.grid[y][c.x]=0
func spawn_enemy(c,kind,boss=false):
	if not g.passable(c):g.clear_patch(c)
	var hp=(10+stage.chapter*2) if boss else (1+int(stage.chapter/2))
	enemies.append({"cell":c,"visual":Vector2(c),"from":Vector2(c),"move":1.0,"duration":.4,"cool":0.0,"hit":0.0,"freeze":0.0,"slow":0.0,"attack":2.5,"kind":kind,"hp":hp,"max_hp":hp,"boss":boss,"dead":false,"serial":spawn_serial})
	spawn_serial+=1
func spawn_group(count):
	var positions=[Vector2i(10,2),Vector2i(18,7),Vector2i(10,12),Vector2i(2,7),Vector2i(15,5),Vector2i(5,9),Vector2i(15,9)]
	for i in range(count):
		var c=positions[(i+spawn_serial)%positions.size()]
		if g.grid[c.y][c.x]==3:continue
		if enemies.any(func(e):return not e.dead and e.cell==c):continue
		spawn_enemy(c,(stage.chapter+i)%6)
func spawn_wave():
	wave+=1;spawn_group(mini(7,2+wave+stage.chapter));g.announce("第%d波怪物来袭！" % wave)
func advance_dialogue():
	dialogue+=1
	if dialogue>=stage.intro.size():g.state="play";g.countdown=1.5
func hit_enemy(e,damage=1):
	if e.dead or e.hit>0:return
	e.hp-=damage;e.hit=.7;
	if not e.boss:e.freeze=maxf(e.freeze,.45)
	g.burst(g.center(e.cell),Color("edcfad"),8);g.sound("splash")
	if e.hp<=0:
		e.dead=true;g.stat("monsters")
		if e.boss:boss_dead=true;g.stat("bosses");g.announce(stage.boss+"恢复清醒了！")
		elif g.rng.randf()<.42:g.drops[e.cell]=[4,5,7,8,15][g.rng.randi_range(0,4)]
		if g.rng.randf()<.25:objects.append({"cell":e.cell,"type":"heart","active":false})
func update(dt):
	escort_hit=maxf(0,escort_hit-dt)
	var living=g.players.filter(func(p):return not p.dead)
	for p in g.players:
		if p.dead and ((not p.bot and revives>0) or (p.bot and p.pve_revives>0)):
			if p.revive_wait<0:p.revive_wait=2.0
			p.revive_wait-=dt
			if p.revive_wait<=0:
				if p.bot:p.pve_revives-=1
				else:revives-=1
				p.dead=false;p.trap=0;p.shield=4;p.grace=3;p.revive_wait=-1
				var dest=g.SPAWNS[p.id]
				if not g.passable(dest):dest=checkpoint
				g.teleport(p,dest);g.announce("萤灯复苏！剩余%d次。" % revives)
	living=g.players.filter(func(p):return not p.dead)
	if living.is_empty() and not g.players.any(func(p):return p.dead and ((not p.bot and revives>0) or (p.bot and p.pve_revives>0))):g.finish_round(1);return
	for e in enemies:
		if e.dead:continue
		e.hit=maxf(0,e.hit-dt);e.freeze=maxf(0,e.freeze-dt);e.slow=maxf(0,e.slow-dt);e.attack-=dt;e.cool-=dt
		e.move=minf(1,e.move+dt/e.duration);e.visual=e.from.lerp(Vector2(e.cell),e.move)
		if g.grid[e.cell.y][e.cell.x]==3:e.dead=true;if_boss_fell(e);continue
		for f in g.blasts:
			if f.owner>=0 and f.cell==e.cell and f.time>0:g.bubble_fx.affect_enemy(e,f);break
		if e.dead or e.freeze>0:continue
		if living.is_empty():continue
		var target=living[0]
		for p in living:
			if g.manhattan(p.cell,e.cell)<g.manhattan(target.cell,e.cell):target=p
		var dest=target.cell
		for decoy in g.decoys:
			if g.manhattan(decoy.cell,e.cell)<=5:dest=decoy.cell;break
		if e.cool<=0 and e.move>=1:
			var d=g.route_direction({"cell":e.cell,"cloak":0,"id":-1},dest,{})
			var next=e.cell+d
			if d!=Vector2i.ZERO and g.passable(next) and not enemies.any(func(other):return other!=e and not other.dead and other.cell==next):
				e.from=e.visual;e.cell=next;e.move=0;e.duration=.65 if e.boss else (.46+.025*e.kind);e.duration*=1.5 if e.slow>0 else 1.0;e.cool=e.duration
		for p in living:
			if p.cell==e.cell:g.damage_player(p,-1)
		if e.boss and e.attack<=0:
			e.attack=4.2 if e.hp>e.max_hp/2 else 2.8
			boss_attack(e,target.cell)
		elif not e.boss and e.kind in [1,3,4] and e.attack<=0:
			e.attack=5.5
			g.hazards.append({"cells":[target.cell],"wait":1.2,"type":"monster"})
	for o in objects:
		if o.active:continue
		if o.type=="beacons":
			for f in g.blasts:
				if f.owner>=0 and f.cell==o.cell:o.active=true;progress+=1;g.sound("pickup");g.burst(g.center(o.cell),Color("fff0a0"),12);break
		else:
			for p in living:
				if p.cell==o.cell or (o.type=="rescue" and g.manhattan(p.cell,o.cell)<=1):
					o.active=true;g.sound("pickup");g.burst(g.center(o.cell),Color("bcf2ad"),12)
					if o.type=="heart":p.trap=0;p.shield=maxf(p.shield,4);p.grace=2
					else:
						progress+=1
						if o.type=="rescue" and p.id==0:g.stat("rescues")
					break
	match stage.mission:
		"collect","rescue","beacons":objective_done=progress>=stage.target
		"boss":objective_done=boss_dead
		"waves":
			if enemies.all(func(e):return e.dead):
				if wave>=stage.target:objective_done=true
				else:
					wave_wait+=dt
					if wave_wait>2:wave_wait=0;spawn_wave()
		"survive":
			progress=mini(stage.target,int(g.round_time));objective_done=progress>=stage.target
			wave_wait-=dt
			if wave_wait<=0 and not objective_done:wave_wait=10;spawn_group(2)
		"escort":
			if living.any(func(p):return g.manhattan(p.cell,escort_cell)<=3):
				escort_timer-=dt
				if escort_timer<=0:
					escort_timer=.65
					var next=escort_cell+Vector2i.RIGHT
					if g.passable(next) and not enemies.any(func(e):return not e.dead and e.cell==next):escort_cell=next
			escort_visual=escort_visual.lerp(Vector2(escort_cell),minf(1,dt*8))
			if escort_hit<=0:
				var attacked=enemies.any(func(e):return not e.dead and g.manhattan(e.cell,escort_cell)<=1)
				attacked=attacked or g.blasts.any(func(f):return f.owner<0 and f.cell==escort_cell)
				if attacked:escort_hp-=1;escort_hit=1.5;g.burst(g.center(escort_cell),Color("ffc6a7"),6)
			if escort_hp<=0:g.finish_round(1);return
			progress=mini(14,escort_cell.x-3);objective_done=escort_cell.x>=17
	if objective_done:
		for p in living:
			if (not p.bot or g.humans==0) and g.manhattan(p.cell,checkpoint)<=1:g.finish_round(0);return
	if g.clock_time<=-35:g.finish_round(1)
func if_boss_fell(e):
	g.stat("monsters")
	if e.boss:boss_dead=true;g.stat("bosses")
func boss_attack(e,target):
	var marked:Array=[]
	match stage.chapter:
		0:
			for d in g.DIRS:
				for n in range(1,5):marked.append(e.cell+d*n)
			if enemies.filter(func(other):return not other.dead).size()<5:spawn_group(2)
		1:
			for x in range(1,g.W-1):marked.append(Vector2i(x,target.y))
			for y in range(1,g.H-1):marked.append(Vector2i(target.x,y))
		2:
			for y in range(-1,2):
				for x in range(-1,2):marked.append(target+Vector2i(x,y))
		3:
			for y in range(1,g.H-1):
				for x in range(-1,2):marked.append(Vector2i(clampi(target.x+x,1,g.W-2),y))
		4:
			for d in [Vector2i(1,1),Vector2i(-1,1),Vector2i(1,-1),Vector2i(-1,-1)]:
				for n in range(1,6):marked.append(target+d*n)
			marked.append(target)
			if enemies.filter(func(other):return not other.dead).size()<6:spawn_group(2)
	marked=marked.filter(func(c):return g.inside(c))
	g.hazards.append({"cells":marked,"wait":1.6 if e.hp>e.max_hp/2 else 1.1,"type":"boss"})
	g.announce(stage.boss+"蓄力！避开亮起的区域。")
func bot_target(p):
	if objective_done:return checkpoint
	for other in g.players:
		if not other.dead and other.trap>0:return other.cell
	var target=escort_cell if stage.mission=="escort" else null
	var distance=g.manhattan(p.cell,escort_cell) if stage.mission=="escort" else 999
	for o in objects:
		if o.active or o.type=="beacons":continue
		var d=g.manhattan(p.cell,o.cell)
		if d<distance:target=o.cell;distance=d
	if stage.mission=="survive" and enemies.filter(func(e):return not e.dead and g.manhattan(e.cell,p.cell)<=4).is_empty():return checkpoint
	for e in enemies:
		if e.dead:continue
		var d=g.manhattan(p.cell,e.cell)
		if d<distance:target=e.cell;distance=d
	if stage.mission=="beacons":
		for o in objects:
			if not o.active and g.manhattan(p.cell,o.cell)<distance:target=o.cell;distance=g.manhattan(p.cell,o.cell)
	return target if target!=null else checkpoint
func should_bomb(p):
	if enemies.any(func(e):return not e.dead and g.manhattan(p.cell,e.cell)<=3):return true
	return stage.mission=="beacons" and objects.any(func(o):return not o.active and o.type=="beacons" and g.manhattan(p.cell,o.cell)<=p.range)
func freeze_nearby(p):
	for e in enemies:
		if not e.dead and g.manhattan(e.cell,p.cell)<=3:e.freeze=2.5;g.burst(g.center(e.cell),Color("bbf2ff"),8)
func object_icon(pos,kind,size=20):g.draw_texture_rect_region(object_art,Rect2(pos,Vector2(size,size)),Rect2(Vector2(kind*20,0),Vector2(20,20)))
func draw_world():
	for o in objects:
		var kind={"collect":0 if stage.chapter==0 else 5,"rescue":1,"beacons":2,"heart":7}.get(o.type,0)
		if o.active and o.type!="beacons":continue
		var pos=g.center(o.cell)-Vector2(10,12+sin(g.elapsed*3+o.cell.x))
		object_icon(pos,6 if o.active and o.type=="rescue" else kind)
		if o.active and o.type=="beacons":g.draw_arc(g.center(o.cell),10,0,TAU,24,Color("fff7b1"),2)
	if stage.mission=="escort":
		object_icon(g.ORIGIN+escort_visual*g.TILE+Vector2(-3,-8),3,25)
		g.rect(g.center(escort_cell)+Vector2(-10,12),Vector2(20,2),g.INK);g.rect(g.center(escort_cell)+Vector2(-10,12),Vector2(20*escort_hp/8.0,2),Color("b6e7a8"))
	object_icon(g.center(checkpoint)-Vector2(12,12),4,24)
	if objective_done:g.draw_arc(g.center(checkpoint),14,0,TAU,28,Color("d9ffb1"),2)
	for e in enemies:
		if e.dead or (e.hit>0 and int(g.elapsed*16)%2==0):continue
		var size=36 if e.boss else 24
		var pos=g.ORIGIN+e.visual*g.TILE+Vector2(g.TILE/2.0,g.TILE/2.0)
		var frame=int(g.elapsed*5)%3
		g.draw_texture_rect_region(enemy_art,Rect2(pos-Vector2(size/2.0,size*.65),Vector2(size,size)),Rect2(Vector2(e.kind*32,frame*32),Vector2(32,32)))
		g.rect(pos+Vector2(-10,11),Vector2(20,2),g.INK);g.rect(pos+Vector2(-10,11),Vector2(20*e.hp/float(e.max_hp),2),Color("ffaaa0"))
		if e.freeze>0:g.draw_arc(pos,12,0,TAU,20,Color("b2e9ff"),1)
func objective_label():
	if objective_done:return "任务完成！去中央出口"
	match stage.mission:
		"boss":
			var bosses=enemies.filter(func(e):return e.boss)
			return stage.boss+" %d/%d" % [bosses[0].hp,bosses[0].max_hp] if not bosses.is_empty() else "寻找守护者"
		"waves":return "波次 %d/%d · 敌人%d" % [wave,stage.target,enemies.filter(func(e):return not e.dead).size()]
		"escort":return "护送 %d/14 · 耐久%d" % [progress,escort_hp]
		_:return "任务进度 %d/%d" % [progress,stage.target]
func draw_sidebar():
	g.wrapped(stage.objective,Vector2(529,120),8,g.CREAM)
	if stage.mission=="boss" and not objective_done:
		g.text_at(stage.boss,Vector2(529,178),12,Color("ffe3a0"))
		var bosses=enemies.filter(func(e):return e.boss)
		if not bosses.is_empty():g.text_at("生命 %d/%d" % [bosses[0].hp,bosses[0].max_hp],Vector2(529,197),12,Color("ffe3a0"))
	else:g.wrapped(objective_label(),Vector2(529,174),8,Color("ffe3a0"))
	g.wrapped("靠近队友可救援。真人倒下后可复苏两次。",Vector2(529,228),8,Color("b8d8c3"))
	g.text_at("剩余复苏 %d" % revives,Vector2(529,293),12,Color("ffe3a0"))
func draw_story():
	g.draw_texture(g.backgrounds[g.Catalog.MAPS[g.arena].theme],Vector2.ZERO)
	g.rect(Vector2.ZERO,Vector2(640,360),Color(.03,.05,.1,.4))
	g.centered(Story.CHAPTERS[stage.chapter].name,49,24,Color("ffe4a5"))
	g.centered("第%d节 · %s" % [int((g.adventure_stage-1)%4)+1,stage.name],77,12,g.CREAM)
	g.mini_board(Vector2(226,87),9)
	g.panel(Vector2(30,237),Vector2(580,98),Color("a1c7c1"))
	var line=stage.intro[dialogue]
	if line[0]==stage.boss:
		g.draw_texture_rect_region(enemy_art,Rect2(Vector2(43,245),Vector2(48,48)),Rect2(Vector2((6+stage.chapter)*32,0),Vector2(32,32)))
	elif line[0] in ["蓝莓","桃桃","薄荷"]:
		g.portrait(Vector2(43,245),["蓝莓","桃桃","薄荷"].find(line[0]),Vector2(40,48))
	else:object_icon(Vector2(43,245),5 if line[0]=="旁白" else (4 if line[0]=="任务" else 6),40)
	g.text_at(line[0],Vector2(99,258),12,Color("ffe3a0"))
	g.wrapped(line[1],Vector2(99,279),40,g.CREAM)
	g.centered("回车 / 空格 / 点击继续 · ESC 跳过对白 · P 暂停",351,12,Color("b9d9d0"))
