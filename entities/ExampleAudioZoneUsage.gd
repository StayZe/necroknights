extends Node

# Exemple d'utilisation du système de zones audio
# Ce script montre comment intégrer les zones audio dans votre jeu

# Référence pour créer les zones
@onready var map_node: Node = get_parent()  # Ou votre nœud de map principal

func _ready():
	# Attendre que tous les nœuds soient prêts
	await get_tree().process_frame
	
	# Créer les zones audio pour votre map
	setup_audio_zones()

# Configuration des zones audio pour votre map
func setup_audio_zones():
	print("Configuration des zones audio...")
	
	# Exemple 1: Zones créées manuellement
	create_combat_zones()
	
	# Exemple 2: Zones créées depuis une configuration
	create_zones_from_config()
	
	# Exemple 3: Zones créées dynamiquement selon les waves
	# setup_dynamic_zones()

# Créer des zones pour les combats
func create_combat_zones():
	# Zone de combat principale
	var combat_zone = AudioZoneCreator.create_audio_zone(
		map_node,
		"CombatZone",
		Vector2(0, 0),          # Position au centre
		Vector2(800, 600),      # Taille de la zone
		load("res://songs/combat_music.ogg"),  # Musique de combat
		-3.0,                   # Volume un peu fort
		1.5,                    # Fondu d'entrée
		1.0                     # Fondu de sortie
	)
	
	# Zone d'ambiance calme
	var peaceful_zone = AudioZoneCreator.create_circular_audio_zone(
		map_node,
		"PeacefulZone",
		Vector2(1000, 0),       # Position à droite
		150.0,                  # Rayon
		load("res://songs/peaceful_ambience.ogg"),
		-8.0,                   # Volume plus doux
		2.0,                    # Fondu d'entrée lent
		2.0                     # Fondu de sortie lent
	)

# Créer des zones depuis une configuration
func create_zones_from_config():
	var zones_config = [
		{
			"name": "SpawnZone1",
			"position": Vector2(-200, -200),
			"size": Vector2(150, 150),
			"audio_path": "res://songs/spawn_area.ogg",
			"volume_db": -10.0,
			"fade_in_duration": 1.0,
			"fade_out_duration": 0.5
		},
		{
			"name": "SpawnZone2", 
			"position": Vector2(200, -200),
			"size": Vector2(150, 150),
			"audio_path": "res://songs/spawn_area.ogg",
			"volume_db": -10.0,
			"fade_in_duration": 1.0,
			"fade_out_duration": 0.5
		},
		{
			"name": "BossZone",
			"position": Vector2(0, -400),
			"size": Vector2(300, 200),
			"audio_path": "res://songs/boss_music.ogg",
			"volume_db": 0.0,
			"fade_in_duration": 2.0,
			"fade_out_duration": 1.5
		}
	]
	
	# Créer toutes les zones
	for config in zones_config:
		AudioZoneCreator.create_zone_from_dict(map_node, config)

# Exemple de zones dynamiques selon les waves
func setup_dynamic_zones():
	# S'abonner aux signaux du WaveManager
	if WaveManager:
		WaveManager.wave_started.connect(_on_wave_started)
		WaveManager.wave_completed.connect(_on_wave_completed)

func _on_wave_started(wave_number: int):
	# Créer une zone de musique intense pour les waves élevées
	if wave_number >= 10:
		var intense_zone = AudioZoneCreator.create_audio_zone(
			map_node,
			"IntenseWave_" + str(wave_number),
			Vector2(0, 0),
			Vector2(1000, 800),
			load("res://songs/intense_combat.ogg"),
			-2.0,
			1.0,
			1.0
		)
		
		# Programmer la suppression de la zone après 30 secondes
		await get_tree().create_timer(30.0).timeout
		if intense_zone:
			intense_zone.queue_free()

func _on_wave_completed(wave_number: int):
	# Créer une zone de répit entre les waves
	var rest_zone = AudioZoneCreator.create_audio_zone(
		map_node,
		"RestZone_" + str(wave_number),
		Vector2(0, 0),
		Vector2(600, 400),
		load("res://songs/rest_music.ogg"),
		-5.0,
		0.5,
		0.5
	)
	
	# Supprimer la zone après 20 secondes (durée de la pause)
	await get_tree().create_timer(20.0).timeout
	if rest_zone:
		rest_zone.queue_free()

# Exemple d'utilisation avancée : zones qui réagissent aux événements
func setup_reactive_zones():
	# Zones qui changent selon la santé du joueur
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Surveiller la santé du joueur
		create_health_reactive_zone(player)

func create_health_reactive_zone(player: Player):
	# Zone qui devient plus intense quand la santé est faible
	var danger_zone = AudioZoneCreator.create_audio_zone(
		map_node,
		"DangerZone",
		Vector2(0, 0),
		Vector2(400, 400),
		load("res://songs/danger_music.ogg"),
		-15.0,  # Très faible au début
		1.0,
		1.0
	)
	
	# Créer un timer pour vérifier la santé
	var health_timer = Timer.new()
	health_timer.wait_time = 0.5  # Vérifier toutes les 0.5 secondes
	health_timer.timeout.connect(func(): check_player_health(player, danger_zone))
	add_child(health_timer)
	health_timer.start()

func check_player_health(player: Player, danger_zone: AudioZone):
	if not player or not danger_zone:
		return
	
	# Ajuster le volume selon la santé
	var health_ratio = player.health / player.max_health
	var target_volume = lerp(0.0, -15.0, health_ratio)  # Plus la santé est faible, plus c'est fort
	
	# Appliquer le changement de volume
	danger_zone.fade_to_volume(target_volume, 0.3)

# Fonctions utilitaires pour le debug
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F10:
				# Créer une zone de test
				test_create_zone()
			KEY_F11:
				# Supprimer toutes les zones
				clear_all_zones()
			KEY_F12:
				# Afficher les infos des zones
				AudioZoneManager.debug_print_status()

func test_create_zone():
	var test_zone = AudioZoneCreator.create_audio_zone(
		map_node,
		"TestZone",
		Vector2(randf_range(-300, 300), randf_range(-300, 300)),
		Vector2(100, 100),
		null,  # Pas de son pour le test
		0.0,
		1.0,
		1.0
	)
	print("Zone de test créée à la position: " + str(test_zone.position))

func clear_all_zones():
	var zones = get_tree().get_nodes_in_group("audio_zones")
	for zone in zones:
		zone.queue_free()
	print("Toutes les zones audio supprimées (" + str(zones.size()) + " zones)")

# Exemple d'intégration avec le GameManager
func integrate_with_game_manager():
	# Si vous avez un GameManager, vous pouvez l'utiliser
	if GameManager:
		# Créer des zones selon l'état du jeu
		pass 
