class_name District
extends Node2D

const CHANGE_LIST_FADE_OFFSET = Vector2(0, 50)

var curr_environment: Dictionary = {
	"contentment" = 5,
	"no-income" = 0,
	"income" = 0,
	"church-level" = 0,
	"taxation-level" = 0,
	"bureaucracy-level" = 0,
	"sanitation-level" = 0,
	"farm-level" = 0,
	"palazzo-level" = 0,
	"trade-level" = 0,
	"security-level" = 0,
	"industry-level" = 0,
	"cloth-industry-level" = 0,
}

var prev_environment: Dictionary

var _board: Board

var _highlight: Polygon2D

var _change_list: Label

var _change_list_position: Vector2

var _hide_change_list_tween: Tween


func apply_building_turn_effects(display_index: int) -> bool:
	var env: ScriptInterpreter.ScriptEnvironment = _board.card_factory.create_environment(_board.global_stats.curr_environment.duplicate(), curr_environment.duplicate())

	for building in get_node("elements").get_children():
		if building is BoardItem:
			await building.apply_turn_effects(display_index, env)
		else:
			printerr("Unexpected child ", building.get_name(), " in ", get_path().get_concatenated_names())
			continue

	if curr_environment["no-income"] != 0:
		env.global_vars["fl"] = _board.global_stats.get_fl()

	var changes: Dictionary = {}

	for var_name in env.local_vars.keys():
		var curr_value: int = env.local_vars[var_name]
		var prev_value: int = curr_environment[var_name]

		if curr_value != prev_value:
			if changes.has(var_name):
				changes[var_name] += curr_value - prev_value
				if changes[var_name] == 0:
					changes.erase(var_name)
			else:
				changes[var_name] = curr_value - prev_value
			print("%", var_name, " changed")

	for var_name in env.global_vars.keys():
		var curr_value: int = env.global_vars[var_name]
		var prev_value: int = _board.global_stats.curr_environment[var_name]

		if curr_value != prev_value:
			if changes.has(var_name):
				changes[var_name] += curr_value - prev_value
				if changes[var_name] == 0:
					changes.erase(var_name)
			else:
				changes[var_name] = curr_value - prev_value
			print("$", var_name, " changed")

	var change_text: String = ""

	for change_name in changes.keys():
		var change_value: int = changes[change_name]
		change_text += '-' if change_value < 0 else '+'
		change_text += str(abs(change_value))
		change_text += ' '
		change_text += change_name
		change_text += '\n'

	_change_list.text = change_text

	if changes.size() != 0:
		# Do not await this, so it only affects the UI, withou delaying any effects
		var show_delay: float = 0.15 * pow(display_index, 0.75)
		var hide_delay: float = show_delay + 2
		_show_change_list(show_delay)
		_hide_change_list(hide_delay)
		curr_environment = env.local_vars
		_board.global_stats.curr_environment = env.global_vars
	
	return changes.size() != 0


func _ready() -> void:
	prev_environment = curr_environment

	_board = get_parent()

	var area: Area2D = get_node("area")
	area.mouse_entered.connect(_on_district_mouse_entered)
	area.mouse_exited.connect(_on_district_mouse_exited)

	var collision: CollisionPolygon2D = area.get_node("polygon")

	_highlight = Polygon2D.new()
	_highlight.polygon = collision.polygon
	_highlight.position =  area.position + collision.position
	_highlight.color = Color(1.0, 0.0, 0.0, 0.2)
	_highlight.hide()
	add_child(_highlight)
	
	_change_list = get_node("change_list")

	_change_list_position = _change_list.position

	_change_list.position += CHANGE_LIST_FADE_OFFSET
	_change_list.modulate = Color(0.5, 0.5, 0.5, 0)
	_change_list.hide()

	_board.new_turn.connect(_on_new_turn)


func _on_district_mouse_entered() -> void:
	_board.active_district = self
	if _board.hand.clicked_card != null:
		if await _board.hand.clicked_card.is_playable(_board.script_environment()):
			_highlight.show()
	else:
		_show_change_list(0)


func _on_district_mouse_exited() -> void:
	if _board.active_district == self:
		_board.active_district = null
	_hide_change_list(0.1)
	_highlight.hide()


func _on_card_played() -> void:
	_highlight.hide()


func _show_change_list(delay: float) -> void:

	if _hide_change_list_tween != null:
		_hide_change_list_tween.kill()
		_hide_change_list_tween = null

	var tween = create_tween()

	tween.tween_interval(delay)

	tween.tween_callback(_change_list.show)

	tween.tween_property(_change_list, "position", _change_list_position, 0.3)
	tween.parallel().tween_property(_change_list, "modulate", Color.WHITE, 0.25)


func _hide_change_list(delay: float) -> void:
	var tween = create_tween()

	tween.tween_interval(delay)

	tween.tween_property(_change_list, "position", _change_list_position + CHANGE_LIST_FADE_OFFSET, 0.3)
	tween.parallel().tween_property(_change_list, "modulate", Color(0.5, 0.5, 0.5, 0), 0.3)

	tween.tween_callback(func():
		_change_list.hide()
		_hide_change_list_tween = null)

	_hide_change_list_tween = tween


func _on_new_turn() -> void:
	var no_income = curr_environment["no-income"]
	if no_income != 0:
		pass
	no_income = max(0, no_income - 1)
	curr_environment["no-income"] = no_income
	prev_environment["no-income"] = no_income
