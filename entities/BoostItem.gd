extends Area2D
class_name BoostItem

enum BoostType {
	ATOMIC_BOMB,
	MEDICAL_KIT,
	SKULL,
	SPEED_BOOST
}

@export var boost_type: BoostType = BoostType.ATOMIC_BOMB
@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D

# Précharger les textures
var atomic_bomb_texture = preload("res://UI/bonus/atomicBomb.png")
var medical_kit_texture = preload("res://UI/bonus/medicalKit.png")
var skull_texture = preload("res://UI/bonus/skull007.png")
var speed_boost_texture = preload("res://UI/bonus/speedBoost.png")

# Sons des bonus
var nuke_sound: AudioStreamPlayer2D
var bandage_sound: AudioStreamPlayer2D
var insta_kill_sound: AudioStreamPlayer2D

var collected = false

func _ready():
	# Attendre une frame pour que la position soit bien définie
	await get_tree().process_frame
	
	# Ajouter le boost au groupe des drops pour le nettoyage automatique
	add_to_group("drops")
	
	# Connecter le signal d'entrée dans la zone de récupération
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	# S'assurer que la zone de collision est activée
	monitoring = true
	monitorable = true
	
	# Créer et configurer les sons de bonus
	setup_boost_sounds()
	
	# Configurer l'apparence selon le type de boost
	setup_boost_appearance()
	
	# Ajouter au groupe des boosts (garder pour compatibilité)
	add_to_group("boosts")

func setup_boost_sounds():
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

func setup_boost_appearance():
	if not sprite:
		return
		
	match boost_type:
		BoostType.ATOMIC_BOMB:
			sprite.texture = atomic_bomb_texture
			# Taille encore plus petite pour la bombe atomique
			sprite.scale = Vector2(0.05, 0.05)  # Encore plus petit
		BoostType.MEDICAL_KIT:
			sprite.texture = medical_kit_texture
			sprite.scale = Vector2(0.5, 0.5)
		BoostType.SKULL:
			sprite.texture = skull_texture
			sprite.scale = Vector2(0.5, 0.5)
		BoostType.SPEED_BOOST:
			sprite.texture = speed_boost_texture
			sprite.scale = Vector2(0.5, 0.5)

func _on_body_entered(body):
	if collected:
		return
		
	if body.is_in_group("player"):
		collect_boost(body)

func collect_boost(player):
	if collected:
		return
		
	collected = true
	
	# Rendre le boost invisible et non-interactable immédiatement
	collision.set_deferred("disabled", true)
	
	# Animation de récupération (comme les pièces)
	var tween = create_tween()
	tween.parallel().tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.2)
	
	# Appliquer l'effet du boost et jouer le son
	var current_sound = apply_boost_effect(player)
	
	# Attendre que l'animation de disparition soit finie
	await tween.finished
	
	# Si un son est en cours, attendre qu'il se termine
	if current_sound and current_sound.playing:
		await current_sound.finished
	
	# Supprimer le boost après que le son soit complètement fini
	queue_free()

func apply_boost_effect(player) -> AudioStreamPlayer2D:
	var current_sound: AudioStreamPlayer2D = null
	
	# Jouer le son approprié selon le type de bonus
	match boost_type:
		BoostType.ATOMIC_BOMB:
			if nuke_sound:
				nuke_sound.play()
				current_sound = nuke_sound
			apply_atomic_bomb()
		BoostType.MEDICAL_KIT:
			if bandage_sound:
				bandage_sound.play()
				current_sound = bandage_sound
			apply_medical_kit(player)
		BoostType.SKULL:
			if insta_kill_sound:
				insta_kill_sound.play()
				current_sound = insta_kill_sound
			apply_skull_boost(player)
		BoostType.SPEED_BOOST:
			# Pas de son pour l'instant
			apply_speed_boost(player)
	
	return current_sound

func apply_atomic_bomb():
	# Tuer tous les zombies sur la map
	var zombies = get_tree().get_nodes_in_group("enemy")
	for zombie in zombies:
		if zombie.has_method("take_damage"):
			zombie.take_damage(9999)  # Dégâts énormes pour tuer instantanément

func apply_medical_kit(player):
	# Soigner le joueur à 100%
	if player.has_method("heal_to_full"):
		player.heal_to_full()
	else:
		player.health = player.max_health
		player.update_health_display()

func apply_skull_boost(player):
	# Appliquer un boost de dégâts énorme pour one-shot kill
	if player.has_method("apply_damage_boost"):
		player.apply_damage_boost(9999, 30.0)  # Dégâts énormes = one-shot kill

func apply_speed_boost(player):
	# Appliquer le boost de vitesse au joueur avec une durée de 60 secondes
	if player.has_method("apply_speed_boost"):
		player.apply_speed_boost(1.5, 30.0) 