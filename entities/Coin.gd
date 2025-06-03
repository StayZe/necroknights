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
	print("🪙 Pièce initialisée à la position: " + str(global_position))
	
	# Vérifier que GameManager existe
	if not GameManager:
		print("❌ Erreur: GameManager non trouvé dans Coin!")
		return
	else:
		print("✅ GameManager trouvé dans Coin!")
	
	# Connecter le signal d'entrée dans la zone de récupération
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
		print("✅ Signal body_entered connecté!")
	
	# S'assurer que la zone de collision est activée
	monitoring = true
	monitorable = true
	print("✅ Monitoring activé pour la pièce!")
	
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
	print("🎯 Quelque chose entre dans la zone de la pièce: " + str(body.name) + " (position pièce: " + str(global_position) + ")")
	
	if collected:
		print("⚠️ Pièce déjà récupérée, ignorée")
		return
		
	print("🔍 Vérification des groupes du corps: " + str(body.get_groups()))
	
	if body.is_in_group("player"):
		print("✅ C'est le joueur! Récupération de la pièce...")
		collect_coin()
	else:
		print("❌ Ce n'est pas le joueur (groupes: " + str(body.get_groups()) + ")")

func collect_coin():
	if collected:
		return
		
	collected = true
	print("🪙 Récupération de la pièce!")
	
	# Vérifier que GameManager existe avant d'appeler add_coins
	if GameManager and GameManager.has_method("add_coins"):
		GameManager.add_coins(1)
		print("✅ Pièce ajoutée au GameManager!")
	else:
		print("❌ Erreur: GameManager.add_coins non disponible!")
	
	# Animation de récupération (optionnel - zoom et disparition)
	var tween = create_tween()
	tween.parallel().tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.2)
	
	# Supprimer la pièce après l'animation
	await tween.finished
	queue_free() 