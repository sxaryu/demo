extends Node
class_name TutorialManager

# --- Сигналы ---
signal step_completed(step_name: String)
signal tutorial_finished()

# --- Этапы туториала ---
enum Step {
	INTRO,              # Тётя Зина представляется
	SHOW_INGREDIENTS,   # Показываем ингредиенты
	SHOW_SAUCES,        # Показываем соусы
	SHOW_GRILL,         # Показываем гриль
	SHOW_PACKAGING,     # Показываем упаковку
	MAKE_SHAWU,         # Игрок делает шаурму
	DELIVER,            # Отдаём шаурму
	FINISH              # Завершение
}

var current_step: Step = Step.INTRO

# --- Узлы UI ---
var hint_panel: Panel
var hint_label: Label
var hint_button: Button

# --- Ссылки ---
var tutorial_customer: Node2D = null

# ---------------- INIT ----------------
func _ready() -> void:
	_setup_ui()

func _setup_ui() -> void:
	# Создаём панель подсказки
	hint_panel = Panel.new()
	hint_panel.set_anchors_preset(Control.PRESET_CENTER)
	hint_panel.custom_minimum_size = Vector2(600, 200)
	hint_panel.z_index = 1000
	add_child(hint_panel)
	
	# Заголовок
	var title := Label.new()
	title.text = "Тётя Зина"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 10
	title.add_theme_font_size_override("font_size", 28)
	hint_panel.add_child(title)
	
	# Текст подсказки
	hint_label = Label.new()
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	hint_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	hint_label.offset_top = 50
	hint_label.offset_bottom = -60
	hint_label.add_theme_font_size_override("font_size", 24)
	hint_panel.add_child(hint_label)
	
	# Кнопка "Понятно"
	hint_button = Button.new()
	hint_button.text = "Понятно, поехали!"
	hint_button.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint_button.offset_left = 200
	hint_button.offset_right = -200
	hint_button.offset_bottom = -20
	hint_button.add_theme_font_size_override("font_size", 24)
	hint_button.pressed.connect(_on_hint_button_pressed)
	hint_panel.add_child(hint_button)
	
	# Стилизация
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.border_color = Color(1, 0.8, 0.2, 1)
	style.set_border_width_all(4)
	style.set_corner_radius_all(16)
	hint_panel.add_theme_stylebox_override("panel", style)
	
	hint_panel.visible = false

# ---------------- УПРАВЛЕНИЕ ----------------
func start_tutorial() -> void:
	current_step = Step.INTRO
	show_hint(_get_hint_text(Step.INTRO))

func show_hint(text: String, button_text: String = "Понятно, поехали!") -> void:
	hint_label.text = text
	hint_button.text = button_text
	hint_panel.visible = true
	
	# Анимация появления
	hint_panel.modulate.a = 0.0
	hint_panel.scale = Vector2(0.8, 0.8)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(hint_panel, "modulate:a", 1.0, 0.3)
	tween.tween_property(hint_panel, "scale", Vector2.ONE, 0.3)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func hide_hint() -> void:
	var tween := create_tween()
	tween.tween_property(hint_panel, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(hint_panel, "scale", Vector2(0.8, 0.8), 0.2)
	tween.tween_callback(func(): hint_panel.visible = false)

func _on_hint_button_pressed() -> void:
	# Сначала скрываем подсказку
	hide_hint()
	
	# Испускаем сигнал о завершении ТЕКУЩЕГО шага
	step_completed.emit(_get_step_name(current_step))
	
	# Переходим к следующему
	await get_tree().create_timer(0.3).timeout
	_next_step()

func _next_step() -> void:
	var next := current_step + 1
	if next >= Step.FINISH:
		tutorial_finished.emit()
		return
	
	current_step = next
	
	# Задержка перед следующей подсказкой
	await get_tree().create_timer(0.5).timeout
	show_hint(_get_hint_text(current_step))

# ---------------- ТЕКСТЫ ПОДСКАЗОК ----------------
func _get_step_name(step: Step) -> String:
	match step:
		Step.INTRO: return "intro"
		Step.SHOW_INGREDIENTS: return "show_ingredients"
		Step.SHOW_SAUCES: return "show_sauces"
		Step.SHOW_GRILL: return "show_grill"
		Step.SHOW_PACKAGING: return "show_packaging"
		Step.MAKE_SHAWU: return "make_shawu"
		Step.DELIVER: return "deliver"
		Step.FINISH: return "finish"
		_: return "unknown"

func _get_hint_text(step: Step) -> String:
	match step:
		Step.INTRO:
			return """Привет, дорогой! Я - тётя Зина.

30 лет я делала лучшую шаурму в районе.
Но возраст... пора передавать дело молодым!

Я передаю тебе всё своё мастерство. 
За работу!"""

		Step.SHOW_INGREDIENTS:
			return """Слева на панели - ингредиенты.

Мясо, курица, помидоры, салат, сыр, лук - всё самое свежее!

Перетаскивай их на лаваш. 
Каждый ингредиент весит определённое количество грамм."""

		Step.SHOW_SAUCES:
			return """Справа - соусы.

Белый, красный, острый - выбирай на вкус!

Рисуй соус прямо на шаурме. 
Не жалей, клиент любит щедрых!"""

		Step.SHOW_GRILL:
			return """Когда ингредиенты выложены - пора на гриль!

Перетащи шаурму на горячую зону (справа).
Она пожарится за 5 секунд.

Жди сигнала - шаурма станет золотистой!"""

		Step.SHOW_PACKAGING:
			return """Готово? Теперь упаковка!

Нажми на кнопку с пакетом (справа внизу).
Пакет прилипнет к курсору - нажми на шаурму!

Она завёрнётся в красивую упаковку."""

		Step.MAKE_SHAWU:
			return """А теперь - твоя очередь!

Собери шаурму с мясом, добавь овощи и соус.
Пожарь на гриле, упакуй.

Тётя Зина будет ждать!"""

		Step.DELIVER:
			return """Отлично получилось!

Забирай свою награду - 1000 рублей «на чай».
Иди к стойке и отдай шаурму тёте Зине."""

		Step.FINISH:
			return """Молодец! Первый заказ выполнен!

Держи ещё 500 рублей на развитие.
Впереди ещё много работы - но ты справишься!

Тётя Зина верит в тебя!"""

	return ""

# ---------------- ДЛЯ КУХНИ ----------------
func show_kitchen_hints() -> void:
	# Показываем подсказки в зависимости от этапа
	match current_step:
		Step.MAKE_SHAWU:
			show_hint(_get_hint_text(Step.MAKE_SHAWU), "Начинаю!")

# ---------------- ПРОВЕРКА ДЕЙСТВИЙ ----------------
func check_action(action: String) -> void:
	match current_step:
		Step.MAKE_SHAWU:
			if action == "shawu_fried":
				await get_tree().create_timer(1.0).timeout
				show_hint(_get_hint_text(Step.SHOW_PACKAGING), "Понял!")
				current_step = Step.SHOW_PACKAGING
			elif action == "shawu_packaged":
				await get_tree().create_timer(1.0).timeout
				current_step = Step.DELIVER
				show_hint(_get_hint_text(Step.DELIVER), "Несу!")
