extends RefCounted
const TITLES=["道具","角色","坐骑","怪物","方块","机关","地图","任务","任务物品"]
const ENEMIES=[
 ["墨泡史莱姆","游荡的墨潮生物。用水柱击败，注意保持退路。"],
 ["毒蕈精","孢子区里的小怪，避开地图毒雾后再进攻。"],
 ["砂甲虫","遗迹里的甲虫，移动通道较窄时可用泡泡封路。"],
 ["珊瑚水母","深海居民被墨潮感染后的形态，可以用冰晶减慢它。"],
 ["巡逻飞蜂","空港的巡逻机械，利用雷鸣核心扩大命中范围。"],
 ["墨潮卫兵","王城守卫，用烈焰强化伤害或诱饵转移注意。"],
 ["苔冠树王","第一章守护者，孢子十字攻击；半血后攻击加快。"],
 ["砂钟守卫","第二章守护者，攻击整行与整列；提前离开警示带。"],
 ["铁钳蟹将","第三章守护者，攻击环形区域；利用间隙移动。"],
 ["雷翼飞艇","第四章守护者，瞄准角色所在区域；保持移动。"],
 ["墨潮大王","第五章守护者，释放多方向冲击；注意连锁与回声。"]]
const MISSION_OBJECTS=[
 ["萤灯种","收集后携带回中央交付点。每人一次携带一件，被击败会掉落，可重新拾取。"],
 ["笼中居民","接触笼子即可解开牢笼。居民获救后会站起挥手。"],
 ["玻璃信标","按标号顺序用水柱激活。亮起的玻璃灯罩表示该座信标已完成。"],
 ["远征补给车","队员保持在三格内护送，在沿途补给站靠近充能。车上的耐久条耗尽会失败。"],
 ["归航交付站","中央的收集箱接收携带物；全部任务完成后，走进发光归航门离开关卡。"],
 ["航海罗盘","收集任务和支线里出现的航海遗物。主任务物品需要送回交付站。"],
 ["获救居民","居民已经脱离牢笼，留在原处向你挥手，不会阻挡队员移动。"],
 ["医疗补给包","靠近拾取获得护盾与保护，可在战斗间隙补充防护。"]]
const BOXES=[
 ["承重墙","1×1，无法破坏。挡住角色、泡泡、水柱和光线，可利用墙角躲避爆炸。"],
 ["坍塌地块","倒计时归零后逐圈变成深渊，无法通行；跌落会出局。"],
 ["普通木箱","1×1，一点耐久。普通掉落率 76%。木板纹理随地图主题变化。"],
 ["可推轮箱","1×1，一点耐久。走向箱子可把它推到空格，不能推过人物、墙或泡泡。"],
 ["加固箱","1×1，两点耐久。第一次命中产生裂纹，第二次破坏。掉落率 95%。"],
 ["宝库箱","2×2，共八点耐久。同一次爆炸只扣一点血，破坏后掉落坐骑、核心与成长奖励。"],
 ["藏身灌木","不可摧毁，四向可进入。己方保留淡轮廓，敌方无法追踪；水柱仍可进入。"],
 ["水泥管道","不可摧毁，仅沿两个开口进出；侧壁挡住人物、泡泡与水柱。"],
 ["空心树干","森林与沼泽的双向藏身处，开口可通行，树干侧壁挡住人物与水柱。"],
 ["四门小屋","主题藏身建筑，四向出入；不会挡住水柱，不能靠藏身免疫伤害。"],
 ["四门帐篷","营地藏身处，四向出入；己方保留淡轮廓，水柱可进入。"]]
const RULE_NAMES={"race":"赛车检查点","cave":"常夜洞窟","cavefog":"洞窟迷雾","tide":"潮汐坍塌","portal":"传送环","flow":"水流","mushroom":"蘑菇跳板","vine":"再生藤蔓","wind":"阵风","ice":"滑冰","blizzard":"暴风雪","sand":"流沙","gate":"开关石门","lava":"熔岩喷发","quake":"地震","spring":"弹床","treasure":"星币争夺","laser":"激光","magnet":"磁场","gravity":"低重力","meteor":"陨星","train":"列车","storm":"雷暴","mud":"泥潭","poison":"毒雾","geyser":"喷泉","mirror":"棱镜","spikes":"尖刺","echo":"爆炸回声","currents":"双向潮流","whirlpool":"漩涡","chronofield":"时钟场","gustpads":"风垫","bridges":"浮桥","turrets":"瞄准炮台","blackout":"灯塔熄灭"}
var g
var category=0
var selected=0
var return_state="menu"
var entries:Array=[]
var previews:Dictionary={}
func _init(game):g=game;rebuild()
func rebuild():
	entries.clear()
	for kind in range(1,g.Catalog.ITEMS.size()):
		var item=g.Catalog.ITEMS[kind]
		if item.kind=="removed":continue
		entries.append({"category":0,"name":item.name,"tip":item.tip,"kind":kind})
	for kind in range(MISSION_OBJECTS.size()):entries.append({"category":8,"name":MISSION_OBJECTS[kind][0],"tip":MISSION_OBJECTS[kind][1],"kind":kind,"art":"mission"})
	for kind in range(g.Catalog.CHARACTERS.size()):
		var item=g.Catalog.CHARACTERS[kind]
		entries.append({"category":1,"name":item.name,"tip":item.perk,"kind":kind})
	for kind in range(1,g.Catalog.MOUNTS.size()):
		var item=g.Catalog.MOUNTS[kind]
		entries.append({"category":2,"name":item.name,"tip":item.tip,"kind":kind})
	for kind in range(ENEMIES.size()):entries.append({"category":3,"name":ENEMIES[kind][0],"tip":ENEMIES[kind][1],"kind":kind})
	for kind in range(BOXES.size()):entries.append({"category":4,"name":BOXES[kind][0],"tip":BOXES[kind][1],"kind":kind})
	var rules:Dictionary={}
	for map in g.Catalog.MAPS:
		if not rules.has(map.rule):
			entries.append({"category":5,"name":RULE_NAMES[map.rule],"tip":map.tip,"kind":g.Catalog.MAPS.find(map),"rule":map.rule});rules[map.rule]=true
	for info in [
		["昼夜循环","普通地图每九十秒经历白昼、黄昏、夜晚与黎明。夜晚视野仅限角色与有效光源附近。"],
		["周期雾气","雾气随机覆盖地图区域，每分钟有一段风吹散雾的时间。火把扩大附近视野，照明弹可照亮全图。"],
		["洞窟固定火把","洞窟每局随机布置固定火把，不会熄灭。墙和箱体会遮挡光线。"],
		["照明弹照明","使用照明弹后，全图照亮八秒。结束后恢复原有黑夜和雾气。"],
		["手持火把","使用后，二十秒内将自身视野半径由约三格扩大到近六格。"]]:entries.append({"category":5,"name":info[0],"tip":info[1],"kind":40,"rule":info[0]})
	for kind in range(g.Catalog.MAPS.size()):
		var map=g.Catalog.MAPS[kind]
		entries.append({"category":6,"name":map.name,"tip":map.tip,"kind":kind})
	for kind in range(g.adventure.Story.STAGES.size()):
		var stage=g.adventure.Story.STAGES[kind]
		entries.append({"category":7,"name":stage.name,"tip":stage.objective+"。"+stage.outro+" "+g.adventure.SIDE_QUESTS[kind],"kind":kind})
func open():
	return_state=g.state;g.state="codex";g.queue_redraw()
func close():g.state=return_state;g.queue_redraw()
func current():return entries.filter(func(e):return e.category==category)
func input_key(key):
	if key in [KEY_ESCAPE,KEY_F2]:close();return
	if key in [KEY_LEFT,KEY_RIGHT,KEY_TAB]:category=posmod(category+(-1 if key==KEY_LEFT else 1),TITLES.size());selected=0
	elif key in [KEY_UP,KEY_DOWN,KEY_PAGEUP,KEY_PAGEDOWN]:selected=posmod(selected+(-1 if key==KEY_UP else (1 if key==KEY_DOWN else (-8 if key==KEY_PAGEUP else 8))),current().size())
func input_mouse(pos):
	if Rect2(540,10,80,22).has_point(pos):close();return
	if pos.y>=46 and pos.y<70:category=clampi(int((pos.x-16)/67),0,8);selected=0;return
	for row in range(8):
		var index=int(selected/8)*8+row
		if Rect2(18,81+row*29,204,27).has_point(pos) and index<current().size():selected=index
	if pos.y>320:selected=posmod(selected+(-8 if pos.x<130 else 8),current().size())
func icon(entry,pos,side):
	var kind=entry.kind
	if entry.get("art","")=="mission":g.adventure.object_icon(pos,kind,side);return
	match entry.category:
		0:g.item_icon(pos,kind,side)
		1:g.hero_sprite(pos,kind,Vector2(side,side*1.2),0,4+int(g.elapsed*8)%8)
		2:g.hd.mount_sprite(kind,0,pos,Vector2(side,side*.875),Color.WHITE,g.elapsed*5)
		3:g.hd.enemy_frame(kind,0,int(g.elapsed*4)%6,pos,side)
		4:
			if kind>=6:g.hd.sprite("maps/decorations/shelters-v480.png",{6:0,7:1,8:3,9:5,10:6}[kind],pos,Vector2.ONE*side)
			elif kind==5:g.hd.theme_sprite(g.Catalog.MAPS[g.arena].theme,6,pos,Vector2.ONE*side)
			elif kind>=2:g.hd.theme_sprite(g.Catalog.MAPS[g.arena].theme,kind+1,pos,Vector2.ONE*side)
			else:
				if kind==0:g.hd.theme_sprite(g.Catalog.MAPS[g.arena].theme,2,pos,Vector2.ONE*side)
				else:g.rect(pos,Vector2.ONE*side,Color("101524"))
		5:
			var rule=entry.get("rule","")
			var tile={"tide":1,"portal":4,"flow":6,"currents":6,"ice":12,"blizzard":12,"sand":14,"whirlpool":14,"gate":10,"laser":9,"spikes":1,"turrets":8,"gravity":11,"gustpads":6,"wind":11,"bridges":6,"mirror":13,"meteor":15,"storm":15,"lava":15,"quake":15,"train":7,"chronofield":11,"geyser":3,"mud":14,"echo":5,"magnet":13}
			if tile.has(rule):g.hd.sprite("maps/mechanisms/mechanisms-v472.png",tile[rule],pos,Vector2.ONE*side)
			elif rule=="vine" or rule=="poison":g.hd.sprite("effects/water-vines-v473.png",3,pos,Vector2.ONE*side)
			elif rule=="race":g.hd.sprite(g.Racing.ART,11,pos,Vector2.ONE*side)
			elif rule=="treasure":g.item_icon(pos,19,side)
			elif rule=="mushroom" or rule=="spring":g.hd.sprite("maps/mechanisms/mechanisms-v472.png",0,pos,Vector2.ONE*side)
			elif rule in ["洞窟固定火把","手持火把","cave","blackout"]:g.item_icon(pos,27,side)
			elif rule=="照明弹照明":g.item_icon(pos,26,side)
			else:
				g.canvas.draw_circle(pos+Vector2.ONE*side*.5,side*.3,Color("b8cbe0"))
				g.canvas.draw_arc(pos+Vector2.ONE*side*.5,side*.38,0,TAU,24,Color("ebddb2"),1)
		6,7:draw_preview(entry,Rect2(pos,Vector2.ONE*side))
func draw():
	g.page_header("群岛全图鉴")
	for i in range(TITLES.size()):g.button(Vector2(16+i*67,46),Vector2(63,24),TITLES[i],i==category)
	var items=current();selected=clampi(selected,0,items.size()-1);var e=items[selected]
	g.panel(Vector2(14,77),Vector2(211,269))
	for row in range(8):
		var index=int(selected/8)*8+row
		if index>=items.size():break
		var pos=Vector2(18,81+row*29)
		if index==selected:g.rect(pos,Vector2(204,27),Color("35596b"))
		icon(items[index],pos+Vector2(3,2),20)
		g.text_at(items[index].name,pos+Vector2(32,18),12,g.CREAM if index!=selected else Color("ffe08e"),166)
	g.text_at("%d / %d" % [selected+1,items.size()],Vector2(94,335),12)
	g.panel(Vector2(237,77),Vector2(386,269),Color("83b5b6"))
	if category in [6,7]:
		g.text_at(e.name,Vector2(252,101),20,Color("ffe08e"),353)
		g.panel(Vector2(251,110),Vector2(358,133),Color("527a8c"))
		draw_preview(e,Rect2(256,115,348,123))
		g.wrapped(e.tip,Vector2(254,261),29,g.CREAM,3)
		if category==6:g.text_at(g.loc("倒计时 %d 秒") % g.Catalog.MAPS[e.kind].seconds,Vector2(254,321),10)
		else:g.text_at(g.loc("剧情冒险 %d / 20") % (e.kind+1),Vector2(254,321),10)
	else:
		icon(e,Vector2(267,100),60)
		g.text_at(e.name,Vector2(341,127),22,Color("ffe08e"),266)
		g.wrapped(e.tip,Vector2(254,200),29,g.CREAM,7)
		if category==1:g.text_at("已解锁" if g.character_unlocked(e.kind) else g.loc("通%d关解锁") % g.Catalog.CHARACTERS[e.kind].unlock,Vector2(341,151),12,Color("a8efac"))
	g.text_at("左右换分类 · 上下浏览 · PgUp/PgDn 翻页 · ESC 返回",Vector2(249,335),12,Color("abd0ca"))

func preview(entry):
	var key=str(entry.category)+":"+str(entry.kind)
	if previews.has(key):return previews[key]
	var board=g.get_script().new()
	board.preview_only=true;board.profile=board.default_profile()
	board.mode=3 if entry.category==7 else 2
	board.adventure_stage=entry.kind+1 if entry.category==7 else 1
	board.map_rules=g.MapMechanisms.new(board);board.world_fx=g.WorldEffects.new(board);board.crates=g.Crates.new(board)
	board.adventure=g.Adventure.new(board);board.racing=g.Racing.new(board);board.rng.seed=1103+entry.kind
	board.build_board(board.adventure.Story.STAGES[entry.kind].map if entry.category==7 else entry.kind,entry.category==7)
	if entry.category==7:
		for i in range(4):board.players.append({"id":i,"bot":false,"cell":board.SPAWNS[i],"visual":Vector2(board.SPAWNS[i])})
		board.adventure.setup();board.world_fx.design_board(true);board.crates.setup();board.world_fx.add_shelters(true)
	var data={"grid":board.grid.duplicate(true),"void":board.map_void.duplicate(),"terrain":board.terrain.duplicate(true),"W":board.W,"H":board.H,"theme":board.Catalog.MAPS[board.arena].theme,"race":board.arena>=g.Racing.FIRST_MAP,"checkpoints":board.racing.checkpoints.duplicate(true)}
	previews[key]=data
	board.map_rules=null;board.world_fx=null;board.crates=null;board.adventure=null;board.racing=null;board.free()
	return data
func draw_preview(entry,frame):
	var data=preview(entry)
	var step=minf(frame.size.x/data.W,frame.size.y/data.H)
	var offset=frame.position+(frame.size-Vector2(data.W,data.H)*step)/2
	g.rect(frame.position,frame.size,Color("101a28"))
	for y in range(data.H):
		for x in range(data.W):
			var c=Vector2i(x,y)
			if data.void.has(c):continue
			var cell=data.grid[y][x]
			var kind=2 if cell==1 else 3 if cell==2 else (x+y)%2
			if data.race:g.rect(offset+Vector2(c)*step,Vector2.ONE*step,Color("537e56") if cell==1 else Color("aa744b") if cell==2 else Color("77888d"))
			else:g.hd.theme_sprite(data.theme,kind,offset+Vector2(c)*step,Vector2.ONE*step,Color.WHITE,false)
	for c in data.terrain:
		var type=data.terrain[c].type
		if type in ["portal","switch","vortex","spring","lava","spike","clock","rail","flow"]:
			var at=offset+(Vector2(c)+Vector2.ONE*.5)*step
			g.canvas.draw_circle(at,step*.3,Color("96dcf0") if type in ["flow","vortex"] else Color("f5d692"))
		elif type=="shelter":g.hd.sprite("maps/decorations/shelters-v480.png",data.terrain[c].art,offset+Vector2(c)*step,Vector2.ONE*step)

	if data.race:
		for i in range(data.checkpoints.size()):
			var cp=data.checkpoints[i];var side=Vector2(-cp.dir.y,cp.dir.x)
			g.canvas.draw_line(offset+(cp.pos-side*3)*step,offset+(cp.pos+side*3)*step,Color("ffe3a8") if i==0 else Color("7ce3ff"),maxf(1,step*.6))
