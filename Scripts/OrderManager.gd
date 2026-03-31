extends Node

# --- Сигналы ---
signal order_changed(order: Dictionary)
signal order_cleared()

var current_order: Dictionary = {}

func set_order(order: Dictionary) -> void:
	if order.is_empty():
		push_warning("OrderManager: попытка установить пустой заказ")
		return
	
	current_order = order
	order_changed.emit(current_order)

func get_order() -> Dictionary:
	return current_order

func has_order() -> bool:
	return not current_order.is_empty()

func clear() -> void:
	current_order.clear()
	order_cleared.emit()
