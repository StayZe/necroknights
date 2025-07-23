extends Control
class_name BonusInventory

@onready var slot1 = $HBoxContainer/Slot1
@onready var slot2 = $HBoxContainer/Slot2
@onready var slot3 = $HBoxContainer/Slot3
@onready var slot1_icon = $HBoxContainer/Slot1/BonusIcon
@onready var slot2_icon = $HBoxContainer/Slot2/BonusIcon
@onready var slot3_icon = $HBoxContainer/Slot3/BonusIcon

# Textures des bonus
var atomic_bomb_texture = preload("res://UI/bonus/atomicBomb.png")
var medical_kit_texture = preload("res://UI/bonus/medicalKit.png")
var skull_texture = preload("res://UI/bonus/skull007.png")
var speed_boost_texture = preload("res://UI/bonus/speedBoost.png")
var shield_texture = preload("res://UI/bonus/shieldPlate.png")

# Styles pour les bordures
var normal_border_style: StyleBoxFlat
var ready_border_style: StyleBoxFlat

# Inventaire des bonus (nom du bonus dans chaque slot, ou "" si vide)
var bonus_slots = ["", "", ""]

func _ready():
	# Créer les styles de bordure
	create_border_styles()
	
	# Initialiser les slots vides
	clear_all_slots()
	
	print("🎁 Inventaire de bonus initialisé")

func create_border_styles():
	# Style normal (bordure grise)
	normal_border_style = StyleBoxFlat.new()
	normal_border_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)  # Fond gris foncé
	normal_border_style.border_width_left = 2
	normal_border_style.border_width_top = 2
	normal_border_style.border_width_right = 2
	normal_border_style.border_width_bottom = 2
	normal_border_style.border_color = Color(0.7, 0.7, 0.7, 0.7)  # Bordure grise
	
	# Style prêt à utiliser (bordure dorée)
	ready_border_style = StyleBoxFlat.new()
	ready_border_style.bg_color = Color(0.3, 0.3, 0.2, 0.9)  # Fond légèrement doré
	ready_border_style.border_width_left = 3
	ready_border_style.border_width_top = 3
	ready_border_style.border_width_right = 3
	ready_border_style.border_width_bottom = 3
	ready_border_style.border_color = Color(1, 0.84, 0, 1)  # Bordure dorée

func add_bonus_to_slot(bonus_type: String) -> bool:
	# Trouver le premier slot libre
	for i in range(3):
		if bonus_slots[i] == "":
			bonus_slots[i] = bonus_type
			set_bonus_in_slot(i + 1, bonus_type)
			return true
	
	print("🎁 Tous les slots de bonus sont pleins!")
	return false

func set_bonus_in_slot(slot_number: int, bonus_type: String):
	var texture = get_bonus_texture(bonus_type)
	
	match slot_number:
		1:
			slot1_icon.texture = texture
			slot1_icon.visible = texture != null
			slot1.add_theme_stylebox_override("panel", ready_border_style if texture != null else normal_border_style)
		2:
			slot2_icon.texture = texture
			slot2_icon.visible = texture != null
			slot2.add_theme_stylebox_override("panel", ready_border_style if texture != null else normal_border_style)
		3:
			slot3_icon.texture = texture
			slot3_icon.visible = texture != null
			slot3.add_theme_stylebox_override("panel", ready_border_style if texture != null else normal_border_style)
	
	print("🎁 Bonus ", bonus_type, " ajouté au slot ", slot_number)

func use_bonus_in_slot(slot_number: int) -> String:
	var slot_index = slot_number - 1
	if slot_index >= 0 and slot_index < 3 and bonus_slots[slot_index] != "":
		var bonus_type = bonus_slots[slot_index]
		bonus_slots[slot_index] = ""
		clear_slot(slot_number)
		print("🎁 Bonus ", bonus_type, " utilisé du slot ", slot_number)
		return bonus_type
	
	return ""

func clear_slot(slot_number: int):
	match slot_number:
		1:
			slot1_icon.texture = null
			slot1_icon.visible = false
			slot1.add_theme_stylebox_override("panel", normal_border_style)
		2:
			slot2_icon.texture = null
			slot2_icon.visible = false
			slot2.add_theme_stylebox_override("panel", normal_border_style)
		3:
			slot3_icon.texture = null
			slot3_icon.visible = false
			slot3.add_theme_stylebox_override("panel", normal_border_style)

func clear_all_slots():
	for i in range(3):
		bonus_slots[i] = ""
		clear_slot(i + 1)

func get_bonus_texture(bonus_type: String) -> Texture2D:
	match bonus_type:
		"atomic_bomb":
			return atomic_bomb_texture
		"medical_kit":
			return medical_kit_texture
		"skull":
			return skull_texture
		"speed_boost":
			return speed_boost_texture
		"shield_small", "shield_large":
			return shield_texture
		_:
			return null

# Vérifier si un slot est plein
func is_slot_full(slot_number: int) -> bool:
	var slot_index = slot_number - 1
	return slot_index >= 0 and slot_index < 3 and bonus_slots[slot_index] != ""

# Obtenir le type de bonus dans un slot
func get_bonus_in_slot(slot_number: int) -> String:
	var slot_index = slot_number - 1
	if slot_index >= 0 and slot_index < 3:
		return bonus_slots[slot_index]
	return "" 