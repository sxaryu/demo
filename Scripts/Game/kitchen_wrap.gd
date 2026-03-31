extends Node2D
class_name KitchenWrap

# --- Константы ---
const SCENE_LAVASH := preload("res://Scenes/Game/Lavash.tscn")
const TEXTURE_SHAWU := preload("res://Textures/shawu.png")
const TEXTURE_WRAPPED := preload("res://Textures/wrapped_shawu.png")

const PACKAGE_WIDTH := 194.073
const PACKAGE_HEIGHT := 291.0

# --- Узлы ---
@onready var work_area: Node2D = $WorkArea
@onready var grill: Grill = $WorkArea/Grill
@onready var done_button: Button = $DoneButton

# --- Шаурма ---
var shawu: Lavash = null
var shawu_sprite: Sprite2D = null # Кэшируем спрайт для быстрого доступа
enum State { RAW, FRIED, PACKAGED }
var state: State = State.RAW

# --- Перетаскивание ---
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var is_animating: bool = false

# --- Ghost package ---
var ghost_package: Sprite2D = null
var is_packaging_mode: bool = false

# ---------------- READY ----------------
func _ready():
	done_button.disabled = true
	done_button.pressed.connect(_on_done_button_pressed)
	
	grill.shawu_fried.connect(_on_shawu_fried)
	spawn_shawu()

# ---------------- SPAWN ----------------
func spawn_shawu():
	shawu = SCENE_LAVASH.instantiate()
	work_area.add_child(shawu)
	
	# Центрируем
	shawu.position = work_area.get_viewport_rect().size / 2
	shawu.scale = Vector2.ONE
	
	# Настраиваем внешний вид (кэшируем ссылку на спрайт)
	shawu_sprite = shawu.get_node("Sprite2D")
	shawu_sprite.texture = TEXTURE_SHAWU
	
	# Скрываем ингредиенты внутри
	for ingredient in shawu.ingredients:
		ingredient.visible = false
		
	print("Свёрнутая шаурма создана. Положите на гриль!")

# ---------------- INPUT ----------------
func _input(event):
	if shawu == null and not is_packaging_mode:
		return

	var mouse_pos = get_global_mouse_position()
	
	if event is InputEventMouseMotion:
		_handle_mouse_motion(mouse_pos)
	elif event is InputEventMouseButton and event.pressed:
		_handle_mouse_click(event, mouse_pos)
	elif event is InputEventMouseButton and not event.pressed:
		_handle_mouse_release(event, mouse_pos)

func _handle_mouse_motion(mouse_pos: Vector2) -> void:
	# Движение перетаскивания
	if is_dragging and not is_animating and can_drag():
		shawu.global_position = mouse_pos + drag_offset
	
	# Движение призрака упаковки
	if is_packaging_mode and ghost_package:
		ghost_package.global_position = mouse_pos

func _handle_mouse_click(event: InputEventMouseButton, mouse_pos: Vector2) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		# СНАЧАЛА проверяем режим упаковки (приоритет!)
		if is_packaging_mode and shawu.contains_global_point(mouse_pos):
			package_shawu()
			cancel_package_preview()
		# Потом перетаскивание (только если НЕ в режиме упаковки)
		elif can_drag() and shawu.contains_global_point(mouse_pos):
			is_dragging = true
			drag_offset = shawu.global_position - mouse_pos
			
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		cancel_package_preview()

func _handle_mouse_release(event: InputEventMouseButton, mouse_pos: Vector2) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT and is_dragging:
		is_dragging = false
		if state == State.RAW and grill.get_grill_rect().has_point(mouse_pos):
			move_to_grill()

func can_drag() -> bool:
	return not is_animating and state != State.PACKAGED

# ---------------- PROCESS ----------------
func _process(_delta):
	if shawu:
		grill.check_hover(shawu)

# ---------------- FRY ----------------
func _on_shawu_fried(fried_shawu: Lavash):
	if state != State.RAW:
		return
		
	state = State.FRIED
	print("Шаурма готова к упаковке!")

	# Подключаем сигналы мыши для подсветки (безопасное подключение)
	if not fried_shawu.mouse_entered.is_connected(_on_fried_shawu_mouse_entered):
		fried_shawu.mouse_entered.connect(_on_fried_shawu_mouse_entered)
	if not fried_shawu.mouse_exited.is_connected(_on_fried_shawu_mouse_exited):
		fried_shawu.mouse_exited.connect(_on_fried_shawu_mouse_exited)

func _on_fried_shawu_mouse_entered():
	if state == State.FRIED and not is_dragging and shawu_sprite:
		shawu_sprite.modulate = Color(1.1, 1.1, 1.1)

func _on_fried_shawu_mouse_exited():
	if state == State.FRIED and not is_dragging and shawu_sprite:
		shawu_sprite.modulate = Color.WHITE

# ---------------- GRILL ----------------
func move_to_grill():
	is_dragging = false
	is_animating = true
	
	var target_pos = grill.get_grill_center()
	var tween = create_tween()
	
	tween.set_parallel(false) # Последовательное выполнение
	tween.tween_property(shawu, "global_position", target_pos, 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(shawu, "rotation_degrees", shawu.rotation_degrees + 90, 0.5)
	tween.tween_callback(_start_grill)
	tween.tween_callback(_animation_done)

func _start_grill():
	grill.start_grill(shawu, 5.0)
	print("Шаурма на гриле! Жарка началась (5 сек)...")

# ---------------- PACKAGE PREVIEW ----------------
func start_package_preview(texture: Texture2D):
	if not texture:
		push_error("start_package_preview: texture не назначен!")
		return

	cancel_package_preview()
	is_packaging_mode = true
	
	ghost_package = _create_ghost(texture, 1000)
	
	# Вычисляем масштаб, чтобы упаковка была нужного размера
	var scale_x = PACKAGE_WIDTH / texture.get_width()
	var scale_y = PACKAGE_HEIGHT / texture.get_height()
	ghost_package.scale = Vector2(scale_x, scale_y)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _create_ghost(texture: Texture2D, z_idx: int) -> Sprite2D:
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.modulate = Color(1, 1, 1, 0.7)
	sprite.z_index = z_idx
	sprite.centered = true
	sprite.global_position = get_global_mouse_position()
	add_child(sprite)
	return sprite

func _clear_ghost_package() -> void:
	if ghost_package:
		ghost_package.queue_free()
		ghost_package = null

func cancel_package_preview():
	_clear_ghost_package()
	is_packaging_mode = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# ---------------- PACKAGE ----------------
func package_shawu():
	if not shawu or state != State.FRIED:
		return

	is_packaging_mode = false
	state = State.PACKAGED

	var tween = create_tween()
	var jump_height = 20.0
	var start_pos = shawu.global_position
	var target_pos = ghost_package.global_position

	tween.tween_property(shawu, "global_position:y", start_pos.y - jump_height, 0.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(shawu, "global_position", target_pos, 0.3)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(_finish_packaging)

func _finish_packaging():
	if shawu_sprite:
		shawu_sprite.texture = TEXTURE_WRAPPED
	done_button.disabled = false
	print("Шаурма упакована!")
	_clear_ghost_package()
	
# ---------------- ANIMATION ----------------
func _animation_done():
	is_animating = false

# ---------------- DONE BUTTON ----------------
func _on_done_button_pressed():
	if done_button.disabled:
		return

	# Сохраняем данные шаурмы
	var packed_lavash_data = {
		"texture": shawu_sprite.texture if shawu_sprite else null,
		"ingredients": shawu.get_ingredients_data(),
		"sauce": shawu.get_sauce_data()
	}
	Globals.last_packed_lavash = packed_lavash_data
	get_tree().change_scene_to_file("res://Scenes/Hall.tscn")
