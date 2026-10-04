extends SceneTree

# Start the real main scene with a temporary save path, before _ready loads it.
func _initialize():
	call_deferred("boot")

func boot():
	var output=""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--harness-output="):output=argument.trim_prefix("--harness-output=")
	if output.is_empty() or not output.is_absolute_path():
		push_error("Harness requires an absolute output directory.")
		quit(1)
		return
	var scene=load("res://scenes/main.tscn")
	if scene==null:
		quit(1)
		return
	var game=scene.instantiate()
	game.save_path=output.path_join("profile.json")
	root.add_child(game)
	var errors:Array=[]
	if game.MAP_COUNT!=game.Catalog.MAPS.size():errors.append("MAP_COUNT differs from catalog size.")
	for map in game.Catalog.MAPS:
		if map.theme<0 or map.theme>=game.Catalog.THEMES.size():errors.append("Invalid map theme: "+map.name)
	for theme in game.Catalog.THEMES:
		for path in ["res://assets/hd/landscape-"+theme+"-hd.png","res://assets/audio/themes/"+theme+".ogg"]:
			if not ResourceLoader.exists(path):errors.append("Missing theme resource: "+path)
	for stage in game.adventure.Story.STAGES:
		if stage.map<0 or stage.map>=game.Catalog.MAPS.size():errors.append("Invalid story map: "+stage.name)
		if stage.chapter<0 or stage.chapter>=game.adventure.Story.CHAPTERS.size():errors.append("Invalid story chapter: "+stage.name)
	var content={"maps":game.Catalog.MAPS.size(),"themes":game.Catalog.THEMES.size(),
		"item_entries":game.Catalog.ITEMS.size(),"characters":game.Catalog.CHARACTERS.size(),
		"mount_entries":game.Catalog.MOUNTS.size(),"chapters":game.adventure.Story.CHAPTERS.size(),
		"story_stages":game.adventure.Story.STAGES.size(),"locales":game.I18n.LOCALES,
		"state":game.state,"save_path":game.save_path,"errors":errors}
	game.save_profile()
	var file=FileAccess.open(output.path_join("content.json"),FileAccess.WRITE)
	if file==null:
		push_error("Cannot write harness content report.")
		quit(1)
		return
	file.store_string(JSON.stringify(content,"\t"))
	file.close()
	print("HARNESS_MAIN_SCENE_READY")
