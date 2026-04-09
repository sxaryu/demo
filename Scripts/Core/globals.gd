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
var last_customer_index: int = -1  # Индекс последнего клиента (2-5)
const TOTAL_CUSTOMERS := 4  # customer 2-5 (без бабки)
const GRANDMA_INDEX := 0  # Бабка = индекс 0 (отдельный спрайт)

func get_random_customer_index() -> int:
	# Выбираем из 2-5 (исключая бабку)
	var available := range(2, 2 + TOTAL_CUSTOMERS)  # [2, 3, 4, 5]
	
	# Исключаем последнего
	if last_customer_index != -1 and last_customer_index >= 2:
		available.erase(last_customer_index)
	
	var index: int = available.pick_random()
	last_customer_index = index
	return index

func add_customer_time() -> void:
	if work_time_minutes + time_per_customer <= work_end_time:
		work_time_minutes += time_per_customer
	else:
		work_time_minutes = work_end_time

func get_formatted_time() -> String:
	var hours := work_time_minutes / 60
	var minutes := work_time_minutes % 60
	return "%02d:%02d" % [hours, minutes]

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
	last_customer_index = -1
	data_changed.emit()
