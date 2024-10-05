class_name BoardItem
extends Sprite2D

@export var _script_name: String

@export var _has_change_indicator: bool = true

var _change_indicator: Sprite2D

var _self_sprite: Sprite2D

var _building_factory: BuildingFactory

var _board: Board

var _district: District

var _script: Dictionary

var _condition: Array[ScriptInterpreter.ScriptNode]

var _effect: Array[ScriptInterpreter.ScriptNode]

var _type: String

var _is_active: bool

var _will_be_active: bool


func apply_turn_effects(_display_index: int, env: ScriptInterpreter.ScriptEnvironment) -> void:
	if _is_active:
		for effect in _effect:
			await effect.evaluate([], env)

	if _is_active and not _will_be_active:
		pass # TODO: Add removal effect
	elif not _is_active and _will_be_active:
		pass # TODO: Add appearance effect


func _ready() -> void:
	_self_sprite = Sprite2D.new()
	_self_sprite.texture = texture
	_self_sprite.visible = false
	add_child(_self_sprite)

	if _has_change_indicator:
		_change_indicator = Sprite2D.new()
		_change_indicator.texture = load("res://assets/god_hand.png")
		_change_indicator.visible = false
		_change_indicator.position = Vector2(25, 0) + _calc_right_image_edge() * scale
		_change_indicator.scale = Vector2.ONE / scale
		_change_indicator.z_index = 2
		add_child(_change_indicator)

	texture = null

	_board = get_node("/root/root/board")

	_district = _get_district()

	_board.environment_changed.connect(_on_environment_changed)

	Root.connect_on_root_ready(self, _on_root_ready)


func _on_root_ready() -> void:
	_building_factory = get_node("/root/root/building_factory")

	_script = _building_factory.get_building_script(_script_name)

	_type = _script["TYPE"]
	_condition = _script["CONDITION"]
	_effect = _script["EFFECT"]


func _get_district() -> District:
	var parent = get_parent()

	while not parent is District:
		parent = parent.get_parent()

	return parent

# TODO: Do this nicely for all images, irrespective of image size vs. actual
#       sprite size and position
func _calc_right_image_edge() -> Vector2:
	var image: Image = _self_sprite.texture.get_image()

	var center_x: int = image.get_width() / 2
	#var center_y: int = image.get_height() / 2
#
	#var offset_x: int = 0
#
	#while image.get_pixel(center_x + offset_x, center_y).a8 == 255:
		#offset_x += 1
#
	#return Vector2(offset_x, 0)
	return Vector2(center_x, 0)


func _calc_is_active() -> bool:
	var env: ScriptInterpreter.ScriptEnvironment = _board.card_factory.create_environment(
		_board.global_stats.prev_environment,
		_district.prev_environment
	)

	for condition in _condition:
		if not await condition.evaluate([], env):
			return false

	return true


func _calc_will_be_active() -> bool:
	var env: ScriptInterpreter.ScriptEnvironment = _board.card_factory.create_environment(
		_board.global_stats.curr_environment,
		_district.curr_environment
	)

	for condition in _condition:
		if not await condition.evaluate([], env):
			return false

	return true


func _on_environment_changed() -> void:
	_is_active = await _calc_is_active()
	_will_be_active = await _calc_will_be_active()

	if _is_active:
		pass

	_self_sprite.visible = _is_active
	if _has_change_indicator:
		_change_indicator.visible = _is_active != _will_be_active
