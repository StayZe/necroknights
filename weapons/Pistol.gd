extends Weapon  # Hérite de la classe Weapon

@onready var sprite = $Sprite2D  # Référence au sprite
@onready var shootDelay = $ShootDelay  # Timer pour le délai entre les tirs
@onready var reloadTimer = $ReloadTimer  # Timer pour le rechargement

func _ready():
	fire_rate = 0.4  # Tir rapide
	reload_time = 1.2  # Temps de recharge rapide
	ammo = 12
	max_ammo = 12

func _process(_delta):
	# Orienter l'arme vers la position de la souris
	look_at(get_global_mouse_position())
	
	# Retourne le sprite horizontalement si nécessaire
	if get_global_mouse_position().x < global_position.x:
		# Si la souris est à gauche du joueur
		sprite.flip_h = true
	else:
		# Si la souris est à droite du joueur
		sprite.flip_h = false

# Override de la fonction shoot pour utiliser les timers
func shoot(direction: Vector2):
	if can_shoot and ammo > 0 and shootDelay.is_stopped():
		ammo -= 1
		can_shoot = false
		emit_signal("shoot_projectile", direction)
		spawn_projectile(direction)
		shootDelay.start()  # Démarre le timer de délai entre les tirs
		await shootDelay.timeout
		can_shoot = true

# Override de la fonction reload pour utiliser le timer
func reload():
	if ammo < max_ammo and reloadTimer.is_stopped():
		can_shoot = false
		reloadTimer.start()  # Démarre le timer de rechargement
		await reloadTimer.timeout
		ammo = max_ammo
		can_shoot = true
