extends Node2D
class_name TutorialCustomer

# --- Сигналы ---
signal order_confirmed(order: Dictionary)
signal tutorial_step(step_index: int)

# --- Узлы ---
@onready var character: Sprite2D = $Character
@onready var bubble: NinePatchRect = $SpeechBubble
@onready var label: Label = $SpeechBubble/ScrollContainer/Label
@onready var ok_button: Button = $SpeechBubble/OKButton
@onready var scroll_container: ScrollContainer = $SpeechBubble/ScrollContainer

# --- Диалоги ---
var dialogs := [
	"""Привет, дорогой! Я - тётя Зина.

30 лет я делала лучшую шаурму в районе.
Но возраст... пора передавать дело молодым!""",

	"""Слева на панели - ингредиенты.
Мясо, курица, помидоры, салат, сыр, лук.

Перетаскивай их на лаваш.""",

	"""Справа - соусы.
Белый, красный, острый.

Рисуй соус прямо на шаурме.""",

	"""Когда ингредиенты выложены - на гриль!
Перетащи шаурму на горячую зону.
Пожарится за 5 секунд.""",

	"""Готово? Теперь упаковка!
Нажми на кнопку с пакетом.
Кликни на шаурму - и она завёрнётся!""",

	"""А теперь - твоя очередь!
Собери шаурму с мясом, добавь овощи и соус.
Пожарь, упакуй, неси мне!

Жду тебя!"""
]

var current_dialog := 0

func _ready() -> void:
	ok_button.pressed.connect(_on_next)
	character.visible = false
	bubble.visible = false
	
	# Показываем персонажа
	await get_tree().create_timer(0.3).timeout
	_show_character()

func _show_character() -> void:
	character.visible = true
	character.scale = Vector2(0.85, 0.85)
	character.modulate.a = 0.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(character, "scale", Vector2.ONE, 0.3)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(character, "modulate:a", 1.0, 0.25)

	# После появления - показываем первый диалог
	tween.tween_callback(_show_dialog)

func _show_dialog() -> void:
	if current_dialog >= dialogs.size():
		# Все диалоги показаны - подтверждаем заказ
		_confirm_order()
		return
	
	label.text = dialogs[current_dialog]
	bubble.visible = true
	bubble.modulate.a = 0.0
	bubble.scale = Vector2(0.8, 0.8)
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(bubble, "modulate:a", 1.0, 0.2)
	tween.tween_property(bubble, "scale", Vector2.ONE, 0.25)\
		.set_trans(Tween.TRANS_BACK)

	ok_button.visible = true
	
	# Обновляем текст кнопки
	if current_dialog == dialogs.size() - 1:
		ok_button.text = "Начинаю!"
	else:
		ok_button.text = "Далее"

func _on_next() -> void:
	# Скрываем
	bubble.visible = false
	ok_button.visible = false
	
	current_dialog += 1
	tutorial_step.emit(current_dialog)
	
	# Показываем следующий
	await get_tree().create_timer(0.3).timeout
	_show_dialog()

func _confirm_order() -> void:
	var order := {
		"name": "обычную шаурму",
		"name_accusative": "обычную шаурму",
		"size": 1,
		"ingredients": ["meat", "tomato", "salad"],
		"sauces": ["white_sauce"],
		"multiplier": 1.0
	}
	order_confirmed.emit(order)

# --- Показать благодарность (после готовки) ---
func show_thanks() -> void:
	label.text = """Неплохо, неплохо!
Держи 1000 рублей на чай!
Работай - и станешь мастером!"""
	
	ok_button.text = "В меню"
	ok_button.pressed.disconnect(_on_next)
	ok_button.pressed.connect(_go_to_menu)
	
	bubble.visible = true
	bubble.modulate.a = 0.0
	bubble.scale = Vector2(0.8, 0.8)
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(bubble, "modulate:a", 1.0, 0.2)
	tween.tween_property(bubble, "scale", Vector2.ONE, 0.25)\
		.set_trans(Tween.TRANS_BACK)
	
	ok_button.visible = true

func _go_to_menu() -> void:
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

# --- Анимация ухода ---
func play_exit() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(character, "modulate:a", 0.0, 0.3)
	tween.tween_property(character, "position:x", character.position.x + 200, 0.3)
	tween.tween_property(bubble, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): queue_free())
