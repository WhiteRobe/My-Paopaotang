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
			scale=Vector2.ONE
			position=-g.ORIGIN-g.camera*g.TILE
			if humans.size()==1:
				var board=Vector2(g.W,g.H)*g.TILE
				scale=Vector2.ONE*minf((get_parent().size.x-8)/board.x,(get_parent().size.y-8)/board.y)
				g.camera=Vector2.ZERO;position=(get_parent().size-board*scale)*.5-g.ORIGIN*scale
			g.draw_world()
			var base=g.ORIGIN+g.camera*g.TILE
			if not p.race_finished:
				var cp=g.racing.checkpoints[p.race_next]
				var delta=cp.pos-p.visual
				var target=g.ORIGIN+(cp.pos+Vector2.ONE*.5)*g.TILE
				if humans.size()>1 and not Rect2(base,get_parent().size).has_point(target):
					var actor=g.ORIGIN+(p.visual+Vector2.ONE*.5)*g.TILE
					var at=actor+delta.normalized()*minf(get_parent().size.x,get_parent().size.y)*.3
					at=at.clamp(base+Vector2(16,16),base+get_parent().size-Vector2(40,20))
					g.canvas.draw_polyline(PackedVector2Array([at-delta.normalized().rotated(.6)*6,at,at-delta.normalized().rotated(-.6)*6]),Color("ffe3a8"),2)
			g.camera=previous;g.racing.view_team=-1;g.racing.view_player=-1
	else:
		position=-g.ORIGIN-g.camera*g.TILE
		g.draw_world()
	g.canvas=g
