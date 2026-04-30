extends Node

<<<<<<< HEAD
signal money_changed(new_amount: float)
signal data_changed()
signal ingredient_purchased(ingredient_type: String, cost: float, position: Vector2)
=======
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
>>>>>>> c33e8377b6fd006e3771648747071697b41d5043
signal time_changed(formatted_time: String)
