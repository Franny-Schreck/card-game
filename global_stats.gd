class_name GlobalStats
extends Node2D

var curr_environment: Dictionary = {
	"fl" = 25,
	"gp" = 30,
	"total-church-level" = 0,
	"total-taxation-level" = 0,
	"total-bureaucracy-level" = 0,
	"total-sanitation-level" = 0,
	"total-farm-level" = 0,
	"total-palazzo-level" = 0,
	"total-trade-level" = 0,
	"total-security-level" = 0,
	"total-industry-level" = 0,
	"total-cloth-industry-level" = 0,
	"year" = 1350,
}

var prev_environment: Dictionary

var _board: Board

var _florin_count: Label

var _govpt_count: Label

var _year: Label


func _input(event: InputEvent) -> void:
	if event is InputEventKey and not event.is_echo() and event.is_pressed():
		if event.as_text_keycode() == "G":
			change_gp(1)
		elif event.as_text_keycode() == "F":
			change_fl(1)


func change_gp(delta: int) -> void:
	curr_environment["gp"] += delta
	_board.environment_changed.emit()


func change_fl(delta: int) -> void:
	curr_environment["fl"] += delta
	_board.environment_changed.emit()


func get_gp() -> int:
	return curr_environment["gp"]


func get_fl() -> int:
	return curr_environment["fl"]


func _ready() -> void:
	_board = get_parent().get_node("board")
	_florin_count = get_node("florin_count")
	_govpt_count = get_node("govpt_count")
	_year = _board.get_node("year_counter")
	prev_environment = curr_environment
	_board.environment_changed.connect(_on_environment_changed)
	_board.new_turn.connect(_on_new_turn)
	_update_year_label()


func _update_year_label() -> void:
	_year.text = str(curr_environment["year"]) + " AD"


func _on_environment_changed() -> void:
	_florin_count.text = str(curr_environment["fl"])
	_govpt_count.text = str(curr_environment["gp"])
	
	var church_level: int = 0
	var taxation_level: int = 0
	var bureaucracy_level: int = 0
	var sanitation_level: int = 0
	var farm_level: int = 0
	var palazzo_level: int = 0
	var trade_level: int = 0
	var security_level: int = 0
	var industry_level: int = 0
	var cloth_industry_level: int = 0
	
	for district: District in _board._districts:
		church_level += district.curr_environment["church-level"]
		taxation_level += district.curr_environment["taxation-level"]
		bureaucracy_level += district.curr_environment["bureaucracy-level"]
		sanitation_level += district.curr_environment["sanitation-level"]
		farm_level += district.curr_environment["farm-level"]
		palazzo_level += district.curr_environment["palazzo-level"]
		trade_level += district.curr_environment["trade-level"]
		security_level += district.curr_environment["security-level"]
		industry_level += district.curr_environment["industry-level"]
		cloth_industry_level += district.curr_environment["cloth-industry-level"]

	curr_environment["total-church-level"] = church_level
	curr_environment["total-taxation-level"] = taxation_level
	curr_environment["total-bureaucracy-level"] = bureaucracy_level
	curr_environment["total-sanitation-level"] = sanitation_level
	curr_environment["total-farm-level"] = farm_level
	curr_environment["total-palazzo-level"] = palazzo_level
	curr_environment["total-trade-level"] = trade_level
	curr_environment["total-security-level"] = security_level
	curr_environment["total-industry-level"] = industry_level
	curr_environment["total-cloth-industry-level"] = cloth_industry_level


func _on_new_turn() -> void:
	curr_environment["year"] += 10
	_update_year_label()
