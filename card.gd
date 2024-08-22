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
	return card


func _on_collider_mouse_entered() -> void:
	var parent = self.get_parent()

	if parent is Hand:
		self.get_node("hover_outline").show()
		parent.hover_timeout = 0
		parent.hovered_card = self
	elif parent is Shop:
		pass # TODO
	else:
		assert(false, "Invalid parent of Card. Expected Hand or Shop but got " + parent.get_class())


func _on_collider_mouse_exited() -> void:
	var parent = self.get_parent()

	if parent is Hand:
		self.get_node("hover_outline").hide()
		parent.hover_timeout = Hand.HOVER_EXIT_DELAY
	elif parent is Shop:
		pass # TODO
	else:
		assert(false, "Invalid parent of Card. Expected Hand or Shop but got " + parent.get_class())


func set_clicked(event: InputEvent) -> void:
	self.click_position = event.global_position
	self.click_time = Time.get_ticks_msec()
	

func is_click(event: InputEvent) -> bool:
	return (self.click_position - event.global_position).length() < MIN_DRAG_DISTANCE \
	   and Time.get_ticks_msec() - self.click_time < MIN_DRAG_TIME


func _on_collider_gui_input(event: InputEvent) -> void:
	var parent = self.get_parent()

	if parent is Hand:
		if event.is_action_pressed("mouse_left") and parent.hovered_card == self:
			self.set_clicked(event)
			parent.clicked_card = self
	elif parent is Shop:
		if event.is_action_pressed("mouse_left"):
			parent.buy(self)
	else:
		assert(false, "Invalid parent of Card. Expected Hand or Shop but got " + parent.get_class())
