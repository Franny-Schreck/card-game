class_name BoardItem
extends Sprite2D

@export var show_if: String

var show_func: ScriptInterpreter.ScriptNode

var board: Board

var district: District

func is_shown() -> bool:
	return show_func.evaluate([], board.card_factory.create_environment(board.environment, district.environment))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	self.visible = is_shown()
