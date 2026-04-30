extends Node

# === ИМПОРТИРУЕМ ТИПЫ ИЗ ShawarmaTypes ===
const SHAWARMA_TYPES := preload("res://Scripts/Core/ShawarmaTypes.gd")

# Для удобства создаём локальные ссылки на enum
enum ShawarmaType {
	CLASSIC,   # Классическая (мясо + овощи)
	VEGAN,     # Веганская (без мяса)
	CHEESE     # Сырная (мясо + овощи + сыр)
}

enum OrderModifier {
	NONE,          # Без модификаторов
	EXTRA_SAUCE,   # Побольше соуса
	LITTLE_SAUCE,  # Поменьше соуса
	SPICY,         # Острее
	MILD,          # Мягче
	EXTRA_MEAT,    # Побольше мяса
	EXTRA_VEGGIES  # Побольше овощей
}

# Исключения: какие ингредиенты можно исключить из каждого типа
const ALLOWED_EXCLUSIONS := {
	ShawarmaType.CLASSIC: ["onion", "pepper", "tomato", "salad"],
	ShawarmaType.VEGAN: ["onion", "pepper", "tomato", "salad"],
	ShawarmaType.CHEESE: ["onion", "pepper", "tomato", "salad"]  # Сыр нельзя исключить!
}

# Базовые ингредиенты для каждого типа
const BASE_INGREDIENTS := {
	ShawarmaType.CLASSIC: ["meat", "tomato", "salad", "onion", "pepper"],
	ShawarmaType.VEGAN: ["tomato", "salad", "onion", "pepper"],
	ShawarmaType.CHEESE: ["meat", "tomato", "salad", "onion", "pepper", "cheese"]  # Сыр всегда в сырной!
}

# Соусы по умолчанию
const DEFAULT_SAUCES := ["white_sauce"]
const SPICY_SAUCES := ["spicy_sauce"]  # Острый соус
const MILD_SAUCES := ["white_sauce"]  # Белый соус мягче

# --- Переменные ---
var db: Node
var _recipes_cache: Array = []
var _ingredients_map: Dictionary = {}
var _sauces_map: Dictionary = {}
var _ingredients_by_key: Dictionary = {}  # key -> id

# --- Геттеры для внешнего кода ---
static func get_ShawarmaType() -> Dictionary:
	return {
		"CLASSIC": ShawarmaType.CLASSIC,
		"VEGAN": ShawarmaType.VEGAN,
		"CHEESE": ShawarmaType.CHEESE
	}

static func get_OrderModifier() -> Dictionary:
	return {
		"NONE": OrderModifier.NONE,
		"EXTRA_SAUCE": OrderModifier.EXTRA_SAUCE,
		"LITTLE_SAUCE": OrderModifier.LITTLE_SAUCE,
		"SPICY": OrderModifier.SPICY,
		"MILD": OrderModifier.MILD,
		"EXTRA_MEAT": OrderModifier.EXTRA_MEAT,
		"EXTRA_VEGGIES": OrderModifier.EXTRA_VEGGIES
	}

func _ready() -> void:
	print("=== ORDER_TEMPLATES: старт")
	_find_database()

func _find_database() -> void:
	# Пробуем разные способы поиска БД
	db = get_tree().get_first_node_in_group("database")
	if db:
		_load_data()
		return
	
	if has_node("/root/Database"):
		db = get_node("/root/Database")
		_load_data()
		return
	
	# Пробуем через таймер если не найден
	print("=== ORDER_TEMPLATES: БД не найден, пробуем через 0.5 сек...")
	await get_tree().create_timer(0.5).timeout
	_find_database()

func _load_data() -> void:
	if not db:
		push_error("ORDER_TEMPLATES: БД не найдена!")
		return
	
	_recipes_cache = db.get_recipes()
	
	print("=== ORDER_TEMPLATES: рецептов: %d" % [_recipes_cache.size()])
	
	# Маппинги
	for ing in db._query_all("SELECT id, name FROM ingredients"):
		var name: String = ing.get("name", "")
		var ing_id = ing.get("id", 0)
		_ingredients_map[ing_id] = name
		# Обратный маппинг для ключей типа "meat", "onion" и т.д.
		_ingredients_by_key[name.to_lower()] = ing_id
	
	for sau in db._query_all("SELECT id, name FROM sauces"):
		var name: String = sau.get("name", "")
		var sau_id = sau.get("id", 0)
		_sauces_map[sau_id] = name
		_sauces_map[name.to_lower()] = sau_id
	
	print("=== ORDER_TEMPLATES: маппинги готовы")

# ---------------- Публичные методы ----------------
func get_random_template() -> Dictionary:
	return _recipes_cache.pick_random() if not _recipes_cache.is_empty() else _default_template()

# === НОВЫЕ МЕТОДЫ ДЛЯ СИСТЕМЫ ЗАКАЗОВ ===

## Генерирует заказ на основе типа шаурмы
func generate_order_by_type(shawarma_type: int, exclusions: Array = [], modifier: int = OrderModifier.NONE) -> Dictionary:
	var base_ings: Array = BASE_INGREDIENTS.get(shawarma_type, BASE_INGREDIENTS[ShawarmaType.CLASSIC]).duplicate()
	
	# Удаляем исключённые ингредиенты
	for exc in exclusions:
		if exc in base_ings:
			base_ings.erase(exc)
	
	var ingredient_list: PackedStringArray = []
	for ing_key in base_ings:
		ingredient_list.append(ing_key)
	
	# Применяем модификаторы к ингредиентам
	var sauce_list: PackedStringArray = []
	
	match modifier:
		OrderModifier.SPICY:
			sauce_list = SPICY_SAUCES.duplicate()
		OrderModifier.MILD:
			sauce_list = MILD_SAUCES.duplicate()
		_:
			sauce_list = DEFAULT_SAUCES.duplicate()
	
	# Определяем имя
	var type_name: String = SHAWARMA_TYPES.get_shawarma_type_name(shawarma_type)
	var type_name_acc: String = SHAWARMA_TYPES.get_shawarma_type_name_accusative(shawarma_type)
	
	return {
		"id": shawarma_type + 1,
		"name": type_name,
		"name_accusative": type_name_acc,
		"ingredients": ingredient_list,
		"sauces": sauce_list,
		"base_meat": "meat",
		"recipe_id": shawarma_type + 1,
		"shawarma_type": shawarma_type,
		"exclusions": exclusions,
		"modifier": modifier,
		"modifier_name": SHAWARMA_TYPES.get_modifier_name(modifier)
	}

## Получает список разрешённых исключений для типа шаурмы
func get_allowed_exclusions(shawarma_type: int) -> Array:
	return ALLOWED_EXCLUSIONS.get(shawarma_type, []).duplicate()

## Получает случайный модификатор заказа
func get_random_modifier() -> int:
	# 30% шанс модификатора
	if randf() < 0.3:
		var modifiers := [
			OrderModifier.EXTRA_SAUCE,
			OrderModifier.LITTLE_SAUCE,
			OrderModifier.SPICY,
			OrderModifier.MILD,
			OrderModifier.EXTRA_MEAT,
			OrderModifier.EXTRA_VEGGIES
		]
		return modifiers.pick_random()
	return OrderModifier.NONE

func generate_order(template: Dictionary, exclusions: Array = [], modifier: int = OrderModifier.NONE) -> Dictionary:
	var ingredients: PackedStringArray = []
	if template.has("ingredients"):
		for item in template["ingredients"]:
			var ing_id = item.get("ingredient_id", 0)
			if _ingredients_map.has(ing_id):
				ingredients.append(_ingredients_map[ing_id])
	
	# Удаляем исключённые ингредиенты
	for exc in exclusions:
		if exc in ingredients:
			ingredients.erase(exc)
	
	var sauces: PackedStringArray = []
	
	# Применяем модификаторы к соусам
	match modifier:
		OrderModifier.SPICY:
			sauces = SPICY_SAUCES.duplicate()
		OrderModifier.MILD:
			sauces = MILD_SAUCES.duplicate()
		_:
			if template.has("sauces"):
				for item in template["sauces"]:
					var sau_id = item.get("sauce_id", 0)
					if _sauces_map.has(sau_id):
						sauces.append(_sauces_map[sau_id])
			else:
				sauces = DEFAULT_SAUCES.duplicate()
	
	return {
		"id": template.get("id", 0),
		"name": template.get("name", "Шаурма"),
		"name_accusative": template.get("name_accusative", "шаурму"),
		"ingredients": ingredients,
		"sauces": sauces,
		"base_meat": template.get("base_meat", "meat"),
		"recipe_id": template.get("id", 0),
		"exclusions": exclusions,
		"modifier": modifier,
		"modifier_name": SHAWARMA_TYPES.get_modifier_name(modifier),
		"shawarma_type": template.get("shawarma_type", ShawarmaType.CLASSIC)
	}

func _default_template() -> Dictionary:
	return {
		"id": 1, "name": "Шаурма", "name_accusative": "шаурму",
		"base_meat": "meat", "ingredients": [{"ingredient_id": 1}], "sauces": [{"sauce_id": 1}]
	}
