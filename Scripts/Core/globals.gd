extends Node

# --- Переменные с типизацией ---
var last_customer_id: String = ""
var last_customer_state: int = 0  # 0=ENTERING, 1=ORDERING, 2=WAITING
var last_customer_order: Dictionary = {}
var last_lavash_ingredients: Array = []
var last_lavash_sauce: Array = []
var last_packed_lavash: Dictionary = {}
var last_order: Dictionary = {}
var last_validation_result: Dictionary = {}
var last_lavash_weights: Dictionary = {}

# --- Клиенты ---
const GRANDMA_ID := "grandma"
const NPC_IDS := ["bald_man", "blonde_girl", "businessman", "ginger_man", "glasses_girl", "goth_girl", "grandpa", "pink_girl", "student"]

# --- Таймер рабочего дня ---
var work_time_minutes: int = 12 * 60
var time_per_customer := 2 * 60 + 15
var work_end_time := 21 * 60
var customers_served: int = 0
var total_money: float = 0.0

# ==================== MONEY API ====================
func get_money() -> float:
	return total_money

func set_money(amount: float) -> void:
	total_money = max(0.0, amount)
	EventBus.money_changed.emit(total_money)
	EventBus.data_changed.emit()

func add_money(amount: float) -> float:
	total_money += amount
	EventBus.money_changed.emit(total_money)
	EventBus.data_changed.emit()
	return total_money

func spend_money(amount: float) -> bool:
	if total_money >= amount:
		total_money -= amount
		EventBus.money_changed.emit(total_money)
		EventBus.data_changed.emit()
		return true
	return false

func has_money(amount: float) -> bool:
	return total_money >= amount

# ==================== ГЕТТЕРЫ/СЕТТЕРЫ С КОПИРОВАНИЕМ ====================
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

func set_last_lavash_data(ingredients: Array, sauce: Array, weights: Dictionary) -> void:
	last_lavash_ingredients = ingredients.duplicate(true)
	last_lavash_sauce = sauce.duplicate(true)
	last_lavash_weights = weights.duplicate(true)

func set_last_packed_lavash(data: Dictionary) -> void:
	last_packed_lavash = data.duplicate(true)

func set_last_order(order: Dictionary) -> void:
	last_order = order.duplicate(true)

# ==================== READY ====================
func _ready() -> void:
	_load_full_progress()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		GlobalLogger.info("Закрытие игры - сохраняем прогресс...")
		_save_full_progress()
		get_tree().quit()

# ==================== СОХРАНЕНИЕ/ЗАГРУЗКА ====================
const SAVE_FILE_PATH := "user://shawarma_save.dat"

func _save_full_progress() -> void:
	var save_file := ConfigFile.new()
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
		GlobalLogger.error("Ошибка сохранения прогресса: %d" % error)
	else:
		GlobalLogger.debug("Прогресс сохранён")

func _load_full_progress() -> void:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		GlobalLogger.info("Файл сохранения не найден, начинаем новую игру")
		_load_default_values()
		return
	
	var save_file := ConfigFile.new()
	var error := save_file.load(SAVE_FILE_PATH)
	
	if error != OK:
		GlobalLogger.error("Ошибка загрузки сохранения: %d" % error)
		_load_default_values()
		return
	
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
	
	GlobalLogger.info("Прогресс загружен: %.2f₽, %s" % [total_money, get_formatted_time()])

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
	last_lavash_weights = {}
	last_validation_result = {}
	
func save_money() -> void:
	_save_full_progress()

# ==================== КЛИЕНТЫ / ВРЕМЯ ====================
func get_random_customer_id() -> String:
	var available := NPC_IDS.duplicate()
	if last_customer_id != "" and last_customer_id != GRANDMA_ID:
		available.erase(last_customer_id)
	var id: String = available.pick_random()
	last_customer_id = id
	return id

func add_customer_time() -> void:
	work_time_minutes = min(work_time_minutes + time_per_customer, work_end_time)

func get_formatted_time() -> String:
	return "%02d:%02d" % [work_time_minutes / 60, work_time_minutes % 60]

func is_work_day_over() -> bool:
	return work_time_minutes >= work_end_time

# ==================== ЦЕНЫ ИНГРЕДИЕНТОВ ====================
const INGREDIENT_COSTS := {
	"lavash": 15.0, "meat": 10.0, "tomato": 2.0, "salad": 2.0,
	"cheese": 3.0, "onion": 2.0, "pepper": 2.0,
	"white_sauce": 0.1, "spicy_sauce": 0.1
}

func get_ingredient_cost(ingredient_type: String, grams: int = 0) -> float:
	var base_cost: float = INGREDIENT_COSTS.get(ingredient_type, 0.0)
	if grams > 0:
		return max(0.01, base_cost * grams / 100.0) if base_cost > 0 else 0.0
	return base_cost

# ==================== СБРОС ДАННЫХ ====================
func clear_data() -> void:
	last_lavash_ingredients.clear()
	last_lavash_sauce.clear()
	last_packed_lavash.clear()
	last_order.clear()
	last_lavash_weights.clear()
	last_validation_result.clear()
	customers_served = 0
	work_time_minutes = 12 * 60
	last_customer_id = ""
	EventBus.data_changed.emit()
	EventBus.money_changed.emit(total_money)

func clear_all_data() -> void:
	clear_data()
	total_money = 0.0
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var error = DirAccess.remove_absolute(SAVE_FILE_PATH)
		if error != OK:
			GlobalLogger.error("Ошибка удаления сохранения: %d" % error)
	EventBus.data_changed.emit()
	EventBus.money_changed.emit(total_money)
