class_name CardContainer2D
extends Node2D

var cards: Array[Card]

var card_factory: CardFactory


func _ready() -> void:
	self.card_factory = get_parent().get_node("card_factory")


func add_card(card: Card) -> void:
	cards.append(card)
	add_child(card)


func remove_card(card: Card) -> void:
	cards.erase(card)
	remove_child(card)
