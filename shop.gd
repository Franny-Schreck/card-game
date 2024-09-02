class_name Shop
extends Node2D

const CARDS_PER_ROW = 3

const INITIAL_SELECTION_SIZE = CARDS_PER_ROW * 2

const COL_WIDTH = 130

const ROW_HEIGHT = 200

var hand: Hand

var card_factory: CardFactory

var selection: Array[Card] = []

func _ready() -> void:
	self.hand = self.get_parent().get_node("hand")
	self.card_factory = get_parent().get_node("card_factory")


func post_ready() -> void:
	for i in range(INITIAL_SELECTION_SIZE):
		self.selection.append(null)	

	restock()


# Replaces the shop's current selection with a newly generated one
func restock() -> void:
	for i in range(self.selection.size()):

		if self.selection[i] != null:
			self.remove_child(self.selection[i])
			self.selection[i].queue_free()

		var card = card_factory.get_card()
		self.selection[i] = card
		self.add_child(card)

	print("Restocked " + str(self.selection.size()) + " cards")


func buy(card: Card) -> bool:
	print("buying " + str(card))
	var card_index = self.selection.find(card)

	assert(card_index != -1, "Could not find card in shop's selection")

	self.selection[card_index] = null

	self.remove_child(card)

	self.hand.add_card(card)

	return false # TODO


func _process(_delta: float) -> void:
	assert(self.selection.size() % CARDS_PER_ROW == 0)

	for i in range(self.selection.size()):
		if self.selection[i] == null:
			continue

		var col = i % CARDS_PER_ROW

		var row: int = i / CARDS_PER_ROW
		
		self.selection[i].transform = Transform2D().translated(Vector2(col * COL_WIDTH, row * ROW_HEIGHT))
