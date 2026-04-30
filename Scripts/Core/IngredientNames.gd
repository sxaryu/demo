extends Node
class_name IngredientNames

# ==================== ИМЕНА ИНГРЕДИЕНТОВ ====================

# Именительный падеж (кто? что?)
const INGREDIENT_NAMES_NOM := {
	"meat": "мясо",
	"tomato": "помидор",
	"salad": "салат",
	"cheese": "сыр",
	"onion": "лук",
	"pepper": "перец"
}

# Родительный падеж (кого? чего?)
const INGREDIENT_NAMES_GEN := {
	"meat": "мяса",
	"tomato": "помидора",
	"salad": "салата",
	"cheese": "сыра",
	"onion": "лука",
	"pepper": "перца"
}

# Творительный падеж (кем? чем?)
const INGREDIENT_NAMES_INS := {
	"meat": "мясом",
	"tomato": "помидором",
	"salad": "салатом",
	"cheese": "сыром",
	"onion": "луком",
	"pepper": "перцем"
}

# ==================== ИМЕНА СОУСОВ ====================

# Творительный падеж (кем? чем?)
const SAUCE_NAMES_INS := {
	"white_sauce": "белым",
	"spicy_sauce": "острым"
}

# ==================== ВСПМОГАТЕЛЬНЫЕ МЕТОДЫ ====================

## Получает имя ингредиента в именительном падеже
static func get_ingredient_name_nom(ingredient_key: String) -> String:
	return INGREDIENT_NAMES_NOM.get(ingredient_key, ingredient_key)

## Получает имя ингредиента в родительном падеже
static func get_ingredient_name_gen(ingredient_key: String) -> String:
	return INGREDIENT_NAMES_GEN.get(ingredient_key, ingredient_key)

## Получает имя ингредиента в творительном падеже
static func get_ingredient_name_ins(ingredient_key: String) -> String:
	return INGREDIENT_NAMES_INS.get(ingredient_key, ingredient_key)

## Получает имя соуса в творительном падеже
static func get_sauce_name_ins(sauce_key: String) -> String:
	return SAUCE_NAMES_INS.get(sauce_key, sauce_key)

## Получает имена ингредиентов из массива
static func get_ingredient_names(ingredients: Array, case: String = "nom") -> PackedStringArray:
	var result: PackedStringArray = []
	var names_map := INGREDIENT_NAMES_NOM
	
	match case:
		"gen":
			names_map = INGREDIENT_NAMES_GEN
		"ins":
			names_map = INGREDIENT_NAMES_INS
	
	for ing in ingredients:
		if names_map.has(ing):
			result.append(names_map[ing])
	
	return result

## Получает имена соусов из массива
static func get_sauce_names(sauces: Array) -> PackedStringArray:
	var result: PackedStringArray = []
	for sauce in sauces:
		if SAUCE_NAMES_INS.has(sauce):
			result.append(SAUCE_NAMES_INS[sauce])
	return result