extends Node

# Gestionnaire principal du jeu (Singleton)
var game_started = false

func _ready():
	# Attendre un peu que tout soit initialisé
	await get_tree().create_timer(1.0).timeout
	start_game()

func start_game():
	print("🎮 Démarrage du jeu...")
	
	# Vérifier que le WaveManager existe
	if not get_node_or_null("/root/WaveManager"):
		print("Erreur: WaveManager non trouvé!")
		return
	
	# Attendre que les spawners et le joueur soient enregistrés
	await get_tree().create_timer(0.5).timeout
	
	# Démarrer les manches
	WaveManager.start_waves()
	game_started = true
	
	print("🚀 Système de manches démarré!")

func _input(event):
	# Possibilité de redémarrer le jeu avec une touche (pour le debug)
	if event.is_action_pressed("ui_accept") and not game_started:
		start_game()

# Fonction pour retourner au menu principal (appelée depuis PauseMenu)
func return_to_main_menu():
	print("Retour au menu principal...")
	# Ici tu peux ajouter la logique pour changer de scène
	# get_tree().change_scene_to_file("res://MainMenu.tscn")
	
	# Pour l'instant, on quitte le jeu
	get_tree().quit() 