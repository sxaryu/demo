extends Node2D
class_name Grill

# --- Константы ---
const TEXTURE_FRIED := preload("res://Textures/Kitchen/fried_shawu.png")

# --- Узлы ---
@onready var grill_opened: Sprite2D = $grill_opened
@onready var grill_closed: Sprite2D = $grill_closed
@onready var grill_timer: Timer = $Timer

signal shawu_fried(lavash: Lavash)

var is_hovered := false
var current_lavash: Lavash = null
var is_busy := false 

func _ready():
	grill_timer.one_shot = true
	grill_timer.timeout.connect(_on_grill_timer_timeout)
	_open_cover()

func start_grill(lavash: Lavash, duration: float) -> void:
	if current_lavash:
		return

	current_lavash = lavash
	_close_cover()
	current_lavash.visible = false

	grill_timer.wait_time = duration
	grill_timer.start()

func _on_grill_timer_timeout() -> void:
	if current_lavash:
		var sprite = current_lavash.get_node("Sprite2D")
		sprite.texture = TEXTURE_FRIED
		current_lavash.visible = true

		shawu_fried.emit(current_lavash)
		current_lavash = null
	
	_open_cover()

# ---------- КРЫШКА ----------
func _close_cover() -> void:
	is_busy = true
	grill_opened.visible = false
	grill_closed.visible = true

func _open_cover() -> void:
	is_busy = false
	grill_opened.visible = true
	grill_closed.visible = false

# ---------- ЛОГИКА ГРИЛЯ ----------
func get_grill_rect() -> Rect2:
	var size = grill_opened.texture.get_size() * grill_opened.scale
	return Rect2(grill_opened.global_position - size / 2, size)

func get_grill_center() -> Vector2:
	return grill_opened.global_position + Vector2(0, 100)

func check_hover(lavash: Lavash) -> bool:
	var hovering = get_grill_rect().has_point(lavash.global_position)
	if hovering != is_hovered:
		is_hovered = hovering
		grill_opened.modulate = Color(1.2, 1.2, 1.2) if is_hovered else Color.WHITE
	return is_hovered

func can_interact() -> bool:
	return not is_busy
