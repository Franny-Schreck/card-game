extends Node2D

func _ready() -> void:
	for child in get_children():
		if "post_ready" in child:
			child.post_ready()
