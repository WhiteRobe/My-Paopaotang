extends Node2D

var hero_palette
const HDArt=preload("res://scripts/render/hd_art.gd")
const MenuUI=preload("res://scripts/ui/menu_ui.gd")
const Catalog = preload("res://scripts/data/catalog.gd")
const Weather=preload("res://scripts/gameplay/weather.gd")
const I18n=preload("res://scripts/ui/i18n.gd")
const DynamicLighting=preload("res://scripts/render/dynamic_lighting.gd")
const Encyclopedia=preload("res://scripts/ui/encyclopedia.gd")
const Adventure=preload("res://scripts/gameplay/adventure.gd")
const MapMechanisms=preload("res://scripts/gameplay/map_mechanisms.gd")
const BubbleEffects=preload("res://scripts/gameplay/bubble_effects.gd")
const Crates=preload("res://scripts/gameplay/crates.gd")
const WorldEffects=preload("res://scripts/render/world_effects.gd")
const MAP_COUNT=47
const Racing=preload("res://scripts/gameplay/racing.gd")
var racing
var team_count=2
var W = 27
var H = 19
const VIEW_SIZE=Vector2(27,19)
var camera=Vector2.ZERO
var map_void={}
var canvas:CanvasItem
var world_clip:Control
var world_canvas:Node2D
var game_overlay:Node2D
var difficulty=1
const TILE = 16
const ORIGIN = Vector2(104, 50)
const DIRS = [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]
var SPAWNS = [Vector2i(1,1),Vector2i(1,17),Vector2i(1,9),Vector2i(13,1),Vector2i(25,17),Vector2i(25,1),Vector2i(25,9),Vector2i(13,17)]
const INK = Color("182840")
const CREAM = Color("fff5d5")
const COLORS = [Color("62ceff"),Color("ff8bad"),Color("ffe18a"),Color("a8efac"),Color("c3a2ff"),Color("ffad64"),Color("58e1c0"),Color("ed9ee6")]
const TEAM_NAMES=["青龙队","白虎队","朱雀队","玄武队","麒麟队","凤凰队","苍狼队","玉兔队"]
const MOVE_KEYS = [[KEY_A,KEY_D,KEY_W,KEY_S],[KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN],[KEY_J,KEY_L,KEY_I,KEY_K],[KEY_F,KEY_H,KEY_T,KEY_G]]
const BOMB_KEYS = [KEY_SPACE,KEY_ENTER,KEY_U,KEY_R]
const ITEM_KEYS = [KEY_Q,KEY_SLASH,KEY_O,KEY_Y]
const PICKUP_KEYS=[KEY_E,KEY_PERIOD,KEY_SEMICOLON,KEY_V]
const PICKUP_LABELS=["E",".",";","V"]
const CONTROL_NAMES = ["WASD / 空格 / Q","方向键 / 回车 / /","IJKL / U / O","TFGH / R / Y"]
const MODES = ["单人闯关","赛车竞速","组队对战","剧情冒险 PVE"]
const UI_FONT=preload("res://assets/fonts/ui_font.tres")
const ZH_FONT=preload("res://assets/fonts/ui_font_zh.tres")
var font=UI_FONT
var backgrounds: Array = []
var rng = RandomNumberGenerator.new()
var state = "menu"
var finale_time=0.0
var mode = 0
var humans = 1
var seats = 4
var companion = true
var team_layout = 0
var seat_roles=[-1,-1,-1,-1,-1,-1,-1,-1]
var seat_characters=[-1,-1,-1,-1,-1,-1,-1,-1]
var seat_teams=[-1,-1,-1,-1,-1,-1,-1,-1]
var selected_map = -1
var arena = 0
var campaign_stage = 1
var adventure_stage=1
var adventure
var map_rules
var world_fx
var crates
var bubble_fx
var encyclopedia
var i18n
var language_selection=0
var language_return="menu"
var lighting
var weather
var pause_return="play"
var chosen_characters = [0,1,0,1]
var hd
var frontend
var music_volume=75
var effects_volume=75
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
const BATTLE_OPTIONS={"collapse":0,"pace":0,"daylight":0,"fog":0,"density":0,"loot":0,"mechanisms":0}
var battle_options=BATTLE_OPTIONS.duplicate()
var round_limit = 150.0
var pickup_effects: Array = []
var death_loot:Array=[]
var loot_flights:Array=[]
var preview_only=false
var collapsed_at: Dictionary = {}
var countdown = 0.0
var round_music = "theme"
var shake = 0.0
var supply_time = 20.0
var mechanism_time = 0.0
var sudden_ring = -1
var gate_open = false
var scores = [0,0,0,0,0,0,0,0]
var round_index = 1
var result_text = ""
var result_winner = -1
var match_over = false
var notice = ""
var notice_time = 0.0
var round_recorded = true
var music: AudioStreamPlayer
var music_previous: AudioStreamPlayer
var music_cache: Dictionary={}
var current_music_path=""
var music_fade=1.0
var current_theme = ""
var sounds: Dictionary = {}
var speakers: Array = []
var speaker_index = 0
var save_path = "user://profile.json"
var profile: Dictionary = {}

func default_profile():
	var data={"version":4,"locale":"zh","adventure_bonus":{},"adventure_stage":1,"adventure_cleared":0,"cleared":0,"stage":1,"muted":false,"chars":[0,1,0,1],"settings":{"race_version":false,"team_count":2,"race_laps":3,"race_seconds":180,"race_map":0,"seat_roles":[-1,-1,-1,-1,-1,-1,-1,-1],"seat_characters":[-1,-1,-1,-1,-1,-1,-1,-1],"seat_teams":[-1,-1,-1,-1,-1,-1,-1,-1],"difficulty":1,"mode":0,"humans":1,"seats":4,"map":-1,"companion":true,"teams":0,"music_volume":75,"effects_volume":75},"stats":{"kills":0,"secrets":0,"pve_stages":0,"monsters":0,"bosses":0,"rounds":0,"wins":0,"losses":0,"draws":0,"bombs":0,"crates":0,"items":0,"rescues":0,"mounts":0,"deaths":0,"abandoned":0,"seconds":0.0}}
	for field in BATTLE_OPTIONS:data.settings["battle_"+field]=0
	return data

func _ready():
	scale = Vector2(3,3)
	canvas=self
	world_clip=Control.new();world_clip.position=ORIGIN;world_clip.size=VIEW_SIZE*TILE;world_clip.clip_contents=true;world_clip.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(world_clip)
	world_canvas=preload("res://scripts/render/world_canvas.gd").new();world_canvas.g=self;world_clip.add_child(world_canvas)
	game_overlay=preload("res://scripts/render/world_canvas.gd").new();game_overlay.g=self;game_overlay.overlay=true;game_overlay.z_index=3;add_child(game_overlay)
	for face in [UI_FONT,ZH_FONT]:
		face.base_font.antialiasing=TextServer.FONT_ANTIALIASING_GRAY
		face.base_font.multichannel_signed_distance_field=true
		face.base_font.allow_system_fallback=false
		face.base_font.msdf_size=96
		face.base_font.msdf_pixel_range=8
	rng.randomize()
	hd=HDArt.new(self)
	hero_palette=preload("res://scripts/render/hero_palette.gd").new(self)
	adventure=Adventure.new(self)
	map_rules=MapMechanisms.new(self)
	world_fx=WorldEffects.new(self)
	crates=Crates.new(self)
	bubble_fx=BubbleEffects.new(self)
	encyclopedia=Encyclopedia.new(self)
	weather=Weather.new(self)
	lighting=DynamicLighting.new(self)
	i18n=I18n.new()
	frontend=MenuUI.new(self)
	racing=Racing.new(self)
	load_profile()
	i18n.set_language(profile.locale)
	get_tree().auto_accept_quit = false
	get_tree().root.close_requested.connect(close_game)
	for theme in Catalog.THEMES: backgrounds.append(load("res://assets/art/maps/backgrounds/landscape-"+theme+"-hd.png"))
	music = AudioStreamPlayer.new()
	music.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	add_child(music)
	music_previous=AudioStreamPlayer.new();music_previous.playback_type=AudioServer.PLAYBACK_TYPE_STREAM;add_child(music_previous)
	for name in ["place","splash","pickup","item","win","trap","bubble-trap","bubble-pop"]: sounds[name] = load("res://assets/audio/sfx/"+name+".wav")
	for i in range(12):
		var speaker = AudioStreamPlayer.new()
		speaker.volume_db = -13
		add_child(speaker)
		speakers.append(speaker)
	build_board(0)
	update_music(0)
	apply_audio_settings()

func load_profile():
	profile = default_profile()
	if FileAccess.file_exists(save_path):
		var loaded = JSON.parse_string(FileAccess.get_file_as_string(save_path))
		if loaded is Dictionary:
			profile.cleared = clampi(int(loaded.get("cleared",0)),0,20)
			profile.stage = clampi(int(loaded.get("stage",1)),1,20)
			profile.muted = bool(loaded.get("muted",false))
			profile.locale=str(loaded.get("locale","zh"))
			if loaded.get("adventure_bonus") is Dictionary:profile.adventure_bonus=loaded.adventure_bonus
			profile.adventure_cleared=clampi(int(loaded.get("adventure_cleared",0)),0,20)
			profile.adventure_stage=clampi(int(loaded.get("adventure_stage",1)),1,20)
			if loaded.get("chars") is Array and loaded.chars.size()==4: profile.chars = loaded.chars
			if loaded.get("settings") is Dictionary:
				for field in profile.settings: profile.settings[field]=loaded.settings.get(field,profile.settings[field])
			if loaded.get("stats") is Dictionary:
				for field in profile.stats:
					var value = loaded.stats.get(field,0)
					if value is int or value is float: profile.stats[field] = maxf(0,float(value))
	for field in ["seat_roles","seat_characters","seat_teams"]:
		var values=profile.settings.get(field)
		var cleaned=[]
		for i in range(8):cleaned.append(clampi(int(values[i]),-1,8 if field=="seat_characters" else 7 if field=="seat_teams" else 1) if values is Array and values.size()==8 and (values[i] is int or values[i] is float) else -1)
		set(field,cleaned)
	for field in BATTLE_OPTIONS:
		var value=profile.settings.get("battle_"+field,0)
		battle_options[field]=clampi(int(value),0,{"collapse":5,"pace":3,"daylight":3,"fog":2,"density":3,"loot":3,"mechanisms":1}[field]) if value is int or value is float else 0
	difficulty=clampi(int(profile.settings.difficulty),0,2)
	mode=clampi(int(profile.settings.mode),0,3)
	humans=clampi(int(profile.settings.humans),1,4)
	seats=clampi(int(profile.settings.seats),2,8)
	selected_map=clampi(int(profile.settings.map),-1,43)
	companion=bool(profile.settings.companion)
	team_layout=clampi(int(profile.settings.teams),0,1)
	if mode==0:humans=1
	elif mode==2:seats=clampi(seats,2,8)
	elif mode==3:seats=4
	if mode==1 and not profile.settings.get("race_version",false):
		mode=2;team_count=seats;seat_teams.fill(-1)
	else:team_count=clampi(int(profile.settings.get("team_count",2)),2,seats)
	racing.laps=clampi(int(profile.settings.get("race_laps",3)),1,9)
	racing.time_limit=clampi(int(profile.settings.get("race_seconds",180)),60,600)
	racing.selected=clampi(int(profile.settings.get("race_map",0)),0,2)
	humans=mini(humans,seats)
	campaign_stage = clampi(int(profile.stage),1,mini(20,int(profile.cleared)+1))
	adventure_stage=clampi(int(profile.adventure_stage),1,mini(20,int(profile.adventure_cleared)+1))
	music_volume=clampi(int(profile.settings.music_volume),0,100)
	effects_volume=clampi(int(profile.settings.effects_volume),0,100)
	muted = profile.muted
	for i in range(4):
		var index = clampi(int(profile.chars[i]),0,8)
		chosen_characters[i] = index if character_unlocked(index) else 0

func save_profile():
	if preview_only:return true
	profile.muted = muted
	profile.chars = chosen_characters.duplicate()
	profile.settings={"seat_roles":seat_roles.duplicate(),"seat_characters":seat_characters.duplicate(),"seat_teams":seat_teams.duplicate(),"difficulty":difficulty,"mode":mode,"humans":humans,"seats":seats,"map":selected_map,"companion":companion,"teams":team_layout,"team_count":team_count,"race_laps":racing.laps,"race_seconds":racing.time_limit,"race_map":racing.selected,"race_version":true,"music_volume":music_volume,"effects_volume":effects_volume}
	for field in BATTLE_OPTIONS:profile.settings["battle_"+field]=battle_options[field]
	var file = FileAccess.open(save_path+".tmp",FileAccess.WRITE)
	if file == null:
		announce("存档失败，请检查目录权限。")
		return false
	file.store_string(JSON.stringify(profile,"\t"))
	file.close()
	var error = DirAccess.rename_absolute(ProjectSettings.globalize_path(save_path+".tmp"),ProjectSettings.globalize_path(save_path))
	if error != OK: announce("存档写入失败。")
	return error==OK

func character_unlocked(index): return index==8 or maxi(int(profile.get("cleared",0)),int(profile.get("adventure_cleared",0))) >= Catalog.CHARACTERS[index].unlock
func stat(field,amount=1): profile.stats[field] = profile.stats.get(field,0) + amount
func switch_music(path,immediate=false):
	if current_music_path==path:return
	if not music_cache.has(path):
		var loaded=load(path)
		if loaded==null:return
		if loaded is AudioStreamOggVorbis:loaded.loop=true
		music_cache[path]=loaded
	music_previous.stop()
	if music.stream!=null and not immediate and music.playing:
		music_previous.stream=music.stream
		music_previous.play(music.get_playback_position())
	music.stop();music.stream=music_cache[path];current_music_path=path
	music_fade=1.0 if immediate or music_previous.stream==null else 0.0
	if DisplayServer.get_name()!="headless":music.play()
	apply_audio_settings()

func play_theme(theme_index):
	var name=Catalog.THEMES[theme_index]
	current_theme=name;round_music="theme"
	var variant=(arena+round_index)%2==0
	switch_music("res://assets/audio/music/variations/"+name+"-alt.ogg" if variant else "res://assets/audio/music/themes/"+name+".ogg")

func play_game_music():
	if mode==1:
		round_music="racing"
		switch_music("res://assets/audio/music/racing/race-"+["harbor","forest","factory"][arena-Racing.FIRST_MAP]+".ogg")
	elif mode==3 and adventure.stage.get("mission","")=="boss" and not adventure.boss_dead and state in ["play","pause"]:
		current_theme=Catalog.THEMES[Catalog.MAPS[arena].theme];round_music="boss"
		switch_music("res://assets/audio/music/boss/boss-"+["swamp","ruins","reef","sky","citadel"][adventure.stage.chapter]+".ogg")
	else:play_theme(Catalog.MAPS[arena].theme)

func play_round_music(kind):
	if kind=="theme":play_game_music();return
	if round_music==kind:return
	round_music=kind
	var path="res://assets/audio/cues/round-"+kind+".wav"
	if not music_cache.has(path):
		var stream=load(path) as AudioStreamWAV
		stream.loop_mode=AudioStreamWAV.LOOP_FORWARD if kind=="urgent" else AudioStreamWAV.LOOP_DISABLED
		stream.loop_end=int(stream.get_length()*stream.mix_rate);music_cache[path]=stream
	switch_music(path,kind=="ready")

func update_music(dt):
	music_fade=minf(1.0,music_fade+dt/.45)
	if music_fade>=1.0:music_previous.stop()
	var page=pause_return if state=="pause" else state
	if page=="play":
		if countdown>0:play_round_music("ready")
		elif clock_time<=30 and mode==1:
			round_music="race-sprint";switch_music("res://assets/audio/music/racing/race-sprint.ogg")
		elif clock_time<=30:play_round_music("urgent")
		else:play_game_music()
	elif page=="finale":play_round_music("victory" if result_winner>=0 and result_winner==primary_player().team else "defeat")
	elif page=="result":
		round_music="result"
		switch_music("res://assets/audio/music/frontend/result-"+("victory" if result_winner>=0 and result_winner==primary_player().team else "defeat")+".ogg")
	elif page=="story":play_theme(Catalog.MAPS[arena].theme)
	else:
		var lobby_page=page in ["lobby","seat","maps","characters"] or frontend.history.has("lobby")
		round_music="lobby" if lobby_page else "menu"
		switch_music("res://assets/audio/music/frontend/"+round_music+".ogg")
	apply_audio_settings()

func apply_audio_settings():
	var level=-80.0 if muted or music_volume==0 else -12+linear_to_db(music_volume/100.0)
	if music:music.volume_db=level+linear_to_db(maxf(.001,music_fade))
	if music_previous:music_previous.volume_db=level+linear_to_db(maxf(.001,1.0-music_fade))
	for speaker in speakers:speaker.volume_db=-80 if muted or effects_volume==0 else -13+linear_to_db(effects_volume/100.0)

func sound(name):
	if muted or effects_volume==0: return
	var speaker = speakers[speaker_index % speakers.size()]
	speaker_index += 1
	speaker.stream = sounds[name]
	speaker.pitch_scale=rng.randf_range(.96,1.04) if name=="bubble-pop" else 1.0
	speaker.volume_db=(-7 if name=="bubble-pop" else -13)+linear_to_db(effects_volume/100.0)
	speaker.play()
func announce(message):
	notice = message
	notice_time = 3.0

func start_match():
	if mode in [1,2]:
		var teams=[]
		for i in range(lobby_count()):
			if not teams.has(slot_team(i)):teams.append(slot_team(i))
		if teams.size()<2:frontend.message="至少需要两支有玩家的队伍。";return
	scores = [0,0,0,0,0,0,0,0]
	round_index = 1
	match_over = false
	new_round()

func primary_player():
	for p in players:
		if not p.bot:return p
	return players[0]

func lobby_count():
	if mode in [1,2]:return seats
	if mode==3:return 4 if companion else humans
	return 2 if campaign_stage<5 else 4
func lobby_roles():
	var roles=[];var count=0
	for i in range(lobby_count()):
		var human=(i<humans if seat_roles[i]<0 or (mode==3 and not companion) else seat_roles[i]==1) if mode!=0 else i==0
		if human and count>=4:human=false
		roles.append(human)
		if human:count+=1
	if count==0:roles[0]=true
	return roles
func slot_team(i):
	if mode==3:return 0
	if mode in [1,2]:return posmod(seat_teams[i],team_count) if seat_teams[i]>=0 else i%team_count
	if mode==0:return 0 if i==0 or (companion and lobby_count()==4 and i==1) else 1
	return i
func slot_character(i):
	if seat_characters[i]>=0:return seat_characters[i]
	if lobby_roles()[i] and i<4:return chosen_characters[i]
	return (campaign_stage+i)%8 if mode==0 else (arena+i*3)%8
func select_slot_character(value):
	seat_characters[character_slot]=value
	if character_slot<4:chosen_characters[character_slot]=value
func character_selectable(value):return character_unlocked(value) or not lobby_roles()[character_slot]

func new_round():
	var choice = selected_map
	if mode == 0:
		choice = campaign_stage-1
		profile.stage = campaign_stage
	elif mode==1:choice=44+racing.selected
	elif mode==3:choice=20+adventure_stage-1
	elif choice < 0: choice = rng.randi_range(0,43)
	build_board(choice,true)
	play_theme(Catalog.MAPS[choice].theme)
	players.clear()
	bombs.clear()
	blasts.clear()
	drops.clear()
	death_loot.clear();loot_flights.clear()
	particles.clear()
	world_fx.events.clear()
	world_fx.links.clear()
	world_fx.footsteps.clear()
	bubble_fx.vines.clear()
	decoys.clear()
	hazards.clear()
	round_limit = match_seconds(choice)
	clock_time = round_limit
	pickup_effects.clear()
	collapsed_at.clear()
	round_time = 0
	countdown = 2.5
	play_round_music("ready")
	shake = 0
	supply_time = 12 if rule()=="sand" else 20
	mechanism_time = 6
	sudden_ring = -1
	paused = false
	quit_selection = 0
	notice_time = 0
	result_winner = -1
	round_recorded = false
	var count=lobby_count()
	var roles=lobby_roles()
	var control=0
	for i in range(count):
		var team=slot_team(i)
		var bot=not roles[i]
		var character=slot_character(i)
		if character==8:
			var pool=range(8).filter(func(index):return bot or character_unlocked(index))
			character=pool[rng.randi_range(0,pool.size()-1)]
		var c = round_spawns(count)[i]
		var p = {"id":i,"control":control if not bot else -1,"team":team,"bot":bot,"character":character,"cell":c,"visual":Vector2(c),"from":Vector2(c),"move":1.0,"cool":0.0,"duration":0.15,"momentum":0.0,"velocity":Vector2.ZERO,"gait":0.0,"bubble_pass":Vector2i(-1,-1),"bubble_pass_cells":[],"push_cool":0.0,"drift":Vector2.ZERO,"motion_dir":Vector2i.ZERO,"starting":true,"pickup_lock":Vector2i(-1,-1),"range":1,"capacity":1,"speed":0,"damage_level":0,"riding":0,"item":0,"element":0,"element_time":0.0,"hurt":0.0,"placing":0.0,"down":0.0,"pop_time":0.0,"pop_row":0,"trapped_elapsed":0.0,"recoil":Vector2.ZERO,"torch":0.0,"shield":0.0,"dash":0.0,"kick":0.0,"cloak":0.0,"magnet":0.0,"freeze":0.0,"slow":0.0,"trap":0.0,"grace":0.0,"warp":0.0,"flow":0.0,"think":0.0,"attack":0.0,"ai_dir":Vector2i.ZERO,"facing":Vector2i.DOWN,"steps":0,"dead":false,"mount":0,"mount_hp":0,"jump":0.0,"coins":0,"last_cell":c,"score":0,"round_kills":0,"round_rescues":0,"round_monsters":0,"trap_owner":-1,"growth_loot":[],"reverse_time":0.0,"jump_travel":0.0,"jump_from":Vector2(c),"jump_to":Vector2(c),"push_cell":Vector2i(-1,-1),"push_dir":Vector2i.ZERO,"push_started":0.0,"push_last":-1.0}
		var base=Catalog.CHARACTERS[character]
		p.base_capacity=base.capacity;p.base_range=base.range;p.base_speed=base.speed
		p.capacity=base.capacity;p.range=base.range;p.speed=base.speed
		players.append(p)
		if not bot:control+=1
	stat("rounds")
	state = "play"
	pause_return="play"
	if mode==3:
		adventure.setup()
		world_fx.design_board(true)
		crates.setup()
	if mode!=1:world_fx.add_shelters(mode==3)
	weather.setup()
	racing.reset_air()
	if mode==1:racing.setup()
	# Equal, reachable opening growth for every battle seat.
	if mode not in [1,3]:
		for p in players:
			var inward=Vector2i(1 if p.cell.x<W/2 else -1,1 if p.cell.y<H/2 else -1)
			for entry in [[p.cell+Vector2i(inward.x*2,0),4],[p.cell+Vector2i(0,inward.y*2),5]]:
				if passable(entry[0]) and not drops.has(entry[0]):drops[entry[0]]=entry[1]

func round_spawns(count):
	if mode==1:return SPAWNS.slice(0,count)
	var result=[]
	for i in range(count):
		var index=i if mode==3 else [0,4,1,5,2,6,3,7][i]
		if mode==0 and count==4:index=[0,1,4,5][i]
		result.append(SPAWNS[index])
	return result

func match_seconds(index):
	if mode==1:return racing.time_limit
	return [Catalog.MAPS[index].seconds,60,90,150,210,300][battle_options.collapse] if mode in [1,2] else Catalog.MAPS[index].seconds+(90 if mode==3 else 0)
func collapse_step():return [5.0,3.0,8.0,12.0][battle_options.pace] if mode in [1,2] else 5.0
func loot_chance(chance):return minf(1.0,chance*[1.0,.5,.8,1.3][battle_options.loot]) if mode in [1,2] else chance
func rule():return "plain" if mode in [1,2] and battle_options.mechanisms==1 else Catalog.MAPS[arena].rule
func inside(c): return c.x>=0 and c.y>=0 and c.x<W and c.y<H and not map_void.has(c)
func center(c): return ORIGIN+Vector2(c)*TILE+Vector2(TILE/2.0,TILE/2.0)
func bomb_at(c):
	for b in bombs:
		if b.cell==c: return b
	return null
func occupied(c,ignore=-1):
	for p in players:
		if p.id!=ignore and not p.dead and absf(p.visual.x-c.x)<.75 and absf(p.visual.y-c.y)<.75: return p
	return null
func passable(c,p=null):
	if mode==3 and p!=null and p.id>=0 and not camera_contains(Vector2(c)):return false
	if not inside(c) or grid[c.y][c.x] in [1,3]: return false
	if grid[c.y][c.x]==2 and (p==null or p.cloak<=0): return false
	return bomb_at(c)==null
func bubble_can_move(c): return passable(c) and occupied(c)==null

func build_board(index,playing=false):
	if index>=44:racing.build(index);return
	map_void.clear();camera=Vector2.ZERO
	W=27;H=19
	if playing and mode==3:
		var dimensions=[Vector2i(51,19),Vector2i(27,37),Vector2i(43,31),Vector2i(47,29)][(adventure_stage-1)%4]
		W=dimensions.x;H=dimensions.y
	SPAWNS=[Vector2i(1,1),Vector2i(1,H-2),Vector2i(1,H/2),Vector2i(W/2,1),Vector2i(W-2,H-2),Vector2i(W-2,1),Vector2i(W-2,H/2),Vector2i(W/2,H-2)]
	if playing and mode==3:SPAWNS=[Vector2i(2,3),Vector2i(4,3),Vector2i(2,5),Vector2i(4,5)]
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
			var sx=x;var sy=y
			if x>0 and x<W-1:sx=clampi(roundi(x*20.0/(W-1)),1,19)
			if y>0 and y<H-1:sy=clampi(roundi(y*14.0/(H-1)),1,13)
			var wall = x==0 or y==0 or x==W-1 or y==H-1
			if not wall:
				match (layout%10 if arena<20 else (layout+10)%20):
					0: wall = sx%2==0 and sy%2==0
					1: wall = sy in [3,9] and sx in [3,4,6,7,11,12,14,15]
					2: wall = sx%4==0 and sy not in [1,6,11]
					3: wall = (sx+sy)%5==0 and sx>2 and sx<16
					4: wall = sy%3==0 and sx not in [1,5,9,13,17]
					5: wall = sx in [4,14] and sy in [3,4,8,9]
					6: wall = (sx%4==2 and sy%3==0)
					7: wall = (sx in [5,13] and sy in [3,4,5,7,8,9]) or (sy in [3,9] and sx in [6,7,11,12])
					8: wall = abs(sx-9)+abs(sy-6) in [4,8] and sx%3!=0 and sy%3!=0
					9: wall = (sx in [3,7,11,15] and sy in [3,5,7,9])
					10: wall = sx in [5,15] and sy not in [2,7,12]
					11: wall = sy in [4,10] and sx%5 not in [0,1]
					12: wall = (sx+sy)%6==0 and sy not in [2,12]
					13: wall = abs(sx-10)+abs(sy-7)==6 and sx%4!=2
					14: wall = (sx%4==0 and sy%4==0) or (sx%4==1 and sy%4==1)
					15: wall = sy in [3,11] and sx not in [2,6,10,14,18]
					16: wall = sx in [4,8,12,16] and sy in [4,5,9,10]
					17: wall = (sx-10)*(sx-10)+(sy-7)*(sy-7) in range(23,29) and sx%3!=0
					18: wall = (sx%5==0 and sy%3!=1) or (sy%5==0 and sx%3==1)
					19: wall = (sx in [6,14] and sy in [2,3,4,10,11,12]) or (sy in [5,9] and sx in [8,9,11,12])
			var density=(.53 if arena%3 else .62)
			if mode in [1,2]:density=[density,.30,.65,.82][battle_options.density]
			var cell = 1 if wall else (2 if map_rng.randf()<density else 0)
			row.append(cell)
		grid.append(row)
	# All maps have routes through the middle and symmetrical corner exits.
	for x in range(1,W-1): grid[H/2][x]=0
	for y in range(1,H-1): grid[y][W/2]=0
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
			for pair in [[Vector2i(W/2-7,H/2-5),Vector2i(W/2+7,H/2+5)],[Vector2i(W/2+7,H/2-5),Vector2i(W/2-7,H/2+5)]]:
				for c in pair:
					clear_patch(c)
					terrain[c]={"type":"portal","exit":pair[1] if c==pair[0] else pair[0]}
		"flow":
			for x in range(2,W-2): terrain[Vector2i(x,H/2)]={"type":"flow","dir":Vector2i.RIGHT if x<W/2 else Vector2i.LEFT}
		"mushroom","spring":
			for c in [Vector2i(W/2-6,H/2-4),Vector2i(W/2+6,H/2+4),Vector2i(W/2-6,H/2+4),Vector2i(W/2+6,H/2-4),Vector2i(W/2,H/2)]:
				clear_patch(c)
				terrain[c]={"type":"spring"}
		"vine":
			for c in [Vector2i(W/2-6,H/2-5),Vector2i(W/2+6,H/2+5),Vector2i(W/2-6,H/2+5),Vector2i(W/2+6,H/2-5),Vector2i(W/2-2,H/2),Vector2i(W/2+2,H/2)]:
				grid[c.y][c.x]=2
				vine_cells.append(c)
		"ice":
			for y in range(H/2-4,H/2+5):
				for x in range(W/2-5,W/2+6):
					if grid[y][x]==0: terrain[Vector2i(x,y)]={"type":"ice"}
		"sand":
			for y in range(H/2-5,H/2+6):
				for x in range(W/2-7,W/2+8):
					if grid[y][x]==0 and (abs(x-W/2)+abs(y-H/2))%3==0: terrain[Vector2i(x,y)]={"type":"sand"}
		"gate":
			for c in [Vector2i(W/2-7,H/2),Vector2i(W/2+7,H/2),Vector2i(W/2,H/2-5),Vector2i(W/2,H/2+5)]:
				gates.append(c)
				grid[c.y][c.x]=1
			for c in [Vector2i(W/2-9,H/2-2),Vector2i(W/2+9,H/2+2)]:
				clear_patch(c)
				terrain[c]={"type":"switch"}
		"lava":
			for c in [Vector2i(W/2-7,H/2),Vector2i(W/2+7,H/2),Vector2i(W/2,H/2-4),Vector2i(W/2,H/2+4),Vector2i(W/2-3,H/2-2),Vector2i(W/2+3,H/2+2)]:
				grid[c.y][c.x]=0
				terrain[c]={"type":"lava"}
		"treasure":
			for c in [Vector2i(W/2-7,H/2-5),Vector2i(W/2+7,H/2+5),Vector2i(W/2-7,H/2+5),Vector2i(W/2+7,H/2-5),Vector2i(W/2-3,H/2),Vector2i(W/2+3,H/2),Vector2i(W/2,H/2-3),Vector2i(W/2,H/2+3)]:
				grid[c.y][c.x]=2
				gold_boxes[c]=true
		"laser":
			for y in [H/2-5,H/2,H/2+5]:
				for x in range(1,W-1): grid[y][x]=0
		"train":
			for x in range(1,W-1): terrain[Vector2i(x,H/2)]={"type":"rail"}
	for c in [Vector2i(W/2,H/2),Vector2i(W/2-2,H/2),Vector2i(W/2+2,H/2)]:
		if grid[c.y][c.x]==0: terrain[c]=terrain.get(c,{"type":"supply"})

	if playing and mode==3:
		for y in range(H):
			for x in range(W):
				var c=Vector2i(x,y)
				var missing=((adventure_stage-1)%4==2 and x>W/2+4 and y<H/2-3) or ((adventure_stage-1)%4==3 and (y<3 or y>H-4) and x>8 and x<W-9)
				if missing:map_void[c]=true;grid[y][x]=1;terrain.erase(c);gold_boxes.erase(c);vine_cells.erase(c)
	if map_rules:map_rules.setup()
	for c in SPAWNS:
		clear_patch(c)
		for d in [Vector2i.ZERO]+DIRS:terrain.erase(c+d)
	if world_fx:world_fx.design_board(false)
	if crates:crates.setup()
	if not playing and world_fx:world_fx.add_shelters(false)
	if weather:weather.setup()

func clear_patch(c):
	for d in [Vector2i.ZERO]+DIRS:
		var next = c+d
		if inside(next) and next.x>0 and next.y>0 and next.x<W-1 and next.y<H-1: grid[next.y][next.x]=0

func _unhandled_key_input(event):
	if not event.pressed or event.echo: return
	var key = event.keycode
	if state=="languages":
		if key in [KEY_ESCAPE,KEY_F3]:state=language_return
		elif key in [KEY_UP,KEY_DOWN]:language_selection=posmod(language_selection+(-1 if key==KEY_UP else 1),5)
		elif key in [KEY_ENTER,KEY_SPACE]:apply_language(language_selection);state=language_return
		return
	if key==KEY_F3:
		language_return=state;state="languages";language_selection=I18n.LOCALES.find(i18n.locale);return
	if state=="codex":encyclopedia.input_key(key);return
	if key==KEY_F2:encyclopedia.open();return
	if key==KEY_M:
		muted=not muted
		apply_audio_settings()
		save_profile()
		return
	if frontend.active():frontend.input_key(key);return
	if state in ["stats","help","maps","characters"]:
		if key==KEY_ESCAPE:
			frontend.back()
			refresh_preview()
			return
		if state=="maps":
			if key==KEY_LEFT: selection=posmod(selection-1,44)
			elif key==KEY_RIGHT: selection=(selection+1)%44
			elif key==KEY_UP: selection=posmod(selection-4,44)
			elif key==KEY_DOWN: selection=(selection+4)%44
			elif key==KEY_ENTER:
				selected_map=mini(selection,43)
				frontend.back()
				refresh_preview()
				save_profile()
			elif key==KEY_R:
				selected_map=-1
				frontend.back()
				refresh_preview()
				save_profile()
		elif state=="characters":
			if key==KEY_TAB:
				character_slot=(character_slot+1)%lobby_count()
				selection=slot_character(character_slot)
			elif key==KEY_LEFT: selection=posmod(selection-1,9)
			elif key==KEY_RIGHT: selection=(selection+1)%9
			elif key==KEY_ENTER and character_selectable(selection):
				select_slot_character(selection)
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
		if key==BOMB_KEYS[players[i].get("control",i)] or (players[i].get("control",i)==1 and key==KEY_KP_ENTER): place_bomb(i)
		if key==PICKUP_KEYS[players[i].get("control",i)]:swap_item(i)
		if key==ITEM_KEYS[players[i].get("control",i)] or (players[i].get("control",i)==1 and key==KEY_KP_DIVIDE):
			if event.shift_pressed:swap_item(i)
			else:use_item(i)

func _unhandled_input(event):
	if event is InputEventMouseMotion and frontend.active():frontend.hover(event.position/3);return
	if not event is InputEventMouseButton or not event.pressed or event.button_index!=MOUSE_BUTTON_LEFT: return
	var pos=event.position/3
	if state=="languages":
		for index in range(5):
			if Rect2(190,96+index*40,260,32).has_point(pos):apply_language(index);state=language_return;return
		if Rect2(540,10,80,22).has_point(pos):state=language_return
		return
	if state=="codex":encyclopedia.input_mouse(pos);return
	if frontend.active():frontend.input_mouse(pos);return
	if state=="story":adventure.advance_dialogue()
	elif state=="play" and Rect2(549,315,78,25).has_point(pos):
		pause_return="play";state="pause"; paused=true; quit_selection=0
	elif state=="pause":
		for i in range(3):
			if Rect2(195,153+i*32,250,28).has_point(pos): pause_action(i)
	elif state=="result":
		if Rect2(195,278,250,28).has_point(pos):
			var key=InputEventKey.new();key.keycode=KEY_ENTER;key.pressed=true;_unhandled_key_input(key)
		elif Rect2(195,313,250,24).has_point(pos): return_to_menu()
	elif state in ["stats","help","maps","characters"] and Rect2(540,10,80,22).has_point(pos):
		frontend.back();refresh_preview()
	elif state=="maps":
		for slot in range(20):
			if Rect2(12+(slot%4)*156,45+int(slot/4)*56,147,52).has_point(pos):
				if int(selection/20)*20+slot>=44:continue
				selection=int(selection/20)*20+slot;selected_map=mini(selection,43);frontend.back();refresh_preview();save_profile();break
		if pos.y>=328 and pos.y<=358 and pos.x<120:selection=posmod(int(selection/20)-1,int(ceil(44/20.0)))*20
		elif pos.y>=328 and pos.y<=358 and pos.x>520:selection=posmod(int(selection/20)+1,int(ceil(44/20.0)))*20
	elif state=="characters":
		for slot in range(lobby_count()):
			if Rect2(32+slot*75,68,65,18).has_point(pos):character_slot=slot;selection=slot_character(slot);return
		for i in range(8):
			if Rect2(32+i*75,92,65,86).has_point(pos): selection=i
		if Rect2(32,182,150,20).has_point(pos):selection=8
		if Rect2(240,283,160,28).has_point(pos) and character_selectable(selection):
			select_slot_character(selection);save_profile();sound("pickup")

func next_character(value,direction):
	for i in range(9):
		value=posmod(value+direction,9)
		if character_unlocked(value): return value
	return 0
func refresh_preview():
	build_board((44+racing.selected) if mode==1 else (20+adventure_stage-1) if mode==3 else (campaign_stage-1 if mode==0 else maxi(0,selected_map)))
	update_music(0)
func pause_action(choice):
	if choice==0: state=pause_return;paused=false
	elif choice==1: return_to_menu()
	else: close_game()
func return_to_menu():
	if not round_recorded:
		stat("abandoned")
		round_recorded=true
	save_profile()
	state="lobby"
	frontend.row=0
	paused=false
	players.clear()
	refresh_preview()

func _process(dt):
	update_music(dt)
	if state=="pause":
		if lighting:lighting.update(0)
		queue_redraw()
		return
	elapsed+=dt
	if mode==3 and state in ["play","finale","result"]:adventure.update_animation(dt)
	if state=="finale":
		update_loot_flights(dt);scatter_growth()
		finale_time+=dt
		if finale_time>=3.8:state="result"
	if state in ["finale","result"]:
		for p in players:
			for timer in ["hurt","placing","down","pop_time"]:p[timer]=maxf(0,p[timer]-dt)
	if world_fx:world_fx.update(dt)
	if lighting:lighting.update(dt)
	shake=maxf(0,shake-dt*18)
	if state=="play":
		if countdown>0:
			countdown-=dt
			if countdown<=0:play_round_music("urgent" if clock_time<=30 else "theme")
		else: update_game(minf(dt,.08))
	for p in particles:
		p.life-=dt
		p.pos+=p.vel*dt
		p.vel.y+=50*dt
	particles=particles.filter(func(p):return p.life>0)
	queue_redraw()

func update_game(dt):
	update_camera(dt)
	round_time+=dt
	clock_time-=dt
	if clock_time<=30:play_round_music("urgent")
	weather.update(dt)
	for effect in pickup_effects:effect.life-=dt
	pickup_effects=pickup_effects.filter(func(effect):return effect.life>0)
	stat("seconds",dt)
	notice_time=maxf(0,notice_time-dt)
	supply_time-=dt
	if supply_time<=0:
		supply_time+=12 if rule()=="sand" else 20
		drop_supply()
	racing.airborne(dt)
	crates.update(dt)
	bubble_fx.update(dt)
	map_rules.update(dt)
	update_mechanisms(dt)
	var danger=danger_cells()
	update_loot_flights(dt)
	scatter_growth()
	for p in players:
		for timer in ["hurt","placing","down","pop_time","torch","shield","dash","kick","cloak","magnet","freeze","slow","grace","warp","flow","think","jump","attack","push_cool","reverse_time"]: p[timer]=maxf(0,p[timer]-dt)
		p.cool=maxf(0,p.cool-dt)
		if p.dead or (mode==1 and p.get("race_finished",false)):p.velocity=Vector2.ZERO;p.move=1;continue
		if round_time-p.push_last>.10:p.push_cell=Vector2i(-1,-1)
		if p.jump_travel>0 and p.trap<=0 and p.freeze<=0:
			p.jump_travel=maxf(0,p.jump_travel-dt)
			var progress=1-p.jump_travel/.42
			p.visual=p.jump_from.lerp(p.jump_to,smoothstep(0,1,progress));p.cell=Vector2i(p.visual.round());p.velocity=Vector2.ZERO
			if p.jump_travel<=0:p.visual=p.jump_to;p.cell=Vector2i(p.jump_to);world_fx.footstep(center(p.cell),p.facing,true)
			continue
		if p.cloak<=0 and grid[p.cell.y][p.cell.x]==2: eject_from_box(p)
		if p.trap>0:
			p.velocity=Vector2.ZERO;p.move=1
			p.trap-=dt;p.trapped_elapsed+=dt
			if p.bot and p.item in [1,9,18]: use_item(p.id)
			if p.trap<=0 and p.grace<=0: kill_player(p)
			continue
		if p.freeze>0:
			p.velocity=Vector2.ZERO;p.move=1
			for f in blasts:
				if not f.get("pulse_only",false) and f.cell==p.cell and f.time>0:bubble_fx.affect_player(p,f)
			continue
		var dir=Vector2.ZERO
		if p.bot:
			if p.think<=0:
				p.think=[.12,.08,.05][difficulty] if mode==1 and p.car else [.28,.14,.08][difficulty]
				p.ai_dir=racing.bot_direction(p,danger) if mode==1 else bot_direction(p,danger)
				if mode!=1:bot_actions(p,danger)
				else:racing.bot_actions(p,danger)
			dir=Vector2(p.ai_dir)
			# Bot routes still use tile centres, but position and collision are continuous.
			if dir.x!=0:dir.y=clampf(roundf(p.visual.y)-p.visual.y,-.8,.8)*4
			elif dir.y!=0:dir.x=clampf(roundf(p.visual.x)-p.visual.x,-.8,.8)*4
		else:
			for d in range(4):
				if Input.is_physical_key_pressed(MOVE_KEYS[p.get("control",p.id)][d]):dir+=Vector2(DIRS[d])
		if p.reverse_time>0:dir=-dir
		if terrain.has(p.cell):
			var tile=terrain[p.cell]
			if tile.type=="ice" and dir==Vector2.ZERO and p.facing!=Vector2i.ZERO:dir=p.facing
		if rule()=="wind" and fmod(round_time,9)>7.5:
			dir=DIRS[int(round_time/9)%4]
		move_player(p,dir,dt)
		apply_terrain(p)
		if p.pickup_lock!=p.cell:p.pickup_lock=Vector2i(-1,-1)
		if drops.has(p.cell): pickup(p,p.cell)
		if p.magnet>0:
			for c in drops.keys():
				if manhattan(c,p.cell)<=2: pickup(p,c)
		for f in blasts:
			if not f.get("pulse_only",false) and f.cell==p.cell and f.time>0: bubble_fx.affect_player(p,f)
	for b in bombs.duplicate():
		if not bombs.has(b): continue
		b.timer-=dt
		if b.slide!=Vector2i.ZERO:
			b.step-=dt
			if b.step<=0:
				var next=b.cell+b.slide
				if bubble_can_move(next) and can_cross(b.cell,next):b.cell=next;b.step=.11
				else:b.slide=Vector2i.ZERO
		for f in blasts:
			if not f.get("pulse_only",false) and f.cell==b.cell and f.time>0:b.timer=0;break
		if b.timer<=0:explode(b)
	for f in blasts:f.time-=dt
	blasts=blasts.filter(func(f):return f.time>0)
	for d in decoys:d.time-=dt
	decoys=decoys.filter(func(d):return d.time>0)
	if mode==1:racing.update(dt);return
	if clock_time<=0:
		var ring=mini(H/2-1,int(-clock_time/collapse_step()))
		if ring>sudden_ring:sudden_ring=ring;flood_ring(ring+1)
	if mode==3:
		adventure.update(dt)
		return
	var alive: Dictionary={}
	for p in players:
		if not p.dead:alive[p.team]=true
	if alive.size()<=1 or clock_time<=-float(H/2)*collapse_step():
		finish_round(alive.keys()[0] if alive.size()==1 else -1)
	elif rule()=="treasure":
		var team_coins={}
		for p in players:team_coins[p.team]=team_coins.get(p.team,0)+p.coins
		for team in team_coins:
			if team_coins[team]>=5:finish_round(team);break

func move_duration(p):
	var speed=.27-.012*p.speed
	if p.dash>0:speed*=.66
	if p.mount==1:speed*=.75
	elif p.mount==2:speed*=1.1
	elif p.mount==3:speed*=.86
	if p.mount>0:speed*=1-.035*p.riding
	if p.freeze>0 or p.slow>0:speed*=1.9
	if rule()=="gravity":speed*=.8
	if terrain.has(p.cell) and terrain[p.cell].type=="sand":speed*=1.65
	return maxf(.12,speed)

func move_player(p,input_direction,dt):
	var dir=Vector2(input_direction).limit_length(1)
	if dir!=Vector2.ZERO:
		p.facing=Vector2i(signf(dir.x),0) if absf(dir.x)>absf(dir.y) else Vector2i(0,signf(dir.y))
		p.motion_dir=p.facing
	p.duration=move_duration(p)
	var speed=1.0/p.duration
	var ice=terrain.has(p.cell) and terrain[p.cell].type=="ice"
	var target_velocity=dir*speed
	if terrain.has(p.cell) and terrain[p.cell].type=="flow":target_velocity+=Vector2(terrain[p.cell].dir)*speed*.38
	if mode==1 and p.get("car",false):
		p.velocity=racing.vehicle_velocity(p,dir,dt)
	else:p.velocity=p.velocity.move_toward(target_velocity,dt*(25.0 if ice else 48.0 if dir!=Vector2.ZERO else 65.0))
	var before=p.visual
	var displacement=p.velocity*dt
	var segments=maxi(1,int(ceil(displacement.length()/.10)))
	for step in range(segments):
		for axis in range(2):
			if absf(displacement[axis])<.00001:continue
			var axis_direction=Vector2i(signf(displacement.x),0) if axis==0 else Vector2i(0,signf(displacement.y))
			var candidate=p.visual
			candidate[axis]+=displacement[axis]/segments
			var current_position=p.visual
			var blocked=movement_blocked(p,candidate,axis_direction)
			# A jump owns the continuous trajectory until its landing.
			if p.jump_travel>0 or p.visual!=current_position:return
			if not blocked:p.visual=candidate
			else:p.velocity[axis]=0
	p.last_cell=p.cell
	p.cell=Vector2i(roundf(p.visual.x),roundf(p.visual.y))
	var travelled=before.distance_to(p.visual)
	if travelled>.001:
		var movement=p.visual-before
		p.facing=Vector2i(signf(movement.x),0) if absf(movement.x)>absf(movement.y) else Vector2i(0,signf(movement.y))
		p.motion_dir=p.facing
	var previous_step=int(p.gait*2)
	p.gait+=travelled
	p.steps=int(p.gait)
	p.move=0.0 if travelled>.0001 else 1.0
	p.momentum=clampf(p.velocity.length()/speed,0,1)
	if int(p.gait*2)>previous_step:world_fx.footstep(ORIGIN+p.visual*TILE+Vector2(8,13),p.facing,p.mount>0)
	p.bubble_pass_cells=p.bubble_pass_cells.filter(func(c):return bomb_at(c)!=null and absf(p.visual.x-c.x)<=.76 and absf(p.visual.y-c.y)<=.76)
	if p.bubble_pass!=Vector2i(-1,-1) and (absf(p.visual.x-p.bubble_pass.x)>.76 or absf(p.visual.y-p.bubble_pass.y)>.76):p.bubble_pass=Vector2i(-1,-1)

func movement_blocked(p,position,dir):
	if mode==3:
		var local=position-camera
		if local.x<.8 or local.x>VIEW_SIZE.x-1.3 or local.y<1.6 or local.y>VIEW_SIZE.y-1.8:return true
	# A small foot collider lets characters move within tiles and along walls.
	var radius=.25
	var low=Vector2i(floor(position.x+.5-radius),floor(position.y+.5-radius))
	var high=Vector2i(floor(position.x+.5+radius),floor(position.y+.5+radius))
	for y in range(low.y,high.y+1):
		for x in range(low.x,high.x+1):
			var c=Vector2i(x,y)
			if not inside(c) or grid[y][x] in [1,3]:return true
			if not can_cross(p.cell,c):return true
			if grid[y][x]==2 and p.cloak<=0:
				if p.push_cool<=0 and dir!=Vector2i.ZERO and crates.try_push(c,dir,p):p.push_cool=.18
				if grid[y][x]==2:
					if p.mount==3 and p.jump<=0 and dir!=Vector2i.ZERO:
						var landing=c+dir
						if passable(landing,p) and (mode!=3 or camera_contains(Vector2(landing))):
							p.jump_from=p.visual;p.jump_to=Vector2(landing);p.jump_travel=.42;p.jump=.8;p.velocity=Vector2.ZERO;p.facing=dir
					return true
			var bubble=bomb_at(c)
			if bubble!=null and not p.bubble_pass_cells.has(c):
				if p.kick>0 and dir!=Vector2i.ZERO:kick_bomb(bubble,dir)
				if bomb_at(c)!=null:return true
	for other in players:
		if other.id==p.id or other.dead or position.distance_to(other.visual)>=.52:continue
		if other.trap>0:
			if other.team==p.team:
				release_player(other,p.id);burst(center(other.cell),Color("82f0c1"),14)
				announce("队友获救！")
			else:kill_player(other,p.id)
		# Actors may overlap; contact only resolves rescue or elimination.
	return false

func apply_terrain(p):
	if not terrain.has(p.cell) or p.cell==p.last_cell:return
	var tile=terrain[p.cell]
	if tile.type=="portal" and p.warp<=0:
		var dest=tile.exit
		if passable(dest,p):
			burst(center(p.cell),Color("ce9dff"),12)
			teleport(p,dest);p.warp=1.0
			sound("item")
	elif tile.type=="spring" and p.jump<=0:
		var dest=p.cell+p.facing*2
		if passable(dest,p):
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
	if mode==3 and state=="play":
		var local=Vector2(dest)-camera
		if local.x<.8 or local.x>VIEW_SIZE.x-1.3 or local.y<1.6 or local.y>VIEW_SIZE.y-1.8:return false
	p.cell=dest;p.visual=Vector2(dest);p.from=p.visual;p.move=1;p.last_cell=dest;p.momentum=0;p.drift=Vector2.ZERO;p.motion_dir=Vector2i.ZERO;p.velocity=Vector2.ZERO
	burst(center(dest),Color("bdeeff"),10)
func eject_from_box(p):
	for d in DIRS:
		if passable(p.cell+d):teleport(p,p.cell+d);return
	grid[p.cell.y][p.cell.x]=0

func damage_player(p,owner):
	if p.dead or p.grace>0 or p.trap>0 or (mode==1 and p.get("race_finished",false)):return
	p.hurt=.48
	p.recoil=Vector2(p.facing)*-1
	if owner>=0 and owner<players.size() and players[owner].cell!=p.cell:p.recoil=Vector2(p.cell-players[owner].cell).normalized()
	world_fx.impact(center(p.cell),0,26)
	if p.shield>0:
		p.shield=0;p.grace=1
		burst(center(p.cell),Color("e8ffe4"),12)
	elif p.mount>0:
		p.mount_hp-=1;p.grace=.9
		burst(center(p.cell),Color(Catalog.MOUNTS[p.mount].color),12)
		if p.mount_hp<=0:p.mount=0;announce("坐骑替你挡住了水柱！")
	else:
		p.trap=8;p.trapped_elapsed=0;p.grace=.6;p.trap_owner=owner
		sound("bubble-trap")
func release_player(p,rescuer=-1):
	if p.trap>0 and rescuer>=0 and rescuer<players.size() and rescuer!=p.id and players[rescuer].team==p.team:
		players[rescuer].round_rescues+=1
		if players[rescuer].get("control",rescuer)==0:stat("rescues")
	p.trap_owner=-1
	p.trap=0;p.grace=1;p.pop_time=.55;p.pop_row=1
	sound("bubble-pop")

func kill_player(p,killer=-1):
	if p.dead:return
	if killer==-1:killer=p.get("trap_owner",-1)
	if killer>=0 and killer<players.size() and killer!=p.id and players[killer].team!=p.team:
		players[killer].round_kills+=1
		if players[killer].get("control",killer)==0:stat("kills")
	p.trap_owner=-1
	if not p.growth_loot.is_empty():death_loot.append({"origin":p.visual,"items":p.growth_loot.duplicate()});p.growth_loot.clear()
	p.capacity=p.get("base_capacity",1);p.range=p.get("base_range",1);p.speed=p.get("base_speed",0);p.reverse_time=0;p.jump_travel=0;p.riding=0;p.damage_level=0
	scatter_growth()
	p.dead=true;p.trap=0;p.down=1.05;p.pop_time=.55;p.pop_row=0
	if mode==1:p.respawn=10.0;p.car=false;p.mount=0
	burst(center(p.cell),color_for(p),18)
	if p.get("control",p.id)==0:stat("deaths")
	sound("bubble-pop")

func scatter_growth():
	if death_loot.is_empty():return
	var danger=danger_cells();var available=[];var reserved={}
	for flight in loot_flights:reserved[flight.cell]=true
	for y in range(H):
		for x in range(W):
			var c=Vector2i(x,y)
			if not map_void.has(c) and grid[y][x]==0 and not reserved.has(c) and bomb_at(c)==null and not drops.has(c) and danger.get(c,99)>1.5:available.append(c)
	for loot in death_loot:
		while not loot.items.is_empty() and not available.is_empty():
			var c=available.pop_at(rng.randi_range(0,available.size()-1))
			loot_flights.append({"origin":Vector2(loot.origin),"cell":c,"kind":loot.items.pop_front(),"age":0.0,"duration":clampf(.65+Vector2(loot.origin).distance_to(Vector2(c))*.025,.7,1.35)})
	death_loot=death_loot.filter(func(loot):return not loot.items.is_empty())

func update_loot_flights(dt):
	for flight in loot_flights:
		flight.age+=dt
		if flight.age<flight.duration:continue
		var c=flight.cell
		if inside(c) and not map_void.has(c) and grid[c.y][c.x]==0 and not drops.has(c) and bomb_at(c)==null and not blasts.any(func(f):return f.cell==c):
			drops[c]=flight.kind;burst(center(c),Color("a7e6ff"),3)
		else:death_loot.append({"origin":Vector2(c),"items":[flight.kind]})
	loot_flights=loot_flights.filter(func(flight):return flight.age<flight.duration)

func draw_loot_flights():
	for flight in loot_flights:
		var t=clampf(flight.age/flight.duration,0,1)
		var origin=ORIGIN+(flight.origin+Vector2.ONE*.5)*TILE
		var at=origin.lerp(center(flight.cell),t)-Vector2(0,sin(t*PI)*minf(48,18+origin.distance_to(center(flight.cell))*.1))
		canvas.draw_arc(at,7,elapsed*5,elapsed*5+PI,12,Color(.65,.9,1,.45),1)
		item_icon(at-Vector2(6,6),flight.kind,12)

func random_drop():
	if mode==1:
		var race_roll=rng.randf()
		if race_roll<.35:return 31
		if race_roll<.90:return [4,5,7][rng.randi_range(0,2)]
	var rare=rng.randf()
	if rare<.01:return 29
	if rare<.02:return 30
	if mode==3 and rng.randf()<.12:return 28
	if (weather.nightness>.2 or weather.fog_strength>.2) and rng.randf()<.16:return rng.randi_range(26,27)
	var roll=rng.randf()
	if roll<.50:return [4,5,7][rng.randi_range(0,2)]
	if roll<.55:return 15
	if roll<.58:return 16
	if roll<.74:return rng.randi_range(20,25)
	return [1,2,3,6,9,10,11,12,13,14,17,18][rng.randi_range(0,11)]

func growth_full(p,kind):
	return (kind==4 and p.capacity>=6) or (kind==5 and p.range>=8) or (kind==7 and p.speed>=5) or (kind==16 and p.riding>=3) or (kind==28 and p.damage_level>=3)

func bubble_fuse(p):return 3.4 if rule()=="gravity" else 2.3

func mount_durability(p):return (2 if p.mount==2 else 1)+mini(2,p.riding)

func pickup(p,c,manual=false):
	if not drops.has(c):return
	var kind=int(drops[c])
	if kind==8:drops.erase(c);return
	if kind==31 and (mode!=1 or p.get("car",false)):return
	if growth_full(p,kind):return
	var category=Catalog.ITEMS[kind].kind
	if category=="active" and not manual and ((p.bot and p.pickup_lock==c) or (p.item!=0 and not p.bot)):return
	if category=="active" and not manual and c!=p.cell and p.item!=0:return
	var previous=p.item if category=="active" else 0
	drops.erase(c)
	if kind in [4,5,7,16,28,29,30]:p.growth_loot.append(kind)
	if previous>0:
		drops[c]=previous
		p.pickup_lock=c
	if category=="active" and not p.bot:announce("拾取"+Catalog.ITEMS[kind].name+("，原道具留在地上。" if previous>0 else ""))
	pickup_effects.append({"pos":center(c),"kind":kind,"life":.65})
	match kind:
		31:p.car=true;p.mount=0;p.velocity=Vector2.ZERO;p.car_heading=Vector2(p.facing)
		4:p.capacity=mini(6,p.capacity+1)
		5:p.range=mini(8,p.range+1)
		7:p.speed=mini(5,p.speed+1)
		29:p.range=maxi(W,H);announce("大力丸：水柱纵横拉满！")
		30:
			if rng.randf()<.5:p.reverse_time=20;announce("邪魔面具：中毒，操作反向二十秒！")
			else:p.capacity=6;p.range=maxi(W,H);p.speed=5;announce("邪魔面具：三维全部拉满！")
		28:
			p.damage_level=mini(3,p.damage_level+1)
			announce(loc("泡泡伤害提升至 %d！") % (1+p.damage_level))
		15:
			p.mount=rng.randi_range(1,3)
			p.mount_hp=mount_durability(p)
			if p.get("control",p.id)==0:stat("mounts")
			announce(Catalog.MOUNTS[p.mount].name+"陪你出战！")
		16:
			p.riding=mini(3,p.riding+1)
			if p.mount>0:p.mount_hp=mini(mount_durability(p),p.mount_hp+1)
		19:p.coins+=1
		_:p.item=kind
	if p.get("control",p.id)==0:stat("items")
	burst(center(c),Color(Catalog.ITEMS[kind].color),9)
	world_fx.impact(center(c),5,25)
	sound("pickup")

func nearby_active(p):
	var chosen=null;var closest=1.15
	for c in drops:
		if grid[c.y][c.x]!=0 or Catalog.ITEMS[int(drops[c])].kind!="active":continue
		var distance=p.visual.distance_to(Vector2(c))
		if distance>=closest:continue
		if c.x!=p.cell.x and c.y!=p.cell.y:
			if grid[p.cell.y][c.x] in [1,2,3] or grid[c.y][p.cell.x] in [1,2,3]:continue
		var visible=true
		for step in range(1,5):
			var along=p.visual.lerp(Vector2(c),step/4.0)
			var tile=Vector2i(roundf(along.x),roundf(along.y))
			if not inside(tile) or grid[tile.y][tile.x] in [1,2,3]:visible=false;break
		if visible:closest=distance;chosen=c
	return chosen
func swap_item(i):
	if i>=players.size():return
	var p=players[i]
	if p.dead or p.trap>0 or p.freeze>0:return
	var c=nearby_active(p)
	if c!=null:pickup(p,c,true)

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
				if enemy.dead or enemy.boss:continue
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
			if passable(next,p):dest=next
		if dest==p.cell:return
		teleport(p,dest)
	elif kind==18:
		var rescued=false
		for other in players:
			if not other.dead and other.team==p.team and other.trap>0 and manhattan(p.cell,other.cell)<=3:
				release_player(other,p.id);rescued=true
		if not rescued:return
	elif kind==3:
		for b in bombs.duplicate():
			if b.owner==i and bombs.has(b):explode(b)
	elif kind in [1,9]:
		if p.trap>0:release_player(p)
		if kind==1:p.shield=8
	elif kind==2:p.dash=6
	elif kind==6:p.kick=8
	elif kind==10:p.cloak=6
	elif kind==12:
		bubble_fx.infuse(p,1,8)
		if mode==3:adventure.freeze_nearby(p)
		for other in players:
			if not other.dead and not concealed(other) and other.team!=p.team and other.trap<=0 and other.grace<=0 and bubble_fx.clear_path(p.cell,other.cell,3):
				other.freeze=maxf(other.freeze,2);burst(center(other.cell),Color("bfefff"),10)
	elif kind==13:decoys.append({"cell":p.cell,"team":p.team,"character":p.character,"time":10.0})
	elif kind==14:p.magnet=5
	elif kind==26:weather.flare_time=8;announce("照明弹升空：全图照亮八秒！")
	elif kind==27:p.torch=20;announce("火把点燃：自身视野扩大二十秒！")
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
	var fuse=bubble_fuse(p)
	bombs.append({"cell":c,"owner":i,"range":p.range,"timer":fuse,"fuse":fuse,"slide":Vector2i.ZERO,"step":0.0,"element":p.element,"damage":1+p.damage_level})
	for player in players:
		if absf(player.visual.x-c.x)<.76 and absf(player.visual.y-c.y)<.76:
			player.bubble_pass=c
			if not player.bubble_pass_cells.has(c):player.bubble_pass_cells.append(c)
	if p.get("control",p.id)==0:stat("bombs")
	p.attack=.85;p.placing=.32
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
			if not can_cross(c,c+dir):break
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
func register_blast(f):
	blasts.append(f)
	if not f.get("pulse_only",false):return
	for p in players:
		if not p.dead and p.cell==f.cell:bubble_fx.affect_player(p,f)
	if mode==3 and f.owner>=0:
		for e in adventure.enemies:
			if not e.dead and Vector2i(e.visual.round())==f.cell:bubble_fx.affect_enemy(e,f)

func explode(b):
	if not bombs.has(b):return
	var cells=blast_cells(b)
	map_rules.on_explode(b,cells)
	bombs.erase(b)
	var chained: Array=[]
	var hit_boxes:Dictionary={}
	# Remove exposed old pickups before creating new crate rewards.
	for c in cells:
		if grid[c.y][c.x]==0:drops.erase(c)
	for c in cells:
		if grid[c.y][c.x]==2:crates.damage(c,b.owner,hit_boxes)
		var next=bomb_at(c)
		if next!=null:chained.append(next)
		var lifetime=(.95 if b.get("element",0)==2 else .5)
		var links=[]
		for direction in DIRS:
			if cells.has(c+direction):links.append(direction)
		register_blast({"cell":c,"time":lifetime,"duration":lifetime,"origin":b.cell,"links":links,"owner":b.owner,"element":b.get("element",0),"damage":b.get("damage",1),"pulse_only":true})
		burst(center(c),Color("c8f8ff"),3)
	bubble_fx.on_explode(b,cells)
	shake=1.6
	sound("bubble-pop")
	sound("splash")
	for next in chained:
		if bombs.has(next):world_fx.chain(center(b.cell),center(next.cell));explode(next)

func kick_bomb(b,dir):
	var dest=b.cell+dir
	if not bubble_can_move(dest) or not can_cross(b.cell,dest):return
	b.cell=dest;b.slide=dir;b.step=.11
	burst(center(dest),Color("baffaf"),5)
	sound("place")
func drop_supply():
	var hub=adventure.checkpoint if mode==3 else Vector2i(W/2,H/2)
	var locations=[hub,hub+Vector2i(-2,0),hub+Vector2i(2,0),hub+Vector2i(0,-2),hub+Vector2i(0,2)]
	locations.shuffle()
	var count=0
	for c in locations:
		if not passable(c) or occupied(c)!=null or drops.has(c):continue
		var burning=false
		for f in blasts:
			if f.cell==c:burning=true
		if burning:continue
		drops[c]=random_drop()
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
				var y=[H/2-5,H/2,H/2+5][int(round_time/7)%3]
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
			if hazard.type=="whirlpool":
				map_rules.pull_vortex();hazards.erase(hazard);sound("splash");continue
			var hit_boxes:Dictionary={}
			for c in hazard.cells:
				if inside(c) and grid[c.y][c.x] not in [1,3]:
					if grid[c.y][c.x]==2:crates.damage(c,-1,hit_boxes)
					var hit={"cell":c,"time":.6,"duration":.6,"owner":-1,"hazard":hazard.type}
					if hazard.has("skill"):hit.skill=hazard.skill;hit.caster=hazard.caster
					blasts.append(hit)
					burst(center(c),Color("ffe68a"),3)
			hazards.erase(hazard)
			shake=2;sound("splash")
	if rule()=="lava" and fmod(round_time,10)>7.5:
		for p in players:
			if terrain.has(p.cell) and terrain[p.cell].type=="lava":damage_player(p,-1)
	if rule()=="magnet":
		for b in bombs:
			if b.slide==Vector2i.ZERO and b.timer>1.2:
				var dir=Vector2i(signi(W/2-b.cell.x),0) if b.cell.x!=W/2 else Vector2i(0,signi(H/2-b.cell.y))
				if dir!=Vector2i.ZERO and bubble_can_move(b.cell+dir):b.slide=dir;b.step=.3
	if rule()=="train":
		var phase=fmod(round_time,12)
		if phase>=8:
			var head=int((phase-8)*8)-2
			for p in players:
				if p.dead or p.cell.y!=H/2 or p.cell.x>head or p.cell.x<head-2:continue
				var pushed=false
				for dir in [Vector2i.UP,Vector2i.DOWN]:
					if passable(p.cell+dir,p):teleport(p,p.cell+dir);pushed=true;break
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
				if p.cell==c:kill_player(p,-2)
	announce("岛屿正在坍塌！向中央移动。")
	shake=1.5
	sound("splash")

func finish_round(winner):
	if state!="play":return
	state="finale"
	finale_time=0.0
	for p in players:
		p.velocity=Vector2.ZERO;p.move=1.0;p.facing=Vector2i.DOWN
		p.hurt=0;p.placing=0;p.jump_travel=0;p.jump=0
	if mode==1:
		for p in players:
			p.visual=racing.checkpoints[0].pos+Vector2(-3+(p.id%4)*2,-.5+int(p.id/4));p.cell=Vector2i(p.visual.round())
	result_winner=winner
	if winner>=0:scores[winner]+=1
	match_over=mode in [0,1,3] or (winner>=0 and scores[winner]>=2)
	if winner<0:result_text="这一局平手"
	elif mode==3:result_text=("群岛重获新生！" if adventure_stage==20 else "冒险任务完成！") if winner==0 else "冒险暂时受挫"
	elif mode==0:result_text=("群岛通关！" if campaign_stage==20 else "闯关成功！") if winner==0 else "这次没闯过去"
	elif mode in [1,2]:result_text=loc("%s夺冠！" if match_over else "%s获胜！") % team_name(winner)
	else:
		var champion=players.filter(func(p):return p.team==winner)[0]
		result_text=Catalog.CHARACTERS[champion.character].name+("夺冠！" if match_over else "获胜！")
	if winner<0:stat("draws")
	elif winner==primary_player().team:stat("wins")
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
	play_round_music("victory" if winner>=0 and winner==primary_player().team else "defeat")

func manhattan(a,b):return abs(a.x-b.x)+abs(a.y-b.y)
func danger_cells():
	var danger: Dictionary={}
	if mode==3:
		for enemy in adventure.enemies:
			if enemy.dead:continue
			danger[enemy.cell]=0
			if enemy.move<1:danger[Vector2i(enemy.from)]=0
	for f in blasts:
		if f.time>0 and not f.get("pulse_only",false):danger[f.cell]=0.0
	var fuses={}
	for b in bombs:fuses[b.cell]=b.timer
	for hop in range(bombs.size()):
		var changed=false
		for b in bombs:
			for c in blast_cells(b):
				if fuses.has(c) and fuses[c]>fuses[b.cell]:fuses[c]=fuses[b.cell];changed=true
		if not changed:break
	for b in bombs:
		for c in blast_cells(b):danger[c]=minf(danger.get(c,99),fuses[b.cell])
	for hazard in hazards:
		for c in hazard.cells:danger[c]=minf(danger.get(c,99),hazard.wait)
	for echo in (map_rules.echoes if map_rules else []):
		for c in echo.cells:danger[c]=minf(danger.get(c,99),echo.wait)
	if rule()=="lava" and fmod(round_time,10)>5.5:
		for c in terrain:
			if terrain[c].type=="lava":danger[c]=0
	if mode!=1 and clock_time<=3:
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
		if node.depth>=[6,9,12][difficulty]:continue
		for dir in DIRS:
			var c=node.cell+dir
			if visited.has(c) or not passable(c,p) or not can_cross(node.cell,c):continue
			if danger.get(c,99)<(node.depth+1)*move_duration(p)+.15:continue
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
			if visited.has(c) or not passable(c,p) or not can_cross(node.cell,c) or danger.has(c):continue
			visited[c]=true
			queue.append({"cell":c,"first":dir if node.cell==p.cell else node.first})
	return best

func bot_direction(p,danger):
	if danger.has(p.cell):
		var escape=escape_direction(p,danger)
		if escape!=Vector2i.ZERO:return escape
	if mode in [1,2]:
		var options=[]
		for other in players:
			if other.id==p.id or other.dead or other.trap<=0 or (other.team!=p.team and concealed(other)):continue
			var distance=safe_route_distance(p,other.cell,danger)
			if distance<0 or distance*move_duration(p)>other.trap-.15:continue
			# Enemy contact has higher value; a much closer ally can still be saved first.
			options.append({"player":other,"cost":distance+(0 if other.team!=p.team else 2.5)})
		options.sort_custom(func(a,b):return a.cost<b.cost)
		if not options.is_empty():
			var target_player=options[0].player
			if p.visual.distance_to(target_player.visual)<.52:
				if target_player.team==p.team:release_player(target_player,p.id)
				else:kill_player(target_player,p.id)
				return Vector2i.ZERO
			return route_direction(p,target_player.cell,danger)
	if mode==3:
		var leaders=players.filter(func(other):return not other.bot and not other.dead)
		if not leaders.is_empty():
			leaders.sort_custom(func(a,b):return manhattan(a.cell,p.cell)<manhattan(b.cell,p.cell))
			if manhattan(leaders[0].cell,p.cell)>8:return route_direction(p,leaders[0].cell,danger)
	var target=adventure.bot_target(p) if mode==3 else null
	var best=manhattan(p.cell,target) if target!=null else 999
	for other in players:
		if other.dead or (other.team!=p.team and concealed(other)):continue
		if other.team==p.team and other.trap<=0:continue
		var distance=manhattan(other.cell,p.cell)
		if other.team==p.team:distance-=8
		if distance<best:target=other.cell;best=distance
	for d in decoys:
		if d.team!=p.team and manhattan(d.cell,p.cell)<best:target=d.cell;best=manhattan(d.cell,p.cell)
	for c in drops:
		var kind=int(drops[c])
		if Catalog.ITEMS[kind].kind=="active" and p.item!=0:continue
		if growth_full(p,kind):continue
		var distance=manhattan(c,p.cell)-3
		if distance<best:target=c;best=distance
	if target!=null:
		var dir=route_direction(p,target,danger)
		if dir!=Vector2i.ZERO:return dir
	var choices: Array=[]
	for d in DIRS:
		if passable(p.cell+d,p) and can_cross(p.cell,p.cell+d) and not danger.has(p.cell+d):choices.append(d)
	return choices[rng.randi_range(0,choices.size()-1)] if not choices.is_empty() else Vector2i.ZERO

func bot_actions(p,danger):
	if p.item!=0:
		var should_use=false
		match int(p.item):
			1,9,11:should_use=danger.has(p.cell) or p.trap>0
			3:
				var owned=bombs.filter(func(b):return b.owner==p.id)
				var trigger=[]
				for b in owned:trigger.append(b)
				var marked={}
				while not trigger.is_empty():
					var bomb=trigger.pop_front()
					if marked.has(bomb.cell):continue
					marked[bomb.cell]=true
					var cells=blast_cells(bomb)
					if cells.has(p.cell):marked[p.cell]=true;break
					for next in bombs:
						if cells.has(next.cell) and not marked.has(next.cell):trigger.append(next)
				should_use=not owned.is_empty() and not marked.has(p.cell)
			6:should_use=DIRS.any(func(d):return bomb_at(p.cell+d)!=null)
			10:should_use=DIRS.any(func(d):return inside(p.cell+d) and grid[p.cell.y+d.y][p.cell.x+d.x]==2)
			12,13,17:should_use=players.any(func(other):return not other.dead and not concealed(other) and other.team!=p.team and manhattan(other.cell,p.cell)<=4)
			18:should_use=players.any(func(other):return not other.dead and other.team==p.team and other.trap>0 and manhattan(other.cell,p.cell)<=3)
			_:should_use=true
		if p.item in [26,27]:should_use=(weather.nightness>.2 or weather.fog_strength>.2) and (p.item==26 or p.torch<=0)
		if mode==3 and p.item in [12,13,17]:should_use=adventure.enemies.any(func(enemy):return not enemy.dead and manhattan(enemy.cell,p.cell)<=4)
		if should_use:use_item(p.id)
	if danger.has(p.cell) or p.get("attack",0)>0 or bomb_at(p.cell)!=null:return
	var wants_bomb=adventure.should_bomb(p) if mode==3 else false
	var ambush=false
	if difficulty>0 and mode in [1,2]:
		for captive in players:
			if captive.dead or concealed(captive) or captive.team==p.team or captive.trap<=0:continue
			var defenders=players.filter(func(other):return not other.dead and other.trap<=0 and other.team==captive.team and manhattan(other.cell,captive.cell)<=5)
			if not defenders.is_empty() and manhattan(p.cell,captive.cell) in [2,3] and safe_route_distance(p,captive.cell,danger)>1:
				ambush=true;wants_bomb=true
	for other in players:
		if not other.dead and not concealed(other) and other.team!=p.team and manhattan(other.cell,p.cell)<=p.range+1:wants_bomb=true
	for d in DIRS:
		var c=p.cell+d
		if inside(c) and grid[c.y][c.x]==2:wants_bomb=true
	if not wants_bomb:return
	var virtual={"cell":p.cell,"range":p.range,"timer":bubble_fuse(p),"owner":p.id,"element":p.element}
	var coverage=blast_cells(virtual)
	var effective=coverage.any(func(c):return grid[c.y][c.x]==2) or players.any(func(other):return not other.dead and not concealed(other) and other.team!=p.team and coverage.has(other.cell))
	if mode==3:effective=effective or adventure.enemies.any(func(e):return not e.dead and coverage.has(e.cell)) or adventure.objects.any(func(o):return not o.active and o.type=="beacons" and coverage.has(o.cell))
	if ambush:
		effective=effective or coverage.any(func(c):return players.any(func(other):return not other.dead and not concealed(other) and other.team!=p.team and other.trap>0 and manhattan(c,other.cell)==1))
	if not effective:return
	bombs.append(virtual)
	var hypothetical=danger_cells()
	bombs.erase(virtual)
	if escape_direction(p,hypothetical)==Vector2i.ZERO:return
	for ally in players:
		if ally.id==p.id or ally.dead or ally.team!=p.team or not hypothetical.has(ally.cell):continue
		if ally.trap>0 or escape_direction(ally,hypothetical)==Vector2i.ZERO:return
	place_bomb(p.id)

func rect(pos,size,color):canvas.draw_rect(Rect2(pos,size),color)
func pixel_size(size):return clampi(size,7,36)
func loc(message):
	font=ZH_FONT if i18n and i18n.locale=="zh" else UI_FONT
	return i18n.render(message) if i18n else str(message)
func apply_language(index):
	i18n.set_language(I18n.LOCALES[index]);profile.locale=i18n.locale;get_tree().root.title=loc("泡泡糖 · 像素群岛大冒险");save_profile();encyclopedia.rebuild();queue_redraw()
func draw_languages():
	page_header("语言 / Language")
	for index in range(5):button(Vector2(190,96+index*40),Vector2(260,32),I18n.NAMES[index],index==language_selection)
	centered("选择语言后立即生效，自动保存。",333,12)
func text_at(message,pos,size=12,color=CREAM,max_width=0):
	var label=loc(message);var px=pixel_size(size)
	var available=float(max_width) if max_width>0 else 632-pos.x
	var measured=font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x
	if measured>available and available>0:px=maxi(7,int(px*available/measured))
	while available>0 and px>7 and font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x>available:px-=1
	if available>0 and font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x>available:
		while not label.is_empty() and font.get_string_size(label+"…",HORIZONTAL_ALIGNMENT_LEFT,-1,px).x>available:label=label.left(label.length()-1)
		label+="…"
	canvas.draw_string(font,pos,label,HORIZONTAL_ALIGNMENT_LEFT,-1,px,color)
func centered(message,y,size=12,color=CREAM):
	var label=loc(message);var px=pixel_size(size)
	var width=font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x
	if width>610:px=maxi(7,int(px*610/width));width=font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x
	canvas.draw_string(font,Vector2((640-width)/2,y),label,HORIZONTAL_ALIGNMENT_LEFT,-1,px,color)
func wrapped(message,pos,width=9,color=CREAM,max_lines=0):
	var label=loc(message);var available=width*12.0;var px=12
	var limit=max_lines if max_lines>0 else maxi(2,int((330-pos.y)/16))
	var lines=wrap_lines(label,available,px)
	while lines.size()>limit and px>8:px-=1;lines=wrap_lines(label,available,px)
	if lines.size()>limit:lines=lines.slice(0,limit);lines[limit-1]+="…"
	for line in range(lines.size()):
		var content=lines[line]
		if font.get_string_size(content,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x>available:
			while not content.is_empty() and font.get_string_size(content+"…",HORIZONTAL_ALIGNMENT_LEFT,-1,px).x>available:content=content.left(content.length()-1)
			content+="…"
		canvas.draw_string(font,pos+Vector2(0,line*(px+4)),content,HORIZONTAL_ALIGNMENT_LEFT,-1,px,color)
func wrap_lines(label,width,px):
	var lines:Array=[];var current=""
	var tokens=label.split(" ") if i18n.locale in ["en","fr","de"] else label.split("")
	var spacer=" " if i18n.locale in ["en","fr","de"] else ""
	for token in tokens:
		var candidate=current+spacer+token if not current.is_empty() else token
		if font.get_string_size(candidate,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x>width and not current.is_empty():lines.append(current);current=token
		else:current=candidate
	if not current.is_empty():lines.append(current)
	return lines

func panel(pos,size,color=Color("60788e")):
	var style=StyleBoxFlat.new();style.bg_color=Color("17283b");style.border_color=color.darkened(.25)
	style.set_border_width_all(1);style.set_corner_radius_all(4)
	canvas.draw_style_box(style,Rect2(pos,size))
func button(pos,size,label,selected=false):
	panel(pos,size,Color("ffe08e") if selected else Color("527c91"))
	var localized=loc(label);var px=12
	var width=font.get_string_size(localized,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x
	if width>size.x-8:px=maxi(7,int(px*(size.x-8)/width));width=font.get_string_size(localized,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x
	canvas.draw_string(font,pos+Vector2((size.x-width)/2,size.y/2+5),localized,HORIZONTAL_ALIGNMENT_LEFT,-1,px,Color("ffe08e") if selected else CREAM)
# Small pools show one square per HP; large pools use ten segments and an exact count.
func health_bar(pos,hp,maximum,width=20,height=2):
	if maximum<=0:return
	var remaining=clampi(hp,0,maximum)
	var counted=maximum>10
	var slots=mini(maximum,10)
	var label="×%d" % remaining
	var badge_width=8+font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,7).x if counted else 0.0
	var gap=.5
	var available=maxf(width-2-(badge_width+3 if counted else 0),slots+(slots-1)*gap)
	var cell_width=minf(float(height), (available-(slots-1)*gap)/slots)
	var bar_width=slots*cell_width+(slots-1)*gap
	var total_width=bar_width+(badge_width+3 if counted else 0)
	var row_height=maxf(float(height),7 if counted else height)
	pos+=Vector2((width-total_width)*.5,0)
	rect(pos-Vector2(1,1),Vector2(total_width+2,row_height+2),Color(.06,.11,.17,.42))
	rect(pos-Vector2(.5,.5),Vector2(total_width+1,.5),Color(.39,.44,.51,.55))
	var filled=ceili(float(remaining)*slots/maximum) if counted else remaining
	for n in range(slots):
		var at=pos+Vector2(n*(cell_width+gap),(row_height-height)*.5)
		rect(at,Vector2(cell_width,height),Color("ee4558") if n<filled else Color(.22,.17,.22,.55))
		if n<filled:
			rect(at,Vector2(cell_width,.5),Color("ff98a1"))
			rect(at+Vector2(0,height-.5),Vector2(cell_width,.5),Color("a32642"))
	if counted:
		var heart=pos+Vector2(bar_width+3,.5)
		var outline=PackedVector2Array([Vector2(0,1),Vector2(1,0),Vector2(2,0),Vector2(3,1),Vector2(4,0),Vector2(5,0),Vector2(6,1),Vector2(6,3),Vector2(3,6),Vector2(0,3)])
		for n in range(outline.size()):outline[n]+=heart
		canvas.draw_colored_polygon(outline,Color("ef4960"))
		outline.append(outline[0]);canvas.draw_polyline(outline,Color("9c233b"),.6)
		rect(heart+Vector2(1,1),Vector2(1.5,.7),Color("ffbec4"))
		canvas.draw_string(font,heart+Vector2(8,6),label,HORIZONTAL_ALIGNMENT_LEFT,-1,7,Color("fff0df"))

func item_icon(pos,kind,side=20):
	if kind<=0 or kind==8:return
	if kind==31:hd.sprite(Racing.ART,3,pos,Vector2.ONE*side);return
	if kind in [5,29,30]:hd.sprite({5:"items/water-reach-v480.png",29:"items/strength-pill-v480.png",30:"items/demon-mask-v480.png"}[kind],0,pos,Vector2.ONE*side)
	elif kind==28:hd.sprite("items/pressure-core-v464.png",0,pos,Vector2.ONE*side)
	else:hd.sprite("items/remote-hd.png" if kind==3 else "items/items-hd.png",0 if kind==3 else kind,pos,Vector2.ONE*side)
	if kind in [4,5,7,16,28]:
		var scale_factor=maxf(.8,side/20.0)
		var at=pos+Vector2(side-3*scale_factor,2*scale_factor)
		rect(at-Vector2.ONE*2.5*scale_factor,Vector2.ONE*5*scale_factor,Color(.03,.12,.24,.82))
		rect(at+Vector2(-2,-.65)*scale_factor,Vector2(4,1.3)*scale_factor,Color("68ceff"))
		rect(at+Vector2(-.65,-2)*scale_factor,Vector2(1.3,4)*scale_factor,Color("68ceff"))
func premium_hero_region(character,direction=0):return hd.region(HDArt.HERO_VIEWS[direction],character)
func hero_piece(pos,size,source,part,offset=Vector2.ZERO,tint=Color.WHITE,direction=0):
	var ratio=size/Vector2(96,112)
	var region=Rect2(source.position+part.position*source.size/Vector2(96,112),part.size*source.size/Vector2(96,112))
	canvas.draw_texture_rect_region(hd.textures[HDArt.HERO_VIEWS[direction]],Rect2(pos+(part.position+offset)*ratio,part.size*ratio),region,tint)
func hero_sprite(pos,character,size,direction=0,pose=0,tint=Color.WHITE,seated=false,walk_phase=-1.0,palette_id=-1):
	if character==8:
		text_at("?",pos+Vector2(size.x*.25,size.y*.75),int(size.y*.7),Color("ffe08e"),size.x);return
	var name=HDArt.HERO_VIEWS[direction]
	var source=premium_hero_region(character,direction)
	var index=character
	if pose in range(4,12) and not seated:
		var walk_name="characters/walk/walk-"+HDArt.WALK_NAMES[character]+"-hd.png"
		if hd.regions.has(walk_name):
			name=walk_name
			var phase=(walk_phase if walk_phase>=0 else (pose-4)*1.5) if pose in range(4,12) else 0.0
			var frames=int(hd.regions[name].size()/4)
			index=direction*frames+posmod(int(phase*frames/12.0),frames);source=hd.region(name,index)
	if direction==0 and not seated and (pose in range(12,16) or pose in range(20,24)):
		name="characters/actions/hero-actions-hd.png"
		var action=mini(2,pose-12)+4 if pose<16 else pose-20
		index=action*8+character;source=hd.region(name,index)
	if pose in range(16,20) and not seated:
		name="characters/actions/hero-trapped-v5.png"
		index=(pose-16)*8+character;source=hd.region(name,index)
	if seated:source.size.y*=.64
	var baseline=source.size
	if name.begins_with("characters/walk/"):
		baseline=hd.animation_baseline(name)
	var drawn=source.size*minf(size.x/baseline.x,size.y/baseline.y)
	var at=pos+Vector2((size.x-drawn.x)/2,size.y-drawn.y)
	var hurt=pose in range(12,16)
	var trapped=pose in range(16,20)
	var placing=pose>=20
	var pivot=at+Vector2(drawn.x*.5,drawn.y*.72)
	var angle=[-.13,-.085,-.035,0.0][pose-12] if hurt else sin(elapsed*10)*.025 if trapped else [0.0,-.045,-.025,0.0][pose-20] if placing else 0.0
	if angle!=0:
		canvas.draw_set_transform(pivot+Vector2(sin(elapsed*83),cos(elapsed*71))*shake,angle)
		at-=pivot
	if palette_id>=0:canvas.draw_texture_rect(hero_palette.texture_for(palette_id,false,hd.textures[name],source,.64 if seated else 1.0,hd.regions[name][index][4] if hd.regions[name][index].size()>4 else []),Rect2(at,drawn),false,tint)
	else:hd.draw_region(name,index,Rect2(at,drawn),tint)
	if angle!=0:canvas.draw_set_transform(Vector2(sin(elapsed*83),cos(elapsed*71))*shake)

func portrait(pos,character,size=Vector2(20,24),frame=0):
	hero_sprite(pos,character,size,int(frame/3),0 if frame%3==0 else 4+(frame%3)*2)

func face_portrait(pos,character,size,palette_id=-1):
	if character==8:
		text_at("?",pos+Vector2(size.x*.25,size.y*.8),int(size.y*.8),Color("ffe08e"),size.x);return
	var source=premium_hero_region(character)
	source.size.y*=.62
	var drawn=source.size*minf(size.x/source.size.x,size.y/source.size.y)
	var at=pos+(size-drawn)/2
	if palette_id>=0:canvas.draw_texture_rect(hero_palette.texture_for(palette_id,true,hd.textures[HDArt.HERO_VIEWS[0]],source,.62),Rect2(at,drawn),false)
	else:canvas.draw_texture_rect_region(hd.textures[HDArt.HERO_VIEWS[0]],Rect2(at,drawn),source)

func color_for(p):
	if mode in [0,1,2,3]:return COLORS[p.team%8]
	return COLORS[p.id]
func burst(pos,color,amount):
	for i in range(amount):particles.append({"pos":pos,"vel":Vector2(rng.randf_range(-32,32),rng.randf_range(-42,10)),"life":rng.randf_range(.25,.55),"color":color})

func _draw():
	canvas=self
	racing.sync_views()
	world_clip.visible=state in ["play","pause","finale","result"] and mode!=1
	game_overlay.visible=state in ["play","pause","finale","result"]
	game_overlay.queue_redraw()
	if backgrounds.is_empty():return
	canvas.draw_texture_rect(backgrounds[Catalog.MAPS[arena].theme],Rect2(Vector2.ZERO,Vector2(640,360)),false,Color.WHITE.lerp(Color(.12,.17,.26),weather.nightness*.8 if weather.flare_time<=0 else 0))
	rect(Vector2.ZERO,Vector2(640,360),Color(.025,.045,.075,.34))
	if state=="story":adventure.draw_story();return
	if frontend.active():frontend.draw();return
	if state=="maps":draw_map_browser();return
	if state=="characters":draw_characters();return
	if state=="stats":draw_stats();return
	if state=="help":draw_help();return
	if state=="codex":encyclopedia.draw();return
	if state=="languages":draw_languages();return
	if mode==1:racing.draw_hud();return
	draw_hud()
	draw_sidebar()
	if mode==3:draw_pve_minimap()
	rect(ORIGIN-Vector2(3,3),VIEW_SIZE*TILE+Vector2(6,6),Color("111b30"))
	world_canvas.queue_redraw()

func draw_tile(c):
	if map_void.has(c):return
	if arena>=44:
		racing.draw_tile(c);return
	var theme=Catalog.MAPS[arena].theme
	var pos=ORIGIN+Vector2(c)*TILE
	var cell=grid[c.y][c.x]
	if cell==2 and crates.at(c)!=null:cell=0
	var kind=(c.x+c.y)%2
	# Opaque theme ground under transparent tile-edge pixels avoids cracks.
	rect(pos,Vector2(TILE,TILE),Color(HDArt.FLOOR_COLORS[theme]))
	if cell==3:
		rect(pos,Vector2(TILE,TILE),Color("101524"))
		var age=round_time-collapsed_at.get(c,round_time-1)
		if age<.55:
			var inset=age*9
			hd.theme_sprite(theme,0,pos+Vector2(inset,inset+age*8),Vector2(TILE-2*inset,TILE-2*inset),Color.WHITE,false)
		return
	hd.theme_sprite(theme,kind,pos,Vector2(TILE,TILE),Color.WHITE,false)
	if gates.has(c) and cell==0:hd.sprite("maps/mechanisms/mechanisms-v472.png",3,pos,Vector2.ONE*TILE,Color.WHITE,false)

func draw_obstacle(c):
	var theme=Catalog.MAPS[arena].theme
	var pos=ORIGIN+Vector2(c)*TILE
	var cell=grid[c.y][c.x]
	if gates.has(c) and cell==1:hd.sprite("maps/mechanisms/mechanisms-v472.png",10,pos,Vector2.ONE*TILE,Color.WHITE,false)
	else:hd.theme_sprite(theme,2 if cell==1 else 3,pos,Vector2(TILE,TILE),Color.WHITE,false)
	if cell==2 and vine_cells.has(c):
		canvas.draw_line(pos+Vector2(6,17),pos+Vector2(8,2),Color("95c989"),2)
		canvas.draw_line(pos+Vector2(8,10),pos+Vector2(14,6),Color("b1dea0"),2)
	if cell==2 and gold_boxes.has(c):
		canvas.draw_rect(Rect2(pos+Vector2(3,3),Vector2(14,13)),Color("ffe696"),false,1)
		item_icon(pos+Vector2(4,2),19,12)

func draw_terrain():
	var kinds={"portal":4,"flow":6,"ice":12,"spring":0,"sand":14,"switch":0,"lava":15,"mirror":13,"mud":14,"spore":15,"spike":1,"gust":6,"vortex":14,"geyser":3,"clock":11,"bridge":6,"rail":6}
	for c in terrain:
		if grid[c.y][c.x] in [1,2,3]:continue
		var tile=terrain[c];var pos=center(c)
		if not kinds.has(tile.type):continue
		var index=kinds[tile.type];var tint=Color.WHITE
		if tile.type=="portal":index=4 if c.x<W/2 else 5
		elif tile.type=="spike":
			if blasts.any(func(f):return f.cell==c and not f.get("pulse_only",false)):index=2
		elif tile.type=="mud":tint=Color("a48b70")
		elif tile.type=="spore":tint=Color("9fd09b")
		elif tile.type=="lava":tint=Color(1.15,.8,.6) if fmod(round_time,10)>7.5 else Color(.75,.75,.75)
		var reverse=false
		if tile.type in ["flow","gust"]:
			var dir=tile.get("dir",Vector2i.RIGHT);index=7 if dir.y!=0 else 6;reverse=dir.x<0 or dir.y<0
		if reverse:canvas.draw_set_transform(pos+Vector2(sin(elapsed*83),cos(elapsed*71))*shake,PI)
		hd.sprite("maps/mechanisms/mechanisms-v472.png",index,Vector2(-8,-8) if reverse else pos-Vector2(8,8),Vector2.ONE*TILE,tint,false)
		if reverse:canvas.draw_set_transform(Vector2(sin(elapsed*83),cos(elapsed*71))*shake)

	for hazard in hazards:
		for c in hazard.cells:
			if hazard.type=="laser":continue
			if inside(c):
				if hazard.has("skill"):adventure.draw_skill_warning(hazard,c)
				else:canvas.draw_arc(center(c),6,0,TAU,32,Color("ffbb65"),.8)
	if mode!=1 and clock_time<=3:
		for y in range(1,H-1):
			for x in range(1,W-1):
				if mini(mini(x,W-1-x),mini(y,H-1-y))==sudden_ring+2:canvas.draw_rect(Rect2(ORIGIN+Vector2(x,y)*TILE+Vector2.ONE,Vector2.ONE*(TILE-2)),Color(1,.75,.3,.5+.3*sin(elapsed*9)),false,.8)

func draw_laser_warning(hazard):
	var charge=clampf(1-hazard.wait/1.2,0,1)
	for c in hazard.cells:
		if not inside(c) or grid[c.y][c.x] in [1,3]:continue
		var pos=center(c)
		canvas.draw_rect(Rect2(pos-Vector2(8,6),Vector2(16,12)),Color(1,.58,.12,.06+charge*.13))
		for offset in [-6,6]:canvas.draw_line(pos+Vector2(-8,offset),pos+Vector2(8,offset),Color(1,.7,.24,.45+charge*.4),.6)
		canvas.draw_line(pos-Vector2(8,0),pos+Vector2(8,0),Color(1,.86,.45,.25+charge*.6),.7)
		var scan=fposmod(elapsed*16+c.x*4,14)-7
		canvas.draw_polyline(PackedVector2Array([pos+Vector2(scan-2,-2),pos+Vector2(scan,0),pos+Vector2(scan-2,2)]),Color(1,.85,.35,.75),.8)

func draw_laser_segment(f):
	var pos=center(f.cell)
	var age=clampf(1-f.time/.6,0,1)
	var fade=minf(1,f.time/.18)
	var width=1.7+sin(age*PI)*.55
	var from=pos-Vector2(TILE*.5+.1,0);var to=pos+Vector2(TILE*.5+.1,0)
	canvas.draw_line(from,to,Color(1,.16,.08,fade*.16),10)
	canvas.draw_line(from,to,Color(1,.24,.12,fade*.35),6)
	canvas.draw_line(from,to,Color(1,.53,.28,fade*.9),width*2)
	canvas.draw_line(from,to,Color(1,.97,.84,fade),width)
	for n in range(2):
		var flight=fposmod(age*26+f.cell.x*3+n*7,16)-8
		var at=pos+Vector2(flight,sin(age*19+f.cell.x+n)*3)
		canvas.draw_line(at-Vector2(1.2,0),at+Vector2(1.2,0),Color(1,.85,.45,fade*(1-age)),.7)

func draw_laser_emitters():
	if rule()!="laser":return
	for row in [H/2-5,H/2,H/2+5]:
		var intensity=0.0
		for hazard in hazards:
			if hazard.type=="laser" and not hazard.cells.is_empty() and hazard.cells[0].y==row:intensity=maxf(intensity,clampf(1-hazard.wait/1.2,0,1))
		for f in blasts:
			if f.get("hazard","")=="laser" and f.cell.y==row:intensity=maxf(intensity,minf(1,f.time/.18))
		for x in [0,W-1]:
			var pos=center(Vector2i(x,row))
			canvas.draw_set_transform(pos,0,Vector2(-1,1) if x==W-1 else Vector2.ONE)
			hd.sprite("maps/mechanisms/mechanisms-v472.png",9,Vector2(-8,-8),Vector2(16,16))
			canvas.draw_set_transform(Vector2(sin(elapsed*83),cos(elapsed*71))*shake)
			canvas.draw_circle(pos+Vector2(-3 if x==W-1 else 3,0),1.2,Color(1,.8,.4,.3+intensity*.7))

func draw_bomb(b):
	var pos=center(b.cell)
	var p=players[b.owner]
	var element=b.get("element",0)
	var color=color_for(p) if element==0 else Color(BubbleEffects.STYLES[element].color)
	var pulse=sin(elapsed*(15 if b.timer<.7 else 4))*.25
	hd.sprite("effects/bubbles-hd.png",element,pos-Vector2(7+pulse,7+pulse),Vector2.ONE*(14+pulse*2))
	canvas.draw_arc(pos,6.7+pulse,0,TAU,48,Color(color,.7),.45)
	if element>0:
		canvas.draw_arc(pos,7.3,elapsed*2,elapsed*2+4.5,20,color.lightened(.3),1)
		item_icon(pos-Vector2(4,4),19+element,8)
	rect(pos+Vector2(-5,8),Vector2(10,1),INK)
	rect(pos+Vector2(-5,8),Vector2(10*clampf(b.timer/b.fuse,0,1),1),CREAM)
func draw_warning(b):
	for c in blast_cells(b):canvas.draw_rect(Rect2(ORIGIN+Vector2(c)*TILE+Vector2(2,2),Vector2(16,16)),Color(1,.93,.62,.7),false,1)
func draw_water_piece(pos,frame,part,size,angle,tint):
	canvas.draw_set_transform(pos+Vector2(sin(elapsed*83),cos(elapsed*71))*shake,angle)
	hd.sprite("effects/water-vines-v473.png",frame*4+part,-size/2,size,tint,false)
	canvas.draw_set_transform(Vector2(sin(elapsed*83),cos(elapsed*71))*shake)

func draw_splash(f):
	if f.has("skill"):adventure.draw_skill_hit(f);return
	if f.get("hazard","")=="laser":draw_laser_segment(f);return
	var pos=center(f.cell)
	var element=f.get("element",0)
	var age=clampf(1-f.time/f.get("duration",.6),0,1)
	var frame=0 if age<.14 else 1 if age<.55 else 2 if age<.82 else 3
	var tint=Color.WHITE if element==0 else Color(BubbleEffects.STYLES[element].color).lightened(.2)
	if f.owner<0:tint=Color("ffd09b")
	tint.a=minf(1,f.time/.12)
	var links=f.get("links",[])
	if links.is_empty():
		draw_water_piece(pos,frame,2,Vector2(13,13),0,tint);return
	if links.size()==1:
		var direction=-Vector2(links[0])
		draw_water_piece(pos,frame,1,Vector2(TILE+.6,10),direction.angle(),tint)
	else:
		for axis in [Vector2i.RIGHT,Vector2i.DOWN]:
			if links.has(axis) and links.has(-axis):draw_water_piece(pos,frame,0,Vector2(TILE+.6,9),Vector2(axis).angle(),tint)
			else:
				for direction in [axis,-axis]:
					if links.has(direction):draw_water_piece(pos+Vector2(direction)*4,frame,0,Vector2(9,9),Vector2(direction).angle(),tint)
	if f.get("origin",f.cell)==f.cell:draw_water_piece(pos,frame,2,Vector2(13,13),0,tint)

func draw_actor(pos,p):
	if concealed(p):return
	if state=="finale" and (not p.dead or (result_winner>=0 and p.team==result_winner)):
		draw_finale_actor(pos,p);return
	if p.dead:
		var death_phase=clampi(int((1.05-p.down)/.35),0,2)
		var size=Vector2(20,25) if death_phase==0 else Vector2(27,18) if death_phase==1 else Vector2(29,12)
		var source=hd.region("characters/actions/hero-death-v5.png",death_phase*8+p.character)
		var drawn=source.size*minf(size.x/source.size.x,size.y/source.size.y)
		canvas.draw_texture_rect(hero_palette.texture_for(p.id,false,hd.textures["characters/actions/hero-death-v5.png"],source),Rect2(pos+Vector2(-drawn.x/2,5-drawn.y),drawn),false)
		draw_bubble_break(pos,p)
		return
	if mode==1 and p.get("car",false):racing.draw_car(pos,p,Color.WHITE);return
	var color=color_for(p)
	var walking=p.move<1 and p.trap<=0 and p.freeze<=0 and not p.dead
	var phase=p.gait*PI
	var bob=-abs(sin(phase))*.6 if walking and p.mount>0 else 0.0
	var direction=0 if p.facing==Vector2i.DOWN else (1 if p.facing==Vector2i.UP else (2 if p.facing==Vector2i.LEFT else 3))
	var pose=3 if fmod(elapsed+p.id*.67,4)>3.86 else int(elapsed*2+p.id)%3
	if walking:pose=4+int(p.gait*4)%8
	elif p.placing>0:pose=20+clampi(int((.32-p.placing)/.08),0,3)
	if p.trap>0:pose=16+int(elapsed*9)%4
	if p.hurt>0:pose=12+clampi(int((.48-p.hurt)/.12),0,3);pos+=p.recoil*sin(p.hurt/.48*PI)*2.5
	var tint=Color(1.35,1.28,1.15) if p.hurt>.36 else Color.WHITE
	if p.grace>0 and p.hurt<=0:tint.a=.6+.4*sin(elapsed*22)
	if p.jump_travel>0:bob-=sin((1-p.jump_travel/.42)*PI)*12
	elif p.jump>0 and p.mount!=3:bob-=sin(clampf(p.jump/.8,0,1)*PI)*3
	# Contact shadow and team ring are distinct from the body and follow the ground.
	canvas.draw_set_transform(pos+Vector2(0,5),0,Vector2(1,.35))
	canvas.draw_circle(Vector2.ZERO,9 if p.mount>0 else 7,Color(0.05,.09,.15,.38*tint.a))
	canvas.draw_arc(Vector2.ZERO,10 if p.mount>0 else 8,0,TAU,24,Color(color,.65*tint.a),1)
	canvas.draw_set_transform(Vector2(sin(elapsed*83),cos(elapsed*71))*shake)
	if p.mount>0:
		var mount_frame=int(p.gait*2)%4 if walking else 0
		hd.riding_sprite(pos+Vector2(0,bob),p,p.mount,direction,mount_frame,tint)
		health_bar(pos+Vector2(-6,14),p.mount_hp,mount_durability(p),12,2)
	else:hero_sprite(pos+Vector2(-11,-20+bob),p.character,Vector2(22,25),direction,pose,tint,false,p.gait*6,p.id)
	if p.hurt>0:
		var hit=1-p.hurt/.48
		for n in range(5):
			var angle=n*TAU/5+hit
			var at=pos+Vector2(cos(angle),sin(angle))*(8+hit*9)-Vector2(0,5)
			canvas.draw_line(at-Vector2(1,0),at+Vector2(1,0),Color(1,.95,.7,1-hit),1)
			canvas.draw_line(at-Vector2(0,1),at+Vector2(0,1),Color(1,.95,.7,1-hit),1)
	if p.reverse_time>0:item_icon(pos+Vector2(-5,-41),30,10)
	if p.freeze>0:canvas.draw_rect(Rect2(pos+Vector2(-15,-32),Vector2(30,42)),Color(.67,.88,1,.16))
	if p.shield>0:
		canvas.draw_arc(pos+Vector2(0,-5),15,elapsed*1.5,elapsed*1.5+TAU*.8,32,Color("b3ffe0"),1)
		for n in range(3):canvas.draw_circle(pos+Vector2(cos(elapsed*2+n*TAU/3),sin(elapsed*2+n*TAU/3))*15-Vector2(0,5),1,Color("edffd3"))
	if p.trap>0:
		var bubble_pos=pos+Vector2(0,-5)
		canvas.draw_circle(bubble_pos,14,Color(.36,.72,.95,.15))
		hd.sprite("effects/bubbles-hd.png",7,bubble_pos-Vector2(15,15),Vector2(30,30))
		canvas.draw_arc(bubble_pos+Vector2(-1,-1),13,3.5,4.5,12,Color("efffff"),2)
		canvas.draw_circle(bubble_pos+Vector2(6,7),1,Color("d3faff"))
		text_at(str(snappedf(p.trap,.1)),pos+Vector2(7,9),8,Color("fff3c5"))
	if p.get("torch",0)>0:item_icon(pos+Vector2(10,-5),27,10)
	if p.kick>0:item_icon(pos+Vector2(-16,5),6,9)
	if p.dash>0:
		rect(pos+Vector2(-15,5),Vector2(4,1),Color("ffe08e"));rect(pos+Vector2(-14,8),Vector2(3,1),Color("ffe08e"))
	if p.cloak>0:canvas.draw_arc(pos,12,PI,TAU,16,Color("c7a4ff"),1)
	if p.magnet>0:canvas.draw_arc(pos,16,elapsed,elapsed+3.7,18,Color("ffe08e"),1)

	draw_bubble_break(pos,p)
	var tag=Vector2(pos.x-9,pos.y-27)
	rect(tag,Vector2(18,7),COLORS[p.id].darkened(.65));rect(tag,Vector2(2,7),color)
	text_at(("B" if p.bot else "P")+str(p.id+1),tag+Vector2(3,6),7,Color.WHITE)

func draw_bubble_break(pos,p):
	if p.pop_time<=0:return
	var frame=clampi(int((.55-p.pop_time)/(.55/6)),0,5)
	hd.sprite("effects/bubble-break-v5.png",p.pop_row*6+frame,pos+Vector2(-18,-21),Vector2(36,36))

func draw_hud():
	text_at(Catalog.MAPS[arena].name,Vector2(8,11),9,CREAM)
	centered(("%d:%02d" % [int(maxf(0,clock_time))/60,int(maxf(0,clock_time))%60]) if clock_time>0 else "坍塌中",11,10,Color("ff8b76") if clock_time<=30 else Color("ffe08e"))
	text_at(loc(MODES[mode]),Vector2(475,11),9,CREAM,155)
	for i in range(players.size()):
		var p=players[i];var pos=Vector2(5+i*79,16);var color=color_for(p)
		panel(pos,Vector2(76,29),color);rect(pos+Vector2(2,2),Vector2(2,25),color)
		face_portrait(pos+Vector2(5,2),p.character,Vector2(12,12),p.id)
		text_at(("B" if p.bot else "P")+str(i+1),pos+Vector2(20,11),9,COLORS[p.id])
		if p.item>0:item_icon(pos+Vector2(58,2),p.item,13)
		text_at("出局" if p.dead else ("被困" if p.trap>0 else loc("泡%d 水%d 速%d") % [p.capacity,p.range,p.speed]),pos+Vector2(6,24),8,Color("8796a6") if p.dead else CREAM,66)

func draw_pve_minimap():
	var pos=Vector2(338,17);var step=minf(105.0/W,27.0/H)
	rect(pos-Vector2.ONE,Vector2(W,H)*step+Vector2(2,2),INK)
	for y in range(H):
		for x in range(W):
			if not map_void.has(Vector2i(x,y)):rect(pos+Vector2(x,y)*step,Vector2.ONE*step,Color("718094") if grid[y][x]==1 else Color("293e4b"))
	for o in adventure.objects:
		if not o.active:rect(pos+Vector2(o.cell)*step-Vector2.ONE,Vector2(2,2),Color("ffda70"))
	for p in players:
		if not p.dead:rect(pos+p.visual*step-Vector2.ONE,Vector2(2,2),COLORS[p.id])
	canvas.draw_rect(Rect2(pos+camera*step,VIEW_SIZE*step),Color("d4eff2"),false,.5)
	text_at(["轻松","标准","挑战"][difficulty],Vector2(459,37),9,CREAM,73)

func draw_sidebar():
	panel(Vector2(5,55),Vector2(94,296),Color("52798b"))
	panel(Vector2(541,55),Vector2(94,296),Color("52798b"))
	var p=primary_player()
	text_at("P"+str(p.id+1),Vector2(13,72),12,color_for(p))
	item_icon(Vector2(13,82),p.item,22)
	text_at(Catalog.ITEMS[p.item].name,Vector2(13,120),10,CREAM,78)
	if state=="play" and notice_time>0:
		var opacity=minf(1.0,notice_time/.4)
		canvas.draw_rect(Rect2(10,132,84,66),Color(.10,.19,.28,.9*opacity))
		canvas.draw_line(Vector2(11,137),Vector2(11,193),Color(1,.83,.48,opacity),1)
		var lines=wrap_lines(loc(notice),72,9)
		if lines.size()>4:lines=lines.slice(0,4);lines[3]+="…"
		for i in range(lines.size()):
			var label=lines[i]
			if font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,9).x>72:
				while font.get_string_size(label+"…",HORIZONTAL_ALIGNMENT_LEFT,-1,9).x>72 and not label.is_empty():label=label.left(label.length()-1)
				label+="…"
			canvas.draw_string(font,Vector2(16,146+i*13),label,HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color(1,.89,.66,opacity))
	else:wrapped(Catalog.ITEMS[p.item].tip,Vector2(13,139),6,Color("aac0cc"),4)
	var kinds=[4,5,7,16];var values=[p.capacity,p.range,p.speed,p.riding]
	if mode==3:kinds.append(28);values.append(1+p.damage_level)
	for i in range(kinds.size()):
		item_icon(Vector2(13,209+i*19),kinds[i],14)
		text_at(str(values[i]),Vector2(40,221+i*19),10,CREAM)
	text_at(weather.label(),Vector2(13,336),9,Color("ead0a1"),79)
	text_at("冒险任务" if mode==3 else "地图机关",Vector2(550,73),10,Color("ffe08e"),77)
	if mode==3:
		wrapped(adventure.stage.objective,Vector2(550,94),6,CREAM,5)
		if adventure.stage.mission=="boss":
			text_at(adventure.objective_label(),Vector2(550,182),9,Color("9ce3c4"),77)
			var bosses=adventure.enemies.filter(func(e):return e.boss and not e.dead)
			if not bosses.is_empty():health_bar(Vector2(550,195),bosses[0].hp,bosses[0].max_hp,77,3)
		else:wrapped(adventure.objective_label(),Vector2(550,170),6,Color("9ce3c4"),4)
		wrapped(adventure.SIDE_QUESTS[adventure_stage-1],Vector2(550,237),6,Color("cbb2e8"),2)
		text_at(loc("支线 %d/2") % adventure.bonus_progress,Vector2(550,281),9,Color("cbb2e8"),77)
		text_at("复苏",Vector2(550,300),9,Color("ffe08e"),58)
		text_at(str(adventure.revives),Vector2(615,300),9,Color("ffe08e"),15)
	else:
		wrapped(Catalog.MAPS[arena].tip,Vector2(550,94),6,Color("b7d2ce"),6)
		wrapped("队友可触碰救援；所有水柱都有友伤。" if mode in [0,2] else "困住对手后触碰获胜，或让泡泡计时结束。",Vector2(550,203),6,Color("9ce3c4"),5)
	button(Vector2(549,315),Vector2(78,25),"暂停 / 退出")

func mini_board(pos,step=8):
	var theme=Catalog.MAPS[arena].theme
	for y in range(H):
		for x in range(W):
			var cell=grid[y][x]
			var kind=2 if cell==1 else (3 if cell==2 else (x+y)%2)
			if arena>=Racing.FIRST_MAP:
				var tile=0 if racing.road.has(Vector2i(x,y)) else 2 if cell==1 else 1
				hd.sprite(Racing.GROUND,(arena-Racing.FIRST_MAP)*3+tile,pos+Vector2(x,y)*step,Vector2.ONE*step,Color.WHITE,false)
				if cell==1 and racing.cover.has(Vector2i(x,y)):hd.theme_sprite(Catalog.MAPS[arena].theme,2,pos+Vector2(x,y)*step,Vector2.ONE*step,Color.WHITE,false)
				elif cell==2:rect(pos+Vector2(x,y)*step,Vector2.ONE*step,Color(.55,.34,.18,.7))
			else:hd.theme_sprite(theme,kind,pos+Vector2(x,y)*step,Vector2(step,step),Color.WHITE,false)
	for c in terrain:
		var type=terrain[c].type
		if type=="shelter":hd.sprite("maps/decorations/shelters-v480.png",terrain[c].art,pos+Vector2(c)*step,Vector2.ONE*step)
		if type in ["portal","spring","lava","switch","ice"]:
			canvas.draw_circle(pos+Vector2(c)*step+Vector2(step/2,step/2),step*.35,Color("d5aeff") if type=="portal" else Color("ffe1aa"))

	if arena>=Racing.FIRST_MAP:
		for i in range(racing.checkpoints.size()):
			var cp=racing.checkpoints[i];var side=Vector2(-cp.dir.y,cp.dir.x)
			canvas.draw_line(pos+(cp.pos+Vector2.ONE*.5-side)*step,pos+(cp.pos+Vector2.ONE*.5+side)*step,Color("ffe3a8") if i==0 else Color("7ce3ff"),maxf(1,step*.6))

func page_header(title):
	rect(Vector2.ZERO,Vector2(640,360),Color(.04,.08,.14,.6))
	text_at(title,Vector2(22,30),24,Color("ffe08e"))
	button(Vector2(540,10),Vector2(80,22),"返回 ESC")

func draw_map_browser():
	page_header("群岛地图图鉴")
	var page=int(selection/20)
	for slot in range(20):
		var i=page*20+slot
		if i>=44:continue
		var map=Catalog.MAPS[i]
		var pos=Vector2(12+(slot%4)*156,45+int(slot/4)*56)
		panel(pos,Vector2(147,52),Color("ffe08e") if i==selection else Color("527a8c"))
		text_at("%02d %s" % [i+1,map.name],pos+Vector2(6,17),12,Color("ffe08e") if i==selection else CREAM)
		canvas.draw_texture_rect(backgrounds[map.theme],Rect2(pos+Vector2(7,23),Vector2(48,23)),false)
		item_icon(pos+Vector2(59,24),[1,11,5,15,10,2,12,12,7,3,16,6,15,19,3,14,7,17,6,12][i%20],20)
		text_at(["海港","森林","冰雪","沙漠","火山","工厂","糖果","星空","沼泽","遗迹","深海","空港","王城","洞窟"][map.theme],pos+Vector2(83,39),12,Color("a8c5c4"))
	button(Vector2(12,331),Vector2(100,23),"上一页")
	button(Vector2(528,331),Vector2(100,23),"下一页")
	centered(loc("第%d/%d页 · 方向键选择 / 回车选图") % [page+1,int(ceil(44/20.0))],348,12)

func draw_characters():
	page_header("人物与坐骑")
	text_at(loc("正在设置玩家 %d / TAB 切换玩家") % (character_slot+1),Vector2(32,63),12,CREAM)
	for slot in range(lobby_count()):button(Vector2(32+slot*75,68),Vector2(65,18),"P%d" % (slot+1),slot==character_slot)
	for i in range(8):
		var pos=Vector2(32+i*75,92)
		var unlocked=character_selectable(i)
		panel(pos,Vector2(65,86),Color("ffe08e") if i==selection else Color("648297"))
		hero_sprite(pos+Vector2(12,6),i,Vector2(40,48),0,4+int(elapsed*8)%8 if i==selection else (3 if fmod(elapsed+i*.5,4)>3.86 else int(elapsed*2+i)%3))
		text_at(Catalog.CHARACTERS[i].name,pos+Vector2(14,67),12,CREAM if unlocked else Color("829bb0"))
		if not unlocked:text_at(loc("通%d关") % Catalog.CHARACTERS[i].unlock,pos+Vector2(7,81),12,Color("ffc8c6"))
	button(Vector2(32,182),Vector2(150,20),"随机角色",selection==8)
	centered("随机：每局从可选角色中抽取。" if selection==8 else character_name(selection)+"："+Catalog.CHARACTERS[selection].perk,218,12,Color("ffe08e"))
	for i in range(1,4):
		var pos=Vector2(88+(i-1)*184,225)
		hd.mount_sprite(i,3,pos,Vector2(48,42),Color.WHITE,elapsed*5)
		text_at(Catalog.MOUNTS[i].name,pos+Vector2(54,18),12,Color(Catalog.MOUNTS[i].color))
	button(Vector2(240,283),Vector2(160,28),"选用 / 回车" if character_selectable(selection) else "闯关后解锁",character_selectable(selection))
	centered("局内成长每局重置，角色解锁和闯关进度会保存。",343,12)

func draw_stats():
	page_header("我的冒险手账")
	panel(Vector2(28,56),Vector2(584,265),Color("83b5b6"))
	text_at(loc("竞技闯关 %d/20   剧情冒险 %d/20") % [int(profile.cleared),int(profile.adventure_cleared)],Vector2(46,81),12,Color("ffe08e"))
	var names=["参加局数","获胜","失利","平局","放置泡泡","炸开箱子","拾取道具","救援队友","骑乘次数","出局次数","中途退出","游戏分钟","击败怪物","击败守护者","冒险通关次数","支线勋章"]
	var values=[profile.stats.rounds,profile.stats.wins,profile.stats.losses,profile.stats.draws,profile.stats.bombs,profile.stats.crates,profile.stats.items,profile.stats.rescues,profile.stats.mounts,profile.stats.deaths,profile.stats.abandoned,int(profile.stats.seconds/60),profile.stats.monsters,profile.stats.bosses,profile.stats.pve_stages,profile.adventure_bonus.size()]
	for i in range(16):
		var pos=Vector2(46+(i%4)*140,106+int(i/4)*49)
		text_at(names[i],pos,12,Color("abd0ca"),130)
		text_at(str(int(values[i])),pos+Vector2(0,24),24,CREAM)
	centered("个人统计记玩家一 · 冒险击败与任务按队伍记录 · 自动存档",346,12)

func draw_help():
	page_header("道具图鉴与操作")
	text_at("玩家1：WASD / 空格 / Q    玩家2：方向键 / 回车 / /",Vector2(20,57),12)
	text_at("玩家3：IJKL / U / O      玩家4：TFGH / R / Y",Vector2(20,75),12)
	var kinds=(range(1,19)+range(20,29)).filter(func(kind):return kind!=8)
	for slot in range(kinds.size()):
		var i=kinds[slot]
		var pos=Vector2(18+(slot%7)*88,86+int(slot/7)*46)
		item_icon(pos,i,24)
		text_at(Catalog.ITEMS[i].name,pos+Vector2(0,36),12,Color(Catalog.ITEMS[i].color),82)
	wrapped("轮箱可以推动；加固箱两点耐久，宝库箱八点耐久。空手自动拾取；手持主动道具时按 E / . / ; / V 更换。蓝色加号代表成长，成长每局重置。",Vector2(20,280),48,CREAM)
	text_at("ESC / P 暂停，可返回大厅或保存并退出；M 声音。",Vector2(20,346),12,Color("ffe08e"))

func draw_pause():
	rect(Vector2.ZERO,Vector2(640,360),Color(.03,.06,.12,.85))
	panel(Vector2(160,103),Vector2(320,172),Color("8bd5d1"))
	centered("歇一会儿",136,24,CREAM)
	for i in range(3):button(Vector2(195,153+i*32),Vector2(250,28),["继续对战","返回大厅（记录退出）","保存并退出游戏"][i],i==quit_selection)
	centered("上下选择 / 回车确认 / ESC 继续",294,12)
func draw_result():
	rect(Vector2.ZERO,Vector2(640,360),Color(.03,.06,.12,.88))
	panel(Vector2(50,24),Vector2(540,322),Color("ffe08e"))
	centered(result_text,58,23,Color("ffe08e"))
	if mode==3:
		wrapped(adventure.stage.outro if result_winner==0 else "调整道具与走位，再挑战本关。章节进度已保存。",Vector2(72,82),41,Color("bfe2ce"),2)
	elif mode==0:
		centered(loc("第%d关 / %s") % [campaign_stage,Catalog.MAPS[arena].name],89,11)
	else:
		for team in range(team_count):
			var points=players.filter(func(p):return p.team==team).reduce(func(total,p):return total+p.race_points,0) if mode==1 else scores[team]
			text_at(team_name(team)+"  "+str(points),Vector2(70+(team%4)*128,84+int(team/4)*15),9,COLORS[team],120)
	for i in range(players.size()):
		var p=players[i];var pos=Vector2(70+(i%2)*255,115+int(i/2)*38)
		panel(pos,Vector2(245,34),color_for(p))
		face_portrait(pos+Vector2(5,3),p.character,Vector2(24,27),p.id)
		text_at(("B" if p.bot else "P")+str(p.id+1)+" · "+loc(Catalog.CHARACTERS[p.character].name)+" · "+loc("电脑" if p.bot else "玩家"),pos+Vector2(35,12),9,color_for(p),203)
		var detail=loc("击杀 %d · 救援 %d") % [p.round_kills,p.round_rescues]
		if mode==1:detail=(loc("第 %d 名 · %d 分") % [p.race_rank,p.race_points]) if p.race_finished else loc("未完成 · 0 分")
		if mode==3:detail+=" · "+loc("击败怪物 %d") % p.round_monsters
		text_at(detail,pos+Vector2(35,27),10,CREAM,203)
	var action=(("下一节" if adventure_stage<20 else "重温故事") if result_winner==0 else "重试本节") if mode==3 else ("下一关" if campaign_stage<20 else "重新冒险") if mode==0 and result_winner==0 else ("再战本关" if mode==0 else ("新一场" if match_over else "下一局"))
	button(Vector2(195,278),Vector2(250,28),action+" / 回车",true)
	button(Vector2(195,313),Vector2(250,24),"返回大厅 / ESC")

func close_game():
	if not round_recorded:stat("abandoned");round_recorded=true
	save_profile()
	music.stop()
	for speaker in speakers:speaker.stop()
	await get_tree().create_timer(.15).timeout
	get_tree().quit()
func _exit_tree():
	if hero_palette:hero_palette.renders.clear()
	if music:music.stop();music.stream=null
	if music_previous:music_previous.stop();music_previous.stream=null
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
			canvas.draw_line(Vector2(x,y).round(),Vector2(x-2,y+5).round(),Color("9aaad0"),1)
	elif rule()=="wind" and fmod(round_time,9)>7.5:
		for n in range(8):
			var y=ORIGIN.y+25+n*27
			var x=ORIGIN.x+fposmod(elapsed*70+n*39,W*TILE)
			canvas.draw_line(Vector2(x,y),Vector2(x+17,y),Color("bddca2"),1)


func _notification(what):
	if what==NOTIFICATION_WM_WINDOW_FOCUS_OUT and state=="play":
		pause_return="play";state="pause";paused=true;quit_selection=0

func draw_world():
	canvas.draw_set_transform(Vector2(sin(elapsed*83),cos(elapsed*71))*shake)
	rect(ORIGIN-Vector2(3,3),Vector2(W*TILE+6,H*TILE+6),Color("111b30"))
	for y in range(maxi(0,int(camera.y)-1),mini(H,int(camera.y+VIEW_SIZE.y)+2)):
		for x in range(maxi(0,int(camera.x)-1),mini(W,int(camera.x+VIEW_SIZE.x)+2)):draw_tile(Vector2i(x,y))
	if mode==1:racing.draw_ground()
	else:world_fx.draw_ground()
	bubble_fx.draw_fields()
	draw_terrain()
	map_rules.draw()
	draw_weather()

	for hazard in hazards:
		if hazard.type=="laser":draw_laser_warning(hazard)
	for b in bombs:
		if b.timer<.7:draw_warning(b)
	# One ground-baseline order for all upright world art, including moving bodies.
	var depth=[]
	for y in range(maxi(0,int(camera.y)-2),mini(H,int(camera.y+VIEW_SIZE.y)+3)):
		for x in range(maxi(0,int(camera.x)-2),mini(W,int(camera.x+VIEW_SIZE.x)+3)):
			var c=Vector2i(x,y)
			if not map_void.has(c) and ((arena<44 and (grid[y][x]==1 or (grid[y][x]==2 and crates.at(c)==null))) or (arena>=44 and racing.cover.has(c) and grid[y][x]==1)):depth.append({"y":float(y+1)*TILE,"kind":"wall","data":c})
	for c in terrain:
		if is_shelter(c) and grid[c.y][c.x]==0:depth.append({"y":c.y*TILE+16.0,"kind":"shelter","data":c})
		if terrain[c].type=="lamp" and grid[c.y][c.x]==0:depth.append({"y":c.y*TILE+14.0,"kind":"lamp","data":c})
	if rule()=="train" and fmod(round_time,12)>=8:
		var head=int((fmod(round_time,12)-8)*8)-2
		for car in range(3):
			var c=Vector2i(head-car,H/2)
			if inside(c):depth.append({"y":c.y*TILE+16.0,"kind":"train","data":c})
	if arena>=20 and rule()=="turrets":
		for c in map_rules.cells:depth.append({"y":(c.y+1)*float(TILE),"kind":"turret","data":c})
	for box in crates.boxes:
		if not box.dead:depth.append({"y":(box.visual.y+box.size.y)*TILE,"kind":"box","data":box})
	for c in weather.torches:depth.append({"y":c.y*TILE+14.0,"kind":"torch","data":c})
	for c in drops:depth.append({"y":c.y*TILE+13.0,"kind":"drop","data":c})
	for bomb in bombs:depth.append({"y":bomb.cell.y*TILE+13.0,"kind":"bomb","data":bomb})
	for d in decoys:depth.append({"y":d.cell.y*TILE+13.0,"kind":"decoy","data":d})
	if mode==3:
		depth.append({"y":adventure.checkpoint.y*TILE+23.0,"kind":"gate","data":null})
		for o in adventure.objects:depth.append({"y":(o.cell.y+1)*float(TILE),"kind":"object","data":o})
		for o in adventure.bonus_objects:depth.append({"y":o.cell.y*TILE+13.0,"kind":"bonus","data":o})
		if adventure.stage.mission=="escort" and not adventure.escort_arrived:depth.append({"y":adventure.escort_visual.y*TILE+22.0,"kind":"escort","data":null})
		for e in adventure.enemies:depth.append({"y":e.visual.y*TILE+(16.0 if e.boss else 13.0),"kind":"enemy","data":e})
	for p in players:depth.append({"y":p.visual.y*TILE+13.0,"kind":"actor","data":p})
	for i in range(depth.size()):depth[i].order=i
	depth.sort_custom(func(a,b):return a.y<b.y if not is_equal_approx(a.y,b.y) else a.order<b.order)
	for entry in depth:
		match entry.kind:
			"shelter":world_fx.draw_shelter(entry.data)
			"wall":draw_obstacle(entry.data)
			"turret":map_rules.draw_turret(entry.data)
			"lamp":hd.sprite("missions/missions-hd.png",2,center(entry.data)-Vector2(6,8),Vector2(12,14))
			"train":hd.sprite("maps/decorations/fauna-hd.png",8,center(entry.data)-Vector2(8,10),Vector2(16,18))
			"box":crates.draw_box(entry.data)
			"torch":weather.draw_torch(entry.data)
			"drop":draw_drop(entry.data)
			"bomb":draw_bomb(entry.data)
			"gate":adventure.draw_checkpoint()
			"object":adventure.draw_object(entry.data)
			"bonus":adventure.draw_bonus(entry.data)
			"escort":adventure.draw_escort()
			"enemy":adventure.draw_enemy(entry.data)
			"actor":
				draw_actor(ORIGIN+entry.data.visual*TILE+Vector2(TILE/2.0,TILE/2.0),entry.data)
				if mode==3 and not concealed(entry.data):adventure.draw_cargo(entry.data)
			"decoy":
				portrait(center(entry.data.cell)-Vector2(10,15),entry.data.character)
				canvas.draw_arc(center(entry.data.cell),9,0,TAU,20,Color("d8abef"),1)
	for p in players:
		if concealed(p) and p.team==(racing.view_team if racing.view_team>=0 else primary_player().team):
			var at=ORIGIN+p.visual*TILE+Vector2(8,8)
			hero_sprite(at-Vector2(9,15),p.character,Vector2(18,20),0,0,Color(.65,.87,1,.28),false,-1,p.id)
			canvas.draw_arc(at+Vector2(0,5),6,0,TAU,24,Color(COLORS[p.id],.5),.8)
			text_at(("B" if p.bot else "P")+str(p.id+1),at+Vector2(-6,-16),7,Color(COLORS[p.id],.5))
	draw_laser_emitters()
	if mode==3:adventure.draw_skill_travel()
	for f in blasts:draw_splash(f)

	draw_loot_flights()
	for effect in pickup_effects:
		var progress=1-effect.life/.65
		item_icon(effect.pos+Vector2(-8,-12-progress*22),effect.kind,16*(1-progress*.35))
		canvas.draw_arc(effect.pos,5+progress*14,0,TAU,24,Color(1,.94,.65,1-progress),1)
	for p in particles:rect(p.pos.round(),Vector2(2,2),p.color)
	world_fx.draw_air()
	map_rules.draw_overlay()
	racing.draw_air()
	draw_pickup_prompts()
	canvas.draw_set_transform(Vector2.ZERO)

func draw_drop(c):
	if grid[c.y][c.x]!=0:return
	var kind=int(drops[c])
	var bob=sin(elapsed*4+c.x)*1.25
	var drop_color=Color(Catalog.ITEMS[kind].color)
	canvas.draw_circle(center(c)+Vector2(0,5),6,Color(.06,.12,.18,.18))
	canvas.draw_arc(center(c)+Vector2(0,4),6+sin(elapsed*3+c.y)*.5,0,TAU,24,Color(drop_color,.35),1)
	item_icon(center(c)+Vector2(-6,-7+bob),kind,12)
	var sparkle=fmod(elapsed+c.x*.3+c.y*.2,2)
	if sparkle<.45:
		var at=center(c)+Vector2(7,-9+bob)
		canvas.draw_line(at-Vector2(2,0),at+Vector2(2,0),Color(1,.98,.8,1-sparkle/.45),1)
		canvas.draw_line(at-Vector2(0,2),at+Vector2(0,2),Color(1,.98,.8,1-sparkle/.45),1)

func update_camera(dt):
	if mode!=3:camera=Vector2.ZERO;return
	var party=players.filter(func(p):return not p.dead)
	if party.is_empty():return
	var low=party[0].visual;var high=low;var mean=Vector2.ZERO
	for p in party:low=low.min(p.visual);high=high.max(p.visual);mean+=p.visual
	mean/=party.size()
	var desired=(mean+(low+high)*.5)*.5+Vector2(.5,.5)-VIEW_SIZE*.5
	var minimum=(high+Vector2(1.3,1.8)-VIEW_SIZE).max(Vector2(0,-.6))
	var maximum=(low-Vector2(.8,1.6)).min(Vector2(W,H)-VIEW_SIZE).max(minimum)
	camera=camera.lerp(desired,1-exp(-dt*6)).clamp(minimum,maximum)

func nearest_playable(c):
	if inside(c):return c
	for radius in range(1,maxi(W,H)):
		for d in DIRS:
			var next=c+d*radius
			if inside(next) and next.x>0 and next.y>0 and next.x<W-1 and next.y<H-1:return next
	return Vector2i(W/2,H/2)

func draw_game_overlay():
	if countdown>0:
		panel(Vector2(238,165),Vector2(164,44),Color("62ceff"))
		centered(str(int(ceil(countdown))) if countdown>.7 else "开战！",197,24)
	if state=="pause":draw_pause()
	elif state=="result":draw_result()
	elif state=="finale":
		var alpha=clampf((finale_time-.45)/.8,0,.85)*clampf((3.8-finale_time)/.4,0,1)
		var tint=Color(1,.92,.65,alpha)
		canvas.draw_rect(Rect2(172,146,296,39),Color(.08,.15,.22,alpha*.45))
		centered(result_text,172,22,tint)


func camera_contains(position):
	var local=position-camera
	return local.x>=.8 and local.x<=VIEW_SIZE.x-1.3 and local.y>=1.6 and local.y<=VIEW_SIZE.y-1.8

func draw_pickup_prompts():
	var prompts={}
	for p in players:
		if p.bot or p.dead or p.trap>0 or p.freeze>0 or p.item==0:continue
		var c=nearby_active(p)
		if c==null:continue
		if not prompts.has(c):prompts[c]=[]
		prompts[c].append({"label":PICKUP_LABELS[p.control],"color":COLORS[p.id]})
	for c in prompts:
		var total=prompts[c].size()*9.0
		var pos=center(c)+Vector2(-total/2,-16+sin(elapsed*3)*.3)
		for n in range(prompts[c].size()):
			var entry=prompts[c][n];var at=pos+Vector2(n*9,0)
			rect(at,Vector2(8,10),Color(.04,.11,.18,.88))
			canvas.draw_rect(Rect2(at,Vector2(8,10)),Color(entry.color,.8),false,.5)
			var width=font.get_string_size(entry.label,HORIZONTAL_ALIGNMENT_LEFT,-1,7).x
			canvas.draw_string(font,at+Vector2((8-width)/2,7.5),entry.label,HORIZONTAL_ALIGNMENT_LEFT,-1,7,Color("fff5db"))

func draw_finale_actor(pos,p):
	var winner=result_winner>=0 and p.team==result_winner
	var t=finale_time
	var rise=absf(sin((t+p.id*.10)*7))*3.8 if winner else 0.0
	canvas.draw_circle(pos+Vector2(0,5),7,Color(.04,.09,.13,.28))
	# Transform the complete sprite: the costume and limbs stay joined.
	var angle=sin(t*7)*.045 if winner else .10*sin(t*1.8+p.id)
	canvas.draw_set_transform(pos+Vector2(0,5-rise),angle,Vector2(1,1 if winner else .92))
	var row=(4 if sin(t*7+p.id*.2)>.2 else 0) if winner else 5
	var name="characters/actions/hero-actions-hd.png"
	var source=hd.region(name,row*8+p.character)
	var baseline=hd.animation_baseline(name)
	var drawn=source.size*minf(22/baseline.x,25/baseline.y)
	canvas.draw_texture_rect(hero_palette.texture_for(p.id,false,hd.textures[name],source),Rect2(Vector2(-drawn.x/2,-drawn.y),drawn),false)
	canvas.draw_set_transform(Vector2.ZERO)
	if winner:
		for i in range(3):
			var at=pos+Vector2((i-1)*10,-27-fmod(t*11+i*7,17))
			canvas.draw_line(at-Vector2(2,0),at+Vector2(2,0),Color(1,.87,.4,.65),1)
			canvas.draw_line(at-Vector2(0,2),at+Vector2(0,2),Color(1,.87,.4,.65),1)
	text_at(("B" if p.bot else "P")+str(p.id+1),pos+Vector2(-7,-31-rise),8,COLORS[p.id])

func safe_route_distance(p,target,danger):
	var queue=[{"cell":p.cell,"depth":0}]
	var visited={p.cell:true}
	while not queue.is_empty():
		var node=queue.pop_front()
		if node.cell==target:return node.depth
		for dir in DIRS:
			var c=node.cell+dir
			if visited.has(c) or not passable(c,p) or not can_cross(node.cell,c) or danger.has(c):continue
			visited[c]=true;queue.append({"cell":c,"depth":node.depth+1})
	return -1

func team_name(team):return loc(TEAM_NAMES[posmod(team,TEAM_NAMES.size())])

func character_name(index):return "随机角色" if index==8 else Catalog.CHARACTERS[index].name

func is_shelter(c):return terrain.has(c) and terrain[c].type=="shelter"
func concealed(p):
	return state in ["play","pause"] and not p.dead and is_shelter(p.cell) and p.visual.distance_to(Vector2(p.cell))<.42
func can_cross(source,dest):
	if source==dest:return true
	var delta=dest-source
	for c in [source,dest]:
		if not is_shelter(c):continue
		var axis=terrain[c].axis
		if axis=="x" and delta.y!=0:return false
		if axis=="y" and delta.x!=0:return false
	return true
