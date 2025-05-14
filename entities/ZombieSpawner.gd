extends Node2D
class_name ZombieSpawner

@export var zombie_scene: PackedScene
@export var spawn_distance: float = 30.0  # Distance d'activation du spawn
@export var max_zombies: int = 3  # Nombre maximum de zombies à spawner
@export var spawn_cooldown: float = 3.0  # Temps entre deux spawns

@onready var cooldown_timer = $CooldownTimer
@onready var detection_area = $DetectionArea

var player = null
var spawned_zombies = 0
var can_spawn = true

func _ready():
	cooldown_timer.wait_time = spawn_cooldown

func _process(_delta):
	if player != null and can_spawn and spawned_zombies < max_zombies:
		spawn_zombie()

func spawn_zombie():
	if zombie_scene:
		can_spawn = false
		cooldown_timer.start()
		
		var zombie = zombie_scene.instantiate()
		get_parent().add_child(zombie)
		zombie.global_position = global_position
		
		spawned_zombies += 1
		
		# Connecter le signal tree_exited du zombie pour savoir quand il est détruit
		zombie.tree_exited.connect(_on_zombie_died)

func _on_zombie_died():
	spawned_zombies -= 1

func _on_cooldown_timer_timeout():
	can_spawn = true

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		player = body

func _on_detection_area_body_exited(body):
	if body.is_in_group("player"):
		player = null 