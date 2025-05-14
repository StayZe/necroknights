extends TextureButton

func _ready() -> void:
	connect("pressed", Callable(self, "_on_cross_pressed"))

func _on_cross_pressed() -> void:
	get_parent().visible = false
