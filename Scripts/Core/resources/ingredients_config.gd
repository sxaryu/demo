extends Resource
class_name IngredientsConfig

## Конфигурация ингредиентов - цены, веса, текстуры
## Редактируется в Inspector или через .tres файл

@export_group("Ингредиенты")
@export var lavash_cost: int = 15
@export var lavash_weight: int = 100
@export var lavash_texture_path: String = "res://Textures/Ingredients/lavash.png"

@export var chicken_cost: int = 8
@export var chicken_weight: int = 30
@export var chicken_texture_path: String = "res://Textures/Ingredients/Pieces/chicken_piece.png"

@export var meat_cost: int = 10
@export var meat_weight: int = 30
@export var meat_texture_path: String = "res://Textures/Ingredients/Pieces/meat_piece.png"

@export var tomato_cost: int = 2
@export var tomato_weight: int = 20
@export var tomato_texture_path: String = "res://Textures/Ingredients/Pieces/tomato_piece.png"

@export var salad_cost: int = 2
@export var salad_weight: int = 20
@export var salad_texture_path: String = "res://Textures/Ingredients/Pieces/salad_piece.png"

@export var cheese_cost: int = 3
@export var cheese_weight: int = 15
@export var cheese_texture_path: String = "res://Textures/Ingredients/Pieces/cheese_piece.png"

@export var onion_cost: int = 2
@export var onion_weight: int = 10
@export var onion_texture_path: String = "res://Textures/Ingredients/Pieces/onion_piece.png"

@export var pepper_cost: int = 2
@export var pepper_weight: int = 10
@export var pepper_texture_path: String = "res://Textures/Ingredients/Pieces/pepper_piece.png"

@export_group("Соусы")
@export var white_sauce_cost: int = 1
@export var white_sauce_weight: int = 10
@export var white_sauce_texture_path: String = "res://Textures/Ingredients/Sauces/mayo_sauce.png"

@export var red_sauce_cost: int = 1
@export var red_sauce_weight: int = 10
@export var red_sauce_texture_path: String = "res://Textures/Ingredients/Sauces/ketchup_bottle.png"

@export var spicy_sauce_cost: int = 1
@export var spicy_sauce_weight: int = 10
@export var spicy_sauce_texture_path: String = "res://Textures/Ingredients/Sauces/spicy_sauce.png"

## Получение цены по типу
func get_cost(type: String) -> int:
	match type:
		"lavash": return lavash_cost
		"chicken": return chicken_cost
		"meat": return meat_cost
		"tomato": return tomato_cost
		"salad": return salad_cost
		"cheese": return cheese_cost
		"onion": return onion_cost
		"pepper": return pepper_cost
		"white_sauce": return white_sauce_cost
		"red_sauce": return red_sauce_cost
		"spicy_sauce": return spicy_sauce_cost
		_: return 0

## Получение веса по типу (в граммах)
func get_weight(type: String) -> int:
	match type:
		"lavash": return lavash_weight
		"chicken": return chicken_weight
		"meat": return meat_weight
		"tomato": return tomato_weight
		"salad": return salad_weight
		"cheese": return cheese_weight
		"onion": return onion_weight
		"pepper": return pepper_weight
		"white_sauce": return white_sauce_weight
		"red_sauce": return red_sauce_weight
		"spicy_sauce": return spicy_sauce_weight
		_: return 0

## Получение пути к тексту по типу
func get_texture_path(type: String) -> String:
	match type:
		"lavash": return lavash_texture_path
		"chicken": return chicken_texture_path
		"meat": return meat_texture_path
		"tomato": return tomato_texture_path
		"salad": return salad_texture_path
		"cheese": return cheese_texture_path
		"onion": return onion_texture_path
		"pepper": return pepper_texture_path
		"white_sauce": return white_sauce_texture_path
		"red_sauce": return red_sauce_texture_path
		"spicy_sauce": return spicy_sauce_texture_path
		_: return ""

## Проверка является ли ингредиент основой
func is_base_ingredient(type: String) -> bool:
	return type == "lavash"

## Получение всех данных ингредиента
func get_ingredient_data(type: String) -> Dictionary:
	return {
		"type": type,
		"cost": get_cost(type),
		"weight": get_weight(type),
		"texture_path": get_texture_path(type)
	}