extends CanvasLayer
class_name WaveUI

@onready var wave_label = $UI/WaveInfo/WaveLabel
@onready var zombies_label = $UI/WaveInfo/ZombiesLabel
@onready var record_label = $UI/WaveInfo/RecordLabel
@onready var coins_label = $UI/WaveInfo/CoinsLabel
@onready var pause_timer = $UI/PauseTimer

var current_wave_active = false

func _ready():
	# Se connecter aux signaux du WaveManager
	if WaveManager:
		WaveManager.wave_started.connect(_on_wave_started)
		WaveManager.wave_completed.connect(_on_wave_completed)
		WaveManager.wave_break_started.connect(_on_wave_break_started)
		WaveManager.wave_break_updated.connect(_on_wave_break_updated)
	
	# Se connecter au signal de pièces du GameManager
	if GameManager:
		GameManager.coins_changed.connect(_on_coins_changed)
		# Initialiser l'affichage des pièces
		_on_coins_changed(GameManager.get_coins())
	
	# Charger et afficher le record initial
	_update_record_display()

func _process(_delta):
	# Mettre à jour le compte de zombies pendant une manche active
	if current_wave_active and WaveManager:
		var wave_info = WaveManager.get_current_wave_info()
		var killed = wave_info.zombies_total - wave_info.zombies_remaining
		zombies_label.text = "Zombies: " + str(killed) + "/" + str(wave_info.zombies_total)

func _on_coins_changed(new_amount: int):
	if coins_label:
		coins_label.text = "💰 Pièces: " + str(new_amount)

func _on_wave_started(wave_number: int):
	current_wave_active = true
	wave_label.text = "Manche " + to_roman(wave_number)
	
	# Obtenir les infos de la manche pour le total de zombies
	if WaveManager:
		var wave_info = WaveManager.get_current_wave_info()
		zombies_label.text = "Zombies: 0/" + str(wave_info.zombies_total)
	
	pause_timer.visible = false

func _on_wave_completed(wave_number: int):
	current_wave_active = false

func _on_wave_break_started(time_left: float):
	pause_timer.text = "Pause: " + str(int(time_left)) + "s\nSanté régénérée!"
	pause_timer.visible = true

func _on_wave_break_updated(time_left: int):
	pause_timer.text = "Pause: " + str(time_left) + "s\nSanté régénérée!"

func _update_record_display():
	if WaveManager:
		record_label.text = "Record: " + str(WaveManager.max_wave_completed) + " manches"

# Fonction pour convertir un nombre en chiffres romains
func to_roman(num: int) -> String:
	if num <= 0:
		return ""
	
	var values = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1]
	var numerals = ["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"]
	
	var result = ""
	var i = 0
	
	while num > 0:
		while num >= values[i]:
			result += numerals[i]
			num -= values[i]
		i += 1
	
	return result 
