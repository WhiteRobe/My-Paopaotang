extends Node2D
var g
var overlay=false
func _draw():
	g.canvas=self
	if overlay:g.draw_game_overlay()
	else:
		position=-g.ORIGIN-g.camera*g.TILE
		g.draw_world()
	g.canvas=g
