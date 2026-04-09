extends Control

func _ready():
	$PlayButton.pressed.connect(_on_play_button_pressed)
	$QuitButton.pressed.connect(_on_exit_button_pressed)

func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/Intro.tscn")

func _on_exit_button_pressed():
	get_tree().quit()
	print("Выход из игры")
