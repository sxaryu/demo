extends Area2D
class_name Lavash

# --- Сигналы ---
signal fried(lavash: Lavash)
signal ingredient_added(type: String, grams: int, max_grams: int)

# --- Переменные ---
var ingredients: Array[Node2D] = []
var is_active := true
var is_fried: bool = false
var is_on_grill: bool = false

# --- Граммовка ---
var ingredients_weight: Dictionary = {}  # {"meat": 0, "tomato": 0, ...}
var ingredient_max_weight: Dictionary = {
	"meat": 100,      # 100г мяса
	"chicken": 100,   # 100г курицы
	"tomato": 50,     # 50г помидоров
	"salad": 50,      # 50г салата
	"cheese": 30,     # 30г сыра
	"onion": 25       # 25г лука
}

# --- Узлы ---
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var ingredients_container: Node2D = $Ingredients
@onready var sauce_viewport: SubViewport = $SauceViewport
@onready var sauce_layer: Node2D = $SauceViewport/SauceLayer
@onready var sauce_sprite: Sprite2D = $SauceResult

# --- Константы ---
const TEXTURE_FRIED := preload("res://Textures/fried_shawu.png")
const PORTION_GRAMS := 15  # Сколько грамм сыпется за раз (было 5)

func _ready() -> void:
	add_to_group("lavash")
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	sauce_viewport.size = Vector2(512, 512)
	sauce_viewport.transparent_bg = true
	sauce_sprite.texture = sauce_viewport.get_texture()

	sauce_layer.z_index = 0
	ingredients_container.z_index = 1

func _on_mouse_entered() -> void:
	var kitchen = get_tree().current_scene
	if kitchen and kitchen.has_method("is_holding_ingredient"):
		if kitchen.is_holding_ingredient():
			modulate = Color(1.1, 1.1, 1.1)

func _on_mouse_exited() -> void:
	modulate = Color.WHITE

func contains_global_point(global_point: Vector2) -> bool:
	if collision_shape.shape is CircleShape2D:
		var local_pos = to_local(global_point)
		return local_pos.length() <= collision_shape.shape.radius
	return false

# ---------------- ИНГРЕДИЕНТЫ (Старый метод для совместимости) ----------------

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
	
	# Добавляем граммы (одно нажатие = полная порция)
	var type = _get_ingredient_type(ingredient_texture)
	var max_grams = ingredient_max_weight.get(type, 50)
	add_weight(type, max_grams)
	
	return ingredient

# ---------------- ГРАММОВКА (Новый метод) ----------------

func add_ingredient_portion(ingredient_texture: Texture2D, global_pos: Vector2, grams: int = PORTION_GRAMS) -> void:
	if not is_active:
		return

	var type = _get_ingredient_type(ingredient_texture)
	var current_weight = ingredients_weight.get(type, 0)
	var max_grams = ingredient_max_weight.get(type, 50)
	
	# Не превышаем максимум
	if current_weight >= max_grams:
		return
	
	# Добавляем порцию
	add_weight(type, grams)
	
	# Визуальный эффект - добавляем маленький спрайт (как соус)
	var portion := Sprite2D.new()
	portion.texture = ingredient_texture
	portion.position = to_local(global_pos)
	portion.scale = Vector2(0.3, 0.3)  # Маленький кусочек
	portion.modulate = Color(1, 1, 1, 0.8)
	portion.centered = true
	portion.z_index = ingredients.size() + 1
	
	ingredients_container.add_child(portion)
	ingredients.append(portion)

func add_weight(type: String, grams: int) -> void:
	if not ingredients_weight.has(type):
		ingredients_weight[type] = 0
	
	ingredients_weight[type] += grams
	
	# Ограничиваем максимумом
	var max_grams = ingredient_max_weight.get(type, 50)
	ingredients_weight[type] = min(ingredients_weight[type], max_grams)
	
	# Отправляем сигнал для UI
	ingredient_added.emit(type, ingredients_weight[type], max_grams)

func get_weight(type: String) -> int:
	return ingredients_weight.get(type, 0)

func get_max_weight(type: String) -> int:
	return ingredient_max_weight.get(type, 50)

func is_ingredient_complete(type: String) -> bool:
	var current = ingredients_weight.get(type, 0)
	var max_grams = ingredient_max_weight.get(type, 50)
	return current >= max_grams

func get_all_weights() -> Dictionary:
	return ingredients_weight.duplicate()

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
	return "unknown"

# ---------------- СОУС (оставляем как было) ----------------

func paint_sauce(global_pos: Vector2, brush_texture: Texture2D) -> void:
	var local = to_local(global_pos)
	var brush := Sprite2D.new()
	
	brush.texture = brush_texture
	brush.position = local + Vector2(sauce_viewport.size) / 2
	brush.centered = true
	brush.modulate = Color(1, 1, 1, 0.5)
	brush.material = _get_blend_material()
	
	sauce_layer.add_child(brush)

func _get_blend_material() -> CanvasItemMaterial:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
	return mat

# ---------------- СОХРАНЕНИЕ / ЗАГРУЗКА ----------------

func get_ingredients_data() -> Array:
	var result := []
	for ingredient in ingredients:
		if is_instance_valid(ingredient):
			var sprite = ingredient.get_node_or_null("Sprite2D")
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
	ingredients_weight.clear()

func reset() -> void:
	clear()
	is_active = true
	modulate = Color.WHITE
	is_fried = false
	is_on_grill = false

func get_ingredient_count() -> int:
	return ingredients.size()

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
