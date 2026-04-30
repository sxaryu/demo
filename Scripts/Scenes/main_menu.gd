extends Control

<<<<<<< HEAD
const SAVE_FILE_PATH := "user://shawarma_save.dat"

func _ready():
=======
func _ready() -> void:
>>>>>>> c33e8377b6fd006e3771648747071697b41d5043
	$PlayButton.pressed.connect(_on_play_button_pressed)
	$ContinueButton.pressed.connect(_on_continue_button_pressed)
	$QuitButton.pressed.connect(_on_exit_button_pressed)
	$SettingsButton.pressed.connect(_on_settings_button_pressed)
<<<<<<< HEAD

	# Скрываем кнопку "Продолжить", если нет сохранения
	if not _has_save_file():
		$ContinueButton.visible = false

func _has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)

func _on_play_button_pressed():
	# Новая игра - сбрасываем все данные
	Globals.clear_all_data()
	get_tree().change_scene_to_file("res://Scenes/Intro.tscn")

func _on_continue_button_pressed():
	# Продолжение игры - загружаем сохранение
	Globals._load_full_progress()
	# Определяем сцену для загрузки на основе состояния
	if Globals.is_work_day_over():
		get_tree().change_scene_to_file("res://Scenes/EndDay.tscn")
	elif not Globals.last_order.is_empty():
		get_tree().change_scene_to_file("res://Scenes/Hall.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/Intro.tscn")

func _on_exit_button_pressed():
	get_tree().quit()
	print("Выход из игры")

func _on_settings_button_pressed():
	var settings_scene := preload("res://Scenes/UI/SettingsPanel.tscn").instantiate()
=======

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Intro.tscn")

func _on_exit_button_pressed() -> void:
	get_tree().quit()
	print("Выход из игры")

func _on_settings_button_pressed() -> void:
	var settings_scene: Control = preload("res://Scenes/UI/SettingsPanel.tscn").instantiate()
>>>>>>> c33e8377b6fd006e3771648747071697b41d5043
	get_tree().current_scene.add_child(settings_scene)
