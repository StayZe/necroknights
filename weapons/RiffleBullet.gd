extends Projectile
class_name RiffleBullet

func _ready():
	# Vitesse spécifique pour le fusil d'assaut
	speed = 700.0
	
	# Réduire la taille par 4
	scale = Vector2(0.25, 0.25)

# Override pour appliquer l'orientation quand la direction est définie
func set_direction(new_direction: Vector2):
	direction = new_direction
	# Orienter le sprite selon la direction de tir avec correction de -90°
	if direction != Vector2.ZERO:
		rotation = direction.angle() - PI/2 