extends Node

# Singleton pour gérer le système de manches infinies
signal wave_started(wave_number)
signal wave_completed(wave_number)
signal wave_break_started(time_left)
signal wave_break_updated(time_left)
signal new_record(wave_number)
signal game_over(zombies_killed, waves_completed)

# Variables d'état
var current_wave: int = 0
var is_wave_active: bool = false
var is_on_break: bool = false
var zombies_remaining: int = 0
var zombies_spawned: int = 0
var total_zombies_in_wave: int = 0

# Statistiques de jeu
var total_zombies_killed: int = 0

# Système de records
var max_wave_completed: int = 0
var save_file_path = "user://necroknights_save.dat"

# Références
var player: Player = null
var spawners: Array[ZombieSpawner] = []
var break_timer: Timer
var game_over_screen: CanvasLayer = null

# Son de début de manche
var wave_start_sound: AudioStreamPlayer
var wave_sound_timer: Timer

# Son d'ambiance de fond
var background_ambient_sound: AudioStreamPlayer

# Son de game over
var game_over_sound: AudioStreamPlayer

# Constantes
const BREAK_DURATION = 20.0
const STARTING_ZOMBIES = 10
const ZOMBIES_INCREMENT = 5
const WAVE_SOUND_DURATION = 7.0  # Durée en secondes pour le son de début de manche

func _ready():
	# Créer le timer pour les pauses
	break_timer = Timer.new()
	break_timer.wait_time = 1.0  # Update chaque seconde
	break_timer.timeout.connect(_on_break_timer_update)
	add_child(break_timer)
	
	# Créer et configurer le son de début de manche
	wave_start_sound = AudioStreamPlayer.new()
	add_child(wave_start_sound)
	wave_start_sound.stream = preload("res://songs/starting-round-zombie-sound.wav")
	wave_start_sound.volume_db = -10  # Ajuster le volume si nécessaire
	
	# Créer et configurer le son d'ambiance de fond
	background_ambient_sound = AudioStreamPlayer.new()
	add_child(background_ambient_sound)
	background_ambient_sound.stream = preload("res://songs/horror-ambiant-song.wav")
	background_ambient_sound.volume_db = -5  # Volume plus faible pour l'ambiance
	background_ambient_sound.autoplay = true  # Démarrer automatiquement
	background_ambient_sound.bus = "Master"  # Utiliser le bus principal
	
	# Connecter le signal finished pour créer une boucle manuelle
	background_ambient_sound.finished.connect(_on_background_ambient_finished)
	
	# Créer et configurer le son de game over
	game_over_sound = AudioStreamPlayer.new()
	add_child(game_over_sound)
	game_over_sound.stream = preload("res://songs/8-bit-game-over-sound-effect-331435.mp3")
	game_over_sound.volume_db = -5  # Volume pour le son de game over
	
	# Créer le timer pour contrôler la durée de lecture du son
	wave_sound_timer = Timer.new()
	wave_sound_timer.wait_time = WAVE_SOUND_DURATION
	wave_sound_timer.timeout.connect(_on_wave_sound_finished)
	add_child(wave_sound_timer)
	
	# Charger le record
	load_save_data()
	
	print("WaveManager initialisé - Système de manches infinies")
	print("Record actuel: " + str(max_wave_completed) + " manches")

# Calculer le nombre de zombies pour une manche donnée
func get_zombies_for_wave(wave_number: int) -> int:
	return STARTING_ZOMBIES + (wave_number - 1) * ZOMBIES_INCREMENT

# Calculer l'intervalle de spawn selon le nombre de zombies
func get_spawn_interval_for_zombies(zombie_count: int) -> float:
	if zombie_count <= 50:
		return 5.0  # 10-50 zombies: 5s
	elif zombie_count <= 100:
		return 3.0  # 50-100 zombies: 3s
	else:
		return 1.0  # 100+ zombies: 1s

# Démarrer le système de manches
func start_waves():
	if spawners.is_empty():
		print("Erreur: Aucun spawner enregistré!")
		return
	
	if not player:
		print("Erreur: Aucun joueur enregistré!")
		return
	
	# S'assurer que le son d'ambiance se joue
	if background_ambient_sound and not background_ambient_sound.playing:
		background_ambient_sound.play()
		print("🎵 Son d'ambiance démarré")
	
	current_wave = 0
	start_next_wave()

# Enregistrer un spawner
func register_spawner(spawner: ZombieSpawner):
	if spawner not in spawners:
		spawners.append(spawner)
		spawner.zombie_died.connect(_on_zombie_died)
		print("Spawner enregistré. Total: " + str(spawners.size()))

# Enregistrer le joueur
func register_player(p: Player):
	player = p
	print("Joueur enregistré dans WaveManager")

# Nettoyer les références lors d'un changement de scène
func cleanup():
	# Arrêter tous les timers
	if break_timer:
		break_timer.stop()
	
	if wave_sound_timer:
		wave_sound_timer.stop()
	
	# Arrêter le son d'ambiance
	if background_ambient_sound:
		background_ambient_sound.stop()
	
	# Arrêter le son de game over
	if game_over_sound:
		game_over_sound.stop()
	
	# Nettoyer les références des spawners
	for spawner in spawners:
		if is_instance_valid(spawner) and spawner.zombie_died.is_connected(_on_zombie_died):
			spawner.zombie_died.disconnect(_on_zombie_died)
	
	spawners.clear()
	player = null
	
	# Réinitialiser l'état du jeu
	current_wave = 0
	is_wave_active = false
	is_on_break = false
	zombies_remaining = 0
	zombies_spawned = 0
	total_zombies_in_wave = 0
	
	print("WaveManager nettoyé et réinitialisé")

# Vérifier si les spawners sont encore valides
func cleanup_invalid_spawners():
	var valid_spawners: Array[ZombieSpawner] = []
	for spawner in spawners:
		if is_instance_valid(spawner):
			valid_spawners.append(spawner)
		else:
			print("Spawner invalide retiré")
	spawners = valid_spawners

# Démarrer la prochaine manche
func start_next_wave():
	# Nettoyer les spawners invalides avant de commencer
	cleanup_invalid_spawners()
	
	if spawners.is_empty():
		print("Erreur: Aucun spawner valide!")
		return
	
	# Nettoyer tous les drops au sol avant de commencer la nouvelle manche
	cleanup_drops_on_ground()
	
	current_wave += 1
	
	# Jouer le son de début de manche
	if wave_start_sound:
		wave_start_sound.play()
		wave_sound_timer.start()
	
	# Calculer les paramètres de la manche
	total_zombies_in_wave = get_zombies_for_wave(current_wave)
	var spawn_interval = get_spawn_interval_for_zombies(total_zombies_in_wave)
	
	zombies_remaining = total_zombies_in_wave
	zombies_spawned = 0
	is_wave_active = true
	is_on_break = false
	
	# Distribuer les zombies entre les spawners
	if spawners.size() > 0:
		var zombies_per_spawner = int(total_zombies_in_wave / spawners.size())
		var remaining_zombies = total_zombies_in_wave % spawners.size()
		
		for i in range(spawners.size()):
			var spawner = spawners[i]
			if is_instance_valid(spawner):
				var quota = zombies_per_spawner
				if i < remaining_zombies:
					quota += 1  # Donner un zombie supplémentaire aux premiers spawners
				spawner.setup_for_wave(spawn_interval, quota, current_wave)
			else:
				print("Spawner invalide détecté à l'index " + str(i))
	
	wave_started.emit(current_wave)
	print("🌊 Manche " + str(current_wave) + " - " + str(total_zombies_in_wave) + " zombies (intervalle: " + str(spawn_interval) + "s)")

# Appelé quand un zombie est tué
func _on_zombie_died():
	if is_wave_active:
		zombies_remaining -= 1
		total_zombies_killed += 1
		print("Zombie tué! Restants: " + str(zombies_remaining) + " | Total tués: " + str(total_zombies_killed))
		
		if zombies_remaining <= 0:
			complete_current_wave()

# Terminer la manche actuelle
func complete_current_wave():
	is_wave_active = false
	wave_completed.emit(current_wave)
	print("✅ Manche " + str(current_wave) + " terminée!")
	
	# Vérifier si c'est un nouveau record
	if current_wave > max_wave_completed:
		max_wave_completed = current_wave
		save_save_data()
		new_record.emit(current_wave)
		print("🏆 Nouveau record: " + str(current_wave) + " manches!")
	
	# Arrêter tous les spawners valides
	for spawner in spawners:
		if is_instance_valid(spawner):
			spawner.stop_spawning()
	
	# Démarrer la pause avant la prochaine manche
	start_wave_break()

# Démarrer la pause entre les manches
func start_wave_break():
	is_on_break = true
	
	# Régénérer la santé du joueur
	if player:
		player.health = player.max_health
		player.update_health_display()
		print("💚 Santé du joueur régénérée à 100%")
	
	# Démarrer le timer de pause
	var time_left = BREAK_DURATION
	wave_break_started.emit(time_left)
	break_timer.start()
	
	# Timer pour la fin de la pause
	await get_tree().create_timer(BREAK_DURATION).timeout
	break_timer.stop()
	start_next_wave()

# Mise à jour du timer de pause
func _on_break_timer_update():
	if is_on_break:
		var time_left = BREAK_DURATION - break_timer.wait_time * break_timer.time_left
		wave_break_updated.emit(int(BREAK_DURATION - time_left))

# Obtenir les informations de la manche actuelle
func get_current_wave_info() -> Dictionary:
	return {
		"wave": current_wave,
		"zombies_total": total_zombies_in_wave,
		"zombies_remaining": zombies_remaining,
		"zombies_spawned": zombies_spawned,
		"is_active": is_wave_active,
		"is_on_break": is_on_break,
		"max_wave_completed": max_wave_completed,
		"spawn_interval": get_spawn_interval_for_zombies(total_zombies_in_wave) if current_wave > 0 else 0.0
	}

# Notifier qu'un zombie a été spawné
func notify_zombie_spawned():
	if is_wave_active:
		zombies_spawned += 1

# Sauvegarder les données
func save_save_data():
	var save_file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if save_file:
		var save_data = {
			"max_wave_completed": max_wave_completed
		}
		save_file.store_string(JSON.stringify(save_data))
		save_file.close()
		print("Données sauvegardées: record " + str(max_wave_completed))

# Charger les données sauvegardées
func load_save_data():
	var save_file = FileAccess.open(save_file_path, FileAccess.READ)
	if save_file:
		var json_string = save_file.get_as_text()
		save_file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var save_data = json.data
			max_wave_completed = save_data.get("max_wave_completed", 0)
			print("Données chargées: record " + str(max_wave_completed))
		else:
			print("Erreur lors du chargement des données")
	else:
		print("Aucune sauvegarde trouvée")

# Réinitialiser le record (pour debug)
func reset_record():
	max_wave_completed = 0
	save_save_data()
	print("Record réinitialisé")

# Obtenir une description de la manche actuelle
func get_wave_description() -> String:
	if current_wave == 0:
		return "En attente..."
	
	var zombies = get_zombies_for_wave(current_wave)
	var interval = get_spawn_interval_for_zombies(zombies)
	
	var difficulty = ""
	if zombies <= 50:
		difficulty = "Facile"
	elif zombies <= 100:
		difficulty = "Moyen"
	else:
		difficulty = "Difficile"
	
	return difficulty + " (" + str(interval) + "s/spawn)" 

# Fonction appelée quand le joueur meurt
func trigger_game_over():
	# Arrêter le jeu
	is_wave_active = false
	is_on_break = false
	
	# Arrêter tous les spawners
	for spawner in spawners:
		if is_instance_valid(spawner):
			spawner.stop_spawning()
	
	# Arrêter le timer de pause s'il est actif
	if break_timer:
		break_timer.stop()
	
	# Arrêter le timer du son s'il est actif
	if wave_sound_timer:
		wave_sound_timer.stop()
	
	# Arrêter le son d'ambiance
	if background_ambient_sound:
		background_ambient_sound.stop()
	
	# Le son de game over sera joué par le GameManager après l'affichage de l'écran
	
	# Calculer le nombre de manches complètement terminées
	var completed_waves = max(0, current_wave - 1)
	
	# Émettre le signal de Game Over
	game_over.emit(total_zombies_killed, completed_waves)
	
	print("🔴 GAME OVER - Zombies tués: " + str(total_zombies_killed) + ", Manches terminées: " + str(completed_waves))

# Obtenir les statistiques actuelles
func get_game_stats() -> Dictionary:
	return {
		"zombies_killed": total_zombies_killed,
		"waves_completed": max(0, current_wave - 1),
		"current_wave": current_wave,
		"max_wave_record": max_wave_completed
	} 

# Nettoyer tous les drops (pièces et bonus) qui traînent au sol
func cleanup_drops_on_ground():
	var drops = get_tree().get_nodes_in_group("drops")
	var drops_count = drops.size()
	
	if drops_count > 0:
		print("🧹 Nettoyage de " + str(drops_count) + " drops au sol avant la manche " + str(current_wave + 1))
		
		for drop in drops:
			if is_instance_valid(drop):
				# Créer un petit effet de disparition pour que ce soit visuel
				var tween = drop.create_tween()
				tween.parallel().tween_property(drop, "scale", Vector2(0.5, 0.5), 0.3)
				tween.parallel().tween_property(drop, "modulate:a", 0.0, 0.3)
				
				# Supprimer le drop après l'effet
				tween.finished.connect(drop.queue_free)
		
		print("✨ Drops nettoyés - Place nette pour la nouvelle manche !")
	else:
		print("✅ Aucun drop à nettoyer") 

# Fonctions pour contrôler le son d'ambiance de fond
func start_background_ambient():
	if background_ambient_sound and not background_ambient_sound.playing:
		background_ambient_sound.play()

func stop_background_ambient():
	if background_ambient_sound and background_ambient_sound.playing:
		background_ambient_sound.stop()

func set_background_ambient_volume(volume_db: float):
	if background_ambient_sound:
		background_ambient_sound.volume_db = volume_db

# Fonction appelée quand le son de début de manche est terminé
func _on_wave_sound_finished():
	if wave_start_sound:
		wave_start_sound.stop()
	wave_sound_timer.stop() 

# Fonction appelée quand le son d'ambiance est terminé
func _on_background_ambient_finished():
	if background_ambient_sound:
		background_ambient_sound.play()
		print("🔄 Son d'ambiance relancé (boucle)") 
