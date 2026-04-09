extends Node2D
class_name Kitchen

# --- Preload ---
const SCENE_LAVASH := preload("res://Scenes/Lavash.tscn")
const SCENE_KITCHEN_WRAP := preload("res://Scenes/KitchenWrap.tscn")

# --- Таймер для сыпания ---
var pour_timer: Timer

# --- Текущий ингредиент ---
var current_ingredient_scene: PackedScene
var current_ingredient_texture: Texture2D
var ghost_ingredient: Sprite2D

# --- Текущий лаваш ---
var current_lavash: Lavash

# --- Рабочая область ---
@onready var work_area: Node2D = $WorkArea

# --- Соус ---
var is_sauce_mode := false
var current_sauce_brush: Texture2D
var ghost_sauce: Sprite2D

# --- UI ---
@onready var done_button: Button = $DoneButton
@onready var lavash_button: TextureButton = $LavashButton
@onready var weight_ui: IngredientsWeightUI = $IngredientsWeightUI

# ---------------- READY ----------------
func _ready() -> void:
	add_to_group("kitchen")
	done_button.pressed.connect(_on_done_pressed)
	lavash_button.pressed.connect(_on_lavash_button_pressed)
	_init_pour_timer()

func _init_pour_timer() -> void:
	pour_timer = Timer.new()
	pour_timer.wait_time = Consts.POUR_INTERVAL
	pour_timer.autostart = false
	pour_timer.timeout.connect(_on_pour_timer)
	add_child(pour_timer)

# ---------------- HELPER FUNCTIONS ----------------
func _create_ghost(texture: Texture2D, z_idx: int) -> Sprite2D:
	return GhostFactory.create_ghost(texture, self, z_idx)

func _clear_ghost(sprite_ref: Sprite2D) -> void:
	GhostFactory.free_ghost(sprite_ref)

func _cleanup_state() -> void:
	_clear_ghost(ghost_ingredient)
	ghost_ingredient = null
	current_ingredient_scene = null
	current_ingredient_texture = null
	
	_clear_ghost(ghost_sauce)
	ghost_sauce = null
	is_sauce_mode = false
	current_sauce_brush = null
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_stop_pouring()

# ---------------- INGREDIENT FLOW ----------------
func start_ingredient_preview(scene: PackedScene, texture: Texture2D) -> void:
	if is_sauce_mode:
		disable_sauce_mode()
	
	_cleanup_state()
	
	current_ingredient_scene = scene
	current_ingredient_texture = texture
	ghost_ingredient = _create_ghost(texture, Consts.GHOST_Z_INDEX)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func cancel_ingredient_preview() -> void:
	_clear_ghost(ghost_ingredient)
	ghost_ingredient = null
	current_ingredient_scene = null
	current_ingredient_texture = null
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_stop_pouring()

func is_holding_ingredient() -> bool:
	return ghost_ingredient != null

func _try_place_ingredient() -> void:
	if not is_holding_ingredient() or not current_lavash:
		return
	
	var mouse_pos := get_global_mouse_position()
	if current_lavash.contains_global_point(mouse_pos):
		current_lavash.add_ingredient_portion(current_ingredient_texture, mouse_pos, Consts.CLICK_GRAMS)

# ---------------- POURING ----------------
func _start_pouring() -> void:
	if pour_timer and pour_timer.is_stopped():
		pour_timer.start()

func _stop_pouring() -> void:
	if pour_timer:
		pour_timer.stop()

func _on_pour_timer() -> void:
	if not is_holding_ingredient() or not current_lavash:
		_stop_pouring()
		return
	
	var mouse_pos := get_global_mouse_position()
	if current_lavash.contains_global_point(mouse_pos):
		current_lavash.add_ingredient_portion(current_ingredient_texture, mouse_pos, Consts.POUR_GRAMS)

# ---------------- LAVASH ----------------
func _on_lavash_button_pressed() -> void:
	if current_lavash:
		print("Лаваш уже есть!")
		return
	
	current_lavash = SCENE_LAVASH.instantiate()
	work_area.add_child(current_lavash)
	current_lavash.position = work_area.get_viewport_rect().size / 2
	current_lavash.ingredient_added.connect(_on_ingredient_added)
	
	if weight_ui:
		weight_ui.clear_all()

func _on_ingredient_added(type: String, current: int, max_grams: int) -> void:
	if weight_ui:
		weight_ui.update_weight(type, current, max_grams)

func _on_done_pressed() -> void:
	if not current_lavash:
		print("Сначала создай лаваш")
		return

	Globals.last_lavash_ingredients = current_lavash.get_ingredients_data()
	Globals.last_lavash_sauce = current_lavash.get_sauce_data()
	Globals.last_lavash_weights = current_lavash.get_all_weights()
	
	print("Сохранено ингредиентов: ", Globals.last_lavash_ingredients.size())
	print("Вес ингредиентов: ", Globals.last_lavash_weights)

	_cleanup_state()
	get_tree().change_scene_to_packed(SCENE_KITCHEN_WRAP)
	current_lavash = null

# ---------------- SAUCE MODE ----------------
func enable_sauce_mode(_sauce_id: String, brush: Texture2D) -> void:
	_cleanup_state()
	
	is_sauce_mode = true
	current_sauce_brush = brush
	ghost_sauce = _create_ghost(brush, Consts.GHOST_Z_INDEX + 1000)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func disable_sauce_mode() -> void:
	_clear_ghost(ghost_sauce)
	ghost_sauce = null
	is_sauce_mode = false
	current_sauce_brush = null
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# ---------------- INPUT ----------------
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_handle_motion(event)
	elif event is InputEventMouseButton:
		if event.pressed:
			_handle_click_pressed(event)
		else:
			_handle_click_released(event)

func _handle_motion(event: InputEventMouseMotion) -> void:
	var mouse_pos := get_global_mouse_position()
	
	if ghost_ingredient:
		ghost_ingredient.global_position = mouse_pos
	
	if ghost_sauce:
		ghost_sauce.global_position = mouse_pos
	
	# Соус при зажатии
	if is_sauce_mode and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and current_lavash:
		if current_lavash.contains_global_point(event.position):
			current_lavash.paint_sauce(event.position, current_sauce_brush)
	
	# Сыпание при зажатии
	if is_holding_ingredient() and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if current_lavash and current_lavash.contains_global_point(mouse_pos):
			_start_pouring()
		else:
			_stop_pouring()
	else:
		_stop_pouring()

func _handle_click_pressed(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		_try_place_ingredient()
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		_cleanup_state()

func _handle_click_released(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		_stop_pouring()
