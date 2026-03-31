extends Node2D

@onready var quit_button: Button = $QuitButton

const SCENE_MAIN_MENU := preload("res://Scenes/MainMenu.tscn")

func _ready() -> void:
	quit_button.pressed.connect(_on_exit_button_pressed)

func _on_exit_button_pressed() -> void:
	get_tree().quit()
