extends Node2D

# ==================== KITCHEN ====================
# --- Узлы ---
@onready var customer_spawn_point: Node2D = $CustomerSpawnPoint
@onready var shawu_spawn_point: Node2D = $ShawuSpawnPoint
@onready var money_counter: Label = $MoneyPanel/MoneyCounter
@onready var time_label: Label = $TimePanel/TimeLabel

# --- Переменные ---
var current_customer: Customer
var current_shawu: Lavash
var money: int = 0
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

# --- Preload ---
const SCENE_CUSTOMER := preload("res://Scenes/Customer.tscn")
const SCENE_LAVASH := preload("res://Scenes/Lavash.tscn")

# ---------------- READY ----------------
func _ready() -> void:
	money = Globals.total_money
	money_counter.text = str(money) + "₽"
	_update_time_display()
	
	# Проверяем, закончился ли рабочий день
	if Globals.is_work_day_over():
		_end_work_day()
		return

	# Сцена всегда пустая - создаём клиента заново
	if not Globals.last_packed_lavash.is_empty():
		# Клиент уже сделал заказ и ждёт готовую шаурму
		_spawn_customer_stand_still()
		_spawn_packed_shawu()
	elif Globals.last_order.is_empty():
		# Новый клиент с дефолтным заказом
		_spawn_customer_with_order()
	else:
		# Восстанавливаем клиента с сохранённым заказом
		_spawn_customer_with_saved_order()

# ---------------- SPAWN ----------------
func _spawn_customer_with_order() -> void:
	_free_customer()
	current_customer = SCENE_CUSTOMER.instantiate()
	current_customer.state = Customer.State.ENTERING
	current_customer.set_order(_get_default_order())  
	# Устанавливаем случайного клиента (2-5, исключая бабку)
	current_customer.set_customer_index(Globals.get_random_customer_index())
	customer_spawn_point.add_child(current_customer)
	current_customer.order_confirmed.connect(_on_customer_order_confirmed)
	
func _spawn_customer_with_saved_order() -> void:
	_free_customer()
	current_customer = SCENE_CUSTOMER.instantiate()
	current_customer.state = Customer.State.ORDERING
	current_customer.set_order(Globals.last_order)
	# Устанавливаем случайного клиента (2-5)
	current_customer.set_customer_index(Globals.get_random_customer_index())
	customer_spawn_point.add_child(current_customer)
	current_customer.order_confirmed.connect(_on_customer_order_confirmed)

func _spawn_customer_stand_still() -> void:
	_free_customer()
	current_customer = SCENE_CUSTOMER.instantiate()
	current_customer.state = Customer.State.WAITING
	# Тот же клиент что был (используем last_customer_index)
	if Globals.last_customer_index == Globals.GRANDMA_INDEX:
		# Бабка - особый случай
		current_customer.set_customer_index(Globals.GRANDMA_INDEX)
	else:
		current_customer.set_customer_index(Globals.last_customer_index if Globals.last_customer_index >= 2 else Globals.get_random_customer_index())
	customer_spawn_point.add_child(current_customer)

func _get_default_order() -> Dictionary:
	return {"lavash": true, "meat": "chicken", "tomato": 1, "salad": 1}

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
	var sprite = current_shawu.get_node("Sprite2D") as Sprite2D
	if sprite:
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

# ---------------- INPUT ----------------
func _input(event: InputEvent) -> void:
	if not is_instance_valid(current_shawu):
		return
	
	if event is InputEventMouseButton:
		_handle_click(event)
	elif event is InputEventMouseMotion and is_dragging:
		current_shawu.global_position = get_global_mouse_position() + drag_offset

func _handle_click(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	var mouse_pos = get_global_mouse_position()
	var sprite = current_shawu.get_node("Sprite2D") as Sprite2D
	if not sprite:
		return

	if event.pressed:
		if sprite.get_rect().has_point(sprite.to_local(mouse_pos)):
			is_dragging = true
			drag_offset = current_shawu.global_position - mouse_pos
	elif is_dragging:
		is_dragging = false
		_try_deliver()

# ---------------- DELIVERY ----------------
func _try_deliver() -> void:
	if not _both_valid():
		return

	var character = _get_customer_character()
	if character and current_shawu.global_position.distance_to(character.global_position) < Consts.DELIVERY_DISTANCE:
		_deliver_shawu()

func _deliver_shawu() -> void:
	var sprite = current_shawu.get_node("Sprite2D") as Sprite2D
	if not sprite:
		return

	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, Consts.ANIM_FADE_DURATION)
	tween.tween_callback(_on_delivery_complete)

func _on_delivery_complete() -> void:
	_free_shawu()
	var reward := Consts.SHAWU_REWARD
	money += reward
	Globals.total_money = money
	money_counter.text = str(money) + "₽"
	Globals.last_packed_lavash = {}
	Globals.last_order = {}

	# Добавляем время и засчитываем клиента
	Globals.add_customer_time()
	Globals.customers_served += 1
	_update_time_display()
	
	# Проверяем, закончился ли рабочий день
	if Globals.is_work_day_over():
		_end_work_day()
		return

	if is_instance_valid(current_customer):
		_animate_customer_exit(current_customer)
		current_customer = null

	await get_tree().create_timer(Consts.EXIT_DELAY).timeout
	_spawn_customer_with_order()  # Спавним нового клиента с заказом

func _update_time_display() -> void:
	if time_label:
		time_label.text = Globals.get_formatted_time()

func _end_work_day() -> void:
	# Переход на экран завершения дня
	get_tree().change_scene_to_file("res://Scenes/EndDay.tscn")

# ---------------- ANIMATION ----------------
func _animate_customer_exit(customer: Customer) -> void:
	var character = customer.get_node("Character") as Sprite2D
	var bubble = customer.get_node("SpeechBubble") as NinePatchRect

	var tween = create_tween()
	tween.set_parallel(true)
	
	# Скрытие bubble
	tween.tween_property(bubble, "modulate:a", 0.0, Consts.ANIM_SCALE_DURATION)
	tween.tween_property(bubble, "scale", Vector2(0.8, 0.8), Consts.ANIM_SCALE_DURATION)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	# Уход character
	tween.chain().tween_property(character, "modulate:a", 0.0, Consts.ANIM_FADE_DURATION)
	tween.parallel().tween_property(character, "scale", Vector2(0.85, 0.85), Consts.ANIM_FADE_DURATION)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(character, "position:x", character.position.x + Consts.ANIM_EXIT_OFFSET, Consts.ANIM_EXIT_DURATION)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	tween.tween_callback(customer.queue_free)

# ---------------- CALLBACK ----------------
func _on_customer_order_confirmed(order: Dictionary) -> void:
	Globals.last_order = order
	# Сохраняем индекс клиента для возврата из Kitchen
	Globals.last_customer_index = current_customer.customer_index
	get_tree().change_scene_to_file("res://Scenes/Kitchen.tscn")

# ---------------- HELPERS ----------------
func _both_valid() -> bool:
	return is_instance_valid(current_customer) and is_instance_valid(current_shawu)

func _get_customer_character() -> Sprite2D:
	return current_customer.get_node("Character") as Sprite2D if current_customer else null

func _parse_money(text: String) -> int:
	var num_str = text.split(" ")[0]
	return num_str.to_int() if num_str.is_valid_int() else 0
