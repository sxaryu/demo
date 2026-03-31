extends Control
class_name IngredientsWeightUI

# Превью текстур для отображения иконок (опционально)
var ingredient_icons: Dictionary = {}

# Ссылки на лейблы
var weight_labels: Dictionary = {}

# Контейнер для элементов
@onready var container: VBoxContainer = $VBoxContainer

func _ready() -> void:
	_setup_ui()

func _setup_ui() -> void:
	# Создаем строки для каждого ингредиента
	var ingredients = ["meat", "chicken", "tomato", "salad", "cheese", "onion"]
	var names = {
		"meat": "Мясо",
		"chicken": "Курица",
		"tomato": "Помидор",
		"salad": "Салат",
		"cheese": "Сыр",
		"onion": "Лук"
	}
	
	for ing_type in ingredients:
		var hbox := HBoxContainer.new()
		
		# Название
		var name_label := Label.new()
		name_label.text = names.get(ing_type, ing_type) + ": "
		name_label.custom_minimum_size.x = 80
		hbox.add_child(name_label)
		
		# Вес (например "0г / 100г")
		var weight_label := Label.new()
		weight_label.text = "0г / 100г"
		weight_label.custom_minimum_size.x = 120
		hbox.add_child(weight_label)
		
		# Прогресс бар
		var progress := ProgressBar.new()
		progress.custom_minimum_size.x = 150
		progress.custom_minimum_size.y = 20
		progress.max_value = 100
		progress.value = 0
		progress.show_percentage = false
		hbox.add_child(progress)
		
		container.add_child(hbox)
		
		# Сохраняем ссылки
		weight_labels[ing_type] = {
			"label": weight_label,
			"progress": progress,
			"max": 100  # можно брать из Lavash
		}

func update_weight(type: String, current: int, max_grams: int) -> void:
	if not weight_labels.has(type):
		return
	
	var data = weight_labels[type]
	var label: Label = data["label"]
	var progress: ProgressBar = data["progress"]
	
	# Обновляем текст
	label.text = str(current) + "г / " + str(max_grams) + "г"
	
	# Обновляем прогресс
	progress.max_value = max_grams
	progress.value = current

func clear_all() -> void:
	for type in weight_labels:
		var data = weight_labels[type]
		data["label"].text = "0г / 100г"
		data["progress"].value = 0
