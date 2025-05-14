extends SceneTree

func _init():
	var err = ProjectSettings.load_resource_pack("res://")
	
	print("Chargement de la scène player.tscn...")
	var playerScene = load("res://player.tscn")
	if playerScene:
		var player = playerScene.instance()
		
		print("Ajout du script Player.gd au nœud Player...")
		var script = load("res://Player.gd")
		if script:
			player.set_script(script)
			var error = ResourceSaver.save("res://player.tscn", playerScene)
			if error == OK:
				print("Script ajouté avec succès et scène enregistrée!")
			else:
				print("Erreur lors de l'enregistrement de la scène: " + str(error))
		else:
			print("Erreur: Impossible de charger le script Player.gd")
	else:
		print("Erreur: Impossible de charger la scène player.tscn")
	
	quit() 