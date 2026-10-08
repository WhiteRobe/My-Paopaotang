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
			g.racing.view_team=p.team;g.racing.view_player=p.id
			position=-g.ORIGIN-g.camera*g.TILE
			g.draw_world()
			var base=g.ORIGIN+g.camera*g.TILE
			g.rect(base,Vector2(get_parent().size.x,29),Color(.04,.1,.16,.72))
			g.text_at("P"+str(p.id+1)+" · "+str(p.race_lap)+"/"+str(g.racing.laps)+" "+g.loc("圈")+" · "+str(snappedf(p.velocity.length(),.1)),base+Vector2(5,13),8,g.CREAM)
			g.text_at(g.loc("泡泡%d · 水柱%d · 速度%d") % [p.capacity,p.range,p.speed],base+Vector2(5,25),7,Color("acd5df"))
			if not p.race_finished:
				var cp=g.racing.checkpoints[p.race_next]
				var delta=cp.pos-p.visual
				var target=g.ORIGIN+(cp.pos+Vector2.ONE*.5)*g.TILE
				if not Rect2(base,get_parent().size).has_point(target):
					var actor=g.ORIGIN+(p.visual+Vector2.ONE*.5)*g.TILE
					var at=actor+delta.normalized()*minf(get_parent().size.x,get_parent().size.y)*.3
					at=at.clamp(base+Vector2(20,45),base+get_parent().size-Vector2(40,20))
					g.canvas.draw_polyline(PackedVector2Array([at-delta.normalized().rotated(.6)*6,at,at-delta.normalized().rotated(-.6)*6]),Color("ffe3a8"),2)
					g.text_at(g.loc("检查点 %d") % p.race_next if p.race_next>0 else g.loc("终点"),at+Vector2(-12,-9),7,Color("ffe3a8"))
				if p.race_flash>0:g.text_at("检查点通过",base+Vector2(5,40),9,Color("8cf2be"))
			g.camera=previous;g.racing.view_team=-1;g.racing.view_player=-1
	else:
		position=-g.ORIGIN-g.camera*g.TILE
		g.draw_world()
	g.canvas=g
