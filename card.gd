class_name Card
extends Node2D

const MIN_DRAG_DISTANCE = 10

const MIN_DRAG_TIME = 500

var click_position: Vector2

var click_time: int = 0

static func create(display_name: String) -> Card:
	var scene = load("res://card.tscn")
	var card: Card = scene.instantiate()
	card.get_node("display_name").text = display_name
	#card.get_node("collider").mouse_filter = Control.MOUSE_FILTER_PASS
	return card


func _on_collider_mouse_entered() -> void:
	self.get_node("hover_outline").show()
	var hand: Hand = self.get_parent()
	hand.hover_timeout = 0
	hand.hovered_card = self


func _on_collider_mouse_exited() -> void:
	self.get_node("hover_outline").hide()
	var hand: Hand = self.get_parent()
	hand.hover_timeout = Hand.HOVER_EXIT_DELAY


func set_clicked(event: InputEvent) -> void:
	self.click_position = event.global_position
	self.click_time = Time.get_ticks_msec()
	

func is_click(event: InputEvent) -> bool:
	return (self.click_position - event.global_position).length() < MIN_DRAG_DISTANCE \
	   and Time.get_ticks_msec() - self.click_time < MIN_DRAG_TIME


func _on_collider_gui_input(event: InputEvent) -> void:
	var hand: Hand = self.get_parent()

	if event.is_action_pressed("mouse_left") and hand.hovered_card == self:
		self.set_clicked(event)
		hand.clicked_card = self
