extends Node2D
class_name ZombieSpawner

# Signaux
signal zombie_died()

@export var zombie_basic_scene: PackedScene = preload("res://entities/Zombie.tscn")
@export var zombie_heavy_scene: PackedScene = preload("res://entities/ZombieHeavy.tscn")
@export var zombie_arabic_scene: PackedScene = preload("res://entities/ZombieArabic.tscn")
@export var spawn_distance: float = 30.0  # Distance d'activation du spawn

@onready var cooldown_timer = $CooldownTimer
@onready var detection_area = $DetectionArea

var player = null
var spawned_zombies = 0
var can_spawn = true

# Variables pour le système de manches
var is_active_for_wave = false
var zombies_quota_for_wave = 0
var zombies_spawned_this_wave = 0
var wave_spawn_interval = 3.0
var current_wave_number = 1

func _ready():
	# S'enregistrer auprès du WaveManager si il existe
	if get_node_or_null("/root/WaveManager"):
		WaveManager.register_spawner(self)
	
	cooldown_timer.wait_time = wave_spawn_interval

func _process(_delta):
	# Ne spawner que si:
	# 1. Le joueur est détecté
	# 2. Le spawner est actif pour la manche
	# 3. On peut spawner (cooldown)
	# 4. On n'a pas atteint le quota pour cette manche
	if player != null and is_active_for_wave and can_spawn and zombies_spawned_this_wave < zombies_quota_for_wave:
		spawn_zombie()

# Configuration pour une nouvelle manche
func setup_for_wave(spawn_interval: float, total_zombies: int, wave_number: int = 1):
	wave_spawn_interval = spawn_interval
	zombies_quota_for_wave = total_zombies
	zombies_spawned_this_wave = 0
	is_active_for_wave = true
	can_spawn = true
	current_wave_number = wave_number
	
	# Mettre à jour le timer
	cooldown_timer.wait_time = wave_spawn_interval
	
	print("Spawner configuré - Manche: " + str(wave_number) + ", Intervalle: " + str(spawn_interval) + "s, Quota: " + str(total_zombies))

# Arrêter le spawn pour cette manche
func stop_spawning():
	is_active_for_wave = false
	can_spawn = false
	if cooldown_timer:
		cooldown_timer.stop()
	print("Spawner arrêté")

# Fonction pour déterminer le type de zombie à spawner selon la manche
func get_zombie_type_for_wave() -> PackedScene:
	var random_value = randf() * 100
	
	# Manche 1-4: 100% Basic
	if current_wave_number >= 1 and current_wave_number <= 4:
		return zombie_basic_scene
	
	# Manche 5-10: 75% Basic, 25% Heavy
	elif current_wave_number >= 5 and current_wave_number <= 10:
		if random_value <= 75.0:
			return zombie_basic_scene
		else:
			return zombie_heavy_scene
	
	# Manche 11-15: 40% Basic, 35% Heavy, 25% Arabic
	elif current_wave_number >= 11 and current_wave_number <= 15:
		if random_value <= 40.0:
			return zombie_basic_scene
		elif random_value <= 75.0:  # 40% + 35% = 75%
			return zombie_heavy_scene
		else:
			return zombie_arabic_scene
	
	# Manche 16+: 25% Basic, 40% Heavy, 35% Arabic
	else:
		if random_value <= 25.0:
			return zombie_basic_scene
		elif random_value <= 65.0:  # 25% + 40% = 65%
			return zombie_heavy_scene
		else:
			return zombie_arabic_scene

func spawn_zombie():
	if is_active_for_wave:
		can_spawn = false
		cooldown_timer.start()
		
		# Sélectionner le type de zombie selon la manche
		var zombie_scene_to_spawn = get_zombie_type_for_wave()
		
		if zombie_scene_to_spawn:
			var zombie = zombie_scene_to_spawn.instantiate()
			get_parent().add_child(zombie)
			
			# Trouver une position de spawn valide
			var spawn_position = find_valid_spawn_position()
			zombie.global_position = spawn_position
			
			# Configurer les propriétés du zombie
			if zombie is CharacterBody2D:
				# Configurer les layers de collision comme le joueur
				zombie.collision_layer = 4  # Layer 3 (Enemies)
				zombie.collision_mask = 1 | 2  # Layer 1 (Walls) + Layer 2 (Player)
				
				# Ajuster le z_index pour que les zombies apparaissent au bon niveau
				zombie.z_index = 1  # Au-dessus de la map mais sous certains objets de décoration
			
			spawned_zombies += 1
			zombies_spawned_this_wave += 1
			
			# Notifier le WaveManager qu'un zombie a été spawné
			if get_node_or_null("/root/WaveManager"):
				WaveManager.notify_zombie_spawned()
			
			# Connecter le signal tree_exited du zombie pour savoir quand il est détruit
			zombie.tree_exited.connect(_on_zombie_died)
			
			# Afficher le type de zombie spawné
			var zombie_type = "Basic"
			if zombie_scene_to_spawn == zombie_heavy_scene:
				zombie_type = "Heavy"
			elif zombie_scene_to_spawn == zombie_arabic_scene:
				zombie_type = "Arabic"
			
			print("Zombie " + zombie_type + " spawné à " + str(spawn_position) + "! (" + str(zombies_spawned_this_wave) + "/" + str(zombies_quota_for_wave) + " pour la manche " + str(current_wave_number) + ")")

# Trouve une position de spawn valide pour éviter les obstacles
func find_valid_spawn_position() -> Vector2:
	var base_position = global_position
	
	# Si on a une référence au joueur, utiliser sa hauteur comme référence
	if player:
		base_position.y = player.global_position.y
	
	var max_attempts = 50  # Nombre maximum de tentatives
	var attempt_radius = 100.0  # Rayon de recherche initial
	
	for attempt in range(max_attempts):
		# Générer une position candidate
		var candidate_position = base_position + Vector2(
			randf_range(-attempt_radius, attempt_radius),
			randf_range(-attempt_radius * 0.5, attempt_radius * 0.5)  # Moins de variation verticale
		)
		
		# Vérifier si cette position est valide
		if is_position_spawn_valid(candidate_position):
			return candidate_position
		
		# Augmenter le rayon de recherche pour les tentatives suivantes
		if attempt % 10 == 9:  # Tous les 10 essais
			attempt_radius += 50.0
	
	# Si aucune position valide trouvée, retourner la position de base avec un petit décalage
	print("⚠️ Aucune position de spawn idéale trouvée pour le zombie, utilisation de la position de fallback")
	return base_position + Vector2(randf_range(-30, 30), randf_range(-15, 15))

# Vérifie si une position est valide pour le spawn (pas sur des obstacles)
func is_position_spawn_valid(position: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	
	# Créer une forme de test (petit cercle) pour vérifier les collisions
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 16.0  # Taille approximative d'un zombie
	query.shape = shape
	query.transform = Transform2D(0, position)
	
	# Vérifier les collisions avec TOUS les layers problématiques
	# Layer 1 = Walls/Murs, et tous les autres éléments de décor ont leurs collisions
	query.collision_mask = 1  # Layer des murs et obstacles
	
	var results = space_state.intersect_shape(query)
	
	# Si on détecte des collisions, la position n'est pas valide
	if not results.is_empty():
		return false
	
	# Vérification supplémentaire avec des raycasts dans plusieurs directions
	var test_directions = [
		Vector2.UP * 20,
		Vector2.DOWN * 20,
		Vector2.LEFT * 20,
		Vector2.RIGHT * 20
	]
	
	for direction in test_directions:
		var ray_query = PhysicsRayQueryParameters2D.create(
			position,
			position + direction,
			1  # Layer des murs
		)
		
		var ray_result = space_state.intersect_ray(ray_query)
		if not ray_result.is_empty():
			# Si le raycast touche quelque chose de très près, ce n'est pas idéal
			var hit_distance = position.distance_to(ray_result.position)
			if hit_distance < 15.0:  # Trop proche d'un obstacle
				return false
	
	return true

func _on_zombie_died():
	spawned_zombies -= 1
	# Émettre le signal pour le WaveManager
	zombie_died.emit()

func _on_cooldown_timer_timeout():
	can_spawn = true

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		player = body

func _on_detection_area_body_exited(body):
	if body.is_in_group("player"):
		player = null 
