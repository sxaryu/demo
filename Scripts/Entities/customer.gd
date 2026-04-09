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

const NPC_DATA := {
	"grandma": {"sprite": "npc_grandma.png", "name": "Бабушка"},
	"bald_man": {"sprite": "npc_bald_man.png", "name": "Лысый"},
	"blonde_girl": {"sprite": "npc_blonde_girl.png", "name": "Блондинка"},
	"businessman": {"sprite": "npc_businessman.png", "name": "Бизнесмен"},
	"ginger_man": {"sprite": "npc_ginger_man.png", "name": "Рыжий"},
	"glasses_girl": {"sprite": "npc_glasses_girl.png", "name": "Очкарик"},
	"goth_girl": {"sprite": "npc_goth_girl.png", "name": "Гот"},
	"grandpa": {"sprite": "npc_grandpa.png", "name": "Дедушка"},
	"pink_girl": {"sprite": "npc_pink_girl.png", "name": "Розовая"},
	"student": {"sprite": "npc_student.png", "name": "Студент"}
}

# --- Узлы ---
@onready var character: Sprite2D = $Character
@onready var bubble: NinePatchRect = $SpeechBubble
@onready var label: Label = $SpeechBubble/DialogLabel
@onready var next_button: Button = $SpeechBubble/NextButton

# --- Сигналы ---
signal order_confirmed(order: Dictionary)

# --- Переменные ---
var state: State = State.WAITING
var order_templates: Node = null
var order_data: Dictionary = {}
var current_full_text := ""
var type_speed := 0.02
var customer_id: String = "bald_man"

# Внутренние переменные состояния
var _idle_time := 0.0
var _base_y := 0.0
var _is_order_shown := false
var _typing_tween: Tween = null

# --- Текстовые данные (статические) ---
static var _greetings := ["Привет!", "Здравствуйте!", "Добрый день!", "Приветики!", "Приветствую!"]
static var _thanks := ["спасибо", "спасибо большое", "благодарю", "спасибочки", "очень благодарен"]

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
	
	next_button.pressed.connect(_on_next_pressed)
	
	character.visible = false
	_hide_dialog()
	
	if customer_id != "":
		_update_texture()
	
	_enter_state(state)

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
	_is_order_shown = false
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
	# Защита от повторного вызова при восстановлении состояния
	if _is_order_shown:
		return
		
	_base_y = character.position.y
	_show_order()

func _enter_waiting() -> void:
	# Останавливаем печатание
	_typing_tween = null
		
	character.visible = true
	character.scale = Vector2.ONE
	character.modulate.a = 1.0
	_hide_dialog()
	_idle_time = 0.0
	_base_y = character.position.y
	_is_order_shown = false

func _process(delta: float) -> void:
	if state == State.WAITING or state == State.ORDERING:
		if character.visible:
			_idle_time += delta
			var offset := sin(_idle_time * 3.0) * 5.0
			character.position.y = _base_y + offset

# ==================== ПУБЛИЧНЫЕ МЕТОДЫ ====================
func set_order(order: Dictionary) -> void:
	order_data = order.duplicate(true)

func set_state(new_state: State) -> void:
	_enter_state(new_state)

func set_customer_id(id: String) -> void:
	customer_id = id
	if is_inside_tree():
		_update_texture()

# ==================== ПРИВАТНЫЕ МЕТОДЫ ====================
func _update_texture() -> void:
	var data = NPC_DATA.get(customer_id, NPC_DATA["bald_man"])
	var texture_path = "res://Textures/Customers/NPC/" + data.sprite
	
	if ResourceLoader.exists(texture_path):
		character.texture = load(texture_path)
	else:
		push_warning("Customer: текстура не найдена: ", texture_path)

func _show_order() -> void:
	_is_order_shown = true
	
	bubble.visible = false
	bubble.modulate.a = 0.0
	bubble.scale = Vector2(0.8, 0.8)
	label.text = ""
	next_button.visible = false

	if order_data.is_empty() or not order_data.has("name"):
		if order_templates:
			order_data = order_templates.generate_order(
				order_templates.get_random_template(),
				order_templates.get_random_size()
			)
		else:
			push_error("Order templates не инициализированы!")
			return
	
	var size = order_data.get("size", 1)
	var size_text := _get_size_text(size)
	
	var greeting = _greetings.pick_random()
	var item_name = order_data.get("name_accusative", "шаурму")
	
	current_full_text = "%s, хочу %s %s" % [greeting, size_text, item_name]
	
	var ing_names := _get_ingredient_names(order_data.get("ingredients", []))
	if not ing_names.is_empty():
		current_full_text += ", с " + ", ".join(ing_names)
	
	var sauce_list := _get_sauce_names(order_data.get("sauces", []))
	if not sauce_list.is_empty():
		current_full_text += " и " + ", ".join(sauce_list) + " соус"
	
	current_full_text += ". %s" % _thanks.pick_random()
	
	bubble.visible = true
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(bubble, "scale", Vector2.ONE, 0.25)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(bubble, "modulate:a", 1.0, 0.2)
	
	await tween.finished
	_type_text()

func _type_text() -> void:
	label.text = ""
	_typing_tween = null  # Сбрасываем ссылку
	
	for i in range(current_full_text.length()):
		if not bubble.visible:  # Проверяем, не закрыт ли диалог
			return
			
		label.text += current_full_text[i]
		await get_tree().create_timer(type_speed).timeout
		
		if not bubble.visible:
			return

	next_button.visible = true

func _get_size_text(size) -> String:
	# Замените 0,1,2 на order_templates.Size.SMALL и т.д. если доступны
	var size_texts := {
		0: "маленькую",
		1: "среднюю",
		2: "большую"
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
	_typing_tween = null  # Останавливаем печатание
		
	order_confirmed.emit(order_data)
	_enter_state(State.WAITING)

func _hide_dialog() -> void:
	bubble.visible = false
	next_button.visible = false
	_typing_tween = null
