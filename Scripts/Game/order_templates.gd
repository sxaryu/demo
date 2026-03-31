extends Node

# --- Enum ---
enum Size { SMALL, MEDIUM, LARGE }

# --- Константы ---
const SIZE_NAMES := {
	Size.SMALL: "маленькую",
	Size.MEDIUM: "среднюю",
	Size.LARGE: "большую"
}
const SIZE_MULTIPLIERS := {
	Size.SMALL: 0.5,
	Size.MEDIUM: 1.0,
	Size.LARGE: 1.5
}

# --- Переменные ---
var db: Node
var _recipes_cache: Array = []
var _sizes_cache: Array = []
var _ingredients_map: Dictionary = {}
var _sauces_map: Dictionary = {}

# --- Геттеры для внешнего кода ---
static func get_Size() -> Dictionary:
	return {"SMALL": Size.SMALL, "MEDIUM": Size.MEDIUM, "LARGE": Size.LARGE}

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
	_sizes_cache = db.get_sizes()
	
	print("=== ORDER_TEMPLATES: рецептов: %d, размеров: %d" % [_recipes_cache.size(), _sizes_cache.size()])
	
	# Маппинги
	for ing in db._query_all("SELECT id, name FROM ingredients"):
		_ingredients_map[ing.get("id", 0)] = ing.get("name", "")
	
	for sau in db._query_all("SELECT id, name FROM sauces"):
		_sauces_map[sau.get("id", 0)] = sau.get("name", "")
	
	print("=== ORDER_TEMPLATES: маппинги готовы")

# ---------------- Публичные методы ----------------
func get_random_template() -> Dictionary:
	return _recipes_cache.pick_random() if not _recipes_cache.is_empty() else _default_template()

func get_random_size() -> int:
	return randi() % Size.size()

func get_all_sizes() -> Array:
	return _sizes_cache

func get_size_name(size: int) -> String:
	return SIZE_NAMES.get(size, "среднюю")

func get_size_multiplier(size: int) -> float:
	return SIZE_MULTIPLIERS.get(size, 1.0) as float

func generate_order(template: Dictionary, size: int) -> Dictionary:
	var mult: float = SIZE_MULTIPLIERS.get(size, 1.0)
	
	var ingredients: PackedStringArray = []
	if template.has("ingredients"):
		for item in template["ingredients"]:
			var ing_id = item.get("ingredient_id", 0)
			if _ingredients_map.has(ing_id):
				ingredients.append(_ingredients_map[ing_id])
	
	var sauces: PackedStringArray = []
	if template.has("sauces"):
		for item in template["sauces"]:
			var sau_id = item.get("sauce_id", 0)
			if _sauces_map.has(sau_id):
				sauces.append(_sauces_map[sau_id])
	
	return {
		"id": template.get("id", 0),
		"name": template.get("name", "Шаурма"),
		"name_accusative": template.get("name_accusative", "шаурму"),
		"size": size,
		"size_name": SIZE_NAMES.get(size, "среднюю"),
		"multiplier": mult,
		"ingredients": ingredients,
		"sauces": sauces,
		"base_meat": template.get("base_meat", "chicken"),
		"recipe_id": template.get("id", 0)
	}

func _default_template() -> Dictionary:
	return {
		"id": 1, "name": "Куриная шаурма", "name_accusative": "куриную шаурму",
		"base_meat": "chicken", "ingredients": [{"ingredient_id": 1}], "sauces": [{"sauce_id": 1}]
	}
