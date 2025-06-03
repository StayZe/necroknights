extends Node2D
class_name ZombieSpawner

# Signaux
signal zombie_died()

@export var zombie_scene: PackedScene
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
func setup_for_wave(spawn_interval: float, total_zombies: int):
	wave_spawn_interval = spawn_interval
	zombies_quota_for_wave = total_zombies
	zombies_spawned_this_wave = 0
	is_active_for_wave = true
	can_spawn = true
	
	# Mettre à jour le timer
	cooldown_timer.wait_time = wave_spawn_interval
	
	print("Spawner configuré - Intervalle: " + str(spawn_interval) + "s, Quota: " + str(total_zombies))

# Arrêter le spawn pour cette manche
func stop_spawning():
	is_active_for_wave = false
	can_spawn = false
	if cooldown_timer:
		cooldown_timer.stop()
	print("Spawner arrêté")

func spawn_zombie():
	if zombie_scene and is_active_for_wave:
		can_spawn = false
		cooldown_timer.start()
		
		var zombie = zombie_scene.instantiate()
		get_parent().add_child(zombie)
		zombie.global_position = global_position
		
		spawned_zombies += 1
		zombies_spawned_this_wave += 1
		
		# Notifier le WaveManager qu'un zombie a été spawné
		if get_node_or_null("/root/WaveManager"):
			WaveManager.notify_zombie_spawned()
		
		# Connecter le signal tree_exited du zombie pour savoir quand il est détruit
		zombie.tree_exited.connect(_on_zombie_died)
		
		print("Zombie spawné! (" + str(zombies_spawned_this_wave) + "/" + str(zombies_quota_for_wave) + " pour cette manche)")

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
