extends RefCounted
var g
var events:Array=[]
var links:Array=[]
var footsteps:Array=[]
func _init(game):g=game
func impact(pos,kind=0,size=30):
	events.append({"pos":pos,"kind":kind,"life":.48,"size":size})
	if events.size()>90:events.pop_front()
func footstep(pos,direction,mounted=false):
	footsteps.append({"pos":pos,"dir":Vector2(direction),"life":.35,"mounted":mounted})
	if footsteps.size()>40:footsteps.pop_front()
func chain(from,to):links.append({"from":from,"to":to,"life":.3})
func update(dt):
	for foot in footsteps:foot.life-=dt
	footsteps=footsteps.filter(func(foot):return foot.life>0)
	for link in links:link.life-=dt
	links=links.filter(func(link):return link.life>0)
	for event in events:event.life-=dt
	events=events.filter(func(event):return event.life>0)
func draw_ground():
	pass
func draw_visitors(theme):
	# Each habitat has a distinct animated visitor, separate from gameplay hazards.
	for n in range(1):
		var pos=g.ORIGIN+Vector2(fposmod(g.elapsed*(22 if theme==13 else 13)+n*117,g.W*g.TILE),28+n*43+sin(g.elapsed*1.7+n)*13)
		var flap=sin(g.elapsed*(11 if theme==13 else 6)+n)
		if theme in [13,0,11,12,1,8,10]:
			var kind=0 if theme==13 else 1 if theme in [0,12] else 4 if theme==11 else 5 if theme==1 else 2 if theme==8 else 3
			var size=Vector2(20,12)*(1+flap*.035)
			g.hd.sprite("fauna-hd.png",kind,pos-size/2,size,Color(1,1,1,.66))
		elif theme==5:
			var vent=g.center(Vector2i(2+n*8,1));var age=fmod(g.elapsed+n,.9)
			g.draw_arc(vent+Vector2(sin(age*5)*3,-age*16),2+age*3,PI,TAU,12,Color(.8,.88,.88,(1-age)*.35),1)
		elif theme==6:g.draw_arc(pos,3+sin(g.elapsed+n),0,TAU,16,Color(.95,.77,.9,.3),1)
		elif theme==7 and fmod(g.elapsed+n*5,18)<1.5:
			g.draw_line(pos,pos+Vector2(-13,5),Color(.86,.84,1,.4),1);g.draw_circle(pos,1,Color("ebddff"))
		elif theme==9:
			g.draw_arc(g.center(Vector2i(3+n*7,2))+Vector2(sin(g.elapsed+n)*3,-fmod(g.elapsed*4+n*7,18)),3,PI,TAU,12,Color(.8,.78,.85,.25),1)
func draw_air():
	var theme=g.Catalog.MAPS[g.arena].theme
	draw_visitors(theme)
	var color=[Color("c4efdf"),Color("c6dba0"),Color("e5f7ff"),Color("eed0aa"),Color("ffba83"),Color("bddbdd"),Color("ffe0ed"),Color("dfd6ff"),Color("d3edaa"),Color("decfb7"),Color("b9eeeb"),Color("e6f3e9"),Color("d1b6ef"),Color("a4c7d1")][theme]
	for n in range(8):
		var pos=g.ORIGIN+Vector2(fposmod(n*53+g.elapsed*(3 if theme in [7,8,12] else 9),g.W*g.TILE),fposmod(n*29+g.elapsed*(8 if theme==2 else -4),g.H*g.TILE))
		var alpha=.12+.12*sin(g.elapsed*2+n)
		if theme in [0,10]:
			g.draw_arc(pos,1.5+(n%3)*.5,0,TAU,10,Color(color,alpha),1)
		elif theme in [1,8]:
			g.rect(pos,Vector2(2,1),Color(color,alpha));g.rect(pos+Vector2(1,-1),Vector2(1,3),Color(color,alpha))
		elif theme in [7,12]:
			g.draw_line(pos-Vector2(2,0),pos+Vector2(2,0),Color(color,alpha),1);g.draw_line(pos-Vector2(0,2),pos+Vector2(0,2),Color(color,alpha),1)
		else:g.rect(pos,Vector2(1 if theme in [3,9] else 2,1),Color(color,alpha))
	for foot in footsteps:
		var age=1-foot.life/.35
		for side in [-1,1]:
			var at=foot.pos-foot.dir*age*4+Vector2(-foot.dir.y,foot.dir.x)*side*(2+age*3)+Vector2(0,5)
			g.draw_circle(at,1.5 if foot.mounted else 1,Color(.82,.84,.74,(1-age)*.4))
	for link in links:
		g.draw_line(link.from,link.to,Color(.65,.91,1,link.life*3),3)
		g.draw_line(link.from,link.to,Color(1,1,1,link.life*3),1)
	for event in events:
		var frame=clampi(int((.48-event.life)/.12),0,3)
		g.hd.sprite("impacts-hd.png",frame*6+event.kind,event.pos-Vector2.ONE*event.size/2.0,Vector2.ONE*event.size)
