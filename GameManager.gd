extends Node

# Gestionnaire principal du jeu (Singleton)
var game_started = false

# Référence à l'écran de Game Over
var game_over_screen: CanvasLayer = null

# Système de pièces
var coins = 0
signal coins_changed(new_amount)

func _ready():
	# Précharger et instancier l'écran de Game Over
	setup_game_over_screen()
	
	# Attendre un peu que tout soit initialisé
	await get_tree().create_timer(1.0).timeout
	start_game()

func setup_game_over_screen():
	# Précharger la scène de Game Over
	var game_over_scene = preload("res://UI/GameOverScreen.tscn")
	game_over_screen = game_over_scene.instantiate()
	
	# Ajouter l'écran de Game Over à la scène actuelle
	get_tree().current_scene.add_child(game_over_screen)
	
	# Connecter le signal de Game Over du WaveManager
	if WaveManager:
		WaveManager.game_over.connect(_on_game_over)
		print("Écran de Game Over connecté au WaveManager")
	else:
		print("Erreur: WaveManager non trouvé pour la connexion Game Over")

func start_game():
	print("🎮 Démarrage du jeu...")
	
	# Pièces temporaires pour test le shield
	coins = 0  
	coins_changed.emit(coins)
	print("💰 Pièces de départ: ", coins)
	
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

# Fonction pour ajouter des pièces
func add_coins(amount: int):
	coins += amount
	coins_changed.emit(coins)

# Fonction pour obtenir le nombre de pièces
func get_coins() -> int:
	return coins

# Fonction appelée quand le Game Over est déclenché
func _on_game_over(zombies_killed: int, waves_completed: int):
	print("Game Over détecté avec " + str(zombies_killed) + " zombies tués et " + str(waves_completed) + " manches terminées")
	
	# Afficher l'écran de Game Over
	if game_over_screen:
		game_over_screen.show_game_over(zombies_killed, waves_completed)
		
		# Jouer le son de game over depuis le WaveManager
		if WaveManager and WaveManager.game_over_sound:
			WaveManager.game_over_sound.play()
			print("💀 Son de game over joué depuis GameManager")
	else:
		print("Erreur: Écran de Game Over non trouvé")

func _input(event):
	# Possibilité de redémarrer le jeu avec une touche (pour le debug)
	if event.is_action_pressed("ui_accept") and not game_started:
		start_game()

# Fonction pour retourner au menu principal (appelée depuis PauseMenu)
func return_to_main_menu():
	print("Retour au menu principal...")
	
	# Nettoyer le WaveManager avant de changer de scène
	if WaveManager:
		WaveManager.cleanup()
	
	# Reprendre le jeu au cas où il serait en pause
	get_tree().paused = false
	
	# Retourner au menu principal
	get_tree().change_scene_to_file("res://main_screen/main_menu.tscn") 