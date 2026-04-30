extends Control

@onready var time_label: Label = $InfoPanel/TimeLabel
@onready var customers_label: Label = $InfoPanel/CustomersLabel
@onready var money_label: Label = $InfoPanel/MoneyLabel
@onready var next_day_button: Button = $NextDayButton
@onready var save_and_quit_button: Button = $SaveAndQuitButton
@onready var main_menu_button: Button = $MainMenuButton

var customers_served: int = 0

func _ready() -> void:
	# Подгружаем данные из глобальных переменных
	var final_time := Globals.get_formatted_time()
	var final_money := Globals.total_money
	var served := Globals.customers_served
	
	time_label.text = "Время: %s" % final_time
	money_label.text = "Заработано: %d₽" % final_money
	customers_label.text = "Обслужено: %d" % served
	
	next_day_button.pressed.connect(_on_next_day_pressed)
	save_and_quit_button.pressed.connect(_on_save_and_quit_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

func _on_next_day_pressed() -> void:
	# Сброс времени на следующий день
	Globals.work_time_minutes = 12 * 60
	Globals.customers_served = 0
	# НЕ сбрасываем деньги - они сохраняются между днями!
	Globals.last_packed_lavash = {}
	Globals.last_order = {}
	Globals.last_lavash_ingredients = []
	Globals.last_lavash_sauce = []
	
	# Сохраняем прогресс перед переходом на следующий день
	Globals._save_full_progress()
	
	get_tree().change_scene_to_file("res://Scenes/Hall.tscn")

func _on_save_and_quit_pressed() -> void:
	# Сохраняем текущий прогресс
	Globals._save_full_progress()
	print("Прогресс сохранён! Выход в главное меню...")
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

func _on_main_menu_pressed() -> void:
	Globals.work_time_minutes = 12 * 60
	# Полный сброс данных включая деньги
	Globals.clear_all_data()
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
