class_name CardFactory
extends Node

var interpreter: ScriptInterpreter

var card_names: Array[String]

var cards: Dictionary

var categories: Dictionary

func load_hand_package() -> void:
	interpreter.define_package(
		"hand",
		{
			"card-from-draw-pile" = Hand.ScriptNodeCardFromDrawPile,
			"card-from-discard-pile" = Hand.ScriptNodeCardFromDiscardPile,
			"card-discard" = Hand.ScriptNodeCardDiscard,
			"card-from" = Hand.ScriptNodeCardFromCategory,
			"card-category-unlawful" = Hand.ScriptNodeCardCategory
		},
		self.get_parent().get_node("hand"))


func create_environment(has_target: bool, target_vars: Dictionary, global_vars: Dictionary) -> ScriptInterpreter.ScriptEnvironment:
	return ScriptInterpreter.ScriptEnvironment.create(has_target, target_vars, global_vars, interpreter.package_data())


func _ready() -> void:
	self.interpreter = self.get_node("script_interpreter")
	
	load_hand_package()

	for card_script_filename in DirAccess.get_files_at("res://card_scripts/"):
		var card_script = self.interpreter.parse_script(card_script_filename)

		if card_script == null:
			print("Could not load '", card_script_filename, "'. Continuing with other cards")
			continue

		self.cards[card_script.script_name] = card_script

		self.card_names.append(card_script.script_name)

		print(card_script_filename, " -> ", card_script.script_name, " (", card_script.display_name, ")")

		for category in card_script.tags:
			if self.categories.has(category):
				self.categories[category].append(card_script)
			else:
				self.categories[category] = [card_script]

	print("Loaded ", self.cards.size(), " card script", "" if self.cards.size() == 1 else "s")


func get_card() -> Card:
	var index: int = randi_range(0, self.cards.size() - 1)
	return Card.create_from_script(self.cards.get(card_names[index]))

