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
	ShawarmaType.CHEESE: ["onion", "pepper", "tomato", "salad"]
}

# Базовые ингредиенты для каждого типа
const BASE_INGREDIENTS := {
	ShawarmaType.CLASSIC: ["meat", "tomato", "salad", "onion", "pepper"],
	ShawarmaType.VEGAN: ["tomato", "salad", "onion", "pepper"],
	ShawarmaType.CHEESE: ["meat", "tomato", "salad", "onion", "pepper", "cheese"]
}

# Соусы по умолчанию
const DEFAULT_SAUCES := ["white_sauce"]
const SPICY_SAUCES := ["spicy_sauce"]
const MILD_SAUCES := ["white_sauce"]

# --- Хардкод рецептов (вместо БД) ---
var _recipes_cache: Array = []

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
	_init_recipes_cache()

func _init_recipes_cache() -> void:
	_recipes_cache = [
		{"id": 1, "name": "Куриная шаурма", "name_accusative": "куриную шаурму", "base_meat": "chicken", "ingredients": [{"ingredient_id": 1}], "sauces": [{"sauce_id": 1}]},
		{"id": 2, "name": "Сырная шаурма", "name_accusative": "сырную шаурму", "base_meat": "meat", "ingredients": [{"ingredient_id": 2}], "sauces": [{"sauce_id": 1}]},
		{"id": 3, "name": "Острая шаурма", "name_accusative": "острую шаурму", "base_meat": "meat", "ingredients": [{"ingredient_id": 2}], "sauces": [{"sauce_id": 3}]},
		{"id": 4, "name": "Домашняя шаурма", "name_accusative": "домашнюю шаурму", "base_meat": "chicken", "ingredients": [{"ingredient_id": 1}], "sauces": [{"sauce_id": 2}]},
		{"id": 5, "name": "Мини шаурма", "name_accusative": "мини шаурму", "base_meat": "chicken", "ingredients": [{"ingredient_id": 1}], "sauces": [{"sauce_id": 1}]}
	]

# ---------------- Публичные методы ----------------
func get_random_template() -> Dictionary:
	return _recipes_cache.pick_random() if not _recipes_cache.is_empty() else _default_template()

## Генерирует заказ на основе типа шаурмы
func generate_order_by_type(shawarma_type: int, exclusions: Array = [], modifier: int = OrderModifier.NONE) -> Dictionary:
	var base_ings: Array = BASE_INGREDIENTS.get(shawarma_type, BASE_INGREDIENTS[ShawarmaType.CLASSIC]).duplicate()
	for exc in exclusions:
		if exc in base_ings:
			base_ings.erase(exc)
	
	var ingredient_list: PackedStringArray = []
	for ing_key in base_ings:
		ingredient_list.append(ing_key)
	
	var sauce_list: PackedStringArray = []
	match modifier:
		OrderModifier.SPICY:
			sauce_list = SPICY_SAUCES.duplicate()
		OrderModifier.MILD:
			sauce_list = MILD_SAUCES.duplicate()
		_:
			sauce_list = DEFAULT_SAUCES.duplicate()
	
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
			match ing_id:
				1: ingredients.append("chicken")
				2: ingredients.append("meat")
				3: ingredients.append("tomato")
				4: ingredients.append("salad")
				5: ingredients.append("cheese")
				6: ingredients.append("onion")
				7: ingredients.append("pepper")
	
	for exc in exclusions:
		if exc in ingredients:
			ingredients.erase(exc)
	
	var sauces: PackedStringArray = []
	match modifier:
		OrderModifier.SPICY:
			sauces = SPICY_SAUCES.duplicate()
		OrderModifier.MILD:
			sauces = MILD_SAUCES.duplicate()
		_:
			if template.has("sauces"):
				for item in template["sauces"]:
					var sau_id = item.get("sauce_id", 0)
					match sau_id:
						1: sauces.append("white_sauce")
						2: sauces.append("red_sauce")
						3: sauces.append("spicy_sauce")
				if sauces.is_empty():
					sauces = DEFAULT_SAUCES.duplicate()
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
