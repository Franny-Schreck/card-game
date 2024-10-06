class_name CardFactory
extends ScriptFactory

var _global_stats: GlobalStats

var _categories: Dictionary

class Category:
	var scripts: Array[Dictionary]
	var frequencies: PackedFloat32Array
	var total_frequency: float


func create_environment(global_vars: Dictionary, target_vars: Variant) -> ScriptInterpreter.ScriptEnvironment:
	assert(target_vars == null or target_vars is Dictionary)
	return ScriptInterpreter.ScriptEnvironment.create(target_vars != null, target_vars if target_vars != null else {}, global_vars)


func get_card_by_category(category_name: String) -> Card:
	var category: Category = _categories[category_name]
	
	var n: float = randf_range(0.0, category.total_frequency)
	
	for i in range(category.frequencies.size()):
		n -= category.frequencies[i]
		if n <= 0:
			return await Card.create_from_script(category.scripts[i])

	return await Card.create_from_script(category.scripts.back())


func get_card_by_name(card_name: String) -> Card:
	return await Card.create_from_script(_scripts.get(card_name))


func has_card_with_name(card_name: String) -> bool:
	return _scripts.has(card_name)


func replace_card_by_name(card_name: String, replace_with: Dictionary) -> void:
	var old_script: Dictionary = _scripts[card_name]

	_scripts[card_name] = replace_with

	for category_name: String in old_script["TAGS"]:
		var category: Category = _categories[category_name]
		category.scripts[category.scripts.find(old_script)] = replace_with
	
	_on_environment_changed()


func get_script_by_name(card_name: String) -> Dictionary:
	return _scripts[card_name]


func _ready() -> void:
	super._ready()
	
	_global_stats = get_node("/root/root/global_stats")

	var env: ScriptInterpreter.ScriptEnvironment = create_environment(_global_stats.curr_environment, null)

	for script in _scripts.values():
		if not script.has("TAGS"):
			continue

		for tag in script["TAGS"]:
			var category: Category = _categories.get(tag)

			if category == null:
				category = Category.new()
				_categories[tag] = category

			category.scripts.append(script)

			var frequency: float = await _get_script_frequency_for_tag(script, tag, env)
			category.frequencies.append(frequency)
			category.total_frequency += frequency

	get_node("/root/root/board").environment_changed.connect(_on_environment_changed)


func _get_script_frequency_for_tag(script: Dictionary, tag: String, env: ScriptInterpreter.ScriptEnvironment) -> float:
	env.global_vars["TAG"] = tag
	var frequency_func: ScriptInterpreter.ScriptNode = script["FREQUENCY"]
	return float(await frequency_func.evaluate([], env))


func _get_schema() -> Array[ScriptInterpreter.ScriptProperty]:
	return [
		ScriptInterpreter.ScriptProperty.create("NAME"),
		ScriptInterpreter.ScriptProperty.create("DISPLAYNAME"),
		ScriptInterpreter.ScriptProperty.create("DESCRIPTION"),
		ScriptInterpreter.ScriptProperty.create("IMAGE"),
		ScriptInterpreter.ScriptProperty.create("TAGS", false, true, "lawless|faith|sticky|keep-on-play|shop"),
		ScriptInterpreter.ScriptProperty.create("USES", false, false, "[1-9][0-9]*"),
		ScriptInterpreter.ScriptProperty.create("TARGET", true, false, "global|local"),
		ScriptInterpreter.ScriptProperty.create("CONDITION", true, true, "", true),
		ScriptInterpreter.ScriptProperty.create("EFFECT", true, true, "", true),
		ScriptInterpreter.ScriptProperty.create("PLAY-COST", true, false, "", true),
		ScriptInterpreter.ScriptProperty.create("SHOP-COST", true, false, "", true),
		ScriptInterpreter.ScriptProperty.create("ON-TURN-START", false, true, "", true),
		ScriptInterpreter.ScriptProperty.create("ON-TURN-END", false, true, "", true),
		ScriptInterpreter.ScriptProperty.create("FREQUENCY", true, false, "", true),
	]


func _on_environment_changed() -> void:
	var env: ScriptInterpreter.ScriptEnvironment = create_environment(_global_stats.curr_environment, null)

	for tag: String in _categories.keys():
		var category: Category = _categories[tag]

		category.total_frequency = 0

		for i in range(category.scripts.size()):
			var frequency: float = await _get_script_frequency_for_tag(category.scripts[i], tag, env)
			category.frequencies[i] = frequency
			category.total_frequency += frequency
