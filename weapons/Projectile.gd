extends Area2D
class_name Projectile

@export var speed: float = 600.0
var direction: Vector2 = Vector2.ZERO
var damage: float = 20.0  # Valeur par défaut pour le pistolet
var player_reference: Player = null  # Référence au joueur qui a tiré

func _process(delta):
	position += direction * speed * delta  # Déplacement du projectile

func _on_body_entered(body):
	if body.is_in_group("enemy"):  # Vérifie si c'est un ennemi
		# Calculer les dégâts finaux avec le multiplicateur du joueur
		var final_damage = damage
		
		if player_reference and player_reference.has_method("get_damage_multiplier"):
			var multiplier = player_reference.get_damage_multiplier()
			final_damage = damage * multiplier
		
		body.take_damage(final_damage)  # Fait des dégâts avec la valeur modifiée
		queue_free()  # Supprime le projectile
	elif not body.is_in_group("player"):  # Si ce n'est pas le joueur
		queue_free()  # Supprime le projectile quand il touche un mur par exemple

func _on_screen_exited():
	queue_free()  # Supprime le projectile quand il sort de l'écran

func set_player_reference(player: Player):
	player_reference = player
