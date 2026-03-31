extends TextureButton

@export var ingredient_scene: PackedScene = null
@export var ingredient_texture: Texture2D = null

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	# Проверка наличия данных
	if not ingredient_scene:
		push_error("IngredientButton: ingredient_scene не назначен!")
		return
	if not ingredient_texture:
		push_error("IngredientButton: ingredient_texture не назначен!")
		return

	# Оптимизация: получаем родителя (UI), затем его родителя (сцена Kitchen)
	# Это работает, если структура такая: Kitchen -> UI -> IngredientButton
	var kitchen = get_parent().get_parent() as Node
	
	if kitchen and kitchen.has_method("start_ingredient_preview"):
		kitchen.start_ingredient_preview(ingredient_scene, ingredient_texture)
