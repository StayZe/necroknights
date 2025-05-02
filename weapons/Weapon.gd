extends Node2D
class_name Weapon  # Permet aux autres armes d'hériter facilement de cette classe

# 📌 Variables configurables pour toutes les armes
@export var fire_rate: float = 0.5  # Cadence de tir (secondes entre chaque tir)
@export var reload_time: float = 1.5  # Temps de recharge
@export var ammo: int = 10  # Nombre de balles actuelles
@export var max_ammo: int = 10  # Munitions maximum
@export var projectile_scene: PackedScene  # La scène du projectile
@export var shoot_offset: Vector2 = Vector2(10, 0)  # Décalage du spawn du tir

var can_shoot: bool = true  # Pour gérer la cadence de tir

# Signal qui va être émis pour gérer le tir
signal shoot_projectile(direction: Vector2)

# 📌 Fonction appelée pour tirer
func shoot(direction: Vector2):
    if can_shoot and ammo > 0:
        ammo -= 1
        can_shoot = false
        shoot_projectile.emit(direction)  # Émet un signal pour tirer
        spawn_projectile(direction)
        await get_tree().create_timer(fire_rate).timeout  # Attente selon la cadence de tir
        can_shoot = true

# 📌 Gérer le spawn du projectile
func spawn_projectile(direction: Vector2):
    if projectile_scene:
        var projectile = projectile_scene.instantiate()
        get_parent().add_child(projectile)  # Ajoute le projectile à la scène
        projectile.global_position = global_position + shoot_offset
        projectile.direction = direction  # Applique la direction du tir

# 📌 Fonction de recharge
func reload():
    can_shoot = false
    await get_tree().create_timer(reload_time).timeout  # Attente du rechargement
    ammo = max_ammo
    can_shoot = true
