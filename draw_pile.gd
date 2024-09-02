class_name DrawPile
extends CardContainer2D

const MAX_RENDERED_CARDS = 5


func post_ready() -> void:
	for i in range(10):
		add_card(card_factory.get_card())


func add_card(card: Card) -> void:
	super.add_card(card)
	card.visible = false
	if cards.size() <= MAX_RENDERED_CARDS:
		var card_back: Sprite2D = get_node("card_back_" + str(cards.size() - 1))
		card_back.visible = true


func remove_card(card: Card) -> void:
	super.remove_card(card)
	card.visible = true
	if cards.size() < MAX_RENDERED_CARDS:
		var card_back: Sprite2D = get_node("card_back_" + str(cards.size()))
		card_back.visible = false
