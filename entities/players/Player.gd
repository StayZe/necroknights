extends CharacterBody2D
class_name Player

# 📌 Constantes et variables
const SPEED = 100.0
@onready var anim = $AnimationPlayer  # Assurez-vous qu'il correspond à votre noeud
@onready var sprite = $sprite  # Ajout pour manipuler le sprite correctement
@onready var last_direction = "walk_down"  # Mémorise la dernière direction
@onready var health_label = $HealthLabel
var player_facing_right = true  # Indique si le joueur regarde à droite ou à gauche

# 📌 Variables de santé
@export var max_health: float = 100.0
var health: float = max_health
var is_invulnerable: bool = false
var invulnerability_time: float = 0.5  # Temps d'invulnérabilité après avoir pris des dégâts

# 📌 Son de dégâts
var hurt_sound: AudioStreamPlayer2D
var hurt_sounds: Array[AudioStream] = []

# 📌 Gestion des armes
@export var weapon: NodePath  # L'arme actuelle du joueur (assignable dans l'inspecteur)
var current_weapon: Weapon = null  # Référence à l'arme actuelle
@export var weapon_pickup_scene: PackedScene  # La scène de pickup d'arme à utiliser

# 📌 Système à 2 slots d'armes
var weapon_slot_1: Weapon = null  # Arme dans le slot 1
var weapon_slot_2: Weapon = null  # Arme dans le slot 2
var weapon_slot_1_scene_path: String = ""  # Chemin de la scène de l'arme du slot 1
var weapon_slot_2_scene_path: String = ""  # Chemin de la scène de l'arme du slot 2
var active_weapon_slot: int = 0  # 0 = aucune arme, 1 = slot 1, 2 = slot 2

# Pour stocker le chemin de la scène de l'arme originale
var current_weapon_scene_path: String = ""

# 📌 Variables de boost
var current_speed_multiplier: float = 1.0
var speed_boost_active: bool = false
var damage_boost_multiplier: float = 1.0
var damage_boost_active: bool = false
var damage_boost_timer: Timer
var speed_boost_timer: Timer

# DEBUG: Test rapide du Game Over (à supprimer après test)
var debug_game_over = false

func _ready():
	# Ajouter le joueur au groupe pour la détection
	add_to_group("player")
	
	# Appliquer le skin sélectionné
	apply_selected_skin()
	
	# Initialiser la santé
	health = max_health
	update_health_display()
	
	# Créer les timers pour les boosts
	create_boost_timers()
	
	# Configurer les sons de dégâts
	setup_hurt_sounds()
	
	# S'enregistrer auprès du WaveManager
	if get_node_or_null("/root/WaveManager"):
		WaveManager.register_player(self)
	
	if weapon:
		current_weapon = get_node(weapon)
	
	print("Joueur initialisé - Santé: " + str(health) + " - Skin: " + str(PlayerSettings.selected_skin))

func _physics_process(delta):
	get_input()
	update_facing_direction()
	
	# Améliorer la gestion des collisions
	var was_on_floor = is_on_floor()
	move_and_slide()
	
	# Vérifier les collisions après le mouvement
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision:
			# Debug pour voir avec quoi on collisionne
			print("Collision détectée avec: ", collision.get_collider())
	
	# 📌 Gestion du changement d'arme avec les touches 1 et 2
	if Input.is_action_just_pressed("weapon_slot_1"):
		switch_to_weapon_slot(1)
	elif Input.is_action_just_pressed("weapon_slot_2"):
		switch_to_weapon_slot(2)
	
	if current_weapon:
		handle_weapon()
		
	# Gérer la dépose d'arme avec la touche F
	if Input.is_action_just_pressed("drop") and current_weapon:
		drop_current_weapon()

# 📌 Gère le déplacement et les animations
func get_input():
	var input_direction = Input.get_vector("left", "right", "up", "down")
	# Appliquer le multiplicateur de vitesse
	velocity = input_direction * SPEED * current_speed_multiplier

	# Les animations sont maintenant principalement gérées par la fonction update_facing_direction
	if anim and input_direction == Vector2.ZERO:
		anim.stop()  # Arrête l'animation si le joueur ne bouge pas

# 📌 Renvoie la direction actuelle du joueur
func get_last_direction() -> String:
	return last_direction

# 📌 Met à jour la direction dans laquelle le joueur regarde en fonction de la souris
func update_facing_direction():
	# Déterminer si le joueur regarde à droite ou à gauche en fonction de la souris
	var mouse_pos = get_global_mouse_position()
	var previous_facing = player_facing_right
	player_facing_right = mouse_pos.x > global_position.x
	
	# Mettre à jour l'animation si la direction a changé
	if anim and previous_facing != player_facing_right:
		if player_facing_right:
			last_direction = "walk-right"
			anim.play("walk-right")
		else:
			last_direction = "walk-left"
			anim.play("walk-left")
	
	# Si le joueur se déplace (mais pas simplement en regardant), on priorise la direction haut/bas
	if velocity.length() > 0 and anim:
		if abs(velocity.y) > abs(velocity.x):
			if velocity.y > 0:
				last_direction = "walk-down"
				anim.play("walk-down")
			else:
				last_direction = "walk-up"
				anim.play("walk-up")
		else:
			if player_facing_right:
				last_direction = "walk-right"
				anim.play("walk-right")
			else:
				last_direction = "walk-left"
				anim.play("walk-left")
	
	# Ajuster la position de l'arme si nécessaire
	if current_weapon:
		adjust_weapon_position()

# 📌 Ajuster la position de l'arme en fonction de la direction du joueur
func adjust_weapon_position():
	if not current_weapon:
		return
		
	# Positions par défaut
	var right_pos = Vector2(10, 0)
	var left_pos = Vector2(-10, 0)
	var up_pos = Vector2(0, -15)  # Position pour regarder vers le haut
	var down_pos = Vector2(0, 5)  # Position pour regarder vers le bas
	
	# Déterminer la position selon la direction
	if last_direction == "walk-up" or last_direction == "walk_up":
		current_weapon.position = up_pos
		# Si le joueur regarde vers le haut, l'arme doit être au-dessus
		current_weapon.z_index = -1  # Pour s'assurer que l'arme apparaît derrière le joueur
	elif last_direction == "walk-down" or last_direction == "walk_down":
		current_weapon.position = down_pos
		current_weapon.z_index = 1  # Pour s'assurer que l'arme apparaît devant le joueur
	else:
		# Pour les directions gauche/droite, ajuster selon que le joueur regarde à gauche ou à droite
		current_weapon.position = right_pos if player_facing_right else left_pos
		current_weapon.z_index = 0  # Réinitialiser le z_index
	
	# Orienter l'arme horizontalement selon la direction
	if "sprite" in current_weapon and current_weapon.sprite:
		current_weapon.sprite.flip_v = !player_facing_right

# 📌 Gère l'utilisation de l'arme
func handle_weapon():
	if not current_weapon:
		return
		
	# Obtenir la position de la souris et la direction de tir
	var mouse_pos = get_global_mouse_position()
	var shoot_direction = (mouse_pos - global_position).normalized()
	
	# Orienter l'arme vers la souris si elle a une rotation
	if current_weapon:
		var angle_to_mouse = shoot_direction.angle()
		
		# Vérifier si la rotation doit être limitée en fonction de la direction du joueur
		if player_facing_right:
			# Pour la direction droite, l'angle doit être entre -90° et 90°
			if angle_to_mouse > PI/2 and angle_to_mouse < 3*PI/2:
				angle_to_mouse = 0  # Pointer horizontalement par défaut
		else:
			# Pour la direction gauche, l'angle doit être entre 90° et 270°
			if angle_to_mouse < PI/2 or angle_to_mouse > 3*PI/2:
				angle_to_mouse = PI  # Pointer horizontalement par défaut
		
		# Appliquer la rotation à l'arme
		current_weapon.rotation = angle_to_mouse

	if Input.is_action_pressed("shoot") and current_weapon:
		current_weapon.shoot(shoot_direction)

	if Input.is_action_just_pressed("reload") and current_weapon:
		current_weapon.reload()

# 📌 Fonction pour changer d'arme
func equip_weapon(new_weapon_scene: PackedScene):
	# Détermine quel slot utiliser
	var target_slot = 1
	if weapon_slot_1 != null and weapon_slot_2 == null:
		target_slot = 2
	elif weapon_slot_1 != null and weapon_slot_2 != null:
		# Les deux slots sont pleins, remplacer l'arme active ou le slot 1 par défaut
		target_slot = active_weapon_slot if active_weapon_slot > 0 else 1
	
	# Libérer l'arme du slot cible s'il y en a une
	if target_slot == 1 and weapon_slot_1 != null:
		weapon_slot_1.queue_free()
		weapon_slot_1 = null
		weapon_slot_1_scene_path = ""
	elif target_slot == 2 and weapon_slot_2 != null:
		weapon_slot_2.queue_free()
		weapon_slot_2 = null
		weapon_slot_2_scene_path = ""
	
	# Créer la nouvelle arme
	var new_weapon = new_weapon_scene.instantiate()
	add_child(new_weapon)
	
	# Configurer l'arme (cacher par défaut)
	new_weapon.visible = false
	
	# L'assigner au bon slot
	if target_slot == 1:
		weapon_slot_1 = new_weapon
		weapon_slot_1_scene_path = new_weapon_scene.resource_path
		print("Arme équipée dans le slot 1: " + weapon_slot_1_scene_path)
	else:
		weapon_slot_2 = new_weapon
		weapon_slot_2_scene_path = new_weapon_scene.resource_path
		print("Arme équipée dans le slot 2: " + weapon_slot_2_scene_path)
	
	# Activer cette arme automatiquement
	switch_to_weapon_slot(target_slot)
	
	# Si l'arme a une méthode pour configurer les sprites, l'appeler
	if new_weapon.has_method("configure_sprites"):
		new_weapon.configure_sprites()

# 📌 Fonction pour changer de slot d'arme actif
func switch_to_weapon_slot(slot_number: int):
	# Cacher toutes les armes
	hide_all_weapons()
	
	# Réinitialiser l'état actuel
	current_weapon = null
	current_weapon_scene_path = ""
	active_weapon_slot = 0
	
	# Activer l'arme du slot demandé
	match slot_number:
		1:
			if weapon_slot_1:
				current_weapon = weapon_slot_1
				current_weapon_scene_path = weapon_slot_1_scene_path
				active_weapon_slot = 1
				current_weapon.visible = true
				adjust_weapon_position()
		2:
			if weapon_slot_2:
				current_weapon = weapon_slot_2
				current_weapon_scene_path = weapon_slot_2_scene_path
				active_weapon_slot = 2
				current_weapon.visible = true
				adjust_weapon_position()

# 📌 Fonction helper pour cacher toutes les armes
func hide_all_weapons():
	if weapon_slot_1:
		weapon_slot_1.visible = false
	if weapon_slot_2:
		weapon_slot_2.visible = false

# 📌 Fonction pour déposer l'arme au sol
func drop_current_weapon():
	if not current_weapon or active_weapon_slot == 0:
		print("Aucune arme à déposer")
		return
		
	# Créer un pickup d'arme
	var pickup = weapon_pickup_scene.instantiate()
	get_parent().add_child(pickup)
	
	# Configurer le pickup avec la bonne scène d'arme
	var weapon_scene = load(current_weapon_scene_path)
	pickup.weapon_scene = weapon_scene
	
	# Positionner le pickup proche du joueur
	var drop_direction = Vector2.RIGHT
	if last_direction == "walk-left":
		drop_direction = Vector2.LEFT
	elif last_direction == "walk-up":
		drop_direction = Vector2.UP
	elif last_direction == "walk-down":
		drop_direction = Vector2.DOWN
		
	pickup.global_position = global_position + drop_direction * 30
	
	# Supprimer l'arme du slot actif
	if active_weapon_slot == 1:
		weapon_slot_1.queue_free()
		weapon_slot_1 = null
		weapon_slot_1_scene_path = ""
		print("Arme du slot 1 déposée")
	elif active_weapon_slot == 2:
		weapon_slot_2.queue_free()
		weapon_slot_2 = null
		weapon_slot_2_scene_path = ""
		print("Arme du slot 2 déposée")
	
	# Réinitialiser les références
	current_weapon = null
	current_weapon_scene_path = ""
	active_weapon_slot = 0

# 📌 Fonction pour mettre à jour l'affichage de la santé
func update_health_display():
	if health_label:
		health_label.text = "HP: " + str(int(health))

# 📌 Fonction pour prendre des dégâts
func take_damage(damage_amount):
	print("Joueur prend " + str(damage_amount) + " dégâts!")
	
	if is_invulnerable:
		print("Joueur invulnérable!")
		return
	
	health -= damage_amount
	update_health_display()
	
	# Jouer un son de dégâts aléatoire
	play_random_hurt_sound()
	
	# Animation de dégâts
	sprite.modulate = Color(1, 0.3, 0.3, 1)  # Teinte rouge
	
	# Période d'invulnérabilité
	is_invulnerable = true
	
	# Vérifier si le joueur est mort
	if health <= 0:
		die()
	
	# Timer pour supprimer l'invulnérabilité
	await get_tree().create_timer(invulnerability_time).timeout
	sprite.modulate = Color(1, 1, 1, 1)  # Retour à la normale
	is_invulnerable = false

# 📌 Fonction appelée quand le joueur meurt
func die():
	# Animation de mort ou game over
	print("Le joueur est mort !")
	
	# Appeler le système de Game Over du WaveManager
	if get_node_or_null("/root/WaveManager"):
		WaveManager.trigger_game_over()
	else:
		print("Erreur: WaveManager non trouvé pour déclencher le Game Over")

# 📌 Méthodes de boost

func heal_to_full():
	health = max_health
	update_health_display()
	print("🏥 Vie restaurée à 100% !")

func apply_damage_boost(multiplier: float, duration: float):
	damage_boost_multiplier = multiplier
	damage_boost_active = true
	damage_boost_timer.wait_time = duration
	damage_boost_timer.start()
	print("💀 Boost de dégâts activé ! x" + str(multiplier) + " pendant " + str(duration) + " secondes")

func apply_speed_boost(multiplier: float, duration: float = 0.0):
	current_speed_multiplier = multiplier
	speed_boost_active = true
	
	if duration > 0:
		speed_boost_timer.wait_time = duration
		# Déconnecter le signal existant avant de reconnecter pour éviter les doublons
		if speed_boost_timer.timeout.is_connected(_on_speed_boost_timeout):
			speed_boost_timer.timeout.disconnect(_on_speed_boost_timeout)
		speed_boost_timer.timeout.connect(_on_speed_boost_timeout)
		speed_boost_timer.start()
		print("⚡ Boost de vitesse activé ! x" + str(multiplier) + " pendant " + str(duration) + " secondes")
	else:
		print("⚡ Boost de vitesse activé ! x" + str(multiplier) + " (permanent)")

func _on_damage_boost_timeout():
	damage_boost_multiplier = 1.0
	damage_boost_active = false
	print("💀 Boost de dégâts terminé, retour à la normale")

func _on_speed_boost_timeout():
	current_speed_multiplier = 1.0
	speed_boost_active = false
	print("⚡ Boost de vitesse terminé, retour à la vitesse normale")

func get_damage_multiplier() -> float:
	return damage_boost_multiplier

func get_speed_multiplier() -> float:
	return current_speed_multiplier

func create_boost_timers():
	# Timer pour le boost de dégâts
	damage_boost_timer = Timer.new()
	damage_boost_timer.wait_time = 30.0
	damage_boost_timer.one_shot = true
	damage_boost_timer.timeout.connect(_on_damage_boost_timeout)
	add_child(damage_boost_timer)
	
	# Timer pour le boost de vitesse
	speed_boost_timer = Timer.new()
	speed_boost_timer.one_shot = true
	add_child(speed_boost_timer)

# 📌 Applique le skin sélectionné au sprite du joueur
func apply_selected_skin():
	if PlayerSettings and sprite:
		var selected_sprite_path = PlayerSettings.get_selected_sprite_path()
		var texture = load(selected_sprite_path)
		if texture:
			sprite.texture = texture
			print("Skin appliqué: " + selected_sprite_path)
		else:
			print("Erreur: Impossible de charger le sprite: " + selected_sprite_path)

func setup_hurt_sounds():
	# Créer l'AudioStreamPlayer2D pour les sons de dégâts
	hurt_sound = AudioStreamPlayer2D.new()
	add_child(hurt_sound)
	hurt_sound.volume_db = -5  # Volume modéré
	
	# Charger les 7 sons de dégâts
	hurt_sounds = []
	for i in range(1, 8):  # De 1 à 7
		var sound_path = "res://songs/human-hurt-song-" + str(i) + ".wav"
		var sound = load(sound_path)
		if sound:
			hurt_sounds.append(sound)
			print("Son de dégâts chargé: " + sound_path)
		else:
			print("Erreur: Impossible de charger le son: " + sound_path)

func play_random_hurt_sound():
	if hurt_sounds.size() == 0 or not hurt_sound:
		return
	
	# Arrêter le son précédent s'il est en cours
	if hurt_sound.playing:
		hurt_sound.stop()
	
	# Choisir un son aléatoire
	var random_index = randi() % hurt_sounds.size()
	hurt_sound.stream = hurt_sounds[random_index]
	hurt_sound.play()
	print("Son de dégâts joué: human-hurt-song-" + str(random_index + 1))
