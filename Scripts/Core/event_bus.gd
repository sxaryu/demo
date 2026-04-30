extends Node

signal money_changed(new_amount: float)
signal data_changed()
signal ingredient_purchased(ingredient_type: String, cost: float, position: Vector2)
signal time_changed(formatted_time: String)
