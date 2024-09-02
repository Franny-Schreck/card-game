class_name Hand
extends CardContainer2D

const IMPORTS = ["board"]

const ARC_ANGLE_BASE: float = 0.1

const ARC_OFFSET_BASE: float = 1100

const ARC_ANGLE_POW: float = 0.6

const ARC_OFFSET_POW: float = 0.5

const ARC_FOCUS_ANGLE_BASE: float = 0.015

const FOCUS_UP_OFFSET: float = 110

const HOVER_EXIT_DELAY: float = 0.05

var board: Board

var draw_pile: DrawPile

var discard_pile: DiscardPile

var clicked_card: Card = null

var hovered_card: Card = null

var hover_timeout: float = 0


func _ready() -> void:
	super._ready()
	self.board = get_parent().get_node("board")
	self.draw_pile = get_parent().get_node("draw_pile")
	self.discard_pile = get_parent().get_node("discard_pile")


func post_ready() -> void:
	add_card(card_factory.get_card())
	add_card(card_factory.get_card())


func _input(event: InputEvent) -> void:
	if self.clicked_card == null:
		return

	if event.is_action_released("mouse_left") and not self.clicked_card.is_click(event) or event.is_action_pressed("mouse_left"):
		self.clicked_card.get_node("scale_container/click_outline").hide()
		self.board.play(self.clicked_card)
		self.clicked_card = null


func _process(delta: float) -> void:
	if hover_timeout != 0:
		if hover_timeout - delta <= 0:
			hover_timeout = 0
			hovered_card = null
		else:
			hover_timeout -= delta

	var enlarged_card_index: int = self.cards.find(self.clicked_card)

	if enlarged_card_index == -1:
		enlarged_card_index = self.cards.find(self.hovered_card)

	for i in range(self.cards.size()):
		var card: Card = self.cards[i]
		var is_clicked: bool = card == self.clicked_card
		card.render_in_hand(i, self.cards.size(), enlarged_card_index, is_clicked)
		card.z_index = 1
		self.move_child(card, i)

	if enlarged_card_index != -1:
		var enlarged_card: Card = self.cards[enlarged_card_index]
		enlarged_card.z_index = 2
		self.move_child(enlarged_card, -1)
