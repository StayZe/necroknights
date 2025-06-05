extends CharacterBody2D
class_name ZombieHeavy

enum State {
	IDLE,
	CHASE,
	HIT,
	ATTACK,
	DEATH
}

@export var speed: float = 80.0  
@export var max_health: float = 150.0
@export var attack_damage: float = 25.0
@export var attack_cooldown: float = 2

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

# Précharger la scène de pièce
var coin_scene = preload("res://entities/Coin.tscn")
# Précharger la scène de boost
var boost_scene = preload("res://entities/BoostItem.tscn")

func _ready():
	health = max_health
	attack_timer.wait_time = attack_cooldown
	add_to_group("enemy")  # Pour que les projectiles puissent détecter les zombies
	
	# Configuration des animations
	sprite.sprite_frames.set_animation_speed("idle", 10)
	sprite.sprite_frames.set_animation_speed("run", 15) 
	sprite.sprite_frames.set_animation_speed("hit", 6)  
	sprite.sprite_frames.set_animation_speed("knocked", 12)
	sprite.sprite_frames.set_animation_speed("death", 10)
	
	# Mise à jour de l'affichage de la santé
	update_health_display()
	
	# Définir l'état initial
	change_state(State.IDLE)

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
		# Déplacer le zombie vers le joueur
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * speed
		
		# Orienter le sprite
		sprite.flip_h = direction.x < 0
		
		# Si le zombie est proche du joueur, attaquer
		if global_position.distance_to(player.global_position) < 30:
			change_state(State.ATTACK)
			if can_attack:
				attack()
	
	move_and_slide()

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
	print("ZombieHeavy prend " + str(damage_amount) + " dégâts!")
	health -= damage_amount
	update_health_display()
	
	if health <= 0:
		print("ZombieHeavy tué!")
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
	# Probabilités de drop: 50% pour 2 pièces, 30% pour 3 pièces, 20% pour 4 pièces (plus de coins car plus fort)
	var random_value = randf() * 100
	var coins_to_drop = 2
	
	if random_value <= 50:
		coins_to_drop = 2
	elif random_value <= 80:
		coins_to_drop = 3
	else:
		coins_to_drop = 4
	
	# Vérifier que la scène coin existe
	if not coin_scene:
		return
	
	# Trouver le nœud parent approprié pour ajouter les pièces
	var scene_root = get_tree().current_scene
	if not scene_root:
		return
	
	# Stocker la position du zombie avant sa suppression
	var zombie_position = global_position
	
	# Créer et placer les pièces
	for i in range(coins_to_drop):
		var coin = coin_scene.instantiate()
		if not coin:
			continue
		
		# Position aléatoire autour du zombie
		var offset = Vector2(
			randf_range(-50, 50),
			randf_range(-50, 50)
		)
		var coin_position = zombie_position + offset
		
		# Ajouter la pièce à la scène d'abord
		scene_root.add_child(coin)
		
		# Puis définir la position APRÈS l'ajout à la scène
		coin.global_position = coin_position
	
	# 5% de chance de drop un boost
	var boost_chance = randf() * 100
	if boost_chance <= 50.0:
		drop_boost()

func drop_boost():
	print("🎁 Un boost va être droppé par ZombieHeavy !")
	
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
	
	# Position aléatoire autour du zombie
	var offset = Vector2(
		randf_range(-30, 30),
		randf_range(-30, 30)
	)
	var boost_position = global_position + offset
	
	# Ajouter le boost à la scène
	scene_root.add_child(boost)
	
	# Définir la position après l'ajout à la scène
	boost.global_position = boost_position

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
			print("ZombieHeavy attaque le joueur pour " + str(attack_damage) + " dégâts!")
			player.take_damage(attack_damage)
		# Vérifier si le joueur a la méthode take_damage
		elif player.has_method("take_damage"):
			print("ZombieHeavy attaque le joueur pour " + str(attack_damage) + " dégâts!")
			player.take_damage(attack_damage)
		else:
			print("Erreur: Le joueur n'a pas de méthode take_damage")

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		player = body
		change_state(State.CHASE)

func _on_detection_area_body_exited(body):
	if body == player:
		player = null
		change_state(State.IDLE)

func _on_attack_timer_timeout():
	can_attack = true

func _on_hit_timer_timeout():
	if current_state == State.HIT and health > 0:
		change_state(State.CHASE)