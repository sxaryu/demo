extends Node2D
class_name Customer

# ==================== STATE MACHINE ====================
enum State {
	ENTERING,   # появляется с анимацией
	ORDERING,   # показывает заказ
	WAITING     # ждёт еду (молча)
}

# --- Константы ---
const ORDER_TEMPLATES := preload("res://Scripts/Utils/order_templates.gd")

# --- Узлы ---
@onready var character: Sprite2D = $Character
@onready var bubble: NinePatchRect = $SpeechBubble
@onready var label: Label = $SpeechBubble/DialogLabel
@onready var next_button: Button = $SpeechBubble/NextButton

# --- Сигналы ---
signal order_confirmed(order: Dictionary)

# --- Переменные ---
var state: State = State.ENTERING
var order_templates: Node
var order_data: Dictionary = {}
var current_full_text := ""
var type_speed := 0.02
var customer_index: int = 1  # Индекс клиента (1-5)

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

# ==================== READY ====================
func _ready() -> void:
	order_templates = ORDER_TEMPLATES.new()
	_init_size_phrases()
	
	next_button.pressed.connect(_on_next_pressed)
	character.visible = false
	_hide_dialog()
	
	# Применяем текстуру если индекс уже установлен
	if customer_index >= 1:
		_update_texture()
	
	# Запускаем начальное состояние
	_enter_state(state)

func _init_size_phrases() -> void:
	if _size_phrases.is_empty():
		_size_phrases = {
			order_templates.Size.SMALL: ["маленькую", "мини", "небольшую"],
			order_templates.Size.MEDIUM: ["маленькую", "обычную", "нормальную"],
			order_templates.Size.LARGE: ["большую", "мега", "огромную", "побольше"]
		}

# ==================== STATE MACHINE ====================
func _enter_state(new_state: State) -> void:
	state = new_state
	
	match state:
		State.ENTERING:
			_enter_entering()
		State.ORDERING:
			_enter_ordering()
		State.WAITING:
			_enter_waiting()

func _enter_entering() -> void:
	character.visible = true
	character.scale = Vector2(0.85, 0.85)
	character.modulate.a = 0.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(character, "scale", Vector2.ONE, 0.3)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(character, "modulate:a", 1.0, 0.25)
	
	await tween.finished
	_enter_state(State.ORDERING)

func _enter_ordering() -> void:
	_show_order()

func _enter_waiting() -> void:
	character.visible = true
	character.scale = Vector2.ONE
	character.modulate.a = 1.0
	_hide_dialog()

# ==================== ORDER ====================
func set_order(order: Dictionary) -> void:
	order_data = order.duplicate(true)

func set_customer_index(index: int) -> void:
	customer_index = index
	# Применяем текстуру только если нода уже готова
	if is_inside_tree():
		_update_texture()

func _update_texture() -> void:
	var texture_path: String
	
	if customer_index == Globals.GRANDMA_INDEX:
		# Бабка - отдельный спрайт
		texture_path = "res://Textures/Customers/grandma.png"
	else:
		# Обычные клиенты 2-5
		texture_path = "res://Textures/Customers/customer %d.png" % customer_index
	
	if ResourceLoader.exists(texture_path):
		character.texture = load(texture_path)
	else:
		push_warning("Customer: текстура не найдена: ", texture_path)

# ==================== SHOW ORDER ====================
func _show_order() -> void:
	if order_data.is_empty() or not order_data.has("name"):
		order_data = order_templates.generate_order(
			order_templates.get_random_template(),
			order_templates.get_random_size()
		)
	
	var size = order_data.get("size", order_templates.Size.MEDIUM)
	var size_text := _get_size_text(size)
	
	current_full_text = "%s, хочу %s %s" % [
		_greetings.pick_random(),
		size_text,
		order_data.get("name_accusative", "шаурму")
	]
	
	# Ингредиенты
	var ing_names := _get_ingredient_names(order_data.get("ingredients", []))
	if not ing_names.is_empty():
		current_full_text += ", с " + ", ".join(ing_names)
	
	# Соусы
	var sauce_list := _get_sauce_names(order_data.get("sauces", []))
	if not sauce_list.is_empty():
		current_full_text += " и " + ", ".join(sauce_list) + " соус"
	
	current_full_text += ". %s" % _thanks.pick_random()
	
	label.text = ""
	bubble.visible = true
	bubble.scale = Vector2(0.8, 0.8)
	bubble.modulate.a = 0.0
	next_button.visible = false

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(bubble, "scale", Vector2.ONE, 0.25)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(bubble, "modulate:a", 1.0, 0.2)
	
	await tween.finished
	_type_text()

func _type_text() -> void:
	label.text = ""
	
	for i in range(current_full_text.length()):
		label.text += current_full_text[i]
		await get_tree().create_timer(type_speed).timeout
	
	next_button.visible = true

func _get_size_text(size) -> String:
	var size_texts := {
		order_templates.Size.SMALL: "маленькую",
		order_templates.Size.MEDIUM: "среднюю",
		order_templates.Size.LARGE: "большую"
	}
	return size_texts.get(size, "среднюю")

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

# ==================== CALLBACKS ====================
func _on_next_pressed() -> void:
	order_confirmed.emit(order_data)
	_enter_state(State.WAITING)

func _hide_dialog() -> void:
	bubble.visible = false
	next_button.visible = false
