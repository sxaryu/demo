extends Node

## Глобальный логгер - добавить в autoload как "GlobalLogger"
## Для продакшена: min_level = Level.NONE или Level.WARNING

enum Level { DEBUG, INFO, WARNING, ERROR, NONE }

var min_level: Level = Level.INFO

func debug(msg: String) -> void:
	if min_level <= Level.DEBUG:
		print("[DEBUG] ", msg)

func info(msg: String) -> void:
	if min_level <= Level.INFO:
		print("[INFO] ", msg)

func warning(msg: String) -> void:
	if min_level <= Level.WARNING:
		push_warning("[WARN] ", msg)

func error(msg: String) -> void:
	if min_level <= Level.ERROR:
		push_error("[ERROR] ", msg)

func set_level(level: Level) -> void:
	min_level = level
