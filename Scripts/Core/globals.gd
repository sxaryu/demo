extends Node

const GRANDMA_ID := "grandma_001"
const NPC_IDS := ["npc_001", "npc_002", "npc_003", "npc_004", "npc_005"]

# --- Переменные с типизацией ---
var last_customer_id: String = ""
var last_lavash_ingredients: Array = []
var last_lavash_sauce: Array = []
var last_packed_lavash: Dictionary = {}
var last_order: Dictionary = {}
var last_lavash_weights: Dictionary = {}

# --- ГЕТТЕРЫ С КОПИРОВАНИЕМ (для save/load и защиты от мутаций) ---
## Получить копию ингредиентов последнего лаваша
func get_last_lavash_ingredients() -> Array:
	return last_lavash_ingredients.duplicate(true)

## Получить копию соуса последнего лаваша
func get_last_lavash_sauce() -> Array:
	return last_lavash_sauce.duplicate(true)

## Получить копию упакованного лаваша
func get_last_packed_lavash() -> Dictionary:
	return last_packed_lavash.duplicate(true)

## Получить копию последнего заказа
func get_last_order() -> Dictionary:
	return last_order.duplicate(true)

## Получить копию весов ингредиентов
func get_last_lavash_weights() -> Dictionary:
	return last_lavash_weights.duplicate(true)

## Установить данные последнего лаваша (копирует входные данные)
func set_last_lavash_data(ingredients: Array, sauce: Array, weights: Dictionary) -> void:
	last_lavash_ingredients = ingredients.duplicate(true)
	last_lavash_sauce = sauce.duplicate(true)
	last_lavash_weights = weights.duplicate(true)

## Установить упакованный лаваш (копирует входные данные)
func set_last_packed_lavash(data: Dictionary) -> void:
	last_packed_lavash = data.duplicate(true)

## Установить заказ (копирует входные данные)
func set_last_order(order: Dictionary) -> void:
	last_order = order.duplicate(true)

# --- Таймер рабочего дня ---
var work_time_minutes: int = 12 * 60  # Начинаем с 12:00 (в минутах от 0:00)
var time_per_customer := 2 * 60 + 15  # 2 часа 15 минут в минутах
var work_end_time := 21 * 60  # Конец рабочего дня в 21:00
var customers_served: int = 0  # Счётчик обслуженных клиентов
var total_money: float = 0.0  # Заработанные деньги

# --- Интерфейс для работы с деньгами ---
## Получить текущее количество денег
func get_money() -> float:
	return total_money

## Установить количество денег (эмитит сигнал автоматически)
func set_money(amount: float) -> void:
	total_money = max(0.0, amount)  # Защита от отрицательных значений
	EventBus.money_changed.emit(total_money)
	EventBus.data_changed.emit()

## Добавить деньги (для наград)
func add_money(amount: float) -> float:
	total_money += amount
	EventBus.money_changed.emit(total_money)
	EventBus.data_changed.emit()
	return total_money

## Потратить деньги (возвращает true если успешно)
func spend_money(amount: float) -> bool:
	if total_money >= amount:
		total_money -= amount
		EventBus.money_changed.emit(total_money)
		EventBus.data_changed.emit()
		return true
	return false

## Проверить достаточность средств
func has_money(amount: float) -> bool:
	return total_money >= amount

# --- Клиенты ---
var last_customer_state: int = 0  # Состояние клиента (0=ENTERING, 1=ORDERING, 2=WAITING)
var last_customer_order: Dictionary = {}  # Заказ клиента

# === ДОБАВЛЕНО: Цены ингредиентов ===
const INGREDIENT_COSTS := {
	"lavash": 15.0,
	"meat": 10.0,
	"tomato": 2.0,
	"salad": 2.0,
	"cheese": 3.0,
	"onion": 2.0,
	"pepper": 2.0,
	"white_sauce": 0.1,
	"spicy_sauce": 0.1
}

# === ДОБАВЛЕНО: Функция получения цены ===
func get_ingredient_cost(ingredient_type: String, grams: int = 0) -> float:
	var base_cost: float = INGREDIENT_COSTS.get(ingredient_type, 0.0)
	if grams > 0:
		var cost := base_cost * grams / 100.0
		return max(0.01, cost) if base_cost > 0 else 0.0
	return base_cost

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
	total_money = 0.0
	last_customer_id = ""
	EventBus.data_changed.emit()
	EventBus.money_changed.emit(total_money)

## Полный сброс данных (включая деньги) - для новой игры
func clear_all_data() -> void:
	clear_data()
	total_money = 0.0
	EventBus.data_changed.emit()
	EventBus.money_changed.emit(total_money)
