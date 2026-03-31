extends Control

func _ready():
	$PlayButton.pressed.connect(_on_play_button_pressed)
	$TutorialButton.pressed.connect(_on_tutorial_button_pressed)
	$QuitButton.pressed.connect(_on_exit_button_pressed)

func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/Game/Hall.tscn")
	print("Загружаем зал...")

func _on_tutorial_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/Tutorial/TutorialHall.tscn")
	print("Загружаем обучение...")

func _on_exit_button_pressed():
	get_tree().quit()
	print("Выход из игры")
