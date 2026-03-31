extends Node2D
class_name TutorialHall

# --- Константы ---
const SCENE_TUTORIAL_CUSTOMER := preload("res://Scenes/Tutorial/TutorialCustomer.tscn")
const SCENE_LAVASH := preload("res://Scenes/Game/Lavash.tscn")

# --- Внешние ресурсы ---
@export var customer_scene: PackedScene
@export var lavash_scene: PackedScene

const DELIVERY_DISTANCE := 130.0

# --- Узлы ---
@onready var customer_spawn_point: Node2D = $CustomerSpawnPoint
@onready var shawu_spawn_point: Node2D = $ShawuSpawnPoint
@onready var money_counter: Label = $MoneyPanel/MoneyCounter

# --- Переменные ---
var current_customer: TutorialCustomer
var current_shawu: Lavash
var money: int = 0
var is_tutorial_mode: bool = true

func _ready() -> void:
	# Просто спавним клиента - он сам управляет диалогами
	spawn_tutorial_customer()

# ---------------- SPAWN ----------------
func spawn_tutorial_customer() -> void:
	_free_customer()
	current_customer = SCENE_TUTORIAL_CUSTOMER.instantiate()
	customer_spawn_point.add_child(current_customer)
	current_customer.order_confirmed.connect(_on_customer_order_confirmed)
	
# ---------------- CALLBACK ----------------
func _on_customer_order_confirmed(order: Dictionary) -> void:
	Globals.last_order = order
	Globals.is_tutorial_mode = true
	# Переходим в кухню
	get_tree().change_scene_to_file("res://Scenes/Kitchen.tscn")

# ---------------- DELIVERY ----------------
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
	
	# Даём награду
	money += 1000
	money_counter.text = str(money) + " деняк"
	
	# Показываем благодарность
	if is_instance_valid(current_customer):
		current_customer.show_thanks()
		
# ---------------- HELPERS ----------------
func _free_customer() -> void:
	if is_instance_valid(current_customer):
		current_customer.queue_free()
		current_customer = null
