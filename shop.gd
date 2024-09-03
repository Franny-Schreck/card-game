class_name Shop
extends CardContainer2D

const CARDS_PER_ROW = 3

const INITIAL_SELECTION_SIZE = 6

const COL_WIDTH = 130

const ROW_HEIGHT = 200

var hand: Hand

var card_positions: Dictionary

var max_card_count: int = INITIAL_SELECTION_SIZE


func _ready() -> void:
	self.hand = self.get_parent().get_node("hand")
	self.card_factory = get_parent().get_node("card_factory")


func post_ready() -> void:
	restock()


func add_card(card: Card, _position: int = -1) -> void:
	assert(_position == -1, "Shop.add_card does not support a non-default position argument")
	super.add_card(card, _position)
	card_positions[card] = cards.size() - 1


func remove_card(card: Card) -> void:
	super.remove_card(card)
	card_positions.erase(card)


# Replaces the shop's current selection with a newly generated one
func restock() -> void:
	while cards.size() != 0:
		remove_card(cards[0])
		
	for i in range(max_card_count):
		add_card(card_factory.get_card())


func buy(card: Card) -> bool:
	print("buying " + str(card))

	# TODO: Check price vs gp

	remove_card(card)
	hand.add_card(card)

	return true


func _process(_delta: float) -> void:
	for card in cards:
		var position: int = card_positions[card]

		var col = position % CARDS_PER_ROW

		var row: int = position / CARDS_PER_ROW

		card.transform = Transform2D().translated(Vector2(col * COL_WIDTH, row * ROW_HEIGHT))
