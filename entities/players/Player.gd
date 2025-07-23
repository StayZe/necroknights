extends CharacterBody2D
class_name Player

# 📌 Constantes et variables
const SPEED = 100.0
@onready var anim = $AnimationPlayer  # Assurez-vous qu'il correspond à votre noeud
@onready var sprite = $sprite  # Ajout pour manipuler le sprite correctement
@onready var last_direction = "walk_down"  # Mémorise la dernière direction
var player_facing_right = true  # Indique si le joueur regarde à droite ou à gauche

# 📌 Variables de santé
@export var max_health: float = 100.0
var health: float = max_health
var is_invulnerable: bool = false
var invulnerability_time: float = 0.5  # Temps d'invulnérabilité après avoir pris des dégâts

# 📌 Variables de bouclier
@export var max_shield: float = 0.0  # Par défaut, pas de bouclier
var shield: float = 0.0  # Bouclier actuel

# 📌 Son de dégâts
var hurt_sound: AudioStreamPlayer2D
var hurt_sounds: Array[AudioStream] = []

# 📌 Sons de bonus
var nuke_sound: AudioStreamPlayer2D
var bandage_sound: AudioStreamPlayer2D
var insta_kill_sound: AudioStreamPlayer2D

# 📌 Gestion des armes
@export var weapon: NodePath  # L'arme actuelle du joueur (assignable dans l'inspecteur)
var current_weapon: Weapon = null  # Référence à l'arme actuelle
@export var weapon_pickup_scene: PackedScene  # La scène de pickup d'arme à utiliser

# 📌 Système à 2 slots d'armes
var weapon_slot_1: Weapon = null  # Arme dans le slot 1
var weapon_slot_2: Weapon = null  # Arme dans le slot 2
var weapon_slot_1_scene_path: String = ""  # Chemin de la scène de l'arme du slot 1
var weapon_slot_2_scene_path: String = ""  # Chemin de la scène de l'arme du slot 2
var active_weapon_slot: int = 1  # 1 = slot 1, 2 = slot 2 (par défaut slot 1)

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
	
	# Initialiser le bouclier
	shield = 0.0
	max_shield = 0.0
	update_shield_display()
	
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
	
	# Initialiser l'inventaire d'armes après un délai pour que l'UI soit chargée
	await get_tree().create_timer(0.1).timeout
	update_weapon_inventory_display()
	
	# Donner un pistolet de départ au joueur
	pickup_weapon_from_path("res://weapons/Pistol.tscn")
	print("🔫 Pistolet de départ donné au joueur")

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
	
	# 📌 Gestion des bonus avec les touches ", ' et (
	if Input.is_action_just_pressed("bonus_slot_1"):  # "
		use_bonus_from_slot(1)
	elif Input.is_action_just_pressed("bonus_slot_2"):  # '
		use_bonus_from_slot(2)
	elif Input.is_action_just_pressed("bonus_slot_3"):  # (
		use_bonus_from_slot(3)
	
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
	
	# L'orientation du personnage est TOUJOURS basée sur la direction de la souris
	var direction_to_mouse = mouse_pos - global_position
	
	# Utiliser les composantes X et Y pour déterminer la direction principale
	# CORRECTION: Les animations sont inversées dans l'AnimationPlayer, je compense
	if anim:
		if abs(direction_to_mouse.x) > abs(direction_to_mouse.y):
			# Direction horizontale dominante
			if direction_to_mouse.x > 0:
				# Souris à droite du personnage
				last_direction = "walk-right"
				anim.play("walk-right")
			else:
				# Souris à gauche du personnage -> jouer walk-down car c'est ce qui s'affiche
				last_direction = "walk-down"
				anim.play("walk-down")
		else:
			# Direction verticale dominante
			if direction_to_mouse.y > 0:
				# Souris en bas du personnage -> jouer walk-left car c'est ce qui s'affiche 
				last_direction = "walk-left"
				anim.play("walk-left")
			else:
				# Souris en haut du personnage
				last_direction = "walk-up"
				anim.play("walk-up")
	
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
	
	# Mettre à jour l'inventaire UI
	update_weapon_inventory_display()

# 📌 Fonction pour ramasser une arme à partir d'un chemin de fichier (utilisée par le shop)
func pickup_weapon_from_path(weapon_path: String):
	# Charger la scène d'arme depuis le chemin
	var weapon_scene = load(weapon_path) as PackedScene
	if not weapon_scene:
		print("🏪 Erreur: Impossible de charger l'arme depuis: ", weapon_path)
		return
	
	# Utiliser la méthode existante pour équiper l'arme
	equip_weapon(weapon_scene)
	print("🔫 Arme ramassée depuis le shop: ", weapon_path)

# 📌 Fonction pour changer de slot d'arme actif
func switch_to_weapon_slot(slot_number: int):
	# Cacher toutes les armes
	hide_all_weapons()
	
	# Réinitialiser l'état actuel
	current_weapon = null
	current_weapon_scene_path = ""
	active_weapon_slot = slot_number
	
	# Activer l'arme du slot demandé
	match slot_number:
		1:
			if weapon_slot_1:
				current_weapon = weapon_slot_1
				current_weapon_scene_path = weapon_slot_1_scene_path
				current_weapon.visible = true
				adjust_weapon_position()
		2:
			if weapon_slot_2:
				current_weapon = weapon_slot_2
				current_weapon_scene_path = weapon_slot_2_scene_path
				current_weapon.visible = true
				adjust_weapon_position()
	
	# Mettre à jour l'inventaire UI
	update_weapon_inventory_display()

# 📌 Fonction helper pour cacher toutes les armes
func hide_all_weapons():
	if weapon_slot_1:
		weapon_slot_1.visible = false
	if weapon_slot_2:
		weapon_slot_2.visible = false

# 📌 Fonction pour déposer l'arme au sol
func drop_current_weapon():
	if not current_weapon:
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
	
	# Réinitialiser les références de l'arme actuelle
	current_weapon = null
	current_weapon_scene_path = ""
	
	# Choisir le nouveau slot actif selon la disponibilité des armes
	if active_weapon_slot == 1 and weapon_slot_2 != null:
		# Si on a lâché le slot 1 et qu'il y a une arme dans le slot 2
		switch_to_weapon_slot(2)
	elif active_weapon_slot == 2 and weapon_slot_1 != null:
		# Si on a lâché le slot 2 et qu'il y a une arme dans le slot 1
		switch_to_weapon_slot(1)
	else:
		# Aucune arme disponible dans l'autre slot
		# Garder le slot actuel mais vide, et forcer la mise à jour UI
		print("🎒 Slot ", active_weapon_slot, " maintenant vide")
		update_weapon_inventory_display()

# 📌 Fonction pour mettre à jour l'affichage de la santé
func update_health_display():
	# Trouver la WaveUI et mettre à jour la barre de santé
	var wave_ui = get_tree().get_first_node_in_group("wave_ui")
	if not wave_ui:
		# Si pas trouvée par groupe, essayer par nom
		wave_ui = get_node_or_null("/root/*/WaveUI")
	
	if wave_ui and wave_ui.has_method("update_health_bar"):
		wave_ui.update_health_bar(health, max_health)
		print("🏥 Barre de santé mise à jour: " + str(health) + "/" + str(max_health))
	else:
		print("⚠️ WaveUI non trouvée pour mettre à jour la barre de santé")

# 📌 Fonction pour mettre à jour l'affichage du bouclier
func update_shield_display():
	# Trouver la WaveUI et mettre à jour la barre de bouclier
	var wave_ui = get_tree().get_first_node_in_group("wave_ui")
	if not wave_ui:
		# Si pas trouvée par groupe, essayer par nom
		wave_ui = get_node_or_null("/root/*/WaveUI")
	
	if wave_ui and wave_ui.has_method("update_shield_bar"):
		wave_ui.update_shield_bar(shield, max_shield)
		print("🛡️ Barre de bouclier mise à jour: " + str(shield) + "/" + str(max_shield))
	else:
		print("⚠️ WaveUI non trouvée pour mettre à jour la barre de bouclier")

# 📌 Fonctions pour gérer le bouclier
func add_shield(shield_amount: int):
	max_shield += shield_amount
	shield = max_shield  # Le bouclier se remplit automatiquement
	update_shield_display()
	print("🛡️ Bouclier ajouté: +" + str(shield_amount) + " (Total: " + str(shield) + "/" + str(max_shield) + ")")

# 📌 Fonction pour mettre à jour l'inventaire d'armes dans l'UI
func update_weapon_inventory_display():
	# Trouver la WaveUI et mettre à jour l'inventaire
	var wave_ui = get_tree().get_first_node_in_group("wave_ui")
	if not wave_ui:
		# Si pas trouvée par groupe, essayer par nom
		wave_ui = get_node_or_null("/root/*/WaveUI")
	
	if wave_ui and wave_ui.has_method("update_weapon_inventory"):
		wave_ui.update_weapon_inventory(weapon_slot_1_scene_path, weapon_slot_2_scene_path, active_weapon_slot)
		print("🎒 Inventaire d'armes mis à jour - Slot actif: " + str(active_weapon_slot))
	else:
		print("⚠️ WaveUI non trouvée pour mettre à jour l'inventaire")

# 📌 Fonction pour prendre des dégâts
func take_damage(damage_amount):
	print("Joueur prend " + str(damage_amount) + " dégâts!")
	
	if is_invulnerable:
		print("Joueur invulnérable!")
		return
	
	# D'abord, vérifier si le dégât est absorbé par le bouclier
	if shield > 0:
		var absorbed_damage = min(damage_amount, shield)
		shield -= absorbed_damage
		damage_amount -= absorbed_damage
		print("Bouclier a absorbé " + str(absorbed_damage) + " dégâts. Bouclier restant: " + str(shield))
		update_shield_display()
	
	# Si il reste des dégâts après le bouclier, les appliquer à la santé
	if damage_amount > 0:
		health -= damage_amount
		update_health_display()
		print("Santé réduite de " + str(damage_amount) + ". Santé restante: " + str(health))
		
		# Jouer un son de dégâts aléatoire
		play_random_hurt_sound()
		
		# Animation de dégâts
		sprite.modulate = Color(1, 0.3, 0.3, 1)  # Teinte rouge
		
		# Vérifier si le joueur est mort
		if health <= 0:
			die()
	
	# Période d'invulnérabilité
	is_invulnerable = true
	
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
	print("🏥 Vie restaurée à 100% ! (Le bouclier n'est pas affecté)")

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
	
	# Configurer les sons de bonus
	setup_bonus_sounds()

func setup_bonus_sounds():
	# Son de la bombe atomique
	nuke_sound = AudioStreamPlayer2D.new()
	add_child(nuke_sound)
	nuke_sound.stream = preload("res://songs/nuke-sound.wav")
	nuke_sound.volume_db = -3  # Volume un peu fort pour l'impact
	
	# Son du kit de soin
	bandage_sound = AudioStreamPlayer2D.new()
	add_child(bandage_sound)
	bandage_sound.stream = preload("res://songs/bandage-sound.wav")
	bandage_sound.volume_db = -8  # Volume plus doux
	
	# Son de l'instant kill
	insta_kill_sound = AudioStreamPlayer2D.new()
	add_child(insta_kill_sound)
	insta_kill_sound.stream = preload("res://songs/insta-kill-sound.wav")
	insta_kill_sound.volume_db = -5  # Volume modéré

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

# 📌 Fonction pour ajouter un bonus à l'inventaire
func add_bonus_to_inventory(bonus_type: String) -> bool:
	# Trouver la WaveUI et ajouter le bonus à l'inventaire
	var wave_ui = get_tree().get_first_node_in_group("wave_ui")
	if not wave_ui:
		wave_ui = get_node_or_null("/root/*/WaveUI")
	
	if wave_ui and wave_ui.has_method("add_bonus_to_inventory"):
		var success = wave_ui.add_bonus_to_inventory(bonus_type)
		if success:
			print("🎁 Bonus ", bonus_type, " ajouté à l'inventaire")
		else:
			print("🎁 ÉCHEC: Inventaire de bonus plein")
		return success
	else:
		print("⚠️ WaveUI non trouvée pour ajouter le bonus")
		return false

# 📌 Fonction pour utiliser un bonus depuis l'inventaire
func use_bonus_from_slot(slot_number: int):
	# Trouver la WaveUI et utiliser le bonus
	var wave_ui = get_tree().get_first_node_in_group("wave_ui")
	if not wave_ui:
		wave_ui = get_node_or_null("/root/*/WaveUI")
	
	if wave_ui and wave_ui.has_method("use_bonus_from_inventory"):
		var bonus_type = wave_ui.use_bonus_from_inventory(slot_number)
		if bonus_type != "":
			print("🎁 Utilisation du bonus ", bonus_type, " du slot ", slot_number)
			apply_bonus_effect(bonus_type)
		else:
			print("🎁 Slot ", slot_number, " vide")
	else:
		print("⚠️ WaveUI non trouvée pour utiliser le bonus")

# 📌 Fonction pour appliquer l'effet d'un bonus
func apply_bonus_effect(bonus_type: String):
	match bonus_type:
		"atomic_bomb":
			# Jouer le son de la bombe atomique
			if nuke_sound:
				nuke_sound.play()
			# Tuer tous les zombies
			var zombies = get_tree().get_nodes_in_group("enemy")
			for zombie in zombies:
				if zombie.has_method("take_damage"):
					zombie.take_damage(9999)
			print("💣 Bombe atomique utilisée! Tous les zombies sont morts!")
			
		"medical_kit":
			# Jouer le son du kit médical
			if bandage_sound:
				bandage_sound.play()
			# Soigner le joueur complètement
			if has_method("heal_to_full"):
				heal_to_full()
			else:
				health = max_health
				update_health_display()
			print("🏥 Kit médical utilisé! Santé restaurée à 100%!")
			
		"skull":
			# Jouer le son du boost de crâne
			if insta_kill_sound:
				insta_kill_sound.play()
			# Boost de dégâts pour one-shot kill
			if has_method("apply_damage_boost"):
				apply_damage_boost(9999, 30.0)
			print("💀 Boost de crâne activé! Dégâts énormes pendant 30 secondes!")
			
		"speed_boost":
			# Pas de son spécifique pour le speed boost pour l'instant
			# Boost de vitesse
			if has_method("apply_speed_boost"):
				apply_speed_boost(1.5, 30.0)
			print("⚡ Boost de vitesse activé! +50% de vitesse pendant 30 secondes!")
			
		"shield_small":
			# Pas de son spécifique pour le bouclier pour l'instant
			# Ajouter 50 HP de bouclier
			if has_method("add_shield"):
				add_shield(50)
			else:
				print("🏪 Erreur: Le joueur n'a pas la méthode add_shield")
			print("🛡️ Petit bouclier utilisé! +50 HP de bouclier")
			
		"shield_large":
			# Pas de son spécifique pour le bouclier pour l'instant
			# Ajouter 100 HP de bouclier
			if has_method("add_shield"):
				add_shield(100)
			else:
				print("🏪 Erreur: Le joueur n'a pas la méthode add_shield")
			print("🛡️ Grand bouclier utilisé! +100 HP de bouclier")
