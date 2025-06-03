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
@export var attack_damage: float = 25.0
@export var attack_cooldown: float = 1.0

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

func _ready():
	health = max_health
	attack_timer.wait_time = attack_cooldown
	add_to_group("enemy")  # Pour que les projectiles puissent détecter les zombies
	
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
	
	print("💰 Zombie drop " + str(coins_to_drop) + " pièce(s)")
	
	# Vérifier que la scène coin existe
	if not coin_scene:
		print("❌ Erreur: scène coin non trouvée!")
		return
	
	# Trouver le nœud parent approprié pour ajouter les pièces
	var scene_root = get_tree().current_scene
	if not scene_root:
		print("❌ Erreur: scene_root non trouvée!")
		return
	
	# Stocker la position du zombie avant sa suppression
	var zombie_position = global_position
	print("🧟 Position du zombie: " + str(zombie_position))
	
	# Créer et placer les pièces
	for i in range(coins_to_drop):
		var coin = coin_scene.instantiate()
		if not coin:
			print("❌ Erreur: impossible d'instancier la pièce!")
			continue
		
		# Position aléatoire autour du zombie
		var offset = Vector2(
			randf_range(-50, 50),
			randf_range(-50, 50)
		)
		var coin_position = zombie_position + offset
		
		print("💰 Tentative de création pièce " + str(i+1) + " à la position: " + str(coin_position))
		
		# Ajouter la pièce à la scène d'abord
		scene_root.add_child(coin)
		
		# Puis définir la position APRÈS l'ajout à la scène
		coin.global_position = coin_position
		
		print("💰 Position finale de la pièce " + str(i+1) + ": " + str(coin.global_position))
		
		# Vérifier que la pièce a bien été ajoutée
		if coin.get_parent():
			print("✅ Pièce " + str(i+1) + " ajoutée avec succès à la position: " + str(coin.global_position))
		else:
			print("❌ Erreur: pièce " + str(i+1) + " non ajoutée!")

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
