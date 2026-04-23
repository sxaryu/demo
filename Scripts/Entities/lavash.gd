extends Area2D
class_name Lavash

# --- Сигналы ---
signal fried(lavash: Lavash)
signal ingredient_added(ingredient_type: String, global_position: Vector2)
signal weight_changed(type: String, current: int, max_grams: int)
signal sauce_weight_changed(current: int, max_grams: int)  # 🆕 НОВЫЙ СИГНАЛ
signal sauce_purchased(cost: float, position: Vector2)     # 🆕 НОВЫЙ СИГНАЛ

# --- Переменные ---
var ingredients: Array[Node2D] = []
var is_active := true
var is_fried: bool = false
var is_on_grill: bool = false
var show_zone_debug := false

# --- Граммовка ---
var ingredients_weight: Dictionary = {}
var ingredient_max_weight: Dictionary = {
	"meat": 100,
	"chicken": 100,
	"tomato": 50,
	"salad": 50,
	"cheese": 30,
	"onion": 25,
	"pepper": 25
}

# --- Соус ---
var _last_sauce_pos: Vector2 = Vector2.ZERO
var _last_sauce_payment_pos: Vector2 = Vector2.ZERO
const MIN_SAUCE_DISTANCE := 1  # Минимальное расстояние между мазками (для плавности)
const SAUCE_PAYMENT_DISTANCE := 30.0  # Минимальное расстояние между списаниями денег
var sauce_weight: int = 0                              # 🆕 Текущий вес соуса
const SAUCE_MAX_WEIGHT: int = 50                       # 🆕 Максимум 50г соуса
const SAUCE_GRAMS_PER_BRUSH: int = 3                   # 🆕 Грамм за одно касание
const SAUCE_COST_PER_GRAM: float = 0.1                 # 🆕 Цена за грамм (0.1₽)
var current_sauce_type: String = ""                    # 🆕 Тип текущего соуса

# --- Узлы ---
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var ingredients_container: Node2D = $Ingredients
@onready var sauce_viewport: SubViewport = $SauceViewport
@onready var sauce_layer: Node2D = $SauceViewport/SauceLayer
@onready var sauce_sprite: Sprite2D = $SauceResult

# --- Кэш ссылок ---
var _sprite_cache: Sprite2D = null
var _material_cache: CanvasItemMaterial = null

# --- Константы ---
const TEXTURE_FRIED := preload("res://Textures/Kitchen/fried_shawu.png")
const DEFAULT_PORTION_GRAMS := 5


# ---------------- INIT ----------------
func _ready() -> void:
	add_to_group("lavash")
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	sauce_viewport.size = Vector2(512, 512)
	sauce_viewport.transparent_bg = true
	sauce_sprite.texture = sauce_viewport.get_texture()
	
	sauce_layer.z_index = 0
	ingredients_container.z_index = 1
	
	set_process(true)


# ---------------- MOUSE ----------------
func _on_mouse_entered() -> void:
	var kitchen = get_tree().current_scene
	if kitchen and kitchen.has_method("is_holding_ingredient"):
		if kitchen.is_holding_ingredient():
			modulate = Color(1.1, 1.1, 1.1)

func _on_mouse_exited() -> void:
	modulate = Color.WHITE

func contains_global_point(global_point: Vector2) -> bool:
	if not collision_shape or not collision_shape.shape:
		return false
	
	if collision_shape.shape is CircleShape2D:
		var local_pos = to_local(global_point)
		return local_pos.length() <= collision_shape.shape.radius
	elif collision_shape.shape is RectangleShape2D:
		var local_pos = to_local(global_point)
		var extents = collision_shape.shape.size / 2
		return abs(local_pos.x) <= extents.x and abs(local_pos.y) <= extents.y
	
	return false


# ---------------- DEBUG ----------------
func _process(_delta: float) -> void:
	if show_zone_debug:
		queue_redraw()

func _draw() -> void:
	if not show_zone_debug:
		return
	
	var sprite = get_node_or_null("Sprite2D")
	if not sprite or not sprite.texture:
		return
	
	var texture_size = sprite.texture.get_size() * sprite.scale
	var rect = Rect2(-texture_size / 2, texture_size)
	
	# Рисуем зоны для отладки
	var zone_height = texture_size.y / 3
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, zone_height)), Color(1, 0, 0, 0.2))
	draw_rect(Rect2(rect.position + Vector2(0, zone_height), Vector2(rect.size.x, zone_height)), Color(1, 0.5, 0, 0.2))
	draw_rect(Rect2(rect.position + Vector2(0, zone_height * 2), Vector2(rect.size.x, zone_height)), Color(1, 1, 0, 0.2))

func set_zone_debug(enabled: bool) -> void:
	show_zone_debug = enabled
	queue_redraw()


# ---------------- ИНГРЕДИЕНТЫ ----------------
func add_ingredient_portion(texture: Texture2D, global_pos: Vector2, grams: int = DEFAULT_PORTION_GRAMS) -> bool:
	if not is_active:
		return false
	
	var type = _get_ingredient_type(texture)
	if type == "unknown":
		push_warning("Неизвестный тип ингредиента: ", texture.resource_path)
		return false
	
	var current = ingredients_weight.get(type, 0)
	var max_grams = ingredient_max_weight.get(type, 50)
	
	if current >= max_grams:
		return false  # Ингредиент уже полный
	
	# Добавляем вес
	_add_weight(type, min(grams, max_grams - current))
	
	# Визуальное представление
	_create_ingredient_sprite(texture, global_pos)
	
	# Сигналы
	ingredient_added.emit(type, global_pos)
	weight_changed.emit(type, ingredients_weight[type], max_grams)
	
	return true

func _add_weight(type: String, grams: int) -> void:
	ingredients_weight[type] = ingredients_weight.get(type, 0) + grams

func _create_ingredient_sprite(texture: Texture2D, global_pos: Vector2) -> void:
	var portion := Sprite2D.new()
	portion.texture = texture
	portion.position = to_local(global_pos)
	portion.scale = Vector2.ONE * randf_range(0.8, 1.1)
	portion.rotation = randf_range(-PI/6, PI/6)
	portion.modulate = Color(1, 1, 1, 0.85)
	portion.centered = true
	portion.z_index = ingredients.size() + 1
	
	ingredients_container.add_child(portion)
	ingredients.append(portion)


# ---------------- СОУС (УЛУЧШЕННЫЙ) ----------------
func paint_sauce(global_pos: Vector2, brush_texture: Texture2D, sauce_type: String = "") -> void:
	if not is_instance_valid(brush_texture):
		return
	
	# 🆕 Проверка: не достигнут ли лимит соуса
	if sauce_weight >= SAUCE_MAX_WEIGHT:
		return
	
	var local = to_local(global_pos)
	var draw_pos = local + Vector2(sauce_viewport.size) / 2
	
	# 🆕 Сохраняем тип соуса
	if sauce_type != "":
		current_sauce_type = sauce_type
	
	if _last_sauce_pos == Vector2.ZERO:
		_add_sauce_brush(brush_texture, draw_pos)
		_last_sauce_pos = draw_pos
		_last_sauce_payment_pos = draw_pos
		# 🆕 Добавляем вес за первое касание
		_add_sauce_weight(SAUCE_GRAMS_PER_BRUSH)
		return
	
	var distance = draw_pos.distance_to(_last_sauce_pos)
	if distance > MIN_SAUCE_DISTANCE:
		var steps = max(1, int(distance / MIN_SAUCE_DISTANCE))
		for i in range(1, steps + 1):
			var interp_pos = _last_sauce_pos.lerp(draw_pos, float(i) / steps)
			_add_sauce_brush(brush_texture, interp_pos)
			# 🆕 Добавляем вес за каждое касание
			if i % 3 == 0:  # Не каждый шаг, чтобы не спамить
				_add_sauce_weight(SAUCE_GRAMS_PER_BRUSH)
	
	_add_sauce_brush(brush_texture, draw_pos)
	_last_sauce_pos = draw_pos

func _add_sauce_brush(brush_texture: Texture2D, pos: Vector2) -> void:
	var brush := Sprite2D.new()
	brush.texture = brush_texture
	brush.position = pos
	brush.centered = true
	brush.modulate = Color(1, 1, 1, randf_range(0.4, 0.7))
	brush.rotation = randf_range(-0.3, 0.3)
	brush.scale = Vector2.ONE * randf_range(0.7, 1.0)
	brush.material = _get_blend_material()
	sauce_layer.add_child(brush)

# 🆕 НОВЫЙ МЕТОД: Добавление веса соуса
func _add_sauce_weight(grams: int) -> void:
	var old_weight = sauce_weight
	sauce_weight = min(sauce_weight + grams, SAUCE_MAX_WEIGHT)
	
	if sauce_weight != old_weight:
		sauce_weight_changed.emit(sauce_weight, SAUCE_MAX_WEIGHT)
		
		# 🆕 Списание денег за соус
		var cost = grams * SAUCE_COST_PER_GRAM
		if Globals.spend_money(cost):
			sauce_purchased.emit(cost, _last_sauce_pos)

func reset_sauce_state() -> void:
	_last_sauce_pos = Vector2.ZERO
	_last_sauce_payment_pos = Vector2.ZERO

func should_charge_sauce() -> bool:
	# 🆕 Теперь оплата происходит в _add_sauce_weight
	# Этот метод оставлен для совместимости
	if _last_sauce_pos == Vector2.ZERO:
		return false
	
	var distance = _last_sauce_pos.distance_to(_last_sauce_payment_pos)
	if distance >= SAUCE_PAYMENT_DISTANCE:
		_last_sauce_payment_pos = _last_sauce_pos
		return true
	return false

# 🆕 НОВЫЙ МЕТОД: Проверка заполненности соуса
func is_sauce_complete() -> bool:
	return sauce_weight >= SAUCE_MAX_WEIGHT

# 🆕 НОВЫЙ МЕТОД: Процент заполнения соуса
func get_sauce_completion_percent() -> float:
	if SAUCE_MAX_WEIGHT == 0:
		return 0.0
	return float(sauce_weight) / SAUCE_MAX_WEIGHT * 100.0

# 🆕 НОВЫЙ МЕТОД: Получение типа соуса
func get_sauce_type() -> String:
	return current_sauce_type


# ---------------- УТИЛИТЫ ----------------
static func get_ingredient_type(texture: Texture2D) -> String:
	if not texture or not texture.resource_path:
		return "unknown"
	
	var path = texture.resource_path.to_lower()
	var keywords = ["chicken", "meat", "cheese", "onion", "tomato", "salad", "pepper"]
	for keyword in keywords:
		if keyword in path:
			return keyword
	return "unknown"

func _get_ingredient_type(texture: Texture2D) -> String:
	return Lavash.get_ingredient_type(texture)

func get_weight(type: String) -> int:
	return ingredients_weight.get(type, 0)

func get_max_weight(type: String) -> int:
	return ingredient_max_weight.get(type, 50)

func get_all_weights() -> Dictionary:
	return ingredients_weight.duplicate()

func is_ingredient_complete(type: String) -> bool:
	return ingredients_weight.get(type, 0) >= ingredient_max_weight.get(type, 50)

# ---------------- КЭШИРОВАНИЕ ---
func get_sprite() -> Sprite2D:
	if not _sprite_cache:
		_sprite_cache = get_node_or_null("Sprite2D")
	return _sprite_cache

func _get_blend_material() -> CanvasItemMaterial:
	if not _material_cache:
		_material_cache = CanvasItemMaterial.new()
		_material_cache.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
	return _material_cache


# ---------------- СОХРАНЕНИЕ ----------------
func get_ingredients_data() -> Array:
	var result := []
	for ing in ingredients:
		if not is_instance_valid(ing):
			continue
		
		var sprite = ing if ing is Sprite2D else ing.get_node_or_null("Sprite2D")
		if sprite and sprite.texture:
			result.append({
				"texture_path": sprite.texture.resource_path,
				"position": ing.position,
				"scale": ing.scale,
				"rotation": ing.rotation,
				"z_index": ing.z_index
			})
	return result

func get_sauce_data() -> Array:
	var result := []
	for child in sauce_layer.get_children():
		if child is Sprite2D and child.texture:
			result.append({
				"texture_path": child.texture.resource_path,
				"position": child.position,
				"scale": child.scale,
				"rotation": child.rotation,
				"modulate": child.modulate
			})
	
	# 🆕 Добавляем информацию о весе и типе соуса
	result.append({
		"sauce_weight": sauce_weight,
		"sauce_type": current_sauce_type,
		"is_meta": true  # 🆕 Метка что это мета-данные
	})
	
	return result

# 🆕 НОВЫЙ МЕТОД: Восстановление соуса из данных
func set_sauce_data(data: Array) -> void:
	clear_sauce()

	for sauce_item in data:
		if sauce_item.get("is_meta", false):
			# 🆕 Восстанавливаем мета-данные
			sauce_weight = sauce_item.get("sauce_weight", 0)
			current_sauce_type = sauce_item.get("sauce_type", "")
		else:
			# 🆕 Восстанавливаем визуальные элементы
			var brush := Sprite2D.new()
			var texture_path = sauce_item.get("texture_path", "")
			if ResourceLoader.exists(texture_path):
				brush.texture = load(texture_path)
				brush.position = sauce_item.get("position", Vector2.ZERO)
				brush.scale = sauce_item.get("scale", Vector2.ONE)
				brush.rotation = sauce_item.get("rotation", 0.0)
				brush.modulate = sauce_item.get("modulate", Color.WHITE)
				brush.centered = true
				sauce_layer.add_child(brush)
	
	# 🆕 Эмитим сигнал для обновления UI
	sauce_weight_changed.emit(sauce_weight, SAUCE_MAX_WEIGHT)

# 🆕 НОВЫЙ МЕТОД: Очистка только соуса
func clear_sauce() -> void:
	for child in sauce_layer.get_children():
		child.queue_free()
	sauce_weight = 0
	current_sauce_type = ""
	reset_sauce_state()
	sauce_weight_changed.emit(0, SAUCE_MAX_WEIGHT)


# ---------------- ОЧИСТКА ----------------
func clear() -> void:
	for ing in ingredients:
		if is_instance_valid(ing):
			ing.queue_free()
	ingredients.clear()
	ingredients_weight.clear()
	
	clear_sauce()  # 🆕 Используем новый метод
	
	reset_sauce_state()

func reset() -> void:
	clear()
	is_active = true
	modulate = Color.WHITE
	is_fried = false
	is_on_grill = false
	

# ---------------- ЖАРКА ----------------
func fry() -> void:
	if is_fried:
		return
	
	is_fried = true
	is_on_grill = false
	
	var sprite = get_sprite()
	if sprite:
		sprite.texture = TEXTURE_FRIED
	
	fried.emit(self)

func place_on_grill(grill_pos: Vector2) -> void:
	if is_fried or is_on_grill:
		return
	
	is_on_grill = true
	rotation_degrees += 90
	position = grill_pos


# ---------------- ДЕПРЕКЕЙТЕД (для совместимости) ----------------
func add_ingredient(_scene: PackedScene, texture: Texture2D, global_pos: Vector2) -> Node2D:
	push_warning("add_ingredient устарел, используйте add_ingredient_portion")
	add_ingredient_portion(texture, global_pos, ingredient_max_weight.get(_get_ingredient_type(texture), 50))
	return ingredients.back() if ingredients.size() > 0 else null

func get_ingredient_count() -> int:
	return ingredients.size()
