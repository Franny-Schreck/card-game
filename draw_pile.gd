class_name DrawPile
extends CardContainer2D

const MAX_RENDERED_CARDS = 5


func post_ready() -> void:
	for i in range(10):
		add_card(card_factory.get_card())


func add_card(card: Card, position: int = -1) -> void:
	super.add_card(card, position)
	card.visible = false


func remove_card(card: Card) -> void:
	super.remove_card(card)
	card.visible = true


func _process(_delta: float) -> void:
	var visible_card_back_count: int = min(cards.size(), MAX_RENDERED_CARDS)

	for i in range(MAX_RENDERED_CARDS):
		var card_back: Sprite2D = get_node("card_back_" + str(i))
		card_back.visible = i < visible_card_back_count
