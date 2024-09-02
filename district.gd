class_name District
extends Node2D

var board: Board

var environment: Dictionary = {
	"contentment" = 5
}

var highlight: Polygon2D


func _on_district_mouse_entered() -> void:
	board.active_district = self
	print("Entered " + str(self))
	if board.hand.clicked_card != null:
		if board.hand.clicked_card.is_applicable(board.script_environment()):
			highlight.show()


func _on_district_mouse_exited() -> void:
	if board.active_district == self:
		board.active_district = null
	print("Exited " + str(self))
	highlight.hide()


func _ready() -> void:
	self.highlight = Polygon2D.new()
	var area: Area2D = get_node("area")
	var collision: CollisionPolygon2D = area.get_node("polygon")
	highlight.polygon = collision.polygon
	add_child(highlight)
	highlight.color = Color(1.0, 0.0, 0.0, 0.2)
	highlight.hide()


func post_ready():
	self.board = get_parent()

	var area: Area2D = get_node("area")
	area.mouse_entered.connect(_on_district_mouse_entered)
	area.mouse_exited.connect(_on_district_mouse_exited)

	for element in get_node("elements").get_children():
		element.board = board
		element.district = self
		element.show_func = board.card_factory \
			.get_node("script_interpreter") \
			.load_script_node(element.get_path().get_concatenated_names(), element.show_if)
