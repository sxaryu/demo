extends Area2D

var dragging := false
var drag_offset := Vector2.ZERO
var current_lavash: Lavash = null

# Данные ингредиента для передачи в лаваш
var ingredient_scene: PackedScene = null
var ingredient_texture: Texture2D = null

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _input(event: InputEvent) -> void:
	if not dragging:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_release()

func _process(_delta: float) -> void:
	if dragging:
		global_position = get_global_mouse_position() + drag_offset

func _release() -> void:
	dragging = false
	
	# Проверяем валидность и наличие лаваша
	if is_instance_valid(current_lavash):
		# Передаём текстуру, позицию и вес (по умолчанию 50 грамм)
		current_lavash.add_ingredient_portion(ingredient_texture, global_position, 50)
	else:
		# Если отпустили не на лаваше - удаляем
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("lavash"):
		current_lavash = area as Lavash

func _on_area_exited(area: Area2D) -> void:
	if area == current_lavash:
		current_lavash = null
