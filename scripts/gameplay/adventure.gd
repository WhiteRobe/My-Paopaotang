extends RefCounted
const SKILL_COLORS=["9ad05f","76dcef","c5b2ff","84b866","e8be72","73b5f3","b7deff","bda1dd"]
const Story=preload("res://scripts/data/story.gd")
var g
var stage:Dictionary={}
var enemies:Array=[]
var objects:Array=[]
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
var party_scale=1.0
const SIDE_QUESTS=[
 "寻回浅滩萤灯","净化毒蕈泉眼","收集营地罗盘","唤醒树王根脉",
 "修复镜光铭文","重启回廊齿轮","找回回声石片","校准砂钟刻印",
 "收集珊瑚珍珠","打开牢湾封印","保护潮汐卵石","修复铁钳徽记",
 "找回风帆邮袋","补充驿路能源","记录云涡星图","点亮飞艇航标",
 "净化外城墨晶","重启街区灯箱","找回工厂钥匙","修复王座核心"]
var bonus_objects:Array=[]
var bonus_progress=0
var escort_fuel=0.0
var escort_stops:Array=[]
var escort_stations:Array=[]
var escort_goal=Vector2i.ZERO
var escort_arrived=false
var escort_distance=14
var checkpoint=Vector2i(10,7)
func _init(game):g=game
func setup():
	stage=Story.STAGES[g.adventure_stage-1].duplicate(true)
	var human_count=g.players.filter(func(p):return not p.bot).size()
	var bot_count=g.players.size()-human_count
	party_scale=1.0+.45*maxi(0,human_count-1)+.15*bot_count
	var instructions={"collect":"每人携带一件，返回中央出口交付。","rescue":"接触居民即可完成救援。","beacons":"按标号顺序，用水柱点亮信标。","escort":"跟随车辆，在三个补给站停留充能。","survive":"守住出口，利用支线奖励抵御增援。","waves":"击败每波敌人，利用地图机关与核心。","boss":"观察攻击预警；半血后守护者会加快攻击。"}
	stage.intro[2][1]+=" "+instructions[stage.mission]
	enemies.clear();objects.clear();dialogue=0;progress=0;wave=0;wave_wait=0;objective_done=false;boss_dead=false
	escort_cell=Vector2i(3,g.H/2);escort_visual=Vector2(escort_cell);escort_hp=8;escort_timer=0;escort_hit=0;revives=[3,2,1][g.difficulty];spawn_serial=0;bonus_progress=0;escort_fuel=0;escort_stops.clear();bonus_objects.clear()
	checkpoint=Vector2i(g.W/2,g.H/2);g.clear_patch(checkpoint)
	escort_goal=checkpoint;escort_arrived=false;escort_distance=escort_goal.x-escort_cell.x;escort_stations.clear()
	for i in range(1,4):escort_stations.append(escort_cell.x+roundi(escort_distance*i/4.0))
	for p in g.players:
		p.team=0;p.grace=3;p.revive_wait=-1.0;p.pve_revives=1;p.cargo=0
		# Every character begins with the same combat stats.
		p.capacity=1;p.range=1;p.power=0;p.damage_level=0
	var points=[Vector2i(5,3),Vector2i(g.W-6,g.H-4),Vector2i(g.W-6,3),Vector2i(5,g.H-4)]
	points=points.map(func(c):return g.nearest_playable(c))
	for c in points:clear_route(c)
	match stage.mission:
		"collect","rescue","beacons":
			for i in range(stage.target):objects.append({"cell":points[i],"type":stage.mission,"active":false,"charge":0.0})
			spawn_group(3+stage.chapter)
		"escort":
			for x in range(2,g.W-2):g.grid[g.H/2][x]=0
			spawn_group(4+stage.chapter)
		"survive":spawn_group(4);wave_wait=9
		"waves":spawn_wave()
		"boss":
			for y in range(3,12):
				for x in range(6,15):g.grid[y][x]=0
			spawn_enemy(Vector2i(10,5),6+stage.chapter,true)
			spawn_group(2+int(stage.chapter/2))
	for c in [Vector2i(8,11),Vector2i(12,3)]:
		clear_route(c);bonus_objects.append({"cell":c,"active":false,"charge":0.0,"type":["collect","hold","water"][(g.adventure_stage-1)%3]})
	for p in g.players:
		var start=p.cell+Vector2i(2,0)
		for entry in [[start,4],[p.cell+Vector2i(0,2),5]]:
			if g.passable(entry[0]) and not g.drops.has(entry[0]):g.drops[entry[0]]=entry[1]
	g.drops[g.nearest_playable(g.players[0].cell+Vector2i(1,0))]=28
	g.state="story"
	g.profile.adventure_stage=g.adventure_stage;g.save_profile()
func clear_route(c):
	g.clear_patch(c)
	for x in range(1,c.x+1):
		if g.inside(Vector2i(x,g.H/2)):g.grid[g.H/2][x]=0
	for y in range(mini(g.H/2,c.y),maxi(g.H/2,c.y)+1):
		if g.inside(Vector2i(c.x,y)):g.grid[y][c.x]=0
func spawn_enemy(c,kind,boss=false):
	c=g.nearest_playable(c)
	if not g.passable(c):g.clear_patch(c)
	var hp=maxi(6,roundi((10+stage.chapter*3)*party_scale*[.85,1.0,1.2][g.difficulty])) if boss else (1+int(stage.chapter/2)+(1 if g.difficulty==2 else 0)+(1 if party_scale>=2 else 0))
	enemies.append({"cell":c,"visual":Vector2(c),"from":Vector2(c),"move":1.0,"duration":.4,"cool":0.0,"hit":0.0,"freeze":0.0,"slow":0.0,"attack":2.5,"kind":kind,"hp":hp,"max_hp":hp,"boss":boss,"dead":false,"serial":spawn_serial,"anim_clock":spawn_serial*.137,"walk_clock":0.0,"facing":Vector2i.RIGHT,"reaction":0.0,"cast_time":0.0,"cast_total":0.0,"cast_wait":0.0,"death_age":0.0})
	spawn_serial+=1
func spawn_group(count):
	var positions=[Vector2i(g.W/3,3),Vector2i(g.W-7,g.H/2),Vector2i(g.W/2,g.H-5),Vector2i(5,g.H/2),Vector2i(g.W-12,5),Vector2i(g.W/3,g.H-8),Vector2i(g.W-10,g.H-8)]
	count=clampi(count+([-1,0,1][g.difficulty])+int(party_scale-1),1,9)
	for i in range(count):
		if enemies.filter(func(e):return not e.dead and not e.boss).size()>=12:break
		var c=g.nearest_playable(positions[(i+spawn_serial)%positions.size()])
		if g.grid[c.y][c.x]==3:continue
		if enemies.any(func(e):return not e.dead and e.cell==c):continue
		spawn_enemy(c,(stage.chapter+i)%6)
func spawn_wave():
	wave+=1;spawn_group(mini(7,2+wave+stage.chapter));g.announce(g.loc("第%d波怪物来袭！") % wave)
func advance_dialogue():
	dialogue+=1
	if dialogue>=stage.intro.size():g.state="play";g.countdown=1.5
func hit_enemy(e,damage=1,pulse=false):
	# Separate bubble explosions may each hit; lingering hazards retain a cooldown.
	if e.dead or (e.hit>0 and not pulse):return
	e.hp=maxi(0,e.hp-damage);e.hit=.7;e.reaction=.5;
	if not e.boss:e.freeze=maxf(e.freeze,.45)
	g.burst(g.center(e.cell),Color("edcfad"),8);g.sound("splash")
	if e.hp<=0:
		e.dead=true;g.stat("monsters")
		if e.boss:boss_dead=true;g.stat("bosses");g.announce(stage.boss+"恢复清醒了！")
		elif g.rng.randf()<.42:g.drops[e.cell]=[4,5,7,8,15,28][g.rng.randi_range(0,5)]
		if g.rng.randf()<.25:objects.append({"cell":e.cell,"type":"heart","active":false})
func update(dt):
	escort_hit=maxf(0,escort_hit-dt)
	var living=g.players.filter(func(p):return not p.dead)
	for p in g.players:
		if p.dead and p.cargo>0:
			objects.append({"cell":p.cell if g.grid[p.cell.y][p.cell.x]==0 else checkpoint,"type":"collect","active":false,"charge":0.0});p.cargo=0
		if p.dead and ((not p.bot and revives>0) or (p.bot and p.pve_revives>0)):
			if p.revive_wait<0:p.revive_wait=2.0
			p.revive_wait-=dt
			if p.revive_wait<=0:
				if p.bot:p.pve_revives-=1
				else:revives-=1
				p.dead=false;p.trap=0;p.shield=4;p.grace=3;p.revive_wait=-1
				var dest=p.cell;var nearest_distance=99999
				for y in range(int(g.camera.y)+2,mini(g.H-1,int(g.camera.y+g.VIEW_SIZE.y)-2)):
					for x in range(int(g.camera.x)+1,mini(g.W-1,int(g.camera.x+g.VIEW_SIZE.x)-2)):
						var candidate=Vector2i(x,y)
						if g.passable(candidate) and g.occupied(candidate,p.id)==null and g.manhattan(candidate,p.cell)<nearest_distance:
							dest=candidate;nearest_distance=g.manhattan(candidate,p.cell)
				g.teleport(p,dest);g.announce(g.loc("萤灯复苏！剩余%d次。") % revives)
	living=g.players.filter(func(p):return not p.dead)
	if living.is_empty() and not g.players.any(func(p):return p.dead and ((not p.bot and revives>0) or (p.bot and p.pve_revives>0))):g.finish_round(1);return
	for e in enemies:
		if e.dead:continue
		e.hit=maxf(0,e.hit-dt);e.freeze=maxf(0,e.freeze-dt);e.slow=maxf(0,e.slow-dt);e.attack-=dt;e.cool-=dt
		if e.freeze<=0:e.move=minf(1,e.move+dt/e.duration);e.visual=e.from.lerp(Vector2(e.cell),e.move)
		if g.grid[e.cell.y][e.cell.x]==3:e.dead=true;if_boss_fell(e);continue
		for f in g.blasts:
			if not f.get("pulse_only",false) and f.owner>=0 and f.cell==e.cell and f.time>0:g.bubble_fx.affect_enemy(e,f);break
		if e.dead or e.freeze>0:continue
		if living.is_empty():continue
		var target=living[0]
		for p in living:
			if g.manhattan(p.cell,e.cell)<g.manhattan(target.cell,e.cell):target=p
		var dest=target.cell
		for decoy in g.decoys:
			if g.manhattan(decoy.cell,e.cell)<=5:dest=decoy.cell;break
		if e.cool<=0 and e.move>=1:
			var d=enemy_direction(e,target,dest)
			var next=e.cell+d
			if d!=Vector2i.ZERO and g.passable(next) and not enemies.any(func(other):return other!=e and not other.dead and other.cell==next):
				e.from=e.visual;e.facing=d;e.cell=next;e.move=0;e.duration=.65 if e.boss else (.46+.025*e.kind);e.duration*=[1.25,1.0,.86][g.difficulty];e.duration*=1.5 if e.slow>0 else 1.0;e.cool=e.duration
		for p in living:
			if p.visual.distance_to(e.visual)<(.85 if e.boss else .60):
				if e.cast_time<=0:start_attack_animation(e,0)
				g.damage_player(p,-1)
		if e.boss and e.attack<=0:
			e.attack=(4.2 if e.hp>e.max_hp/2 else 2.8)*[1.3,1.0,.82][g.difficulty]
			boss_attack(e,target.cell)
		elif not e.boss and e.kind in [1,3,4] and e.attack<=0:
			e.attack=[7.0,5.5,4.5][g.difficulty];start_attack_animation(e,1.2)
			g.hazards.append({"cells":[target.cell],"wait":1.2,"duration":1.2,"type":"monster","skill":skill_kind(e),"caster":e.serial})
	for o in objects:
		if o.active:continue
		if o.type=="beacons":
			# Numbered lamps must be lit in order; stray splashes cannot skip steps.
			if objects.filter(func(obj):return obj.type=="beacons").find(o)!=progress:continue
			for f in g.blasts:
				if f.owner>=0 and f.cell==o.cell:o.active=true;progress+=1;g.sound("pickup");g.burst(g.center(o.cell),Color("fff0a0"),12);break
		else:
			var nearby=living.filter(func(p):return p.trap<=0 and (p.cell==o.cell or (o.type=="rescue" and g.manhattan(p.cell,o.cell)<=1)))
			if o.type=="rescue":o.charge=maxf(0,o.get("charge",0)+(dt if not nearby.is_empty() else -dt*2))
			for p in nearby:
				if o.type=="rescue":o.charge=1.0
				if o.type=="collect" and p.cargo>0:continue
				o.active=true;g.sound("pickup");g.burst(g.center(o.cell),Color("bcf2ad"),12)
				if o.type=="heart":p.trap=0;p.shield=maxf(p.shield,4);p.grace=2
				elif o.type=="collect":p.cargo+=1;g.announce("携带物资，返回中央出口交付。")
				else:
					progress+=1
					if o.type=="rescue" and p.get("control",p.id)==0:g.stat("rescues")
				break
	for p in living:
		if p.cargo>0 and g.manhattan(p.cell,checkpoint)<=1:progress+=p.cargo;p.cargo=0;g.sound("pickup");g.announce("物资已交付！")
	update_bonus(dt,living)
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
			if wave_wait<=0 and not objective_done:wave_wait=[12,10,8][g.difficulty];spawn_group(2)
		"escort":
			if not escort_arrived and living.any(func(p):return p.trap<=0 and g.manhattan(p.cell,escort_cell)<=3):
				escort_timer-=dt
				if escort_timer<=0:
					if escort_cell.x in escort_stations and not escort_stops.has(escort_cell.x):
						escort_fuel+=dt
						if escort_fuel<1.5:escort_timer=0
						else:escort_stops.append(escort_cell.x);escort_fuel=0;g.announce("补给完成，运输车继续前进。")
					escort_timer=0 if escort_cell.x in escort_stations and not escort_stops.has(escort_cell.x) else .65
					var next=escort_cell+Vector2i.RIGHT
					if (escort_cell.x not in escort_stations or escort_stops.has(escort_cell.x)) and escort_cell!=escort_goal and g.passable(next) and not enemies.any(func(e):return not e.dead and e.cell==next):escort_cell=next
			escort_visual=escort_visual.lerp(Vector2(escort_cell),minf(1,dt*8))
			if not escort_arrived and escort_hit<=0:
				var attacked=enemies.any(func(e):return not e.dead and g.manhattan(e.cell,escort_cell)<=1)
				attacked=attacked or g.blasts.any(func(f):return f.owner<0 and f.cell==escort_cell)
				if attacked:escort_hp-=1;escort_hit=1.5;g.burst(g.center(escort_cell),Color("ffc6a7"),6)
			if escort_hp<=0:g.finish_round(1);return
			progress=mini(escort_distance,escort_cell.x-3)
			if not escort_arrived and escort_cell==escort_goal and escort_visual.distance_to(Vector2(escort_goal))<.03:
				escort_visual=Vector2(escort_goal);escort_arrived=true
			objective_done=escort_arrived
	if objective_done:
		for p in living:
			if (not p.bot or g.humans==0) and g.manhattan(p.cell,checkpoint)<=1:g.finish_round(0);return
	if g.clock_time<=-35:g.finish_round(1)
func update_bonus(dt,living):
	for o in bonus_objects:
		if o.active:continue
		var nearby=living.filter(func(p):return p.trap<=0 and g.manhattan(p.cell,o.cell)<=1)
		var ready=not nearby.is_empty() if o.type=="collect" else false
		if o.type=="hold":o.charge=maxf(0,o.charge+(dt if not nearby.is_empty() else -dt));ready=o.charge>=1.2
		elif o.type=="water":ready=g.blasts.any(func(f):return f.owner>=0 and f.cell==o.cell)
		if not ready:continue
		o.active=true;bonus_progress+=1;g.world_fx.impact(g.center(o.cell),5,40);g.sound("pickup")
		if not living.is_empty():
			var hero=living[0]
			for p in living:
				if g.manhattan(p.cell,o.cell)<g.manhattan(hero.cell,o.cell):hero=p
			g.bubble_fx.infuse(hero,1+stage.chapter);hero.shield=maxf(hero.shield,4)
		if bonus_progress==2:
			g.profile.adventure_bonus[str(g.adventure_stage)]=true;g.stat("secrets");g.save_profile();g.announce("支线完成！获得属性核心和守护。")
func if_boss_fell(e):
	g.stat("monsters")
	if e.boss:boss_dead=true;g.stat("bosses")
func boss_attack(e,target):
	start_attack_animation(e,1.6 if e.hp>e.max_hp/2 else 1.1)
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
	g.hazards.append({"cells":marked,"wait":1.6 if e.hp>e.max_hp/2 else 1.1,"duration":1.6 if e.hp>e.max_hp/2 else 1.1,"type":"boss","skill":skill_kind(e),"caster":e.serial})
	g.announce(stage.boss+"蓄力！避开亮起的区域。")
func bot_target(p):
	if objective_done or p.get("cargo",0)>0:return checkpoint
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
			if not o.active and o.type=="beacons":target=o.cell;break
	return target if target!=null else checkpoint
func should_bomb(p):
	if enemies.any(func(e):return not e.dead and g.manhattan(p.cell,e.cell)<=p.range+1):return true
	return stage.mission=="beacons" and objects.any(func(o):return not o.active and o.type=="beacons" and g.manhattan(p.cell,o.cell)<=p.range)
func freeze_nearby(p):
	for e in enemies:
		if not e.dead and g.bubble_fx.clear_path(p.cell,e.cell,3):e.freeze=maxf(e.freeze,.65 if e.boss else 2.0);g.burst(g.center(e.cell),Color("bbf2ff"),8)
func object_icon(pos,kind,size=20,tint=Color.WHITE):
	g.hd.sprite("missions/missions-hd.png",kind,pos,Vector2.ONE*size,tint)

func draw_checkpoint():
	# Footprint, rather than sprite height, determines depth.
	object_icon(g.center(checkpoint)-Vector2(19,23),4,38)
	if objective_done:
		g.canvas.draw_arc(g.center(checkpoint),17,0,TAU,32,Color("d9ffb1"),1)
		g.text_at("交付 / 出口",g.center(checkpoint)+Vector2(-20,-25),12,Color("d9ffb1"),44)

func draw_object(o):
	if o.active and o.type not in ["rescue","beacons"]:return
	var kind={"collect":0 if stage.chapter==0 else 5,"rescue":1,"beacons":2,"heart":7}.get(o.type,0)
	var size=24 if o.type in ["rescue","beacons"] else 18
	var bob=sin(g.elapsed*2+o.cell.x)*.45
	var pos=g.center(o.cell)-Vector2(size/2.0,size-8+bob)
	var tint=Color("9dc3bd") if o.type=="beacons" and not o.active else Color.WHITE
	object_icon(pos,6 if o.active and o.type=="rescue" else kind,size,tint)
	if o.type=="beacons":
		g.text_at(str(objects.filter(func(obj):return obj.type=="beacons").find(o)+1),g.center(o.cell)+Vector2(-3,-29),12,Color("fff7b1") if not o.active else Color("94d9c1"))
		if o.active:
			g.canvas.draw_arc(g.center(o.cell),10,0,TAU,24,Color("b8eaff"),1)
			g.canvas.draw_circle(g.center(o.cell)-Vector2(0,15),4,Color(.48,.8,1,.22))
	if o.type=="rescue":
		g.text_at("已获救" if o.active else "等待营救",g.center(o.cell)+Vector2(-18,-29),12,Color("bcf2ad") if o.active else Color("f2d7b4"),38)
		if not o.active:
			g.rect(g.center(o.cell)+Vector2(-10,10),Vector2(20,2),g.INK)
			g.rect(g.center(o.cell)+Vector2(-10,10),Vector2(20*o.get("charge",0),2),Color("bcf2ad"))

func draw_bonus(o):
	if o.active:return
	object_icon(g.center(o.cell)-Vector2(12,19+sin(g.elapsed*3)*.5),5 if o.type=="collect" else (2 if o.type=="water" else 0),24)
	g.canvas.draw_arc(g.center(o.cell),11,0,TAU,24,Color("c6afff"),1)
	if o.type=="hold":g.rect(g.center(o.cell)+Vector2(-9,10),Vector2(18*o.charge/1.2,2),Color("dec3ff"))

func draw_cargo(p):
	if not p.dead and p.get("cargo",0)>0:object_icon(g.ORIGIN+p.visual*g.TILE+Vector2(14,-25),0,14)

func draw_escort():
	if escort_arrived:return
	var cart=g.ORIGIN+escort_visual*g.TILE+Vector2(g.TILE/2.0,g.TILE/2.0)
	object_icon(cart-Vector2(19,24+sin(g.elapsed*7)*.35),3,38)
	g.health_bar(cart+Vector2(-13,12),escort_hp,8,26,2)

func draw_enemy(e):
	if e.dead and e.death_age>=3:return
	var size=32 if e.boss else 20
	var pos=g.ORIGIN+e.visual*g.TILE+Vector2(g.TILE/2.0,g.TILE/2.0)
	var pose=enemy_pose(e)
	var tint=Color(1.3,1.16,1.08) if e.hit>.45 and not e.dead else Color.WHITE
	g.canvas.draw_set_transform(pos+Vector2(sin(g.elapsed*83),cos(g.elapsed*71))*g.shake)
	g.hd.enemy_frame(e.kind,pose.x,pose.y,Vector2(-size/2.0,-size*.75),size,tint)
	g.canvas.draw_set_transform(Vector2(sin(g.elapsed*83),cos(g.elapsed*71))*g.shake)
	if e.dead:return
	draw_cast_magic(e,pos,size)
	g.health_bar(pos+Vector2(-24 if e.boss else -10,11),e.hp,e.max_hp,48 if e.boss else 20,3)
	if e.freeze>0:g.canvas.draw_arc(pos,12,0,TAU,20,Color("b2e9ff"),1)

func start_attack_animation(e,wait):
	e.cast_wait=wait;e.cast_total=wait+.45;e.cast_time=e.cast_total
func update_animation(dt):
	for e in enemies:
		if e.dead:e.death_age+=dt;continue
		e.reaction=maxf(0,e.reaction-dt);e.cast_time=maxf(0,e.cast_time-dt)
		if e.freeze>0:continue
		e.anim_clock+=dt
		if e.move<1:e.walk_clock+=dt
		else:e.walk_clock=0
func enemy_pose(e):
	if e.dead:return Vector2i(5,clampi(int(e.death_age/.14),0,5))
	if e.reaction>0:return Vector2i(4,clampi(int((.5-e.reaction)*12),0,5))
	if e.cast_time>0:
		var progress=e.cast_total-e.cast_time
		var frame=clampi(int(progress/maxf(.001,e.cast_wait)*2),0,1) if progress<e.cast_wait else 2+clampi(int((progress-e.cast_wait)/.45*4),0,3)
		return Vector2i(3,frame)
	if e.freeze>0:return Vector2i(0,0)
	if e.move<1:return Vector2i(2 if e.facing.x<0 else 1,int(e.walk_clock/maxf(.1,e.duration)*6)%6)
	return Vector2i(0,int(e.anim_clock*4)%6)

func objective_label():
	if objective_done:return "任务完成！去中央出口"
	match stage.mission:
		"boss":
			var bosses=enemies.filter(func(e):return e.boss)
			return stage.boss+" %d/%d" % [bosses[0].hp,bosses[0].max_hp] if not bosses.is_empty() else "寻找守护者"
		"waves":return g.loc("波次 %d/%d · 敌人%d") % [wave,stage.target,enemies.filter(func(e):return not e.dead).size()]
		"escort":return g.loc("护送 %d/%d · 耐久%d") % [progress,escort_distance,escort_hp]
		_:return g.loc("任务进度 %d/%d") % [progress,stage.target]
func draw_sidebar():
	g.wrapped(stage.objective,Vector2(529,120),8,g.CREAM)
	if stage.mission=="boss" and not objective_done:
		g.text_at(stage.boss,Vector2(529,178),12,Color("ffe3a0"))
		var bosses=enemies.filter(func(e):return e.boss)
		if not bosses.is_empty():g.text_at(g.loc("生命 %d/%d") % [bosses[0].hp,bosses[0].max_hp],Vector2(529,197),12,Color("ffe3a0"))
	else:g.wrapped(objective_label(),Vector2(529,174),8,Color("ffe3a0"))
	g.wrapped(SIDE_QUESTS[g.adventure_stage-1],Vector2(529,223),8,Color("dec3ff"))
	g.text_at(g.loc("支线 %d/2") % bonus_progress,Vector2(529,263),12,Color("dec3ff"))
	g.text_at(["触碰收集","停留充能","水柱激活"][(g.adventure_stage-1)%3],Vector2(529,279),12,Color("b8d8c3"))
	g.text_at(g.loc("剩余复苏 %d") % revives,Vector2(529,293),12,Color("ffe3a0"))
func draw_story():
	g.canvas.draw_texture_rect(g.backgrounds[g.Catalog.MAPS[g.arena].theme],Rect2(Vector2.ZERO,Vector2(640,360)),false)
	g.rect(Vector2.ZERO,Vector2(640,360),Color(.03,.05,.1,.4))
	g.centered(Story.CHAPTERS[stage.chapter].name,49,24,Color("ffe4a5"))
	g.centered(g.loc("第%d节 · %s") % [int((g.adventure_stage-1)%4)+1,stage.name],77,12,g.CREAM)
	g.mini_board(Vector2(226,87),9)
	g.panel(Vector2(30,237),Vector2(580,98),Color("a1c7c1"))
	var line=stage.intro[dialogue]
	if line[0]==stage.boss:
		g.hd.enemy_sprite(6+stage.chapter,Vector2(43,245),48)
	elif line[0] in ["蓝莓","桃桃","薄荷"]:
		g.portrait(Vector2(43,245),["蓝莓","桃桃","薄荷"].find(line[0]),Vector2(40,48))
	else:object_icon(Vector2(43,245),5 if line[0]=="旁白" else (4 if line[0]=="任务" else 6),40)
	g.text_at(line[0],Vector2(99,258),12,Color("ffe3a0"))
	g.wrapped(line[1],Vector2(99,279),40,g.CREAM,4)
	g.centered("回车 / 空格 / 点击继续 · ESC 跳过对白 · P 暂停",351,12,Color("b9d9d0"))

func enemy_direction(e,target,dest):
	var blocked={}
	for other in enemies:
		if other!=e and not other.dead:blocked[other.cell]=0
	if g.difficulty>0:
		for f in g.blasts:
			if not f.get("pulse_only",false):blocked[f.cell]=0
		for b in g.bombs:
			if b.timer<1.2:
				for c in g.blast_cells(b):blocked[c]=0
		for hazard in g.hazards:
			if hazard.wait<.8:
				for c in hazard.cells:blocked[c]=0
		if not e.boss and dest==target.cell and g.manhattan(e.cell,dest)>2:
			var flank=dest+g.DIRS[e.serial%4]*(2 if g.difficulty==2 else 1)
			if g.passable(flank) and not blocked.has(flank):dest=flank
	return g.route_direction({"cell":e.cell,"cloak":0,"id":-1},dest,blocked)

func skill_kind(e):
	return [3,4,5,6,7][clampi(e.kind-6,0,4)] if e.boss else [7,0,4,1,2,7][clampi(e.kind,0,5)]

func draw_cast_magic(e,pos,size):
	if e.cast_time<=0:return
	var elapsed=e.cast_total-e.cast_time
	var charging=elapsed<e.cast_wait
	var progress=clampf(elapsed/maxf(.01,e.cast_wait),0,1) if charging else clampf((elapsed-e.cast_wait)/.45,0,1)
	var frame=0 if charging else 1 if progress<.4 else 2 if progress<.75 else 3
	var side=(9+progress*5 if charging else 17-progress*7)*(1.25 if e.boss else 1.0)
	var alpha=.45+progress*.35 if charging else 1-progress*.65
	g.hd.sprite("effects/monster-skills-v474.png",frame*8+skill_kind(e),pos+Vector2(size*.3-side/2,-size*.15-side/2),Vector2.ONE*side,Color(1,1,1,alpha))

func draw_skill_warning(hazard,c):
	var pos=g.center(c)
	var progress=clampf(1-hazard.wait/hazard.get("duration",1.6),0,1)
	var color=Color(SKILL_COLORS[hazard.skill])
	g.canvas.draw_rect(Rect2(pos-Vector2(7,7),Vector2(14,14)),Color(color,.055+progress*.07))
	for corner in [Vector2(-7,-7),Vector2(7,-7),Vector2(-7,7),Vector2(7,7)]:
		var at=pos+corner
		g.canvas.draw_line(at,at-Vector2(signf(corner.x)*3,0),Color(color,.65+progress*.3),.65)
		g.canvas.draw_line(at,at-Vector2(0,signf(corner.y)*3),Color(color,.65+progress*.3),.65)
	g.hd.sprite("effects/monster-skills-v474.png",hazard.skill,pos-Vector2(4,4),Vector2(8,8),Color(1,1,1,.25+progress*.4))

func draw_skill_hit(f):
	var age=clampf(1-f.time/f.get("duration",.6),0,1)
	var frame=1 if age<.32 else 2 if age<.7 else 3
	var side=14+sin(age*PI)*2
	g.hd.sprite("effects/monster-skills-v474.png",frame*8+f.skill,g.center(f.cell)-Vector2.ONE*side/2,Vector2.ONE*side,Color(1,1,1,minf(1,f.time/.15)))

func draw_skill_travel():
	for hazard in g.hazards:
		if not hazard.has("skill") or hazard.type!="monster" or hazard.wait>.35 or hazard.cells.is_empty():continue
		var caster=null
		for e in enemies:
			if e.serial==hazard.caster and not e.dead:caster=e;break
		if caster==null:continue
		var progress=clampf(1-hazard.wait/.35,0,1)
		var start=g.ORIGIN+caster.visual*g.TILE+Vector2(8,2)
		var end=g.center(hazard.cells[0])
		var pos=start.lerp(end,progress)-Vector2(0,sin(progress*PI)*5)
		g.hd.sprite("effects/monster-skills-v474.png",hazard.skill,pos-Vector2(4,4),Vector2(8,8))
