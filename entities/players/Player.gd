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

# 📌 Gestion des armes
@export var weapon: NodePath  # L'arme actuelle du joueur (assignable dans l'inspecteur)
var current_weapon: Weapon = null  # Référence à l'arme actuelle
@export var weapon_pickup_scene: PackedScene  # La scène de pickup d'arme à utiliser

# Pour stocker le chemin de la scène de l'arme originale
var current_weapon_scene_path: String = ""

func _ready():
	# Ajouter le joueur au groupe pour la détection
	add_to_group("player")
	
	# Initialiser la santé
	health = max_health
	update_health_display()
	
	if weapon:
		current_weapon = get_node(weapon)
	
	print("Joueur initialisé - Santé: " + str(health))

func _physics_process(delta):
	get_input()
	update_facing_direction()
	move_and_slide()
	
	if current_weapon:
		handle_weapon()
		
	# Gérer la dépose d'arme avec la touche F
	if Input.is_action_just_pressed("drop") and current_weapon:
		drop_weapon()

# 📌 Gère le déplacement et les animations
func get_input():
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * SPEED

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
	if current_weapon:
		current_weapon.queue_free()  # Supprime l'ancienne arme

	# Sauvegarder le chemin de la scène de l'arme
	current_weapon_scene_path = new_weapon_scene.resource_path
	
	# Instancier la nouvelle arme
	current_weapon = new_weapon_scene.instantiate()
	add_child(current_weapon)  # Ajoute l'arme au joueur
	
	# S'assurer que l'arme est visible et correctement positionnée
	if current_weapon:
		print("Arme équipée: " + current_weapon_scene_path)
		
		# Ajuster la position initiale selon la direction actuelle
		adjust_weapon_position()
		
		# Si l'arme a une méthode pour configurer les sprites, l'appeler
		if current_weapon.has_method("configure_sprites"):
			current_weapon.configure_sprites()

# 📌 Fonction pour déposer l'arme au sol
func drop_weapon():
	if current_weapon and current_weapon_scene_path:
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
		
		# Supprimer l'arme actuelle
		current_weapon.queue_free()
		current_weapon = null
		current_weapon_scene_path = ""

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
	# À compléter avec la logique de game over 
