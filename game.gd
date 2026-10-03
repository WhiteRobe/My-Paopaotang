extends Node2D

const Catalog = preload("res://data/catalog.gd")
const Adventure=preload("res://adventure.gd")
const MapMechanisms=preload("res://map_mechanisms.gd")
const BubbleEffects=preload("res://bubble_effects.gd")
const Crates=preload("res://crates.gd")
const WorldEffects=preload("res://world_effects.gd")
const MAP_COUNT=40
const W = 21
const H = 15
const TILE = 18
const ORIGIN = Vector2(130, 74)
const DIRS = [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]
const SPAWNS = [Vector2i(1,1),Vector2i(19,1),Vector2i(1,13),Vector2i(19,13)]
const INK = Color("182840")
const CREAM = Color("fff5d5")
const COLORS = [Color("62ceff"),Color("ff8bad"),Color("ffe18a"),Color("a8efac")]
const MOVE_KEYS = [[KEY_A,KEY_D,KEY_W,KEY_S],[KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN],[KEY_J,KEY_L,KEY_I,KEY_K],[KEY_F,KEY_H,KEY_T,KEY_G]]
const BOMB_KEYS = [KEY_SPACE,KEY_ENTER,KEY_U,KEY_R]
const ITEM_KEYS = [KEY_Q,KEY_SLASH,KEY_O,KEY_Y]
const CONTROL_NAMES = ["WASD / 空格 / Q","方向键 / 回车 / /","IJKL / U / O","TFGH / R / Y"]
const MODES = ["单人闯关","自由混战","双人组队 2v2","剧情冒险 PVE"]
var font = preload("res://assets/fonts/pixel_font.tres")
var tiles = preload("res://assets/tiles.png")
var item_art = preload("res://assets/items.png")
var character_art = preload("res://assets/characters.png")
var mount_art = preload("res://assets/mounts.png")
var backgrounds: Array = []
var rng = RandomNumberGenerator.new()
var state = "menu"
var mode = 0
var humans = 1
var seats = 4
var companion = true
var team_layout = 0
var selected_map = -1
var arena = 0
var campaign_stage = 1
var adventure_stage=1
var adventure
var map_rules
var world_fx
var crates
var bubble_fx
var pause_return="play"
var chosen_characters = [0,1,0,1]
var menu_row = 0
var selection = 0
var map_page = 0
var character_slot = 0
var muted = false
var paused = false
var quit_selection = 0
var grid: Array = []
var terrain: Dictionary = {}
var gates: Array = []
var vine_cells: Array = []
var gold_boxes: Dictionary = {}
var players: Array = []
var bombs: Array = []
var blasts: Array = []
var drops: Dictionary = {}
var particles: Array = []
var decoys: Array = []
var hazards: Array = []
var elapsed = 0.0
var round_time = 0.0
var clock_time = 150.0
var round_limit = 150.0
var pickup_effects: Array = []
var collapsed_at: Dictionary = {}
var countdown = 0.0
var shake = 0.0
var supply_time = 20.0
var mechanism_time = 0.0
var sudden_ring = -1
var gate_open = false
var scores = [0,0,0,0]
var round_index = 1
var result_text = ""
var result_winner = -1
var match_over = false
var notice = ""
var notice_time = 0.0
var round_recorded = true
var music: AudioStreamPlayer
var current_theme = ""
var sounds: Dictionary = {}
var speakers: Array = []
var speaker_index = 0
var save_path = "user://profile.json"
var profile: Dictionary = {}

func default_profile():
	return {"version":3,"adventure_stage":1,"adventure_cleared":0,"cleared":0,"stage":1,"muted":false,"chars":[0,1,0,1],"settings":{"mode":0,"humans":1,"seats":4,"map":-1,"companion":true,"teams":0},"stats":{"pve_stages":0,"monsters":0,"bosses":0,"rounds":0,"wins":0,"losses":0,"draws":0,"bombs":0,"crates":0,"items":0,"rescues":0,"mounts":0,"deaths":0,"abandoned":0,"seconds":0.0}}

func _ready():
	scale = Vector2(3,3)
	font.base_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	rng.randomize()
	adventure=Adventure.new(self)
	map_rules=MapMechanisms.new(self)
	world_fx=WorldEffects.new(self)
	crates=Crates.new(self)
	bubble_fx=BubbleEffects.new(self)
	load_profile()
	get_tree().auto_accept_quit = false
	get_tree().root.close_requested.connect(close_game)
	for theme in Catalog.THEMES: backgrounds.append(load("res://assets/background-"+theme+".png"))
	music = AudioStreamPlayer.new()
	music.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	add_child(music)
	for name in ["place","splash","pickup","item","win","trap"]: sounds[name] = load("res://assets/audio/"+name+".wav")
	for i in range(12):
		var speaker = AudioStreamPlayer.new()
		speaker.volume_db = -13
		add_child(speaker)
		speakers.append(speaker)
	build_board(0)
	play_theme(0)

func load_profile():
	profile = default_profile()
	if FileAccess.file_exists(save_path):
		var loaded = JSON.parse_string(FileAccess.get_file_as_string(save_path))
		if loaded is Dictionary:
			profile.cleared = clampi(int(loaded.get("cleared",0)),0,20)
			profile.stage = clampi(int(loaded.get("stage",1)),1,20)
			profile.muted = bool(loaded.get("muted",false))
			profile.adventure_cleared=clampi(int(loaded.get("adventure_cleared",0)),0,20)
			profile.adventure_stage=clampi(int(loaded.get("adventure_stage",1)),1,20)
			if loaded.get("chars") is Array and loaded.chars.size()==4: profile.chars = loaded.chars
			if loaded.get("settings") is Dictionary:
				for field in profile.settings: profile.settings[field]=loaded.settings.get(field,profile.settings[field])
			if loaded.get("stats") is Dictionary:
				for field in profile.stats:
					var value = loaded.stats.get(field,0)
					if value is int or value is float: profile.stats[field] = maxf(0,float(value))
	mode=clampi(int(profile.settings.mode),0,3)
	humans=clampi(int(profile.settings.humans),1,4)
	seats=clampi(int(profile.settings.seats),2,4)
	selected_map=clampi(int(profile.settings.map),-1,MAP_COUNT-1)
	companion=bool(profile.settings.companion)
	team_layout=clampi(int(profile.settings.teams),0,1)
	if mode==0:humans=1
	elif mode in [2,3]:seats=4
	humans=mini(humans,seats)
	campaign_stage = clampi(int(profile.stage),1,mini(20,int(profile.cleared)+1))
	adventure_stage=clampi(int(profile.adventure_stage),1,mini(20,int(profile.adventure_cleared)+1))
	muted = profile.muted
	for i in range(4):
		var index = clampi(int(profile.chars[i]),0,7)
		chosen_characters[i] = index if character_unlocked(index) else 0

func save_profile():
	profile.muted = muted
	profile.chars = chosen_characters.duplicate()
	profile.settings={"mode":mode,"humans":humans,"seats":seats,"map":selected_map,"companion":companion,"teams":team_layout}
	var file = FileAccess.open(save_path+".tmp",FileAccess.WRITE)
	if file == null:
		announce("存档失败，请检查目录权限。")
		return
	file.store_string(JSON.stringify(profile,"\t"))
	file.close()
	var error = DirAccess.rename_absolute(ProjectSettings.globalize_path(save_path+".tmp"),ProjectSettings.globalize_path(save_path))
	if error != OK: announce("存档写入失败。")

func character_unlocked(index): return maxi(int(profile.get("cleared",0)),int(profile.get("adventure_cleared",0))) >= Catalog.CHARACTERS[index].unlock
func stat(field,amount=1): profile.stats[field] = profile.stats.get(field,0) + amount
func play_theme(theme_index):
	var name = Catalog.THEMES[theme_index]
	if current_theme == name: return
	current_theme = name
	music.stop()
	var stream = load("res://assets/audio/themes/"+name+".ogg") as AudioStreamOggVorbis
	stream.loop = true
	music.stream = stream
	music.volume_db = -80 if muted else -12
	if DisplayServer.get_name() != "headless": music.play()
func sound(name):
	if muted: return
	var speaker = speakers[speaker_index % speakers.size()]
	speaker_index += 1
	speaker.stream = sounds[name]
	speaker.play()
func announce(message):
	notice = message
	notice_time = 3.0

func start_match():
	scores = [0,0,0,0]
	round_index = 1
	match_over = false
	new_round()

func new_round():
	var choice = selected_map
	if mode == 0:
		choice = campaign_stage-1
		profile.stage = campaign_stage
	elif mode==3:choice=20+adventure_stage-1
	elif choice < 0: choice = rng.randi_range(0,MAP_COUNT-1)
	build_board(choice)
	play_theme(Catalog.MAPS[choice].theme)
	players.clear()
	bombs.clear()
	blasts.clear()
	drops.clear()
	particles.clear()
	world_fx.events.clear()
	bubble_fx.vines.clear()
	decoys.clear()
	hazards.clear()
	round_limit = Catalog.MAPS[choice].seconds+(90 if mode==3 else 0)
	clock_time = round_limit
	pickup_effects.clear()
	collapsed_at.clear()
	round_time = 0
	countdown = 2.5
	shake = 0
	supply_time = 12 if rule()=="sand" else 20
	mechanism_time = 6
	sudden_ring = -1
	paused = false
	quit_selection = 0
	notice_time = 0
	result_winner = -1
	round_recorded = false
	var count = 4 if mode==2 else seats
	if mode==0: count = 2 if campaign_stage<5 else 4
	elif mode==3:count=4 if companion else humans
	for i in range(count):
		var team = i
		if mode==3:team=0
		elif mode==2: team = int(i/2) if team_layout==0 else i%2
		elif mode==0: team = 0 if i==0 or (companion and count==4 and i==1) else 1
		var bot = i >= humans or (mode==0 and i>0)
		var character = chosen_characters[i]
		if mode==0 and i>0: character = (campaign_stage+i)%8
		elif bot: character = (arena+i*3)%8
		var c = SPAWNS[i]
		var p = {"id":i,"team":team,"bot":bot,"character":character,"cell":c,"visual":Vector2(c),"from":Vector2(c),"move":1.0,"cool":0.0,"duration":0.15,"pickup_lock":Vector2i(-1,-1),"range":2,"capacity":2,"speed":0,"power":0,"riding":0,"item":1,"element":0,"element_time":0.0,"shield":0.0,"dash":0.0,"kick":0.0,"cloak":0.0,"magnet":0.0,"freeze":0.0,"slow":0.0,"trap":0.0,"grace":0.0,"warp":0.0,"flow":0.0,"think":0.0,"attack":0.0,"ai_dir":Vector2i.ZERO,"facing":Vector2i.DOWN,"steps":0,"dead":false,"mount":0,"mount_hp":0,"jump":0.0,"coins":0,"last_cell":c,"score":0}
		match character:
			1: p.range = 3
			2: p.speed = 1
			3: p.capacity = 3
			4: p.power = 1
			5: p.item = 14
			6: p.item = 6
			7: p.riding = 1
		if mode==0 and bot and team==1:
			p.speed=mini(3,p.speed+int(campaign_stage/8))
			p.capacity=mini(5,p.capacity+int(campaign_stage/10))
		players.append(p)
	stat("rounds")
	state = "play"
	pause_return="play"
	if mode==3:
		adventure.setup()
		crates.setup()

func rule(): return Catalog.MAPS[arena].rule
func inside(c): return c.x>=0 and c.y>=0 and c.x<W and c.y<H
func center(c): return ORIGIN+Vector2(c)*TILE+Vector2(TILE/2.0,TILE/2.0)
func bomb_at(c):
	for b in bombs:
		if b.cell==c: return b
	return null
func occupied(c,ignore=-1):
	for p in players:
		if p.id!=ignore and not p.dead and p.cell==c: return p
	return null
func passable(c,p=null):
	if not inside(c) or grid[c.y][c.x] in [1,3]: return false
	if grid[c.y][c.x]==2 and (p==null or p.cloak<=0): return false
	return bomb_at(c)==null
func bubble_can_move(c): return passable(c) and occupied(c)==null

func build_board(index):
	arena = clampi(index,0,MAP_COUNT-1)
	grid.clear()
	terrain.clear()
	gates.clear()
	vine_cells.clear()
	gold_boxes.clear()
	gate_open = false
	var layout = Catalog.MAPS[arena].layout
	var map_rng = RandomNumberGenerator.new()
	map_rng.seed = 1103+arena*137
	for y in range(H):
		var row: Array = []
		for x in range(W):
			var wall = x==0 or y==0 or x==W-1 or y==H-1
			if not wall:
				match (layout%10 if arena<20 else (layout+10)%20):
					0: wall = x%2==0 and y%2==0
					1: wall = y in [3,9] and x in [3,4,6,7,11,12,14,15]
					2: wall = x%4==0 and y not in [1,6,11]
					3: wall = (x+y)%5==0 and x>2 and x<16
					4: wall = y%3==0 and x not in [1,5,9,13,17]
					5: wall = x in [4,14] and y in [3,4,8,9]
					6: wall = (x%4==2 and y%3==0)
					7: wall = (x in [5,13] and y in [3,4,5,7,8,9]) or (y in [3,9] and x in [6,7,11,12])
					8: wall = abs(x-9)+abs(y-6) in [4,8] and x%3!=0 and y%3!=0
					9: wall = (x in [3,7,11,15] and y in [3,5,7,9])
					10: wall = x in [5,15] and y not in [2,7,12]
					11: wall = y in [4,10] and x%5 not in [0,1]
					12: wall = (x+y)%6==0 and y not in [2,12]
					13: wall = abs(x-10)+abs(y-7)==6 and x%4!=2
					14: wall = (x%4==0 and y%4==0) or (x%4==1 and y%4==1)
					15: wall = y in [3,11] and x not in [2,6,10,14,18]
					16: wall = x in [4,8,12,16] and y in [4,5,9,10]
					17: wall = (x-10)*(x-10)+(y-7)*(y-7) in range(23,29) and x%3!=0
					18: wall = (x%5==0 and y%3!=1) or (y%5==0 and x%3==1)
					19: wall = (x in [6,14] and y in [2,3,4,10,11,12]) or (y in [5,9] and x in [8,9,11,12])
			var cell = 1 if wall else (2 if map_rng.randf()<(.35 if arena%3 else .45) else 0)
			row.append(cell)
		grid.append(row)
	# All maps have routes through the middle and symmetrical corner exits.
	for x in range(1,W-1): grid[7][x]=0
	for y in range(1,H-1): grid[y][10]=0
	for c in SPAWNS:
		for y in range(maxi(1,c.y-2),mini(H-1,c.y+3)):
			for x in range(maxi(1,c.x-2),mini(W-1,c.x+3)):
				if abs(x-c.x)+abs(y-c.y)<=2: grid[y][x]=0
	# Mirror the board so opposing spawns receive equivalent obstacles.
	for y in range(1,H-1):
		for x in range(1,W-1):
			if y>H/2 or (y==H/2 and x>W/2): grid[y][x]=grid[H-1-y][W-1-x]
	match rule():
		"portal":
			for pair in [[Vector2i(5,3),Vector2i(13,9)],[Vector2i(13,3),Vector2i(5,9)]]:
				for c in pair:
					clear_patch(c)
					terrain[c]={"type":"portal","exit":pair[1] if c==pair[0] else pair[0]}
		"flow":
			for x in range(2,W-2): terrain[Vector2i(x,7)]={"type":"flow","dir":Vector2i.RIGHT if x<10 else Vector2i.LEFT}
		"mushroom","spring":
			for c in [Vector2i(5,4),Vector2i(13,8),Vector2i(5,8),Vector2i(13,4),Vector2i(10,7)]:
				clear_patch(c)
				terrain[c]={"type":"spring"}
		"vine":
			for c in [Vector2i(5,3),Vector2i(13,9),Vector2i(5,9),Vector2i(13,3),Vector2i(7,6),Vector2i(11,6)]:
				grid[c.y][c.x]=2
				vine_cells.append(c)
		"ice":
			for y in range(3,10):
				for x in range(5,14):
					if grid[y][x]==0: terrain[Vector2i(x,y)]={"type":"ice"}
		"sand":
			for y in range(2,11):
				for x in range(3,16):
					if grid[y][x]==0 and (x+y)%3==0: terrain[Vector2i(x,y)]={"type":"sand"}
		"gate":
			for c in [Vector2i(5,6),Vector2i(13,6),Vector2i(9,3),Vector2i(9,9)]:
				gates.append(c)
				grid[c.y][c.x]=1
			for c in [Vector2i(3,5),Vector2i(15,7)]:
				clear_patch(c)
				terrain[c]={"type":"switch"}
		"lava":
			for c in [Vector2i(5,6),Vector2i(13,6),Vector2i(9,4),Vector2i(9,8),Vector2i(7,5),Vector2i(11,7)]:
				grid[c.y][c.x]=0
				terrain[c]={"type":"lava"}
		"treasure":
			for c in [Vector2i(5,3),Vector2i(13,9),Vector2i(5,9),Vector2i(13,3),Vector2i(7,6),Vector2i(11,6),Vector2i(9,5),Vector2i(9,7)]:
				grid[c.y][c.x]=2
				gold_boxes[c]=true
		"laser":
			for y in [3,6,9]:
				for x in range(1,W-1): grid[y][x]=0
		"train":
			for x in range(1,W-1): terrain[Vector2i(x,7)]={"type":"rail"}
	for c in [Vector2i(10,7),Vector2i(7,6),Vector2i(11,6)]:
		if grid[c.y][c.x]==0: terrain[c]=terrain.get(c,{"type":"supply"})

	if map_rules:map_rules.setup()
	if crates:crates.setup()

func clear_patch(c):
	for d in [Vector2i.ZERO]+DIRS:
		var next = c+d
		if inside(next) and next.x>0 and next.y>0 and next.x<W-1 and next.y<H-1: grid[next.y][next.x]=0

func _unhandled_key_input(event):
	if not event.pressed or event.echo: return
	var key = event.keycode
	if key==KEY_M:
		muted=not muted
		music.volume_db=-80 if muted else -12
		save_profile()
		return
	if state=="menu":
		if key==KEY_UP: menu_row=posmod(menu_row-1,6)
		elif key==KEY_DOWN: menu_row=(menu_row+1)%6
		elif key in [KEY_LEFT,KEY_RIGHT]: adjust_menu(-1 if key==KEY_LEFT else 1)
		elif key==KEY_TAB:
			if mode in [0,3]:mode=1
			selected_map=posmod(selected_map+1,MAP_COUNT)
			refresh_preview()
		elif key==KEY_R:
			if mode in [0,3]:mode=1
			selected_map=-1
			refresh_preview()
		elif key==KEY_C:
			character_slot=0
			selection=chosen_characters[0]
			state="characters"
		elif key==KEY_B: state="stats"
		elif key==KEY_V:
			selection=maxi(0,selected_map)
			state="maps"
		elif key==KEY_F1: state="help"
		elif key in [KEY_ENTER,KEY_SPACE]: start_match()
		return
	if state in ["stats","help","maps","characters"]:
		if key==KEY_ESCAPE:
			state="menu"
			refresh_preview()
			return
		if state=="maps":
			if key==KEY_LEFT: selection=posmod(selection-1,MAP_COUNT)
			elif key==KEY_RIGHT: selection=(selection+1)%MAP_COUNT
			elif key==KEY_UP: selection=posmod(selection-4,MAP_COUNT)
			elif key==KEY_DOWN: selection=(selection+4)%MAP_COUNT
			elif key==KEY_ENTER:
				selected_map=selection
				if mode in [0,3]:mode=1
				state="menu"
				refresh_preview()
			elif key==KEY_R:
				selected_map=-1
				state="menu"
		elif state=="characters":
			if key==KEY_TAB:
				character_slot=(character_slot+1)%4
				selection=chosen_characters[character_slot]
			elif key==KEY_LEFT: selection=posmod(selection-1,8)
			elif key==KEY_RIGHT: selection=(selection+1)%8
			elif key==KEY_ENTER and character_unlocked(selection):
				chosen_characters[character_slot]=selection
				save_profile()
				sound("pickup")
		return
	if state=="story":
		if key in [KEY_ENTER,KEY_SPACE]:adventure.advance_dialogue()
		elif key==KEY_ESCAPE:state="play";countdown=1.5
		elif key==KEY_P:pause_return="story";state="pause";paused=true;quit_selection=0
		return
	if state=="pause":
		if key in [KEY_ESCAPE,KEY_P]:
			state=pause_return
			paused=false
		elif key==KEY_UP: quit_selection=posmod(quit_selection-1,3)
		elif key==KEY_DOWN: quit_selection=(quit_selection+1)%3
		elif key==KEY_ENTER: pause_action(quit_selection)
		return
	if state=="result":
		if key==KEY_ESCAPE: return_to_menu()
		elif key in [KEY_ENTER,KEY_SPACE]:
			if mode==3:
				if result_winner==0:adventure_stage=adventure_stage+1 if adventure_stage<20 else 1
				start_match()
			elif mode==0:
				if result_winner==0: campaign_stage=campaign_stage+1 if campaign_stage<20 else 1
				start_match()
			elif match_over: start_match()
			else:
				round_index+=1
				new_round()
		return
	if state!="play": return
	if key in [KEY_ESCAPE,KEY_P]:
		pause_return="play"
		state="pause"
		paused=true
		quit_selection=0
		return
	if countdown>0: return
	for i in range(players.size()):
		if players[i].bot: continue
		if key==BOMB_KEYS[i] or (i==1 and key==KEY_KP_ENTER): place_bomb(i)
		if key==ITEM_KEYS[i] or (i==1 and key==KEY_KP_DIVIDE):
			if event.shift_pressed:swap_item(i)
			else:use_item(i)

func _unhandled_input(event):
	if not event is InputEventMouseButton or not event.pressed or event.button_index!=MOUSE_BUTTON_LEFT: return
	var pos=event.position/3
	if state=="menu":
		if Rect2(22,300,254,28).has_point(pos): start_match()
		elif Rect2(290,304,102,24).has_point(pos): state="maps"; selection=maxi(0,selected_map)
		elif Rect2(400,304,102,24).has_point(pos): state="characters"; selection=chosen_characters[0]
		elif Rect2(510,304,106,24).has_point(pos): state="stats"
		elif pos.x<280 and pos.y>=151 and pos.y<295:
			menu_row=clampi(int((pos.y-151)/24),0,5)
			adjust_menu(1)
	elif state=="story":adventure.advance_dialogue()
	elif state=="play" and Rect2(528,309,92,20).has_point(pos):
		pause_return="play";state="pause"; paused=true; quit_selection=0
	elif state=="pause":
		for i in range(3):
			if Rect2(195,153+i*32,250,28).has_point(pos): pause_action(i)
	elif state=="result":
		if Rect2(195,210,250,30).has_point(pos):
			var key=InputEventKey.new();key.keycode=KEY_ENTER;key.pressed=true;_unhandled_key_input(key)
		elif Rect2(195,248,250,25).has_point(pos): return_to_menu()
	elif state in ["stats","help","maps","characters"] and Rect2(540,10,80,22).has_point(pos):
		state="menu";refresh_preview()
	elif state=="maps":
		for slot in range(20):
			if Rect2(12+(slot%4)*156,45+int(slot/4)*56,147,52).has_point(pos):
				selection=int(selection/20)*20+slot;selected_map=selection;mode=1 if mode in [0,3] else mode;state="menu";refresh_preview();break
		if pos.y>=328 and pos.y<=358 and pos.x<120:selection=posmod(selection-20,MAP_COUNT)
		elif pos.y>=328 and pos.y<=358 and pos.x>520:selection=posmod(selection+20,MAP_COUNT)
	elif state=="characters":
		for i in range(8):
			if Rect2(32+i*75,92,65,86).has_point(pos): selection=i
		if Rect2(240,283,160,28).has_point(pos) and character_unlocked(selection):
			chosen_characters[character_slot]=selection;save_profile();sound("pickup")

func adjust_menu(direction):
	match menu_row:
		0: mode=posmod(mode+direction,4)
		1:
			if mode==3:adventure_stage=clampi(adventure_stage+direction,1,mini(20,int(profile.adventure_cleared)+1))
			elif mode==0: campaign_stage=clampi(campaign_stage+direction,1,mini(20,int(profile.cleared)+1))
			else: selected_map=posmod(selected_map+1+direction,MAP_COUNT+1)-1
		2: humans=clampi(humans+direction,1,4)
		3: seats=clampi(seats+direction,2,4)
		4:
			if mode in [0,3]:companion=not companion
			elif mode==2:team_layout=1-team_layout
		5:
			chosen_characters[0]=next_character(chosen_characters[0],direction)
			save_profile()
	if mode==0: humans=1
	elif mode in [2,3]: seats=4
	humans=mini(humans,seats)
	refresh_preview()

func next_character(value,direction):
	for i in range(8):
		value=posmod(value+direction,8)
		if character_unlocked(value): return value
	return 0
func refresh_preview():
	build_board((20+adventure_stage-1) if mode==3 else (campaign_stage-1 if mode==0 else maxi(0,selected_map)))
	play_theme(Catalog.MAPS[arena].theme)
func pause_action(choice):
	if choice==0: state=pause_return;paused=false
	elif choice==1: return_to_menu()
	else: close_game()
func return_to_menu():
	if not round_recorded:
		stat("abandoned")
		round_recorded=true
	save_profile()
	state="menu"
	paused=false
	players.clear()
	refresh_preview()

func _process(dt):
	elapsed+=dt
	if world_fx:world_fx.update(dt)
	shake=maxf(0,shake-dt*18)
	if state=="play":
		if countdown>0: countdown-=dt
		else: update_game(minf(dt,.08))
	for p in particles:
		p.life-=dt
		p.pos+=p.vel*dt
		p.vel.y+=50*dt
	particles=particles.filter(func(p):return p.life>0)
	queue_redraw()

func update_game(dt):
	round_time+=dt
	clock_time-=dt
	for effect in pickup_effects:effect.life-=dt
	pickup_effects=pickup_effects.filter(func(effect):return effect.life>0)
	stat("seconds",dt)
	notice_time=maxf(0,notice_time-dt)
	supply_time-=dt
	if supply_time<=0:
		supply_time+=12 if rule()=="sand" else 20
		drop_supply()
	crates.update(dt)
	bubble_fx.update(dt)
	map_rules.update(dt)
	update_mechanisms(dt)
	var danger=danger_cells()
	for p in players:
		for timer in ["shield","dash","kick","cloak","magnet","freeze","slow","grace","warp","flow","think","jump","attack"]: p[timer]=maxf(0,p[timer]-dt)
		p.cool=maxf(0,p.cool-dt)
		p.move=minf(1,p.move+dt/p.duration)
		p.visual=p.from.lerp(Vector2(p.cell),p.move)
		if p.dead: continue
		if p.cloak<=0 and grid[p.cell.y][p.cell.x]==2: eject_from_box(p)
		if p.trap>0:
			p.trap-=dt
			if p.bot and p.item in [1,9,18]: use_item(p.id)
			if p.trap<=0 and p.grace<=0: kill_player(p)
			continue
		if p.freeze>0: continue
		var dir=Vector2i.ZERO
		if p.bot:
			if p.think<=0:
				p.think=.14 if mode!=0 else maxf(.11,.28-campaign_stage*.008)
				p.ai_dir=bot_direction(p,danger)
				bot_actions(p,danger)
			dir=p.ai_dir
		else:
			for d in range(4):
				if Input.is_physical_key_pressed(MOVE_KEYS[p.id][d]):dir=DIRS[d];break
		if terrain.has(p.cell) and p.flow<=0:
			var tile=terrain[p.cell]
			if tile.type=="flow":dir=tile.dir;p.flow=.4
			elif tile.type=="ice" and dir==Vector2i.ZERO and p.facing!=Vector2i.ZERO:dir=p.facing
		if rule()=="wind" and fmod(round_time,9)>7.5 and p.flow<=0:
			dir=DIRS[int(round_time/9)%4];p.flow=.5
		if dir!=Vector2i.ZERO and p.move>=1: try_move(p,dir)
		apply_terrain(p)
		if p.pickup_lock!=p.cell:p.pickup_lock=Vector2i(-1,-1)
		if p.move>=.65 and drops.has(p.cell): pickup(p,p.cell)
		if p.magnet>0:
			for c in drops.keys():
				if manhattan(c,p.cell)<=2: pickup(p,c)
		for f in blasts:
			if f.cell==p.cell and f.time>0: bubble_fx.affect_player(p,f)
	for b in bombs.duplicate():
		if not bombs.has(b): continue
		b.timer-=dt
		if b.slide!=Vector2i.ZERO:
			b.step-=dt
			if b.step<=0:
				var next=b.cell+b.slide
				if bubble_can_move(next):b.cell=next;b.step=.11
				else:b.slide=Vector2i.ZERO
		for f in blasts:
			if f.cell==b.cell and f.time>0:b.timer=0;break
		if b.timer<=0:explode(b)
	for f in blasts:f.time-=dt
	blasts=blasts.filter(func(f):return f.time>0)
	for d in decoys:d.time-=dt
	decoys=decoys.filter(func(d):return d.time>0)
	if clock_time<=0:
		var ring=mini(H/2-1,int(-clock_time/5))
		if ring>sudden_ring:sudden_ring=ring;flood_ring(ring+1)
	if mode==3:
		adventure.update(dt)
		return
	var alive: Dictionary={}
	for p in players:
		if not p.dead:alive[p.team]=true
	if alive.size()<=1 or clock_time<=-float(H/2)*5:
		finish_round(alive.keys()[0] if alive.size()==1 else -1)
	elif rule()=="treasure":
		for p in players:
			if p.coins>=5:finish_round(p.team);break

func move_duration(p):
	var speed=.15-.012*p.speed
	if p.dash>0:speed*=.66
	if p.mount==1:speed*=.75
	elif p.mount==2:speed*=1.1
	elif p.mount==3:speed*=.86
	if p.mount>0:speed*=1-.06*p.riding
	if p.freeze>0 or p.slow>0:speed*=1.9
	if rule()=="gravity":speed*=.8
	if terrain.has(p.cell) and terrain[p.cell].type=="sand":speed*=1.65
	return maxf(.065,speed)

func try_move(p,dir):
	p.facing=dir
	var target=p.cell+dir
	var other=occupied(target,p.id)
	if other!=null and other.trap>0:
		if p.team==other.team:
			other.trap=0;other.grace=1;burst(center(other.cell),Color("82f0c1"),14)
			if p.id==0:stat("rescues")
			announce("队友获救！")
		else:kill_player(other)
	if inside(target) and grid[target.y][target.x]==2:crates.try_push(target,dir,p)
	var bubble=bomb_at(target)
	if bubble!=null and p.kick>0:kick_bomb(bubble,dir)
	if inside(target) and grid[target.y][target.x]==2 and p.mount==3 and p.jump<=0:
		var landing=target+dir
		if passable(landing,p) and occupied(landing,p.id)==null:target=landing;p.jump=1.0
	if not passable(target,p) or occupied(target,p.id)!=null:return
	p.from=p.visual
	p.last_cell=p.cell
	p.cell=target
	p.move=0
	p.duration=move_duration(p)
	p.cool=p.duration
	p.steps+=1

func apply_terrain(p):
	if not terrain.has(p.cell) or p.cell==p.last_cell:return
	var tile=terrain[p.cell]
	if tile.type=="portal" and p.warp<=0:
		var dest=tile.exit
		if passable(dest,p) and occupied(dest,p.id)==null:
			burst(center(p.cell),Color("ce9dff"),12)
			teleport(p,dest);p.warp=1.0
			sound("item")
	elif tile.type=="spring" and p.jump<=0:
		var dest=p.cell+p.facing*2
		if passable(dest,p) and occupied(dest,p.id)==null:
			teleport(p,dest);p.jump=.8;burst(center(dest),Color("ffe595"),10)
	elif tile.type=="switch" and p.warp<=0:
		gate_open=not gate_open
		for c in gates:
			if gate_open:grid[c.y][c.x]=0
			elif occupied(c)==null and bomb_at(c)==null:grid[c.y][c.x]=1
		p.warp=1
		announce("石门开启" if gate_open else "石门关闭")
	p.last_cell=p.cell
func teleport(p,dest):
	p.cell=dest;p.visual=Vector2(dest);p.from=p.visual;p.move=1;p.last_cell=dest
	burst(center(dest),Color("bdeeff"),10)
func eject_from_box(p):
	for d in DIRS:
		if passable(p.cell+d) and occupied(p.cell+d,p.id)==null:teleport(p,p.cell+d);return
	grid[p.cell.y][p.cell.x]=0

func damage_player(p,owner):
	if p.dead or p.grace>0 or p.trap>0:return
	if owner>=0 and owner<players.size() and owner!=p.id and players[owner].team==p.team:return
	if p.shield>0:
		p.shield=0;p.grace=1
		burst(center(p.cell),Color("e8ffe4"),12)
	elif p.mount>0:
		p.mount_hp-=1;p.grace=.9
		burst(center(p.cell),Color(Catalog.MOUNTS[p.mount].color),12)
		if p.mount_hp<=0:p.mount=0;announce("坐骑替你挡住了水柱！")
	else:
		p.trap=3;p.grace=.6
		sound("trap")
func kill_player(p):
	if p.dead:return
	p.dead=true;p.trap=0
	burst(center(p.cell),COLORS[p.id],18)
	if p.id==0:stat("deaths")
	sound("trap")

func random_drop():
	return rng.randi_range(20,25) if rng.randf()<.24 else rng.randi_range(1,18)

func pickup(p,c):
	if not drops.has(c):return
	var kind=int(drops[c])
	var category=Catalog.ITEMS[kind].kind
	if category=="active" and p.pickup_lock==c:return
	if category=="active" and c!=p.cell and p.item!=0:return
	var previous=p.item if category=="active" else 0
	drops.erase(c)
	if previous>0:
		drops[c]=previous
		p.pickup_lock=c
	if category=="active" and not p.bot:announce("拾取"+Catalog.ITEMS[kind].name+("，原道具留在地上。" if previous>0 else ""))
	pickup_effects.append({"pos":center(c),"kind":kind,"life":.65})
	match kind:
		4:p.capacity=mini(6,p.capacity+1)
		5:p.range=mini(8,p.range+1)
		7:p.speed=mini(5,p.speed+1)
		8:p.power=mini(3,p.power+1)
		15:
			p.mount=rng.randi_range(1,3)
			p.mount_hp=(2 if p.mount==2 else 1)+p.riding
			if p.id==0:stat("mounts")
			announce(Catalog.MOUNTS[p.mount].name+"陪你出战！")
		16:
			p.riding=mini(3,p.riding+1)
			if p.mount>0:p.mount_hp=mini(5,p.mount_hp+1)
		19:p.coins+=1
		_:p.item=kind
	if p.id==0:stat("items")
	burst(center(c),Color(Catalog.ITEMS[kind].color),9)
	world_fx.impact(center(c),5,25)
	sound("pickup")

func swap_item(i):
	var p=players[i]
	if p.dead or p.trap>0 or not drops.has(p.cell):return
	var kind=int(drops[p.cell])
	p.pickup_lock=p.cell
	if Catalog.ITEMS[kind].kind!="active":return
	var held=p.item
	p.item=kind
	if held>0:drops[p.cell]=held
	else:drops.erase(p.cell)
	if i==0:stat("items")
	sound("pickup")

func use_item(i):
	if i>=players.size():return
	var p=players[i]
	if p.dead or p.item==0:return
	var kind=int(p.item)
	if p.trap>0 and kind not in [1,9,18]:return
	if kind==9 and p.trap<=0:return
	if kind==3 and bombs.filter(func(b):return b.owner==i).is_empty():return
	if kind==17:
		var target=null
		var distance=7
		for other in players:
			if other.dead or other.team==p.team or other.trap>0:continue
			var dist=manhattan(p.cell,other.cell)
			if dist<distance and bomb_at(other.cell)==null and bomb_at(p.cell)==null:distance=dist;target=other
		if mode==3:
			for enemy in adventure.enemies:
				if enemy.dead:continue
				var dist=manhattan(p.cell,enemy.cell)
				if dist<distance and bomb_at(enemy.cell)==null and bomb_at(p.cell)==null and occupied(enemy.cell,i)==null:distance=dist;target=enemy
		if target==null:return
		var old=p.cell
		teleport(p,target.cell);teleport(target,old)
	elif kind==11:
		var dest=p.cell
		for step in range(1,4):
			var next=p.cell+p.facing*step
			if not inside(next) or grid[next.y][next.x] in [1,3]:break
			if passable(next,p) and occupied(next,i)==null:dest=next
		if dest==p.cell:return
		teleport(p,dest)
	elif kind==18:
		var rescued=false
		for other in players:
			if not other.dead and other.team==p.team and other.trap>0 and manhattan(p.cell,other.cell)<=3:
				other.trap=0;other.grace=1;rescued=true
				if i==0:stat("rescues")
		if not rescued:return
	elif kind==3:
		for b in bombs.duplicate():
			if b.owner==i and bombs.has(b):explode(b)
	elif kind in [1,9]:
		p.trap=0;p.grace=1
		if kind==1:p.shield=8
	elif kind==2:p.dash=6
	elif kind==6:p.kick=8
	elif kind==10:p.cloak=6
	elif kind==12:
		bubble_fx.infuse(p,1,8)
		if mode==3:adventure.freeze_nearby(p)
		for other in players:
			if not other.dead and other.team!=p.team and manhattan(other.cell,p.cell)<=3:
				other.freeze=2;burst(center(other.cell),Color("bfefff"),10)
	elif kind==13:decoys.append({"cell":p.cell,"team":p.team,"character":p.character,"time":10.0})
	elif kind==14:p.magnet=5
	elif kind in range(20,26):bubble_fx.infuse(p,kind-19)
	p.item=0
	burst(center(p.cell),Color(Catalog.ITEMS[kind].color),12)
	world_fx.impact(center(p.cell),1 if kind==12 else (4 if kind in [10,15,16] else 5),32)
	sound("item")

func place_bomb(i,cell=null):
	if i>=players.size():return false
	var p=players[i]
	if p.dead or p.trap>0 or p.freeze>0:return false
	var c=p.cell if cell==null else cell
	if bombs.filter(func(b):return b.owner==i).size()>=p.capacity or bomb_at(c)!=null or not inside(c):return false
	if grid[c.y][c.x] in [1,3]:return false
	var fuse=3.4 if rule()=="gravity" else 2.3
	bombs.append({"cell":c,"owner":i,"range":p.range,"power":p.power,"timer":fuse,"fuse":fuse,"slide":Vector2i.ZERO,"step":0.0,"element":p.element})
	if i==0:stat("bombs")
	p.attack=.85
	world_fx.impact(center(c),0,24)
	sound("place")
	return true

func blast_cells(b):
	var cells=[b.cell]
	for initial in DIRS:
		var dir=initial
		var c=b.cell
		var pierced_box=null
		var pierced=false
		for n in range(b.range):
			c+=dir
			if not inside(c) or grid[c.y][c.x] in [1,3]:break
			if not cells.has(c):cells.append(c)
			if bomb_at(c)!=null:break
			if grid[c.y][c.x]==2:
				var box=crates.at(c)
				if b.get("element",0)!=6:break
				if pierced and (box==null or box!=pierced_box):break
				pierced=true;pierced_box=box
			if terrain.has(c) and terrain[c].type=="mirror":
				dir=Vector2i(-dir.y,dir.x)*terrain[c].turn
	return bubble_fx.extra_cells(b,cells)
func explode(b):
	if not bombs.has(b):return
	var cells=blast_cells(b)
	map_rules.on_explode(b,cells)
	bombs.erase(b)
	var chained: Array=[]
	var hit_boxes:Dictionary={}
	for c in cells:
		if grid[c.y][c.x]==2:crates.damage(c,b.owner,hit_boxes)
		elif drops.has(c):drops.erase(c)
		var next=bomb_at(c)
		if next!=null:chained.append(next)
		blasts.append({"cell":c,"time":(.95 if b.get("element",0)==2 else .5)+.22*b.power,"owner":b.owner,"element":b.get("element",0)})
		burst(center(c),Color("c8f8ff"),3)
	bubble_fx.on_explode(b,cells)
	shake=1.6
	sound("splash")
	for next in chained:explode(next)

func kick_bomb(b,dir):
	var dest=b.cell+dir
	if not bubble_can_move(dest):return
	b.cell=dest;b.slide=dir;b.step=.11
	burst(center(dest),Color("baffaf"),5)
	sound("place")
func drop_supply():
	var locations=[Vector2i(10,7),Vector2i(7,6),Vector2i(11,6),Vector2i(9,4),Vector2i(9,8)]
	locations.shuffle()
	var count=0
	for c in locations:
		if not passable(c) or occupied(c)!=null or drops.has(c):continue
		var burning=false
		for f in blasts:
			if f.cell==c:burning=true
		if burning:continue
		drops[c]=random_drop()
		if count==0 and round_time>35:drops[c]=15
		burst(center(c),Color("ffdf73"),12)
		count+=1
		if count>=2:break
	if count>0:announce("中央补给到达！");sound("pickup")

func update_mechanisms(dt):
	mechanism_time-=dt
	if mechanism_time<=0:
		match rule():
			"vine":
				mechanism_time=18
				for c in vine_cells:
					if occupied(c)==null and bomb_at(c)==null:grid[c.y][c.x]=2;drops.erase(c)
				announce("藤蔓又长回来了！")
			"blizzard":
				mechanism_time=12
				for p in players:p.slow=2.5
				announce("暴风雪！暂时减速。")
			"quake":
				mechanism_time=12;shake=3
				for b in bombs:b.timer=maxf(.3,b.timer-.9)
				var removed=0
				for y in range(3,H-3):
					for x in range(4,W-4):
						if grid[y][x]==2 and rng.randf()<.2 and removed<3:crates.damage(Vector2i(x,y));removed+=1
				announce("地震！泡泡提前爆炸！")
			"laser":
				mechanism_time=7
				var y=[3,6,9][int(round_time/7)%3]
				var cells: Array=[]
				for x in range(1,W-1):cells.append(Vector2i(x,y))
				hazards.append({"cells":cells,"wait":1.2,"type":"laser"})
				announce("激光预警！离开亮起的横线。")
			"meteor":
				mechanism_time=5
				var c=Vector2i(rng.randi_range(3,W-4),rng.randi_range(3,H-4))
				var cells: Array=[]
				for y in range(-1,2):
					for x in range(-1,2):cells.append(c+Vector2i(x,y))
				hazards.append({"cells":cells,"wait":1.5,"type":"meteor"})
			"storm":
				mechanism_time=6
				var alive=players.filter(func(p):return not p.dead)
				if not alive.is_empty():
					var c=alive[rng.randi_range(0,alive.size()-1)].cell
					var cells=[c]
					for d in DIRS:
						for n in range(1,3):
							if inside(c+d*n):cells.append(c+d*n)
					hazards.append({"cells":cells,"wait":1.3,"type":"storm"})
			_:mechanism_time=6
	for hazard in hazards.duplicate():
		hazard.wait-=dt
		if hazard.wait<=0:
			for c in hazard.cells:
				if inside(c) and grid[c.y][c.x] not in [1,3]:
					if grid[c.y][c.x]==2:crates.damage(c)
					blasts.append({"cell":c,"time":.6,"owner":-1})
					burst(center(c),Color("ffe68a"),3)
			hazards.erase(hazard)
			shake=2;sound("splash")
	if rule()=="lava" and fmod(round_time,10)>7.5:
		for p in players:
			if terrain.has(p.cell) and terrain[p.cell].type=="lava":damage_player(p,-1)
	if rule()=="magnet":
		for b in bombs:
			if b.slide==Vector2i.ZERO and b.timer>1.2:
				var dir=Vector2i(signi(10-b.cell.x),0) if b.cell.x!=10 else Vector2i(0,signi(7-b.cell.y))
				if dir!=Vector2i.ZERO and bubble_can_move(b.cell+dir):b.slide=dir;b.step=.3
	if rule()=="train":
		var phase=fmod(round_time,12)
		if phase>=8:
			var head=int((phase-8)*6)-2
			for p in players:
				if p.dead or p.cell.y!=7 or p.cell.x>head or p.cell.x<head-2:continue
				var pushed=false
				for dir in [Vector2i.UP,Vector2i.DOWN]:
					if passable(p.cell+dir,p) and occupied(p.cell+dir,p.id)==null:teleport(p,p.cell+dir);pushed=true;break
				if not pushed:damage_player(p,-1)

func flood_ring(ring):
	for y in range(1,H-1):
		for x in range(1,W-1):
			if mini(mini(x,W-1-x),mini(y,H-1-y))!=ring:continue
			var c=Vector2i(x,y)
			var b=bomb_at(c)
			if b!=null:explode(b)
			grid[y][x]=3;drops.erase(c)
			collapsed_at[c]=round_time
			burst(center(c),Color("ac9dc0"),5)
			for p in players:
				if p.cell==c:kill_player(p)
	announce("岛屿正在坍塌！向中央移动。")
	shake=1.5
	sound("splash")

func finish_round(winner):
	if state!="play":return
	state="result"
	result_winner=winner
	if winner>=0:scores[winner]+=1
	match_over=mode in [0,3] or (winner>=0 and scores[winner]>=2)
	if winner<0:result_text="这一局平手"
	elif mode==3:result_text=("群岛重获新生！" if adventure_stage==20 else "冒险任务完成！") if winner==0 else "冒险暂时受挫"
	elif mode==0:result_text=("群岛通关！" if campaign_stage==20 else "闯关成功！") if winner==0 else "这次没闯过去"
	elif mode==2:result_text=("蓝队" if winner==0 else "桃队")+("夺冠！" if match_over else "获胜！")
	else:
		var champion=players.filter(func(p):return p.team==winner)[0]
		result_text=Catalog.CHARACTERS[champion.character].name+("夺冠！" if match_over else "获胜！")
	if winner<0:stat("draws")
	elif winner==players[0].team:stat("wins")
	else:stat("losses")
	if mode==0 and winner==0:
		var previous=int(profile.cleared)
		profile.cleared=maxi(previous,campaign_stage)
		profile.stage=mini(20,campaign_stage+1)
		if int(profile.cleared)>previous:
			for c in Catalog.CHARACTERS:
				if c.unlock==campaign_stage:announce("新角色解锁："+c.name)
	if mode==3 and winner==0:
		profile.adventure_cleared=maxi(int(profile.adventure_cleared),adventure_stage)
		profile.adventure_stage=mini(20,adventure_stage+1)
		stat("pve_stages")
	round_recorded=true
	save_profile()
	sound("win")

func manhattan(a,b):return abs(a.x-b.x)+abs(a.y-b.y)
func danger_cells():
	var danger: Dictionary={}
	if mode==3:
		for enemy in adventure.enemies:
			if enemy.dead:continue
			danger[enemy.cell]=0
			for d in DIRS:danger[enemy.cell+d]=minf(danger.get(enemy.cell+d,99),.8)
	for f in blasts:
		if f.time>0:danger[f.cell]=0.0
	for b in bombs:
		for c in blast_cells(b):danger[c]=minf(danger.get(c,99),b.timer)
	for hazard in hazards:
		for c in hazard.cells:danger[c]=minf(danger.get(c,99),hazard.wait)
	for echo in (map_rules.echoes if map_rules else []):
		for c in echo.cells:danger[c]=minf(danger.get(c,99),echo.wait)
	if rule()=="lava" and fmod(round_time,10)>5.5:
		for c in terrain:
			if terrain[c].type=="lava":danger[c]=0
	if clock_time<=3:
		var next_ring=sudden_ring+2
		for y in range(1,H-1):
			for x in range(1,W-1):
				if mini(mini(x,W-1-x),mini(y,H-1-y))==next_ring:danger[Vector2i(x,y)]=2
	return danger

func escape_direction(p,danger):
	var queue=[{"cell":p.cell,"first":Vector2i.ZERO,"depth":0}]
	var visited={p.cell:true}
	while not queue.is_empty():
		var node=queue.pop_front()
		if node.depth>0 and not danger.has(node.cell):return node.first
		if node.depth>=6:continue
		for dir in DIRS:
			var c=node.cell+dir
			if visited.has(c) or not passable(c,p) or occupied(c,p.id)!=null:continue
			if danger.get(c,99)<node.depth*move_duration(p)+.15:continue
			visited[c]=true
			queue.append({"cell":c,"first":dir if node.depth==0 else node.first,"depth":node.depth+1})
	return Vector2i.ZERO

func route_direction(p,target,danger):
	var queue=[{"cell":p.cell,"first":Vector2i.ZERO}]
	var visited={p.cell:true}
	var best=Vector2i.ZERO
	var distance=manhattan(p.cell,target)
	while not queue.is_empty():
		var node=queue.pop_front()
		var dist=manhattan(node.cell,target)
		if dist<distance:distance=dist;best=node.first
		if node.cell==target:return node.first
		for dir in DIRS:
			var c=node.cell+dir
			if visited.has(c) or not passable(c,p) or danger.has(c):continue
			var other=occupied(c,p.id)
			if other!=null and c!=target:continue
			visited[c]=true
			queue.append({"cell":c,"first":dir if node.cell==p.cell else node.first})
	return best

func bot_direction(p,danger):
	if danger.has(p.cell):
		var escape=escape_direction(p,danger)
		if escape!=Vector2i.ZERO:return escape
	var target=adventure.bot_target(p) if mode==3 else null
	var best=manhattan(p.cell,target) if target!=null else 999
	for other in players:
		if other.dead:continue
		if other.team==p.team and other.trap<=0:continue
		var distance=manhattan(other.cell,p.cell)
		if other.team==p.team:distance-=8
		if distance<best:target=other.cell;best=distance
	for d in decoys:
		if d.team!=p.team and manhattan(d.cell,p.cell)<best:target=d.cell;best=manhattan(d.cell,p.cell)
	for c in drops:
		var kind=int(drops[c])
		if Catalog.ITEMS[kind].kind=="active" and p.item!=0:continue
		var distance=manhattan(c,p.cell)-3
		if distance<best:target=c;best=distance
	if target!=null:
		var dir=route_direction(p,target,danger)
		if dir!=Vector2i.ZERO:return dir
	var choices: Array=[]
	for d in DIRS:
		if passable(p.cell+d,p) and not danger.has(p.cell+d) and occupied(p.cell+d,p.id)==null:choices.append(d)
	return choices[rng.randi_range(0,choices.size()-1)] if not choices.is_empty() else Vector2i.ZERO

func bot_actions(p,danger):
	if p.item!=0:
		var should_use=false
		match int(p.item):
			1,9,11:should_use=danger.has(p.cell) or p.trap>0
			3:should_use=bombs.any(func(b):return b.owner==p.id and not blast_cells(b).has(p.cell))
			6:should_use=DIRS.any(func(d):return bomb_at(p.cell+d)!=null)
			10:should_use=DIRS.any(func(d):return inside(p.cell+d) and grid[p.cell.y+d.y][p.cell.x+d.x]==2)
			12,13,17:should_use=players.any(func(other):return not other.dead and other.team!=p.team and manhattan(other.cell,p.cell)<=4)
			18:should_use=players.any(func(other):return not other.dead and other.team==p.team and other.trap>0 and manhattan(other.cell,p.cell)<=3)
			_:should_use=true
		if mode==3 and p.item in [12,13,17]:should_use=adventure.enemies.any(func(enemy):return not enemy.dead and manhattan(enemy.cell,p.cell)<=4)
		if should_use:use_item(p.id)
	if danger.has(p.cell) or p.get("attack",0)>0 or bomb_at(p.cell)!=null:return
	var wants_bomb=adventure.should_bomb(p) if mode==3 else false
	for other in players:
		if not other.dead and other.team!=p.team and manhattan(other.cell,p.cell)<=3:wants_bomb=true
	for d in DIRS:
		var c=p.cell+d
		if inside(c) and grid[c.y][c.x]==2:wants_bomb=true
	if not wants_bomb:return
	var virtual={"cell":p.cell,"range":p.range,"timer":2.3,"owner":p.id,"element":p.element}
	bombs.append(virtual)
	var hypothetical=danger_cells()
	bombs.erase(virtual)
	if escape_direction(p,hypothetical)!=Vector2i.ZERO:place_bomb(p.id)

func rect(pos,size,color):draw_rect(Rect2(pos,size),color)
func pixel_size(size):return 12 if size<18 else (24 if size<32 else 36)
func text_at(message,pos,size=12,color=CREAM):draw_string(font,pos,str(message),HORIZONTAL_ALIGNMENT_LEFT,-1,pixel_size(size),color)
func centered(message,y,size=12,color=CREAM):
	var width=font.get_string_size(str(message),HORIZONTAL_ALIGNMENT_LEFT,-1,pixel_size(size)).x
	text_at(message,Vector2((640-width)/2,y),size,color)
func wrapped(message,pos,width=9,color=CREAM):
	var line=0
	var start=0
	while start<message.length():
		var count=mini(width,message.length()-start)
		if start+count<message.length() and message.substr(start+count,1) in "。，！；：、）":count-=1
		text_at(message.substr(start,count),pos+Vector2(0,line*16),12,color)
		start+=count
		line+=1

func panel(pos,size,color=Color("60788e")):
	rect(pos+Vector2(0,3),size,Color("101b2e"))
	rect(pos,size,color)
	rect(pos+Vector2(2,2),size-Vector2(4,4),Color("1c3045"))
func button(pos,size,label,selected=false):
	panel(pos,size,Color("ffe08e") if selected else Color("527c91"))
	var width=font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
	text_at(label,pos+Vector2((size.x-width)/2,size.y/2+5),12,Color("ffe08e") if selected else CREAM)
func item_icon(pos,kind,side=20):
	if kind<=0:return
	var source=Rect2(Vector2((kind%10)*20,int(kind/10)*20),Vector2(20,20))
	draw_texture_rect_region(item_art,Rect2(pos,Vector2(side,side)),source)
func portrait(pos,character,size=Vector2(20,24),frame=0):
	draw_texture_rect_region(character_art,Rect2(pos,size),Rect2(Vector2(character*20,frame*24),Vector2(20,24)))
func color_for(p):
	if mode in [0,2,3]:return COLORS[0 if p.team==0 else 1]
	return COLORS[p.id]
func burst(pos,color,amount):
	for i in range(amount):particles.append({"pos":pos,"vel":Vector2(rng.randf_range(-32,32),rng.randf_range(-42,10)),"life":rng.randf_range(.25,.55),"color":color})

func _draw():
	if backgrounds.is_empty():return
	draw_texture(backgrounds[Catalog.MAPS[arena].theme],Vector2.ZERO)
	if state=="story":adventure.draw_story();return
	if state=="menu":draw_menu();return
	if state=="maps":draw_map_browser();return
	if state=="characters":draw_characters();return
	if state=="stats":draw_stats();return
	if state=="help":draw_help();return
	draw_hud()
	draw_sidebar()
	draw_set_transform(Vector2(sin(elapsed*83),cos(elapsed*71))*shake)
	rect(ORIGIN-Vector2(3,3),Vector2(W*TILE+6,H*TILE+6),Color("111b30"))
	for y in range(H):
		for x in range(W):draw_tile(Vector2i(x,y))
	world_fx.draw_ground()
	crates.draw()
	bubble_fx.draw_fields()
	draw_terrain()
	map_rules.draw()
	draw_weather()
	for c in drops:
		if grid[c.y][c.x]!=0:continue
		var bob=round(sin(elapsed*4+c.x)*1.5)
		item_icon(center(c)+Vector2(-10,-10+bob),int(drops[c]))
	for b in bombs:
		if b.timer<.7:draw_warning(b)
	for b in bombs:draw_bomb(b)
	for f in blasts:draw_splash(f)
	for d in decoys:
		portrait(center(d.cell)-Vector2(10,15),d.character)
		draw_arc(center(d.cell),9,0,TAU,20,Color("d8abef"),1)
	if mode==3:adventure.draw_world()
	var sorted=players.duplicate()
	sorted.sort_custom(func(a,b):return a.visual.y<b.visual.y)
	for p in sorted:
		if not p.dead:draw_actor(ORIGIN+p.visual*TILE+Vector2(TILE/2.0,TILE/2.0),p)
	for effect in pickup_effects:
		var progress=1-effect.life/.65
		item_icon(effect.pos+Vector2(-8,-12-progress*22),effect.kind,16*(1-progress*.35))
		draw_arc(effect.pos,5+progress*14,0,TAU,24,Color(1,.94,.65,1-progress),1)
	for p in particles:rect(p.pos.round(),Vector2(2,2),p.color)
	world_fx.draw_air()
	map_rules.draw_overlay()
	draw_set_transform(Vector2.ZERO)
	if notice_time>0:
		panel(Vector2(194,79),Vector2(252,19),Color("ffe08e"))
		centered(notice,93,12,Color("ffe08e"))
	if countdown>0:
		panel(Vector2(238,165),Vector2(164,44),Color("62ceff"))
		centered(str(int(ceil(countdown))) if countdown>.7 else "开战！",197,24)
	if state=="pause":draw_pause()
	elif state=="result":draw_result()

func draw_tile(c):
	var theme=Catalog.MAPS[arena].theme
	var pos=ORIGIN+Vector2(c)*TILE
	var cell=grid[c.y][c.x]
	if cell==2 and crates.at(c)!=null:cell=0
	var kind=(c.x+c.y)%2
	if cell==3:
		rect(pos,Vector2(TILE,TILE),Color("101524"))
		var age=round_time-collapsed_at.get(c,round_time-1)
		if age<.55:
			var inset=age*9
			draw_texture_rect_region(tiles,Rect2(pos+Vector2(inset,inset+age*8),Vector2(TILE-2*inset,TILE-2*inset)),Rect2(Vector2(0,theme*20),Vector2(20,20)))
		return
	if cell==1:kind=2
	elif cell==2:kind=3
	elif cell==3:kind=4
	draw_texture_rect_region(tiles,Rect2(pos,Vector2(TILE,TILE)),Rect2(Vector2(kind*20,theme*20),Vector2(20,20)))
	if rule()=="gate" and cell==1 and c.x>0 and c.y>0 and c.x<W-1 and c.y<H-1:
		rect(pos+Vector2(2,1),Vector2(16,17),Color("b99a70"))
		rect(pos+Vector2(1,1),Vector2(18,3),Color("ecd2a0"))
		for x in [5,10,15]:draw_line(pos+Vector2(x,5),pos+Vector2(x,15),Color("8a765b"),1)
	if cell==2 and vine_cells.has(c):
		draw_line(pos+Vector2(6,17),pos+Vector2(8,2),Color("95c989"),2)
		draw_line(pos+Vector2(8,10),pos+Vector2(14,6),Color("b1dea0"),2)
	if cell==2 and gold_boxes.has(c):
		draw_rect(Rect2(pos+Vector2(3,3),Vector2(14,13)),Color("ffe696"),false,1)
		item_icon(pos+Vector2(4,2),19,12)
	if gates.has(c):
		draw_rect(Rect2(pos+Vector2(3,2),Vector2(14,16)),Color("edca81"),false,1)
		if cell==1:
			for x in [6,10,14]:rect(pos+Vector2(x,3),Vector2(1,13),Color("edca81"))

func draw_terrain():
	for c in terrain:
		if grid[c.y][c.x]!=0:continue
		var tile=terrain[c]
		var pos=center(c)
		match tile.type:
			"portal":
				draw_circle(pos,8,Color("7563b7"))
				draw_arc(pos,6,elapsed*2,elapsed*2+5.5,20,Color("e0beff"),2)
				draw_circle(pos,2,Color("f5dcff"))
			"flow":
				for n in [-1,0,1]:
					var dx=(n*5+int(elapsed*8)%5)*tile.dir.x
					draw_line(pos+Vector2(dx-2*tile.dir.x,-3),pos+Vector2(dx,0),Color("d1f9e6"),1)
					draw_line(pos+Vector2(dx,0),pos+Vector2(dx-2*tile.dir.x,3),Color("d1f9e6"),1)
			"ice":
				rect(pos-Vector2(9,9),Vector2(18,18),Color("a8d8ec"))
				draw_line(pos+Vector2(-7,1),pos+Vector2(3,-6),Color("e6fbff"),1)
				draw_line(pos+Vector2(0,7),pos+Vector2(7,0),Color("e6fbff"),1)
			"spring":
				if rule()=="mushroom":
					draw_texture_rect_region(tiles,Rect2(pos-Vector2(10,10),Vector2(20,20)),Rect2(Vector2(100,20),Vector2(20,20)))
				else:
					rect(pos-Vector2(8,7),Vector2(16,14),Color("986caa"))
					for n in range(4):draw_line(pos+Vector2(-6,-4+n*3),pos+Vector2(6,-4+n*3),Color("ffd7de"),1)
			"sand":
				for n in range(3):draw_arc(pos,3+n*2,.1,3.8,16,Color("af8f58"),1)
			"switch":
				draw_circle(pos,7,INK);draw_circle(pos,5,Color("92e6b3") if gate_open else Color("ffe088"))
			"lava":
				var phase=fmod(round_time,10)
				var color=Color("ffce80") if phase>7.5 else Color("b66a59")
				if phase>5.5 and int(elapsed*5)%2==0:color=Color("f9a970")
				draw_line(pos+Vector2(-6,-8),pos+Vector2(2,0),color,2)
				draw_line(pos+Vector2(2,0),pos+Vector2(-3,8),color,2)
			"rail":
				draw_line(pos+Vector2(-10,-6),pos+Vector2(10,-6),Color("c3c8b6"),1)
				draw_line(pos+Vector2(-10,6),pos+Vector2(10,6),Color("c3c8b6"),1)
				for x in [-6,2]:rect(pos+Vector2(x,-7),Vector2(2,15),Color("846b62"))
			"supply":
				draw_rect(Rect2(pos-Vector2(7,7),Vector2(14,14)),Color("e9d898"),false,1)
	if rule()=="magnet":item_icon(center(Vector2i(10,7))-Vector2(10,10),14)
	if rule()=="sand":
		draw_arc(center(Vector2i(10,7)),14,0,TAU,28,Color("74c8b8"),3)
	if rule()=="laser":
		for y in [3,6,9]:
			draw_circle(center(Vector2i(0,y)),5,Color("ffca88"));draw_circle(center(Vector2i(W-1,y)),5,Color("ffca88"))
	for hazard in hazards:
		for c in hazard.cells:
			if not inside(c):continue
			var pos=center(c)
			draw_arc(pos,8,0,TAU,16,Color("ffcf86"),1)
			draw_line(pos+Vector2(-5,-5),pos+Vector2(5,5),Color("ffcf86"),1)
			draw_line(pos+Vector2(-5,5),pos+Vector2(5,-5),Color("ffcf86"),1)
	if rule()=="train":
		var phase=fmod(round_time,12)
		if phase>=8:
			var head=int((phase-8)*6)-2
			for car in range(3):
				var c=Vector2i(head-car,7)
				if c.x<1 or c.x>=W-1:continue
				var pos=center(c)
				rect(pos+Vector2(-9,-10),Vector2(18,17),Color("dfa464"))
				rect(pos+Vector2(-7,-8),Vector2(14,8),Color("67a8b6"))
				draw_circle(pos+Vector2(-5,8),3,INK);draw_circle(pos+Vector2(5,8),3,INK)
				if car==0:rect(pos+Vector2(4,-13),Vector2(4,5),Color("e9c095"))
	if clock_time<=3:
		var ring=sudden_ring+2
		var until=clock_time+float(sudden_ring+1)*5
		if until<=2 and int(elapsed*5)%2==0:
			for y in range(1,H-1):
				for x in range(1,W-1):
					if mini(mini(x,W-1-x),mini(y,H-1-y))==ring:draw_rect(Rect2(ORIGIN+Vector2(x,y)*TILE+Vector2(1,1),Vector2(TILE-2,TILE-2)),Color("ffe08e"),false,1)

func draw_bomb(b):
	var pos=center(b.cell)
	var p=players[b.owner]
	var element=b.get("element",0)
	var color=color_for(p) if element==0 else Color(BubbleEffects.STYLES[element].color)
	var pulse=sin(elapsed*(15 if b.timer<.7 else 4))*.5
	draw_circle(pos+Vector2(0,3),8.5,Color("355265"))
	draw_circle(pos,8.5+pulse,INK)
	draw_circle(pos,7.5+pulse,color)
	draw_arc(pos+Vector2(0,1),5.5+pulse,.2,2.8,18,color.darkened(.3),2)
	draw_circle(pos+Vector2(-3,-3),2,Color("edffff"))
	draw_circle(pos+Vector2(3,2),1,Color("e0faff"))
	if element>0:
		draw_arc(pos,10,elapsed*2,elapsed*2+4.5,20,color.lightened(.3),1)
		item_icon(pos-Vector2(4,4),19+element,8)
	if b.power>0:draw_arc(pos,9.5,elapsed,elapsed+4.8,20,Color("fff6b1"),1)
	rect(pos+Vector2(-7,10),Vector2(14,1),INK)
	rect(pos+Vector2(-7,10),Vector2(14*clampf(b.timer/b.fuse,0,1),1),CREAM)
func draw_warning(b):
	for c in blast_cells(b):draw_rect(Rect2(ORIGIN+Vector2(c)*TILE+Vector2(2,2),Vector2(16,16)),Color(1,.93,.62,.7),false,1)
func draw_splash(f):
	var pos=center(f.cell)
	var element=f.get("element",0)
	var color=Color(BubbleEffects.STYLES[element].color) if element>0 else (Color("ffe49c") if f.owner<0 else color_for(players[f.owner]).lightened(.25))
	rect(pos+Vector2(-10,-5),Vector2(20,10),color)
	rect(pos+Vector2(-5,-10),Vector2(10,20),color)
	rect(pos+Vector2(-10,-2),Vector2(20,4),Color("eaffff"))
	rect(pos+Vector2(-2,-10),Vector2(4,20),Color("eaffff"))

func draw_actor(pos,p):
	var color=color_for(p)
	draw_arc(pos+Vector2(0,7),8,0,TAU,18,color,1)
	if p.grace>0 and int(elapsed*13)%2==0:return
	var walking=p.move<1 and p.trap<=0 and p.freeze<=0
	var phase=elapsed*(8 if p.mount>0 else 12)
	var bob=-abs(sin(phase))*(1.2 if p.mount>0 else .7) if walking else sin(elapsed*2+p.id)*.25
	if p.jump>0:bob-=sin(clampf(p.jump/.8,0,1)*PI)*9
	var direction=0 if p.facing==Vector2i.DOWN else (1 if p.facing==Vector2i.UP else (2 if p.facing==Vector2i.LEFT else 3))
	var frame=direction*3+(1+int(phase*2)%2 if walking else 0)
	if p.mount>0:
		draw_texture_rect_region(mount_art,Rect2(pos+Vector2(-16,-12+bob),Vector2(32,28)),Rect2(Vector2((p.mount-1)*32,0),Vector2(32,28)))
		portrait(pos+Vector2(-10,-23+bob),p.character,Vector2(20,24),frame)
		for n in range(p.mount_hp):rect(pos+Vector2(-6+n*3,16),Vector2(2,2),Color("fff09b"))
	else:portrait(pos+Vector2(-10,-15+bob),p.character,Vector2(20,24),frame)
	if p.freeze>0:
		draw_rect(Rect2(pos+Vector2(-10,-14),Vector2(20,24)),Color(.67,.88,1,.35))
	if p.shield>0 or p.trap>0:
		draw_arc(pos+Vector2(0,-3),12,0,TAU,24,Color("b3ffe0") if p.shield>0 else Color("e7fcff"),1)
	if p.trap>0:
		text_at(str(snappedf(p.trap,.1)),pos+Vector2(-8,-19),12,Color("fff3c5"))
	if p.kick>0:item_icon(pos+Vector2(-14,5),6,9)
	if p.dash>0:
		rect(pos+Vector2(-13,5),Vector2(4,1),Color("ffe08e"));rect(pos+Vector2(-12,8),Vector2(3,1),Color("ffe08e"))
	if p.cloak>0:draw_arc(pos,10,PI,TAU,16,Color("c7a4ff"),1)
	if p.magnet>0:draw_arc(pos,14,elapsed,elapsed+3.7,18,Color("ffb5b1"),1)

func draw_hud():
	text_at("泡泡糖",Vector2(8,15),12,CREAM)
	text_at(Catalog.MAPS[arena].name,Vector2(130,15),12,CREAM)
	centered(("%d:%02d" % [int(maxf(0,clock_time))/60,int(maxf(0,clock_time))%60]) if clock_time>0 else "坍塌中",15,12,Color("ffe08e"))
	var label="冒险 %d/20" % adventure_stage if mode==3 else ("第%d关" % campaign_stage if mode==0 else ("蓝队%d : %d桃队" % [scores[0],scores[1]] if mode==2 else "第%d局 / 两胜夺冠" % round_index))
	text_at(label,Vector2(441,15),12,CREAM)
	for i in range(players.size()):
		var p=players[i]
		var pos=Vector2(8+i*156,23)
		panel(pos,Vector2(150,46),color_for(p).darkened(.15))
		portrait(pos+Vector2(4,2),p.character,Vector2(16,20))
		text_at(str(i+1)+" "+Catalog.CHARACTERS[p.character].name+("机" if p.bot else ""),pos+Vector2(23,14),12,color_for(p))
		text_at("出局" if p.dead else ("泡%d 水%d 速%d" % [p.capacity,p.range,p.speed]),pos+Vector2(6,29),12,Color("95bdc4") if p.dead else CREAM)
		if p.item>0:item_icon(pos+Vector2(6,29),p.item,14)
		text_at(("机" if p.bot else ["Q","/","O","Y"][i])+" "+Catalog.ITEMS[p.item].name,pos+Vector2(23,42),12,Color(Catalog.ITEMS[p.item].color))
	for i in range(players.size()):
		var label_control="电脑自动对战" if players[i].bot else CONTROL_NAMES[i]
		text_at(label_control,Vector2(8+i*156,354),12,color_for(players[i]))

func draw_sidebar():
	panel(Vector2(8,83),Vector2(112,252),Color("648297"))
	panel(Vector2(520,83),Vector2(112,252),Color("648297"))
	var p=players[0]
	text_at("我的成长",Vector2(19,101),12,Color("ffe08e"))
	item_icon(Vector2(18,111),p.item,24)
	text_at(Catalog.ITEMS[p.item].name,Vector2(45,127),12,Color(Catalog.ITEMS[p.item].color))
	wrapped(Catalog.ITEMS[p.item].tip,Vector2(18,149),8,Color("a6c7c9"))
	var kinds=[4,5,7,8,16]
	var values=[p.capacity,p.range,p.speed,p.power,p.riding]
	for i in range(5):
		item_icon(Vector2(18,191+i*21),kinds[i],17)
		text_at(["泡泡 ","水柱 ","跑鞋 ","强化 ","骑术 "][i]+str(values[i]),Vector2(40,204+i*21),12)
	text_at((BubbleEffects.STYLES[p.element].name+" %d秒" % int(ceil(p.element_time))) if p.element>0 else "拾取自动换道具",Vector2(18,303),12,Color(BubbleEffects.STYLES[p.element].color))
	text_at(Catalog.MOUNTS[p.mount].name,Vector2(18,318),12,Color("ffe08e"))
	text_at("冒险任务" if mode==3 else "地图机关",Vector2(529,101),12,Color("ffe08e"))
	if mode==3:
		adventure.draw_sidebar()
		button(Vector2(528,309),Vector2(96,20),"暂停 / 退出")
		return
	wrapped(Catalog.MAPS[arena].tip,Vector2(529,123),8,Color("b7d2ce"))
	if mode in [0,2]:
		wrapped("队友可触碰救援；同队水柱不伤队友。",Vector2(529,213),8,Color("9ce3c4"))
	else:wrapped("困住对手后触碰获胜，或让泡泡计时结束。",Vector2(529,213),8,Color("ffc8c6"))
	text_at("时间到后逐圈坍塌",Vector2(529,297),12,Color("ffdf8a"))
	button(Vector2(528,309),Vector2(96,20),"暂停 / 退出")

func mini_board(pos,step=8):
	var theme=Catalog.MAPS[arena].theme
	for y in range(H):
		for x in range(W):
			var cell=grid[y][x]
			var kind=2 if cell==1 else (3 if cell==2 else (x+y)%2)
			draw_texture_rect_region(tiles,Rect2(pos+Vector2(x,y)*step,Vector2(step,step)),Rect2(Vector2(kind*20,theme*20),Vector2(20,20)))
	for c in terrain:
		var type=terrain[c].type
		if type in ["portal","spring","lava","switch","ice"]:
			draw_circle(pos+Vector2(c)*step+Vector2(step/2,step/2),step*.35,Color("d5aeff") if type=="portal" else Color("ffe1aa"))

func draw_menu():
	rect(Vector2.ZERO,Vector2(640,360),Color(.04,.08,.14,.35))
	text_at("泡泡糖",Vector2(24,53),36,Color("a4efff"))
	text_at("像素群岛大冒险",Vector2(210,49),24,Color("ffd0c5"))
	text_at("四十地图 / 剧情冒险 / 四人同屏",Vector2(24,77),12,CREAM)
	panel(Vector2(20,96),Vector2(258,234),Color("83b5b6"))
	text_at("方向键设置，回车开始",Vector2(32,119),12,Color("ffe08e"))
	var values=[MODES[mode],("冒险%d/20（通%d）" % [adventure_stage,int(profile.adventure_cleared)]) if mode==3 else "第%d关（已通%d关）" % [campaign_stage,int(profile.cleared)] if mode==0 else ("随机地图" if selected_map<0 else Catalog.MAPS[selected_map].name),str(1 if mode==0 else humans)+"名真人",str((4 if companion else humans) if mode==3 else ((2 if campaign_stage<5 else 4) if mode==0 else (4 if mode==2 else seats)))+"个席位",(("开启" if companion else "关闭")+"电脑队友") if mode==3 else (("开启" if companion else "关闭")+"（第五关起）") if mode==0 else (("前两人一队" if team_layout==0 else "交叉对抗") if mode==2 else "各自为战"),Catalog.CHARACTERS[chosen_characters[0]].name]
	var labels=["模式","地图","真人","人数","队伍","角色"]
	for i in range(6):
		var y=151+i*24
		if i==menu_row:rect(Vector2(26,y-14),Vector2(246,21),Color("35596b"))
		text_at(labels[i]+"  "+values[i],Vector2(32,y),12,Color("ffe08e") if i==menu_row else CREAM)
	button(Vector2(24,300),Vector2(250,26),"开始游戏 / 回车",true)
	panel(Vector2(290,96),Vector2(326,202),Color("92a5c4"))
	text_at(Catalog.MAPS[arena].name,Vector2(303,116),12,Color("ffe08e"))
	var preview_seconds=Catalog.MAPS[arena].seconds+(90 if mode==3 else 0)
	text_at("%d:%02d" % [int(preview_seconds)/60,int(preview_seconds)%60],Vector2(552,116),12,CREAM)
	mini_board(Vector2(358,125),9)
	wrapped(Catalog.MAPS[arena].tip,Vector2(303,277),24,Color("d0dbd0"))
	button(Vector2(290,304),Vector2(102,24),"地图图鉴 V")
	button(Vector2(400,304),Vector2(102,24),"人物选择 C")
	button(Vector2(510,304),Vector2(106,24),"局外统计 B")
	centered("TAB 换地图 / R 随机 / F1 道具与操作 / M 声音",350,12,CREAM)

func page_header(title):
	rect(Vector2.ZERO,Vector2(640,360),Color(.04,.08,.14,.6))
	text_at(title,Vector2(22,30),24,Color("ffe08e"))
	button(Vector2(540,10),Vector2(80,22),"返回 ESC")

func draw_map_browser():
	page_header("四十座像素小岛")
	var page=int(selection/20)
	for slot in range(20):
		var i=page*20+slot
		var map=Catalog.MAPS[i]
		var pos=Vector2(12+(slot%4)*156,45+int(slot/4)*56)
		panel(pos,Vector2(147,52),Color("ffe08e") if i==selection else Color("527a8c"))
		text_at("%02d %s" % [i+1,map.name],pos+Vector2(6,17),12,Color("ffe08e") if i==selection else CREAM)
		draw_texture_rect(backgrounds[map.theme],Rect2(pos+Vector2(7,23),Vector2(48,23)),false)
		item_icon(pos+Vector2(59,24),[1,11,5,15,10,2,12,12,7,3,8,6,15,19,3,14,8,17,6,12][i%20],20)
		text_at(["海港","森林","冰雪","沙漠","火山","工厂","糖果","星空","沼泽","遗迹","深海","空港","王城"][map.theme],pos+Vector2(83,39),12,Color("a8c5c4"))
	button(Vector2(12,331),Vector2(100,23),"上一页")
	button(Vector2(528,331),Vector2(100,23),"下一页")
	centered("第%d/2页 · 方向键选择 / 回车选图" % (page+1),348,12)

func draw_characters():
	page_header("人物与坐骑")
	text_at("正在设置玩家 %d / TAB 切换玩家" % (character_slot+1),Vector2(32,63),12,CREAM)
	for i in range(8):
		var pos=Vector2(32+i*75,92)
		var unlocked=character_unlocked(i)
		panel(pos,Vector2(65,86),Color("ffe08e") if i==selection else Color("648297"))
		portrait(pos+Vector2(12,6),i,Vector2(40,48))
		text_at(Catalog.CHARACTERS[i].name,pos+Vector2(14,67),12,CREAM if unlocked else Color("829bb0"))
		if not unlocked:text_at("通%d关" % Catalog.CHARACTERS[i].unlock,pos+Vector2(7,81),12,Color("ffc8c6"))
	var character=Catalog.CHARACTERS[selection]
	centered(character.name+"："+character.perk,207,12,Color("ffe08e"))
	for i in range(1,4):
		var pos=Vector2(88+(i-1)*184,225)
		draw_texture_rect_region(mount_art,Rect2(pos,Vector2(48,42)),Rect2(Vector2((i-1)*32,0),Vector2(32,28)))
		text_at(Catalog.MOUNTS[i].name,pos+Vector2(54,18),12,Color(Catalog.MOUNTS[i].color))
	button(Vector2(240,283),Vector2(160,28),"选用 / 回车" if character_unlocked(selection) else "闯关后解锁",character_unlocked(selection))
	centered("局内成长每局重置，角色解锁和闯关进度会保存。",343,12)

func draw_stats():
	page_header("我的冒险手账")
	panel(Vector2(28,56),Vector2(584,265),Color("83b5b6"))
	text_at("竞技闯关 %d/20   剧情冒险 %d/20" % [int(profile.cleared),int(profile.adventure_cleared)],Vector2(46,81),12,Color("ffe08e"))
	var names=["参加局数","获胜","失利","平局","放置泡泡","炸开箱子","拾取道具","救援队友","骑乘次数","出局次数","中途退出","游戏分钟","击败怪物","击败守护者","冒险通关次数"]
	var values=[profile.stats.rounds,profile.stats.wins,profile.stats.losses,profile.stats.draws,profile.stats.bombs,profile.stats.crates,profile.stats.items,profile.stats.rescues,profile.stats.mounts,profile.stats.deaths,profile.stats.abandoned,int(profile.stats.seconds/60),profile.stats.monsters,profile.stats.bosses,profile.stats.pve_stages]
	for i in range(15):
		var pos=Vector2(46+(i%3)*186,106+int(i/3)*40)
		text_at(names[i],pos,12,Color("abd0ca"))
		text_at(str(int(values[i])),pos+Vector2(0,24),24,CREAM)
	centered("个人统计记玩家一 · 冒险击败与任务按队伍记录 · 自动存档",346,12)

func draw_help():
	page_header("道具图鉴与操作")
	text_at("玩家1：WASD / 空格 / Q    玩家2：方向键 / 回车 / /",Vector2(20,57),12)
	text_at("玩家3：IJKL / U / O      玩家4：TFGH / R / Y",Vector2(20,75),12)
	var kinds=range(1,19)+range(20,26)
	for slot in range(kinds.size()):
		var i=kinds[slot]
		var pos=Vector2(20+(slot%6)*102,86+int(slot/6)*46)
		item_icon(pos,i,24)
		text_at(Catalog.ITEMS[i].name,pos+Vector2(0,36),12,Color(Catalog.ITEMS[i].color))
	wrapped("水柱困住角色三秒；敌人触碰会出局，队友触碰可救援。坐骑先承受水柱，耐久耗尽才下马。走过道具自动拾取替换，成长每局重置。",Vector2(20,280),48,CREAM)
	text_at("ESC / P 暂停，可返回大厅或保存并退出；M 声音。",Vector2(20,346),12,Color("ffe08e"))

func draw_pause():
	rect(Vector2.ZERO,Vector2(640,360),Color(.03,.06,.12,.85))
	panel(Vector2(160,103),Vector2(320,172),Color("8bd5d1"))
	centered("歇一会儿",136,24,CREAM)
	for i in range(3):button(Vector2(195,153+i*32),Vector2(250,28),["继续对战","返回大厅（记录退出）","保存并退出游戏"][i],i==quit_selection)
	centered("上下选择 / 回车确认 / ESC 继续",294,12)
func draw_result():
	rect(Vector2.ZERO,Vector2(640,360),Color(.03,.06,.12,.82))
	panel(Vector2(135,91),Vector2(370,206),Color("ffe08e"))
	centered(result_text,133,24,Color("ffe08e"))
	if mode==3:
		wrapped(adventure.stage.outro if result_winner==0 else "调整道具与走位，再挑战本关。章节进度已保存。",Vector2(156,158),27,Color("bfe2ce"))
	elif mode==0:
		centered("第%d关 / %s" % [campaign_stage,Catalog.MAPS[arena].name],162,12)
		centered("进度与统计已保存",186,12,Color("a8dbc3"))
	else:
		var label="蓝队 %d : %d 桃队" % [scores[0],scores[1]] if mode==2 else "比分  "+" : ".join(scores.slice(0,players.size()).map(func(value):return str(value)))
		centered(label,168,12)
		centered("两胜夺冠 / 统计已保存",189,12,Color("a8dbc3"))
	var action=(("下一节" if adventure_stage<20 else "重温故事") if result_winner==0 else "重试本节") if mode==3 else ("下一关" if campaign_stage<20 else "重新冒险") if mode==0 and result_winner==0 else ("再战本关" if mode==0 else ("新一场" if match_over else "下一局"))
	button(Vector2(195,210),Vector2(250,30),action+" / 回车",true)
	button(Vector2(195,248),Vector2(250,25),"返回大厅 / ESC")
	if notice_time>0:centered(notice,323,12,Color("ffe08e"))

func close_game():
	if not round_recorded:stat("abandoned");round_recorded=true
	save_profile()
	music.stop()
	for speaker in speakers:speaker.stop()
	await get_tree().create_timer(.15).timeout
	get_tree().quit()
func _exit_tree():
	if music:music.stop();music.stream=null
	for speaker in speakers:speaker.stop();speaker.stream=null

func draw_weather():
	if rule()=="blizzard" and mechanism_time>9.5:
		for n in range(34):
			var x=ORIGIN.x+fposmod(n*37+elapsed*18,W*TILE)
			var y=ORIGIN.y+fposmod(n*23+elapsed*22,H*TILE)
			rect(Vector2(x,y).round(),Vector2(2,2),Color("e5faff"))
	elif rule()=="storm":
		for n in range(30):
			var x=ORIGIN.x+fposmod(n*43-elapsed*13,W*TILE)
			var y=ORIGIN.y+fposmod(n*37+elapsed*95,H*TILE)
			draw_line(Vector2(x,y).round(),Vector2(x-2,y+5).round(),Color("9aaad0"),1)
	elif rule()=="wind" and fmod(round_time,9)>7.5:
		for n in range(8):
			var y=ORIGIN.y+25+n*27
			var x=ORIGIN.x+fposmod(elapsed*70+n*39,W*TILE)
			draw_line(Vector2(x,y),Vector2(x+17,y),Color("bddca2"),1)
