extends Node

# --- Константы ---
const DB_NAME := "shawarama.db"

# --- Переменные ---
var db: SQLite

func _ready() -> void:
	if not is_in_group("database"):
		add_to_group("database")
	
	GlobalLogger.info("DATABASE: старт")
	
	if db:
		GlobalLogger.info("DATABASE: уже инициализирован")
		return
	
	_init_db()

func _init_db() -> void:
	db = SQLite.new()
	db.path = DB_NAME
	db.open_db()
	GlobalLogger.info("DATABASE: БД открыта")
	
	_create_tables()
	_insert_default_data()
	GlobalLogger.info("DATABASE: Готово")

# ---------------- Таблицы ----------------
func _create_tables() -> void:
	GlobalLogger.debug("Создание таблиц...")
	
	@warning_ignore("unused_variable")
	var tables := [
		"ingredients", "recipes", "recipe_ingredients", "sauces",
		"recipe_sauces", "sizes", "orders", "player_stats"
	]
	
	_query("CREATE TABLE IF NOT EXISTS ingredients (id INTEGER PRIMARY KEY, name TEXT NOT NULL, display_name TEXT NOT NULL, max_weight INTEGER DEFAULT 100, price_per_gram REAL DEFAULT 0.5)")
	_query("CREATE TABLE IF NOT EXISTS recipes (id INTEGER PRIMARY KEY, name TEXT NOT NULL, name_accusative TEXT NOT NULL, base_meat TEXT NOT NULL)")
	_query("CREATE TABLE IF NOT EXISTS recipe_ingredients (id INTEGER PRIMARY KEY, recipe_id INTEGER NOT NULL, ingredient_id INTEGER NOT NULL, is_required INTEGER DEFAULT 1)")
	_query("CREATE TABLE IF NOT EXISTS sauces (id INTEGER PRIMARY KEY, name TEXT NOT NULL, display_name TEXT NOT NULL, price REAL DEFAULT 10)")
	_query("CREATE TABLE IF NOT EXISTS recipe_sauces (id INTEGER PRIMARY KEY, recipe_id INTEGER NOT NULL, sauce_id INTEGER NOT NULL)")
	_query("CREATE TABLE IF NOT EXISTS sizes (id INTEGER PRIMARY KEY, name TEXT NOT NULL, display_name TEXT NOT NULL, multiplier REAL NOT NULL)")
	_query("CREATE TABLE IF NOT EXISTS orders (id INTEGER PRIMARY KEY, recipe_id INTEGER NOT NULL, size_id INTEGER NOT NULL, total_weight INTEGER DEFAULT 0, price REAL DEFAULT 0, created_at TEXT DEFAULT CURRENT_TIMESTAMP, status TEXT DEFAULT 'pending')")
	_query("CREATE TABLE IF NOT EXISTS player_stats (id INTEGER PRIMARY KEY, total_money REAL DEFAULT 0, total_orders INTEGER DEFAULT 0, completed_orders INTEGER DEFAULT 0, playtime_seconds INTEGER DEFAULT 0, last_played TEXT)")
	
	GlobalLogger.debug("Таблицы созданы!")

# ---------------- Данные ----------------
func _insert_default_data() -> void:
	GlobalLogger.debug("Вставка данных...")
	
	# Ингредиенты
	_insert_if_not_exists("ingredients", [1, 'chicken', 'Курица', 100, 0.5])
	_insert_if_not_exists("ingredients", [2, 'meat', 'Говядина', 100, 0.7])
	_insert_if_not_exists("ingredients", [3, 'tomato', 'Помидор', 50, 0.3])
	_insert_if_not_exists("ingredients", [4, 'salad', 'Салат', 40, 0.2])
	_insert_if_not_exists("ingredients", [5, 'cheese', 'Сыр', 30, 0.8])
	_insert_if_not_exists("ingredients", [6, 'onion', 'Лук', 25, 0.1])
	
	# Соусы
	_insert_if_not_exists("sauces", [1, 'white_sauce', 'Белый', 10])
	_insert_if_not_exists("sauces", [2, 'red_sauce', 'Красный', 10])
	_insert_if_not_exists("sauces", [3, 'spicy_sauce', 'Острый', 15])
	
	# Размеры
	_insert_if_not_exists("sizes", [0, 'SMALL', 'маленькую', 0.5])
	_insert_if_not_exists("sizes", [1, 'MEDIUM', 'среднюю', 1.0])
	_insert_if_not_exists("sizes", [2, 'LARGE', 'большую', 1.5])
	
	# Рецепты
	_insert_if_not_exists("recipes", [1, 'Куриная шаурма', 'куриную шаурму', 'chicken'])
	_insert_if_not_exists("recipes", [2, 'Сырная шаурма', 'сырную шаурму', 'meat'])
	_insert_if_not_exists("recipes", [3, 'Острая шаурма', 'острую шаурму', 'meat'])
	_insert_if_not_exists("recipes", [4, 'Домашняя шаурма', 'домашнюю шаурму', 'chicken'])
	_insert_if_not_exists("recipes", [5, 'Мини шаурма', 'мини шаурму', 'chicken'])
	
	# Рецепт-Ингредиенты
	_insert_if_not_exists("recipe_ingredients", [1, 1, 1, 1], true)
	_insert_if_not_exists("recipe_ingredients", [2, 1, 3, 1], true)
	_insert_if_not_exists("recipe_ingredients", [3, 1, 4, 1], true)
	_insert_if_not_exists("recipe_ingredients", [4, 2, 2, 1], true)
	_insert_if_not_exists("recipe_ingredients", [5, 2, 5, 1], true)
	_insert_if_not_exists("recipe_ingredients", [6, 2, 6, 1], true)
	_insert_if_not_exists("recipe_ingredients", [7, 3, 2, 1], true)
	_insert_if_not_exists("recipe_ingredients", [8, 3, 6, 1], true)
	_insert_if_not_exists("recipe_ingredients", [9, 3, 3, 1], true)
	_insert_if_not_exists("recipe_ingredients", [10, 4, 1, 1], true)
	_insert_if_not_exists("recipe_ingredients", [11, 4, 4, 1], true)
	_insert_if_not_exists("recipe_ingredients", [12, 4, 6, 1], true)
	_insert_if_not_exists("recipe_ingredients", [13, 5, 1, 1], true)
	
	# Рецепт-Соусы
	_insert_if_not_exists("recipe_sauces", [1, 1, 1], true)
	_insert_if_not_exists("recipe_sauces", [2, 2, 1], true)
	_insert_if_not_exists("recipe_sauces", [3, 3, 3], true)
	_insert_if_not_exists("recipe_sauces", [4, 4, 2], true)
	_insert_if_not_exists("recipe_sauces", [5, 5, 1], true)
	
	# Статистика
	_insert_if_not_exists("player_stats", [1, 0, 0, 0, 0, ''], true)
	
	GlobalLogger.debug("Данные готовы!")

func _insert_if_not_exists(table: String, values: Array, _is_many_col: bool = false) -> void:
	# Формируем VALUES (...) из массива
	var values_str := ""
	for i in values.size():
		var v = values[i]
		if typeof(v) == TYPE_STRING:
			values_str += "'%s'" % v
		else:
			values_str += str(v)
		if i < values.size() - 1:
			values_str += ", "
	
	var sql := "INSERT OR IGNORE INTO %s VALUES (%s)" % [table, values_str]
	_query(sql)

# ---------------- Запросы ----------------
func _query(sql: String) -> void:
	db.query(sql)

func _query_all(sql: String) -> Array:
	db.query(sql)
	return db.get_query_results() if db.has_method("get_query_results") else []

# ---------------- Публичные методы ----------------
func get_recipes() -> Array:
	var rows := _query_all("SELECT * FROM recipes")
	var recipes: Array = []
	
	for row in rows:
		var recipe_id = row.get("id", 0)
		var recipe := {
			"id": recipe_id,
			"name": row.get("name", ""),
			"name_accusative": row.get("name_accusative", ""),
			"base_meat": row.get("base_meat", "")
		}
		
		recipe["ingredients"] = _query_all("SELECT * FROM recipe_ingredients WHERE recipe_id = %d" % recipe_id)
		recipe["sauces"] = _query_all("SELECT * FROM recipe_sauces WHERE recipe_id = %d" % recipe_id)
		recipes.append(recipe)
	
	return recipes

func get_sizes() -> Array:
	var rows := _query_all("SELECT * FROM sizes")
	var sizes: Array = []
	for row in rows:
		sizes.append({
			"id": row.get("id", 0),
			"name": row.get("name", ""),
			"display_name": row.get("display_name", ""),
			"multiplier": row.get("multiplier", 1.0)
		})
	return sizes

func save_order(recipe_id: int, size_id: int, total_weight: int, price: float) -> void:
	_query("INSERT INTO orders (recipe_id, size_id, total_weight, price, status) VALUES (%d, %d, %d, %.2f, 'completed')" % [recipe_id, size_id, total_weight, price])

func update_stats(money_earned: float, order_completed: bool) -> void:
	var completed := 1 if order_completed else 0
	_query("UPDATE player_stats SET total_money = total_money + %.2f, total_orders = total_orders + 1, completed_orders = completed_orders + %d WHERE id = 1" % [money_earned, completed])

func get_stats() -> Dictionary:
	var rows := _query_all("SELECT * FROM player_stats WHERE id = 1")
	return rows[0] if not rows.is_empty() else {}
