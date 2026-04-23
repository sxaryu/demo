extends Control
class_name SettingsPanel

# Ссылки на UI элементы
@onready var music_slider: HSlider = $PanelContainer/VBoxContainer/MusicContainer/MusicSlider
@onready var sfx_slider: HSlider = $PanelContainer/VBoxContainer/SFXContainer/SFXSlider
@onready var master_slider: HSlider = $PanelContainer/VBoxContainer/MasterContainer/MasterSlider
@onready var fullscreen_check: CheckButton = $PanelContainer/VBoxContainer/FullscreenContainer/FullscreenCheck
@onready var close_button: Button = $PanelContainer/VBoxContainer/CloseButton

# Константы для сохранения
const MUSIC_VOLUME_KEY := "music_volume"
const SFX_VOLUME_KEY := "sfx_volume"
const MASTER_VOLUME_KEY := "master_volume"
const FULLSCREEN_KEY := "fullscreen"
const SETTINGS_FILE := "user://settings.cfg"


func _ready() -> void:
	_setup_ui()
	_load_settings()
	# === ИСПРАВЛЕНО: Принудительно применяем полноэкранный режим при запуске ===
	_apply_fullscreen_from_settings()

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
	
	# Настраиваем чекбокс
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	
	# Настраиваем кнопку
	close_button.pressed.connect(_on_close_pressed)
	
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
	else:
		# Дефолтные значения
		master_slider.value = 1.0
		music_slider.value = 0.8
		sfx_slider.value = 0.8
		var current_mode = DisplayServer.window_get_mode()
		fullscreen_check.button_pressed = (current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	# Применяем настройки звука (полноэкранный режим применится отдельно)
	_apply_audio_settings()

# === ИСПРАВЛЕНО: Новая функция для применения полноэкранного режима при запуске ===
func _apply_fullscreen_from_settings() -> void:
	var should_be_fullscreen: bool = fullscreen_check.button_pressed
	var current_mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
	var is_currently_fullscreen: bool = (current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	# Применяем только если состояние не совпадает
	if should_be_fullscreen != is_currently_fullscreen:
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN if should_be_fullscreen 
			else DisplayServer.WINDOW_MODE_WINDOWED
		)

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
	
	# Сохраняем
	config.save(path)

func _apply_all_settings() -> void:
	_apply_audio_settings()
	apply_display_settings()

func _apply_audio_settings() -> void:
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

func _update_value_labels() -> void:
	$PanelContainer/VBoxContainer/MusicContainer/MusicValue.text = str(int(music_slider.value * 100)) + "%"
	$PanelContainer/VBoxContainer/SFXContainer/SFXValue.text = str(int(sfx_slider.value * 100)) + "%"
	$PanelContainer/VBoxContainer/MasterContainer/MasterValue.text = str(int(master_slider.value * 100)) + "%"

# ---------------- СОБЫТИЯ ----------------

func _on_music_changed(_value: float) -> void:
	_update_value_labels()
	_apply_audio_settings()

func _on_sfx_changed(_value: float) -> void:
	_update_value_labels()
	_apply_audio_settings()

func _on_master_changed(_value: float) -> void:
	_update_value_labels()
	_apply_audio_settings()

func _on_fullscreen_toggled(_pressed: bool) -> void:
	apply_display_settings()

func _on_close_pressed() -> void:
	_save_settings()
	queue_free()
