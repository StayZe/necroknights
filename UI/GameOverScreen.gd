extends CanvasLayer

# Références aux éléments UI
@onready var zombies_killed_label = $GameOverPanel/VBoxContainer/StatsContainer/ZombiesKilledLabel
@onready var waves_completed_label = $GameOverPanel/VBoxContainer/StatsContainer/WavesCompletedLabel
@onready var return_button = $GameOverPanel/VBoxContainer/ReturnButton

func _ready():
	# Cacher l'écran au démarrage
	visible = false
	
	# Ajouter au groupe game_over pour la détection par le shop
	add_to_group("game_over")
	
	# Connecter le bouton de retour
	if return_button:
		return_button.pressed.connect(_on_return_button_pressed)

# Afficher l'écran de Game Over avec les statistiques
func show_game_over(zombies_killed: int, waves_completed: int):
	visible = true
	
	# Mettre à jour les statistiques
	if zombies_killed_label:
		zombies_killed_label.text = "Zombies tués: " + str(zombies_killed)
	
	if waves_completed_label:
		waves_completed_label.text = "Manches terminées: " + str(waves_completed)
	
	# Mettre le jeu en pause
	get_tree().paused = true
	
	print("Écran de Game Over affiché - Zombies: " + str(zombies_killed) + ", Manches: " + str(waves_completed))

# Fonction appelée quand le bouton retour est pressé
func _on_return_button_pressed():
	print("Retour au menu principal demandé")
	
	# Dépauser le jeu
	get_tree().paused = false
	
	# Appeler la fonction du GameManager pour retourner au menu
	if GameManager:
		GameManager.return_to_main_menu() 
