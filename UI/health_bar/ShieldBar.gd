extends Control
class_name ShieldBar

@onready var shield_bar_decoration = $ShieldBarDecoration
@onready var shield_bar_fill = $ShieldBarFill

var max_shield: float = 0.0
var current_shield: float = 0.0
var original_width: float = 172.0  # Largeur calculée : 206 - 34 = 172

func _ready():
	print("🛡️ Barre de bouclier initialisée")

# Fonction pour mettre à jour le bouclier
func update_shield(shield: float, max_shield: float):
	self.current_shield = shield
	self.max_shield = max_shield
	
	# Si pas de bouclier maximum, cacher la barre
	if max_shield <= 0:
		visible = false
		return
	else:
		visible = true
	
	# Calculer le pourcentage de bouclier
	var shield_percentage = shield / max_shield
	shield_percentage = clamp(shield_percentage, 0.0, 1.0)
	
	# Calculer la nouvelle largeur
	var new_width = original_width * shield_percentage
	
	# Appliquer la nouvelle largeur en changeant offset_right
	shield_bar_fill.offset_right = shield_bar_fill.offset_left + new_width
	
	print("🛡️ Bouclier mis à jour: ", shield, "/", max_shield, " (", int(shield_percentage * 100), "%)")

# Fonction pour obtenir le pourcentage de bouclier actuel
func get_shield_percentage() -> float:
	return current_shield / max_shield if max_shield > 0 else 0.0 