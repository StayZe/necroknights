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
		print("🔗 Connexion du bouton ReturnButton...")
		return_button.pressed.connect(_on_return_button_pressed)
		print("✅ Bouton ReturnButton connecté avec succès")
	else:
		print("❌ Erreur: return_button est null!")

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
	print("🎯 BOUTON QUIT CLIQUE - Fonction _on_return_button_pressed appelée!")
	
	# Dépauser le jeu
	get_tree().paused = false
	print("⏸️ Jeu dépausé")
	
	# Appeler la fonction du GameManager pour retourner au menu
	if GameManager:
		print("✅ GameManager trouvé, appel de return_to_main_menu()")
		GameManager.return_to_main_menu()
	else:
		print("❌ Erreur: GameManager non trouvé!")
		print("🔄 Tentative de fallback vers le menu principal...")
		# Fallback: retourner directement au menu principal
		get_tree().change_scene_to_file("res://main_screen/main_menu.tscn")
		print("📱 Changement de scène vers main_menu.tscn effectué") 

# Fonction alternative pour gérer les inputs si le signal ne fonctionne pas
func _input(event):
	if visible and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Vérifier si le clic est sur le bouton
			if return_button and return_button.get_global_rect().has_point(event.global_position):
				print("🖱️ Clic détecté sur le bouton via _input")
				_on_return_button_pressed() 
