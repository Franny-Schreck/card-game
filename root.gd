extends Node2D

func _ready() -> void:
	var factory: CardFactory = self.get_node("card_factory")

	var hand: Hand = self.get_node("hand")
	hand.add_card_to_hand(factory.get_card())
	hand.add_card_to_hand(factory.get_card())

	var shop: Shop = self.get_node("shop")
	shop.restock()
