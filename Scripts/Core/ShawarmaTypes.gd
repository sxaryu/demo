extends Node
class_name ShawarmaTypes

# ==================== ТИПЫ ШАУРМЫ ====================
enum ShawarmaType {
	CLASSIC,   # Классическая (мясо + овощи)
	VEGAN,     # Веганская (без мяса)
	CHEESE     # Сырная (мясо + овощи + сыр)
}

# ==================== МОДИФИКАТОРЫ ЗАКАЗА ====================
enum OrderModifier {
	NONE,          # Без модификаторов
	EXTRA_SAUCE,   # Побольше соуса
	LITTLE_SAUCE,  # Поменьше соуса
	SPICY,         # Острее
	MILD,          # Мягче
	EXTRA_MEAT,    # Побольше мяса
	EXTRA_VEGGIES  # Побольше овощей
}

# ==================== ИМЕНА ТИПОВ ШАУРМЫ ====================
const SHAWARMA_TYPE_NAMES := {
	ShawarmaType.CLASSIC: "классическую",
	ShawarmaType.VEGAN: "веганскую",
	ShawarmaType.CHEESE: "сырную"
}

const SHAWARMA_TYPE_NAMES_ACCUSATIVE := {
	ShawarmaType.CLASSIC: "классическую",
	ShawarmaType.VEGAN: "веганскую",
	ShawarmaType.CHEESE: "сырную"
}

# ==================== ИМЕНА МОДИФИКАТОРОВ ====================
const MODIFIER_NAMES := {
	OrderModifier.EXTRA_SAUCE: "с побольше соуса",
	OrderModifier.LITTLE_SAUCE: "с поменьше соуса",
	OrderModifier.SPICY: "поживчее",
	OrderModifier.MILD: "помягче",
	OrderModifier.EXTRA_MEAT: "с побольше мяса",
	OrderModifier.EXTRA_VEGGIES: "с побольше овощей"
}

# ==================== ГЕТТЕРЫ ====================

## Получает имя типа шаурмы
static func get_shawarma_type_name(shawarma_type: int) -> String:
	return SHAWARMA_TYPE_NAMES.get(shawarma_type, "классическую")

## Получает имя типа шаурмы в винительном падеже
static func get_shawarma_type_name_accusative(shawarma_type: int) -> String:
	return SHAWARMA_TYPE_NAMES_ACCUSATIVE.get(shawarma_type, "классическую")

## Получает имя модификатора
static func get_modifier_name(modifier: int) -> String:
	return MODIFIER_NAMES.get(modifier, "")