extends Control
class_name HealthBar

@onready var health_bar_decoration = $HealthBarDecoration
@onready var health_bar_fill = $HealthBarFill

var max_health: float = 100.0
var current_health: float = 100.0
var original_width: float = 172.0  # Largeur calculée : 206 - 34 = 172

func _ready():
	print("🏥 Barre de santé initialisée")

# Fonction pour mettre à jour la santé
func update_health(health: float, max_health: float):
	self.current_health = health
	self.max_health = max_health
	
	# Calculer le pourcentage de santé
	var health_percentage = health / max_health
	health_percentage = clamp(health_percentage, 0.0, 1.0)
	
	# Calculer la nouvelle largeur
	var new_width = original_width * health_percentage
	
	# Appliquer la nouvelle largeur en changeant offset_right
	health_bar_fill.offset_right = health_bar_fill.offset_left + new_width
	
	print("🏥 Santé mise à jour: ", health, "/", max_health, " (", int(health_percentage * 100), "%)")

# Fonction pour obtenir le pourcentage de santé actuel
func get_health_percentage() -> float:
	return current_health / max_health if max_health > 0 else 0.0 