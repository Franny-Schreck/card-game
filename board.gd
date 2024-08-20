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
	if self.active_district == null:
		return false
	else:
		print("Played " + str(card) + " onto " + str(self.active_district))
		return true
