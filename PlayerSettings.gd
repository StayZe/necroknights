extends Node

# Singleton pour gérer les paramètres du joueur
var selected_skin: int = 1  # Par défaut, le joueur 1

# Chemins vers les sprites des joueurs
var player_sprites = {
	1: "res://sprites/players/1.png",
	2: "res://sprites/players/2.png", 
	3: "res://sprites/players/3.png"
}

func get_selected_sprite_path() -> String:
	return player_sprites.get(selected_skin, player_sprites[1])

func reset_to_default():
	selected_skin = 1 