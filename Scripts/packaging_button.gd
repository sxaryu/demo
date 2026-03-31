extends TextureButton

@export var package_texture: Texture2D

func _pressed():
	if not package_texture:
		push_error("PackagingButton: package_texture не назначен!")
		return

	var kitchen_wrap = get_tree().current_scene
	if kitchen_wrap and kitchen_wrap.has_method("start_package_preview"):
		# Передаём только текстуру
		kitchen_wrap.start_package_preview(package_texture)
	else:
		push_error("PackagingButton: текущая сцена не содержит метод start_package_preview()!")
