class_name ScriptFactory
extends Node

@export var _script_directory: String

var _interpreter: ScriptInterpreter

var _scripts: Dictionary

var _script_names: Array[String]


func _ready() -> void:
	_interpreter = ScriptInterpreter.new()

	_load_custom_operators()

	var actual_directory: String = _script_directory + ('/' if not _script_directory.ends_with('/') else '')

	var schema: Array[ScriptInterpreter.ScriptProperty] = _get_schema()

	for filename in DirAccess.get_files_at(actual_directory):
		if filename.begins_with('_'):
			continue

		var filepath: String = actual_directory + filename
		var code: String = FileAccess.get_file_as_string(filepath)

		if code == "":
			var error: Error = FileAccess.get_open_error()
			if error != OK:
				printerr("Could not open card script file '", filepath, "' (Error ", error, ")")
				continue

		var script: Dictionary = _interpreter.load_script(filename, code, schema)

		if script.size() == 0:
			printerr("Could not load '", filename, "'. Continuing with other cards")
			continue

		var script_name = script["NAME"]
		_scripts[script_name] = script
		_script_names.append(script_name)

	print("Loaded ", _scripts.size(), " script", "" if _scripts.size() == 1 else "s", " from ", _script_directory)


func _get_schema() -> Array[ScriptInterpreter.ScriptProperty]:
	assert(false, "Called abstract func ScriptFactory._get_schema")
	return []


func _load_custom_operators() -> void:
	var board: Board = get_node("/root/root/board")
	var shop: Shop = get_node("/root/root/shop")
	_interpreter.define_operators([
		ScriptInterpreter.CustomOperator.create("put-card", board._interp_card_put, 2),
		ScriptInterpreter.CustomOperator.create("take-card", board._interp_card_take, 3),
		ScriptInterpreter.CustomOperator.create("pick-card", board._interp_card_pick, 4),
		ScriptInterpreter.CustomOperator.create("card-count", board._interp_card_count, 1),
		ScriptInterpreter.CustomOperator.create("card-attr", board._interp_get_card_attribute, 2),
		ScriptInterpreter.CustomOperator.create("replace-card", board._interp_replace_card, 2),
		ScriptInterpreter.CustomOperator.create("rng", board._interp_random, 2),
		ScriptInterpreter.CustomOperator.create("async", board._interp_recurring_effect, 2),
		ScriptInterpreter.CustomOperator.create("all-districts", board._interp_all_districts, 1),
		ScriptInterpreter.CustomOperator.create("animate-play", board._interp_animate_play, 1),
		ScriptInterpreter.CustomOperator.create("reset-play-costs", board._interp_reset_play_costs, 0),
		ScriptInterpreter.CustomOperator.create("modify-prices", shop._interp_add_price_modifier, 2),
	])
