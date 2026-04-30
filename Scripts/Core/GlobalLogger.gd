extends Node

enum LogLevel { DEBUG, INFO, WARNING, ERROR, NONE }

var current_level: LogLevel = LogLevel.DEBUG

func _should_log(level: LogLevel) -> bool:
	return level >= current_level

func debug(msg: String) -> void:
	if _should_log(LogLevel.DEBUG):
		print("[DEBUG] ", msg)

func info(msg: String) -> void:
	if _should_log(LogLevel.INFO):
		print("[INFO] ", msg)

func warning(msg: String) -> void:
	if _should_log(LogLevel.WARNING):
		push_warning("[WARNING] ", msg)

func error(msg: String) -> void:
	if _should_log(LogLevel.ERROR):
		push_error("[ERROR] ", msg)
