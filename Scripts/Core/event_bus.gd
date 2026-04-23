extends Node

func _ready() -> void:
	pass

# 💰 Финансы
signal money_changed(new_amount: float)
signal data_changed()
signal ingredient_purchased(type: String, cost: float, position: Vector2)

# 🌯 Лаваш и ингредиенты
signal lavash_composition_changed(lavash: Node, ingredients_data: Array)
signal ingredient_added_to_lavash(lavash: Node, type: String, global_position: Vector2)

# 📦 Шаурма
signal shawarma_packaged(data: Dictionary)
signal shawarma_delivered(reward: float)

# 📋 Заказы
signal order_changed(new_order: Dictionary)

# 🎨 Дебаг
signal zone_visualization_toggled(enabled: bool)

# 🕐 Время
signal time_changed(formatted_time: String)
