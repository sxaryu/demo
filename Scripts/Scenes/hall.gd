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
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

# --- Preload ---
const SCENE_CUSTOMER := preload("res://Scenes/Customer.tscn")
const SCENE_LAVASH := preload("res://Scenes/Lavash.tscn")

# --- Константы ---
const BASE_REWARD := 250.0  # Базовая награда

# ---------------- READY ----------------
func _ready() -> void:
	EventBus.money_changed.connect(_on_money_changed)
	_update_money_display()
	_update_time_display()
	
	if Globals.is_work_day_over():
		_end_work_day()
		return

	if not Globals.last_packed_lavash.is_empty():
		_spawn_customer_stand_still()
		_spawn_packed_shawu()
	elif Globals.last_order.is_empty():
		_spawn_customer_with_order()
	else:
		_spawn_customer_with_saved_order()

func _on_money_changed(new_amount: float) -> void:
	_update_money_display()

func _update_money_display() -> void:
	if money_counter:
		money_counter.text = str(snappedf(Globals.total_money, 0.01)) + "₽"

# ---------------- SPAWN ----------------
func _spawn_customer_with_order() -> void:
	_free_customer()
	current_customer = SCENE_CUSTOMER.instantiate()
	current_customer.set_order(_get_default_order())  
	# Устанавливаем случайного клиента (из NPC_IDS)
	current_customer.set_customer_id(Globals.get_random_customer_id())
	customer_spawn_point.add_child(current_customer)
	current_customer.order_confirmed.connect(_on_customer_order_confirmed)
	# Явно устанавливаем ENTERING - начнётся анимация появления
	current_customer.set_state(Customer.State.ENTERING)
	
func _spawn_customer_with_saved_order() -> void:
	_free_customer()
	current_customer = SCENE_CUSTOMER.instantiate()
	current_customer.set_order(Globals.last_order)
	# Используем сохранённого клиента
	current_customer.set_customer_id(Globals.last_customer_id if Globals.last_customer_id != "" else Globals.get_random_customer_id())
	customer_spawn_point.add_child(current_customer)
	current_customer.order_confirmed.connect(_on_customer_order_confirmed)
	# Явно устанавливаем ORDERING - покажем заказ
	current_customer.set_state(Customer.State.ORDERING)

func _spawn_customer_stand_still() -> void:
	_free_customer()
	current_customer = SCENE_CUSTOMER.instantiate()
	# Тот же клиент что был
	if Globals.last_customer_id == Globals.GRANDMA_ID:
		current_customer.set_customer_id(Globals.GRANDMA_ID)
	else:
		current_customer.set_customer_id(Globals.last_customer_id if Globals.last_customer_id != "" else Globals.get_random_customer_id())
	customer_spawn_point.add_child(current_customer)
	# Явно устанавливаем WAITING - клиент молча ждёт
	current_customer.set_state(Customer.State.WAITING)

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
	# Простая выплата без детальной проверки
	var reward = BASE_REWARD
	
	_free_shawu()
	Globals.add_money(reward)
	_update_money_display()
	
	Globals.last_packed_lavash = {}
	Globals.last_order = {}

	Globals.add_customer_time()
	Globals.customers_served += 1
	_update_time_display()
	
	if Globals.is_work_day_over():
		_end_work_day()
		return
	
	if is_instance_valid(current_customer):
		_animate_customer_exit(current_customer)
		current_customer = null

	await get_tree().create_timer(Consts.EXIT_DELAY).timeout
	_spawn_customer_with_order()

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
	# Сохраняем ID клиента для возврата из Kitchen
	Globals.last_customer_id = current_customer.customer_id
	get_tree().change_scene_to_file("res://Scenes/Kitchen.tscn")

# ---------------- HELPERS ----------------
func _both_valid() -> bool:
	return is_instance_valid(current_customer) and is_instance_valid(current_shawu)

func _get_customer_character() -> Sprite2D:
	return current_customer.get_node("Character") as Sprite2D if current_customer else null

func _parse_money(text: String) -> int:
	var num_str = text.split(" ")[0]
	return num_str.to_int() if num_str.is_valid_int() else 0

func _exit_tree() -> void:
	if EventBus.money_changed.is_connected(_on_money_changed):
		EventBus.money_changed.disconnect(_on_money_changed)
