class_name District
extends Node2D

const CHANGE_LIST_FADE_OFFSET = Vector2(0, 50)

const BASE_ENVIRONMENT: Dictionary = {
	"contentment" = 4,
	"no-income" = 0,
	"income" = 0,
	"taxation-level" = 0,
	"church-level" = 0,
	"bureaucracy-level" = 0,
	"sanitation-level" = 0,
	"farm-level" = 0,
	"palazzo-level" = 0,
	"trade-level" = 0,
	"security-level" = 0,
	"industry-level" = 0,
	"cloth-industry-level" = 0,
	"public-level" = 0,
	
}

@export var _initial_environment: Dictionary = {
	"max-church-level" = 0,
	"max-bureaucracy-level" = 0,
	"max-sanitation-level" = 0,
	"max-farm-level" = 0,
	"max-palazzo-level" = 0,
	"max-trade-level" = 0,
	"max-security-level" = 0,
	"max-industry-level" = 0,
	"max-cloth-industry-level" = 0,
	"max-public-level" = 0,
}

@export var _max_public_level: int = 0

var curr_environment: Dictionary

var prev_environment: Dictionary

var _board: Board

var _highlight: Polygon2D

var _change_list: VBoxContainer

var _contentment_change_box: HBoxContainer

var _contentment_change_label: Label

var _fl_change_box: HBoxContainer

var _fl_change_label: Label

var _gp_change_box: HBoxContainer

var _gp_change_label: Label

var _change_list_position: Vector2

var _hide_change_list_tween: Tween

var _card_played_this_turn: bool


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

	if not _card_played_this_turn:
		if changes.has("contentment"):
			if changes["contentment"] == 1:
				changes.erase("contentment")
			else:
				changes["contentment"] -= 1
		else:
			changes["contentment"] = -1


	if _change_list is VBoxContainer:
		var contentment_delta: int = changes["contentment"] if changes.has("contentment") else 0
		_contentment_change_label.text = str(curr_environment["contentment"]) + ('-' if contentment_delta < 0 else '+' if contentment_delta > 0 else '±') + str(abs(contentment_delta))

		if changes.has("fl"):
			var fl_delta: int = changes["fl"]
			_fl_change_label.text = ('-' if fl_delta < 0 else '+') + str(abs(fl_delta))
		
		_fl_change_box.visible = changes.has("fl")
		
		if changes.has("gp"):
			var gp_delta: int = changes["gp"]
			_gp_change_label.text = ('-' if gp_delta < 0 else '+') + str(abs(gp_delta))
		
		_gp_change_box.visible = changes.has("gp")
	else:
		var change_text: String = "contentment: " + str(curr_environment["contentment"])

		if changes.has("contentment"):
			change_text += (" (-" if changes["contentment"] < 0 else " (+") + str(abs(changes["contentment"])) + ")\n"
			changes.erase("contentment")
		else:
			change_text += '\n'

		for change_name in changes.keys():
			var change_value: int = changes[change_name]
			change_text += '-' if change_value < 0 else '+'
			change_text += str(abs(change_value))
			change_text += ' '
			change_text += change_name
			change_text += '\n'

		_change_list.text = change_text

	if changes.size() != 0:
		# Do not await this, so it only affects the UI, without delaying any effects
		var show_delay: float = 0.15 * pow(display_index, 0.75)
		var hide_delay: float = show_delay + 2
		_show_change_list(show_delay)
		_hide_change_list(hide_delay)
		curr_environment = env.local_vars
		_board.global_stats.curr_environment = env.global_vars

	return changes.size() != 0


func reset() -> void:
	curr_environment = BASE_ENVIRONMENT.duplicate()

	for var_name: String in _initial_environment.keys():
		curr_environment[var_name] = _initial_environment[var_name]

	curr_environment["max-public-level"] = _max_public_level

	prev_environment = curr_environment
	
	_highlight.hide()
	_change_list.hide()


func _ready() -> void:
	_board = get_parent()

	var area: Area2D = get_node("area")
	area.mouse_entered.connect(_on_district_mouse_entered)
	area.mouse_exited.connect(_on_district_mouse_exited)

	var collision: CollisionPolygon2D = area.get_node("polygon")

	_highlight = Polygon2D.new()
	_highlight.polygon = collision.polygon
	_highlight.position =  area.position + collision.position
	_highlight.color = Color(1.0, 0.0, 0.0, 0.2)
	add_child(_highlight)

	_change_list = get_node("change_list")

	_change_list_position = _change_list.position

	_change_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_change_list.position += CHANGE_LIST_FADE_OFFSET
	_change_list.modulate = Color(0.5, 0.5, 0.5, 0)
	_change_list.z_index += 1;
	
	var font: Font = load("res://assets/fonts/PixelOperator8.ttf")

	_contentment_change_label = Label.new()
	_contentment_change_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_contentment_change_label.text = "5±0"
	_contentment_change_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_contentment_change_label.add_theme_font_override("font", font)

	var contentment_change_icon: TextureRect = TextureRect.new()
	contentment_change_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contentment_change_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	contentment_change_icon.texture = load("res://assets/contentment_icon.png")

	_contentment_change_box = HBoxContainer.new()
	_contentment_change_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_contentment_change_box.alignment = BoxContainer.ALIGNMENT_END
	_contentment_change_box.add_child(_contentment_change_label)
	_contentment_change_box.add_child(contentment_change_icon)
	_change_list.add_child(_contentment_change_box)


	_gp_change_label = Label.new()
	_gp_change_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gp_change_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_gp_change_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_gp_change_label.add_theme_font_override("font", font)
	
	var gp_change_icon: TextureRect = TextureRect.new()
	gp_change_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gp_change_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	gp_change_icon.texture = load("res://assets/govpt_icon.png")

	_gp_change_box = HBoxContainer.new()
	_gp_change_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gp_change_box.alignment = BoxContainer.ALIGNMENT_END
	_gp_change_box.hide()
	_gp_change_box.add_child(_gp_change_label)
	_gp_change_box.add_child(gp_change_icon)
	_change_list.add_child(_gp_change_box)


	_fl_change_label = Label.new()
	_fl_change_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fl_change_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_fl_change_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_fl_change_label.add_theme_font_override("font", font)
	
	var fl_change_icon: TextureRect = TextureRect.new()
	fl_change_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fl_change_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	fl_change_icon.texture = load("res://assets/florin_icon.png")
	
	_fl_change_box = HBoxContainer.new()
	_fl_change_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fl_change_box.alignment = BoxContainer.ALIGNMENT_END
	_fl_change_box.hide()
	_fl_change_box.add_child(_fl_change_label)
	_fl_change_box.add_child(fl_change_icon)
	_change_list.add_child(_fl_change_box)


	_board.new_turn.connect(_on_new_turn)

	reset()


func _on_district_mouse_entered() -> void:
	_board.active_district = self
	if _board.hand.clicked_card != null and await _board.hand.clicked_card.is_playable(_board.script_environment()):
		_highlight.show()

	_show_change_list(0)


func _on_district_mouse_exited() -> void:
	if _board.active_district == self:
		_board.active_district = null
	_hide_change_list(0.1)
	_highlight.hide()


func _on_card_played() -> void:
	_highlight.hide()
	_card_played_this_turn = true


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
	if curr_environment["no-income"] > 0:
		curr_environment["no-income"] -= 1

	if not _card_played_this_turn:
		curr_environment["contentment"] -= 1

	_card_played_this_turn = false
