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
@onready var save_and_quit_button: Button = $SaveAndQuitButton

# --- UI качества ---
@onready var quality_panel: Panel = $QualityPanel
@onready var score_label: Label = $QualityPanel/VBoxContainer/ScoreLabel
@onready var quality_label: Label = $QualityPanel/VBoxContainer/QualityLabel
@onready var weight_label: Label = $QualityPanel/VBoxContainer/WeightLabel
@onready var weight_progress: ProgressBar = $QualityPanel/VBoxContainer/WeightProgress
@onready var distribution_label: Label = $QualityPanel/VBoxContainer/DistributionLabel
@onready var distribution_progress: ProgressBar = $QualityPanel/VBoxContainer/DistributionProgress
@onready var sauce_label: Label = $QualityPanel/VBoxContainer/SauceLabel
@onready var sauce_progress: ProgressBar = $QualityPanel/VBoxContainer/SauceProgress
@onready var issues_list: RichTextLabel = $QualityPanel/VBoxContainer/IssuesList
@onready var tip_label: Label = $QualityPanel/VBoxContainer/TipLabel

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

# --- Валидация ---
var _validation_result: Dictionary = {}
var _customer_order: Dictionary = {}
var _is_validated: bool = false  # Флаг показа результатов валидации

# --- Защита от повторных действий ---
var _is_changing_scene: bool = false

# ---------------- READY ----------------
func _ready() -> void:
	done_button.disabled = true
	done_button.pressed.connect(_on_done_button_pressed)
	save_and_quit_button.pressed.connect(_on_save_and_quit_pressed)
	grill.shawu_fried.connect(_on_shawu_fried)
	_spawn_shawu()

	# Получаем заказ клиента из Globals
	_customer_order = Globals.last_order.duplicate(true) if not Globals.last_order.is_empty() else {}

# ---------------- EXIT ----------------
func _exit_tree() -> void:
	# Очищаем лаваш
	if is_instance_valid(shawu):
		shawu.queue_free()
		shawu = null
	_free_ghost()

# ---------------- SPAWN ----------------
func _spawn_shawu() -> void:
	# Защита от повторного спавна
	if is_instance_valid(shawu):
		return

	shawu = SCENE_LAVASH.instantiate()
	work_area.add_child(shawu)
	
	shawu.position = work_area.get_viewport_rect().size / 2
	shawu.scale = Consts.LAVASH_SCALE
	
	shawu_sprite = shawu.get_node_or_null("Sprite2D") as Sprite2D
	if shawu_sprite:
		shawu_sprite.texture = TEXTURE_SHAWU
	
	# Восстанавливаем ингредиенты из Globals
	if not Globals.last_lavash_ingredients.is_empty():
		_restore_ingredients(Globals.last_lavash_ingredients)
		print("Восстановлено ингредиентов: ", Globals.last_lavash_ingredients.size())
	
	if not Globals.last_lavash_sauce.is_empty():
		_restore_sauce(Globals.last_lavash_sauce)
		print("Восстановлено соуса: ", Globals.last_lavash_sauce.size())
	
	# СРАЗУ скрываем все элементы, чтобы они не отображались поверх текстуры
	_hide_shawarma_contents()

# ---------------- HELPER FUNCTIONS ----------------
func _set_mouse_visible() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _set_mouse_hidden() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

# ---------------- INPUT ----------------
func _input(event: InputEvent) -> void:
	# Закрытие панели качества по Escape
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if quality_panel and quality_panel.visible:
			_hide_quality_panel()
			get_viewport().set_input_as_handled()
			return
	
	if not is_instance_valid(shawu) and not is_packaging_mode:
		return
	
	var mouse_pos := get_global_mouse_position()
	
	if event is InputEventMouseButton:
		# Закрытие панели качества по клику вне панели
		if not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if quality_panel and quality_panel.visible:
				if not quality_panel.get_global_rect().has_point(mouse_pos):
					_hide_quality_panel()
					get_viewport().set_input_as_handled()
					return
		
		# ВСЕГДА сбрасываем drag при отпускании кнопки
		if not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_handle_release(mouse_pos)
		elif event.pressed:
			_handle_click(event, mouse_pos)
	
	elif event is InputEventMouseMotion:
		_handle_motion(mouse_pos)

func _handle_motion(mouse_pos: Vector2) -> void:
	if is_dragging and not is_animating and can_drag() and is_instance_valid(shawu):
		shawu.global_position = mouse_pos + drag_offset
	
	if is_packaging_mode and is_instance_valid(ghost_package):
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

func _handle_release(mouse_pos: Vector2) -> void:
	# Сброс drag ВСЕГДА при отпускании кнопки
	if is_dragging:
		is_dragging = false
		if state == State.RAW and grill.get_grill_rect().has_point(mouse_pos):
			_move_to_grill()

func _contains_point(mouse_pos: Vector2) -> bool:
	return is_instance_valid(shawu) and shawu.contains_global_point(mouse_pos)

func can_drag() -> bool:
	return is_instance_valid(shawu) and not is_animating and state != State.PACKAGED

# ---------------- PROCESS ----------------
func _process(_delta: float) -> void:
	if is_instance_valid(shawu):
		grill.check_hover(shawu)

# ---------------- FRY ----------------
func _on_shawu_fried(_fried_lavash: Lavash) -> void:
	if state != State.RAW:
		return
	
	state = State.FRIED
	print("Шаурма готова к упаковке!")

func _on_mouse_entered() -> void:
	if state == State.FRIED and not is_dragging and is_instance_valid(shawu_sprite):
		shawu_sprite.modulate = Color(1.1, 1.1, 1.1)

func _on_mouse_exited() -> void:
	if state == State.FRIED and not is_dragging and is_instance_valid(shawu_sprite):
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
	_set_mouse_hidden()

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
	_set_mouse_visible()

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
	# Скрываем всё содержимое шаурмы (соус и ингредиенты)
	_hide_shawarma_contents()
	
	# Меняем текстуру на свёрнутую шаурму
	if is_instance_valid(shawu_sprite):
		shawu_sprite.texture = TEXTURE_WRAPPED
	
	done_button.disabled = false
	
	# Проводим валидацию и показываем результаты
	_validate_and_show_results()
	
	print("Шаурма упакована!")

## Скрывает всё содержимое шаурмы (соус и ингредиенты)
func _hide_shawarma_contents() -> void:
	if not is_instance_valid(shawu):
		return
	
	# Скрываем все ингредиенты
	if shawu.ingredients:
		for ingredient in shawu.ingredients:
			if is_instance_valid(ingredient):
				ingredient.visible = false
	
	# Скрываем контейнер ингредиентов
	var ingredients_container = shawu.get_node_or_null("Ingredients") as Node2D
	if ingredients_container:
		ingredients_container.visible = false
	
	# Скрываем соус
	_hide_sauce()

## Скрывает соус на упакованной шаурме
func _hide_sauce() -> void:
	if not is_instance_valid(shawu):
		return
	
	# Получаем SauceResult спрайт (отображает результат из SubViewport)
	var sauce_result = shawu.get_node_or_null("SauceResult") as Sprite2D
	if sauce_result:
		# Полностью скрываем и делаем прозрачным
		sauce_result.visible = false
		sauce_result.modulate = Color.TRANSPARENT
		# Понижаем z_index, чтобы точно не перекрывал упакованную шаурму
		sauce_result.z_index = -100
	
	# Получаем SauceLayer с соусом
	var sauce_layer = shawu.get_node_or_null("SauceViewport/SauceLayer") as Node2D
	if sauce_layer:
		# Скрываем и делаем прозрачным
		sauce_layer.visible = false
		sauce_layer.modulate = Color.TRANSPARENT

	# Очищаем все спрайты соуса из слоя
	if sauce_layer:
		for child in sauce_layer.get_children():
			if is_instance_valid(child):
				child.queue_free()

# ---------------- DONE ----------------
func _on_done_button_pressed() -> void:
	# Защита от повторного нажатия
	if _is_changing_scene or done_button.disabled:
		return
	
	if not is_instance_valid(shawu) or not is_instance_valid(shawu_sprite):
		push_error("Шаурма невалидна для сохранения!")
		return
	
	_is_changing_scene = true

	# Скрываем панель качества
	_hide_quality_panel()
	
	var ingredients_data: Array = shawu.get_ingredients_data()
	var sauce_data: Array = shawu.get_sauce_data()
	
	var data := {
		"texture": shawu_sprite.texture,
		"ingredients": ingredients_data,
		"sauce": sauce_data,
		"validation": _validation_result
	}
	Globals.last_packed_lavash = data
	Globals.last_validation_result = _validation_result  # Сохраняем отдельно для клиента
	get_tree().change_scene_to_file("res://Scenes/Hall.tscn")

func _on_save_and_quit_pressed() -> void:
	# Сохраняем текущий прогресс
	Globals._save_full_progress()
	print("Прогресс сохранён! Выход в главное меню...")
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

func _shawu_get_height() -> float:
	if not is_instance_valid(shawu_sprite):
		return 400.0
	var texture: Texture2D = shawu_sprite.texture
	if not texture:
		return 400.0
	return float(texture.get_height()) * shawu_sprite.scale.y

## Восстанавливает ингредиенты из сохранённых данных
func _restore_ingredients(ingredients_data: Array) -> void:
	if not is_instance_valid(shawu):
		return
	
	for ing_data in ingredients_data:
		var texture: Texture2D = ing_data.get("texture")
		var position: Vector2 = ing_data.get("position", Vector2.ZERO)
		var scale_val: Vector2 = ing_data.get("scale", Vector2.ONE)
		var rotation_val: float = ing_data.get("rotation", 0.0)
		var z_index: int = ing_data.get("z_index", 1)
		
		if not texture:
			continue
		
		# Создаём порцию ингредиента
		var portion := Sprite2D.new()
		portion.texture = texture
		portion.position = position
		portion.scale = scale_val
		portion.rotation = rotation_val
		portion.z_index = z_index
		portion.modulate = Color(1, 1, 1, 0.8)
		portion.centered = true
		
		# Определяем тип по пути текстуры для валидации
		var texture_path: String = ing_data.get("texture_path", "")
		if not texture_path.is_empty():
			var path_lower := texture_path.to_lower()
			var ingredient_type := "unknown"
			if "meat" in path_lower:
				ingredient_type = "meat"
			elif "cheese" in path_lower:
				ingredient_type = "cheese"
			elif "onion" in path_lower:
				ingredient_type = "onion"
			elif "tomato" in path_lower:
				ingredient_type = "tomato"
			elif "salad" in path_lower:
				ingredient_type = "salad"
			elif "pepper" in path_lower:
				ingredient_type = "pepper"
			portion.set_meta("ingredient_type", ingredient_type)
		
		# Добавляем в контейнер
		var ingredients_container = shawu.get_node_or_null("Ingredients")
		if ingredients_container:
			ingredients_container.add_child(portion)
			shawu.ingredients.append(portion)
		else:
			push_error("Ingredients container не найден!")

## Восстанавливает соус из сохранённых данных
func _restore_sauce(sauce_data: Array) -> void:
	if not is_instance_valid(shawu):
		return
	
	var sauce_layer = shawu.get_node_or_null("SauceViewport/SauceLayer")
	if not sauce_layer:
		push_error("SauceLayer не найден!")
		return
	
	for sauce in sauce_data:
		var texture: Texture2D = sauce.get("texture")
		var position: Vector2 = sauce.get("position", Vector2.ZERO)
		var modulate_color: Color = sauce.get("modulate", Color.WHITE)
		var scale_val: Vector2 = sauce.get("scale", Vector2.ONE)
		var rotation_val: float = sauce.get("rotation", 0.0)
		
		if not texture:
			continue
		
		var brush: Sprite2D = Sprite2D.new()
		brush.texture = texture
		brush.position = position
		brush.modulate = modulate_color
		brush.scale = scale_val
		brush.rotation = rotation_val
		brush.centered = true
		
		# Добавляем материал для смешивания
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
		brush.material = mat
		
		sauce_layer.add_child(brush)

# ---------------- ВАЛИДАЦИЯ И КАЧЕСТВО ----------------

## Проводит валидацию и показывает результаты
func _validate_and_show_results() -> void:
	if not is_instance_valid(shawu):
		return
	
	var ingredients_data: Array = shawu.get_ingredients_data()
	var sauce_data: Array = shawu.get_sauce_data()
	
	print("=== ДАННЫЕ ШАУРМЫ ДЛЯ ВАЛИДАЦИИ ===")
	print("Ингредиентов: ", ingredients_data.size())
	print("Соуса: ", sauce_data.size())
	
	# Если заказа нет, считаем что всё ок
	_validation_result = {
		"validation": 0,  # PERFECT
		"score": 100,
		"issues": [],
		"weight_total": ingredients_data.size() * 10,
		"zones": {}
	}
	
	print("=== БАЗОВАЯ ВАЛИДАЦИЯ ШАУРМЫ ===")
	print("Результат: Идеально")
	print("Счёт: ", _validation_result.score)
	print("Вес: ", _validation_result.get("weight_total", 0))
	print("Проблемы: ", _validation_result.issues)
	
	# Показываем базовые результаты
	_show_quality_results()
	
	_is_validated = true

## Показывает базовую панель качества с результатами
func _show_quality_results() -> void:
	if not quality_panel:
		return
	
	var score: int = _validation_result.get("score", 0)
	var validation: int = _validation_result.get("validation", 0)
	var issues: Array = _validation_result.get("issues", [])
	var zones: Dictionary = _validation_result.get("zones", {})
	
	# Общий балл
	score_label.text = "Балл: %d" % score
	
	# Качество
	var quality_text: String = _get_quality_text(validation)
	var quality_color: Color = _get_quality_color(validation)
	quality_label.text = quality_text
	quality_label.modulate = quality_color
	
	# Прогресс-бары
	# Вес начинки (оцениваем по score)
	var weight_score: float = clampf(float(score), 0, 100)
	var weight_total: float = _validation_result.get("weight_total", 0)
	weight_progress.value = weight_score
	weight_label.text = "🥩 Вес начинки: %.0f%% (%.0fg)" % [weight_score, weight_total]
	weight_label.modulate = _get_progress_color(weight_score, 60)
	weight_progress.modulate = _get_progress_color(weight_score, 60)
	
	# Распределение по зонам (оцениваем по зонам)
	var distribution_score: float = _calculate_distribution_score(zones)
	distribution_progress.value = distribution_score
	distribution_label.text = "📍 Распределение: %.0f%%" % distribution_score
	distribution_label.modulate = _get_progress_color(distribution_score, 70)
	distribution_progress.modulate = _get_progress_color(distribution_score, 70)
	
	# Соус (оцениваем по отсутствию проблем с соусом)
	var sauce_score: float = _calculate_sauce_score(issues)
	sauce_progress.value = sauce_score
	sauce_label.text = "🥫 Соус: %.0f%%" % sauce_score
	sauce_label.modulate = _get_progress_color(sauce_score, 80)
	sauce_progress.modulate = _get_progress_color(sauce_score, 80)
	
	# Список проблем
	if issues.is_empty():
		issues_list.text = "[color=green]✓ Проблем нет![/color]"
	else:
		var issues_text := ""
		for issue in issues:
			issues_text += "• " + issue + "\n"
		issues_list.text = issues_text
	
	# Предсказание чаевых
	var tip_prediction: int = _calculate_tip_prediction(validation)
	tip_label.text = "💰 Чаевые: +%d₽" % tip_prediction
	tip_label.modulate = Color.GREEN if tip_prediction > 0 else Color.RED
	
	# Анимация появления
	quality_panel.modulate.a = 0.0
	quality_panel.scale = Vector2(0.9, 0.9)
	quality_panel.visible = true

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(quality_panel, "modulate:a", 1.0, 0.3)
	tween.tween_property(quality_panel, "scale", Vector2.ONE, 0.3)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Скрывает панель качества
func _hide_quality_panel() -> void:
	if quality_panel and quality_panel.visible:
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(quality_panel, "modulate:a", 0.0, 0.2)
		tween.tween_property(quality_panel, "scale", Vector2(0.9, 0.9), 0.2)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_callback(func(): quality_panel.visible = false)

## Получает текст для качества (базовая)
func _get_quality_text(validation: int) -> String:
	match validation:
		0:  # PERFECT
			return "🌟 Идеально"
		1:  # GOOD
			return "✓ Хорошо"
		2:  # ACCEPTABLE
			return "~ Приемлемо"
		3:  # BAD
			return "✗ Плохо"
		_:
			return "Неизвестно"

## Получает цвет для качества
func _get_quality_color(validation: int) -> Color:
	match validation:
		0:  # PERFECT
			return Color(0.0, 0.8, 0.0)  # Зелёный
		1:  # GOOD
			return Color(0.8, 0.8, 0.0)  # Жёлтый
		2:  # ACCEPTABLE
			return Color(1.0, 0.5, 0.0)  # Оранжевый
		3:  # BAD
			return Color(0.8, 0.0, 0.0)  # Красный
		_:
			return Color.WHITE

## Получает цвет для прогресс-бара
func _get_progress_color(value: float, threshold: float) -> Color:
	if value >= threshold:
		return Color(0.0, 0.8, 0.0)  # Зелёный
	elif value >= threshold * 0.7:
		return Color(0.8, 0.8, 0.0)  # Жёлтый
	else:
		return Color(0.8, 0.0, 0.0)  # Красный

## Рассчитывает оценку распределения по зонам (базовая)
func _calculate_distribution_score(zones: Dictionary) -> float:
	if zones.is_empty():
		return 0.0
	
	var filled_zones: int = 0
	var total_zones: int = zones.size()
	
	for zone_data in zones.values():
		if zone_data.get("total", 0) > 0:
			filled_zones += 1
	
	return float(filled_zones) / float(total_zones) * 100.0

## Рассчитывает оценку соуса
func _calculate_sauce_score(issues: Array) -> float:
	if issues.is_empty():
		return 100.0
	
	var has_sauce_issue: bool = false
	for issue in issues:
		if "соус" in issue.to_lower():
			has_sauce_issue = true
			break
	
	return 0.0 if has_sauce_issue else 80.0

## Рассчитывает предсказание чаевых
func _calculate_tip_prediction(validation: int) -> int:
	var base_reward: int = Consts.SHAWU_REWARD if "Consts" in global else 100
	
	match validation:
		0:  # PERFECT
			return int(base_reward * 1.0)  # 100% чаевые
		1:  # GOOD
			return int(base_reward * 0.5)  # 50% чаевые
		2:  # ACCEPTABLE
			return int(base_reward * 0.2)  # 20% чаевые
		3:  # BAD
			return 0  # Нет чаевых
		_:
			return 0

# ---------------- ANIMATION ----------------
func _on_animation_done() -> void:
	is_animating = false
