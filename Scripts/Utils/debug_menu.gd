extends CanvasLayer

var panel: Panel
var visible_flag := false

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_create_ui()
	hide_menu()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		toggle_menu()
		get_viewport().set_input_as_handled()

func toggle_menu() -> void:
	visible_flag = not visible_flag
	if visible_flag:
		show_menu()
	else:
		hide_menu()

func show_menu() -> void:
	panel.visible = true

func hide_menu() -> void:
	panel.visible = false

func _create_ui() -> void:
	panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.offset_left = 10
	panel.offset_top = 80
	panel.offset_right = 220
	panel.offset_bottom = 400
	
	var vbox := VBoxContainer.new()
	vbox.offset_left = 10
	vbox.offset_top = 10
	vbox.offset_right = 200
	vbox.offset_bottom = 310
	
	var title := Label.new()
	title.text = "🔧 DEBUG MENU"
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)
	
	vbox.add_child(_create_separator())
	
	# Кнопки навигации
	vbox.add_child(_create_button("🏠 MainMenu", _go_main_menu))
	vbox.add_child(_create_button("📖 Intro", _go_intro))
	vbox.add_child(_create_button("👥 Hall", _go_hall))
	vbox.add_child(_create_button("🍳 Kitchen", _go_kitchen))
	vbox.add_child(_create_button("📦 KitchenWrap", _go_kitchen_wrap))
	vbox.add_child(_create_button("📊 EndDay", _go_end_day))
	
	vbox.add_child(_create_separator())
	
	# Debug действия
	vbox.add_child(_create_button("⏩ +2ч15м", _add_time))
	vbox.add_child(_create_button("💰 +1000 денег", _add_money))
	vbox.add_child(_create_button("🔄 Сброс данных", _reset_data))
	
	panel.add_child(vbox)
	add_child(panel)

func _create_button(text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.pressed.connect(callback)
	return btn

func _create_separator() -> HSeparator:
	return HSeparator.new()

# ==================== НАВИГАЦИЯ ====================
func _go_main_menu() -> void:
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

func _go_intro() -> void:
	get_tree().change_scene_to_file("res://Scenes/Intro.tscn")

func _go_hall() -> void:
	Globals.last_packed_lavash = {}
	Globals.last_order = {}
	get_tree().change_scene_to_file("res://Scenes/Hall.tscn")

func _go_kitchen() -> void:
	if Globals.last_order.is_empty():
		Globals.last_order = {"lavash": true, "meat": "chicken", "tomato": 1, "salad": 1}
	get_tree().change_scene_to_file("res://Scenes/Kitchen.tscn")

func _go_kitchen_wrap() -> void:
	get_tree().change_scene_to_file("res://Scenes/KitchenWrap.tscn")

func _go_end_day() -> void:
	get_tree().change_scene_to_file("res://Scenes/EndDay.tscn")

# ==================== DEBUG ДЕЙСТВИЯ ====================
func _add_time() -> void:
	Globals.add_customer_time()
	print("⏩ Время: ", Globals.get_formatted_time())

func _add_money() -> void:
	Globals.add_money(1000.0)
	print("💰 Деньги: ", Globals.total_money, "₽")

func _reset_data() -> void:
	Globals.clear_data()
	print("🔄 Данные сброшены")