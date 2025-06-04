extends Area2D
class_name Coin

@onready var sprite = $Sprite2D
@onready var collection_area = $CollisionShape2D
@onready var animation_player = $AnimationPlayer

var float_offset = 0.0
var float_speed = 3.0
var float_amplitude = 5.0
var collected = false

func _ready():
	# Attendre une frame pour que la position soit bien définie
	await get_tree().process_frame
	
	# Connecter le signal d'entrée dans la zone de récupération
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	# S'assurer que la zone de collision est activée
	monitoring = true
	monitorable = true
	
	# Démarrer l'animation de flottaison
	start_floating_animation()

func _process(delta):
	if not collected:
		# Animation de flottaison
		float_offset += float_speed * delta
		sprite.position.y = sin(float_offset) * float_amplitude

func start_floating_animation():
	# Petite rotation pour rendre la pièce plus vivante
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(sprite, "rotation", PI * 2, 2.0)

func _on_body_entered(body):
	if collected:
		return
		
	if body.is_in_group("player"):
		collect_coin()

func collect_coin():
	if collected:
		return
		
	collected = true
	
	# Informer le GameManager que la pièce a été récupérée
	if GameManager and GameManager.has_method("add_coins"):
		GameManager.add_coins(1)
	
	# Animation de récupération (optionnel - zoom et disparition)
	var tween = create_tween()
	tween.parallel().tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.2)
	
	# Supprimer la pièce après l'animation
	await tween.finished
	queue_free() 