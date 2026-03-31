extends Node2D

# --- Константы ---
const SCENE_THANKS := preload("res://Scenes/thanks.tscn")
const SCENE_CUSTOMER := preload("res://Scenes/Customer.tscn")
const SCENE_LAVASH := preload("res://Scenes/Lavash.tscn")

const DELIVERY_DISTANCE := 130.0
const SHAWU_REWARD := 100
const ANIM_DURATION := 0.3

# --- Узлы ---
@onready var customer_spawn_point: Node2D = $CustomerSpawnPoint
@onready var shawu_spawn_point: Node2D = $ShawuSpawnPoint
@onready var money_counter: Label = $MoneyPanel/MoneyCounter

# --- Переменные ---
var current_customer: Customer
var current_shawu: Lavash
var money: int = 0
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	money = _parse_money(money_counter.text)
	
	if Globals.last_packed_lavash.is_empty():
		spawn_customer_with_order()
	else:
		spawn_customer_stand_still()
		spawn_packed_shawu()

# ---------------- SPAWN ----------------
func spawn_customer_stand_still() -> void:
	_free_customer()
	current_customer = SCENE_CUSTOMER.instantiate()
	current_customer.stand_still = true
	customer_spawn_point.add_child(current_customer)
	current_customer.set_stand_still()

func spawn_customer_with_order() -> void:
	_free_customer()
	current_customer = SCENE_CUSTOMER.instantiate()
	customer_spawn_point.add_child(current_customer)
	current_customer.set_order({"lavash": true, "meat": "chicken", "tomato": 1, "salad": 1})
	current_customer.order_confirmed.connect(_on_customer_order_confirmed)

func spawn_packed_shawu() -> void:
	var data = Globals.last_packed_lavash
	if data.is_empty():
		push_warning("Hall: данные шаурмы пустые!")
		return

	current_shawu = SCENE_LAVASH.instantiate()
	add_child(current_shawu)
	current_shawu.global_position = shawu_spawn_point.global_position
	current_shawu.visible = true

	if current_shawu.has_method("set_ingredients_data"):
		current_shawu.set_ingredients_data(data.ingredients)
	if current_shawu.has_method("set_sauce_data"):
		current_shawu.set_sauce_data(data.sauce)

	var sprite = current_shawu.get_node("Sprite2D")
	sprite.texture = data.texture
	sprite.z_index = 100
	sprite.visible = true

func _free_customer() -> void:
	if is_instance_valid(current_customer):
		current_customer.queue_free()
		current_customer = null

# ---------------- INPUT / DRAG ----------------
func _input(event: InputEvent) -> void:
	if not is_instance_valid(current_shawu):
		return

	var mouse_pos := get_global_mouse_position()
	var sprite: Sprite2D = current_shawu.get_node("Sprite2D")

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and sprite.get_rect().has_point(sprite.to_local(mouse_pos)):
				is_dragging = true
				drag_offset = current_shawu.global_position - mouse_pos
			elif not event.pressed and is_dragging:
				is_dragging = false
				_check_delivery()

	elif event is InputEventMouseMotion and is_dragging:
		current_shawu.global_position = mouse_pos + drag_offset

# ---------------- DELIVERY ----------------
func _check_delivery() -> void:
	if not _both_valid():
		return

	var character_sprite: Sprite2D = current_customer.get_node("Character")
	if current_shawu.global_position.distance_to(character_sprite.global_position) < DELIVERY_DISTANCE:
		deliver_shawu()

func deliver_shawu() -> void:
	if not is_instance_valid(current_shawu):
		return

	var sprite: Sprite2D = current_shawu.get_node("Sprite2D")
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.25)
	tween.tween_callback(_on_delivery_complete)

func _on_delivery_complete() -> void:
	if is_instance_valid(current_shawu):
		current_shawu.queue_free()
		current_shawu = null

	Globals.last_packed_lavash = {}
	money += SHAWU_REWARD
	money_counter.text = str(money) + " деняк"

	if is_instance_valid(current_customer):
		_animate_customer_exit(current_customer)
		current_customer = null

	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_packed(SCENE_THANKS)

# ---------------- ANIMATION (симметрично появлению) ----------------
func _animate_customer_exit(customer: Customer) -> void:
	var character: Sprite2D = customer.get_node("Character")
	var bubble: NinePatchRect = customer.get_node("SpeechBubble")

	# Сначала скрываем bubble (как при появлении, только наоборот)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(bubble, "modulate:a", 0.0, 0.2)
	tween.tween_property(bubble, "scale", Vector2(0.8, 0.8), 0.2)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	# Затем character уходит и затухает
	tween.chain().tween_property(character, "modulate:a", 0.0, 0.25)
	tween.parallel().tween_property(character, "scale", Vector2(0.85, 0.85), 0.25)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(character, "position:x", character.position.x + 200, 0.3)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	tween.tween_callback(customer.queue_free)

# ---------------- CALLBACK ----------------
func _on_customer_order_confirmed(order: Dictionary) -> void:
	Globals.last_order = order
	get_tree().change_scene_to_file("res://Scenes/Kitchen.tscn")

# ---------------- HELPERS ----------------
func _both_valid() -> bool:
	return is_instance_valid(current_customer) and is_instance_valid(current_shawu)

func _parse_money(text: String) -> int:
	var num_str = text.split(" ")[0]
	return num_str.to_int() if num_str.is_valid_int() else 0
