extends Node2D
class_name ZombieSpawner

# Signaux
signal zombie_died()

@export var zombie_basic_scene: PackedScene = preload("res://entities/Zombie.tscn")
@export var zombie_heavy_scene: PackedScene = preload("res://entities/ZombieHeavy.tscn")
@export var zombie_arabic_scene: PackedScene = preload("res://entities/ZombieArabic.tscn")
@export var spawn_distance: float = 30.0  # Distance d'activation du spawn

@onready var cooldown_timer = $CooldownTimer
@onready var detection_area = $DetectionArea

var player = null
var spawned_zombies = 0
var can_spawn = true

# Variables pour le système de manches
var is_active_for_wave = false
var zombies_quota_for_wave = 0
var zombies_spawned_this_wave = 0
var wave_spawn_interval = 3.0
var current_wave_number = 1

func _ready():
	# S'enregistrer auprès du WaveManager si il existe
	if get_node_or_null("/root/WaveManager"):
		WaveManager.register_spawner(self)
	
	cooldown_timer.wait_time = wave_spawn_interval

func _process(_delta):
	# Ne spawner que si:
	# 1. Le joueur est détecté
	# 2. Le spawner est actif pour la manche
	# 3. On peut spawner (cooldown)
	# 4. On n'a pas atteint le quota pour cette manche
	if player != null and is_active_for_wave and can_spawn and zombies_spawned_this_wave < zombies_quota_for_wave:
		spawn_zombie()

# Configuration pour une nouvelle manche
func setup_for_wave(spawn_interval: float, total_zombies: int, wave_number: int = 1):
	wave_spawn_interval = spawn_interval
	zombies_quota_for_wave = total_zombies
	zombies_spawned_this_wave = 0
	is_active_for_wave = true
	can_spawn = true
	current_wave_number = wave_number
	
	# Mettre à jour le timer
	cooldown_timer.wait_time = wave_spawn_interval
	
	print("Spawner configuré - Manche: " + str(wave_number) + ", Intervalle: " + str(spawn_interval) + "s, Quota: " + str(total_zombies))

# Arrêter le spawn pour cette manche
func stop_spawning():
	is_active_for_wave = false
	can_spawn = false
	if cooldown_timer:
		cooldown_timer.stop()
	print("Spawner arrêté")

# Fonction pour déterminer le type de zombie à spawner selon la manche
func get_zombie_type_for_wave() -> PackedScene:
	var random_value = randf() * 100
	
	# Manche 1-4: 100% Basic
	if current_wave_number >= 1 and current_wave_number <= 4:
		return zombie_basic_scene
	
	# Manche 5-10: 75% Basic, 25% Heavy
	elif current_wave_number >= 5 and current_wave_number <= 10:
		if random_value <= 75.0:
			return zombie_basic_scene
		else:
			return zombie_heavy_scene
	
	# Manche 11-15: 40% Basic, 35% Heavy, 25% Arabic
	elif current_wave_number >= 11 and current_wave_number <= 15:
		if random_value <= 40.0:
			return zombie_basic_scene
		elif random_value <= 75.0:  # 40% + 35% = 75%
			return zombie_heavy_scene
		else:
			return zombie_arabic_scene
	
	# Manche 16+: 25% Basic, 40% Heavy, 35% Arabic
	else:
		if random_value <= 25.0:
			return zombie_basic_scene
		elif random_value <= 65.0:  # 25% + 40% = 65%
			return zombie_heavy_scene
		else:
			return zombie_arabic_scene

func spawn_zombie():
	if is_active_for_wave:
		can_spawn = false
		cooldown_timer.start()
		
		# Sélectionner le type de zombie selon la manche
		var zombie_scene_to_spawn = get_zombie_type_for_wave()
		
		if zombie_scene_to_spawn:
			var zombie = zombie_scene_to_spawn.instantiate()
			get_parent().add_child(zombie)
			zombie.global_position = global_position
			
			spawned_zombies += 1
			zombies_spawned_this_wave += 1
			
			# Notifier le WaveManager qu'un zombie a été spawné
			if get_node_or_null("/root/WaveManager"):
				WaveManager.notify_zombie_spawned()
			
			# Connecter le signal tree_exited du zombie pour savoir quand il est détruit
			zombie.tree_exited.connect(_on_zombie_died)
			
			# Afficher le type de zombie spawné
			var zombie_type = "Basic"
			if zombie_scene_to_spawn == zombie_heavy_scene:
				zombie_type = "Heavy"
			elif zombie_scene_to_spawn == zombie_arabic_scene:
				zombie_type = "Arabic"
			
			print("Zombie " + zombie_type + " spawné! (" + str(zombies_spawned_this_wave) + "/" + str(zombies_quota_for_wave) + " pour la manche " + str(current_wave_number) + ")")

func _on_zombie_died():
	spawned_zombies -= 1
	# Émettre le signal pour le WaveManager
	zombie_died.emit()

func _on_cooldown_timer_timeout():
	can_spawn = true

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		player = body

func _on_detection_area_body_exited(body):
	if body.is_in_group("player"):
		player = null 
