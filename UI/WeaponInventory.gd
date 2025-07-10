extends Control
class_name WeaponInventory

@onready var slot1 = $HBoxContainer/Slot1
@onready var slot2 = $HBoxContainer/Slot2
@onready var slot1_icon = $HBoxContainer/Slot1/WeaponIcon
@onready var slot2_icon = $HBoxContainer/Slot2/WeaponIcon

# Textures des armes
var pistol_texture = preload("res://sprites/weapons/pistolFrame.png")
var riffle_texture = preload("res://sprites/weapons/riffleFrame.png")
var sniper_texture = preload("res://sprites/weapons/sniperFrame.png")

# Styles pour les bordures
var normal_border_style: StyleBoxFlat
var selected_border_style: StyleBoxFlat

func _ready():
	# Créer les styles de bordure
	create_border_styles()
	
	# Initialiser les slots vides
	clear_slot(1)
	clear_slot(2)
	
	# Définir le slot 1 comme sélectionné par défaut
	set_active_slot(1)
	
	print("🎒 Inventaire d'armes initialisé")

func create_border_styles():
	# Style normal (bordure blanche fine)
	normal_border_style = StyleBoxFlat.new()
	normal_border_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)  # Fond gris foncé
	normal_border_style.border_width_left = 2
	normal_border_style.border_width_top = 2
	normal_border_style.border_width_right = 2
	normal_border_style.border_width_bottom = 2
	normal_border_style.border_color = Color(1, 1, 1, 0.7)  # Bordure blanche
	
	# Style sélectionné (bordure blanche plus épaisse)
	selected_border_style = StyleBoxFlat.new()
	selected_border_style.bg_color = Color(0.3, 0.3, 0.3, 0.9)  # Fond gris plus clair
	selected_border_style.border_width_left = 4
	selected_border_style.border_width_top = 4
	selected_border_style.border_width_right = 4
	selected_border_style.border_width_bottom = 4
	selected_border_style.border_color = Color(1, 1, 1, 1)  # Bordure blanche plus visible

func set_weapon_in_slot(slot_number: int, weapon_path: String):
	var weapon_type = get_weapon_type_from_path(weapon_path)
	var texture = get_weapon_texture(weapon_type)
	
	if slot_number == 1:
		slot1_icon.texture = texture
		slot1_icon.visible = texture != null
	elif slot_number == 2:
		slot2_icon.texture = texture
		slot2_icon.visible = texture != null
	
	print("🎒 Arme ", weapon_type, " ajoutée au slot ", slot_number)

func clear_slot(slot_number: int):
	if slot_number == 1:
		slot1_icon.texture = null
		slot1_icon.visible = false
	elif slot_number == 2:
		slot2_icon.texture = null
		slot2_icon.visible = false
	
	print("🎒 Slot ", slot_number, " vidé")

func set_active_slot(slot_number: int):
	# Réinitialiser tous les slots au style normal
	slot1.add_theme_stylebox_override("panel", normal_border_style)
	slot2.add_theme_stylebox_override("panel", normal_border_style)
	
	# Appliquer le style sélectionné au slot actif
	if slot_number == 1:
		slot1.add_theme_stylebox_override("panel", selected_border_style)
	elif slot_number == 2:
		slot2.add_theme_stylebox_override("panel", selected_border_style)
	
	print("🎒 Slot ", slot_number, " sélectionné")

func get_weapon_type_from_path(weapon_path: String) -> String:
	var path_lower = weapon_path.to_lower()
	
	# Vérifier dans le chemin complet
	if "pistol" in path_lower:
		return "pistol"
	elif "riffle" in path_lower or "rifle" in path_lower:
		return "riffle"
	elif "sniper" in path_lower:
		return "sniper"
	else:
		# Vérifier seulement le nom du fichier
		var filename = weapon_path.get_file().to_lower()
		if "pistol" in filename:
			return "pistol"
		elif "riffle" in filename or "rifle" in filename:
			return "riffle"
		elif "sniper" in filename:
			return "sniper"
		else:
			print("⚠️ Type d'arme non reconnu pour: ", weapon_path)
			return "unknown"

func get_weapon_texture(weapon_type: String) -> Texture2D:
	match weapon_type:
		"pistol":
			return pistol_texture
		"riffle":
			return riffle_texture
		"sniper":
			return sniper_texture
		_:
			return null

# Fonction pour mettre à jour l'inventaire complet
func update_inventory(slot1_weapon: String, slot2_weapon: String, active_slot: int):
	print("🎒 Mise à jour inventaire - Slot1: '", slot1_weapon, "' Slot2: '", slot2_weapon, "' Actif: ", active_slot)
	
	# Vider tous les slots d'abord
	clear_slot(1)
	clear_slot(2)
	
	# Remplir les slots avec les armes (seulement si le chemin n'est pas vide)
	if slot1_weapon != null and slot1_weapon != "":
		set_weapon_in_slot(1, slot1_weapon)
	else:
		print("🎒 Slot 1 reste vide")
		
	if slot2_weapon != null and slot2_weapon != "":
		set_weapon_in_slot(2, slot2_weapon)
	else:
		print("🎒 Slot 2 reste vide")
	
	# Définir le slot actif
	set_active_slot(active_slot) 