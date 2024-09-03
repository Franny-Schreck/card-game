class_name District
extends Node2D

var board: Board

var curr_environment: Dictionary = {
	"contentment" = 5,
}

var prev_environment: Dictionary

var highlight: Polygon2D

var change_list: Label


func _ready() -> void:
	prev_environment = curr_environment

	highlight = Polygon2D.new()
	var area: Area2D = get_node("area")
	var collision: CollisionPolygon2D = area.get_node("polygon")
	highlight.polygon = collision.polygon
	add_child(highlight)
	highlight.color = Color(1.0, 0.0, 0.0, 0.2)
	highlight.hide()
	
	change_list = get_node("change_list")
	change_list.hide()


func _on_district_mouse_entered() -> void:
	board.active_district = self
	if board.hand.clicked_card != null:
		if await board.hand.clicked_card.is_applicable(board.script_environment()):
			highlight.show()


func _on_district_mouse_exited() -> void:
	if board.active_district == self:
		board.active_district = null
	highlight.hide()


func post_ready():
	self.board = get_parent()

	var area: Area2D = get_node("area")
	area.mouse_entered.connect(_on_district_mouse_entered)
	area.mouse_exited.connect(_on_district_mouse_exited)

	for element in get_node("elements").get_children():
		element.board = board
		element.district = self
		element.post_ready()


func apply_building_turn_effects(display_index: int) -> bool:
	var env: ScriptInterpreter.ScriptEnvironment = board.card_factory.create_environment(board.global_stats.curr_environment.duplicate(), curr_environment.duplicate())

	for building in get_node("elements").get_children():
		if building is BoardItem:
			await building.apply_turn_effects(display_index, env)
		else:
			printerr("Unexpected child ", building.get_name(), " in ", get_path().get_concatenated_names())
			continue

	var changes: Dictionary

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
		var prev_value: int = board.global_stats.curr_environment[var_name]

		if curr_value != prev_value:
			if changes.has(var_name):
				changes[var_name] += curr_value - prev_value
				if changes[var_name] == 0:
					changes.erase(var_name)
			else:
				changes[var_name] = curr_value - prev_value
			print("$", var_name, " changed")

	var change_text: String

	for change_name in changes.keys():
		var change_value: int = changes[change_name]
		change_text += '-' if change_value < 0 else '+'
		change_text += str(abs(change_value))
		change_text += ' '
		change_text += change_name
		change_text += '\n'

	if changes.size() != 0:
		# Do not await this, so it only affects the UI, withou delaying any effects
		_show_change_list(change_text, 0.15 * pow(display_index, 0.75), 2.5)
		curr_environment = env.local_vars
		board.global_stats.curr_environment = env.global_vars
	
	return changes.size() != 0


func _show_change_list(text: String, delay: float, duration: float) -> void:
	change_list.text = text

	var tween = create_tween()

	tween.tween_interval(delay)

	tween.tween_callback(func():
		change_list.show()
		change_list.position = Vector2(0, 50)
		change_list.modulate = Color(0.5, 0.5, 0.5, 0))
	
	tween.tween_property(change_list, "position", Vector2(0, 0), 0.3)
	tween.parallel().tween_property(change_list, "modulate", Color.WHITE, 0.25)

	tween.tween_interval(duration)

	tween.tween_property(change_list, "position", Vector2(0, 50), 0.3)
	tween.parallel().tween_property(change_list, "modulate", Color(0.5, 0.5, 0.5, 0), 0.25)

	tween.tween_callback(change_list.hide)

	#await get_tree().create_timer(delay).timeout
	#change_list.text = text
	#change_list.visible = true
	#await get_tree().create_timer(duration).timeout
	#change_list.visible = false
