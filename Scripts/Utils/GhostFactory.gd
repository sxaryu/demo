class_name GhostFactory
extends RefCounted

# Создаёт ghost-спрайт для preview
static func create_ghost(
	texture: Texture2D, 
	parent: Node, 
	z_index: int = 1000,
	modulate: Color = Color(1, 1, 1, 0.7),
	start_position: Vector2 = Vector2.ZERO
) -> Sprite2D:
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.modulate = modulate
	sprite.z_index = z_index
	sprite.centered = true
	
	if start_position != Vector2.ZERO:
		sprite.global_position = start_position
	else:
		sprite.global_position = parent.get_global_mouse_position() if parent.has_method("get_global_mouse_position") else Vector2.ZERO
	
	parent.add_child(sprite)
	return sprite

# Удаляет ghost-спрайт безопасно
static func free_ghost(sprite: Sprite2D) -> void:
	if is_instance_valid(sprite):
		sprite.queue_free()
