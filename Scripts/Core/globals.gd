extends Node

# --- Сигналы ---
signal data_changed()

# --- Переменные с типизацией ---
var last_lavash_ingredients: Array = []
var last_lavash_sauce: Array = []
var last_packed_lavash: Dictionary = {}
var last_order: Dictionary = {}
var last_lavash_weights: Dictionary = {}

# --- Таймер рабочего дня ---
var work_time_minutes: int = 12 * 60  # Начинаем с 12:00 (в минутах от 0:00)
var time_per_customer := 2 * 60 + 15  # 2 часа 15 минут в минутах
var work_end_time := 21 * 60  # Конец рабочего дня в 21:00
var customers_served: int = 0  # Счётчик обслуженных клиентов
var total_money: int = 0  # Заработанные деньги

# --- Клиенты ---
var last_customer_id: String = ""  # ID последнего клиента
const GRANDMA_ID := "grandma"  # ID бабки
const NPC_IDS := ["bald_man", "blonde_girl", "businessman", "ginger_man", "glasses_girl", "goth_girl", "grandpa", "pink_girl", "student"]

func get_random_customer_id() -> String:
	var available := NPC_IDS.duplicate()
	
	# Исключаем последнего
	if last_customer_id != "" and last_customer_id != GRANDMA_ID:
		available.erase(last_customer_id)
	
	var id: String = available.pick_random()
	last_customer_id = id
	return id

func add_customer_time() -> void:
	if work_time_minutes + time_per_customer <= work_end_time:
		work_time_minutes += time_per_customer
	else:
		work_time_minutes = work_end_time

func get_formatted_time() -> String:
	var hours := work_time_minutes / 60.0
	var minutes := work_time_minutes % 60
	return "%02d:%02d" % [int(hours), minutes]

func is_work_day_over() -> bool:
	return work_time_minutes >= work_end_time

func clear_data() -> void:
	last_lavash_ingredients.clear()
	last_lavash_sauce.clear()
	last_packed_lavash.clear()
	last_order.clear()
	last_lavash_weights.clear()
	customers_served = 0
	work_time_minutes = 12 * 60
	total_money = 0
	last_customer_id = ""
	data_changed.emit()
