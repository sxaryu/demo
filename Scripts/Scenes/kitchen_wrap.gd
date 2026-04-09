extends Node2D
class_name KitchenWrap

# --- Preload ---
const SCENE_LAVASH := preload("res://Scenes/Lavash.tscn")
const TEXTURE_SHAWU := preload("res://Textures/Kitchen/shawu.png")
const TEXTURE_WRAPPED := preload("res://Textures/Kitchen/wrapped_shawu.png")

# --- Узлы ---
@onready var work_area: Node2D = $WorkArea
@onready var grill: Grill = $WorkArea/Grill
@onready var done_button: Button = $DoneButton

# --- Шаурма ---
var shawu: Lavash
var shawu_sprite: Sprite2D

enum State { RAW, FRIED, PACKAGED }
var state: State = State.RAW

# --- Перетаскивание ---
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var is_animating: bool = false

# --- Ghost package ---
var ghost_package: Sprite2D
var is_packaging_mode: bool = false

# ---------------- READY ----------------
func _ready() -> void:
	done_button.disabled = true
	done_button.pressed.connect(_on_done_button_pressed)
	grill.shawu_fried.connect(_on_shawu_fried)
	_spawn_shawu()

# ---------------- SPAWN ----------------
func _spawn_shawu() -> void:
	shawu = SCENE_LAVASH.instantiate()
	work_area.add_child(shawu)
	
	shawu.position = work_area.get_viewport_rect().size / 2
	shawu.scale = Consts.LAVASH_SCALE
	
	shawu_sprite = shawu.get_node("Sprite2D")
	shawu_sprite.texture = TEXTURE_SHAWU
	
	# Скрываем ингредиенты внутри
	for ingredient in shawu.ingredients:
		ingredient.visible = false

# ---------------- INPUT ----------------
func _input(event: InputEvent) -> void:
	if not shawu and not is_packaging_mode:
		return

	var mouse_pos := get_global_mouse_position()
	
	if event is InputEventMouseMotion:
		_handle_motion(mouse_pos)
	elif event is InputEventMouseButton:
		if event.pressed:
			_handle_click(event, mouse_pos)
		else:
			_handle_release(event, mouse_pos)

func _handle_motion(mouse_pos: Vector2) -> void:
	if is_dragging and not is_animating and can_drag():
		shawu.global_position = mouse_pos + drag_offset
	
	if is_packaging_mode and ghost_package:
		ghost_package.global_position = mouse_pos

func _handle_click(event: InputEventMouseButton, mouse_pos: Vector2) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if is_packaging_mode and _contains_point(mouse_pos):
			if package_shawu():
				cancel_package_preview()
		elif can_drag() and _contains_point(mouse_pos):
			is_dragging = true
			drag_offset = shawu.global_position - mouse_pos
			
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		cancel_package_preview()

func _handle_release(event: InputEventMouseButton, mouse_pos: Vector2) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT and is_dragging:
		is_dragging = false
		if state == State.RAW and grill.get_grill_rect().has_point(mouse_pos):
			_move_to_grill()

func _contains_point(mouse_pos: Vector2) -> bool:
	return shawu and shawu.contains_global_point(mouse_pos)

func can_drag() -> bool:
	return not is_animating and state != State.PACKAGED

# ---------------- PROCESS ----------------
func _process(_delta: float) -> void:
	if shawu:
		grill.check_hover(shawu)

# ---------------- FRY ----------------
func _on_shawu_fried(fried_lavash: Lavash) -> void:
	if state != State.RAW:
		return
	
	state = State.FRIED
	print("Шаурма готова к упаковке!")
	_connect_mouse_signals(fried_lavash)

func _connect_mouse_signals(lavash: Lavash) -> void:
	if not lavash.mouse_entered.is_connected(_on_mouse_entered):
		lavash.mouse_entered.connect(_on_mouse_entered)
	if not lavash.mouse_exited.is_connected(_on_mouse_exited):
		lavash.mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	if state == State.FRIED and not is_dragging and shawu_sprite:
		shawu_sprite.modulate = Color(1.1, 1.1, 1.1)

func _on_mouse_exited() -> void:
	if state == State.FRIED and not is_dragging and shawu_sprite:
		shawu_sprite.modulate = Color.WHITE

# ---------------- GRILL ----------------
func _move_to_grill() -> void:
	is_dragging = false
	is_animating = true
	
	var tween := create_tween()
	tween.set_parallel(false)
	tween.tween_property(shawu, "global_position", grill.get_grill_center(), Consts.GRILL_MOVE_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(shawu, "rotation_degrees", shawu.rotation_degrees + 90, Consts.GRILL_MOVE_DURATION)
	tween.tween_callback(_start_grill)
	tween.tween_callback(_on_animation_done)

func _start_grill() -> void:
	grill.start_grill(shawu, 5.0)  # 5 секунд жарки
	print("Шаурма на гриле! Жарка началась...")

# ---------------- PACKAGE PREVIEW ----------------
func start_package_preview(texture: Texture2D) -> void:
	if not texture:
		push_error("start_package_preview: texture не назначен!")
		return

	cancel_package_preview()
	is_packaging_mode = true
	
	ghost_package = _create_ghost(texture)
	_scale_package(ghost_package, texture)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _create_ghost(texture: Texture2D) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.modulate = Consts.GHOST_MODULATE
	sprite.z_index = Consts.GHOST_Z_INDEX
	sprite.centered = true
	sprite.global_position = get_global_mouse_position()
	add_child(sprite)
	return sprite

func _scale_package(sprite: Sprite2D, texture: Texture2D) -> void:
	var w := float(Consts.PACKAGE_WIDTH)
	var h := float(Consts.PACKAGE_HEIGHT)
	var tw := float(texture.get_width())
	var th := float(texture.get_height())
	sprite.scale = Vector2(w / tw, h / th)

func cancel_package_preview() -> void:
	_free_ghost()
	is_packaging_mode = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _free_ghost() -> void:
	if is_instance_valid(ghost_package):
		ghost_package.queue_free()
		ghost_package = null

# ---------------- PACKAGE ----------------
func package_shawu() -> bool:
	if not shawu or is_animating or state != State.FRIED:
		if is_animating:
			print("Нельзя упаковывать - шаурма на гриле!")
		elif state != State.FRIED:
			print("Шаурма ещё не готова к упаковке!")
		return false

	state = State.PACKAGED
	
	var tween := create_tween()
	var jump := 20.0  # Высота прыжка
	var target := ghost_package.global_position
	
	tween.tween_property(shawu, "global_position:y", shawu.global_position.y - jump, 0.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(shawu, "global_position", target, 0.3)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(_finish_packaging)
	
	return true

func _finish_packaging() -> void:
	if shawu_sprite:
		shawu_sprite.texture = TEXTURE_WRAPPED
	done_button.disabled = false
	print("Шаурма упакована!")
	_free_ghost()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# ---------------- DONE ----------------
func _on_done_button_pressed() -> void:
	if done_button.disabled:
		return

	var data := {
		"texture": shawu_sprite.texture if shawu_sprite else null,
		"ingredients": shawu.get_ingredients_data(),
		"sauce": shawu.get_sauce_data()
	}
	Globals.last_packed_lavash = data
	get_tree().change_scene_to_file("res://Scenes/Hall.tscn")

# ---------------- ANIMATION ----------------
func _on_animation_done() -> void:
	is_animating = false
