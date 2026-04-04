extends TextureButton

@export var sauce_id: String = ""
@export var display_name: String = ""
@export var brush_texture: Texture2D

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	var kitchen = get_tree().get_first_node_in_group("kitchen")
	
	if kitchen and kitchen.has_method("enable_sauce_mode") and brush_texture:
		kitchen.enable_sauce_mode(sauce_id, brush_texture)
