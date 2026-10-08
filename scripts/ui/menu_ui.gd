extends RefCounted

# Frontend pages share the same match configuration and save data as the game.
const PAGES=["menu","modes","lobby","settings","saves","save_confirm","about","seat","advanced"]
const TITLES=["单人闯关","赛车竞速","组队对战","剧情冒险 PVE"]
const DESCRIPTIONS=["挑战二十关经典竞技地图，击败电脑对手，解锁新角色。","驾驶赛车依次通过检查点，默认三圈，按冲线顺序为个人或队伍计分。","二至八个席位自由分成最多八队，每人一队即混战，先赢两局夺冠。","五章故事、二十个任务。和伙伴营救居民、护送车辆、挑战首领。"]
const BADGES=["1 位真人 · 20 关","1–4 位真人 · 2–8 席位","1–4 位真人 · 2–8 席位","1–4 位真人 · 5 章故事"]
const HUB=["选择游戏模式","继续上次模式","设置与音量","快捷键与操作","存档管理","全图鉴","局外统计","制作与版本"]
const SAVE_ACTIONS=["立即保存","创建备份","恢复备份","重置游戏进度","打开存档目录"]
var g
var focus=0
var mode_focus=0
var row=0
var page_return="menu"
var history:Array=[]
var message=""
var pending=""
var confirmation=0
var seat_slot=0
var seat_row=0
func _init(game):g=game
func active():return g.state in PAGES
func open_page(page):
	page_return=g.state
	history.append(g.state)
	g.state=page
	focus=0
	message=""
	if page=="characters":g.selection=g.slot_character(g.character_slot)
	if page=="maps":g.selection=maxi(0,g.selected_map)
func back():
	if g.state=="lobby":g.save_profile();g.state="modes";focus=g.mode
	elif g.state=="modes":g.state="menu";focus=0
	elif g.state=="save_confirm":g.state="saves"
	else:g.state=history.pop_back() if not history.is_empty() else "menu"
func enter_lobby(which):
	history.clear()
	g.mode=which;mode_focus=which;row=0
	if which==0:g.humans=1
	if which in [1,2]:g.seats=clampi(g.seats,2,8);g.team_count=mini(g.team_count,g.seats)
	if which==3:g.seats=4
	g.humans=g.lobby_roles().filter(func(value):return value).size()
	g.character_slot=mini(g.character_slot,g.humans-1)
	g.state="lobby";g.refresh_preview();g.save_profile()
func hub_action(index):
	match index:
		0:g.state="modes";focus=g.mode
		1:enter_lobby(g.mode)
		2:open_page("settings")
		3:open_page("help")
		4:open_page("saves")
		5:g.encyclopedia.open()
		6:open_page("stats")
		7:open_page("about")
		8:g.close_game()
func row_rect(index):return Rect2(25,(79+index*24) if g.mode==1 else (86+index*29),260,22 if g.mode==1 else 25)
func start_rect():return Rect2(25,298,260,30)
func slot_rect(index):return Rect2(309+(index%4)*74,241+(index/4)*42,69,37)
func rows():
	if g.mode==0:return ["stage","companion","difficulty","characters","start"]
	if g.mode==1:return ["race_map","humans","seats","teams","laps","race_time","difficulty","characters","start"]
	if g.mode==2:return ["map","humans","seats","teams","difficulty","characters","start"]
	return ["stage","humans","companion","difficulty","characters","start"]
func adjust(direction):
	var field=rows()[row]
	match field:
		"stage":
			if g.mode==0:g.campaign_stage=clampi(g.campaign_stage+direction,1,mini(20,int(g.profile.cleared)+1))
			else:g.adventure_stage=clampi(g.adventure_stage+direction,1,mini(20,int(g.profile.adventure_cleared)+1))
		"map":g.selected_map=posmod(g.selected_map+1+direction,45)-1
		"humans":
			g.humans=clampi(g.humans+direction,1,mini(4,g.seats));g.seat_roles.fill(-1)
		"seats":g.seats=clampi(g.seats+direction,2,8);g.humans=mini(g.humans,g.seats);g.team_count=mini(g.team_count,g.seats)
		"teams":g.team_count=clampi(g.team_count+direction,2,g.seats);g.seat_teams.fill(-1)
		"race_map":g.racing.selected=posmod(g.racing.selected+direction,3)
		"laps":g.racing.laps=clampi(g.racing.laps+direction,1,9)
		"race_time":g.racing.time_limit=clampi(g.racing.time_limit+direction*30,60,600)
		"companion":g.companion=not g.companion
		"difficulty":g.difficulty=posmod(g.difficulty+direction,3)
		"characters":g.character_slot=posmod(g.character_slot+direction,g.lobby_count())
	g.humans=g.lobby_roles().filter(func(value):return value).size()
	g.character_slot=mini(g.character_slot,g.lobby_count()-1)
	g.refresh_preview();g.save_profile()
func activate_row():
	match rows()[row]:
		"start":g.start_match()
		"map":open_page("maps")
		"characters":open_page("characters")
		_:adjust(1)
func settings_action(direction=1):
	match focus:
		0:g.language_return="settings";g.language_selection=g.I18n.LOCALES.find(g.i18n.locale);g.state="languages"
		1:g.music_volume=clampi(g.music_volume+direction*5,0,100);g.apply_audio_settings();g.save_profile()
		2:g.effects_volume=clampi(g.effects_volume+direction*5,0,100);g.apply_audio_settings();g.save_profile();g.sound("pickup")
		3:g.muted=not g.muted;g.apply_audio_settings();g.save_profile()
		4:
			var fullscreen=DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)
		5:open_page("help")
func input_key(key):
	if key==KEY_ESCAPE:back();return
	if key==KEY_F1:open_page("help");return
	match g.state:
		"menu":
			if key==KEY_TAB:focus=posmod(focus+1,9)
			elif key==KEY_UP:focus=6 if focus==8 else maxi(0,focus-2)
			elif key==KEY_DOWN:focus=8 if focus>=6 else focus+2
			elif key in [KEY_LEFT,KEY_RIGHT]:focus=(7 if key==KEY_LEFT else 0) if focus==8 else (focus^1)
			elif key in [KEY_ENTER,KEY_SPACE]:hub_action(focus)
		"modes":
			if key in [KEY_LEFT,KEY_RIGHT]:focus=posmod(focus+(1 if key==KEY_RIGHT else -1),4)
			elif key in [KEY_UP,KEY_DOWN]:focus=posmod(focus+2,4)
			elif key in [KEY_ENTER,KEY_SPACE]:enter_lobby(focus)
		"seat":
			if key in [KEY_UP,KEY_DOWN]:seat_row=posmod(seat_row+(-1 if key==KEY_UP else 1),4)
			elif key in [KEY_LEFT,KEY_RIGHT]:adjust_seat(-1 if key==KEY_LEFT else 1)
			elif key in [KEY_ENTER,KEY_SPACE]:
				if seat_row==1:g.character_slot=seat_slot;open_page("characters")
				elif seat_row==3:back()
				else:adjust_seat(1)
		"advanced":
			if key in [KEY_UP,KEY_DOWN]:focus=posmod(focus+(-1 if key==KEY_UP else 1),8)
			elif key in [KEY_LEFT,KEY_RIGHT,KEY_ENTER,KEY_SPACE]:adjust_advanced(-1 if key==KEY_LEFT else 1)
		"lobby":
			if key==KEY_A and g.mode==2:open_page("advanced")
			elif key==KEY_UP:row=posmod(row-1,rows().size())
			elif key==KEY_DOWN:row=posmod(row+1,rows().size())
			elif key in [KEY_LEFT,KEY_RIGHT]:adjust(-1 if key==KEY_LEFT else 1)
			elif key==KEY_ENTER:activate_row()
			elif key==KEY_SPACE:activate_row()
			elif key==KEY_C:open_page("characters")
			elif key==KEY_V and g.mode==2:open_page("maps")
			elif key==KEY_R and g.mode==2:g.selected_map=-1;g.refresh_preview();g.save_profile()
		"settings":
			if key in [KEY_UP,KEY_DOWN]:focus=posmod(focus+(-1 if key==KEY_UP else 1),6)
			elif key in [KEY_LEFT,KEY_RIGHT]:settings_action(-1 if key==KEY_LEFT else 1)
			elif key in [KEY_ENTER,KEY_SPACE]:settings_action()
		"saves":
			if key in [KEY_UP,KEY_DOWN]:focus=posmod(focus+(-1 if key==KEY_UP else 1),5)
			elif key in [KEY_ENTER,KEY_SPACE]:save_action(focus)
		"save_confirm":
			if key in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]:confirmation=1-confirmation
			elif key in [KEY_ENTER,KEY_SPACE]:
				if confirmation==1:perform_save_action()
				else:back()
func input_mouse(pos):
	if g.state!="menu" and Rect2(540,10,80,22).has_point(pos):back();return
	match g.state:
		"menu":
			for i in range(8):
				if hub_rect(i).has_point(pos):focus=i;hub_action(i);return
			if Rect2(546,326,76,23).has_point(pos):g.close_game()
		"modes":
			for i in range(4):
				if mode_rect(i).has_point(pos):focus=i;enter_lobby(i);return
		"advanced":
			for i in range(8):
				if Rect2(35,69+i*31,570,27).has_point(pos):focus=i;adjust_advanced(-1 if pos.x<340 else 1);return
		"lobby":
			if g.mode==2 and Rect2(25,271,260,22).has_point(pos):open_page("advanced");return
			if start_rect().has_point(pos):g.start_match();return
			for i in range(rows().size()-1):
				if row_rect(i).has_point(pos):
					row=i
					if rows()[row]=="map" or rows()[row]=="characters":activate_row()
					else:adjust(-1 if pos.x<160 else 1)
					return
			for i in range(8):
				if i<g.lobby_count() and slot_rect(i).has_point(pos):seat_slot=i;seat_row=0;g.character_slot=i;open_page("seat");return
			if Rect2(309,210,292,24).has_point(pos) and g.mode==2:open_page("maps")
		"seat":
			for i in range(4):
				if Rect2(40,100+i*45,280,35).has_point(pos):
					seat_row=i
					if i==1:g.character_slot=seat_slot;open_page("characters")
					elif i==3:back()
					else:adjust_seat(-1 if pos.x<180 else 1)
					return
		"settings":
			for i in range(6):
				if Rect2(100,68+i*40,440,34).has_point(pos):
					focus=i
					if i in [1,2] and pos.x>=325:
						var amount=clampi(int((pos.x-325)/185.0*100),0,100)
						if i==1:g.music_volume=amount
						else:g.effects_volume=amount
						g.apply_audio_settings();g.save_profile()
						if i==2:g.sound("pickup")
					else:settings_action(-1 if pos.x<320 else 1)
					return
		"saves":
			for i in range(5):
				if Rect2(365,85+i*43,235,34).has_point(pos):focus=i;save_action(i);return
		"save_confirm":
			if Rect2(145,243,155,32).has_point(pos):back()
			elif Rect2(335,243,155,32).has_point(pos):perform_save_action()
func hover(pos):
	match g.state:
		"menu":
			for i in range(8):
				if hub_rect(i).has_point(pos):focus=i
			if Rect2(546,326,76,23).has_point(pos):focus=8
		"modes":
			for i in range(4):
				if mode_rect(i).has_point(pos):focus=i
		"lobby":
			for i in range(rows().size()-1):
				if row_rect(i).has_point(pos):row=i
			if start_rect().has_point(pos):row=rows().size()-1
		"seat":
			for i in range(4):
				if Rect2(40,100+i*45,280,35).has_point(pos):
					seat_row=i
					return
		"settings":
			for i in range(6):
				if Rect2(100,68+i*40,440,34).has_point(pos):focus=i
		"saves":
			for i in range(5):
				if Rect2(365,85+i*43,235,34).has_point(pos):focus=i
func hub_rect(index):
	if index<2:return Rect2(36+index*166,132,156,42)
	return Rect2(36+((index-2)%2)*166,193+int((index-2)/2)*41,156,32)
func mode_rect(index):return Rect2(24+(index%2)*302,68+int(index/2)*128,290,116)
func card(pos,size,selected=false):
	g.panel(pos,size,Color("ffd18b") if selected else Color("497d9a"))
	g.rect(pos+Vector2(3,3),Vector2(size.x-6,2),Color("4e6981"))
	if selected:g.rect(pos+Vector2(3,5),Vector2(3,size.y-8),Color("ffcc78"))
func heading(title,subtitle=""):
	g.page_header(title)
	if subtitle!="":g.text_at(subtitle,Vector2(25,53),12,Color("aacdd9"),585)
func draw():
	match g.state:
		"menu":draw_hub()
		"modes":draw_modes()
		"lobby":draw_lobby()
		"seat":draw_seat()
		"advanced":draw_advanced()
		"settings":draw_settings()
		"saves":draw_saves()
		"save_confirm":draw_saves();draw_confirmation()
		"about":draw_about()
func draw_hub():
	g.rect(Vector2.ZERO,Vector2(640,360),Color("102237"))
	for n in range(9):
		var at=Vector2(400+n%3*82,42+n/3*105)+Vector2(sin(g.elapsed*.3+n)*8,cos(g.elapsed*.25+n)*7)
		g.canvas.draw_circle(at,28+n%3*10,Color(.24,.64,.75,.05))
		g.canvas.draw_arc(at,28+n%3*10,3.4,4.5,28,Color(.56,.87,.92,.12),1)
	g.text_at("泡泡糖",Vector2(36,60),36,Color("a4efff"),315)
	g.text_at("像素群岛大冒险",Vector2(38,87),16,Color("bfd2da"),315)
	g.text_at("47 张地图 · 最多 8 队对战",Vector2(38,111),12,Color("7fafbf"),315)
	for i in range(8):
		var r=hub_rect(i);card(r.position,r.size,focus==i)
		g.text_at(HUB[i],r.position+Vector2(12,27 if i<2 else 21),16 if i<2 else 12,Color("ffe3a8") if focus==i else g.CREAM,r.size.x-24)
	for i in range(3):
		g.hero_sprite(Vector2(410+i*60,145+sin(g.elapsed*.6+i)*2),[0,1,2][i],Vector2(45,60),0,0)
	g.hd.sprite("effects/bubbles-hd.png",0,Vector2(462,73),Vector2(62,62))
	g.text_at("和伙伴一起，守护泡泡群岛",Vector2(394,250),12,Color("c7dce2"),230)
	g.text_at(g.loc("上次模式：%s") % g.loc(TITLES[g.mode]),Vector2(37,326),10,Color("91aeba"),360)
	g.button(Vector2(546,326),Vector2(76,23),"退出游戏",focus==8)
func draw_modes():
	heading("选择游戏模式","选择玩法后进入专属大厅，再配置关卡、地图与队伍。")
	for i in range(4):
		var r=mode_rect(i)
		card(r.position,r.size,i==focus)
		g.hero_sprite(r.position+Vector2(9,17),[0,1,4,7][i],Vector2(55,73),0,0)
		g.text_at(TITLES[i],r.position+Vector2(72,25),18,Color("ffe0a0"),208)
		g.text_at(BADGES[i],r.position+Vector2(72,46),12,Color("8cd9d8"),208)
		g.wrapped(DESCRIPTIONS[i],r.position+Vector2(72,66),17,Color("d0dce0"),3)
		g.text_at("进入大厅 →",r.position+Vector2(10,106),9,Color("ffe4aa"),61)
	g.centered("方向键选择 · 回车进入大厅 · ESC 返回主菜单",343,12)
func value(field):
	match field:
		"difficulty":return g.loc(["轻松","标准","挑战"][g.difficulty])
		"stage":return g.loc("第 %d / 20 关") % (g.adventure_stage if g.mode==3 else g.campaign_stage)
		"map":return g.loc("随机地图") if g.selected_map<0 else g.loc(g.Catalog.MAPS[g.selected_map].name)
		"humans":return g.loc("%d 位真人") % g.humans
		"seats":return g.loc("%d 个席位，电脑补齐") % g.seats
		"teams":return (g.loc("%d 支队伍") % g.team_count)+(" · "+g.loc("混战") if g.team_count==g.seats else "")
		"race_map":return g.Catalog.MAPS[44+g.racing.selected].name
		"laps":return g.loc("%d 圈") % g.racing.laps
		"race_time":return g.loc("%d 秒") % g.racing.time_limit
		"companion":return g.loc("开启") if g.companion else g.loc("关闭")
		"characters":return g.loc("玩家 %d · %s") % [g.character_slot+1,g.loc(g.character_name(g.slot_character(g.character_slot)))]
	return ""
func draw_lobby():
	heading(TITLES[g.mode],"模式大厅 · 配置完成后开始游戏")
	g.text_at(DESCRIPTIONS[g.mode],Vector2(25,73),9,Color("a7cbd8"),260)
	var labels={"difficulty":"AI 难度","stage":"当前关卡","map":"对战地图","humans":"真人人数","seats":"总席位","teams":"分队方式","companion":"电脑队友","characters":"角色选择","race_map":"赛车地图","laps":"目标圈数","race_time":"比赛时间"}
	for i in range(rows().size()-1):
		var field=rows()[i];var pos=row_rect(i).position
		card(pos,row_rect(i).size,row==i)
		g.text_at(labels[field],pos+Vector2(10,17),12,Color("a1c6d6"),78)
		g.text_at(value(field),pos+Vector2(94,17),12,g.CREAM,150)
	if g.mode==3:
		var stage=g.adventure.Story.STAGES[g.adventure_stage-1]
		g.text_at(g.adventure.Story.CHAPTERS[stage.chapter].name,Vector2(25,264),12,Color("b4ddc2"),260)
		g.text_at(stage.objective,Vector2(25,282),12,Color("a7c9d5"),260)
	elif g.mode==0:
		g.text_at("第五关起可带电脑队友",Vector2(25,244),12,Color("b4ddc2"),260)
		g.text_at("电脑对手造型随关卡变化",Vector2(25,265),12,Color("a7c9d5"),260)
	elif g.mode==2:
		g.button(Vector2(25,271),Vector2(260,22),"高级规则 A")
	g.button(start_rect().position,start_rect().size,"开始游戏",rows()[row]=="start")
	card(Vector2(309,68),Vector2(292,137))
	g.text_at("随机地图 · 开局揭晓" if g.selected_map<0 and g.mode==2 else g.Catalog.MAPS[g.arena].name,Vector2(322,88),12,Color("ffe3a8"),272)
	g.mini_board(Vector2(391,91) if g.mode!=1 else Vector2(374,93),minf(4.7,minf(210.0/g.W,92.0/g.H)))
	var seconds=g.match_seconds(g.arena)
	g.text_at((g.loc("%d 圈 · %d 秒 · 分屏竞速") % [g.racing.laps,seconds]) if g.mode==1 else g.loc("倒计时 %d 秒 · 到时逐圈坍塌") % seconds,Vector2(322,199),12,Color("a2c9d3"),270)
	if g.mode==2:g.button(Vector2(309,210),Vector2(292,24),"浏览地图 V · R 随机")
	elif g.mode==1:g.text_at("阵亡十秒复活 · 赛车检查点",Vector2(322,226),10,g.CREAM,270)
	else:g.text_at(g.loc("已通关 %d / 20 · 左右切换已解锁关卡") % int(g.profile.adventure_cleared if g.mode==3 else g.profile.cleared),Vector2(322,221),12,Color("9cd0bd"),292)
	var count=g.lobby_count()
	var roles=g.lobby_roles()
	for i in range(count):
		var team=g.slot_team(i)
		var r=slot_rect(i);card(r.position,r.size,i==g.character_slot)
		var character=g.slot_character(i)
		g.face_portrait(r.position+Vector2(4,3),character,Vector2(20,21),i)
		g.text_at(("P" if roles[i] else "B")+str(i+1),r.position+Vector2(28,13),9,g.COLORS[team%8],36)
		g.text_at(g.loc("真人") if roles[i] else g.loc("电脑"),r.position+Vector2(27,27),8,Color("9eb8c6"),37)
	if message!="":g.text_at(message,Vector2(25,289),9,Color("ffb493"),260)
	g.centered("↑↓ 选择 · ←→ 调整 · 回车确认 · C 选角色 · ESC 返回",346,12)
func adjust_seat(direction):
	message=""
	if seat_row==0:
		if g.mode==0:return
		var roles=g.lobby_roles()
		var total=roles.filter(func(value):return value).size()
		if not roles[seat_slot] and total>=4:message="真人最多四名。";return
		if roles[seat_slot] and total<=1:message="至少保留一名真人。";return
		for i in range(roles.size()):g.seat_roles[i]=int(roles[i])
		g.seat_roles[seat_slot]=0 if roles[seat_slot] else 1
		g.humans+=-1 if roles[seat_slot] else 1
		if g.mode==3:g.companion=true
	elif seat_row==1:
		g.character_slot=seat_slot
		var value=g.slot_character(seat_slot)
		for i in range(9):
			value=posmod(value+direction,9)
			if g.character_selectable(value):g.select_slot_character(value);break
	elif seat_row==2 and g.mode in [1,2]:g.seat_teams[seat_slot]=posmod(g.slot_team(seat_slot)+direction,g.team_count)
	g.save_profile()
func draw_seat():
	heading("席位设置",g.loc("席位 %d") % (seat_slot+1))
	var roles=g.lobby_roles()
	var values=[g.loc("真人") if roles[seat_slot] else g.loc("电脑"),g.loc(g.character_name(g.slot_character(seat_slot))),g.loc("队伍 %d") % (g.slot_team(seat_slot)+1) if g.mode in [1,2] else g.loc("同队") if g.mode==3 else g.loc("固定分队"),g.loc("返回大厅")]
	var labels=["控制方式","角色选择","所属队伍","完成设置"]
	for i in range(4):
		var pos=Vector2(40,100+i*45);card(pos,Vector2(280,35),i==seat_row)
		g.text_at(labels[i],pos+Vector2(12,22),12,Color("abd0d7"),110)
		g.text_at(values[i],pos+Vector2(122,22),12,Color("ffe3a8"),146)
	card(Vector2(365,85),Vector2(230,210))
	var control=0
	for i in range(seat_slot+1):
		if roles[i]:control+=1
	if roles[seat_slot]:g.text_at(g.loc("控制 %d") % control,Vector2(380,276),12,Color("a3d7de"),200)
	g.hero_sprite(Vector2(440,103),g.slot_character(seat_slot),Vector2(80,108),0,0,Color.WHITE,false,-1.0,seat_slot)
	g.centered(message if message!="" else "点击角色可打开人物选择；左右键调整。",325,12)

func draw_settings():
	heading("设置与音量","音乐与音效分别调整，设置自动保存。")
	var labels=["界面语言","背景音乐","游戏音效","全部静音","显示模式","查看快捷键"]
	var values=[g.I18n.NAMES[g.I18n.LOCALES.find(g.i18n.locale)],str(g.music_volume)+"%",str(g.effects_volume)+"%",g.loc("开启") if g.muted else g.loc("关闭"),g.loc("全屏") if DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN else g.loc("窗口"),"F1"]
	for i in range(6):
		var pos=Vector2(100,68+i*40)
		card(pos,Vector2(440,34),focus==i)
		g.text_at(labels[i],pos+Vector2(14,23),12,Color("b1d2df"),170)
		if i in [1,2]:
			var amount=g.music_volume if i==1 else g.effects_volume
			g.rect(pos+Vector2(225,14),Vector2(185,7),Color("101d30"))
			g.rect(pos+Vector2(225,14),Vector2(185*amount/100.0,7),Color("77d9dd"))
			g.text_at(values[i],pos+Vector2(171,23),12,g.CREAM,47)
		else:g.text_at(values[i],pos+Vector2(225,23),12,Color("ffe2b0"),202)
	g.centered("↑↓ 选择 · ←→ 调整 · 点击滑块 · M 静音 · F3 语言",338,12)
func backup_path():return g.save_path+".backup"
func write_json(path,data):
	var file=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null:return false
	file.store_string(JSON.stringify(data,"\t"));file.close()
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path))==OK
func save_action(index):
	match index:
		0:message="已保存当前进度与设置。" if g.save_profile() else "存档写入失败。"
		1:
			g.save_profile()
			message="备份已创建，可随时恢复。" if write_json(backup_path(),g.profile) else "备份失败，请检查目录权限。"
		2:
			if not FileAccess.file_exists(backup_path()):message="暂无备份，请先创建备份。";return
			pending="restore";confirmation=0;g.state="save_confirm"
		3:pending="reset";confirmation=0;g.state="save_confirm"
		4:OS.shell_open(ProjectSettings.globalize_path(g.save_path).get_base_dir())
func valid_snapshot(data):
	if not data is Dictionary:return false
	for field in ["cleared","stage","adventure_cleared","adventure_stage"]:
		if not data.get(field) is float and not data.get(field) is int:return false
	if not data.get("chars") is Array or data.chars.size()!=4:return false
	for character in data.chars:
		if not character is int and not character is float:return false
	if not data.get("stats") is Dictionary or not data.get("settings") is Dictionary or not data.get("adventure_bonus",{}) is Dictionary:return false
	for field in g.default_profile().settings:
		if not data.settings.has(field):continue
		var setting=data.settings[field]
		if field in ["seat_roles","seat_characters","seat_teams"]:
			if not setting is Array or setting.size()!=8:return false
			for value in setting:
				if not value is int and not value is float:return false
		elif field=="companion":
			if not setting is bool:return false
		elif not setting is int and not setting is float:return false
	for field in data.stats:
		if not data.stats[field] is int and not data.stats[field] is float:return false
	return true
func perform_save_action():
	var next_profile
	if pending=="restore":
		if not FileAccess.file_exists(backup_path()):message="暂无备份，请先创建备份。";g.state="saves";return
		next_profile=JSON.parse_string(FileAccess.get_file_as_string(backup_path()))
		if not valid_snapshot(next_profile):message="备份损坏，原存档未改动。";g.state="saves";return
		if not write_json(g.save_path+".before-restore",g.profile):message="安全备份失败，操作已取消。";g.state="saves";return
	else:
		g.save_profile()
		if not write_json(backup_path(),g.profile):message="安全备份失败，操作已取消。";g.state="saves";return
		next_profile=g.default_profile();next_profile.settings=g.profile.settings.duplicate(true);next_profile.locale=g.profile.locale;next_profile.muted=g.muted
	if not write_json(g.save_path,next_profile):message="存档写入失败。";g.state="saves";return
	g.load_profile();g.i18n.set_language(g.profile.locale);g.apply_audio_settings();g.encyclopedia.rebuild();g.refresh_preview()
	g.get_tree().root.title=g.loc("泡泡糖 · 像素群岛大冒险")
	g.state="saves";message="备份已恢复。" if pending=="restore" else "进度已重置，原进度已备份。"
func draw_saves():
	heading("存档管理","自动保存闯关进度、任务成就、角色解锁与设置。")
	card(Vector2(25,76),Vector2(320,228))
	g.text_at("当前存档",Vector2(41,100),18,Color("ffe2ac"),280)
	var lines=[g.loc("经典闯关：已通 %d / 20 关") % int(g.profile.cleared),g.loc("剧情冒险：已通 %d / 20 关") % int(g.profile.adventure_cleared),g.loc("任务成就：%d / 20") % g.profile.adventure_bonus.size(),g.loc("已解锁角色：%d / 8") % range(8).filter(func(i):return g.character_unlocked(i)).size(),g.loc("累计对局：%d") % int(g.profile.stats.rounds),g.loc("备份状态：%s") % g.loc("可恢复" if FileAccess.file_exists(backup_path()) else "暂无备份")]
	for i in range(lines.size()):g.text_at(lines[i],Vector2(41,132+i*23),12,Color("bbd5df"),286)
	for i in range(5):g.button(Vector2(365,85+i*43),Vector2(235,34),SAVE_ACTIONS[i],focus==i)
	if message!="":g.centered(message,330,12,Color("ffe1a2"))
	else:g.centered("恢复与重置需再次确认，重置前会自动备份。",330,12)
func draw_confirmation():
	g.rect(Vector2.ZERO,Vector2(640,360),Color(0,0,0,.7))
	card(Vector2(115,102),Vector2(410,188),true)
	g.text_at("恢复备份？" if pending=="restore" else "重置游戏进度？",Vector2(140,136),24,Color("ffe0a0"),360)
	g.wrapped("恢复会替换当前进度与设置。当前存档会另存为恢复前备份。" if pending=="restore" else "清空闯关、统计与角色解锁，保留设置。原进度会自动备份。",Vector2(140,170),29,Color("d5e3ea"),3)
	g.button(Vector2(145,243),Vector2(155,32),"取消",confirmation==0)
	g.button(Vector2(335,243),Vector2(155,32),"确认恢复" if pending=="restore" else "备份并重置",confirmation==1)
func draw_about():
	heading("制作与版本","泡泡糖 · 像素群岛大冒险 · v4.9.1")
	card(Vector2(55,77),Vector2(530,237))
	g.hero_sprite(Vector2(75,119),7,Vector2(110,145),0,0)
	g.text_at("像素群岛，等你来冒险",Vector2(220,112),24,Color("ffe3ac"),340)
	g.wrapped("以圆形水泡、连锁爆炸和伙伴救援为核心，加入坐骑、元素泡泡、昼夜、迷雾与剧情任务。",Vector2(220,149),28,Color("bfdae0"),4)
	g.wrapped("原创像素素材与主题音乐，角色及任务物件使用生成美术。Godot 引擎制作，支持中文、英文、日文、法文与德文。",Vector2(220,226),28,Color("9fc1d0"),4)
	g.centered("本机同屏 · 最多四名真人 · 八人对战",342,12)

const ADVANCED_FIELDS=["collapse","pace","daylight","fog","density","loot","mechanisms"]
const ADVANCED_LABELS=["坍塌开始时间","坍塌速度","昼夜模式","雾气","箱子密度","道具掉落量","地图机关"]
const ADVANCED_VALUES=[
 ["地图默认","60 秒","90 秒","150 秒","210 秒","300 秒"],
 ["标准 · 每圈 5 秒","快速 · 每圈 3 秒","缓慢 · 每圈 8 秒","悠闲 · 每圈 12 秒"],
 ["地图默认","白昼","昼夜交替","恒夜"],
 ["地图默认","关闭","开启"],
 ["地图默认","稀疏","丰富","密集"],
 ["标准","稀少","适中","丰富"],
 ["开启","关闭"]]
func adjust_advanced(direction):
	if focus==7:g.battle_options=g.BATTLE_OPTIONS.duplicate()
	else:
		var field=ADVANCED_FIELDS[focus]
		if field=="daylight" and g.selected_map>=0 and g.Catalog.MAPS[g.selected_map].get("night",false):return
		g.battle_options[field]=posmod(g.battle_options[field]+direction,ADVANCED_VALUES[focus].size())
	g.refresh_preview();g.save_profile()
func draw_advanced():
	heading("对战高级规则","设置自动保存；洞窟始终为夜晚。")
	for i in range(8):
		var pos=Vector2(35,69+i*31);card(pos,Vector2(570,27),focus==i)
		g.text_at(ADVANCED_LABELS[i] if i<7 else "恢复默认规则",pos+Vector2(12,18),12,Color("a1c6d6"),210)
		if i<7:
			var locked=i==2 and g.selected_map>=0 and g.Catalog.MAPS[g.selected_map].get("night",false)
			g.text_at("洞窟 · 常夜" if locked else ADVANCED_VALUES[i][g.battle_options[ADVANCED_FIELDS[i]]],pos+Vector2(258,18),12,Color("ffe3a8"),285)
	g.centered("↑↓ 选择 · ←→ 调整 · ESC 返回大厅",343,12)
