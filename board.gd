class_name Board
extends Node2D

var active_district: Area2D = null

func _on_district_mouse_entered(district: Area2D) -> void:
	self.active_district = district
	print("Entered " + str(district))

func _on_district_mouse_exited(district: Area2D) -> void:
	if self.active_district == district:
		self.active_district = null
	print("Exited " + str(district))

func _ready() -> void:
	for district in self.get_children():
		if district is Area2D:
			district.mouse_entered.connect(_on_district_mouse_entered.bind(district))
			district.mouse_exited.connect(_on_district_mouse_exited.bind(district))


func play(card: Card) -> bool:
	var factory: CardFactory = self.get_parent().get_node("card_factory")
	var env: ScriptInterpreter.ScriptEnvironment = factory.create_environment( \
		self.active_district != null, \
		{ }, # TODO
		{ "fl" = 0, "gp" = 0, "cm" = 0 } # TODO
	)

	if card.card_script.is_applicable(env):
		card.card_script.apply(env)
		return true
	else:
		return false
