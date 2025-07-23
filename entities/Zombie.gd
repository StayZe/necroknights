extends CharacterBody2D
class_name Zombie

enum State {
	IDLE,
	CHASE,
	HIT,
	ATTACK,
	DEATH
}

@export var speed: float = 100.0  # Même vitesse que le joueur
@export var max_health: float = 100.0
@export var attack_damage: float = 15.0
@export var attack_cooldown: float = 1.5

@onready var sprite = $AnimatedSprite2D
@onready var animation_player = $AnimationPlayer
@onready var attack_timer = $AttackTimer
@onready var hit_timer = $HitTimer
@onready var detection_area = $DetectionArea
@onready var health_label = $HealthLabel

var player = null
var current_state = State.IDLE
var health = max_health
var can_attack = true

# Variables pour le pathfinding amélioré
var navigation_agent: NavigationAgent2D
var target_position: Vector2
var is_stuck = false
var stuck_timer = 0.0
var last_position: Vector2
var obstacle_avoidance_direction: Vector2 = Vector2.ZERO
var path_recalculation_timer = 0.0

# Précharger la scène de pièce
var coin_scene = preload("res://entities/Coin.tscn")
# Précharger la scène de boost
var boost_scene = preload("res://entities/BoostItem.tscn")

# Sons de zombies
var zombie_sound: AudioStreamPlayer2D
var zombie_sounds: Array[AudioStream] = []
var sound_timer: Timer
var sound_cooldown_min: float = 2.0
var sound_cooldown_max: float = 6.0

func _ready():
	health = max_health
	attack_timer.wait_time = attack_cooldown
	add_to_group("enemy")  # Pour que les projectiles puissent détecter les zombies
	
	# Configuration du NavigationAgent2D (optionnel si NavigationRegion2D existe)
	navigation_agent = NavigationAgent2D.new()
	add_child(navigation_agent)
	navigation_agent.avoidance_enabled = true
	navigation_agent.radius = 16.0
	navigation_agent.neighbor_distance = 50.0
	navigation_agent.max_neighbors = 10
	navigation_agent.time_horizon = 1.5
	navigation_agent.max_speed = speed
	
	# Configuration des animations
	sprite.sprite_frames.set_animation_speed("idle", 10)  # 6 frames
	sprite.sprite_frames.set_animation_speed("run", 15)   # 8 frames
	sprite.sprite_frames.set_animation_speed("hit", 6)    # 3 frames
	sprite.sprite_frames.set_animation_speed("knocked", 12)  # 6 frames
	sprite.sprite_frames.set_animation_speed("death", 10)   # 8 frames
	
	# Mise à jour de l'affichage de la santé
	update_health_display()
	
	# Définir l'état initial
	change_state(State.IDLE)
	
	# Initialiser la position précédente
	last_position = global_position
	
	# Configuration des layers de collision
	collision_layer = 4  # Layer 3 (Enemies)
	collision_mask = 1 | 2  # Layer 1 (Walls) + Layer 2 (Player)
	
	# Configurer les sons de zombies
	setup_zombie_sounds()

func _process(_delta):
	# Les animations sont gérées via change_state et les fonctions de transition
	pass

func _physics_process(delta):
	if current_state == State.DEATH:
		# Ne pas bouger si le zombie est mort
		return
	
	if current_state == State.HIT:
		# Le zombie est touché, ne pas bouger pendant un court instant
		return
	
	if current_state == State.ATTACK:
		# Le zombie attaque, ne pas bouger pendant l'attaque
		return
	
	if player != null and current_state == State.CHASE:
		# Système de pathfinding amélioré avec détection prédictive
		update_pathfinding_with_prediction(delta)
		
		# Si le zombie est proche du joueur, attaquer
		if global_position.distance_to(player.global_position) < 30:
			change_state(State.ATTACK)
			if can_attack:
				attack()
	
	# Mise à jour du z-index basé sur la position Y pour la profondeur
	update_depth_sorting()
	
	move_and_slide()
	
	# Debug des collisions (simplifié)
	if get_slide_collision_count() > 0:
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			var collider_name = "objet inconnu"
			
			if collider:
				if collider.has_method("get_name"):
					collider_name = collider.name
				elif collider.get("name"):
					collider_name = str(collider.name)
				else:
					collider_name = str(collider.get_class())
			
			print("🧟 Zombie basique rencontre une collision avec: ", collider_name)

func change_state(new_state):
	current_state = new_state
	
	match new_state:
		State.IDLE:
			# Animation d'idle (6 frames)
			sprite.play("idle")
		State.CHASE:
			# Animation de course (8 frames)
			sprite.play("run")
		State.HIT:
			# Animation de hit (3 frames)
			sprite.play("hit")
			hit_timer.start()
		State.ATTACK:
			# Animation d'attaque (6 frames)
			sprite.play("knocked")
			# S'assurer que l'animation d'attaque se termine avant de retourner à la poursuite
			await sprite.animation_finished
			if current_state == State.ATTACK and health > 0:
				change_state(State.CHASE)
		State.DEATH:
			# Animation de mort (8 frames)
			sprite.play("death")

func take_damage(damage_amount):
	print("Zombie prend " + str(damage_amount) + " dégâts!")
	health -= damage_amount
	update_health_display()
	
	if health <= 0:
		print("Zombie tué!")
		change_state(State.DEATH)
		# Désactiver la collision
		$CollisionShape2D.set_deferred("disabled", true)
		
		# Drop des pièces avant de supprimer le zombie
		drop_coins()
		
		# Supprimer le zombie après l'animation de mort
		await sprite.animation_finished
		queue_free()
	else:
		change_state(State.HIT)

func drop_coins():
	# Probabilités de drop: 50% pour 1 pièce, 30% pour 2 pièces, 20% pour 3 pièces
	var random_value = randf() * 100
	var coins_to_drop = 1
	
	if random_value <= 50:
		coins_to_drop = 1
	elif random_value <= 80:
		coins_to_drop = 2
	else:
		coins_to_drop = 3
	
	# Vérifier que la scène coin existe
	if not coin_scene:
		return
	
	# Trouver le nœud parent approprié pour ajouter les pièces
	var scene_root = get_tree().current_scene
	if not scene_root:
		return
	
	# Stocker la position du zombie avant sa suppression
	var zombie_position = global_position
	
	# Créer et placer les pièces à des positions valides
	for i in range(coins_to_drop):
		var coin = coin_scene.instantiate()
		if not coin:
			continue
		
		# Trouver une position valide pour la pièce
		var coin_position = find_valid_drop_position(zombie_position, 60.0)
		
		# Ajouter la pièce à la scène d'abord
		scene_root.add_child(coin)
		
		# Puis définir la position APRÈS l'ajout à la scène
		coin.global_position = coin_position
	
	# 5% de chance de drop un boost
	var boost_chance = randf() * 100
	if boost_chance <= 50.0:
		drop_boost()

func drop_boost():
	print("🎁 Un boost va être droppé !")
	
	# Vérifier que la scène boost existe
	if not boost_scene:
		print("Erreur: scène boost non trouvée")
		return
	
	# Trouver le nœud parent approprié
	var scene_root = get_tree().current_scene
	if not scene_root:
		print("Erreur: scene_root non trouvée")
		return
	
	# Créer le boost
	var boost = boost_scene.instantiate()
	if not boost:
		print("Erreur: impossible d'instancier le boost")
		return
	
	# Choisir aléatoirement le type de boost (1/4 de chance pour chaque)
	var boost_type_rand = randi() % 4
	match boost_type_rand:
		0:
			boost.boost_type = BoostItem.BoostType.ATOMIC_BOMB
			print("💥 Bombe atomique droppée !")
		1:
			boost.boost_type = BoostItem.BoostType.MEDICAL_KIT
			print("🏥 Kit médical droppé !")
		2:
			boost.boost_type = BoostItem.BoostType.SKULL
			print("💀 Boost de puissance droppé !")
		3:
			boost.boost_type = BoostItem.BoostType.SPEED_BOOST
			print("⚡ Boost de vitesse droppé !")
	
	# Trouver une position valide pour le boost
	var boost_position = find_valid_drop_position(global_position, 50.0)
	
	# Ajouter le boost à la scène
	scene_root.add_child(boost)
	
	# Définir la position après l'ajout à la scène
	boost.global_position = boost_position

# Trouve une position valide pour dropper un item (pièce ou boost)
func find_valid_drop_position(center_position: Vector2, max_radius: float = 60.0) -> Vector2:
	var max_attempts = 25  # Nombre maximum de tentatives pour les drops
	
	for attempt in range(max_attempts):
		# Générer une position candidate dans un rayon autour du centre
		var angle = randf() * 2.0 * PI
		var distance = randf_range(15.0, max_radius)  # Minimum 15 pixels du centre
		
		var candidate_position = center_position + Vector2(
			cos(angle) * distance,
			sin(angle) * distance
		)
		
		# Vérifier si cette position est valide pour un drop
		if is_position_drop_valid(candidate_position):
			return candidate_position
	
	# Si aucune position valide trouvée, retourner une position proche du centre
	print("⚠️ Aucune position de drop idéale trouvée, utilisation de la position de fallback")
	return center_position + Vector2(randf_range(-25, 25), randf_range(-25, 25))

# Vérifie si une position est valide pour dropper un item
func is_position_drop_valid(position: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	
	# Créer une forme de test plus petite pour les items
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 8.0  # Plus petit rayon pour les items
	query.shape = shape
	query.transform = Transform2D(0, position)
	
	# Vérifier les collisions avec les obstacles
	query.collision_mask = 1  # Layer des murs et obstacles
	
	var results = space_state.intersect_shape(query)
	
	# Si on détecte des collisions, la position n'est pas valide
	if not results.is_empty():
		return false
	
	# Test rapide avec un raycast vers le bas pour s'assurer qu'on est sur le sol
	var ground_check = PhysicsRayQueryParameters2D.create(
		position + Vector2(0, -5),  # Un peu au-dessus
		position + Vector2(0, 15),   # Un peu en-dessous
		1  # Layer des murs/sol
	)
	
	var ground_result = space_state.intersect_ray(ground_check)
	# On veut qu'il y ait quelque chose (le sol) pas trop loin en dessous
	if ground_result.is_empty():
		var hit_distance = 20.0  # Distance par défaut si pas de collision
	else:
		var hit_distance = position.distance_to(ground_result.position)
		# Si le sol est trop loin (plus de 30 pixels), ce n'est pas idéal
		if hit_distance > 30.0:
			return false
	
	return true

func update_health_display():
	if health_label:
		health_label.text = "HP: " + str(int(health))

func attack():
	can_attack = false
	attack_timer.start()
	if player != null:
		# Informations de débogage pour comprendre pourquoi take_damage n'est pas trouvé
		print("Type du joueur: ", player.get_class())
		print("Groupes du joueur: ", player.get_groups())
		print("Nom du nœud joueur: ", player.name)
		print("Script du joueur: ", player.get_script())
		
		# Vérifier si le joueur est une instance de la classe Player
		if player is Player:
			print("Le joueur est bien une instance de la classe Player")
			print("Zombie attaque le joueur pour " + str(attack_damage) + " dégâts!")
			player.take_damage(attack_damage)
		# Vérifier si le joueur a la méthode take_damage
		elif player.has_method("take_damage"):
			print("Zombie attaque le joueur pour " + str(attack_damage) + " dégâts!")
			player.take_damage(attack_damage)
		else:
			print("Le joueur n'a pas de méthode take_damage!")
			# Commenté pour éviter le crash du jeu
			# player.call("take_damage", attack_damage)

func _on_attack_timer_timeout():
	can_attack = true
	if current_state == State.ATTACK:
		change_state(State.CHASE)

func _on_hit_timer_timeout():
	if current_state == State.HIT and health > 0:
		change_state(State.CHASE)

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		print("Joueur détecté!")
		player = body
		change_state(State.CHASE)

func _on_detection_area_body_exited(body):
	if body.is_in_group("player"):
		print("Joueur hors de portée!")
		player = null
		change_state(State.IDLE)

func update_pathfinding(delta):
	# Tenter d'utiliser le NavigationAgent si disponible
	var has_navigation_map = NavigationServer2D.map_get_agents(get_world_2d().navigation_map).size() > 0
	
	if has_navigation_map:
		# Utiliser le système de navigation standard
		path_recalculation_timer += delta
		if path_recalculation_timer > 0.5 or global_position.distance_to(target_position) > 100:
			target_position = player.global_position
			navigation_agent.target_position = target_position
			path_recalculation_timer = 0.0
		
		var next_path_position = navigation_agent.get_next_path_position()
		var direction = global_position.direction_to(next_path_position)
		
		# Si le zombie est bloqué, utiliser l'évitement d'obstacles
		detect_if_stuck(delta)
		if is_stuck:
			direction = get_obstacle_avoidance_direction()
		
		velocity = direction * speed
	else:
		# Utiliser un système d'évitement d'obstacles personnalisé
		use_custom_pathfinding(delta)
	
	# Orienter le sprite
	if velocity.length() > 0:
		sprite.flip_h = velocity.x < 0

func detect_if_stuck(delta):
	# Vérifier si le zombie bouge très peu
	var distance_moved = global_position.distance_to(last_position)
	
	if distance_moved < 3.0:  # Seuil réduit
		stuck_timer += delta
		if stuck_timer > 0.8:  # Temps réduit avant de considérer comme bloqué
			is_stuck = true
	else:
		stuck_timer = 0.0
		is_stuck = false
		
	last_position = global_position

func get_obstacle_avoidance_direction():
	# Tester plusieurs directions pour éviter les obstacles
	var test_directions = [
		Vector2.UP,
		Vector2.DOWN,
		Vector2.LEFT,
		Vector2.RIGHT,
		Vector2.UP + Vector2.RIGHT,
		Vector2.UP + Vector2.LEFT,
		Vector2.DOWN + Vector2.RIGHT,
		Vector2.DOWN + Vector2.LEFT
	]
	
	var space_state = get_world_2d().direct_space_state
	var best_direction = Vector2.ZERO
	var best_score = -1.0
	
	for direction in test_directions:
		var test_position = global_position + direction * 50.0
		
		# Créer un rayon pour tester cette direction
		var query = PhysicsRayQueryParameters2D.create(
			global_position,
			test_position,
			1  # Layer des murs
		)
		
		var result = space_state.intersect_ray(query)
		
		# Calculer un score pour cette direction
		var score = 0.0
		if result.is_empty():
			# Pas d'obstacle, c'est bien
			score += 2.0
		
		# Favoriser les directions qui nous rapprochent du joueur
		var player_direction = global_position.direction_to(player.global_position)
		score += direction.dot(player_direction)
		
		if score > best_score:
			best_score = score
			best_direction = direction
	
	return best_direction

func use_custom_pathfinding(delta):
	# Détecter les blocages
	detect_if_stuck(delta)
	
	# Direction directe vers le joueur
	var direct_direction = global_position.direction_to(player.global_position)
	
	# Méthode simplifiée : tester seulement si il y a un obstacle direct
	var space_state = get_world_2d().direct_space_state
	var direct_query = PhysicsRayQueryParameters2D.create(
		global_position + Vector2(0, -8),  # Partir légèrement au-dessus du centre
		player.global_position + Vector2(0, -8),  # Vers le centre du joueur
		1  # Seulement layer des murs
	)
	direct_query.exclude = [self]
	var direct_result = space_state.intersect_ray(direct_query)
	
	var final_direction = direct_direction
	
	# Si il y a un obstacle OU si le zombie est bloqué depuis longtemps
	if not direct_result.is_empty() or is_stuck:
		# Utiliser une méthode plus simple : tourner autour de l'obstacle
		final_direction = get_simple_avoidance_direction()
	
	# Éviter les regroupements
	var nearby_zombies = get_nearby_zombies_count()
	if nearby_zombies > 1:
		# Ajouter une petite déviation pour éviter les embouteillages
		var spread_angle = randf_range(-PI/4, PI/4)  # ±45 degrés
		var spread_direction = Vector2(cos(direct_direction.angle() + spread_angle), sin(direct_direction.angle() + spread_angle))
		final_direction = final_direction.lerp(spread_direction, 0.3)
	
	velocity = final_direction * speed

func get_simple_avoidance_direction() -> Vector2:
	# Méthode simplifiée : essayer seulement quelques directions principales
	var player_direction = global_position.direction_to(player.global_position)
	var test_directions = [
		player_direction,  # Direction directe
		Vector2(-player_direction.y, player_direction.x),  # 90° à gauche
		Vector2(player_direction.y, -player_direction.x),  # 90° à droite
		player_direction.rotated(PI/4),    # 45° rotation
		player_direction.rotated(-PI/4),   # -45° rotation
		player_direction.rotated(3*PI/4),  # 135° rotation
		player_direction.rotated(-3*PI/4), # -135° rotation
	]
	
	var space_state = get_world_2d().direct_space_state
	
	for direction in test_directions:
		var test_query = PhysicsRayQueryParameters2D.create(
			global_position,
			global_position + direction * 50.0,
			1  # Seulement les murs
		)
		test_query.exclude = [self]
		var result = space_state.intersect_ray(test_query)
		
		if result.is_empty():
			return direction
	
	# Si aucune direction n'est libre, reculer
	return -player_direction * 0.5

func get_nearby_zombies_count() -> int:
	# Version simplifiée pour compter les zombies proches
	var nearby_count = 0
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 25.0
	query.shape = shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 4  # Layer des ennemis
	query.exclude = [self]
	
	var results = space_state.intersect_shape(query)
	return results.size()

func get_advanced_obstacle_avoidance_direction():
	# Directions à tester (plus de directions pour un meilleur évitement)
	var test_angles = []
	for i in range(16):  # 16 directions autour du zombie
		var angle = (i * PI * 2) / 16
		test_angles.append(angle)
	
	var space_state = get_world_2d().direct_space_state
	var best_direction = Vector2.ZERO
	var best_score = -999.0
	
	for angle in test_angles:
		var direction = Vector2(cos(angle), sin(angle))
		var test_position = global_position + direction * 80.0
		
		# Créer un rayon pour tester cette direction avec un masque de collision approprié
		var query = PhysicsRayQueryParameters2D.create(
			global_position,
			test_position,
			1 | 4  # Layer des murs (1) + layer des autres ennemis (4) pour éviter les collisions entre zombies
		)
		
		var result = space_state.intersect_ray(query)
		
		# Calculer un score pour cette direction
		var score = 0.0
		
		# Bonus si pas d'obstacle
		if result.is_empty():
			score += 10.0
		else:
			# Pénalité basée sur la distance de l'obstacle
			var obstacle_distance = global_position.distance_to(result.position)
			score += obstacle_distance / 20.0  # Plus l'obstacle est loin, mieux c'est
			
			# Pénalité supplémentaire si c'est un mur solide
			var collider = result.get("collider")
			if collider and collider.collision_layer & 1:  # Layer des murs
				score -= 5.0
		
		# Bonus pour se rapprocher du joueur
		var player_direction = global_position.direction_to(player.global_position)
		var alignment = direction.dot(player_direction)
		score += alignment * 5.0
		
		# Éviter de revenir en arrière
		if velocity.length() > 0:
			var current_direction = velocity.normalized()
			var momentum_bonus = direction.dot(current_direction)
			score += momentum_bonus * 2.0
		
		# Bonus pour éviter les autres zombies
		var nearby_zombies = check_for_nearby_zombies(global_position + direction * 40.0)
		if nearby_zombies == 0:
			score += 3.0
		else:
			score -= nearby_zombies * 2.0
		
		if score > best_score:
			best_score = score
			best_direction = direction
	
	return best_direction

func check_for_nearby_zombies(position: Vector2) -> int:
	# Vérifier s'il y a d'autres zombies proches pour éviter les regroupements
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 30.0
	query.shape = shape
	query.transform = Transform2D(0, position)
	query.collision_mask = 4  # Layer des ennemis
	query.exclude = [self]  # Exclure ce zombie
	
	var results = space_state.intersect_shape(query)
	return results.size()

func get_wall_following_direction():
	# Technique de "wall following" - suivre le mur pour le contourner
	var space_state = get_world_2d().direct_space_state
	var player_direction = global_position.direction_to(player.global_position)
	
	# Tester les directions perpendiculaires à gauche et à droite
	var perpendicular_left = Vector2(-player_direction.y, player_direction.x)
	var perpendicular_right = Vector2(player_direction.y, -player_direction.x)
	
	# Tester quelle direction perpendiculaire est libre
	var left_query = PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + perpendicular_left * 60.0,
		1
	)
	var right_query = PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + perpendicular_right * 60.0,
		1
	)
	
	var left_result = space_state.intersect_ray(left_query)
	var right_result = space_state.intersect_ray(right_query)
	
	# Choisir la direction la plus libre
	if left_result.is_empty() and right_result.is_empty():
		# Les deux sont libres, choisir aléatoirement
		return perpendicular_left if randf() > 0.5 else perpendicular_right
	elif left_result.is_empty():
		return perpendicular_left
	elif right_result.is_empty():
		return perpendicular_right
	else:
		# Aucune direction perpendiculaire libre, reculer légèrement
		return -player_direction * 0.5 

func update_depth_sorting():
	# Plus le zombie est en bas de l'écran, plus il doit être rendu devant
	# Utiliser la position Y pour déterminer l'ordre de rendu
	z_index = int(global_position.y / 10)  # Diviser par 10 pour éviter des valeurs trop grandes

func setup_zombie_sounds():
	# Créer l'AudioStreamPlayer2D pour les sons de zombies
	zombie_sound = AudioStreamPlayer2D.new()
	add_child(zombie_sound)
	zombie_sound.volume_db = -8  # Volume modéré
	
	# Configuration de la distance d'audition (ajustée pour le jeu)
	zombie_sound.max_distance = 1000  # 100m - distance beaucoup plus grande
	zombie_sound.attenuation = 1.5  # Dégradé plus doux du son
	
	# Charger les sons de zombies
	zombie_sounds = []
	
	# Charger les sons de grognement (4 sons)
	for i in range(1, 5):  # De 1 à 4
		var sound_path = "res://songs/zombie-growl-sound-" + str(i) + ".wav"
		var sound = load(sound_path)
		if sound:
			zombie_sounds.append(sound)
			print("Son de zombie chargé: " + sound_path)
		else:
			print("Erreur: Impossible de charger le son: " + sound_path)
	
	# Charger les sons de gémissement (3 sons)
	for i in range(1, 4):  # De 1 à 3
		var sound_path = "res://songs/zombie-moaning-sound-" + str(i) + ".wav"
		var sound = load(sound_path)
		if sound:
			zombie_sounds.append(sound)
			print("Son de zombie chargé: " + sound_path)
		else:
			print("Erreur: Impossible de charger le son: " + sound_path)
	
	# Charger le son de rugissement
	var roar_sound = load("res://songs/zombie-roar.wav")
	if roar_sound:
		zombie_sounds.append(roar_sound)
		print("Son de zombie chargé: zombie-roar.wav")
	else:
		print("Erreur: Impossible de charger le son: zombie-roar.wav")
	
	# Créer le timer pour les sons aléatoires
	sound_timer = Timer.new()
	add_child(sound_timer)
	sound_timer.one_shot = true
	sound_timer.timeout.connect(_on_sound_timer_timeout)
	
	# Démarrer le premier son après un délai aléatoire
	start_random_sound_timer()

func play_random_zombie_sound():
	if zombie_sounds.size() == 0 or not zombie_sound:
		return
	
	# Vérifier si le zombie est dans un état où il peut faire du bruit
	if current_state == State.DEATH:
		return
	
	# Choisir un son aléatoire
	var random_index = randi() % zombie_sounds.size()
	zombie_sound.stream = zombie_sounds[random_index]
	zombie_sound.play()
	
	# Déterminer le type de son pour le debug
	var sound_type = ""
	if random_index < 4:
		sound_type = "growl-" + str(random_index + 1)
	elif random_index < 7:
		sound_type = "moaning-" + str(random_index - 3)
	else:
		sound_type = "roar"
	
	# Debug amélioré avec informations de distance
	var debug_info = "Zombie émet un son: " + sound_type
	if player:
		var distance = global_position.distance_to(player.global_position)
		debug_info += " (distance: " + str(int(distance)) + " pixels)"
		if distance > zombie_sound.max_distance:
			debug_info += " [HORS PORTÉE]"
		elif distance > zombie_sound.max_distance * 0.5:
			debug_info += " [LOINTAIN]"
		else:
			debug_info += " [PROCHE]"
	
	print(debug_info)

func start_random_sound_timer():
	if sound_timer:
		var random_delay = randf_range(sound_cooldown_min, sound_cooldown_max)
		sound_timer.wait_time = random_delay
		sound_timer.start()

func _on_sound_timer_timeout():
	play_random_zombie_sound()
	start_random_sound_timer()  # Programmer le prochain son

# Fonction de debug pour tester les sons et distances
func debug_sound_system():
	if player and zombie_sound:
		var distance_to_player = global_position.distance_to(player.global_position)
		print("🧟 Zombie à " + str(int(distance_to_player)) + " pixels du joueur")
		print("📍 Max distance configurée: " + str(zombie_sound.max_distance))
		print("🔊 Volume configuré: " + str(zombie_sound.volume_db) + " dB")
		print("📉 Atténuation: " + str(zombie_sound.attenuation))
		
		# Calculer le volume théorique à cette distance
		if distance_to_player < zombie_sound.max_distance:
			var volume_factor = 1.0 - pow(distance_to_player / zombie_sound.max_distance, zombie_sound.attenuation)
			print("🎵 Volume théorique: " + str(int(volume_factor * 100)) + "%")
		else:
			print("🔇 Hors de portée - inaudible")

# Fonction pour forcer un son de test
func force_test_sound():
	print("🔊 Test de son forcé par le zombie")
	play_random_zombie_sound()
	debug_sound_system()

# Calcule la direction d'évitement optimale basée sur la normale de collision
func calculate_avoidance_direction(collision_normal: Vector2) -> Vector2:
	if player == null:
		return collision_normal
	
	# Direction vers le joueur
	var player_direction = global_position.direction_to(player.global_position)
	
	# Calculer les deux directions perpendiculaires à la normale de collision
	var perpendicular_left = Vector2(-collision_normal.y, collision_normal.x)
	var perpendicular_right = Vector2(collision_normal.y, -collision_normal.x)
	
	# Choisir la direction perpendiculaire qui nous rapproche le plus du joueur
	var dot_left = perpendicular_left.dot(player_direction)
	var dot_right = perpendicular_right.dot(player_direction)
	
	var best_perpendicular = perpendicular_left if dot_left > dot_right else perpendicular_right
	
	# Mélanger la normale de collision avec la direction perpendiculaire optimale
	# Plus de poids sur la normale pour s'éloigner de l'obstacle
	var avoidance_direction = (collision_normal * 0.6 + best_perpendicular * 0.4).normalized()
	
	return avoidance_direction

# Variables pour l'évitement prédictif
var avoidance_mode = false
var avoidance_direction = Vector2.ZERO
var avoidance_timer = 0.0
var avoidance_duration = 0.6  # Durée d'évitement réduite

# Variables spéciales pour les grillages
var fence_bypass_mode = false
var fence_entry_point = Vector2.ZERO
var fence_bypass_timer = 0.0

# Points d'entrée des grillages - à définir selon ta map
var fence_entry_points = {
	"Grillage": Vector2(47, 20)  # Position du point d'entrée du grillage
}

# Fonction de debug pour afficher la position actuelle du zombie
func debug_position():
	print("🧟 Position actuelle du zombie basique: ", global_position)
	print("🧟 Point d'entrée configuré: ", fence_entry_points.get("Grillage", Vector2.ZERO))
	print("🧟 Distance au point d'entrée: ", global_position.distance_to(fence_entry_points.get("Grillage", Vector2.ZERO)))

# Système de pathfinding avec détection prédictive d'obstacles
func update_pathfinding_with_prediction(delta):
	if player == null:
		return
	
	# Mettre à jour le timer d'évitement de grillage
	if fence_bypass_mode:
		fence_bypass_timer -= delta
		# Vérifier si on a atteint le point d'entrée du grillage
		var distance_to_entry = global_position.distance_to(fence_entry_point)
		if distance_to_entry < 30.0 or fence_bypass_timer <= 0:
			fence_bypass_mode = false
			print("🧟 Zombie basique a atteint le point d'entrée du grillage")
	
	# Si on est en mode contournement de grillage
	if fence_bypass_mode:
		var entry_direction = global_position.direction_to(fence_entry_point)
		velocity = entry_direction * speed
		
		# Orienter le sprite
		if velocity.length() > 0:
			sprite.flip_h = velocity.x < 0
		return
	
	# Mettre à jour le timer d'évitement normal
	if avoidance_mode:
		avoidance_timer -= delta
		if avoidance_timer <= 0:
			avoidance_mode = false
			print("🧟 Zombie basique termine l'évitement")
	
	# Si on est en mode évitement normal, continuer dans cette direction
	if avoidance_mode:
		# Mélanger davantage avec la direction du joueur pour un évitement plus court
		var player_direction = global_position.direction_to(player.global_position)
		var mixed_direction = (avoidance_direction * 0.6 + player_direction * 0.4).normalized()
		velocity = mixed_direction * speed
		
		# Orienter le sprite
		if velocity.length() > 0:
			sprite.flip_h = velocity.x < 0
		return
	
	# Direction directe vers le joueur
	var player_direction = global_position.direction_to(player.global_position)
	
	# Détecter les obstacles avec un raycast prédictif plus court
	var obstacle_info = detect_obstacle_ahead_with_type(player_direction)
	
	if obstacle_info.detected:
		# Vérifier si c'est un grillage
		if obstacle_info.obstacle_name == "Grillage":
			# Mode spécial pour contourner le grillage
			fence_bypass_mode = true
			fence_entry_point = fence_entry_points.get("Grillage", global_position)
			fence_bypass_timer = 5.0  # Maximum 5 secondes pour atteindre l'entrée
			print("🧟 Zombie basique détecte un grillage!")
			print("🧟 Position zombie: ", global_position)
			print("🧟 Point d'entrée configuré: ", fence_entry_point)
			print("🧟 Distance au point d'entrée: ", global_position.distance_to(fence_entry_point))
			debug_position()  # Afficher les infos de debug
		else:
			# Évitement normal pour les autres obstacles
			avoidance_direction = calculate_best_avoidance_direction(player_direction)
			avoidance_mode = true
			avoidance_timer = avoidance_duration
			velocity = avoidance_direction * speed
			print("🧟 Zombie basique commence l'évitement normal - direction: ", avoidance_direction)
	else:
		# Aucun obstacle détecté, aller directement vers le joueur
		velocity = player_direction * speed
	
	# Orienter le sprite
	if velocity.length() > 0:
		sprite.flip_h = velocity.x < 0

# Détecte s'il y a un obstacle dans la direction donnée et retourne son type
func detect_obstacle_ahead_with_type(direction: Vector2) -> Dictionary:
	var space_state = get_world_2d().direct_space_state
	var detection_distance = 35.0  # Distance de détection réduite
	
	# Raycast principal
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + direction * detection_distance,
		1  # Layer des murs/obstacles
	)
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	
	if result.is_empty():
		return {"detected": false, "obstacle_name": ""}
	
	# Analyser le type d'obstacle
	var collider = result.get("collider")
	var obstacle_name = ""
	
	if collider:
		# Si c'est un TileMapLayer, obtenir son nom
		if collider is TileMapLayer:
			obstacle_name = collider.name
		elif collider.has_method("get_name"):
			obstacle_name = collider.name
		elif collider.get("name"):
			obstacle_name = str(collider.name)
		else:
			obstacle_name = str(collider.get_class())
	
	return {"detected": true, "obstacle_name": obstacle_name}

# Ancienne fonction gardée pour compatibilité
func detect_obstacle_ahead(direction: Vector2) -> bool:
	var obstacle_info = detect_obstacle_ahead_with_type(direction)
	return obstacle_info.detected

# Calcule la meilleure direction pour éviter l'obstacle
func calculate_best_avoidance_direction(blocked_direction: Vector2) -> Vector2:
	var space_state = get_world_2d().direct_space_state
	var detection_distance = 45.0  # Distance de test réduite
	
	# Tester d'abord des angles plus petits pour un évitement plus subtil
	var test_angles = [PI/4, -PI/4, PI/2, -PI/2, PI/3, -PI/3]  # 45°, 90°, 60° dans chaque direction
	
	for angle in test_angles:
		var test_direction = blocked_direction.rotated(angle)
		
		# Tester cette direction
		var query = PhysicsRayQueryParameters2D.create(
			global_position,
			global_position + test_direction * detection_distance,
			1  # Layer des murs/obstacles
		)
		query.exclude = [self]
		
		var result = space_state.intersect_ray(query)
		
		# Si cette direction est libre
		if result.is_empty():
			print("🧟 Direction d'évitement trouvée: angle ", rad_to_deg(angle), "°")
			return test_direction
	
	# Si aucune direction n'est complètement libre, choisir une direction perpendiculaire
	return Vector2(-blocked_direction.y, blocked_direction.x)  # 90° à gauche par défaut
