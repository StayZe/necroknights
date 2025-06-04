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

var collected = false

func _ready():
	# Attendre une frame pour que la position soit bien définie
	await get_tree().process_frame
	
	# Connecter le signal d'entrée dans la zone de récupération
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	# S'assurer que la zone de collision est activée
	monitoring = true
	monitorable = true
	
	# Configurer l'apparence selon le type de boost
	setup_boost_appearance()
	
	# Ajouter au groupe des boosts
	add_to_group("boosts")

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
	
	# Appliquer l'effet du boost
	apply_boost_effect(player)
	
	# Animation de récupération (comme les pièces)
	var tween = create_tween()
	tween.parallel().tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.2)
	
	# Supprimer le boost après l'animation
	await tween.finished
	queue_free()

func apply_boost_effect(player):
	match boost_type:
		BoostType.ATOMIC_BOMB:
			apply_atomic_bomb()
		BoostType.MEDICAL_KIT:
			apply_medical_kit(player)
		BoostType.SKULL:
			apply_skull_boost(player)
		BoostType.SPEED_BOOST:
			apply_speed_boost(player)

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
		player.apply_speed_boost(2.0, 60.0) 