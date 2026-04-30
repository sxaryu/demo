extends Area2D
class_name Lavash

# --- Сигналы ---
signal fried(lavash: Lavash)
signal ingredient_added(ingredient_type: String, global_position: Vector2)

# --- Переменные ---
var ingredients: Array[Node2D] = []
var is_active := true
var is_fried: bool = false
var is_on_grill: bool = false
var show_zone_debug := false  

# --- Узлы ---
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var ingredients_container: Node2D = $Ingredients
@onready var sauce_viewport: SubViewport = $SauceViewport
@onready var sauce_layer: Node2D = $SauceViewport/SauceLayer
@onready var sauce_sprite: Sprite2D = $SauceResult

# --- Соус ---
var _last_sauce_pos: Vector2 = Vector2.ZERO
var _last_sauce_payment_pos: Vector2 = Vector2.ZERO
const MIN_SAUCE_DISTANCE := 1  # Минимальное расстояние между мазками
const SAUCE_PAYMENT_DISTANCE := 30.0  # Минимальное расстояние между списаниями денег

# --- Константы ---
const TEXTURE_FRIED := preload("res://Textures/Kitchen/fried_shawu.png")

func _ready() -> void:
	add_to_group("lavash")
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	sauce_viewport.size = Vector2(512, 512)
	sauce_viewport.transparent_bg = true
	sauce_sprite.texture = sauce_viewport.get_texture()

	sauce_layer.z_index = 0
	ingredients_container.z_index = 1

	# Включаем _process для перерисовки зон
	set_process(true)

func _on_mouse_entered() -> void:
	var kitchen = get_tree().current_scene
	if kitchen and kitchen.has_method("is_holding_ingredient"):
		if kitchen.is_holding_ingredient():
			modulate = Color(1.1, 1.1, 1.1)

func _on_mouse_exited() -> void:
	modulate = Color.WHITE

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not show_zone_debug:
		return

	# Рисуем линии зон (визуализация для отладки)
	var sprite = get_node_or_null("Sprite2D")
	if not sprite or not sprite.texture:
		return
	
	var texture_height = float(sprite.texture.get_height())
	var texture_width = float(sprite.texture.get_width())
	
	# Получаем масштаб спрайта
	var sprite_scale = sprite.scale
	var scaled_width = texture_width * sprite_scale.x
	var scaled_height = texture_height * sprite_scale.y
	
	# Центр спрайта в локальных координатах лаваша (центр Area2D = 0,0)
	var _sprite_center = Vector2.ZERO
	
	# Центры зон (Y растёт вниз) - относительно центра спрайта
	var zone_top_y = scaled_height * 0.33
	var zone_middle_y = scaled_height * 0.66
	
	# Цвета зон
	var top_color = Color(1.0, 0.3, 0.3, 0.3)    # Красный (верх)
	var middle_color = Color(1.0, 0.5, 0.3, 0.3) # Оранжевый (середина)
	var bottom_color = Color(1.0, 0.7, 0.3, 0.3) # Оранжево-жёлтый (низ)
	
	# Верхняя точка спрайта относительно центра
	var top_y = -scaled_height / 2.0
	var center_x = 0.0
	
	# Рисуем полупрозрачные зоны
	draw_rect(Rect2(Vector2(center_x - scaled_width/2, top_y), Vector2(scaled_width, zone_top_y)), top_color)
	draw_rect(Rect2(Vector2(center_x - scaled_width/2, top_y + zone_top_y), Vector2(scaled_width, zone_middle_y - zone_top_y)), middle_color)
	draw_rect(Rect2(Vector2(center_x - scaled_width/2, top_y + zone_middle_y), Vector2(scaled_width, scaled_height - zone_middle_y)), bottom_color)
	
	# Рисуем линии границ
	draw_line(Vector2(center_x - scaled_width/2, top_y + zone_top_y), Vector2(center_x + scaled_width/2, top_y + zone_top_y), Color.WHITE, 3.0, true)
	draw_line(Vector2(center_x - scaled_width/2, top_y + zone_middle_y), Vector2(center_x + scaled_width/2, top_y + zone_middle_y), Color.WHITE, 3.0, true)

func contains_global_point(global_point: Vector2) -> bool:
	if collision_shape.shape is CircleShape2D:
		var local_pos = to_local(global_point)
		return local_pos.length() <= collision_shape.shape.radius
	return false

# ---------------- ИНГРЕДИЕНТЫ ----------------

func add_ingredient(ingredient_scene: PackedScene, ingredient_texture: Texture2D, global_pos: Vector2) -> Node2D:
	if not is_active:
		return null

	var ingredient = ingredient_scene.instantiate()
	ingredients_container.add_child(ingredient)
	ingredient.position = to_local(global_pos)

	var sprite = ingredient.get_node_or_null("Sprite2D")
	if sprite and ingredient_texture:
		sprite.texture = ingredient_texture

	ingredient.z_index = ingredients.size() + 1
	ingredients.append(ingredient)
	
	return ingredient

func add_ingredient_portion(ingredient_texture: Texture2D, global_pos: Vector2) -> void:
	if not is_active:
		return
	
	var type = _get_ingredient_type(ingredient_texture)
	
	# Визуальный эффект - добавляем маленький спрайт (как соус)
	var portion := Sprite2D.new()
	portion.texture = ingredient_texture
	portion.position = to_local(global_pos)
	
	# Сохраняем тип ингредиента для валидации
	portion.set_meta("ingredient_type", type)
	
	# Рандомизация размера
	var random_scale = randf_range(0.9, 1.2)
	portion.scale = Vector2(random_scale, random_scale)
	
	# Рандомизация поворота
	portion.rotation_degrees = randf_range(-90, 90)
	
	portion.modulate = Color(1, 1, 1, 0.8)
	portion.centered = true
	portion.z_index = ingredients.size() + 1
	
	ingredients_container.add_child(portion)
	ingredients.append(portion)

	# Сигнал для UI
	ingredient_added.emit(type, global_pos)

# ---------------- ТЕХНОВ ----------------

func _get_ingredient_type(texture: Texture2D) -> String:
	if not texture or not texture.resource_path:
		return "unknown"
	
	var path = texture.resource_path.to_lower()
	if "chicken" in path:
		return "chicken"
	elif "meat" in path:
		return "meat"
	elif "cheese" in path:
		return "cheese"
	elif "onion" in path:
		return "onion"
	elif "tomato" in path:
		return "tomato"
	elif "salad" in path:
		return "salad"
	elif "pepper" in path:
		return "pepper"
	return "unknown"

# ---------------- СОУС (УЛУЧШЕННЫЙ) ----------------

func paint_sauce(global_pos: Vector2, brush_texture: Texture2D) -> void:
	if not is_instance_valid(brush_texture):
		return
	
	var local = to_local(global_pos)
	var viewport_center = Vector2(sauce_viewport.size) / 2
	var draw_pos = local + viewport_center
	
	# Первая точка или сброс состояния
	if _last_sauce_pos == Vector2.ZERO:
		_add_sauce_brush(brush_texture, draw_pos)
		_last_sauce_pos = draw_pos
		return
	
	# Интерполяция между точками для плавной линии
	var distance = draw_pos.distance_to(_last_sauce_pos)
	
	if distance > MIN_SAUCE_DISTANCE:
		var steps = max(1, int(distance / MIN_SAUCE_DISTANCE))
		
		for i in range(1, steps + 1):
			var t = float(i) / float(steps)
			var interp_pos = _last_sauce_pos.lerp(draw_pos, t)
			_add_sauce_brush(brush_texture, interp_pos)
	
	# Всегда добавляем текущую точку для плотного покрытия
	_add_sauce_brush(brush_texture, draw_pos)
	_last_sauce_pos = draw_pos

func _add_sauce_brush(brush_texture: Texture2D, pos: Vector2) -> void:
	var brush := Sprite2D.new()
	brush.texture = brush_texture
	brush.position = pos
	brush.centered = true
	
	# Визуальные вариации для натуральности
	brush.modulate = Color(1, 1, 1, randf_range(0.4, 0.7))
	brush.rotation = randf_range(-0.3, 0.3)
	var random_scale = randf_range(0.7, 1.0)
	brush.scale = Vector2(random_scale, random_scale)
	
	brush.material = _get_blend_material()
	sauce_layer.add_child(brush) 

func reset_sauce_state() -> void:
	_last_sauce_pos = Vector2.ZERO
	_last_sauce_payment_pos = Vector2.ZERO

func should_charge_sauce() -> bool:
	var distance = _last_sauce_pos.distance_to(_last_sauce_payment_pos)
	if distance >= SAUCE_PAYMENT_DISTANCE:
		_last_sauce_payment_pos = _last_sauce_pos
		return true
	return false

func _get_blend_material() -> CanvasItemMaterial:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
	return mat

# ---------------- СОХРАНЕНИЕ / ЗАГРУЗКА ----------------

func get_ingredients_data() -> Array:
	var result := []
	for ingredient in ingredients:
		if is_instance_valid(ingredient):
			# Ингредиент может быть Node2D с Sprite2D внутри или сам Sprite2D
			var sprite: Sprite2D = null
			if ingredient is Sprite2D:
				sprite = ingredient as Sprite2D
			else:
				sprite = ingredient.get_node_or_null("Sprite2D") as Sprite2D
			
			if sprite and sprite.texture:
				result.append({
					"texture": sprite.texture,
					"texture_path": sprite.texture.resource_path,
					"position": ingredient.position,
					"z_index": ingredient.z_index,
					"scale": ingredient.scale,
					"rotation": ingredient.rotation
				})
	return result

func get_sauce_data() -> Array:
	var sauce_data := []
	for child in sauce_layer.get_children():
		if child is Sprite2D:
			sauce_data.append({
				"texture": child.texture,
				"texture_path": child.texture.resource_path,
				"position": child.position,
				"modulate": child.modulate,
				"scale": child.scale,
				"rotation": child.rotation
			})
	return sauce_data

# ---------------- ОБЩИЕ ----------------

func clear() -> void:
	for i in ingredients:
		if is_instance_valid(i):
			i.queue_free()
	ingredients.clear()
	
	# Очищаем соус
	for child in sauce_layer.get_children():
		child.queue_free()
	
	reset_sauce_state()

func reset() -> void:
	clear()
	is_active = true
	modulate = Color.WHITE
	is_fried = false
	is_on_grill = false

func get_ingredient_count() -> int:
	return ingredients.size()

func set_zone_debug(enabled: bool) -> void:
	show_zone_debug = enabled
	queue_redraw()

# ---------------- ЖАРКА ----------------

func fry() -> void:
	if is_fried:
		return
	
	is_fried = true
	is_on_grill = false
	
	var sprite = get_node("Sprite2D")
	if sprite:
		sprite.texture = TEXTURE_FRIED
	
	fried.emit(self)

func place_on_grill(grill_pos: Vector2) -> void:
	if is_fried or is_on_grill:
		return
	
	is_on_grill = true
	rotation_degrees += 90
	position = grill_pos
