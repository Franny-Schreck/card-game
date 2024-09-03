class_name CardContainer2D
extends Node2D

var cards: Array[Card]

var card_factory: CardFactory


func _ready() -> void:
	self.card_factory = get_parent().get_node("card_factory")


func add_card(card: Card, position: int = -1) -> void:
	assert(card.get_card_container() == null, "Argument of CardContainer2D.add_card is already inside a card container")

	add_child(card)

	if position == -1:
		cards.append(card)
	else:
		cards.insert(position, card)
		move_child(card, position)

	card.reset()


func remove_card(card: Card) -> void:
	cards.erase(card)
	remove_child(card)
