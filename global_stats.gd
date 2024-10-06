class_name GlobalStats
extends Node2D

const INITIAL_ENVIRONMENT: Dictionary = {
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
	"total-public-level" = 0,
	"year" = 1350,
}

var curr_environment: Dictionary = INITIAL_ENVIRONMENT.duplicate()

var prev_environment: Dictionary

var _board: Board

var _florin_count: Label

var _florin_container: Node2D

var _govpt_count: Label

var _govpt_container: Node2D

var _year: Label


func reset() -> void:
	curr_environment = INITIAL_ENVIRONMENT.duplicate()
	prev_environment = curr_environment
	_update_year_label()


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
	_board = get_node("/root/root/board")
	_florin_container = get_node("florin")
	_florin_count = _florin_container.get_node("florin_count")
	_govpt_container = get_node("govpt")
	_govpt_count = _govpt_container.get_node("govpt_count")
	_year = _board.get_node("year_counter")
	_board.environment_changed.connect(_on_environment_changed)
	_board.new_turn.connect(_on_new_turn)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and not event.is_echo() and event.is_pressed():
		if event.as_text_keycode() == "G":
			change_gp(1)
		elif event.as_text_keycode() == "F":
			change_fl(1)


func _update_year_label() -> void:
	_year.text = str(curr_environment["year"]) + " AD"


func _on_environment_changed() -> void:
	var old_florin_count: String = _florin_count.text
	var new_florin_count: String = str(curr_environment["fl"])
	_florin_count.text = new_florin_count

	if old_florin_count != new_florin_count:
		var tween = create_tween()
		tween.tween_property(_florin_container, "scale", Vector2(1.3, 1.3), 0.4)
		tween.tween_property(_florin_container, "scale", Vector2(1.0, 1.0), 0.4)

	var old_govpt_count: String = _govpt_count.text
	var new_govpt_count: String = str(curr_environment["gp"])
	_govpt_count.text = new_govpt_count
	
	if old_govpt_count != new_govpt_count:
		var tween = create_tween()
		tween.tween_property(_govpt_container, "scale", Vector2(1.3, 1.3), 0.4)
		tween.tween_property(_govpt_container, "scale", Vector2(1.0, 1.0), 0.4)

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
	var public_level: int = 0
	
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
		public_level += district.curr_environment["public-level"]

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
	curr_environment["total-public-level"] = public_level


func _on_new_turn() -> void:
	curr_environment["year"] += 5
	_update_year_label()
