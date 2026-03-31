extends Node2D
class_name TutorialKitchen

# --- Сигналы ---
signal tutorial_step_completed(step: int)
signal tutorial_finished()

# --- Этапы ---
enum Step {
	INTRO,              # Знакомство
	CREATE_LAVASH,      # Создать лаваш
	ADD_MEAT,           # Добавить мясо
	ADD_VEGGIES,        # Добавить овощи
	ADD_SAUCE,          # Добавить соус
	TO_GRILL,           # Переход на гриль
	GRILL,              # Жарить
	PACKAGE,            # Упаковать
	DONE                # Готово
}

var current_step: Step = Step.INTRO

# --- Узлы UI ---
var overlay: ColorRect           # Затемнение
var highlight_rect: ColorRect    # Подсветка (дырка)
var hint_panel: Panel            # Панель подсказки
var hint_label: Label
var hint_button: Button

# --- Ссылки на элементы кухни (получаем от родителя) ---
var ingredient_panel: Control
var sauce_bottle: Node
var work_area: Node2D
var done_button: Button
var lavash_button: TextureButton


func _ready() -> void:
	# Получаем узлы от родителя (Kitchen)
	var kitchen: Node2D = get_parent()
	ingredient_panel = kitchen.get_node("IngredientPanel")
	sauce_bottle = kitchen.get_node("SauceBottle")
	work_area = kitchen.get_node("WorkArea")
	done_button = kitchen.get_node("DoneButton")
	lavash_button = kitchen.get_node("LavashButton")
	
	_setup_overlay()
	
	# Запускаем обучение с задержкой
	await get_tree().create_timer(0.5).timeout
	_show_current_hint()

# --- Тексты подсказок ---
var hints := {
	Step.INTRO: """Добро пожаловать на кухню!

Это твоя шаурмечная. Давай покажу, как тут всё работает.""",

	Step.CREATE_LAVASH: """Сначала создай лаваш!

Нажми на кнопку с лавашом (слева внизу).
Появится основа для шаурмы.""",

	Step.ADD_MEAT: """Начнём с мяса!

Нажми на кнопку с мясом (справа внизу).
Оно перенесётся на лаваш.""",

	Step.ADD_VEGGIES: """Отлично! Теперь овощи.

Добавь помидоры и салат.
Нажимай на них - они добавятся к шаурме.""",

	Step.ADD_SAUCE: """Теперь соус!

Возьми бутылку слева (перетащи на шаурму).
Нарисуй соус по вкусу.""",

	Step.TO_GRILL: """Всё готово! Время жарить!

Нажми кнопку "Готово" (справа внизу).
Перейдёшь на экран с грилем.""",

	Step.GRILL: """Время жарить!

Перетащи шаурму на гриль (справа внизу).
Подожди пока пожарится (5 секунд).""",

	Step.PACKAGE: """Шаурма готова! Теперь упаковка.

Нажми на кнопку с пакетом (справа внизу).
Потом кликни на шаурму - и она завёрнётся!""",

	Step.DONE: """Молодец! Шаурма готова.

Нажми кнопку "Готово" и отнеси её тёте Зине!
Она даст тебе 1000 рублей на чай."""
}

func _setup_overlay() -> void:
	# Затемнение (весь экран)
	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	
	# Подсветка (дырка в затемнении) - используем clip_content
	highlight_rect = ColorRect.new()
	highlight_rect.color = Color(1, 1, 0, 0.3)  # Жёлтая подсветка
	highlight_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	highlight_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(highlight_rect)
	
	# Панель подсказки
	_setup_hint_panel()

func _setup_hint_panel() -> void:
	# Панель по центру
	hint_panel = Panel.new()
	hint_panel.set_anchors_preset(Control.PRESET_CENTER)
	hint_panel.custom_minimum_size = Vector2(500, 180)
	hint_panel.z_index = 100
	add_child(hint_panel)
	
	# Стилизация
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	style.border_color = Color(1, 0.8, 0.2, 1)
	style.set_border_width_all(4)
	style.set_corner_radius_all(16)
	hint_panel.add_theme_stylebox_override("panel", style)
	
	# Заголовок
	var title := Label.new()
	title.text = "Тётя Зина"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 10
	title.add_theme_font_size_override("font_size", 24)
	hint_panel.add_child(title)
	
	# Текст
	hint_label = Label.new()
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	hint_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	hint_label.offset_top = 45
	hint_label.offset_bottom = -55
	hint_label.add_theme_font_size_override("font_size", 20)
	hint_panel.add_child(hint_label)
	
	# Кнопка
	hint_button = Button.new()
	hint_button.text = "Хорошо"
	hint_button.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint_button.offset_left = 150
	hint_button.offset_right = -150
	hint_button.offset_bottom = -15
	hint_button.add_theme_font_size_override("font_size", 20)
	hint_button.pressed.connect(_on_hint_button_pressed)
	hint_panel.add_child(hint_button)

# ---------------- УПРАВЛЕНИЕ ----------------
func _show_current_hint() -> void:
	# Проверяем завершение
	if current_step >= Step.DONE:
		tutorial_finished.emit()
		return
	
	# Получаем текст подсказки
	var text: String = hints.get(current_step, "Подсказка не найдена")
	hint_label.text = text
	
	# Показываем/скрываем подсветку
	_highlight_element()
	
	# Анимация появления
	hint_panel.modulate.a = 0.0
	hint_panel.visible = true
	var tween := create_tween()
	tween.tween_property(hint_panel, "modulate:a", 1.0, 0.3)

func _highlight_element() -> void:
	var element: Node = null
	
	match current_step:
		Step.CREATE_LAVASH:
			element = lavash_button
		Step.ADD_MEAT:
			element = ingredient_panel.get_node("Meat")
		Step.ADD_VEGGIES:
			element = ingredient_panel.get_node("Tomato")
		Step.ADD_SAUCE:
			element = sauce_bottle
		Step.TO_GRILL:
			element = done_button
		Step.GRILL, Step.PACKAGE, Step.DONE:
			# Гриль и упаковка - на следующей сцене (KitchenWrap)
			# Просто скрываем подсветку
			highlight_rect.visible = false
			return

	if element:
		_set_highlight(element)

func _set_highlight(element: Node) -> void:
	if not element:
		highlight_rect.visible = false
		return
	
	# Получаем глобальную позицию элемента
	var rect: Rect2 = element.get_global_rect()
	
	# Позиционируем подсветку
	highlight_rect.global_position = rect.position - Vector2(10, 10)
	highlight_rect.custom_minimum_size = rect.size + Vector2(20, 20)
	highlight_rect.visible = true
	
	# Анимация пульсации
	var tw := create_tween()
	tw.set_loops()
	tw.tween_property(highlight_rect, "modulate:a", 0.5, 0.5)
	tw.tween_property(highlight_rect, "modulate:a", 0.2, 0.5)

func _on_hint_button_pressed() -> void:
	# Скрываем подсказку
	hint_panel.visible = false
	highlight_rect.visible = false
	
	# Переходим к следующему шагу
	current_step = current_step + 1
	tutorial_step_completed.emit(current_step)
	
	# Сразу показываем следующую подсказку
	_show_current_hint()

# ---------------- ПРОВЕРКА ДЕЙСТВИЙ ----------------
# Эти методы вызываются из основного скрипта кухни
# Автоматический переход ОТКЛЮЧЕН - игрок сам нажимает "Хорошо"
func on_ingredient_added(type: String) -> void:
	# Просто логируем действие, не переходим к следующему шагу
	print("Добавлен ингредиент:", type)

func on_sauce_added() -> void:
	# Просто логируем, не переходим
	print("Добавлен соус")

func on_grill_started() -> void:
	# Не переходим автоматически
	print("Начато жарение")

func on_packaged() -> void:
	# Не переходим автоматически
	print("Упаковано")

# Удаляем _complete_step - больше не нужен

# ---------------- СКРЫТЬ OVERLAY ----------------
func hide_overlay() -> void:
	if overlay:
		overlay.visible = false
	if highlight_rect:
		highlight_rect.visible = false
	if hint_panel:
		hint_panel.visible = false
