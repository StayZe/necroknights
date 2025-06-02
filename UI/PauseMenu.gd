extends CanvasLayer
class_name PauseMenu

@onready var ui = $UI
@onready var pause_panel = $UI/PausePanel
@onready var controls_panel = $UI/ControlsPanel

@onready var resume_button = $UI/PausePanel/VBoxContainer/ResumeButton
@onready var controls_button = $UI/PausePanel/VBoxContainer/ControlsButton
@onready var quit_button = $UI/PausePanel/VBoxContainer/QuitButton
@onready var back_button = $UI/ControlsPanel/BackButton

var is_paused = false

func _ready():
	# Connect button signals
	resume_button.pressed.connect(_on_resume_pressed)
	controls_button.pressed.connect(_on_controls_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Hide menu at start
	visible = false
	controls_panel.visible = false

func _input(event):
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause():
	if is_paused:
		resume_game()
	else:
		pause_game()

func pause_game():
	is_paused = true
	visible = true
	pause_panel.visible = true
	controls_panel.visible = false
	
	# Pause the game
	get_tree().paused = true
	
	# Give focus to first button
	resume_button.grab_focus()
	
	print("Game paused")

func resume_game():
	is_paused = false
	visible = false
	
	# Resume the game
	get_tree().paused = false
	
	print("Game resumed")

func _on_resume_pressed():
	resume_game()

func _on_controls_pressed():
	# Show controls panel
	pause_panel.visible = false
	controls_panel.visible = true
	back_button.grab_focus()

func _on_back_pressed():
	# Return to main pause menu
	controls_panel.visible = false
	pause_panel.visible = true
	controls_button.grab_focus()

func _on_quit_pressed():
	# Return to main menu
	resume_game()  # First resume game to avoid pause issues
	
	# Clean WaveManager before changing scene
	if WaveManager:
		WaveManager.cleanup()
	
	# Change scene to main menu
	get_tree().change_scene_to_file("res://main_screen/main_menu.tscn")
	print("Returning to main menu") 