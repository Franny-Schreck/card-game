class_name Hand
extends Node2D

const ARC_ANGLE_BASE: float = 0.1

const ARC_OFFSET_BASE: float = 700

const ARC_FOCUS_ANGLE_BASE: float = 0.015

const ARC_FOCUS_OFFSET_BASE: float = 50

const HOVER_EXIT_DELAY: float = 0.05

const CLICKED_OFFSET: float = 50

var board: Board

var cards: Array[Card] = []

var clicked_card: Card = null

var hovered_card: Card = null

var hover_timeout: float = 0


func _ready() -> void:
	self.board = self.get_parent().get_node("board")
	add_card_to_hand(Card.create("The Card OOOOOOOOOOOOOOOOOOOOOO"))
	add_card_to_hand(Card.create("The other Card"))


func add_card_to_hand(card: Card) -> void:
	print("Adding card")
	self.cards.append(card)
	self.add_child(card)


func remove_card_from_hand(card: Card) -> void:
	print("Removing card " + str(Card))
	self.cards.erase(card)
	card.queue_free()


func _input(event: InputEvent) -> void:
	if self.clicked_card == null:
		return

	if event.is_action_released("mouse_left") and not self.clicked_card.is_click(event) or event.is_action_pressed("mouse_left"):
		self.board.play(self.clicked_card)
		self.clicked_card = null


func _process(delta: float) -> void:
	if hover_timeout != 0:
		if hover_timeout - delta <= 0:
			hover_timeout = 0
			hovered_card = null
		else:
			hover_timeout -= delta
	
	var hovered_index: int = self.cards.find(self.hovered_card) if self.hovered_card != null else 9999

	var clicked_index: int = self.cards.find(self.clicked_card) if self.clicked_card != null else 9999

	var centered_index: int = clicked_index
	
	var enlarged_index: int = clicked_index if self.clicked_card != null else hovered_index

	var card_count = self.cards.size()

	var offset = ARC_OFFSET_BASE * pow(card_count, 0.5)

	var angle_delta = ARC_ANGLE_BASE / pow(card_count, 0.6)

	var angle_offset = ((card_count - 1) * angle_delta) / 2

	if self.hovered_card != null or self.clicked_card != null:
		angle_offset += ARC_FOCUS_ANGLE_BASE / 2

	for i in range(card_count):

		var card = self.cards[i]

		var angle = i * angle_delta - angle_offset

		if (i > enlarged_index):
			angle += ARC_FOCUS_ANGLE_BASE

		var transf = Transform2D()

		if i == enlarged_index:
			transf = transf.scaled(Vector2(1.5, 1.5))

		if i == enlarged_index:
			card.z_index = 2
			self.move_child(self.cards[i], -1)
		else:
			card.z_index = 1
			self.move_child(self.cards[i], i)
		
		var tween: Tween = null
		
		if i == centered_index:
			tween = create_tween().set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
		
			tween.tween_property(self.cards[i], "position", Vector2(0, -CLICKED_OFFSET), 0.3).from_current()
			
			#transf = transf.translated(Vector2(0, -CLICKED_OFFSET))
		else:
			var move_up = ARC_FOCUS_OFFSET_BASE if i == hovered_index and self.clicked_card == null else 0.0

			transf = transf.translated(Vector2(0, -(offset + move_up))).rotated(angle).translated(Vector2(0, offset))

			var current_card = self.cards[i]

			current_card.transform = transf

			var current_position = current_card.position

			tween = create_tween().set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)

			tween.tween_property(self.cards[i], "position", current_position, 1).from_current()
			
		card.transform = transf
