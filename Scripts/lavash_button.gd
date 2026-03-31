extends TextureButton

@export var lavash_scene: PackedScene
@export var work_area_node_path: NodePath = "WorkArea"

func _pressed():
	var kitchen = get_tree().current_scene
	if kitchen.has_method("spawn_lavash"):
		kitchen.spawn_lavash(lavash_scene, kitchen.get_node(work_area_node_path))
