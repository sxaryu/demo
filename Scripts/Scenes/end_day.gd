extends Control

@onready var time_label: Label = $InfoPanel/TimeLabel
@onready var customers_label: Label = $InfoPanel/CustomersLabel
@onready var money_label: Label = $InfoPanel/MoneyLabel

var customers_served: int = 0

func _ready() -> void:
	# Подгружаем данные из глобальных переменных
	var final_time := Globals.get_formatted_time()
	var final_money := Globals.total_money
	var served := Globals.customers_served
	
	time_label.text = "Время: %s" % final_time
	money_label.text = "Заработано: %d₽" % final_money
	customers_label.text = "Обслужено: %d" % served
	
	$NextDayButton.pressed.connect(_on_next_day_pressed)
	$MainMenuButton.pressed.connect(_on_main_menu_pressed)

func _on_next_day_pressed() -> void:
	# Сброс времени на следующий день
	Globals.work_time_minutes = 12 * 60
	Globals.customers_served = 0
	Globals.total_money = 0
	Globals.last_packed_lavash = {}
	Globals.last_order = {}
	Globals.last_lavash_ingredients = []
	Globals.last_lavash_sauce = []
	Globals.last_lavash_weights = {}
	get_tree().change_scene_to_file("res://Scenes/Hall.tscn")

func _on_main_menu_pressed() -> void:
	Globals.work_time_minutes = 12 * 60
	Globals.clear_data()
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
