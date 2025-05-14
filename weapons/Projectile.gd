extends Area2D
class_name Projectile

@export var speed: float = 600.0
var direction: Vector2 = Vector2.ZERO

func _process(delta):
	position += direction * speed * delta  # Déplacement du projectile

func _on_body_entered(body):
	if body.is_in_group("enemy"):  # Vérifie si c'est un ennemi
		body.take_damage(10)  # Fait des dégâts (exemple)
		queue_free()  # Supprime le projectile
	elif not body.is_in_group("player"):  # Si ce n'est pas le joueur
		queue_free()  # Supprime le projectile quand il touche un mur par exemple

func _on_screen_exited():
	queue_free()  # Supprime le projectile quand il sort de l'écran
