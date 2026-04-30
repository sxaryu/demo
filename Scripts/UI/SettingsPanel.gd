extends Control
class_name SettingsPanel

# Ссылки на UI элементы
@onready var music_slider: HSlider = $PanelContainer/VBoxContainer/MusicContainer/MusicSlider
@onready var sfx_slider: HSlider = $PanelContainer/VBoxContainer/SFXContainer/SFXSlider
@onready var master_slider: HSlider = $PanelContainer/VBoxContainer/MasterContainer/MasterSlider
@onready var fullscreen_check: CheckButton = $PanelContainer/VBoxContainer/FullscreenContainer/FullscreenCheck
@onready var vsync_check: CheckButton = $PanelContainer/VBoxContainer/VSyncContainer/VSyncCheck
@onready var fps_label: Label = $PanelContainer/VBoxContainer/FPSTargetContainer/FPSTargetLabel
@onready var fps_slider: HSlider = $PanelContainer/VBoxContainer/FPSTargetContainer/FPSTargetSlider
@onready var language_option: OptionButton = $PanelContainer/VBoxContainer/LanguageContainer/LanguageOption
@onready var sensitivity_slider: HSlider = $PanelContainer/VBoxContainer/SensitivityContainer/SensitivitySlider
@onready var close_button: Button = $PanelContainer/VBoxContainer/CloseButton
@onready var reset_button: Button = $PanelContainer/VBoxContainer/ResetButton
@onready var apply_button: Button = $PanelContainer/VBoxContainer/ApplyButton

# Константы для сохранения
const MUSIC_VOLUME_KEY := "music_volume"
const SFX_VOLUME_KEY := "sfx_volume"
const MASTER_VOLUME_KEY := "master_volume"
const FULLSCREEN_KEY := "fullscreen"
const VSYNC_KEY := "vsync"
const FPS_LIMIT_KEY := "fps_limit"
const LANGUAGE_KEY := "language"
const SENSITIVITY_KEY := "mouse_sensitivity"
const SETTINGS_FILE := "user://settings.cfg"

# Языки
const LANGUAGES := [
	{"code": "ru", "name": "Русский"},
	{"code": "en", "name": "English"},
	{"code": "es", "name": "Español"},
	{"code": "fr", "name": "Français"}
]

func _ready() -> void:
	_setup_ui()
	_load_settings()

func _setup_ui() -> void:
	# Настраиваем слайдеры
	music_slider.min_value = 0.0
	music_slider.max_value = 1.0
	music_slider.step = 0.01
	music_slider.value_changed.connect(_on_music_changed)
	
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 1.0
	sfx_slider.step = 0.01
	sfx_slider.value_changed.connect(_on_sfx_changed)
	
	master_slider.min_value = 0.0
	master_slider.max_value = 1.0
	master_slider.step = 0.01
	master_slider.value_changed.connect(_on_master_changed)
	
	fps_slider.min_value = 30
	fps_slider.max_value = 300
	fps_slider.step = 30
	fps_slider.value_changed.connect(_on_fps_changed)
	
	sensitivity_slider.min_value = 0.1
	sensitivity_slider.max_value = 3.0
	sensitivity_slider.step = 0.1
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	
	# Настраиваем чекбоксы
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	vsync_check.toggled.connect(_on_vsync_toggled)
	
	# Настраиваем опцию языка
	language_option.clear()
	for lang in LANGUAGES:
		language_option.add_item(lang.name)
		language_option.set_item_metadata(language_option.item_count - 1, lang.code)
	language_option.item_selected.connect(_on_language_changed)
	
	# Настраиваем кнопки
	close_button.pressed.connect(_on_close_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	apply_button.pressed.connect(_on_apply_pressed)
	
	# Обновляем отображение значений
	_update_value_labels()

func _load_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	var path: String = SETTINGS_FILE
	
	if config.load(path) == OK:
		master_slider.value = config.get_value("audio", MASTER_VOLUME_KEY, 1.0)
		music_slider.value = config.get_value("audio", MUSIC_VOLUME_KEY, 0.8)
		sfx_slider.value = config.get_value("audio", SFX_VOLUME_KEY, 0.8)
		fullscreen_check.button_pressed = config.get_value("display", FULLSCREEN_KEY, false)
		vsync_check.button_pressed = config.get_value("display", VSYNC_KEY, true)
		fps_slider.value = config.get_value("display", FPS_LIMIT_KEY, 60)
		
		var lang_code: String = config.get_value("general", LANGUAGE_KEY, "ru")
		for i in range(language_option.item_count):
			if language_option.get_item_metadata(i) == lang_code:
				language_option.selected = i
				break
		
		sensitivity_slider.value = config.get_value("controls", SENSITIVITY_KEY, 1.0)
	else:
		# Дефолтные значения
		master_slider.value = 1.0
		music_slider.value = 0.8
		sfx_slider.value = 0.8
		var current_mode = DisplayServer.window_get_mode()
		fullscreen_check.button_pressed = (current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN)
		vsync_check.button_pressed = true
		fps_slider.value = 60
		language_option.selected = 0  # Русский по умолчанию
		sensitivity_slider.value = 1.0
	
	# Применяем настройки
	_apply_all_settings()

func _save_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	var path: String = SETTINGS_FILE
	
	# Загружаем существующий конфиг если есть
	if config.load(path) != OK:
		config = ConfigFile.new()
	
	# Сохраняем новые значения
	config.set_value("audio", MASTER_VOLUME_KEY, master_slider.value)
	config.set_value("audio", MUSIC_VOLUME_KEY, music_slider.value)
	config.set_value("audio", SFX_VOLUME_KEY, sfx_slider.value)
	config.set_value("display", FULLSCREEN_KEY, fullscreen_check.button_pressed)
	config.set_value("display", VSYNC_KEY, vsync_check.button_pressed)
	config.set_value("display", FPS_LIMIT_KEY, fps_slider.value)
	config.set_value("general", LANGUAGE_KEY, language_option.get_item_metadata(language_option.selected))
	config.set_value("controls", SENSITIVITY_KEY, sensitivity_slider.value)
	
	# Сохраняем
	var err: int = config.save(path)
	if err == OK:
		print("Настройки сохранены")
	else:
		push_error("Не удалось сохранить настройки: ", err)

func _apply_all_settings() -> void:
	_apply_audio_settings()
	apply_display_settings()
	apply_fps_settings()
	apply_vsync_settings()
	apply_sensitivity_settings()

func _apply_audio_settings() -> void:
	# Применяем громкость
	var bus_master: int = AudioServer.get_bus_index("Master")
	var bus_music: int = AudioServer.get_bus_index("Music")
	var bus_sfx: int = AudioServer.get_bus_index("SFX")
	
	if bus_master >= 0:
		AudioServer.set_bus_volume_db(bus_master, linear_to_db(master_slider.value))
	
	if bus_music >= 0:
		AudioServer.set_bus_volume_db(bus_music, linear_to_db(music_slider.value))
	
	if bus_sfx >= 0:
		AudioServer.set_bus_volume_db(bus_sfx, linear_to_db(sfx_slider.value))

func apply_display_settings() -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen_check.button_pressed 
		else DisplayServer.WINDOW_MODE_WINDOWED
	)

func apply_fps_settings() -> void:
	Engine.max_fps = int(fps_slider.value)
	fps_label.text = str(fps_slider.value) + " FPS"

func apply_vsync_settings() -> void:
	# Применяем VSync через ProjectSettings
	ProjectSettings.set_setting("rendering/vsync/vsync_mode", 1 if vsync_check.button_pressed else 0)
	
	# Применяем настройки
	if Engine.is_editor_hint():
		# В редакторе просто выводим сообщение
		print("VSync:", "Включен" if vsync_check.button_pressed else "Выключен")
	else:
		# В игре применяем через Engine
		Engine.set_time_scale(1.0)  # Сбрасываем таймскейл

func apply_sensitivity_settings() -> void:
	# Применяем чувствительность мыши
	if has_method("_set_mouse_sensitivity"):
		call("_set_mouse_sensitivity", sensitivity_slider.value)

func _update_value_labels() -> void:
	$PanelContainer/VBoxContainer/MusicContainer/MusicValue.text = str(int(music_slider.value * 100)) + "%"
	$PanelContainer/VBoxContainer/SFXContainer/SFXValue.text = str(int(sfx_slider.value * 100)) + "%"
	$PanelContainer/VBoxContainer/MasterContainer/MasterValue.text = str(int(master_slider.value * 100)) + "%"
	$PanelContainer/VBoxContainer/SensitivityContainer/SensitivityValue.text = str(sensitivity_slider.value) + "x"
	apply_fps_settings()

# ---------------- СОБЫТИЯ ----------------

func _on_music_changed(value: float) -> void:
	_update_value_labels()
	_apply_audio_settings()

func _on_sfx_changed(value: float) -> void:
	_update_value_labels()
	_apply_audio_settings()

func _on_master_changed(value: float) -> void:
	_update_value_labels()
	_apply_audio_settings()

func _on_fullscreen_toggled(_pressed: bool) -> void:
	apply_display_settings()

func _on_vsync_toggled(_pressed: bool) -> void:
	apply_vsync_settings()

func _on_fps_changed(value: float) -> void:
	apply_fps_settings()

func _on_language_changed(index: int) -> void:
	var lang_code: String = language_option.get_item_metadata(index)
	print("Язык изменен на: ", lang_code)

func _on_sensitivity_changed(value: float) -> void:
	$PanelContainer/VBoxContainer/SensitivityContainer/SensitivityValue.text = str(value) + "x"
	apply_sensitivity_settings()

func _on_close_pressed() -> void:
	_save_settings()
	queue_free()

func _on_reset_pressed() -> void:
	# Сбрасываем настройки по умолчанию
	master_slider.value = 1.0
	music_slider.value = 0.8
	sfx_slider.value = 0.8
	fullscreen_check.button_pressed = false
	vsync_check.button_pressed = true
	fps_slider.value = 60
	language_option.selected = 0
	sensitivity_slider.value = 1.0
	
	# Применяем настройки
	_apply_all_settings()
	
	print("Настройки сброшены")

func _on_apply_pressed() -> void:
	_save_settings()
	print("Настройки применены")