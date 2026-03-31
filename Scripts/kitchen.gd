extends Node2D
class_name Kitchen

# --- Константы ---
const SCENE_LAVASH := preload("res://Scenes/Lavash.tscn")
const SCENE_KITCHEN_WRAP := preload("res://Scenes/KitchenWrap.tscn")

# --- Таймер для сыпания ---
var pour_timer: Timer = null
const POUR_INTERVAL := 0.1  # Сыпать каждые 0.1 секунды

# --- Текущий ингредиент ---
var current_ingredient_scene: PackedScene = null
var current_ingredient_texture: Texture2D = null
var ghost_ingredient: Sprite2D = null

# --- Текущий лаваш ---
var current_lavash: Lavash = null

# --- Рабочая область ---
@onready var work_area: Node2D = $WorkArea

# --- Соус ---
var is_sauce_mode := false
var current_sauce_brush: Texture2D
var ghost_sauce: Sprite2D = null

@onready var done_button: Button = $DoneButton
@onready var lavash_button: TextureButton = $LavashButton

# --- UI панель веса ---
@onready var weight_ui: IngredientsWeightUI = $IngredientsWeightUI


func _ready():
	done_button.pressed.connect(_on_done_pressed)
	lavash_button.pressed.connect(_on_lavash_button_pressed)
	
	# Таймер для сыпания
	pour_timer = Timer.new()
	pour_timer.wait_time = POUR_INTERVAL
	pour_timer.autostart = false
	pour_timer.timeout.connect(_on_pour_timer)
	add_child(pour_timer)

# -------- HELPER FUNCTIONS --------

func _create_ghost(texture: Texture2D, z_idx: int) -> Sprite2D:
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.modulate = Color(1, 1, 1, 0.7)
	sprite.z_index = z_idx
	sprite.centered = true
	sprite.global_position = get_global_mouse_position()
	add_child(sprite)
	return sprite

func _clear_ghost(sprite_ref: Sprite2D) -> void:
	if sprite_ref:
		sprite_ref.queue_free()

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

# -------- INGREDIENT FLOW --------

func start_ingredient_preview(scene: PackedScene, texture: Texture2D):
	if is_sauce_mode:
		disable_sauce_mode()
	
	_cleanup_state()
	
	current_ingredient_scene = scene
	current_ingredient_texture = texture
	ghost_ingredient = _create_ghost(texture, 1000)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func cancel_ingredient_preview():
	_clear_ghost(ghost_ingredient)
	ghost_ingredient = null
	current_ingredient_scene = null
	current_ingredient_texture = null
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_stop_pouring()

func is_holding_ingredient() -> bool:
	return ghost_ingredient != null

func _try_place_ingredient():
	if not is_holding_ingredient() or not current_lavash:
		return
	
	var mouse_pos = get_global_mouse_position()
	if current_lavash.contains_global_point(mouse_pos):
		# Уменьшил с 50 до 15 грамм за клик
		current_lavash.add_ingredient_portion(current_ingredient_texture, mouse_pos, 15)

# -------- ПОУРИНГ (Сыпание) --------

func _start_pouring() -> void:
	if not pour_timer:
		return
	if not pour_timer.is_stopped():
		return
	pour_timer.start()

func _stop_pouring() -> void:
	if pour_timer:
		pour_timer.stop()

func _on_pour_timer() -> void:
	if not is_holding_ingredient() or not current_lavash:
		_stop_pouring()
		return
	
	var mouse_pos = get_global_mouse_position()
	if current_lavash.contains_global_point(mouse_pos):
		# Сыпем порцию (5 грамм)
		current_lavash.add_ingredient_portion(current_ingredient_texture, mouse_pos, 5)

# -------- LAVASH --------

func _on_lavash_button_pressed():
	if current_lavash:
		print("Лаваш уже есть!")
		return
	
	current_lavash = SCENE_LAVASH.instantiate()
	work_area.add_child(current_lavash)
	current_lavash.position = work_area.get_viewport_rect().size / 2
	
	# Подключаем сигнал обновления веса
	current_lavash.ingredient_added.connect(_on_ingredient_added)
	
	# Очищаем UI при новом лаваше
	if weight_ui:
		weight_ui.clear_all()

# Новый метод для обновления UI
func _on_ingredient_added(type: String, current: int, max_grams: int) -> void:
	if weight_ui:
		weight_ui.update_weight(type, current, max_grams)

func _on_done_pressed():
	if not current_lavash:
		print("Сначала создай лаваш")
		return

	Globals.last_lavash_ingredients = current_lavash.get_ingredients_data()
	Globals.last_lavash_sauce = current_lavash.get_sauce_data()
	
	# Также сохраняем вес ингредиентов
	Globals.last_lavash_weights = current_lavash.get_all_weights()
	
	print("Сохранено ингредиентов: ", Globals.last_lavash_ingredients.size())
	print("Вес ингредиентов: ", Globals.last_lavash_weights)

	_cleanup_state()

	get_tree().change_scene_to_packed(SCENE_KITCHEN_WRAP)
	current_lavash = null

# -------- SAUCE MODE --------

func enable_sauce_mode(brush: Texture2D):
	_cleanup_state()
	
	is_sauce_mode = true
	current_sauce_brush = brush
	ghost_sauce = _create_ghost(brush, 2000)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func disable_sauce_mode():
	_clear_ghost(ghost_sauce)
	ghost_sauce = null
	is_sauce_mode = false
	current_sauce_brush = null
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# -------- INPUT --------

func _input(event):
	# Обработка движения мыши
	if event is InputEventMouseMotion:
		var mouse_pos = get_global_mouse_position()
		if ghost_ingredient:
			ghost_ingredient.global_position = mouse_pos
		if ghost_sauce:
			ghost_sauce.global_position = mouse_pos
		
		# Логика соуса (как было)
		if is_sauce_mode and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and current_lavash:
			if current_lavash.contains_global_point(event.position):
				current_lavash.paint_sauce(event.position, current_sauce_brush)
		
		# НОВОЕ: Логика сыпания ингредиентов при зажатии
		if is_holding_ingredient() and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if current_lavash and current_lavash.contains_global_point(mouse_pos):
				_start_pouring()
			else:
				_stop_pouring()
		else:
			_stop_pouring()
		return

	# Обработка кликов
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_try_place_ingredient()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_cleanup_state()
	
	# Обработка отпускания кнопки
	if event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_stop_pouring()
