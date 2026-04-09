extends Control

@onready var grandma_sprite: Sprite2D = $GrandmaSprite
@onready var dialog_label: Label = $SpeechBubble/DialogLabel
@onready var next_button: Button = $SpeechBubble/NextButton
@onready var bubble: NinePatchRect = $SpeechBubble

var dialogs := [
	"Здравствуй, дорогой дорогой мой!",
	"Мне нужно срочно уехать на недельку по важным делам...",
	"Не мог бы ты присмотреть за моим маленьким ресторанчиком, в качестве стажировки?",
	"Главное - не потеряй наших клиентов, они очень важные!",
	"Я вернусь и обязательно награжу тебя!",
	"Удачи тебе, у тебя всё получится!", 
	"А сейчас предлагаю потренироваться на мне, прими у меня заказ!"
]

var current_index := 0
var current_full_text := ""
var type_speed := 0.02
var _idle_time := 0.0
var _base_y := 0.0

func _ready() -> void:
	next_button.pressed.connect(_on_next_pressed)
	grandma_sprite.modulate.a = 0.0
	bubble.modulate.a = 0.0
	bubble.scale = Vector2(0.8, 0.8)
	next_button.visible = false
	_show_grandma()

func _show_grandma() -> void:
	_base_y = grandma_sprite.position.y
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(grandma_sprite, "modulate:a", 1.0, 0.5)
	tween.tween_property(grandma_sprite, "scale", Vector2(1.03, 1.03), 0.5)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	await get_tree().create_timer(0.3).timeout
	_show_bubble()

func _process(delta: float) -> void:
	_idle_time += delta
	var offset := sin(_idle_time * 3.0) * 5.0
	grandma_sprite.position.y = _base_y + offset

func _show_bubble() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(bubble, "modulate:a", 1.0, 0.3)
	tween.tween_property(bubble, "scale", Vector2.ONE, 0.25)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	_show_dialog()

func _show_dialog() -> void:
	if current_index < dialogs.size():
		current_full_text = dialogs[current_index]
		dialog_label.text = ""
		next_button.visible = false
		
		if current_index == dialogs.size() - 1:
			next_button.text = "Начать!"
		
		_type_text()
	else:
		# Бабка будет первым клиентом
		Globals.last_customer_id = Globals.GRANDMA_ID
		get_tree().change_scene_to_file("res://Scenes/Hall.tscn")

func _type_text() -> void:
	dialog_label.text = ""
	
	for i in range(current_full_text.length()):
		dialog_label.text += current_full_text[i]
		await get_tree().create_timer(type_speed).timeout
	
	# Текст допечатан - показываем кнопку
	next_button.visible = true

func _on_next_pressed() -> void:
	current_index += 1
	_show_dialog()
