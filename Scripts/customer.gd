extends Node2D
class_name Customer

# --- Константы ---
const BUBBLE_PADDING := Vector2(20, 14)
const ORDER_TEMPLATES := preload("res://Scripts/order_templates.gd")

# --- Узлы ---
@onready var character: Sprite2D = $Character
@onready var bubble: NinePatchRect = $SpeechBubble
@onready var label: Label = $SpeechBubble/Label
@onready var ok_button: Button = $SpeechBubble/OKButton

# --- Сигналы ---
signal order_confirmed(order: Dictionary)

# --- Переменные ---
var order_templates: Node
var order_data: Dictionary = {}
var stand_still: bool = false
var dialog_shown: bool = false

# --- Текстовые данные (статические) ---
static var _greetings := ["Привет!", "Здравствуйте!", "Добрый день!", "Приветики!", "Приветствую!"]
static var _requests := ["хочу", "мне нужно", "дайте мне", "можно мне", "закажу", "мне пожалуйста"]
static var _thanks := ["спасибо", "спасибо большое", "благодарю", "спасибочки", "очень благодарен"]

# Маппинги
static var _size_phrases := {}
static var _ingredient_names := {
	"chicken": "курица", "meat": "мясо", "tomato": "помидор",
	"salad": "салат", "cheese": "сыр", "onion": "лук"
}
static var _sauce_names := {
	"white_sauce": "белым", "red_sauce": "красным", "spicy_sauce": "острым"
}

func _ready() -> void:
	order_templates = ORDER_TEMPLATES.new()
	_init_size_phrases()
	
	ok_button.pressed.connect(_on_ok_pressed)
	character.visible = false
	_hide_dialog()

	if stand_still:
		set_stand_still()
	else:
		_show_character_delayed()

func _init_size_phrases() -> void:
	if _size_phrases.is_empty():
		_size_phrases = {
			order_templates.Size.SMALL: ["маленькую", "мини", "небольшую"],
			order_templates.Size.MEDIUM: ["маленькую", "обычную", "нормальную"],
			order_templates.Size.LARGE: ["большую", "мега", "огромную", "побольше"]
		}

func _show_character_delayed() -> void:
	if dialog_shown:
		return
	dialog_shown = true
	
	await get_tree().create_timer(0.6).timeout
	_show_character()
	await get_tree().create_timer(0.4).timeout
	_show_order()

func set_order(order: Dictionary) -> void:
	order_data = order

func set_stand_still() -> void:
	character.visible = true
	_hide_dialog()
	dialog_shown = true

# ---------------- Анимация появления ----------------
func _show_character() -> void:
	character.visible = true
	character.scale = Vector2(0.85, 0.85)
	character.modulate.a = 0.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(character, "scale", Vector2.ONE, 0.3)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(character, "modulate:a", 1.0, 0.25)

func _show_order() -> void:
	if order_data.is_empty() or not order_data.has("name"):
		order_data = order_templates.generate_order(
			order_templates.get_random_template(),
			order_templates.get_random_size()
		)
	
	var size = order_data.get("size", order_templates.Size.MEDIUM)
	var size_name = _size_phrases[size].pick_random()
	
	# Формируем текст заказа
	var text := "%s %s %s %s.\n\n" % [
		_greetings.pick_random(),
		_requests.pick_random(),
		size_name,
		order_data.get("name_accusative", "шаурму")
	]
	
	# Ингредиенты
	var ing_names := _get_ingredient_names(order_data.get("ingredients", []))
	if not ing_names.is_empty():
		text += "С " + ", ".join(ing_names)
	
	# Соусы
	var sauce_list := _get_sauce_names(order_data.get("sauces", []))
	if not sauce_list.is_empty():
		if not ing_names.is_empty():
			text += " и "
		text += "с " + ", ".join(sauce_list) + " соусом"
	
	if not ing_names.is_empty() or not sauce_list.is_empty():
		text += "."
	
	text += "\n(x%.1f)\n%s!" % [order_data.get("multiplier", 1.0), _thanks.pick_random()]
	
	label.text = text
	await get_tree().process_frame

	bubble.size = label.size + BUBBLE_PADDING
	bubble.pivot_offset = bubble.size / 2
	bubble.visible = true
	bubble.scale = Vector2(0.8, 0.8)
	bubble.modulate.a = 0.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(bubble, "scale", Vector2.ONE, 0.25)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(bubble, "modulate:a", 1.0, 0.2)

	ok_button.visible = true

func _get_ingredient_names(ingredients: Array) -> PackedStringArray:
	var result: PackedStringArray = []
	for ing in ingredients:
		if _ingredient_names.has(ing):
			result.append(_ingredient_names[ing])
	return result

func _get_sauce_names(sauces: Array) -> PackedStringArray:
	var result: PackedStringArray = []
	for sau in sauces:
		if _sauce_names.has(sau):
			result.append(_sauce_names[sau])
	return result

func _on_ok_pressed() -> void:
	order_confirmed.emit(order_data)
	_hide_dialog()

func _hide_dialog() -> void:
	bubble.visible = false
	ok_button.visible = false
