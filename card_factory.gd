class_name CardFactory
extends Node

@export var card_script_directory: String

var CARD_SCHEMA: Array[ScriptInterpreter.ScriptProperty] = [
	ScriptInterpreter.ScriptProperty.create("NAME"),
	ScriptInterpreter.ScriptProperty.create("DISPLAYNAME"),
	ScriptInterpreter.ScriptProperty.create("DESCRIPTION"),
	ScriptInterpreter.ScriptProperty.create("IMAGE"),
	ScriptInterpreter.ScriptProperty.create("TAGS", false, true, "lawless|faith"),
	ScriptInterpreter.ScriptProperty.create("USES", false, false, "[1-9][0-9]*"),
	ScriptInterpreter.ScriptProperty.create("TARGET", true, false, "global|local"),
	ScriptInterpreter.ScriptProperty.create("CONDITION", true, true, "", true),
	ScriptInterpreter.ScriptProperty.create("EFFECT", true, true, "", true),
]

var interpreter: ScriptInterpreter

var card_names: Array[String]

var cards: Dictionary

var categories: Dictionary

func load_card_package() -> void:
	var board: Board = get_parent().get_node("board")
	interpreter.define_operators([
		ScriptInterpreter.CustomOperator.create("put-card", board._interp_card_put, 2),
		ScriptInterpreter.CustomOperator.create("take-card", board._interp_card_take, 3),
		ScriptInterpreter.CustomOperator.create("pick-card", board._interp_card_pick, 4),
	])


func create_environment(global_vars: Dictionary, target_vars: Variant) -> ScriptInterpreter.ScriptEnvironment:
	assert(target_vars == null or target_vars is Dictionary)
	return ScriptInterpreter.ScriptEnvironment.create(target_vars != null, target_vars if target_vars != null else {}, global_vars)


func _ready() -> void:
	interpreter = get_node("script_interpreter")

	load_card_package()

	var actual_card_script_directory: String = card_script_directory + ('/' if not card_script_directory.ends_with('/') else '')

	for card_script_filename in DirAccess.get_files_at(actual_card_script_directory):
		var card_script_filepath: String = actual_card_script_directory + card_script_filename
		var card_script_code: String = FileAccess.get_file_as_string(card_script_filepath)

		if card_script_code == "":
			var error: Error = FileAccess.get_open_error()
			if error != OK:
				print("Could not open card script file '", card_script_filepath, "' (Error ", error, ")")
				continue

		var card_script = interpreter.load_script(card_script_filename, card_script_code, CARD_SCHEMA)

		if card_script == null:
			print("Could not load '", card_script_filename, "'. Continuing with other cards")
			continue

		var script_name = card_script["NAME"]

		self.cards[script_name] = card_script

		self.card_names.append(script_name)

		print(card_script_filename, " -> ", script_name, " (", card_script["DISPLAYNAME"], ")")

		if card_script.has("TAGS"):
			for category in card_script["TAGS"]:
				if self.categories.has(category):
					self.categories[category].append(card_script)
				else:
					self.categories[category] = [card_script]

	print("Loaded ", self.cards.size(), " card script", "" if self.cards.size() == 1 else "s")


func get_card() -> Card:
	var index: int = randi_range(0, cards.size() - 1)
	return Card.create_from_script(cards.get(card_names[index]))


func get_card_by_category(category_name: String) -> Card:
	var cards_in_category = categories.get(category_name)
	
	if cards_in_category == null:
		return null
		
	var index: int = randi_range(0, cards_in_category.size() - 1)
	return Card.create_from_script(cards_in_category[index])


func get_card_by_name(card_name: String) -> Card:
	return Card.create_from_script(cards.get(card_name))
