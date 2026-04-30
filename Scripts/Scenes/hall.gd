extends Node2D

# ==================== KITCHEN ====================
# --- Узлы ---
@onready var customer_spawn_point: Node2D = $CustomerSpawnPoint
@onready var shawu_spawn_point: Node2D = $ShawuSpawnPoint
@onready var money_counter: Label = $MoneyPanel/MoneyCounter
@onready var time_label: Label = $TimePanel/TimeLabel
@onready var save_and_quit_button: Button = $SaveAndQuitButton

# --- Переменные ---
var current_customer: Customer
var current_shawu: Lavash
<<<<<<< HEAD
var money: float = 0.0
=======
>>>>>>> c33e8377b6fd006e3771648747071697b41d5043
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

# --- Защита от повторных вызовов ---
var _is_delivering: bool = false
var _active_delivery_tween: Tween = null

# --- Preload ---
const SCENE_CUSTOMER := preload("res://Scenes/Customer.tscn")
const SCENE_LAVASH := preload("res://Scenes/Lavash.tscn")
const VALIDATOR := preload("res://Scripts/Core/ShawarmaValidator.gd")

# --- Константы ---
const BASE_REWARD := 250.0  # Базовая награда

# ---------------- READY ----------------
func _ready() -> void:
<<<<<<< HEAD
	# Убеждаемся, что деньги синхронизированы с Globals
	money = Globals.total_money
	money_counter.text = str(snappedf(money, 0.01)) + "₽"
=======
	EventBus.money_changed.connect(_on_money_changed)
	_update_money_display()
>>>>>>> c33e8377b6fd006e3771648747071697b41d5043
	_update_time_display()
	EventBus.money_changed.connect(_on_money_changed)
	EventBus.time_changed.connect(_on_time_changed)
	
	# Подключаем кнопку "Сохранить и выйти"
	save_and_quit_button.pressed.connect(_on_save_and_quit_pressed)
	
	if Globals.is_work_day_over():
		_end_work_day()
		return

<<<<<<< HEAD
	# Сцена всегда пустая - создаём клиента заново
	if _validate_packed_shawu_data():
		# Клиент уже сделал заказ и ждёт готовую шаурму
		_spawn_customer_waiting()
=======
	if not Globals.last_packed_lavash.is_empty():
		_spawn_customer_stand_still()
>>>>>>> c33e8377b6fd006e3771648747071697b41d5043
		_spawn_packed_shawu()
	elif Globals.last_order.is_empty():
		_spawn_customer_with_order()
	else:
		_spawn_customer_with_saved_order()

func _on_money_changed(new_amount: float) -> void:
<<<<<<< HEAD
	money = new_amount
	if money_counter:
		money_counter.text = str(snappedf(money, 0.01)) + "₽"
	
func _on_time_changed(_formatted_time: String) -> void:
	_update_time_display()
	
func _on_save_and_quit_pressed() -> void:
	# Сохраняем текущий баланс денег
	Globals.total_money = money
	Globals._save_full_progress()
	print("Прогресс сохранён! Выход в главное меню...")
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
	
=======
	_update_money_display()

func _update_money_display() -> void:
	if money_counter:
		money_counter.text = str(snappedf(Globals.total_money, 0.01)) + "₽"

>>>>>>> c33e8377b6fd006e3771648747071697b41d5043
# ---------------- SPAWN ----------------
func _spawn_customer_with_order() -> void:
	var customer_id := Globals.get_random_customer_id()
	# Очищаем старый заказ - это новый клиент
	Globals.last_customer_order = {}
	_setup_customer(_get_default_order(), customer_id, Customer.State.ENTERING)

func _spawn_customer_with_saved_order() -> void:
	var customer_id := Globals.last_customer_id if Globals.last_customer_id != "" else Globals.get_random_customer_id()
	# Восстанавливаем состояние клиента из сохранённого
	var state := Globals.last_customer_state as Customer.State
	_setup_customer(Globals.last_order, customer_id, state)

func _spawn_customer_waiting() -> void:
	# Восстанавливаем клиента в состоянии WAITING (ожидание готовой шаурмы)
	var customer_id: String
	if Globals.last_customer_id == Globals.GRANDMA_ID:
		customer_id = Globals.GRANDMA_ID
	else:
		customer_id = Globals.last_customer_id if Globals.last_customer_id != "" else Globals.get_random_customer_id()
	_setup_customer({}, customer_id, Customer.State.WAITING)

func _setup_customer(order: Dictionary, customer_id: String, new_state: Customer.State) -> void:
	_free_customer()
	current_customer = SCENE_CUSTOMER.instantiate()
	
	# Восстанавливаем заказ из Globals если есть, иначе из order
	if not Globals.last_customer_order.is_empty():
		current_customer.set_order(Globals.last_customer_order)
	elif not order.is_empty():
		current_customer.set_order(order)
	
	current_customer.set_customer_id(customer_id)
	customer_spawn_point.add_child(current_customer)
	current_customer.order_confirmed.connect(_on_customer_order_confirmed)
	current_customer._enter_state(new_state)

func _get_default_order() -> Dictionary:
	return {"lavash": true, "meat": "meat", "tomato": 1, "salad": 1}

func _validate_packed_shawu_data() -> bool:
	var data = Globals.last_packed_lavash
	if data.is_empty():
		return false
	
	# Проверяем обязательные поля
	if not data.has("texture") or not data.has("ingredients"):
		push_error("Hall: повреждённые данные шаурмы - отсутствуют обязательные поля!")
		Globals.last_packed_lavash = {}
		return false
	
	return true

func _spawn_packed_shawu() -> void:
	var data = Globals.last_packed_lavash
	if data.is_empty():
		push_warning("Hall: данные шаурмы пустые!")
		return
		
	current_shawu = SCENE_LAVASH.instantiate()
	add_child(current_shawu)
	current_shawu.global_position = shawu_spawn_point.global_position
	current_shawu.visible = true

	# Загрузка данных
	_set_shawu_data(current_shawu, data)
	
	# Настройка спрайта
	var sprite = current_shawu.get_node_or_null("Sprite2D") as Sprite2D
	if sprite and data.has("texture"):
		sprite.texture = data.texture
		sprite.z_index = Consts.Z_INDEX_SHAWU
		sprite.visible = true

func _set_shawu_data(lavash: Lavash, data: Dictionary) -> void:
	if lavash.has_method("set_ingredients_data"):
		lavash.set_ingredients_data(data.get("ingredients", []))
	if lavash.has_method("set_sauce_data"):
		lavash.set_sauce_data(data.get("sauce", []))

func _free_customer() -> void:
	_free_instance(current_customer)
	current_customer = null

func _free_shawu() -> void:
	_free_instance(current_shawu)
	current_shawu = null

func _free_instance(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()

func _exit_tree() -> void:
	# Отключаем сигналы
	if EventBus.money_changed.is_connected(_on_money_changed):
		EventBus.money_changed.disconnect(_on_money_changed)
	
	if EventBus.time_changed.is_connected(_on_time_changed):
		EventBus.time_changed.disconnect(_on_time_changed)

# ---------------- INPUT ----------------
func _input(event: InputEvent) -> void:
	if not is_instance_valid(current_shawu):
		return

	if event is InputEventMouseButton:
		_handle_click(event)
	elif event is InputEventMouseMotion and is_dragging:
		var new_pos := get_global_mouse_position() + drag_offset
		new_pos = _clamp_shawu_position(new_pos)
		current_shawu.global_position = new_pos

func _handle_click(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	# ВСЕГДА сбрасываем drag при отпускании кнопки (даже вне спрайта!)
	if not event.pressed:
		if is_dragging:
			is_dragging = false
			_try_deliver()
		return

	# Начало перетаскивания - проверяем попадание в спрайт
	var mouse_pos := get_global_mouse_position()
	var sprite = current_shawu.get_node_or_null("Sprite2D") as Sprite2D
	if not sprite:
		return

	# Точная детекция через глобальный Rect2 с учётом scale
	var global_rect := _get_sprite_global_rect(sprite)
	if global_rect.has_point(mouse_pos):
		is_dragging = true
		drag_offset = current_shawu.global_position - mouse_pos

func _get_sprite_global_rect(sprite: Sprite2D) -> Rect2:
	var size := sprite.texture.get_size() if sprite.texture else Vector2.ZERO
	var scaled_size := size * sprite.scale
	var top_left := sprite.global_position - (scaled_size / 2.0)
	return Rect2(top_left, scaled_size)

func _clamp_shawu_position(pos: Vector2) -> Vector2:
	var viewport := get_viewport().get_visible_rect()
	var margin := 50.0  # Отступ от краёв экрана
	return pos.clamp(viewport.position + Vector2(margin, margin), viewport.end - Vector2(margin, margin))

# ---------------- DELIVERY ----------------
func _try_deliver() -> void:
	# Защита от повторного вызова
	if _is_delivering:
		return

	if not _both_valid():
		return

	var character = _get_customer_character_safe()
	if character and current_shawu.global_position.distance_to(character.global_position) < Consts.DELIVERY_DISTANCE:
		_deliver_shawu()

func _deliver_shawu() -> void:
	# Защита от повторного вызова
	if _is_delivering:
		return
	_is_delivering = true

	# Отменяем предыдущий твен, если есть
	if _active_delivery_tween and _active_delivery_tween.is_valid():
		_active_delivery_tween.kill()

	var sprite = current_shawu.get_node_or_null("Sprite2D") as Sprite2D
	if not sprite:
		_is_delivering = false
		return

	_active_delivery_tween = create_tween()
	_active_delivery_tween.tween_property(sprite, "modulate:a", 0.0, Consts.ANIM_FADE_DURATION)
	_active_delivery_tween.tween_callback(_on_delivery_complete)

func _on_delivery_complete() -> void:
<<<<<<< HEAD
	if not is_instance_valid(self):
		return
	
	_free_shawu()
	
	# Получаем результат валидации
	var validation_result: Dictionary = Globals.last_validation_result
	if validation_result.is_empty():
		validation_result = {
			"validation": VALIDATOR.ValidationResult.PERFECT,
			"score": 100,
			"issues": [],
			"weight_total": 0,
			"zones": {}
		}
	
	# Вычисляем чаевые на основе качества
	var base_reward := float(Consts.SHAWU_REWARD)
	var tip_multiplier := _get_tip_multiplier(validation_result)
	var tip := base_reward * tip_multiplier
	var total_reward := base_reward + tip
	
	money += total_reward
	Globals.total_money = money
	
	# Сохраняем только при важных моментах (переход между сценами, закрытие игры)
	# НЕ сохраняем при каждой доставке - это вызывает лаги
	
	if money_counter:
		money_counter.text = str(snappedf(money, 0.01)) + "₽"
	
	EventBus.money_changed.emit(money)
	EventBus.shawarma_delivered.emit(total_reward)
	
	# Показываем реакцию клиента (await для завершения анимации реакции)
	if is_instance_valid(current_customer):
		await current_customer.react_to_shawarma(validation_result, int(tip))
		# После await проверяем валидность снова
		if not is_instance_valid(self):
			return
	
	# Очищаем данные после успешной доставки
=======
	# Простая выплата без детальной проверки
	var reward = BASE_REWARD
	
	_free_shawu()
	Globals.add_money(reward)
	_update_money_display()
	
>>>>>>> c33e8377b6fd006e3771648747071697b41d5043
	Globals.last_packed_lavash = {}
	Globals.last_order = {}
	Globals.last_customer_order = {}
	Globals.last_validation_result = {}

	Globals.add_customer_time()
	Globals.customers_served += 1
	_update_time_display()
	
	if Globals.is_work_day_over():
		_is_delivering = false
		_end_work_day()
		return
<<<<<<< HEAD
		
=======
	
>>>>>>> c33e8377b6fd006e3771648747071697b41d5043
	if is_instance_valid(current_customer):
		_animate_customer_exit(current_customer)
		current_customer = null

	# Безопасный await - проверяем валидность узла
	await get_tree().create_timer(Consts.EXIT_DELAY).timeout
<<<<<<< HEAD
	
	if not is_instance_valid(self):
		return

	_is_delivering = false
	_spawn_customer_with_order()  # Спавним нового клиента с заказом
=======
	_spawn_customer_with_order()
>>>>>>> c33e8377b6fd006e3771648747071697b41d5043

func _update_time_display() -> void:
	if time_label:
		time_label.text = Globals.get_formatted_time()

func _end_work_day() -> void:
	# Сохраняем прогресс перед переходом на экран завершения дня
	Globals._save_full_progress()
	# Переход на экран завершения дня
	get_tree().change_scene_to_file("res://Scenes/EndDay.tscn")

# ---------------- ANIMATION ----------------
func _animate_customer_exit(customer: Customer) -> void:
	var character = customer.get_node_or_null("Character") as Sprite2D
	var bubble = customer.get_node_or_null("SpeechBubble") as NinePatchRect

	if not character:
		if is_instance_valid(customer):
			customer.queue_free()
		return

	var tween = create_tween()
	tween.set_parallel(true)
	
	# Bubble уже скрыт реакцией клиента, не трогаем его
	
	# Уход character
	tween.tween_property(character, "modulate:a", 0.0, Consts.ANIM_FADE_DURATION)
	tween.parallel().tween_property(character, "scale", Vector2(0.85, 0.85), Consts.ANIM_FADE_DURATION)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(character, "position:x", character.position.x + Consts.ANIM_EXIT_OFFSET, Consts.ANIM_EXIT_DURATION)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	tween.tween_callback(customer.queue_free)

# ---------------- CALLBACK ----------------
func _on_customer_order_confirmed(order: Dictionary) -> void:
	Globals.last_order = order
	# Сохраняем ID, состояние и заказ клиента для возврата из Kitchen
	Globals.last_customer_id = current_customer.customer_id
	Globals.last_customer_state = current_customer.state
	Globals.last_customer_order = current_customer.order_data
	# Сохраняем прогресс при переходе в Kitchen
	Globals._save_full_progress()
	get_tree().change_scene_to_file("res://Scenes/Kitchen.tscn")

# ---------------- HELPERS ----------------
func _both_valid() -> bool:
	return is_instance_valid(current_customer) and is_instance_valid(current_shawu)

func _get_customer_character_safe() -> Sprite2D:
	if not is_instance_valid(current_customer):
		return null
	return current_customer.get_node_or_null("Character") as Sprite2D

func _parse_money(text: String) -> int:
	var num_str = text.split(" ")[0]
	return num_str.to_int() if num_str.is_valid_int() else 0

<<<<<<< HEAD
## Получает множитель чаевых на основе результата валидации
func _get_tip_multiplier(validation_result: Dictionary) -> float:
	# Используем метод из валидатора для избежания дублирования
	var validator_instance := VALIDATOR.new()
	return validator_instance.get_tip_multiplier(validation_result)

=======
func _exit_tree() -> void:
	if EventBus.money_changed.is_connected(_on_money_changed):
		EventBus.money_changed.disconnect(_on_money_changed)
>>>>>>> c33e8377b6fd006e3771648747071697b41d5043
