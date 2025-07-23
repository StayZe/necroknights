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

# Son de rechargement
var reload_sound: AudioStreamPlayer2D
var reload_base_duration: float = 1.8  # Durée de base du son de rechargement en secondes

# Son d'arme vide
var empty_gun_sound: AudioStreamPlayer2D

# Signal qui va être émis pour gérer le tir
signal shoot_projectile(direction: Vector2)

func _ready():
	# Créer et configurer le son de rechargement
	reload_sound = AudioStreamPlayer2D.new()
	add_child(reload_sound)
	reload_sound.stream = preload("res://songs/reload-gun-sound.wav")
	reload_sound.volume_db = -5  # Ajuster le volume si nécessaire
	
	# Créer et configurer le son d'arme vide
	empty_gun_sound = AudioStreamPlayer2D.new()
	add_child(empty_gun_sound)
	empty_gun_sound.stream = preload("res://songs/empty-gun-sound.wav")
	empty_gun_sound.volume_db = -3  # Ajuster le volume si nécessaire

# 📌 Fonction appelée pour tirer
func shoot(direction: Vector2):
	if can_shoot and ammo > 0:
		ammo -= 1
		can_shoot = false
		shoot_projectile.emit(direction)  # Émet un signal pour tirer
		spawn_projectile(direction)
		await get_tree().create_timer(fire_rate).timeout  # Attente selon la cadence de tir
		can_shoot = true
	elif can_shoot and ammo <= 0:
		# Jouer le son d'arme vide
		if empty_gun_sound:
			empty_gun_sound.stop()
			empty_gun_sound.play()

# 📌 Gérer le spawn du projectile
func spawn_projectile(direction: Vector2):
	if projectile_scene:
		var projectile = projectile_scene.instantiate()
		get_parent().add_child(projectile)  # Ajoute le projectile à la scène
		projectile.global_position = global_position + shoot_offset
		
		# Utiliser la méthode set_direction pour l'orientation si elle existe
		if projectile.has_method("set_direction"):
			projectile.set_direction(direction)
		else:
			projectile.direction = direction  # Fallback pour la compatibilité
		
		# Passer la référence du joueur au projectile
		var player = get_parent()
		if player is Player and projectile.has_method("set_player_reference"):
			projectile.set_player_reference(player)

# 📌 Fonction de recharge avec son
func reload():
	if ammo >= max_ammo:
		return
		
	can_shoot = false
	play_reload_sound()
	await get_tree().create_timer(reload_time).timeout  # Attente du rechargement
	ammo = max_ammo
	can_shoot = true

# 📌 Jouer le son de rechargement avec ajustement de vitesse
func play_reload_sound():
	if reload_sound and reload_sound.stream:
		# Calculer le pitch_scale pour ajuster la vitesse du son
		# Si reload_time est plus court que la durée de base, accélérer le son
		# Si reload_time est plus long que la durée de base, ralentir le son
		var pitch_scale = reload_base_duration / reload_time
		
		# Limiter le pitch entre 0.5 et 2.0 pour éviter des sons trop déformés
		pitch_scale = clamp(pitch_scale, 0.5, 2.0)
		
		reload_sound.pitch_scale = pitch_scale
		reload_sound.play()
