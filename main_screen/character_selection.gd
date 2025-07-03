extends Control

# Variables pour la sélection
var selected_player_id: int = -1

# Références aux nœuds
@onready var player_buttons: Array = []
@onready var player_labels: Array = []
@onready var play_button: Button
@onready var hover_sound: AudioStreamPlayer

# Information des joueurs
var player_data = [
	{"id": 1, "name": "Player 1", "sprite_path": "res://sprites/players/1.png"},
	{"id": 2, "name": "Player 2", "sprite_path": "res://sprites/players/2.png"},
	{"id": 3, "name": "Player 3", "sprite_path": "res://sprites/players/3.png"}
]

func _ready():
	print("Character selection initialized")
	
	# Récupérer les références aux nœuds
	play_button = $PlayButton
	hover_sound = $HoverSound
	
	# Initialiser les boutons des joueurs
	for i in range(3):
		var container = get_node("PlayersContainer/PlayerContainer" + str(i + 1))
		var button = container.get_node("PlayerButton")
		var label = container.get_node("PlayerLabel")
		
		player_buttons.append(button)
		player_labels.append(label)
		
		# Connecter les signaux pour chaque bouton
		button.mouse_entered.connect(_on_player_hover.bind(i + 1))
		button.mouse_exited.connect(_on_player_hover_exit.bind(i + 1))
		button.pressed.connect(_on_player_clicked.bind(i + 1))
		
		print("Connected player button ", i + 1)
	
	# Connecter le bouton play
	play_button.pressed.connect(_on_play_button_pressed)
	play_button.visible = false
	
	print("All connections ready")

func _on_player_hover(player_id: int):
	print("Hovering player: ", player_id)
	hover_sound.play()

func _on_player_hover_exit(player_id: int):
	print("Exiting player: ", player_id)

func _on_player_clicked(player_id: int):
	print("Player clicked: ", player_id)
	select_player(player_id)

func select_player(player_id: int):
	print("Selecting player: ", player_id)
	
	# Désélectionner l'ancien joueur
	if selected_player_id != -1:
		var old_label = player_labels[selected_player_id - 1]
		old_label.modulate = Color.WHITE
	
	# Sélectionner le nouveau joueur
	selected_player_id = player_id
	var label = player_labels[player_id - 1]
	
	# Mettre le label en évidence (jaune)
	var tween = create_tween()
	tween.tween_property(label, "modulate", Color(1.0, 1.0, 0.5), 0.2)
	
	# Afficher le bouton play
	play_button.visible = true
	play_button.modulate.a = 0.0
	var button_tween = create_tween()
	button_tween.tween_property(play_button, "modulate:a", 1.0, 0.3)

func _on_play_button_pressed():
	print("Play button pressed with player: ", selected_player_id)
	if selected_player_id != -1:
		# Sauvegarder le skin sélectionné dans le singleton
		PlayerSettings.selected_skin = selected_player_id
		print("Selected skin saved: ", PlayerSettings.selected_skin)
		
		# Lancer le jeu
		get_tree().change_scene_to_file("res://map.tscn") 