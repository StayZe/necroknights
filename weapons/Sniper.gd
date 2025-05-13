extends Weapon  # Hérite de la classe Weapon

@onready var sprite = $Sprite2D  # Référence au sprite
@onready var shootDelay = $ShootDelay  # Timer pour le délai entre les tirs
@onready var reloadTimer = $ReloadTimer  # Timer pour le rechargement
@onready var flickerTimer = $FlickerTimer  # Timer pour l'animation de flicker
@onready var animationPlayer = $AnimationPlayer  # Reference to the animation player

# Preload sprites for quick access
var flicker_texture = preload("res://sprites/weapons/Sniper_Flicker.png")
var shoot_texture = preload("res://sprites/weapons/Sniper_Shoot.png")
var current_texture = null
var is_shooting = false  # Pour éviter de tirer pendant une animation en cours
var player_facing_right = true  # Direction à laquelle le joueur fait face
var player_direction = "right"  # Direction du joueur (right, left, up, down)

func _ready():
	fire_rate = 0.8  # Tir plus lent que le pistol
	reload_time = 2.0  # Temps de recharge plus long
	ammo = 8
	max_ammo = 8
	
	# Set initial texture
	current_texture = flicker_texture
	sprite.texture = current_texture
	
	# Configure les spritesheets
	configure_sprites()
	
	# Start the flickering timer
	flickerTimer.start()
	
	# Configurer le timer de tir pour qu'il corresponde à l'animation
	shootDelay.wait_time = fire_rate
	
	# Connecter le signal d'animation terminée
	if animationPlayer:
		animationPlayer.animation_finished.connect(_on_animation_finished)

# Configure les spritesheets selon leur contenu
func configure_sprites():
	# Configurer le sprite Sniper_Flicker
	if sprite.texture == flicker_texture:
		sprite.hframes = 7  # 7 frames horizontales 
		sprite.frame = 0    # Commencer à la première frame

func _process(_delta):
	# Obtenir la position de la souris et la position du joueur
	var mouse_pos = get_global_mouse_position()
	var player_pos = get_parent().global_position if get_parent() else global_position
	
	# Déterminer si le joueur regarde à droite ou à gauche en fonction de la souris
	player_facing_right = mouse_pos.x > player_pos.x
	
	# Vérifier la direction du joueur (si parent est un joueur)
	if get_parent() and get_parent().has_method("get_last_direction"):
		player_direction = get_parent().get_last_direction()
	elif get_parent() and "last_direction" in get_parent():
		player_direction = get_parent().last_direction
	
	# Orienter le sprite horizontalement selon la direction
	sprite.flip_v = !player_facing_right
	
	# Ajuster la position de l'arme en fonction de la direction du joueur
	adjust_weapon_position()
	
	# Orienter l'arme vers la position de la souris, mais seulement si la souris est du même côté
	var angle_to_mouse = (mouse_pos - global_position).angle()
	
	# Si le joueur regarde à droite, l'arme peut viser entre -90° et 90°
	# Si le joueur regarde à gauche, l'arme peut viser entre 90° et 270°
	if player_facing_right:
		# Limiter l'angle pour qu'il soit entre -90° et 90°
		if angle_to_mouse > PI/2 and angle_to_mouse < 3*PI/2:
			angle_to_mouse = 0  # Pointer horizontalement
		rotation = angle_to_mouse
	else:
		# Limiter l'angle pour qu'il soit entre 90° et 270°
		if angle_to_mouse < PI/2 or angle_to_mouse > 3*PI/2:
			angle_to_mouse = PI  # Pointer horizontalement
		rotation = angle_to_mouse
	
	# Calculer la direction de tir
	var shoot_direction = Vector2.RIGHT if player_facing_right else Vector2.LEFT
	if player_facing_right and angle_to_mouse >= -PI/2 and angle_to_mouse <= PI/2:
		shoot_direction = Vector2.RIGHT.rotated(angle_to_mouse)
	elif !player_facing_right and angle_to_mouse >= PI/2 and angle_to_mouse <= 3*PI/2:
		shoot_direction = Vector2.LEFT.rotated(angle_to_mouse - PI)

# Ajuste la position de l'arme en fonction de la direction du personnage
func adjust_weapon_position():
	# Positions par défaut
	var right_pos = Vector2(10, 0)
	var left_pos = Vector2(-10, 0)
	var up_pos = Vector2(0, -15)  # Position pour regarder vers le haut
	var down_pos = Vector2(0, 5)  # Position pour regarder vers le bas
	
	# Déterminer la position selon la direction
	if player_direction == "walk-up" or player_direction == "walk_up":
		position = up_pos
		# Si le joueur regarde vers le haut, l'arme doit être au-dessus
		z_index = -1  # Pour s'assurer que l'arme apparaît derrière le joueur
	elif player_direction == "walk-down" or player_direction == "walk_down":
		position = down_pos
		z_index = 1  # Pour s'assurer que l'arme apparaît devant le joueur
	else:
		# Pour les directions gauche/droite, ajuster selon que le joueur regarde à gauche ou à droite
		position = right_pos if player_facing_right else left_pos
		z_index = 0  # Réinitialiser le z_index

# Override de la fonction shoot pour utiliser les timers
func shoot(direction: Vector2):
	# Obtenir la position de la souris et la position du joueur
	var mouse_pos = get_global_mouse_position()
	var player_pos = get_parent().global_position if get_parent() else global_position
	
	# Vérifier si la souris est du même côté que la direction du joueur
	var mouse_is_right = mouse_pos.x > player_pos.x
	
	# Ne tirer que si la souris est du même côté que le joueur regarde
	if (player_facing_right and mouse_is_right) or (!player_facing_right and !mouse_is_right):
		if can_shoot and ammo > 0 and !is_shooting:
			ammo -= 1
			can_shoot = false
			is_shooting = true
			emit_signal("shoot_projectile", direction)
			
			# Play shooting animation
			play_shoot_animation()
			
			spawn_projectile(direction)
			shootDelay.start()  # Démarre le timer de délai entre les tirs

# Fonction appelée quand une animation est terminée
func _on_animation_finished(anim_name: String):
	if anim_name == "shoot":
		is_shooting = false
		if shootDelay.is_stopped():
			can_shoot = true

# Override de la fonction reload pour utiliser le timer
func reload():
	if ammo < max_ammo and reloadTimer.is_stopped() and !is_shooting:
		can_shoot = false
		reloadTimer.start()  # Démarre le timer de rechargement
		await reloadTimer.timeout
		ammo = max_ammo
		can_shoot = true

# Fonction pour jouer l'animation de tir
func play_shoot_animation():
	if animationPlayer and animationPlayer.has_animation("shoot"):
		animationPlayer.play("shoot")
	else:
		# Fallback if animation is not set up
		sprite.texture = shoot_texture
		sprite.hframes = 13  # Le spritesheet du Sniper_Shoot a 13 frames
		
		# Calculer le délai entre chaque frame pour que l'animation dure exactement fire_rate secondes
		var frame_delay = fire_rate / 13
		
		# Parcourir les frames manuellement
		for i in range(13):
			sprite.frame = i
			await get_tree().create_timer(frame_delay).timeout
		
		# Revenir au sprite de base
		sprite.texture = flicker_texture
		sprite.hframes = 7
		sprite.frame = 0
		
		# Réinitialiser l'état de tir
		is_shooting = false
		if shootDelay.is_stopped():
			can_shoot = true

# Fonction pour gérer le flickering
func _on_flicker_timer_timeout():
	# Play the flicker animation uniquement si on n'est pas en train de tirer
	if !is_shooting:
		animationPlayer.play("flicker") 
