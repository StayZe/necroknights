extends Node

# Gestionnaire global pour les zones audio
# Ce script doit être ajouté en tant qu'Autoload dans le projet

var registered_zones: Array[AudioZone] = []
var current_active_zone: AudioZone = null
var zones_player_is_in: Array[AudioZone] = []

# Paramètres globaux
var global_fade_duration: float = 1.0
var volume_reduction_factor: float = 0.5  # Facteur de réduction du volume lors des transitions

func _ready():
	print("AudioZoneManager initialisé")

# Enregistrer une zone audio
func register_zone(zone: AudioZone):
	if zone not in registered_zones:
		registered_zones.append(zone)
		print("Zone audio enregistrée: " + zone.get_zone_name())

# Désenregistrer une zone audio
func unregister_zone(zone: AudioZone):
	if zone in registered_zones:
		registered_zones.erase(zone)
		if zone == current_active_zone:
			current_active_zone = null
		if zone in zones_player_is_in:
			zones_player_is_in.erase(zone)
		print("Zone audio désenregistrée: " + zone.get_zone_name())

# Appelé quand le joueur entre dans une zone
func player_entered_zone(zone: AudioZone):
	if zone not in zones_player_is_in:
		zones_player_is_in.append(zone)
		print("Joueur entré dans: " + zone.get_zone_name() + " (Total zones: " + str(zones_player_is_in.size()) + ")")
		
		# Déterminer quelle zone doit être active
		update_active_zone()

# Appelé quand le joueur sort d'une zone
func player_exited_zone(zone: AudioZone):
	if zone in zones_player_is_in:
		zones_player_is_in.erase(zone)
		print("Joueur sorti de: " + zone.get_zone_name() + " (Total zones: " + str(zones_player_is_in.size()) + ")")
		
		# Déterminer quelle zone doit être active
		update_active_zone()

# Mettre à jour la zone active
func update_active_zone():
	var new_active_zone: AudioZone = null
	
	# Prioriser la zone la plus récemment entrée
	if zones_player_is_in.size() > 0:
		new_active_zone = zones_player_is_in[-1]  # Dernière zone entrée
	
	# Si la zone active a changé
	if new_active_zone != current_active_zone:
		transition_to_zone(new_active_zone)

# Transition vers une nouvelle zone
func transition_to_zone(new_zone: AudioZone):
	var previous_zone = current_active_zone
	current_active_zone = new_zone
	
	print("Transition audio: " + 
		(previous_zone.get_zone_name() if previous_zone else "Silence") + 
		" → " + 
		(new_zone.get_zone_name() if new_zone else "Silence"))
	
	# Cas 1: Pas de zone précédente, juste démarrer la nouvelle
	if not previous_zone and new_zone:
		new_zone.start_audio()
	
	# Cas 2: Pas de nouvelle zone, juste arrêter l'ancienne
	elif previous_zone and not new_zone:
		previous_zone.stop_audio()
	
	# Cas 3: Transition entre deux zones
	elif previous_zone and new_zone:
		# Créer un fondu croisé
		create_crossfade(previous_zone, new_zone)
	
	# Cas 4: Aucune zone (ne devrait pas arriver dans update_active_zone)
	else:
		print("Aucune transition nécessaire")

# Créer un fondu croisé entre deux zones
func create_crossfade(from_zone: AudioZone, to_zone: AudioZone):
	var fade_duration = min(from_zone.fade_out_duration, to_zone.fade_in_duration)
	fade_duration = min(fade_duration, global_fade_duration)
	
	print("Fondu croisé sur " + str(fade_duration) + " secondes")
	
	# Démarrer la nouvelle zone au volume réduit
	if not to_zone.get_audio_player().playing:
		to_zone.get_audio_player().play()
	
	# Faire un fondu croisé
	var tween = create_tween()
	tween.set_parallel(true)  # Permettre les animations parallèles
	
	# Fondu sortant de l'ancienne zone
	tween.tween_property(from_zone.get_audio_player(), "volume_db", -80.0, fade_duration)
	
	# Fondu entrant de la nouvelle zone
	tween.tween_property(to_zone.get_audio_player(), "volume_db", to_zone.volume_db, fade_duration)
	
	# Arrêter l'ancienne zone après le fondu
	tween.tween_callback(func(): from_zone.get_audio_player().stop()).set_delay(fade_duration)

# Arrêter toutes les zones audio
func stop_all_zones():
	for zone in registered_zones:
		zone.force_stop()
	
	current_active_zone = null
	zones_player_is_in.clear()
	print("Toutes les zones audio arrêtées")

# Définir la durée de fondu globale
func set_global_fade_duration(duration: float):
	global_fade_duration = duration
	print("Durée de fondu globale définie à: " + str(duration) + " secondes")

# Obtenir des informations sur l'état actuel
func get_current_zone_info() -> Dictionary:
	return {
		"active_zone": current_active_zone.get_zone_name() if current_active_zone else "Aucune",
		"zones_player_is_in": zones_player_is_in.map(func(z): return z.get_zone_name()),
		"total_registered_zones": registered_zones.size()
	}

# Debug: Afficher l'état actuel
func debug_print_status():
	var info = get_current_zone_info()
	print("=== État AudioZoneManager ===")
	print("Zone active: " + info.active_zone)
	print("Zones où le joueur est présent: " + str(info.zones_player_is_in))
	print("Total zones enregistrées: " + str(info.total_registered_zones))
	print("============================")

# Fonction pour tester manuellement les transitions
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F9:  # Touche F9 pour debug
			debug_print_status() 