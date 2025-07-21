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
	
	# Convertir le type de boost en string et essayer d'ajouter à l'inventaire
	var bonus_type_string = get_bonus_type_string()
	if player.has_method("add_bonus_to_inventory"):
		var success = player.add_bonus_to_inventory(bonus_type_string)
		if success:
			print("🎁 Bonus ", bonus_type_string, " ajouté à l'inventaire du joueur!")
			
			# Marquer comme collecté seulement si l'ajout a réussi
			collected = true
			
			# Rendre le boost invisible et non-interactable immédiatement
			collision.set_deferred("disabled", true)
			
			# Animation de récupération (comme les pièces)
			var tween = create_tween()
			tween.parallel().tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)
			tween.parallel().tween_property(self, "modulate:a", 0.0, 0.2)
			
			# Attendre que l'animation de disparition soit finie
			await tween.finished
			
			# Supprimer le boost après l'animation
			queue_free()
		else:
			print("🎁 Inventaire de bonus plein, impossible de ramasser ", bonus_type_string)
			# Ne pas marquer comme collecté, le bonus reste au sol
			return
	else:
		print("⚠️ Le joueur n'a pas la méthode add_bonus_to_inventory")

# Convertir le type enum en string pour l'inventaire
func get_bonus_type_string() -> String:
	match boost_type:
		BoostType.ATOMIC_BOMB:
			return "atomic_bomb"
		BoostType.MEDICAL_KIT:
			return "medical_kit"
		BoostType.SKULL:
			return "skull"
		BoostType.SPEED_BOOST:
			return "speed_boost"
		_:
			return ""

# Obtenir le son de ramassage approprié
func get_pickup_sound() -> AudioStreamPlayer2D:
	match boost_type:
		BoostType.ATOMIC_BOMB:
			return nuke_sound
		BoostType.MEDICAL_KIT:
			return bandage_sound
		BoostType.SKULL:
			return insta_kill_sound
		BoostType.SPEED_BOOST:
			return null  # Pas de son pour l'instant
		_:
			return null 