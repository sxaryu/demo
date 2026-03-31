extends Node

# --- Сигналы ---
signal data_changed()

# --- Переменные с типизацией ---
var last_lavash_ingredients: Array = []
var last_lavash_sauce: Array = []
var last_packed_lavash: Dictionary = {}
var last_order: Dictionary = {}

# Новое: вес ингредиентов
var last_lavash_weights: Dictionary = {}

# Режим туториала
var is_tutorial_mode: bool = false

func clear_data() -> void:
	last_lavash_ingredients.clear()
	last_lavash_sauce.clear()
	last_packed_lavash.clear()
	last_order.clear()
	last_lavash_weights.clear()
	data_changed.emit()
