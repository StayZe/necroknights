extends Node2D
class_name WeaponPickup

# Le type d'arme que ce pickup représente
@export var weapon_scene: PackedScene

# Animation pour l'effet de flottaison
var time = 0
var float_height = 5
var float_speed = 2

# État initial
var initial_position: Vector2

func _ready():
	# Sauvegarde de la position initiale pour l'animation de flottaison
	initial_position = position
	
	# Ajouter le sprite de l'arme si nécessaire
	if $Sprite2D and weapon_scene:
		# Vérifier si c'est un pistolet (exemple spécifique)
		var weapon_path = weapon_scene.resource_path
		if "Pistol" in weapon_path:
			# S'assurer que la texture est correctement configurée
			$Sprite2D.texture = preload("res://sprites/weapons/Pistol_Flicker.png")
			
			# Configurer le spritesheet
			$Sprite2D.hframes = 7  # 7 frames horizontales comme vu dans l'image
			$Sprite2D.frame = 0    # Première frame par défaut
			
			# Taille originale de l'arme
			$Sprite2D.scale = Vector2(1.0, 1.0)

var player_in_range = false
var current_player = null
var anim_timer = 0.0  # Pour l'animation de frame au sol

func _process(delta):
	# Animation de flottaison
	time += delta
	position.y = initial_position.y + sin(time * float_speed) * float_height
	
	# Animation de rotation légère - vérifier que le sprite existe avant de modifier sa rotation
	if has_node("Sprite2D") and $Sprite2D:
		$Sprite2D.rotation_degrees = sin(time * 1.5) * 5  # Rotation de +/- 5 degrés
		
		# Animation simple du spritesheet pour l'arme au sol
		if $Sprite2D.hframes > 1:
			anim_timer += delta
			if anim_timer >= 0.3:  # Changer de frame toutes les 0.3 secondes
				anim_timer = 0.0
				$Sprite2D.frame = ($Sprite2D.frame + 1) % $Sprite2D.hframes
	
	# Vérifier si le joueur peut ramasser l'arme
	if player_in_range and Input.is_action_just_pressed("pickup"):
		if current_player and current_player.has_method("equip_weapon"):
			current_player.equip_weapon(weapon_scene)
			queue_free()  # Supprimer le pickup après ramassage

func _on_interaction_area_body_entered(body):
	if body.is_in_group("player") or body.name == "player":
		player_in_range = true
		current_player = body
		show_pickup_prompt()

func _on_interaction_area_body_exited(body):
	if body.is_in_group("player") or body.name == "player":
		player_in_range = false
		current_player = null
		hide_pickup_prompt()

# Afficher une indication visuelle pour ramasser
func show_pickup_prompt():
	if $PickupPrompt:
		$PickupPrompt.visible = true

# Cacher l'indication
func hide_pickup_prompt():
	if $PickupPrompt:
		$PickupPrompt.visible = false 
