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


func render_in_hand(index_in_hand: int, hand_size: int, enlarged_card_index: int, is_centered: bool) -> void:
	# Whether the card is enlarged (i.e., its index is equal to enlarged_card_index)
	var is_enlarged: bool = index_in_hand == enlarged_card_index

	# Distance from the card arc's center point
	var offset: float = Hand.ARC_OFFSET_BASE * pow(hand_size, Hand.ARC_OFFSET_POW)

	# Angle between cards
	var angle_delta: float = Hand.ARC_ANGLE_BASE / pow(hand_size, Hand.ARC_ANGLE_POW)

	# Offset applied to the card's angle to 'center' the card arc
	var angle_offset: float = ((hand_size - 1) * angle_delta) / 2 + (Hand.ARC_FOCUS_ANGLE_BASE / 2 if enlarged_card_index >= 0 and enlarged_card_index <= index_in_hand else 0.0)

	var tf_scale: Vector2 = Vector2(1.5, 1.5) if is_enlarged else Vector2(1, 1)

	var tf_rotate: float = angle_delta * index_in_hand - angle_offset if not is_centered else 0.0

	var tf_up: float = Hand.FOCUS_UP_OFFSET if is_enlarged else 0.0

	var tf_unrotate: float = -tf_rotate if is_enlarged and not is_centered else 0

	self.transform = Transform2D() \
		.scaled(tf_scale) \
		.rotated(tf_unrotate) \
		.translated(Vector2(0, -offset - tf_up)) \
		.rotated(tf_rotate) \
		.translated(Vector2(0, offset))


func _on_collider_mouse_entered() -> void:
	var parent = self.get_parent()

	if parent is Hand:
		if parent.clicked_card == null:
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
