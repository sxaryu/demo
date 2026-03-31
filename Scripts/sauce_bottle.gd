extends TextureButton

@export var sauce_brush: Texture2D

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	var kitchen = get_parent() as Kitchen
	
	if kitchen:
		kitchen.enable_sauce_mode(sauce_brush)
