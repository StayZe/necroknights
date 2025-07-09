extends Area2D
class_name AudioZone

# Configuration de la zone audio
@export var audio_stream: AudioStream  # Le son à jouer (à assigner dans l'inspecteur)
@export var volume_db: float = 0.0  # Volume de base (remis à 0 pour avoir priorité)
@export var fade_in_duration: float = 1.0  # Durée du fondu d'entrée
@export var fade_out_duration: float = 1.0  # Durée du fondu de sortie
@export var zone_name: String = "AudioZone"  # Nom de la zone pour le debug
@export var loop_audio: bool = true  # Pour faire une boucle du son
@export var restart_on_reenter: bool = true  # Redémarrer le son à chaque entrée

# Composants audio
@onready var audio_player: AudioStreamPlayer2D
@onready var collision_shape: CollisionShape2D

# Variables d'état
var is_player_inside: bool = false
var current_fade_tween: Tween
var target_volume: float

func _ready():
	# Créer et configurer l'AudioStreamPlayer2D
	audio_player = AudioStreamPlayer2D.new()
	add_child(audio_player)
	
	# Configuration du lecteur audio
	audio_player.stream = audio_stream
	audio_player.volume_db = -80.0  # Commencer silencieux
	audio_player.autoplay = false
	
	# Configurer le loop si un AudioStreamWAV
	if audio_stream is AudioStreamWAV and loop_audio:
		audio_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		print("DEBUG - Audio configuré en loop")
	elif audio_stream is AudioStreamOggVorbis and loop_audio:
		audio_stream.loop = true
		print("DEBUG - Audio OGG configuré en loop")
	
	# S'assurer que la zone de collision est activée
	monitoring = true
	monitorable = true
	
	# Connecter les signaux de collision
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
	
	# S'enregistrer auprès du gestionnaire de zones audio
	if get_node_or_null("/root/AudioZoneManager"):
		AudioZoneManager.register_zone(self)
	
	# Ajouter au groupe des zones audio
	add_to_group("audio_zones")
	
	print("Zone audio initialisée: " + zone_name)
	print("DEBUG - Audio stream assigné: " + str(audio_stream))
	print("DEBUG - Volume configuré: " + str(volume_db))
	print("DEBUG - Position de la zone: " + str(global_position))
	print("DEBUG - Monitoring activé: " + str(monitoring))
	print("DEBUG - Loop activé: " + str(loop_audio))
	
	# Timer pour vérifier la distance du joueur
	var distance_timer = Timer.new()
	distance_timer.wait_time = 3.0
	distance_timer.timeout.connect(_check_player_distance)
	add_child(distance_timer)
	distance_timer.start()

# Fonction pour vérifier si le joueur est dans la zone (pour debug)
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_F8:
		check_player_in_zone()

func check_player_in_zone():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		print("=== DEBUG ZONE AUDIO ===")
		print("Joueur trouvé: " + str(player.name))
		print("Position joueur: " + str(player.global_position))
		print("Position zone: " + str(global_position))
		print("Zone monitoring: " + str(monitoring))
		print("Joueur dans zone: " + str(is_player_inside))
		
		# Vérifier si le joueur est géométriquement dans la zone
		var space_state = get_world_2d().direct_space_state
		var point_params = PhysicsPointQueryParameters2D.new()
		point_params.position = player.global_position
		point_params.collision_mask = 1  # Adapter selon vos layers
		var result = space_state.intersect_point(point_params)
		
		print("Collisions détectées au point joueur: " + str(result.size()))
		for collision in result:
			print("  - " + str(collision.collider.name))
		print("========================")
	else:
		print("DEBUG - Aucun joueur trouvé dans le groupe 'player'")

func _on_body_entered(body):
	print("DEBUG - Corpo entré dans zone: " + str(body.name) + " (groupes: " + str(body.get_groups()) + ")")
	print("DEBUG - Position body: " + str(body.global_position))
	print("DEBUG - Position zone: " + str(global_position))
	
	if body.is_in_group("player"):
		if restart_on_reenter or not is_player_inside:
			is_player_inside = true
			print("🎵 JOUEUR ENTRÉ DANS LA ZONE: " + zone_name)
			print("DEBUG - Audio Stream: " + str(audio_stream))
			print("DEBUG - Volume configuré: " + str(volume_db))
			
			# Toujours redémarrer le son si restart_on_reenter est activé
			if restart_on_reenter and audio_player.playing:
				print("DEBUG - Redémarrage du son (restart_on_reenter)")
				audio_player.stop()
			
			# Notifier le gestionnaire de zones
			if get_node_or_null("/root/AudioZoneManager"):
				AudioZoneManager.player_entered_zone(self)
			else:
				# Fallback si pas de gestionnaire
				print("DEBUG - Pas de gestionnaire, lancement direct")
				start_audio()
		else:
			print("DEBUG - Joueur déjà dans la zone, pas de redémarrage")

func _on_body_exited(body):
	print("DEBUG - Corpo sorti de zone: " + str(body.name))
	
	if body.is_in_group("player") and is_player_inside:
		is_player_inside = false
		print("🎵 JOUEUR SORTI DE LA ZONE: " + zone_name)
		
		# Notifier le gestionnaire de zones
		if get_node_or_null("/root/AudioZoneManager"):
			AudioZoneManager.player_exited_zone(self)
		else:
			# Fallback si pas de gestionnaire
			stop_audio()

# Démarrer la lecture audio avec fondu
func start_audio():
	print("DEBUG - Tentative de démarrage audio...")
	print("DEBUG - audio_stream: " + str(audio_stream))
	print("DEBUG - audio_player: " + str(audio_player))
	
	if not audio_stream:
		print("Attention: Aucun audio stream assigné à la zone " + zone_name)
		return
	
	# Arrêter le tween précédent s'il existe
	if current_fade_tween:
		current_fade_tween.kill()
	
	# TOUJOURS redémarrer la lecture pour garantir le son
	if audio_player.playing:
		audio_player.stop()
	
	print("DEBUG - Démarrage de la lecture audio...")
	audio_player.play()
	print("DEBUG - Audio player playing: " + str(audio_player.playing))
	
	# Créer le fondu d'entrée
	current_fade_tween = create_tween()
	current_fade_tween.tween_property(audio_player, "volume_db", volume_db, fade_in_duration)
	
	print("Audio démarré dans la zone: " + zone_name + " (volume target: " + str(volume_db) + ")")
	print("🔊 SON DE ZONE ACTIVÉ!")

# Arrêter la lecture audio avec fondu
func stop_audio():
	if not audio_player.playing:
		return
	
	# Arrêter le tween précédent s'il existe
	if current_fade_tween:
		current_fade_tween.kill()
	
	# Créer le fondu de sortie
	current_fade_tween = create_tween()
	current_fade_tween.tween_property(audio_player, "volume_db", -80.0, fade_out_duration)
	
	# Arrêter la lecture après le fondu
	current_fade_tween.tween_callback(func(): audio_player.stop())
	
	print("Audio arrêté dans la zone: " + zone_name)
	print("🔇 SON DE ZONE DÉSACTIVÉ!")

# Fonction pour changer le volume avec fondu
func fade_to_volume(new_volume: float, duration: float = 1.0):
	if current_fade_tween:
		current_fade_tween.kill()
	
	current_fade_tween = create_tween()
	current_fade_tween.tween_property(audio_player, "volume_db", new_volume, duration)

# Fonction pour forcer l'arrêt immédiat
func force_stop():
	if current_fade_tween:
		current_fade_tween.kill()
	
	audio_player.stop()
	audio_player.volume_db = -80.0

# Getters pour le gestionnaire
func get_audio_player() -> AudioStreamPlayer2D:
	return audio_player

func get_zone_name() -> String:
	return zone_name

func is_playing() -> bool:
	return audio_player.playing if audio_player else false 

func _check_player_distance():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var distance = global_position.distance_to(player.global_position)
		print("🎯 Distance joueur ↔ zone: " + str(int(distance)) + " pixels")
		print("   Joueur: " + str(player.global_position))
		print("   Zone:   " + str(global_position))
		
		if distance > 300:
			print("⚠️  ZONE TROP LOIN ! Rapprochez la zone du joueur")
		elif distance < 100:
			print("✅ Zone bien positionnée")
			# Test de collision forcée si proche
			if distance < 50 and not is_player_inside:
				print("🔥 FORÇAGE COLLISION - Joueur très proche mais pas détecté!")
				# Simuler l'entrée du joueur
				_on_body_entered(player)
	else:
		print("❌ Joueur non trouvé") 
