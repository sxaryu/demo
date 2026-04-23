extends Control

func _ready() -> void:
	$PlayButton.pressed.connect(_on_play_button_pressed)
	$QuitButton.pressed.connect(_on_exit_button_pressed)
	$SettingsButton.pressed.connect(_on_settings_button_pressed)

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Intro.tscn")

func _on_exit_button_pressed() -> void:
	get_tree().quit()
	print("Выход из игры")

func _on_settings_button_pressed() -> void:
	var settings_scene: Control = preload("res://Scenes/UI/SettingsPanel.tscn").instantiate()
	get_tree().current_scene.add_child(settings_scene)
