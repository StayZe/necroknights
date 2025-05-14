@tool
extends EditorScript

func _run():
	# Charger la scène player.tscn
	var player_scene = load("res://player.tscn")
	if not player_scene:
		print("Erreur: Impossible de charger player.tscn")
		return
		
	# Obtenir le nœud root (qui devrait être le joueur)
	var player_scene_instance = player_scene.instantiate()
	var player_node = player_scene_instance.get_node("player")
	
	if not player_node:
		print("Erreur: Impossible de trouver le nœud 'player' dans player.tscn")
		# Essayons de chercher dans les enfants directs
		for child in player_scene_instance.get_children():
			print("Enfant trouvé: ", child.name)
			if child.name.to_lower().contains("player"):
				player_node = child
				print("Nœud joueur trouvé: ", child.name)
				break
	
	if not player_node:
		# Essayons d'utiliser directement le nœud racine
		print("Utilisation du nœud racine comme joueur")
		player_node = player_scene_instance
	
	# Chargement du script Player.gd
	var player_script = load("res://Player.gd")
	if not player_script:
		print("Erreur: Impossible de charger Player.gd")
		return
	
	# Assigner le script au nœud joueur
	player_node.set_script(player_script)
	
	# Ajouter le joueur au groupe "player" s'il n'y est pas déjà
	if not player_node.is_in_group("player"):
		player_node.add_to_group("player")
	
	# Enregistrer la scène
	var packed_scene = PackedScene.new()
	var result = packed_scene.pack(player_scene_instance)
	if result != OK:
		print("Erreur lors du packing de la scène: ", result)
		return
	
	result = ResourceSaver.save(packed_scene, "res://player.tscn")
	if result != OK:
		print("Erreur lors de l'enregistrement de la scène: ", result)
		return
	
	print("Script ajouté avec succès au nœud joueur dans player.tscn!") 