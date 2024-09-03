class_name BoardItem
extends Sprite2D

@export var show_if: String

@export var turn_effects: String

var show_func: ScriptInterpreter.ScriptNode

var turn_effect_funcs: Array[ScriptInterpreter.ScriptNode]

var change_indicator: Sprite2D

var board: Board

var district: District

var is_active: bool

var will_be_active: bool


func _ready() -> void:
	self.change_indicator = Sprite2D.new()
	change_indicator.texture = load("res://assets/god_hand.png")
	change_indicator.offset = Vector2(35, 0)
	change_indicator.visible = false
	add_child(change_indicator)


func post_ready() -> void:
	board.environment_changed.connect(_on_environment_changed)
	
	var interpreter: ScriptInterpreter = board.card_factory.get_node("script_interpreter")

	show_func = interpreter.load_script_node(
		get_path().get_concatenated_names() + "@show_if",
		show_if
	)

	turn_effect_funcs = interpreter.load_script_nodes(
		get_path().get_concatenated_names() + "@turn_effects",
		turn_effects
	)


func _calc_is_active() -> bool:
	var env: ScriptInterpreter.ScriptEnvironment = board.card_factory.create_environment(
		board.global_stats.prev_environment,
		district.prev_environment
	)

	return await show_func.evaluate([], env)


func _calc_will_be_active() -> bool:
	var env: ScriptInterpreter.ScriptEnvironment = board.card_factory.create_environment(
		board.global_stats.curr_environment,
		district.curr_environment
	)

	return await show_func.evaluate([], env)


func _on_environment_changed() -> void:
	is_active = await _calc_is_active()
	will_be_active = await _calc_will_be_active()

	self.visible = is_active
	change_indicator.visible = is_active != will_be_active


func apply_turn_effects(display_index: int, env: ScriptInterpreter.ScriptEnvironment) -> void:
	if is_active:
		for turn_effect_func in turn_effect_funcs:
			await turn_effect_func.evaluate([], env)

	if is_active and not will_be_active:
		pass # TODO: Add removal effect
	elif not is_active and will_be_active:
		pass # TODO: Add appearance effect
