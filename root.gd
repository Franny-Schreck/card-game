class_name Root
extends Node2D

signal root_ready


func _ready() -> void:
	root_ready.emit()


static func connect_on_root_ready(node: Node, on_root_ready: Callable) -> void:
	node.get_node('/root/root').root_ready.connect(on_root_ready)
