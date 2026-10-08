extends Node2D
var g
var overlay=false
var race_view=-1
func _draw():
	g.canvas=self
	if overlay:g.draw_game_overlay()
	elif race_view>=0:
		var humans=g.players.filter(func(p):return not p.bot)
		if race_view<humans.size():
			var previous=g.camera
			var p=humans[race_view];var extent=get_parent().size/g.TILE
			g.camera=(p.visual+Vector2(.5,.5)-extent*.5).clamp(Vector2.ZERO,(Vector2(g.W,g.H)-extent).max(Vector2.ZERO))
			g.racing.view_team=p.team
			position=-g.ORIGIN-g.camera*g.TILE
			g.draw_world()
			var base=g.ORIGIN+g.camera*g.TILE
			g.rect(base,Vector2(get_parent().size.x,29),Color(.04,.1,.16,.72))
			g.text_at("P"+str(p.id+1)+" · "+str(p.race_lap)+"/"+str(g.racing.laps)+" "+g.loc("圈")+" · "+str(snappedf(p.velocity.length(),.1)),base+Vector2(5,13),8,g.CREAM)
			g.text_at(g.loc("泡泡%d · 水柱%d · 速度%d") % [p.capacity,p.range,p.speed],base+Vector2(5,25),7,Color("acd5df"))
			if not p.race_finished:
				var cp=g.racing.checkpoints[p.race_next]
				var delta=cp.pos-p.visual
				var middle=base+get_parent().size*.5
				var at=middle+delta.normalized()*minf(get_parent().size.x,get_parent().size.y)*.34
				g.canvas.draw_line(at,at+delta.normalized()*7,Color("ffe3a8"),2)
				g.text_at("CP"+str(p.race_next),at+Vector2(-8,-5),7,Color("ffe3a8"))
			g.camera=previous;g.racing.view_team=-1
	else:
		position=-g.ORIGIN-g.camera*g.TILE
		g.draw_world()
	g.canvas=g
