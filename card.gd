class_name Card
extends Node2D

const MIN_DRAG_DISTANCE = 10

const MIN_DRAG_TIME = 500

var card_script: ScriptInterpreter.ScriptBlock

var click_position: Vector2

var click_time: int = 0



static func create_from_script(card_script_: ScriptInterpreter.ScriptBlock) -> Card:
	var scene = load("res://card.tscn")
	var card: Card = scene.instantiate()
	card.card_script = card_script_
	card.get_node("scale_container/display_name").text = card_script_.display_name
	card.get_node("scale_container/description_container/description").text = card_script_.description
	card.get_node("scale_container/artwork").texture = load("res://assets/card_images/" + card_script_.image_path + ".png")
	return card


func _on_collider_mouse_entered() -> void:
	var parent = self.get_parent()

	if parent is Hand:
		self.get_node("scale_container/hover_outline").show()
		parent.hover_timeout = 0
		parent.hovered_card = self
	elif parent is Shop:
		pass # TODO
	else:
		assert(false, "Invalid parent of Card. Expected Hand or Shop but got " + parent.get_class())


func _on_collider_mouse_exited() -> void:
	var parent = self.get_parent()

	if parent is Hand:
		self.get_node("scale_container/hover_outline").hide()
		parent.hover_timeout = Hand.HOVER_EXIT_DELAY
	elif parent is Shop:
		pass # TODO
	else:
		assert(false, "Invalid parent of Card. Expected Hand or Shop but got " + parent.get_class())


func set_clicked(event: InputEvent) -> void:
	self.get_node("scale_container/click_outline").show()
	self.get_node("scale_container/hover_outline").hide()

	self.click_position = event.global_position

	self.click_time = Time.get_ticks_msec()


func is_click(event: InputEvent) -> bool:
	self.get_node("scale_container/click_outline").show()
	self.get_node("scale_container/hover_outline").hide()

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
