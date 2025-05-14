extends Button

@export var action_type: String  # "start", "help", etc.

var target_x: float
var speed := 25.0  # vitesse de déplacement en pixels par seconde
var sound_player  # Déclaré mais pas encore initialisé

func _ready() -> void:
	target_x = position.x
	connect("mouse_entered", Callable(self, "_on_Button_mouse_entered"))
	connect("mouse_exited", Callable(self, "_on_Button_mouse_exited"))
	connect("pressed", Callable(self, "_on_Button_pressed"))

	# Initialiser le sound_player ici, une fois que la scène est prête
	if get_parent().has_node("HoverSound"):
		sound_player = get_parent().get_node("HoverSound")

func _process(delta: float) -> void:
	position.x = lerp(position.x, target_x, speed * delta)

func _on_Button_mouse_entered() -> void:
	target_x = position.x + 5
	if sound_player:
		sound_player.play()

func _on_Button_mouse_exited() -> void:
	target_x = position.x - 5

func _on_Button_pressed() -> void:
	match action_type:
		"start":
			get_tree().change_scene_to_file("res://player.tscn")  # ← adapte ce chemin
		"help":
			var label = get_parent().get_node("Label")
			label.visible = true
		_:
			print("Aucune action définie pour :", action_type)
