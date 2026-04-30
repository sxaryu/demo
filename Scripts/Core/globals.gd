extends Node

<<<<<<< HEAD
# --- Сигналы ---
signal data_changed()
signal money_changed(new_amount: float)
=======
const GRANDMA_ID := "grandma_001"
const NPC_IDS := ["npc_001", "npc_002", "npc_003", "npc_004", "npc_005"]
>>>>>>> c33e8377b6fd006e3771648747071697b41d5043

# --- Переменные с типизацией ---
var last_customer_id: String = ""
var last_lavash_ingredients: Array = []
var last_lavash_sauce: Array = []
var last_packed_lavash: Dictionary = {}
var last_order: Dictionary = {}
var last_validation_result: Dictionary = {}
var last_lavash_weights: Dictionary = {}

<<<<<<< HEAD
# --- ГЕТТЕРЫ С КОПИРОВАНИЕМ (защита от мутаций) ---
func get_last_lavash_ingredients() -> Array:
	return last_lavash_ingredients.duplicate(true)

func get_last_lavash_sauce() -> Array:
	return last_lavash_sauce.duplicate(true)

func get_last_packed_lavash() -> Dictionary:
	return last_packed_lavash.duplicate(true)

func get_last_order() -> Dictionary:
	return last_order.duplicate(true)

func get_last_lavash_weights() -> Dictionary:
	return last_lavash_weights.duplicate(true)

=======
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
>>>>>>> c33e8377b6fd006e3771648747071697b41d5043
func set_last_lavash_data(ingredients: Array, sauce: Array, weights: Dictionary) -> void:
	last_lavash_ingredients = ingredients.duplicate(true)
	last_lavash_sauce = sauce.duplicate(true)
	last_lavash_weights = weights.duplicate(true)

<<<<<<< HEAD
func set_last_packed_lavash(data: Dictionary) -> void:
	last_packed_lavash = data.duplicate(true)

func set_last_order(order: Dictionary) -> void:
	last_order = order.duplicate(true)

# --- Money API ---
func get_money() -> float:
	return total_money

func set_money(amount: float) -> void:
	total_money = max(0.0, amount)
	money_changed.emit(total_money)
	data_changed.emit()

func add_money(amount: float) -> float:
	total_money += amount
	money_changed.emit(total_money)
	data_changed.emit()
	return total_money

func spend_money(amount: float) -> bool:
	if total_money >= amount:
		total_money -= amount
		money_changed.emit(total_money)
		data_changed.emit()
		return true
	return false

func has_money(amount: float) -> bool:
	return total_money >= amount

=======
## Установить упакованный лаваш (копирует входные данные)
func set_last_packed_lavash(data: Dictionary) -> void:
	last_packed_lavash = data.duplicate(true)

## Установить заказ (копирует входные данные)
func set_last_order(order: Dictionary) -> void:
	last_order = order.duplicate(true)

>>>>>>> c33e8377b6fd006e3771648747071697b41d5043
# --- Таймер рабочего дня ---
var work_time_minutes: int = 12 * 60  # Начинаем с 12:00 (в минутах от 0:00)
var time_per_customer := 2 * 60 + 15  # 2 часа 15 минут в минутах
var work_end_time := 21 * 60  # Конец рабочего дня в 21:00
var customers_served: int = 0  # Счётчик обслуженных клиентов
var total_money: float = 0.0  # Заработанные деньги
<<<<<<< HEAD

# --- Клиенты ---
var last_customer_id: String = ""  # ID последнего клиента
var last_customer_state: int = 0  # Состояние клиента (0=ENTERING, 1=ORDERING, 2=WAITING)
var last_customer_order: Dictionary = {}  # Заказ клиента
const GRANDMA_ID := "grandma"  # ID бабки
const NPC_IDS := ["bald_man", "blonde_girl", "businessman", "ginger_man", "glasses_girl", "goth_girl", "grandpa", "pink_girl", "student"]
=======

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
>>>>>>> c33e8377b6fd006e3771648747071697b41d5043

# ==================== READY ====================
func _ready() -> void:
	# Загружаем сохранённый прогресс при запуске игры
	_load_full_progress()

# ==================== УВЕДОМЛЕНИЯ ====================
func _notification(what: int) -> void:
	# Автосохранение при закрытии игры
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("Закрытие игры - сохраняем прогресс...")
		_save_full_progress()
		get_tree().quit()

# ==================== СОХРАНЕНИЕ/ЗАГРУЗКА ====================
const SAVE_FILE_PATH := "user://shawarma_save.dat"

## Сохраняет весь прогресс игры
func _save_full_progress() -> void:
	var save_file := ConfigFile.new()
	
	# Сохраняем все данные игры
	save_file.set_value("game", "total_money", total_money)
	save_file.set_value("game", "work_time_minutes", work_time_minutes)
	save_file.set_value("game", "customers_served", customers_served)
	save_file.set_value("game", "last_customer_id", last_customer_id)
	save_file.set_value("game", "last_customer_state", last_customer_state)
	save_file.set_value("game", "last_order", last_order)
	save_file.set_value("game", "last_customer_order", last_customer_order)
	save_file.set_value("game", "last_lavash_ingredients", last_lavash_ingredients)
	save_file.set_value("game", "last_lavash_sauce", last_lavash_sauce)
	save_file.set_value("game", "last_packed_lavash", last_packed_lavash)
	save_file.set_value("game", "last_lavash_weights", last_lavash_weights)
	save_file.set_value("game", "last_validation_result", last_validation_result)
	
	var error := save_file.save(SAVE_FILE_PATH)
	if error != OK:
		push_error("Ошибка сохранения прогресса: %d" % error)
	else:
		print("Прогресс сохранён успешно!")

## Загружает весь прогресс игры
func _load_full_progress() -> void:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("Файл сохранения не найден, начинаем новую игру")
		total_money = 0.0
		work_time_minutes = 12 * 60
		customers_served = 0
		last_customer_id = ""
		last_customer_state = 0
		last_order = {}
		last_customer_order = {}
		last_lavash_ingredients = []
		last_lavash_sauce = []
		last_packed_lavash = {}
		last_lavash_weights = {}
	last_lavash_weights = {}
	last_validation_result = {}
		return

	var save_file := ConfigFile.new()
	var error := save_file.load(SAVE_FILE_PATH)
	
	if error != OK:
		push_error("Ошибка загрузки сохранения: %d" % error)
		_load_default_values()
		return
	
	# Загружаем все данные
	total_money = save_file.get_value("game", "total_money", 0.0)
	work_time_minutes = save_file.get_value("game", "work_time_minutes", 12 * 60)
	customers_served = save_file.get_value("game", "customers_served", 0)
	last_customer_id = save_file.get_value("game", "last_customer_id", "")
	last_customer_state = save_file.get_value("game", "last_customer_state", 0)
	last_order = save_file.get_value("game", "last_order", {})
	last_customer_order = save_file.get_value("game", "last_customer_order", {})
	last_lavash_ingredients = save_file.get_value("game", "last_lavash_ingredients", [])
	last_lavash_sauce = save_file.get_value("game", "last_lavash_sauce", [])
	last_packed_lavash = save_file.get_value("game", "last_packed_lavash", {})
	last_lavash_weights = save_file.get_value("game", "last_lavash_weights", {})
	last_validation_result = save_file.get_value("game", "last_validation_result", {})
	
	print("=== ЗАГРУЖЕН ПРОГРЕСС ===")
	print("Деньги: %.2f₽" % total_money)
	print("Время: %s" % get_formatted_time())
	print("Клиентов: %d" % customers_served)
	print("Последний клиент: %s" % last_customer_id)

## Загружает значения по умолчанию
func _load_default_values() -> void:
	total_money = 0.0
	work_time_minutes = 12 * 60
	customers_served = 0
	last_customer_id = ""
	last_customer_state = 0
	last_order = {}
	last_customer_order = {}
	last_lavash_ingredients = []
	last_lavash_sauce = []
	last_packed_lavash = {}
	last_validation_result = {}
	
## Сохраняет только деньги (для совместимости с существующим кодом)
func save_money() -> void:
	_save_full_progress()  # Сохраняем весь прогресс вместо одних денег

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

# ==================== ЦЕНЫ ИНГРЕДИЕНТОВ ====================
# Стоимость за 100 грамм (или за единицу)
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

func get_ingredient_cost(ingredient_type: String, grams: int = 0) -> float:
	var base_cost: float = INGREDIENT_COSTS.get(ingredient_type, 0.0)
	if grams > 0:
		# Для ингредиентов с весом (за 100г)
		var cost := base_cost * grams / 100.0
		return max(0.01, cost) if base_cost > 0 else 0.0  # Минимум 1 копейка
	return base_cost

func clear_data() -> void:
	last_lavash_ingredients.clear()
	last_lavash_sauce.clear()
	last_packed_lavash.clear()
	last_order.clear()
	last_lavash_weights.clear()
	last_validation_result.clear()
	customers_served = 0
	work_time_minutes = 12 * 60
<<<<<<< HEAD
	# НЕ сбрасываем деньги - они сохраняются между днями!
	last_customer_id = ""
	data_changed.emit()
	money_changed.emit(total_money)
=======
	total_money = 0.0
	last_customer_id = ""
	EventBus.data_changed.emit()
	EventBus.money_changed.emit(total_money)
>>>>>>> c33e8377b6fd006e3771648747071697b41d5043

## Полный сброс данных (включая деньги) - для новой игры
func clear_all_data() -> void:
	clear_data()
	total_money = 0.0
<<<<<<< HEAD
	
	# Удаляем файл сохранения
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var error = DirAccess.remove_absolute(SAVE_FILE_PATH)
		if error != OK:
			push_error("Ошибка удаления файла сохранения: %d" % error)
		else:
			print("Файл сохранения удалён")
	
	data_changed.emit()
	money_changed.emit(total_money)
=======
	EventBus.data_changed.emit()
	EventBus.money_changed.emit(total_money)
>>>>>>> c33e8377b6fd006e3771648747071697b41d5043
