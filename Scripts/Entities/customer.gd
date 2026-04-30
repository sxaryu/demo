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
const INGREDIENT_NAMES := preload("res://Scripts/Core/IngredientNames.gd")

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

# === СТИЛИ РЕЧИ ДЛЯ КАЖДОГО NPC ===
const SPEECH_STYLES := {
	"grandma": {
		"greetings": ["Здравствуй, внучек!", "Доброго здоровьица!", "Милочек, будь добр...", "Привет, деточка!"],
		"thanks": ["спасибо, родной", "благослови тебя бог", "буду ждать, милый", "спасибочки, золотце"],
		"extra": ["и пожирнее", "чтоб душа радовалась", "как в старые времена", "на здоровье"],
		"reactions": {
			"perfect": ["Вкуснотища! Как дома!", "Божественно! Молодец, внучек!", "Вот это понимаю - шаурма!", "Ммм, пальчики оближешь!"],
			"good": ["Хорошенько, милый!", "Ничего так, спасибо!", "Вкусно, родной!"],
			"acceptable": ["Ну... сойдёт.", "Могло быть и лучше.", "Так себе, но съедобно."],
			"bad": ["Ой, это... плохо.", "Эх, молодёжь... Не умеет готовить.", "Это даже не шаурма, а что-то..."]
		}
	},
	"bald_man": {
		"greetings": ["Привет.", "Здорово.", "Что-нибудь поесть."],
		"thanks": ["спасибо", "всё норм", "благодарю", "ок"],
		"extra": ["чтоб не голодать", "срочно", "без лишних разговоров"],
		"reactions": {
			"perfect": ["Отлично! Съел бы ещё.", "Нормально сделал!", "Вот это раз! Спасибо."],
			"good": ["Хорошо, спасибо.", "Нормально.", "Съел, всё ок."],
			"acceptable": ["Ну... нормально.", "Могло быть лучше.", "Так себе."],
			"bad": ["Фу, это не то.", "Пережарено/сухое.", "Не буду больше брать."]
		}
	},
	"blonde_girl": {
		"greetings": ["Приветики!", "Ой, привет!", "Здравствуйте!"],
		"thanks": ["спасибо большое!", "очень вкусно будет!", "спасибочки!", "мега спасибо!"],
		"extra": ["пожалуйста, очень хочу", "срочно, пожалуйста", "на вынос"],
		"reactions": {
			"perfect": ["Вау! Это так вкусно!", "Ой, обожаю шаурму!", "Лучше не бывает! Спасибо!"],
			"good": ["Ммм, вкусненько!", "Спасибо, мне понравилось!", "Ням-ням!"],
			"acceptable": ["Ну... окей.", "Хм, немного суховато.", "Не очень, но сойдёт."],
			"bad": ["Фу, это невкусно!", "Ой, это даже не хочется есть.", "Я разочарована..."]
		}
	},
	"businessman": {
		"greetings": ["Добрый день.", "Здравствуйте.", "Давайте быстрее."],
		"thanks": ["спасибо", "благодарю", "поторопитесь", "всё хорошо"],
		"extra": ["у меня встреча через 10 минут", "срочно", "на счётчике"],
		"reactions": {
			"perfect": ["Отлично! Продолжайте так.", "Хорошая работа.", "Принято, спасибо."],
			"good": ["Неплохо.", "Удовлетворительно.", "Так-то сойдёт."],
			"acceptable": ["Хм... могли бы лучше.", "Не очень качественно.", "Посредственно."],
			"bad": ["Это недопустимо!", "Жалоба на качество!", "Совсем не то, что заказывал."]
		}
	},
	"ginger_man": {
		"greetings": ["Здарова!", "Чё, как жизнь?", "Здравия желаю!"],
		"thanks": ["спасибо, брат", "благодарствую", "всё окей", "спасибо, мужик"],
		"extra": ["чтоб хватило", "пожирнее", "на сытость"],
		"reactions": {
			"perfect": ["Зашибись, брат!", "Вот это раз! Спасибо!", "Мужик, ты крут!"],
			"good": ["Нормально, спасибо!", "Сделал хорошо, брат.", "Всё супер!"],
			"acceptable": ["Ну... норм.", "Могло быть лучше.", "Так себе."],
			"bad": ["Эх, брат, не фартануло.", "Не то совсем.", "Больше не возьму."]
		}
	},
	"glasses_girl": {
		"greetings": ["Добрый вечер.", "Приветствую.", "Здравствуйте."],
		"thanks": ["благодарю", "спасибо", "всё правильно", "идеально"],
		"extra": ["всё по инструкции", "как в рецепте", "без ошибок"],
		"reactions": {
			"perfect": ["Идеальное исполнение!", "Превосходно!", "Безупречно! Спасибо."],
			"good": ["Хорошо сделано.", "Качественно.", "Правильная шаурма."],
			"acceptable": ["Допустимо.", "Есть недочёты.", "Могло быть лучше."],
			"bad": ["Это неверно.", "Критические ошибки.", "Совершенно неправильно."]
		}
	},
	"goth_girl": {
		"greetings": ["Привет...", "Мрачного дня.", "Ну, давай."],
		"thanks": ["спасиб", "ага", "жду", "нормально"],
		"extra": ["побольше тьмы", "без ярких овощей", "наоборот"],
		"reactions": {
			"perfect": ["Тьма... это вкусно.", "Мрачное удовольствие.", "Тёмно и вкусно. Спасибо."],
			"good": ["Нормально...", "Съедобно.", "Пойдёт."],
			"acceptable": ["Ну... ок.", "Не очень тёмно.", "Хотелось бы более мрачного."],
			"bad": ["Слишком светло.", "Это не для меня.", "Разочарование тьмы."]
		}
	},
	"grandpa": {
		"greetings": ["Здравия желаю!", "Доброго времени!", "Эх, молодёжь..."],
		"thanks": ["спасибо, сынок", "благодарен", "буду ждать", "всё чётко"],
		"extra": ["как раньше делали", "без фокусов", "по-честному"],
		"reactions": {
			"perfect": ["Вот так надо! Молодец!", "Как в старые времена!", "Эх, хорошо сделал, сынок!"],
			"good": ["Неплохо, сынок.", "Спасибо, сыт буду.", "Хорошо, молодец."],
			"acceptable": ["Ну... так себе.", "Эх, не то.", "Мог бы лучше."],
			"bad": ["Эх, молодёжь... Не умеет.", "Это не шаурма, сынок.", "Разочарован."]
		}
	},
	"pink_girl": {
		"greetings": ["Привет-привет!", "Хаюшки!", "Ой, здравствуй!"],
		"thanks": ["спасибочки!", "ты лучший!", "милочки, спасибо!", "очень-очень спасибо!"],
		"extra": ["пожалуйста", "срочно-срочно", "очень хочется"],
		"reactions": {
			"perfect": ["Вау! Это так мило и вкусно!", "Обожаю! Спасибо!", "Ты лучший! Ммм!"],
			"good": ["Ммм, вкусненько!", "Спасибо большое!", "Мне понравилось!"],
			"acceptable": ["Ну... окей.", "Хм, не очень.", "Могло быть вкуснее."],
			"bad": ["Ой, это не вкусно.", "Фу, не хочу.", "Мне грустно..."]
		}
	},
	"student": {
		"greetings": ["Йо!", "Привет, мужик.", "Чё каво?"],
		"thanks": ["спасибо", "всё супер", "всё гуд", "спасиб"],
		"extra": ["срочно", "пока не остыла", "на бегу"],
		"reactions": {
			"perfect": ["Зашибись! Спасибо!", "Вот это раз! Всё супер!", "Мужик, ты кайф!"],
			"good": ["Нормально, мужик!", "Всё гуд, спасибо.", "Качественно сделал!"],
			"acceptable": ["Ну... ок.", "Могло быть лучше.", "Так себе."],
			"bad": ["Эх, мужик, не фартануло.", "Это не то.", "Больше не возьму."]
		}
	}
}

# --- Текстовые данные (константы вместо static) ---
# Фразы берутся из SPEECH_STYLES для каждого NPC
# Имена ингредиентов берутся из IngredientNames.gd

const _INGREDIENT_NAMES_GEN := {
	"meat": "мяса", "tomato": "помидора",
	"salad": "салата", "cheese": "сыра", "onion": "лука", "pepper": "перца"
}

const _INGREDIENT_NAMES_INS := {
	"meat": "мясом", "tomato": "помидором",
	"salad": "салатом", "cheese": "сыром", "onion": "луком", "pepper": "перцем"
}

const _SAUCE_NAMES_INS := {
	"white_sauce": "белым",
	"spicy_sauce": "острым"
}

# --- Узлы ---
@onready var character: Sprite2D = $Character
@onready var bubble: NinePatchRect = $SpeechBubble
@onready var label: Label = $SpeechBubble/DialogLabel
@onready var next_button: Button = $SpeechBubble/NextButton

# --- Сигналы ---
signal order_confirmed(order: Dictionary)

# --- Переменные ---
var _state: State = State.ENTERING  # Приватная для защиты через setter
var order_templates: Node
var order_data: Dictionary = {}
var current_full_text := ""
var type_speed := 0.05  # Немного медленнее для читаемости
var customer_id: String = "bald_man"

# Защита от повторного нажатия
var _is_order_confirmed: bool = false

# Внутренние переменные состояния
var _idle_time := 0.0
var _base_y := 0.0
var _is_order_shown := false
var _typing_timer: Timer = null  # Таймер для печатания текста
var _typing_index: int = 0
var _active_tweens: Array[Tween] = []  # Для очистки при выходе

# Геттер/сеттер для state
var state: State:
	get: return _state
	set(value): 
		push_warning("Customer: используй _enter_state() для смены состояния!")
		_enter_state(value)

# ==================== READY ====================
func _ready() -> void:
	if ORDER_TEMPLATES == null:
		push_error("Не удалось загрузить order_templates.gd")
		return
		
	order_templates = ORDER_TEMPLATES.new()
	
	next_button.pressed.connect(_on_next_pressed)
	
	if character:
		character.visible = false
	
	_hide_dialog()
	
	if customer_id != "":
		_update_texture()
	
	_enter_state(State.ENTERING)

# ==================== EXIT ====================
func _exit_tree() -> void:
	# Очищаем все твины
	_clear_all_tweens()
	
	if order_templates:
		order_templates.free()
		order_templates = null

func _clear_all_tweens() -> void:
	_clear_typing_tween()
	
	for tween in _active_tweens:
		if tween and tween.is_valid():
			tween.kill()
	_active_tweens.clear()

# ==================== STATE MACHINE ====================
func _enter_state(new_state: State) -> void:
	_state = new_state
	
	match _state:
		State.ENTERING:
			_enter_entering()
		State.ORDERING:
			_enter_ordering()
		State.WAITING:
			_enter_waiting()

func _enter_entering() -> void:
	_is_order_shown = false
	_is_order_confirmed = false

	if not character:
		push_error("Customer: узел Character не найден!")
		_enter_state(State.ORDERING)
		return
		
	character.visible = true
	character.scale = Vector2(0.85, 0.85)
	character.modulate.a = 0.0
	_base_y = character.position.y

	var tween := create_tween()
	_active_tweens.append(tween)
	tween.set_parallel(true)
	tween.tween_property(character, "scale", Vector2.ONE, 0.3)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(character, "modulate:a", 1.0, 0.25)
	
	await tween.finished
	_enter_state(State.ORDERING)

func _enter_ordering() -> void:
	# Если заказ уже был показан или подтверждён - не показываем снова
	if _is_order_shown or _is_order_confirmed:
		return
	
	if character:
		_base_y = character.position.y
	
	_show_order()

func _enter_waiting() -> void:
	# Отменяем печатание
	_clear_typing_tween()
	
	if character:
		character.visible = true
		character.scale = Vector2.ONE
		character.modulate.a = 1.0
		_base_y = character.position.y
	
	_hide_dialog()
	_idle_time = 0.0
	# Не сбрасываем _is_order_shown - заказ уже был показан клиенту
	# _is_order_shown = false
	_is_order_confirmed = true  # Заказ подтверждён

func _process(delta: float) -> void:
	if _state == State.WAITING or _state == State.ORDERING:
		if character and character.visible:
			_idle_time += delta
			var offset := sin(_idle_time * 3.0) * 5.0
			character.position.y = _base_y + offset

func _input(event: InputEvent) -> void:
	# Пропуск печатания по клику
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if bubble.visible and _typing_timer and _typing_timer.is_inside_tree():
			_skip_typing()

func _skip_typing() -> void:
	_clear_typing_tween()
	if label:
		label.text = current_full_text
	if next_button:
		next_button.visible = true

func _clear_typing_tween() -> void:
	if _typing_timer and is_instance_valid(_typing_timer):
		_typing_timer.stop()
		if _typing_timer.timeout.is_connected(_on_typing_tick):
			_typing_timer.timeout.disconnect(_on_typing_tick)
		_typing_timer.queue_free()
		_typing_timer = null
		_typing_index = 0

# ==================== ПУБЛИЧНЫЕ МЕТОДЫ ====================
func set_order(order: Dictionary) -> void:
	order_data = order.duplicate(true)

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

## Получает стиль речи для текущего NPC
func _get_speech_style() -> Dictionary:
	return SPEECH_STYLES.get(customer_id, SPEECH_STYLES["bald_man"])

## Получает случайное приветствие
func _get_greeting() -> String:
	var style := _get_speech_style()
	var greetings: Array = style.get("greetings", ["Привет!"])
	return greetings.pick_random() if not greetings.is_empty() else "Привет!"

## Получает случайную благодарность
func _get_thanks() -> String:
	var style := _get_speech_style()
	var thanks: Array = style.get("thanks", ["спасибо"])
	return thanks.pick_random() if not thanks.is_empty() else "спасибо"

## Получает случайную дополнительную фразу
func _get_extra_phrase() -> String:
	var style := _get_speech_style()
	var extras: Array = style.get("extra", [])
	if not extras.is_empty() and randf() < 0.3:
		return extras.pick_random()
	return ""

## Получает реакцию на качество шаурмы
func _get_reaction_text(validation_result: Dictionary) -> String:
	var validation: int = validation_result.get("validation", 0)
	var quality_key := ""
	
	match validation:
		VALIDATOR.ValidationResult.PERFECT:
			quality_key = "perfect"
		VALIDATOR.ValidationResult.GOOD:
			quality_key = "good"
		VALIDATOR.ValidationResult.ACCEPTABLE:
			quality_key = "acceptable"
		VALIDATOR.ValidationResult.BAD:
			quality_key = "bad"
		_:
			quality_key = "acceptable"
	
	var style := _get_speech_style()
	var reactions: Dictionary = style.get("reactions", {})
	var quality_phrases: Array = reactions.get(quality_key, ["Спасибо."])
	
	return quality_phrases.pick_random() if not quality_phrases.is_empty() else "Спасибо."

## Реагирует на получение шаурмы
func react_to_shawarma(validation_result: Dictionary, tip: int) -> void:
	var reaction_text := _get_reaction_text(validation_result)
	
	# Добавляем информацию о чаевых если есть
	if tip > 0:
		reaction_text += " (+" + str(tip) + "₽)"
	
	# Показываем реакцию с анимацией появления
	if bubble and label:
		# Удаляем старый таймер печатания если есть
		_clear_typing_tween()
		
		# Сбрасываем состояние для анимации появления
		bubble.visible = true
		bubble.modulate.a = 0.0
		bubble.scale = Vector2(0.8, 0.8)
		label.text = reaction_text
		next_button.visible = false
		
		# Анимация появления
		var appear_tween := create_tween()
		_active_tweens.append(appear_tween)
		appear_tween.set_parallel(true)
		appear_tween.tween_property(bubble, "scale", Vector2.ONE, 0.25)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		appear_tween.tween_property(bubble, "modulate:a", 1.0, 0.2)
		
		await appear_tween.finished
		
		# Ждём показа реакции (увеличил с 2.0 до 3.5 секунд)
		await get_tree().create_timer(3.5).timeout
		
		# Анимация исчезновения (противоположная появлению)
		if bubble:
			var disappear_tween := create_tween()
			_active_tweens.append(disappear_tween)
			disappear_tween.set_parallel(true)
			disappear_tween.tween_property(bubble, "scale", Vector2(0.8, 0.8), 0.25)\
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			disappear_tween.tween_property(bubble, "modulate:a", 0.0, 0.2)
			
			await disappear_tween.finished
			bubble.visible = false

## Генерирует заказ с случайными исключениями и модификаторами
func generate_random_order_with_exclusions() -> Dictionary:
	if not order_templates:
		push_error("Order templates не инициализированы!")
		return {}
	
	# Выбираем случайный тип шаурмы (0=классическая, 1=веганская, 2=сырная)
	var shawarma_type: int = randi() % 3
	
	# Получаем разрешённые исключения для этого типа
	var allowed_exclusions: Array = []
	match shawarma_type:
		ORDER_TEMPLATES.ShawarmaType.CLASSIC:
			allowed_exclusions = ["onion", "pepper", "tomato", "salad"]
		ORDER_TEMPLATES.ShawarmaType.VEGAN:
			allowed_exclusions = ["onion", "pepper", "tomato", "salad"]
		ORDER_TEMPLATES.ShawarmaType.CHEESE:
			allowed_exclusions = ["onion", "pepper", "tomato", "salad"]  # Сыр нельзя исключить!
	
	# С шансом 40% исключаем что-то
	var exclusions: Array = []
	if randf() < 0.4 and not allowed_exclusions.is_empty():
		# Исключаем 1-2 ингредиента
		var num_exclusions: int = randi() % 2 + 1
		var shuffled: Array = allowed_exclusions.duplicate()
		shuffled.shuffle()
		exclusions = shuffled.slice(0, min(num_exclusions, shuffled.size()))
	
	# Получаем случайный модификатор
	var modifier: int = order_templates.get_random_modifier()
	
	# Генерируем заказ
	var order: Dictionary = order_templates.generate_order_by_type(shawarma_type, exclusions, modifier)
	return order

## Вспомогательная функция для естественного перечисления с "и"
func _join_with_and(items: PackedStringArray) -> String:
	if items.size() == 0:
		return ""
	elif items.size() == 1:
		return items[0]
	else:
		var all_but_last = items.slice(0, items.size() - 1)
		return ", ".join(all_but_last) + " и " + items[items.size() - 1]

## Строит полный текст заказа из данных
func _build_order_text() -> String:
	var parts := PackedStringArray()
	
	# 1. Приветствие и запрос
	var greeting = _get_greeting()
	var item_name = order_data.get("name_accusative", "шаурму")
	parts.append("%s, хочу %s" % [greeting, item_name])
	
	# 2. Исключения (встраиваем сразу после запроса)
	var exclusions: Array = order_data.get("exclusions", [])
	if not exclusions.is_empty():
		var exc_names: PackedStringArray = INGREDIENT_NAMES.get_ingredient_names(exclusions, "gen")
		if not exc_names.is_empty():
			parts.append("без " + _join_with_and(exc_names))
	
	# 3. Модификатор (он может влиять на ингредиенты и соусы)
	var modifier: int = order_data.get("modifier", 0)
	var modifier_name: String = order_data.get("modifier_name", "")
	var has_modifier := modifier_name != ""
	
	# 4. Ингредиенты (кроме тех, что исключены)
	var ingredients: Array = order_data.get("ingredients", [])
	var ing_names_ins: PackedStringArray = []
	for ing in ingredients:
		if ing not in exclusions:
			ing_names_ins.append(INGREDIENT_NAMES.get_ingredient_name_ins(ing))
	
	# 5. Соусы
	var sauces: Array = order_data.get("sauces", [])
	var sauce_names_ins: PackedStringArray = INGREDIENT_NAMES.get_sauce_names(sauces)
	
	# Если модификатор подразумевает изменение соуса, лучше не дублировать
	var modifier_affects_sauce := has_modifier and (
		modifier == ORDER_TEMPLATES.OrderModifier.EXTRA_SAUCE or 
		modifier == ORDER_TEMPLATES.OrderModifier.LITTLE_SAUCE or
		modifier == ORDER_TEMPLATES.OrderModifier.SPICY or
		modifier == ORDER_TEMPLATES.OrderModifier.MILD
	)
	
	# 6. Собираем ингредиенты и соусы вместе
	var combined_parts := PackedStringArray()
	
	# Добавляем ингредиенты
	if not ing_names_ins.is_empty():
		combined_parts.append(_join_with_and(ing_names_ins))
	
	# Добавляем соусы (если модификатор не переопределяет)
	if not modifier_affects_sauce and not sauce_names_ins.is_empty():
		if sauce_names_ins.size() == 1:
			combined_parts.append("соусом " + sauce_names_ins[0])
		else:
			combined_parts.append("соусами: " + _join_with_and(sauce_names_ins))
	
	# Если есть что-то для перечисления, добавляем с предлогом "с"
	if not combined_parts.is_empty():
		parts.append("с " + ", ".join(combined_parts))
	
	# 7. Добавляем модификатор (если ещё не добавили)
	if has_modifier and not modifier_affects_sauce:
		parts.append(modifier_name)
	
	# 8. Завершающая фраза
	var thanks = _get_thanks()
	var extra = _get_extra_phrase()
	
	var full_text = ", ".join(parts) + ". "
	full_text += thanks
	
	if extra != "":
		full_text += " " + extra
	
	return full_text

## Получает текст для соусов с правильным согласованием
func _get_sauce_text() -> String:
	var sauce_list := INGREDIENT_NAMES.get_sauce_names(order_data.get("sauces", []))
	
	if sauce_list.is_empty():
		return ""
	elif sauce_list.size() == 1:
		return "с %s соусом" % sauce_list[0]
	else:
		return "с соусами: " + ", ".join(sauce_list)

func _show_order() -> void:
	_is_order_shown = true
	
	if bubble:
		bubble.visible = false
		bubble.modulate.a = 0.0
		bubble.scale = Vector2(0.8, 0.8)
	
	if label:
		label.text = ""
	
	if next_button:
		next_button.visible = false

	if order_data.is_empty() or not order_data.has("name"):
		# Используем новый генератор заказов с исключениями
		order_data = generate_random_order_with_exclusions()
		if order_data.is_empty():
			push_error("Не удалось сгенерировать заказ!")
			return
	
	# Строим текст заказа
	current_full_text = _build_order_text()
	
	if bubble:
		bubble.visible = true
		var tween := create_tween()
		_active_tweens.append(tween)
		tween.set_parallel(true)
		tween.tween_property(bubble, "scale", Vector2.ONE, 0.25)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(bubble, "modulate:a", 1.0, 0.2)
		
		await tween.finished
	
	_type_text()

func _type_text() -> void:
	if not label:
		return
		
	label.text = ""
	_typing_index = 0
	
	# Создаём таймер для печатания
	_typing_timer = Timer.new()
	_typing_timer.wait_time = type_speed
	_typing_timer.one_shot = false
	_typing_timer.timeout.connect(_on_typing_tick)
	add_child(_typing_timer)
	_typing_timer.start()

func _on_typing_tick() -> void:
	if not label:
		_clear_typing_tween()
		return
	
	# Проверяем, не скрыт ли диалог
	if bubble and not bubble.visible:
		_clear_typing_tween()
		return
	
	# Добавляем следующий символ
	if _typing_index < current_full_text.length():
		label.text += current_full_text[_typing_index]
		_typing_index += 1
	else:
		# Печатание завершено
		_clear_typing_tween()
		if next_button:
			next_button.visible = true

# ==================== CALLBACKS ====================
func _on_next_pressed() -> void:
	# Защита от повторного нажатия
	if _is_order_confirmed:
		return
	_is_order_confirmed = true
	
	_clear_typing_tween()

	order_confirmed.emit(order_data)
	_enter_state(State.WAITING)

func _hide_dialog() -> void:
	if bubble:
		bubble.visible = false
	if next_button:
		next_button.visible = false
	_clear_typing_tween()
