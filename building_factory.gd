class_name BuildingFactory
extends ScriptFactory

func get_building_script(script_name: String) -> Dictionary:
	return _scripts[script_name]


func _ready() -> void:
	super._ready()


func _get_schema() -> Array[ScriptInterpreter.ScriptProperty]:
	return [
		ScriptInterpreter.ScriptProperty.create("NAME"),
		ScriptInterpreter.ScriptProperty.create("DESCRIPTION"),
		ScriptInterpreter.ScriptProperty.create("TYPE"),
		ScriptInterpreter.ScriptProperty.create("CONDITION", true, true, "", true),
		ScriptInterpreter.ScriptProperty.create("EFFECT", true, true, "", true),
	]
